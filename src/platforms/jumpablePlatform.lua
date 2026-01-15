---
--- jumpablePlatform class
--- Created by florianerbel
--- DateTime: 15.01.26 12:36
---

---@class jumpablePlatform
---@field public name string
local jumpablePlatform = {}
jumpablePlatform.__index = jumpablePlatform

---Constructor
---@param name string
---@return jumpablePlatform
function jumpablePlatform.new(name)
    local self = setmetatable({}, jumpablePlatform)
    self.name = name or "jumpPlatform"
    return self
end

return jumpablePlatform
