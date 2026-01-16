---
--- BreakablePlatform class
--- Created by florianerbel
--- DateTime: 15.01.26 16:04
---

---@class BreakablePlatform
local BreakablePlatform = {}
BreakablePlatform = setmetatable({}, Platform)
BreakablePlatform.__index = BreakablePlatform

---Constructor
---@param pos_x number
---@param pos_y number
---@param width number
---@return BreakablePlatform
function BreakablePlatform.new(pos_x, pos_y, width)
    local self = Platform.new(pos_x, pos_y, width)
    self.fill_color = 4
    self.border_color = 5
    return setmetatable(self, BreakablePlatform)
end

function BreakablePlatform:on_land(player)
    self.is_dead = true
end

function BreakablePlatform:draw()
    rectfill(self.pos_x, self.pos_y, self.pos_x + self.width - 1, self.pos_y + self.height - 1, self.fill_color)
end
