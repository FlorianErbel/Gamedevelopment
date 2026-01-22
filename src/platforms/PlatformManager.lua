---@class PlatformManager
---@field list table                 -- Liste aller Plattformen
---@field topmost_platform_y number  -- y-Koordinate der höchstgelegenen Plattform
---@field last_platform_anchor_x number -- Letzte x-Koordinate als Anker für neue Plattformen
---@field difficulty number           -- Schwierigkeitsgrad
---@field DEFAULT_JUMP_VELOCITY number -- Standard-Sprunggeschwindigkeit des Spielers
---@field GRAVITY number             -- Schwerkraft
---@field camera_pos_y number        -- Aktuelle Kameraposition Y
---@field MINIMUM_HEIGHT_CATAPULT_PLATFORM number -- Mindesthöhe für Katapult-Plattformen
---@field MINIMUM_HEIGHT_BREAKABLE_PLATFORM number -- Mindesthöhe für zerstörbare Plattformen
---@field RANDOM_GENERATION_LIMIT_CATAPULT_PLATFORM number -- Spawnwahrscheinlichkeit Katapult-Plattform
---@field RANDOM_GENERATION_LIMIT_BREAKABLE_PLATFORM number -- Spawnwahrscheinlichkeit Breakable-Plattform
---@field SCREEN_HEIGHT number       -- Höhe des sichtbaren Bildschirms
---@field SCREEN_WIDTH number        -- Breite des sichtbaren Bildschirms
---@field SPAWN_BUFFER_Y number      -- Mindestabstand für Spawn-Lücken
---@field PLATFORM_DEFAULT_HEIGHT number -- Standardhöhe einer Plattform
---@field CLEANUP_MARGIN number      -- Extra-Margin für das Entfernen unterer Plattformen
---@field DEFAULT_GROUND_Y number    -- y-Koordinate der Bodenplattform
---@field ANCHOR_SPREAD number       -- Abstand zwischen mehreren Plattformen auf gleicher Höhe
---@field MAX_SPAWN_ATTEMPTS number  -- Maximale Versuche zur Platzierung einer Plattform
---@field MAX_PLATFORMS_EASY number  -- Max Plattformen pro Level (leicht)
---@field MAX_PLATFORMS_MEDIUM number -- Max Plattformen pro Level (mittel)
---@field MAX_PLATFORMS_HARD number -- Max Plattformen pro Level (schwer)
---@field DIFFICULTY_EASY number     -- Index für leicht
---@field DIFFICULTY_MEDIUM number   -- Index für mittel
---@field DIFFICULTY_HARD number     -- Index für schwer
local PlatformManager = {}

PlatformManager.__index = PlatformManager

---Initialisiert den PlatformManager
---@param difficulty number? optionaler Schwierigkeitsgrad
function PlatformManager:init(difficulty)
    -- Allgemeine Spiel-Parameter
    self.difficulty = difficulty or 1
    self.DEFAULT_JUMP_VELOCITY = 4.4
    self.GRAVITY = 0.22

    -- Platform-Tracking
    self.list = {}
    self.topmost_platform_y = 112
    self.last_platform_anchor_x = nil

    -- Plattform-Generierungsparameter
    self.MINIMUM_HEIGHT_CATAPULT_PLATFORM = 2000
    self.MINIMUM_HEIGHT_BREAKABLE_PLATFORM = 1000
    self.RANDOM_GENERATION_LIMIT_CATAPULT_PLATFORM = 0.20
    self.RANDOM_GENERATION_LIMIT_BREAKABLE_PLATFORM = 0.35
    self.PLATFORM_DEFAULT_HEIGHT = 6
    self.SPAWN_BUFFER_Y = 12
    self.ANCHOR_SPREAD = 18
    self.MAX_SPAWN_ATTEMPTS = 8
    self.CLEANUP_MARGIN = 16

    -- Bildschirm- und Layout-Parameter
    self.SCREEN_HEIGHT = 128
    self.SCREEN_WIDTH = 128
    self.DEFAULT_GROUND_Y = 120

    -- Anzahl Plattformen pro Schwierigkeitsgrad
    self.MAX_PLATFORMS_EASY = 3
    self.MAX_PLATFORMS_MEDIUM = 2
    self.MAX_PLATFORMS_HARD = 1
    self.DIFFICULTY_EASY = 1
    self.DIFFICULTY_MEDIUM = 2
    self.DIFFICULTY_HARD = 3

    -- Startplattform
    self:add_platform("ground", 0, self.DEFAULT_GROUND_Y, self.SCREEN_WIDTH, true)
