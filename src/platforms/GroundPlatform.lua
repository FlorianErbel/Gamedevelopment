---
--- GroundPlatform class
--- Created by florianerbel
--- DateTime: 15.01.26 20:56
---

---@class GroundPlatform
---@field public name string
local GroundPlatform = {}
GroundPlatform = setmetatable({}, Platform)
GroundPlatform.__index = GroundPlatform

---Constructor
---@param name string
---@return GroundPlatform
function GroundPlatform.new(pos_x, pos_y, width)
    local self = Platform.new(pos_x, pos_y, width)
    return setmetatable(self, GroundPlatform)
end