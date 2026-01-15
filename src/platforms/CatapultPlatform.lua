---
--- CatapultPlatform class
--- Created by florianerbel
--- DateTime: 15.01.26 16:00
---

---@class CatapultPlatform
---@field public name string
local CatapultPlatform = {}
CatapultPlatform = setmetatable({}, Platform)
CatapultPlatform.__index = CatapultPlatform

---Constructor
---@param name string
---@return CatapultPlatform
function CatapultPlatform.new(pos_x, pos_y, width)
    local self = Platform.new(pos_x, pos_y, width)
    self.fill_color = 12
    self.border_color = 12
    self.boost = -6.8
    return setmetatable(self, CatapultPlatform)
end

function CatapultPlatform:on_land(player)
    player.vy = self.boost
end