---
--- Player class
--- Klasse für Spielerobjekte inklusive Bewegung, Sprung und Schießen
---

---@class Player
---@field pos_x number           -- x-Koordinate des Spielers
---@field pos_y number           -- y-Koordinate des Spielers
---@field WIDTH number           -- Breite des Spielers
---@field HEIGHT number          -- Höhe des Spielers
---@field velocity_x number      -- Geschwindigkeit in x-Richtung
---@field velocity_y number      -- Geschwindigkeit in y-Richtung
---@field GRAVITY number         -- Gravitation
---@field MOVE_ACCELERATION number -- Beschleunigung bei Bewegung
---@field MAX_VELOCITY_X number  -- Max Geschwindigkeit horizontal
---@field JUMP_VERTICAL number   -- Standard-Sprungkraft
---@field JUMP_VERTICAL_SMALL number -- Kleine Sprungkraft (Down-Button)
---@field jump_boost_factor number   -- Faktor für Sprungverstärkung
---@field is_jump_boost_used boolean -- Flag, ob Boost aktiv ist
---@field on_plat boolean        -- Flag, ob Spieler auf Plattform ist
---@field is_alive boolean       -- Flag, ob Spieler lebt
---@field last_landed_pos_y number -- Letzte y-Koordinate beim Landen
---@field best_landed_pos_y number -- Höchste bisher erreichte Plattform (kleinste y)
---@field shots Shot[]           -- Liste der aktiven Projektile
---@field SHOT_SPEED number      -- Geschwindigkeit der Projektile
local player = {}

---Initialisiert Spieler-Attribute
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

    self.JUMP_VERTICAL = -4.4
    self.JUMP_VERTICAL_SMALL = -2.4

    self.jump_boost_factor = 1.0
    self.is_jump_boost_used = false

    self.on_plat = false
    self.is_alive = true

    self.last_landed_pos_y = 120
    self.best_landed_pos_y = 120

    self.shots = {}
    self.SHOT_SPEED = 5
end

---Führt einen Sprung aus, unter Berücksichtigung von Boost oder Down-Button
function player:jump()
    local base_jump = self.JUMP_VERTICAL
    if btn(3) then -- Down-Button kleine Sprunghöhe
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

---Feuert ein Projektil in die gewünschte Richtung
---@param direction_x number Richtung x (-1 bis 1)
---@param direction_y number Richtung y (-1 bis 1)
function player:shoot(direction_x, direction_y)
    add(self.shots, Shot.new(
        self.pos_x + self.WIDTH / 2,
        self.pos_y + self.HEIGHT / 2,
        direction_x * self.SHOT_SPEED,
        direction_y * self.SHOT_SPEED
    ))
end

---Aktualisiert alle aktiven Projektile
---@param cam_pos_y number aktuelle Kameraposition Y
function player:update_shots(cam_pos_y)
    for i = #self.shots, 1, -1 do
        local shot = self.shots[i]
        shot:update()
        if shot:is_dead(cam_pos_y) then
            del(self.shots, shot)
        end
    end
end

---Zeichnet alle aktiven Projektile
function player:draw_shots()
    for shot in all(self.shots) do
        shot:draw()
    end
end

---Aktualisiert Spielerbewegung, Input, Gravitation, Sprünge und Projektile
---@param plats_ref PlatformManager Referenz auf den PlatformManager
---@param cam_pos_y number aktuelle Kameraposition Y
function player:update(plats_ref, cam_pos_y)
    if not self.is_alive then return end

    local previous_y = self.pos_y

    -- Input horizontal
    local anchor_x = 0
    if btn(0) then anchor_x = anchor_x - self.MOVE_ACCELERATION end
    if btn(1) then anchor_x = anchor_x + self.MOVE_ACCELERATION end
    self.velocity_x = clamp(self.velocity_x + anchor_x, -self.MAX_VELOCITY_X, self.MAX_VELOCITY_X)

    -- Schießen mit UP-Button
    if btn(2) then
        if btnp(2) then self:shoot(0, -1) end
        if btnp(3) then self:shoot(0, 1) end
        if btnp(0) then self:shoot(-1, 0) end
        if btnp(1) then self:shoot(1, 0) end
    end

    -- Luftwiderstand
    self.velocity_x = self.velocity_x * 0.9

    -- Gravitation
    self.velocity_y = self.velocity_y + self.GRAVITY

    -- Position aktualisieren
    self.pos_x = self.pos_x + self.velocity_x
    self.pos_y = self.pos_y + self.velocity_y

    -- Wrap-around horizontal
    if self.pos_x < -self.WIDTH then self.pos_x = 128 end
    if self.pos_x > 128 then self.pos_x = -self.WIDTH end

    -- Plattform-Check
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

---Zeichnet den Spieler und seine Projektile
function player:draw()
    self:draw_shots()
    rectfill(self.pos_x, self.pos_y, self.pos_x + self.WIDTH - 1, self.pos_y + self.HEIGHT - 1, 7)
    pset(self.pos_x + 1, self.pos_y + 2, 0)
    pset(self.pos_x + 4, self.pos_y + 2, 0)
end
