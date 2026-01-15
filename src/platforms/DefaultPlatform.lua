---
--- DefaultPlatform class
--- Created by florianerbel
--- DateTime: 15.01.26 15:56
---

---@class DefaultPlatform
---@field public name string
local DefaultPlatform = {}
DefaultPlatform = setmetatable({}, Platform)
DefaultPlatform.__index = DefaultPlatform

---Constructor
---@param name string
---@return DefaultPlatform
function DefaultPlatform.new(x, y, w)
    local self = Platform.new(x, y, w)
    return setmetatable(self, DefaultPlatform)
end

---return DefaultPlatform
