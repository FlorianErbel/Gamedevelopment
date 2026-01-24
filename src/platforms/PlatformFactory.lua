---
--- PlatformFactory class
--- Erstellt Plattformen verschiedener Typen anhand des angegebenen Kinds
---

---@class PlatformFactory
---@field public name string Name der Factory
local PlatformFactory = {}
PlatformFactory.__index = PlatformFactory

---Konstruktor der Factory
---@param name string optionaler Name der Factory
---@return PlatformFactory
function PlatformFactory.new(name)
    local self = setmetatable({}, PlatformFactory)
    self.name = name or "PlatformFactory"
end

---Erstellt eine Plattform des angegebenen Typs an der Position (pos_x, pos_y) mit gegebener Breite
---@param kind string Plattformtyp (siehe PlatformType ENUM)
---@param pos_x number X-Position der Plattform
---@param pos_y number Y-Position der Plattform
---@param width number Breite der Plattform
---@return Platform
function PlatformFactory.create(kind, pos_x, pos_y, width)
    if kind == PlatformType.DEFAULT then
        return DefaultPlatform.new(pos_x, pos_y, width)
    elseif kind == PlatformType.CATAPULT then
        return CatapultPlatform.new(pos_x, pos_y, width)
    elseif kind == PlatformType.BREAKABLE then
        return BreakablePlatform.new(pos_x, pos_y, width)
    elseif kind == PlatformType.GROUND then
        return GroundPlatform.new(pos_x, pos_y, width)
    end
end
