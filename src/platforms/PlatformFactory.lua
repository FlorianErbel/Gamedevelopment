---
--- PlatformFactory class
--- Created by florianerbel
--- DateTime: 15.01.26 16:16
---

---@class PlatformFactory
---@field public name string
local PlatformFactory = {}
PlatformFactory.__index = PlatformFactory

---Constructor
---@param name string
---@return PlatformFactory
function PlatformFactory.new(name)
    local self = setmetatable({}, PlatformFactory)
    self.name = name or "PlatformFactory"
    return self
end

function PlatformFactory.create(kind, pos_x, pos_y, width)
    if kind == "default" then
        return DefaultPlatform.new(pos_x, pos_y, width)
    elseif kind == "catapult" then
        return CatapultPlatform.new(pos_x, pos_y, width)
    elseif kind == "breakable" then
        return BreakablePlatform.new(pos_x, pos_y, width)
    elseif kind == "starting" then
        return StartingPlatform.new(pos_x, pos_y, width)
    end
end
