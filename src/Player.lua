player = {}

function player:init()
    self.pos_x = 64
    self.pos_y = 100
    self.width = 6
    self.height = 8

    self.velocity_x = 0
    self.velocity_y = 0

    self.gravity = 0.22
    self.move_acceleration = 0.35
    self.max_velocity_x = 1.8

    self.jump_vertical = -4.4 -- -3.6
    self.jump_vertical_small = -2.4

    self.jump_boost_factor = 1.0
    self.is_jump_boost_used = false

    self.on_plat = false
    self.is_alive = true

    self.last_landed_pos_y = 120
    self.best_landed_pos_y = 120 -- kleinste y (höchste plattform)

    self.shots = {}
    self.shot_speed = 18
end

function player:jump()
    local base_jump = self.jump_vertical
    if btn(3) then -- down
        base_jump = self.jump_vertical_small
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
    --[[local shot_speed = self.shot_speed
    add(self.shots, {
        pos_x = self.pos_x + self.width / 2,
        pos_y = self.pos_y + self.height / 2,
        velocity_x = direction_x * shot_speed,
        velocity_y = direction_y * shot_speed,
        life = 60
    })]]
    add(self.shots, Shot.new(
        self.pos_x + self.width / 2,
        self.pos_y + self.height / 2,
        direction_x * self.shot_speed,
        direction_y * self.shot_speed
    ))
end

function player:update_shots(cam_pos_y)
    --[[for i = #self.shots, 1, -1 do
        local shots = self.shots[i]
        shots.pos_x = shots.pos_x + shots.velocity_x
        shots.pos_y = shots.pos_y + shots.velocity_y
        shots.life = shots.life - 1

        -- screen bounds in world coords
        local left_bound = 0
        local right_bound = 128
        local top_bound = cam_pos_y
        local bottom_bound = cam_pos_y + 128

        if shots.pos_x < left_bound - 4 or shots.pos_x > right_bound + 4 or shots.pos_y < top_bound - 4 or shots.pos_y > bottom_bound + 4 or shots.life <= 0 then
            del(self.shots, shots)
        end
    end]]
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
        circfill(shot.pos_x, shot.pos_y, 2, 10) -- feuerball
        pset(shot.pos_x + 1, shot.pos_y, 7)     -- glanzpunkt
    end
end

function player:update(plats_ref, cam_pos_y)
    if not self.is_alive then return end

    local previous_y = self.pos_y

    -- input
    local ax = 0
    if btn(0) then ax = ax - self.move_acceleration end -- left
    if btn(1) then ax = ax + self.move_acceleration end -- right

    self.velocity_x = self.velocity_x + ax
    self.velocity_x = clamp(self.velocity_x, -self.max_velocity_x, self.max_velocity_x)

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
    self.velocity_y = self.velocity_y + self.gravity

    -- Bewegung
    self.pos_x = self.pos_x + self.velocity_x
    self.pos_y = self.pos_y + self.velocity_y

    -- wrap-around
    if self.pos_x < -self.width then self.pos_x = 128 end
    if self.pos_x > 128 then self.pos_x = -self.width end

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
    rectfill(self.pos_x, self.pos_y, self.pos_x + self.width - 1, self.pos_y + self.height - 1, 7)
    pset(self.pos_x + 1, self.pos_y + 2, 0)
    pset(self.pos_x + 4, self.pos_y + 2, 0)
end
