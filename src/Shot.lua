---
--- Shot class
--- Klasse für einzelne Projektilobjekte des Spielers
---

---@class Shot
---@field pos_x number          -- x-Koordinate des Projektils
---@field pos_y number          -- y-Koordinate des Projektils
---@field velocity_x number     -- Geschwindigkeit in x-Richtung
---@field velocity_y number     -- Geschwindigkeit in y-Richtung
---@field life number           -- Lebensdauer des Projektils in Frames
local Shot = {}
Shot.__index = Shot

---Erstellt ein neues Projektil
---@param pos_x number Start-x-Koordinate
---@param pos_y number Start-y-Koordinate
---@param velocity_x number Geschwindigkeit in x-Richtung
---@param velocity_y number Geschwindigkeit in y-Richtung
---@return Shot
function Shot.new(pos_x, pos_y, velocity_x, velocity_y)
    local self = setmetatable({}, Shot)
    self.pos_x = pos_x
    self.pos_y = pos_y
    self.velocity_x = velocity_x
    self.velocity_y = velocity_y
    self.life = 60 -- Standard-Lebensdauer in Frames
    return self
end

---Aktualisiert die Position und Lebensdauer des Projektils
function Shot:update()
    self.pos_x = self.pos_x + self.velocity_x
    self.pos_y = self.pos_y + self.velocity_y
    self.life = self.life - 1
end

---Zeichnet das Projektil auf den Bildschirm
function Shot:draw()
    circfill(self.pos_x, self.pos_y, 2, 10)
    pset(self.pos_x + 1, self.pos_y, 7)
end

---Überprüft, ob das Projektil zerstört oder aus dem Sichtbereich gefallen ist
---@param cam_y number aktuelle y-Kameraposition
---@return boolean true, wenn Projektil entfernt werden sollte
function Shot:is_dead(cam_y)
    return self.life <= 0
        or self.pos_x < -4
        or self.pos_x > 132
        or self.pos_y < cam_y - 4
        or self.pos_y > cam_y + 132
end
