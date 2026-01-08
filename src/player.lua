player = {}

function player:init()
  self.x = 64
  self.y = 100
  self.w = 6
  self.h = 8

  self.vx = 0
  self.vy = 0

  self.g = 0.22
  self.move_acc = 0.35
  self.max_vx = 1.8

  self.jump_v = -4.4 -- -3.6
  self.jump_v_small = -2.4

  self.on_plat = false
  self.alive = true

  self.last_landed_y = 120
  self.best_landed_y = 120  -- kleinste y (höchste plattform)

  self.shots = {}
  self.shot_speed = 18

end

function player:jump()
  local j = self.jump_v
  if btn(3) then -- down
    j = self.jump_v_small
  end
  self.vy = j
  self.on_plat = false
end

function player:shoot(dx, dy)
  local sp = self.shot_speed
  add(self.shots, {
    x = self.x + self.w/2,
    y = self.y + self.h/2,
    vx = dx * sp,
    vy = dy * sp,
    life = 60
  })
end


function player:update_shots(cam_y)
  for i=#self.shots,1,-1 do
    local s = self.shots[i]
    s.x += s.vx
    s.y += s.vy
    s.life -= 1

    -- screen bounds in world coords
    local left = 0
    local right = 128
    local top = cam_y
    local bot = cam_y + 128

    if s.x < left-4 or s.x > right+4 or s.y < top-4 or s.y > bot+4 or s.life <= 0 then
      del(self.shots, s)
    end
  end
end


function player:draw_shots()
  for s in all(self.shots) do
    circfill(s.x, s.y, 2, 10)  -- feuerball
    pset(s.x+1, s.y, 7)        -- glanzpunkt
  end
end


function player:update(plats_ref, cam_y)
  if not self.alive then return end

  local prev_y = self.y

  -- input
  local ax = 0
  if btn(0) then ax -= self.move_acc end -- left
  if btn(1) then ax += self.move_acc end -- right

  self.vx = self.vx + ax
  self.vx = clamp(self.vx, -self.max_vx, self.max_vx)

  -- shoot only while holding UP
  if btn(2) then
    if btnp(2) then self:shoot( 0,-1) end -- up shoots up
    if btnp(3) then self:shoot( 0, 1) end -- down shoots down
    if btnp(0) then self:shoot(-1, 0) end -- left shoots left
    if btnp(1) then self:shoot( 1, 0) end -- right shoots right
  end


  -- luftwiderstand
  self.vx *= 0.90

  -- gravity
  self.vy += self.g

  -- move
  self.x += self.vx
  self.y += self.vy

  -- wrap-around
  if self.x < -self.w then self.x = 128 end
  if self.x > 128 then self.x = -self.w end

  -- one-way landings (einmal prüfen, mit gültigem prev_y)
  self.on_plat = false
  local landed_y = plats_ref:check_landing(self, prev_y)
  if landed_y then
    self.last_landed_y = landed_y
    if landed_y < self.best_landed_y then
      self.best_landed_y = landed_y
    end
    self:jump() -- doodlejump: direkt wieder hoch
  end
  self:update_shots(cam_y)
end


function player:draw()
  self:draw_shots()
  -- einfache figur: body + augen
  rectfill(self.x, self.y, self.x+self.w-1, self.y+self.h-1, 7)
  pset(self.x+1, self.y+2, 0)
  pset(self.x+4, self.y+2, 0)
end
