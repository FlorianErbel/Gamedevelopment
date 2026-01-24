enemies = {}

function enemies:init()
  self.list = {}
end

-- AABB collision
local function aabb(ax,ay,aw,ah,bx,by,bw,bh)
  return ax < bx+bw and ax+aw > bx and ay < by+bh and ay+ah > by
end

function enemies:max_alive(diff)
  if diff==1 then return 1 end
  if diff==2 then return 2 end
  return 3
end

-- spawnchance pro "platform level"
function enemies:spawn_prob(diff, height)
  local base = (diff==1 and 0.05) or (diff==2 and 0.08) or 0.12
  -- height wächst mit fortschritt; langsam ansteigen lassen
  local hf = clamp(height / 800, 0, 1) * 0.18  -- +0..0.18
  local p = base + hf
  return min(p, 0.35)
end

-- platform: table {x,y,w,h}
function enemies:try_spawn_on_platform(platform, diff, height)
  if not self.list then self.list = {} end
  if #self.list >= self:max_alive(diff) then return end
  if platform.ground then return end
  if platform.w < 18 then return end -- zu klein für igel-laufen

  local p = self:spawn_prob(diff, height)
  if rnd() > p then return end

  local e = {
    kind="hedgehog",
    plat=platform,          -- referenz
    w=8, h=6,
    dir = (rnd() < 0.5) and -1 or 1,
    speed = (diff==1 and 0.45) or (diff==2 and 0.6) or 0.8,
    x = platform.x + 4,
    y = platform.y - 6,
    alive=true
  }
  add(self.list, e)
end

function enemies:update()
  for i=#self.list,1,-1 do
    local e = self.list[i]
    if not e.alive then
      del(self.list, e)
    else
      local p = e.plat
      -- falls plattform gelöscht wurde: entfernen
      if not p then
        del(self.list, e)
      else
        -- y an plattform binden
        e.y = p.y - e.h

        -- hin und her laufen auf der plattform
        e.x = e.x +  e.dir * e.speed
        local left = p.x
        local right = p.x + p.w - e.w
        if e.x < left then e.x = left; e.dir = 1 end
        if e.x > right then e.x = right; e.dir = -1 end
      end
    end
  end
end

function enemies:draw()
  for e in all(self.list) do
    -- einfacher "igel": kleiner block + stacheln
    rectfill(e.x, e.y, e.x+e.w-1, e.y+e.h-1, 4)
    -- stacheln oben
    pset(e.x+1, e.y-1, 0)
    pset(e.x+3, e.y-2, 0)
    pset(e.x+5, e.y-1, 0)
  end
end

function enemies:player_hit(player)
  for e in all(self.list) do
    if aabb(player.pos_x, player.pos_y, player.width, player.height, e.x, e.y, e.w, e.h) then
      return true
    end
  end
  return false
end

function enemies:shots_hit(player)
  -- player.shots ist die projektil-liste
  local shots = player.shots
  if not shots then return 0 end

  local kills = 0

  for si=#shots,1,-1 do
    local s = shots[si]
    -- treat shot as small box
    local sx, sy = s.pos_x-2, s.pos_y-2
    local sw, sh = 4, 4

    local hit = false

    for ei=#self.list,1,-1 do
      local e = self.list[ei]
      if e.alive then
        if sx < e.x+e.w and sx+sw > e.x and sy < e.y+e.h and sy+sh > e.y then
          -- kill enemy + consume shot
          e.alive = false
          del(self.list, e)
          hit = true
          kills = kills + 1
          break
        end
      end
    end

    if hit then
      del(shots, s)
    end
  end

  return kills
end

