---
--- Basisklasse für alle Plattformtypen.
--- Stellt gemeinsame Positions-, Größen-, Rendering- und Lebenszykluslogik bereit.
---
---@class Platform
---@field pos_x number        -- Weltkoordinate X (linke Kante)
---@field pos_y number        -- Weltkoordinate Y (obere Kante)
---@field width number        -- Breite der Plattform
---@field height number       -- Höhe der Plattform
---@field is_dead boolean     -- Markiert die Plattform zur Entfernung
---@field fill_color number   -- Füllfarbe für das Rendering
---@field border_color number -- Rahmenfarbe für das Rendering
local Platform = {}
Platform.__index = Platform

---
--- Erstellt eine neue Plattforminstanz.
---
---@param pos_x number
---@param pos_y number
---@param width number
---@return Platform
function Platform.new(pos_x, pos_y, width)
    local self = setmetatable({}, Platform)
    self.pos_x = pos_x
    self.pos_y = pos_y
    self.width = width
    self.height = 4
    self.is_dead = false
    self.fill_color = 11
    self.border_color = 3
    return self
end

---
--- Wird aufgerufen, wenn der Spieler auf der Plattform landet.
--- Standardmäßig leer, kann von Unterklassen überschrieben werden, um Spezialverhalten zu implementieren.
---
---@param player table
function Platform:on_land(player)
end

---
--- Aktualisiert plattformspezifische Logik.
--- Standardmäßig leer und für Überschreibungen vorgesehen.
function Platform:update()
end

---
--- Zeichnet die Plattform anhand ihrer Positions- und Farbattribute.
function Platform:draw()
    rectfill(
        self.pos_x,
        self.pos_y,
        self.pos_x + self.width - 1,
        self.pos_y + self.height - 1,
        self.fill_color
    )
    rect(
        self.pos_x,
        self.pos_y,
        self.pos_x + self.width - 1,
        self.pos_y + self.height - 1,
        self.border_color
    )
end
