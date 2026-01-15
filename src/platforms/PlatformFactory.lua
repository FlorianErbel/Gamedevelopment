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

function PlatformFactory.create(kind, x, y, w)
    if kind == "default" then
        return DefaultPlatform.new(x, y, w)
    elseif kind == "catapult" then
        return CatapultPlatform.new(x, y, w)
    elseif kind == "breakable" then
        return BreakablePlatform.new(x, y, w)
    end
end
