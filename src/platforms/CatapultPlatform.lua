---
--- Katapultplattform.
--- Verleiht dem Spieler beim Landen einen einmaligen Sprung-Boost.
---

---@class CatapultPlatform : Platform
---@field boost_factor number -- Multiplikator für die Sprunghöhe
local CatapultPlatform = {}
CatapultPlatform.__index = CatapultPlatform
setmetatable(CatapultPlatform, Platform)

---
--- Erstellt eine neue Katapultplattform.
--- Die Plattform setzt beim Landen einen temporären Sprung-Boost am Spieler.
---
---@param pos_x number -- Linke X-Position der Plattform
---@param pos_y number -- Y-Position der Plattform (Weltkoordinaten)
---@param width number -- Breite der Plattform
---@return CatapultPlatform
function CatapultPlatform.new(pos_x, pos_y, width)
    local self = Platform.new(pos_x, pos_y, width)
    self.fill_color = 13
    self.border_color = 12
    self.boost_factor = 1.3
    return setmetatable(self, CatapultPlatform)
end

---
--- Wird aufgerufen, wenn der Spieler auf der Plattform landet.
--- Aktiviert einen einmaligen Sprung-Boost beim nächsten Sprung.
---
---@param player Player -- Referenz auf den Spieler
function CatapultPlatform:on_land(player)
    player.jump_boost_factor = self.boost_factor
    player.is_jump_boost_used = true
end
