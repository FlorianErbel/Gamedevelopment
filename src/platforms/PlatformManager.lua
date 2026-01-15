---@class PlatformManager
---@field list table
---@field highest_y number
---@field last_x number
---@field diff number
---@field jump_v number
---@field g number
local PlatformManager = {}

function PlatformManager.new(diff)
    local self = setmetatable({}, PlatformManager)
    self:init(diff)
    return self
end


function PlatformManager:init(diff)
     self.diff = diff or 1

     self.jump_v = 4.4
     self.g = 0.22

     self.list = {}
     self.highest_y = 112
     self.last_x = nil

     -- ground
     self:add(-64, 120, 256, true)

     -- startplattformen
     local y = 104
     for i = 1, 14 do
         self:spawn_platform(y, true)
         y = y - 10
     end
 end


function PlatformManager:add(x, y, w, is_ground)
    add(self.list, {
        x = x, y = y, w = w,
        h = 4,
        ground = is_ground or false
    })
    if y < self.highest_y then
        self.highest_y = y
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
    local v = self.jump_v or 3.6
    local g = self.g or 0.22
    return (v * v) / (2 * g)
end


-- difficulty in 5%-schritten bis max 90% der reach
-- am anfang sehr easy (z.B. 55-65%), später höher
function PlatformManager:get_reach_factor(at_y, easy)
  if easy then return 0.55 end

  local height = max(0, 120 - at_y)

  -- alle ~80px höhe ein +5% step
  local step = flr(height / 80)      -- 0,1,2,...
  local factor = 0.60 + step*0.05    -- 0.60, 0.65, 0.70, ...
  return clamp(factor, 0.60, 0.90)
end

function PlatformManager:get_dy_reach(at_y, easy)
  local maxh = self:get_max_jump_height()
  local f = self:get_reach_factor(at_y, easy)
  -- 90% von max height (oder weniger im early game)
  return maxh * f
end

function PlatformManager:get_dx_reach(at_y, easy)
  -- simple "radius" um den anchor x
  -- am anfang großzügig, später etwas strenger
  local height = max(0, 120 - at_y)
  local base = easy and 44 or 38
  local shrink = flr(height/140) * 4
  return clamp(base - shrink, 22, 44)
end

function PlatformManager:max_per_level(easy)
  if easy then return 3 end
  if self.diff==1 then return 3 end
  if self.diff==2 then return 2 end
  return 1
end

-- function PlatformManager:spawn_platform(at_y, easy)
  --  local height = max(0, 120 - at_y)

  --  local w
  --  if easy then
  --      w = 34
  --  else
  --      w = 28 - flr(height / 90) * 4
  --      w = clamp(w, 12, 28)
  --  end

    -- anchor um die letzte plattform (oder mitte beim start)
  --  local ax = self.last_x or 64

    -- horizontale erreichbarkeit: "radius" um ax
  --  local dx = self:get_dx_reach(at_y, easy)
  --  local minx = ax - dx
  --  local maxx = ax + dx

    -- wrap-friendly: clamp nur auf groben screenbereich
  --  local x = flr(rnd(maxx - minx + 1) + minx)

    -- auf screenbreite mappen
  --  x = (x % 128 + 128) % 128
  --  x = clamp(x, 0, 128 - w)

  --  self.last_x = x + w / 2
  --  self:add(x, at_y, w, false)
--end

function PlatformManager:spawn_platform(at_y, easy)
    local height = max(0, 120 - at_y)

    local w
    if easy then
        w = 34
    else
        w = clamp(28 - flr(height / 90) * 4, 12, 28)
    end

    local ax = self.last_x or 64
    local dx = self:get_dx_reach(at_y, easy)

    local x = flr(rnd(dx * 2 + 1) + (ax - dx))
    x = (x % 128 + 128) % 128
    x = clamp(x, 0, 128 - w)

    self.last_x = x + w / 2
    self:add(x, at_y, w, false)
end


function PlatformManager:update(camera_y)
  -- stelle sicher, dass oberhalb des sichtbaren bereichs genug plattformen existieren
  -- sichtbarer top ist camera_y, wir wollen bis camera_y - 128 (eine screenhöhe darüber) auffüllen
  local top_needed = camera_y - 140

  while self.highest_y > top_needed do
    local dy = self:get_dy_reach(self.highest_y, false)

    -- dy soll nie zu klein werden (sonst zu viele plattformen)
    dy = clamp(dy, 10, 28)

        local next_y = self.highest_y - flr(dy)

    local n = self:max_per_level(false)
    -- etwas randomness, aber begrenzt:
    -- easy: oft 2-3, medium: 1-2, hard: 1
    if self.diff==1 then
      n = 1 + flr(rnd(n)) -- 1..3
      if rnd() < 0.55 then n = min(3, n+1) end
    elseif self.diff==2 then
      n = 1 + flr(rnd(n)) -- 1..2
    else
      n = 1
    end

    -- mehrere plattformen auf gleicher höhe, aber mit leicht unterschiedlichen anchors
    local saved_anchor = self.last_x
    for i=1,n do
      if saved_anchor then
        self.last_x = saved_anchor + (i-((n+1)/2))*18
      end
      self:spawn_platform(next_y, false)
    end
    self.last_x = saved_anchor

    self.highest_y = next_y
  end

  -- alte plattformen weit unter dem bildschirm entfernen
  for i=#self.list,1,-1 do
    local p = self.list[i]
    if p.y > camera_y + 200 then
      del(self.list, p)
    end
  end
end

function PlatformManager:draw()
  for p in all(self.list) do
    if p.ground then
      rectfill(p.x, p.y, p.x+p.w-1, p.y+p.h-1, 5)
    else
      rectfill(p.x, p.y, p.x+p.w-1, p.y+p.h-1, 11)
      -- kleine kanten
      rect(p.x, p.y, p.x+p.w-1, p.y+p.h-1, 3)
    end
  end
end

-- one-way collision: nur wenn player von oben kommt (fallend) und über der plattform war
function PlatformManager:check_landing(player, prev_y)
  if player.vy <= 0 then return false end -- nur beim fallen (vy positiv)
  local px = player.x
  local py = player.y
  local pw = player.w
  local ph = player.h

  -- player "füße"
  local foot_y_prev = prev_y + ph
  local foot_y_now  = py + ph

  for p in all(self.list) do
    -- x-overlap
    if px+pw > p.x and px < p.x+p.w then
      local plat_y = p.y

      -- war vorher über der plattform und ist jetzt drunter/gleich => landen
      if foot_y_prev <= plat_y and foot_y_now >= plat_y then
        -- auf plattform setzen
        player.y = plat_y - ph
        player.vy = 0
     --   player.on_plat = true
        return p.y
      end
    end
  end

  return false
end
