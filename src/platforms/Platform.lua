---
--- Platform class
--- Created by florianerbel
--- DateTime: 15.01.26 15:39
--- Template class to enable using the template pattern
---

---@class Platform
---@field public name string
local Platform = {}
Platform.__index = Platform

---Constructor
---@param name string
---@return Platform
function Platform.new(pos_x, pos_y, width)
    local self = setmetatable({}, Platform)
    self.pos_x = pos_x
    self.pos_y = pos_y
    self.width = width
    self.height = 4
    self.is_dead = false
    self.fill_color = 11
    self.border_color = 3
    return self
end

function Platform:on_land(player)
    -- Default: nichts
end

function Platform:update()
    -- Default: nichts
end

function Platform:draw()
    rectfill(self.pos_x, self.pos_y, self.pos_x + self.width - 1, self.pos_y + self.height - 1, self.fill_color)
    rect(self.pos_x, self.pos_y, self.pos_x + self.width - 1, self.pos_y + self.height - 1, self.border_color)
end
