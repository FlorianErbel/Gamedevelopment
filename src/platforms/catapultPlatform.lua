---
--- catapultPlatform class
--- Created by florianerbel
--- DateTime: 15.01.26 12:36
---

---@class catapultPlatform
---@field public name string
local catapultPlatform = {}
catapultPlatform.__index = catapultPlatform

---Constructor
---@param name string
---@return catapultPlatform
function catapultPlatform.new(name)
    local self = setmetatable({}, catapultPlatform)
    self.name = name or "jumpPlatform"
    return self
end

return catapultPlatform
