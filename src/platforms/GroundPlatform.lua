---
--- Plattformtyp für den Boden (Startplattform).
--- Erbt von Platform und stellt eine höhere, visuell unterscheidbare Plattform dar.
---
---@class GroundPlatform : Platform
local GroundPlatform = {}
GroundPlatform.__index = GroundPlatform
setmetatable(GroundPlatform, Platform)

---
--- Erstellt eine neue Bodenplattform.
--- Diese Plattform ist höher als normale Plattformen und dient als Startbereich.
---
---@param pos_x number
---@param pos_y number
---@param width number
---@return GroundPlatform
function GroundPlatform.new(pos_x, pos_y, width)
    local self = Platform.new(pos_x, pos_y, width)

    self.height = 8
    self.fill_color = 4
    self.border_color = 3

    return setmetatable(self, GroundPlatform)
end