end

---Erzeugt eine neue Instanz des PlatformManagers
---@param difficulty number? optionaler Schwierigkeitsgrad
---@return PlatformManager
function PlatformManager.new(difficulty)
    local self = setmetatable({}, PlatformManager)
    self:init(difficulty)
    return self
end

---Berechnet die Höhe eines Punkts relativ zum Boden
---@param pos_y number
---@return number
function PlatformManager:get_height_from_ground(pos_y)
    return max(0, self.DEFAULT_GROUND_Y - pos_y)
end

---Fügt eine Plattform hinzu
---@param kind string Plattformtyp ("default", "breakable", "catapult")
---@param pos_x number x-Koordinate
---@param pos_y number y-Koordinate
---@param width number Plattformbreite
---@param is_ground boolean? ob es sich um den Boden handelt
function PlatformManager:add_platform(kind, pos_x, pos_y, width, is_ground)
    local plat = PlatformFactory.create(kind or "default", pos_x, pos_y, width)
    plat.is_ground = is_ground or false
    add(self.list, plat)

    if pos_y < self.topmost_platform_y then
        self.topmost_platform_y = pos_y
    end
end

---Gibt den minimalen vertikalen Abstand zwischen Plattformen in Abhängigkeit von Höhe zurück
---@param pos_y number
---@return number
function PlatformManager:difficulty_at(pos_y)
    local height = self:get_height_from_ground(pos_y)
    local gap = self.SPAWN_BUFFER_Y + flr(height / 60)
    return clamp(gap, self.SPAWN_BUFFER_Y, 26)
end

---Berechnet die maximale Sprunghöhe basierend auf Gravitation und Standard-Jump
---@return number
function PlatformManager:get_max_jump_height()
    return (self.DEFAULT_JUMP_VELOCITY ^ 2) / (2 * self.GRAVITY)
end

---Bestimmt einen Faktor für die vertikale Reichweite abhängig von Höhe und Schwierigkeit
---@param at_pos_y number
---@param is_easy_mode boolean
---@return number
function PlatformManager:get_reach_factor(at_pos_y, is_easy_mode)
    if is_easy_mode then return 0.55 end
    local height = self:get_height_from_ground(at_pos_y)
    local step = flr(height / 80)
    local factor = 0.60 + step * 0.05
    return clamp(factor, 0.60, 0.90)
end

---Berechnet vertikale Spawn-Lücke für Plattformen
---@param at_pos_y number
---@param is_easy_mode boolean
---@return number
function PlatformManager:get_vertical_spawn_gap_reach(at_pos_y, is_easy_mode)
    return self:get_max_jump_height() * self:get_reach_factor(at_pos_y, is_easy_mode)
end

---Berechnet horizontale Reichweite für Spawn-Positionen
---@param at_pos_y number
---@param is_easy_mode boolean
---@return number
function PlatformManager:get_horizontal_reach(at_pos_y, is_easy_mode)
    local height = self:get_height_from_ground(at_pos_y)
    local base = is_easy_mode and 44 or 38
    local shrink = flr(height / 140) * 4
    return clamp(base - shrink, 22, 44)
end

---Maximale Plattformen pro Level je nach Schwierigkeitsgrad
---@param is_easy_mode boolean
---@return number
function PlatformManager:max_per_level(is_easy_mode)
    if is_easy_mode then return self.MAX_PLATFORMS_EASY end
    if self.difficulty == self.DIFFICULTY_EASY then return self.MAX_PLATFORMS_EASY end
    if self.difficulty == self.DIFFICULTY_MEDIUM then return self.MAX_PLATFORMS_MEDIUM end
    return self.MAX_PLATFORMS_HARD
end

---Prüft, ob eine neue Plattform mit existierenden kollidiert
---@param pos_x number
---@param pos_y number
---@param width number
---@param height number
---@return boolean
function PlatformManager:platform_overlaps_existing(pos_x, pos_y, width, height)
    height = height or self.PLATFORM_DEFAULT_HEIGHT
    for plat in all(self.list) do
        if pos_y < plat.pos_y + plat.height and pos_y + height > plat.pos_y then
            if pos_x < plat.pos_x + plat.width and pos_x + width > plat.pos_x then
                return true
            end
        end
    end
    return false
