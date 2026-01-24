---
--- Standardplattform ohne Spezialverhalten.
--- Dient als häufigster Plattformtyp im Spiel.
---
---@class DefaultPlatform : Platform
local DefaultPlatform = {}
DefaultPlatform.__index = DefaultPlatform
setmetatable(DefaultPlatform, Platform)

---
--- Erstellt eine neue Standardplattform.
--- Übernimmt vollständig das Verhalten und die Darstellung der Basisklasse Platform.
---
---@param pos_x number -- Linke X-Position der Plattform
---@param pos_y number -- Y-Position der Plattform (Weltkoordinaten)
---@param width number -- Breite der Plattform
---@return DefaultPlatform
function DefaultPlatform.new(pos_x, pos_y, width)
    local self = Platform.new(pos_x, pos_y, width)
    return setmetatable(self, DefaultPlatform)
end
