---
--- StartingPlatform class
--- Created by erbel
--- DateTime: 15.01.2026 20:02
---

---@class StartingPlatform
---@field public name string
local StartingPlatform = {}
StartingPlatform = setmetatable({}, Platform)
StartingPlatform.__index = StartingPlatform

---Constructor
---@param name string
---@return StartingPlatform
function StartingPlatform.new(pos_x, pos_y, width)
    local self = Platform.new(pos_x_pos_y, width)
    return setmetatable(self, StartingPlatform)
end