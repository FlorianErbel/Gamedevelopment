---@class PlatformManager
---@field list table
---@field highest_pos_y number
---@field last_pos_x number
---@field diff number
---@field jump_vertical number
---@field g number
local PlatformManager = {}
PlatformManager.__index = PlatformManager

function PlatformManager:init(diff)
    self.diff = diff or 1

    self.jump_vertical = 4.4
    self.g = 0.22

    self.list = {}
    self.highest_pos_y = 112
    self.last_pos_x = nil

    -- ground
    --self:add_platform(-64, 120, 256, true)
    self:add_platform("default", -64, 120, 256, true)

    -- startplattformen
    local y = 104
    for i = 1, 14 do
        self:spawn_platform(y, true)
        y = y - 10
    end
end

function PlatformManager.new(diff)
    local self = setmetatable({}, PlatformManager)

    self.diff = diff or 1
    self.jump_vertical = 4.4
    self.g = 0.22
    self.list = {}
    self.highest_pos_y = 112
    self.last_pos_x = nil

    self:add_platform("default", -64, 120, 256, true)

    local y = 104
    for i = 1, 14 do
        self:spawn_platform(y, true)
        y = y - 10
    end
    return self
end

function PlatformManager:add_platform(kind, pos_x, pos_y, width, is_ground)
    local plat = PlatformFactory.create(kind or "default", pos_x, pos_y, width)

    plat.is_ground = is_ground or false
    add(self.list, plat)

    if pos_y < self.highest_pos_y then
        self.highest_pos_y = pos_y
    end
end

-- difficulty: je höher, desto weniger / weiter auseinander
function PlatformManager:difficulty_at(y)
    local height = max(0, 120 - y)
    local gap = 12 + flr(height / 60)
    return clamp(gap, 12, 26)
end

-- max jump height aus physik: h = v^2/(2g)
-- wir nehmen default-werte passend zu Player.lua (jump_v=-3.6, g=0.22)
function PlatformManager:get_max_jump_height()
    local vertical = self.jump_vertical or 3.6
    local g = self.g or 0.22
    return (vertical * vertical) / (2 * g)
end

-- difficulty in 5%-schritten bis max 90% der reach
-- am anfang sehr easy (z.B. 55-65%), später höher
function PlatformManager:get_reach_factor(at_pos_y, easy)
    if easy then return 0.55 end

    local height = max(0, 120 - at_pos_y)

    -- alle ~80px höhe ein +5% step
    local step = flr(height / 80)     -- 0,1,2,...
    local factor = 0.60 + step * 0.05 -- 0.60, 0.65, 0.70, ...
    return clamp(factor, 0.60, 0.90)
end

function PlatformManager:get_dy_reach(at_pos_y, easy)
    local max_height = self:get_max_jump_height()
    local factor = self:get_reach_factor(at_pos_y, easy)
    -- 90% von max height (oder weniger im early game)
    return max_height * factor
end

function PlatformManager:get_dx_reach(at_pos_y, easy)
    -- simple "radius" um den anchor x
    -- am anfang großzügig, später etwas strenger
    local height = max(0, 120 - at_pos_y)
    local base = easy and 44 or 38
    local shrink = flr(height / 140) * 4
    return clamp(base - shrink, 22, 44)
end

function PlatformManager:max_per_level(easy)
    if easy then return 3 end
    if self.diff == 1 then return 3 end
    if self.diff == 2 then return 2 end
    return 1
end

function PlatformManager:spawn_platform(at_pos_y, easy)
    local height = max(0, 120 - at_pos_y)

    local width
    if easy then
        width = 34
    else
        width = clamp(28 - flr(height / 90) * 4, 12, 28)
    end

    local ax = self.last_pos_x or 64
    local dx = self:get_dx_reach(at_pos_y, easy)

    local new_pos_x = flr(rnd(dx * 2 + 1) + (ax - dx))
    new_pos_x = (new_pos_x % 128 + 128) % 128
    new_pos_x = clamp(new_pos_x, 0, 128 - width)
    self.last_pos_x = new_pos_x + width / 2

    local kind = "default"
    if not easy then
        local r = rnd()
        if r < 0.2 then
            kind = "catapult"
        elseif r < 0.35 then
            kind = "breakable"
        end
    end

    self:add_platform(kind, new_pos_x, at_pos_y, width, false)
end

function PlatformManager:update(camera_pos_y)
    -- stelle sicher, dass oberhalb des sichtbaren bereichs genug plattformen existieren
    -- sichtbarer top ist camera_y, wir wollen bis camera_y - 128 (eine screenhöhe darüber) auffüllen
    local top_needed = camera_pos_y - 140

    while self.highest_pos_y > top_needed do
        local dy = self:get_dy_reach(self.highest_pos_y, false)

        -- dy soll nie zu klein werden (sonst zu viele plattformen)
        dy = clamp(dy, 10, 28)

        local next_pos_y = self.highest_pos_y - flr(dy)

        local number_of_max_per_level = self:max_per_level(false)
        -- etwas randomness, aber begrenzt:
        -- easy: oft 2-3, medium: 1-2, hard: 1
        if self.diff == 1 then
            number_of_max_per_level = 1 + flr(rnd(number_of_max_per_level)) -- 1..3
            if rnd() < 0.55 then number_of_max_per_level = min(3, number_of_max_per_level + 1) end
        elseif self.diff == 2 then
            number_of_max_per_level = 1 + flr(rnd(number_of_max_per_level)) -- 1..2
        else
            number_of_max_per_level = 1
        end

        -- mehrere plattformen auf gleicher höhe, aber mit leicht unterschiedlichen anchors
        local saved_anchor = self.last_pos_x
        for i = 1, number_of_max_per_level do
            if saved_anchor then
                self.last_pos_x = saved_anchor + (i - ((number_of_max_per_level + 1) / 2)) * 18
            end
            self:spawn_platform(next_pos_y, false)
        end
        self.last_pos_x = saved_anchor

        self.highest_pos_y = next_pos_y
    end

    -- alte plattformen weit unter dem bildschirm entfernen
    for i = #self.list, 1, -1 do
        local plat = self.list[i]
        if plat.is_dead then del(self.list, plat) end
    end
end

function PlatformManager:draw()
    for plat in all(self.list) do
        if plat.ground then
            rectfill(plat.pos_x, plat.pos_y, plat.pos_x + plat.width - 1, plat.pos_y + plat.height - 1, 5)
        else
            rectfill(plat.pos_x, plat.pos_y, plat.pos_x + plat.width - 1, plat.pos_y + plat.height - 1, 11)
            -- kleine kanten
            rect(plat.pos_x, plat.pos_y, plat.pos_x + plat.width - 1, plat.pos_y + plat.height - 1, 3)
        end
    end
end

-- one-way collision: nur wenn player von oben kommt (fallend) und über der plattform war
function PlatformManager:check_landing(player, previous_pos_y)
    if player.vy <= 0 then return false end

    local foot_previous = previous_pos_y + player.height
    local foot_now      = player.pos_y + player.height

    for plat in all(self.list) do
        if player.pos_x + player.width > plat.pos_x and player.pos_x < plat.pos_x + plat.width then
            if foot_previous <= plat.pos_y and foot_now >= plat.pos_y then
                player.pos_y = plat.pos_y - player.height
                player.vy = 0
                plat:on_land(player)
                return plat
            end
        end
    end
end
