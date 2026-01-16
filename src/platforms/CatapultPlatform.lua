---
--- CatapultPlatform class
--- Created by florianerbel
--- DateTime: 15.01.26 16:00
---Class to create platforms which enable a jump-boost to the player
---

---@class CatapultPlatform
local CatapultPlatform = {}
CatapultPlatform = setmetatable({}, Platform)
CatapultPlatform.__index = CatapultPlatform

---Constructor
---@param pos_x number
---@param pos_y number
---@param width number
---@return CatapultPlatform
function CatapultPlatform.new(pos_x, pos_y, width)
    local self = Platform.new(pos_x, pos_y, width)
    self.fill_color = 12
    self.border_color = 12
    self.boost_factor = 1.3
    return setmetatable(self, CatapultPlatform)
end

function CatapultPlatform:on_land(player)
    player.jump_boost_factor = self.boost_factor
    player.is_jump_boost_used = true
end
