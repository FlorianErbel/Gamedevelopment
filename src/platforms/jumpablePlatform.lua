---
--- jumpPlatform class
--- Created by florianerbel
--- DateTime: 15.01.26 12:36
---

---@class jumpPlatform
---@field public name string
local jumpPlatform = {}
jumpPlatform.__index = jumpPlatform

---Constructor
---@param name string
---@return jumpPlatform
function jumpPlatform.new(name)
    local self = setmetatable({}, jumpPlatform)
    self.name = name or "jumpPlatform"
    return self
end

return jumpPlatform
