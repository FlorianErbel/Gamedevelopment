---
--- breakablePlatform class
--- Created by florianerbel
--- DateTime: 15.01.26 12:36
---

---@class breakablePlatform
---@field public name string
local breakablePlatform = {}
breakablePlatform.__index = breakablePlatform

---Constructor
---@param name string
---@return breakablePlatform
function breakablePlatform.new(name)
    local self = setmetatable({}, breakablePlatform)
    self.name = name or "breakablePlatform"
    return self
end

return breakablePlatform
