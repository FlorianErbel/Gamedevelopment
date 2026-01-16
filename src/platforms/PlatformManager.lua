---@class PlatformManager
---@field list table                 -- Liste aller Plattformen
---@field topmost_platform_y number  -- y-Koordinate der höchstgelegenen Plattform
---@field last_platform_anchor_x number -- Letzte x-Koordinate als Anker für neue Plattformen
---@field difficulty number           -- Schwierigkeitsgrad
---@field default_jump_velocity number -- Standard-Sprunggeschwindigkeit des Spielers
---@field gravity number             -- Schwerkraft
---@field camera_pos_y number        -- Aktuelle Kameraposition Y
---@field minimum_height_catapult_platform number -- Mindesthöhe für Katapult-Plattformen
---@field minimum_height_breakable_platform number -- Mindesthöhe für zerstörbare Plattformen
---@field random_generation_limit_catapult_platform number -- Spawnwahrscheinlichkeit Katapult-Plattform
---@field random_generation_limit_breakable_platform number -- Spawnwahrscheinlichkeit Breakable-Plattform
---@field screen_height number       -- Höhe des sichtbaren Bildschirms
---@field screen_width number        -- Breite des sichtbaren Bildschirms
---@field spawn_buffer_y number      -- Mindestabstand für Spawn-Lücken
---@field platform_default_height number -- Standardhöhe einer Plattform
---@field cleanup_margin number      -- Extra-Margin für das Entfernen unterer Plattformen
---@field default_ground_y number    -- y-Koordinate der Bodenplattform
---@field anchor_spread number       -- Abstand zwischen mehreren Plattformen auf gleicher Höhe
---@field max_spawn_attempts number  -- Maximale Versuche zur Platzierung einer Plattform
---@field max_platforms_easy number  -- Max Plattformen pro Level (leicht)
---@field max_platforms_medium number -- Max Plattformen pro Level (mittel)
---@field max_platforms_hard number -- Max Plattformen pro Level (schwer)
---@field difficulty_easy number     -- Index für leicht
---@field difficulty_medium number   -- Index für mittel
---@field difficulty_hard number     -- Index für schwer
local PlatformManager = {}

PlatformManager.__index = PlatformManager

---Initialisiert den PlatformManager
---@param difficulty number? optionaler Schwierigkeitsgrad
function PlatformManager:init(difficulty)
    -- Allgemeine Spiel-Parameter
    self.difficulty = difficulty or 1
    self.default_jump_velocity = 4.4
    self.gravity = 0.22

    -- Platform-Tracking
    self.list = {}
    self.topmost_platform_y = 112
    self.last_platform_anchor_x = nil

    -- Plattform-Generierungsparameter
    self.minimum_height_catapult_platform = 2000
    self.minimum_height_breakable_platform = 1000
    self.random_generation_limit_catapult_platform = 0.20
    self.random_generation_limit_breakable_platform = 0.35
    self.platform_default_height = 6
    self.spawn_buffer_y = 12
    self.anchor_spread = 18
    self.max_spawn_attempts = 8
    self.cleanup_margin = 16

    -- Bildschirm- und Layout-Parameter
    self.screen_height = 128
    self.screen_width = 128
    self.default_ground_y = 120

    -- Anzahl Plattformen pro Schwierigkeitsgrad
    self.max_platforms_easy = 3
    self.max_platforms_medium = 2
    self.max_platforms_hard = 1
    self.difficulty_easy = 1
    self.difficulty_medium = 2
    self.difficulty_hard = 3

    -- Startplattform
    self:add_platform("ground", 0, self.default_ground_y, self.screen_width, true)
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
    return max(0, self.default_ground_y - pos_y)
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
    local gap = self.spawn_buffer_y + flr(height / 60)
    return clamp(gap, self.spawn_buffer_y, 26)
end

---Berechnet die maximale Sprunghöhe basierend auf Gravitation und Standard-Jump
---@return number
function PlatformManager:get_max_jump_height()
    return (self.default_jump_velocity ^ 2) / (2 * self.gravity)
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
    if is_easy_mode then return self.max_platforms_easy end
    if self.difficulty == self.difficulty_easy then return self.max_platforms_easy end
    if self.difficulty == self.difficulty_medium then return self.max_platforms_medium end
    return self.max_platforms_hard
