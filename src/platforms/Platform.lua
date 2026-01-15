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
function Platform.new(name)
    local self = setmetatable({}, Platform)
    self.x = x
    self.y = y
    self.w = w
    self.h = 4
    self.dead = false
    return self
end

function Platform:on_land(player)
    -- Default: nichts
end

function Platform:update()
end

function Platform:draw()
    rectfill(self.x, self.y, self.x + self.w - 1, self.y + self.h - 1, 11)
    rect(self.x, self.y, self.x + self.w - 1, self.y + self.h - 1, 3)
end

---return Platform
