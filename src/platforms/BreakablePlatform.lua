---
--- Zerbrechliche Plattform.
--- Wird nach dem ersten Betreten durch den Spieler entfernt.
---

---@class BreakablePlatform : Platform
local BreakablePlatform = {}
BreakablePlatform.__index = BreakablePlatform
setmetatable(BreakablePlatform, Platform)

---
--- Erstellt eine neue zerbrechliche Plattform.
---
---@param pos_x number -- Linke X-Position der Plattform
---@param pos_y number -- Y-Position der Plattform (Weltkoordinaten)
---@param width number -- Breite der Plattform
---@return BreakablePlatform
function BreakablePlatform.new(pos_x, pos_y, width)
    local self = Platform.new(pos_x, pos_y, width)
    self.fill_color = 5
    self.border_color = 4
    return setmetatable(self, BreakablePlatform)
end

---
--- Wird aufgerufen, wenn der Spieler auf der Plattform landet.
--- Markiert die Plattform als zerstört, sodass sie im nächsten Update entfernt wird.
---
---@param player Player -- Referenz auf den Spieler
function BreakablePlatform:on_land(player)
    self.is_dead = true
end
