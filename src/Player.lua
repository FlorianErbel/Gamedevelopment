player = {}

function player:init()
    self.pos_x = 64
    self.pos_y = 100
    self.WIDTH = 6
    self.HEIGHT = 8

    self.velocity_x = 0
    self.velocity_y = 0

    self.GRAVITY = 0.22
    self.MOVE_ACCELERATION = 0.35
    self.MAX_VELOCITY_X = 1.8

    self.JUMP_VERTICAL = -4.4 -- -3.6
    self.JUMP_VERTICAL_SMALL = -2.4

    self.jump_boost_factor = 1.0
    self.is_jump_boost_used = false

    self.on_plat = false
    self.is_alive = true

    self.last_landed_pos_y = 120
    self.best_landed_pos_y = 120 -- kleinste y (höchste plattform)

    self.shots = {}
    self.SHOT_SPEED = 5
end

function player:jump()
    local base_jump = self.JUMP_VERTICAL
    if btn(3) then -- down
        base_jump = self.JUMP_VERTICAL_SMALL
    end
    if self.is_jump_boost_used == true then
        local final_jump_height = base_jump * self.jump_boost_factor

        self.velocity_y = final_jump_height
        self.jump_boost_factor = 1.0
        self.is_jump_boost_used = false
    else
        self.velocity_y = base_jump
    end
    self.on_plat = false
end

function player:shoot(direction_x, direction_y)
    add(self.shots, Shot.new(
        self.pos_x + self.WIDTH / 2,
        self.pos_y + self.HEIGHT / 2,
        direction_x * self.SHOT_SPEED,
        direction_y * self.SHOT_SPEED
    ))
end

function player:update_shots(cam_pos_y)
    for i = #self.shots, 1, -1 do
        local shot = self.shots[i]
        shot:update()
        if shot:is_dead(cam_pos_y) then
            del(self.shots, shot)
        end
    end
end

function player:draw_shots()
    for shot in all(self.shots) do
        shot:draw()
    end
end

function player:update(plats_ref, cam_pos_y)
    if not self.is_alive then return end

    local previous_y = self.pos_y

    -- input
    local anchor_x = 0
    if btn(0) then anchor_x = anchor_x - self.MOVE_ACCELERATION end -- left
    if btn(1) then anchor_x = anchor_x + self.MOVE_ACCELERATION end -- right

    self.velocity_x = self.velocity_x + anchor_x
    self.velocity_x = clamp(self.velocity_x, -self.MAX_VELOCITY_X, self.MAX_VELOCITY_X)

    -- shoot only while holding UP
    if btn(2) then
        if btnp(2) then self:shoot(0, -1) end -- up shoots up
        if btnp(3) then self:shoot(0, 1) end  -- down shoots down
        if btnp(0) then self:shoot(-1, 0) end -- left shoots left
        if btnp(1) then self:shoot(1, 0) end  -- right shoots right
    end


    -- Luftwiderstand
    self.velocity_x = self.velocity_x * 0.90

    -- Gravitation
    self.velocity_y = self.velocity_y + self.GRAVITY

    -- Bewegung
    self.pos_x = self.pos_x + self.velocity_x
    self.pos_y = self.pos_y + self.velocity_y

    -- wrap-around
    if self.pos_x < -self.WIDTH then self.pos_x = 128 end
    if self.pos_x > 128 then self.pos_x = -self.WIDTH end

    -- one-way landings (einmal prüfen, mit gültigem previous_y)
    self.on_plat = false
    local landed_plat = plats_ref:check_landing(self, previous_y)

    if landed_plat then
        self.last_landed_pos_y = landed_plat.pos_y
        if landed_plat.pos_y < self.best_landed_pos_y then
            self.best_landed_pos_y = landed_plat.pos_y
        end
        self:jump()
    end

    self:update_shots(cam_pos_y)
end

function player:draw()
    self:draw_shots()
    -- einfache figur: body + augen
    rectfill(self.pos_x, self.pos_y, self.pos_x + self.WIDTH - 1, self.pos_y + self.HEIGHT - 1, 7)
    pset(self.pos_x + 1, self.pos_y + 2, 0)
    pset(self.pos_x + 4, self.pos_y + 2, 0)
end
