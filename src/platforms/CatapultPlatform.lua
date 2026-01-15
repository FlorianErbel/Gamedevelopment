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
function CatapultPlatform.new(x, y, w)
    local self = Platform.new(x, y, w)
    self.boost = -6.8
    return setmetatable(self, CatapultPlatform)
end

function CatapultPlatform:on_land(player)
    player.vy = self.boost
end