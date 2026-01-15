---
--- StartingPlatform class
--- Created by erbel
--- DateTime: 15.01.2026 20:02
---

---@class StartingPlatform
---@field public name string
local StartingPlatform = {}
StartingPlatform.__index = StartingPlatform

---Constructor
---@param name string
---@return StartingPlatform
function StartingPlatform.new(name)
    local self = setmetatable({}, StartingPlatform)
    self.name = name or "StartingPlatform"
    return self
end

return StartingPlatform
