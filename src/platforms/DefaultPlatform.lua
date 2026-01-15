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
function DefaultPlatform.new(pos_x, pos_y, width)
    local self = Platform.new(pos_x, pos_y, width)
    return setmetatable(self, DefaultPlatform)
end