end

---Erzeugt eine neue Plattform basierend auf Höhe, Schwierigkeitsgrad und Zufall
---@param at_pos_y number
---@param is_easy_mode boolean
function PlatformManager:spawn_platform(at_pos_y, is_easy_mode)
    local height_from_ground = self:get_height_from_ground(at_pos_y)
    local width = is_easy_mode and 34 or clamp(28 - flr(height_from_ground / 90) * 4, 12, 28)

    local anchor_x = self.last_platform_anchor_x or 64
    local horizontal_reach = self:get_horizontal_reach(at_pos_y, is_easy_mode)

    local pos_x = nil
    for i = 1, self.MAX_SPAWN_ATTEMPTS do
        local new_pos_x = flr(rnd(horizontal_reach * 2 + 1) + (anchor_x - horizontal_reach))
        new_pos_x = (new_pos_x % self.SCREEN_WIDTH + self.SCREEN_WIDTH) % self.SCREEN_WIDTH
        new_pos_x = clamp(new_pos_x, 0, self.SCREEN_WIDTH - width)

        if not self:platform_overlaps_existing(new_pos_x, at_pos_y, width, self.PLATFORM_DEFAULT_HEIGHT) then
            pos_x = new_pos_x
            break
        end
    end

    if not pos_x then
        self.topmost_platform_y = at_pos_y
        return
    end

    self.last_platform_anchor_x = pos_x + width / 2

    local kind = "default"
    if not is_easy_mode then
        local random_number = rnd()
        if height_from_ground >= self.MINIMUM_HEIGHT_CATAPULT_PLATFORM and random_number < self.RANDOM_GENERATION_LIMIT_CATAPULT_PLATFORM then
            kind = "catapult"
        elseif height_from_ground >= self.MINIMUM_HEIGHT_BREAKABLE_PLATFORM and random_number < self.RANDOM_GENERATION_LIMIT_BREAKABLE_PLATFORM then
            kind = "breakable"
        end
    end

    self:add_platform(kind, pos_x, at_pos_y, width, false)
end

---Aktualisiert Plattformen: erzeugt neue und entfernt alte
---@param camera_pos_y number
function PlatformManager:update(camera_pos_y)
    local top_needed = camera_pos_y - (self.SCREEN_HEIGHT + self.SPAWN_BUFFER_Y)

    while self.topmost_platform_y > top_needed do
        local vertical_gap = clamp(self:get_vertical_spawn_gap_reach(self.topmost_platform_y, false), 10, 28)
        local next_pos_y = self.topmost_platform_y - flr(vertical_gap)

        local number_of_max_per_level = self:max_per_level(false)
        local saved_anchor = self.last_platform_anchor_x
        for i = 1, number_of_max_per_level do
            if saved_anchor then
                self.last_platform_anchor_x = saved_anchor +
                    (i - ((number_of_max_per_level + 1) / 2)) * self.ANCHOR_SPREAD
            end
            self:spawn_platform(next_pos_y, false)
        end
        self.last_platform_anchor_x = saved_anchor
        self.topmost_platform_y = next_pos_y
    end

    local visible_bottom_y = camera_pos_y + self.SCREEN_HEIGHT
    for i = #self.list, 1, -1 do
        local plat = self.list[i]
        if plat.is_dead or plat.pos_y > visible_bottom_y + self.CLEANUP_MARGIN then
            del(self.list, plat)
        end
    end
end

---Zeichnet alle Plattformen auf den Bildschirm
function PlatformManager:draw()
    for plat in all(self.list) do
        plat:draw()
    end
end

---Prüft, ob der Spieler auf einer Plattform landet
---@param player table Spieler-Objekt mit pos_x, pos_y, width, height, velocity_y
---@param previous_pos_y number
---@return table|nil die Plattform, auf der der Spieler gelandet ist
function PlatformManager:check_landing(player, previous_pos_y)
    if player.velocity_y <= 0 then return false end

    local foot_previous = previous_pos_y + player.height
    local foot_now = player.pos_y + player.height

    for plat in all(self.list) do
        if player.pos_x + player.width > plat.pos_x and player.pos_x < plat.pos_x + plat.width then
            if foot_previous <= plat.pos_y and foot_now >= plat.pos_y then
                player.pos_y = plat.pos_y - player.height
                player.velocity_y = 0
                plat:on_land(player)
                return plat
            end
        end
    end
end
