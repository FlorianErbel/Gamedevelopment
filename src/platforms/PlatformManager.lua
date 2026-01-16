---@class PlatformManager
---@field list table
---@field topmost_platform_y number
---@field last_platform_anchor_x number
---@field difficulty number
---@field jump_vertical number
---@field gravity number
local PlatformManager = {}
PlatformManager.__index = PlatformManager

function PlatformManager:init(difficulty)
    self.difficulty = difficulty or 1
    self.jump_vertical = 4.4
    self.gravity = 0.22

    self.list = {}
    self.topmost_platform_y = 112
    self.last_platform_anchor_x = nil
    self.camera_pos_y = 0

    self.minimum_height_catapult_platform = 2000
    self.minimum_height_breakable_platform = 1000

    self.random_generation_limit_catapult_platform = 0.20
    self.random_generation_limit_breakable_platform = 0.35

    -- ground
    self:add_platform("ground", 0, 120, 128, true)
end

function PlatformManager.new(difficulty)
    local self = setmetatable({}, PlatformManager)
    self:init(difficulty)
    return self
end

function PlatformManager:add_platform(kind, pos_x, pos_y, width, is_ground)
    local plat = PlatformFactory.create(kind or "default", pos_x, pos_y, width)

    plat.is_ground = is_ground or false
    add(self.list, plat)

    if pos_y < self.topmost_platform_y then
        self.topmost_platform_y = pos_y
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
    local g = self.gravity or 0.22
    return (vertical * vertical) / (2 * g)
end

-- difficulty in 5%-schritten bis max 90% der reach
-- am anfang sehr is_easy_mode (z.B. 55-65%), später höher
function PlatformManager:get_reach_factor(at_pos_y, is_easy_mode)
    if is_easy_mode then return 0.55 end

    local height = max(0, 120 - at_pos_y)

    -- alle ~80px höhe ein +5% step
    local step = flr(height / 80)     -- 0,1,2,...
    local factor = 0.60 + step * 0.05 -- 0.60, 0.65, 0.70, ...
    return clamp(factor, 0.60, 0.90)
end

function PlatformManager:get_vertical_spawn_gap_reach(at_pos_y, is_easy_mode)
    local max_height = self:get_max_jump_height()
    local factor = self:get_reach_factor(at_pos_y, is_easy_mode)
    -- 90% von max height (oder weniger im early game)
    return max_height * factor
end

function PlatformManager:get_horizontal_reach_reach(at_pos_y, is_easy_mode)
    -- simple "radius" um den anchor x
    -- am anfang großzügig, später etwas strenger
    local height = max(0, 120 - at_pos_y)
    local base = is_easy_mode and 44 or 38
    local shrink = flr(height / 140) * 4
    return clamp(base - shrink, 22, 44)
end

function PlatformManager:max_per_level(is_easy_mode)
    if is_easy_mode then return 3 end
    if self.difficulty == 1 then return 3 end
    if self.difficulty == 2 then return 2 end
    return 1
end

function PlatformManager:platform_overlaps_existing(pos_x, pos_y, width, height)
    local min_vertical_gap = height or 6

    for plat in all(self.list) do
        if pos_y < plat.pos_y + plat.height
            and pos_y + height > plat.pos_y then
            -- horizontale Überlappung
            if pos_x < plat.pos_x + plat.width
                and pos_x + width > plat.pos_x then
                return true
            end
        end
    end
    return false
end

function PlatformManager:spawn_platform(at_pos_y, is_easy_mode)
    local height = max(0, 120 - at_pos_y)

    local width = is_easy_mode and 34 or clamp(28 - flr(height / 90) * 4, 12, 28)

    local anchor_x = self.last_platform_anchor_x or 64
    local horizontal_reach = self:get_horizontal_reach_reach(at_pos_y, is_easy_mode)

    local max_tries = 8
    local pos_x = nil

    for i = 1, max_tries do
        local new_pos_x = flr(rnd(horizontal_reach * 2 + 1) + (anchor_x - horizontal_reach))
        new_pos_x = (new_pos_x % 128 + 128) % 128
        new_pos_x = clamp(new_pos_x, 0, 128 - width)

        if not self:platform_overlaps_existing(new_pos_x, at_pos_y, width, 6) then
            pos_x = new_pos_x
            break
        end
    end

    if not pos_x then
        self.topmost_platform_y = at_pos_y
        return
    end

    self.last_platform_anchor_x = pos_x + width / 2

    local kind = "default"
    if not is_easy_mode then
        local height_from_ground = max(0, 120 - at_pos_y)
        local random_number = rnd()

        if height_from_ground >= self.minimum_height_catapult_platform and random_number < self.random_generation_limit_catapult_platform then
            kind = "catapult"
        elseif height_from_ground >= self.minimum_height_breakable_platform and random_number < self.random_generation_limit_breakable_platform then
            kind = "breakable"
        end
    end

    self:add_platform(kind, pos_x, at_pos_y, width, false)
end

function PlatformManager:update(camera_pos_y)
    -- stelle sicher, dass oberhalb des sichtbaren bereichs genug plattformen existieren
    -- sichtbarer top ist camera_y, wir wollen bis camera_y - 128 (eine screenhöhe darüber) auffüllen
    local top_needed = camera_pos_y - 140

    while self.topmost_platform_y > top_needed do
        local vertical_spawn_gap = self:get_vertical_spawn_gap_reach(self.topmost_platform_y, false)

        -- vertical_spawn_gap soll nie zu klein werden (sonst zu viele plattformen)
        vertical_spawn_gap = clamp(vertical_spawn_gap, 10, 28)

        local next_pos_y = self.topmost_platform_y - flr(vertical_spawn_gap)

        local number_of_max_per_level = self:max_per_level(false)
        -- etwas randomness, aber begrenzt:
        -- is_easy_mode: oft 2-3, medium: 1-2, hard: 1
        if self.difficulty == 1 then
            number_of_max_per_level = 1 + flr(rnd(number_of_max_per_level)) -- 1..3
            if rnd() < 0.55 then number_of_max_per_level = min(3, number_of_max_per_level + 1) end
        elseif self.difficulty == 2 then
            number_of_max_per_level = 1 + flr(rnd(number_of_max_per_level)) -- 1..2
        else
            number_of_max_per_level = 1
        end

        -- mehrere plattformen auf gleicher höhe, aber mit leicht unterschiedlichen anchors
        local saved_anchor = self.last_platform_anchor_x
        for i = 1, number_of_max_per_level do
            if saved_anchor then
                self.last_platform_anchor_x = saved_anchor + (i - ((number_of_max_per_level + 1) / 2)) * 18
            end
            self:spawn_platform(next_pos_y, false)
        end
        self.last_platform_anchor_x = saved_anchor

        self.topmost_platform_y = next_pos_y
    end

    local visible_bottom_y = camera_pos_y + 128

    for i = #self.list, 1, -1 do
        local plat = self.list[i]

        if plat.is_dead
            or plat.pos_y > visible_bottom_y + 16 then
            del(self.list, plat)
        end
    end
end

function PlatformManager:draw()
    for plat in all(self.list) do
        if plat.ground then
            rectfill(plat.pos_x, plat.pos_y, plat.pos_x + plat.width - 1, plat.pos_y + plat.height - 1, 5)
        else
            rectfill(plat.pos_x, plat.pos_y, plat.pos_x + plat.width - 1, plat.pos_y + plat.height - 1, plat.fill_color)
            -- kleine kanten
            rect(plat.pos_x, plat.pos_y, plat.pos_x + plat.width - 1, plat.pos_y + plat.height - 1, plat.border_color)
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
