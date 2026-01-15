---
--- BreakablePlatform class
--- Created by florianerbel
--- DateTime: 15.01.26 16:04
---

---@class BreakablePlatform
---@field public name string
local BreakablePlatform = {}
BreakablePlatform = setmetatable({}, Platform)
BreakablePlatform.__index = BreakablePlatform

---Constructor
---@param name string
---@return BreakablePlatform
---function BreakablePlatform.new(name)
---local self = setmetatable({}, BreakablePlatform)
---self.name = name or "BreakablePlatform"
--- return self
---end

function BreakablePlatform:on_land(player)
    self.dead = true
end

function BreakablePlatform:draw()
    rectfill(self.x, self.y, self.x + self.w - 1, self.y + self.h - 1, 8)
end

---return BreakablePlatform