end

---Prüft, ob eine neue Plattform mit existierenden kollidiert
---@param pos_x number
---@param pos_y number
---@param width number
---@param height number
---@return boolean
function PlatformManager:platform_overlaps_existing(pos_x, pos_y, width, height)
    height = height or self.platform_default_height
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
    for i = 1, self.max_spawn_attempts do
        local new_pos_x = flr(rnd(horizontal_reach * 2 + 1) + (anchor_x - horizontal_reach))
        new_pos_x = (new_pos_x % self.screen_width + self.screen_width) % self.screen_width
        new_pos_x = clamp(new_pos_x, 0, self.screen_width - width)

        if not self:platform_overlaps_existing(new_pos_x, at_pos_y, width, self.platform_default_height) then
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
        if height_from_ground >= self.minimum_height_catapult_platform and random_number < self.random_generation_limit_catapult_platform then
            kind = "catapult"
        elseif height_from_ground >= self.minimum_height_breakable_platform and random_number < self.random_generation_limit_breakable_platform then
            kind = "breakable"
        end
    end

    self:add_platform(kind, pos_x, at_pos_y, width, false)
end

---Aktualisiert Plattformen: erzeugt neue und entfernt alte
---@param camera_pos_y number
function PlatformManager:update(camera_pos_y)
    local top_needed = camera_pos_y - (self.screen_height + self.spawn_buffer_y)

    while self.topmost_platform_y > top_needed do
        local vertical_gap = clamp(self:get_vertical_spawn_gap_reach(self.topmost_platform_y, false), 10, 28)
        local next_pos_y = self.topmost_platform_y - flr(vertical_gap)

        local number_of_max_per_level = self:max_per_level(false)
        local saved_anchor = self.last_platform_anchor_x
        for i = 1, number_of_max_per_level do
            if saved_anchor then
                self.last_platform_anchor_x = saved_anchor +
                    (i - ((number_of_max_per_level + 1) / 2)) * self.anchor_spread
            end
            self:spawn_platform(next_pos_y, false)
        end
        self.last_platform_anchor_x = saved_anchor
        self.topmost_platform_y = next_pos_y
    end

    local visible_bottom_y = camera_pos_y + self.screen_height
    for i = #self.list, 1, -1 do
        local plat = self.list[i]
        if plat.is_dead or plat.pos_y > visible_bottom_y + self.cleanup_margin then
            del(self.list, plat)
        end
    end
end

---Zeichnet alle Plattformen auf den Bildschirm
function PlatformManager:draw()
    for plat in all(self.list) do
        if plat.ground then
            rectfill(plat.pos_x, plat.pos_y, plat.pos_x + plat.width - 1, plat.pos_y + plat.height - 1, 5)
        else
            rectfill(plat.pos_x, plat.pos_y, plat.pos_x + plat.width - 1, plat.pos_y + plat.height - 1, plat.fill_color)
            rect(plat.pos_x, plat.pos_y, plat.pos_x + plat.width - 1, plat.pos_y + plat.height - 1, plat.border_color)
        end
    end
end

---Prüft, ob der Spieler auf einer Plattform landet
---@param player table Spieler-Objekt mit pos_x, pos_y, width, height, vy
---@param previous_pos_y number
---@return table|nil die Plattform, auf der der Spieler gelandet ist
function PlatformManager:check_landing(player, previous_pos_y)
    if player.vy <= 0 then return false end

    local foot_previous = previous_pos_y + player.height
    local foot_now = player.pos_y + player.height

    for plat in all(self.list) do
        if player.pos_x + player.width > plat.pos_x and player.pos_x < plat.pos_x + plat.width then
            if foot_previous <= plat.pos_y and foot_now >= plat.pos_y then
                player.pos_y = plat.pos_y - player.height
                player.vy = 0
                plat:on_land(player)
                return plat
            end
        end
    end
end
