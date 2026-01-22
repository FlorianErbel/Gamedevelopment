---
--- Shot class
--- Created by florianerbel
--- DateTime: 22.01.26 08:38
---

---@class Shot
---@field public name string
local Shot = {}
Shot.__index = Shot

---Constructor
---@param name string
---@return Shot
function Shot.new(name)
    local self = setmetatable({}, Shot)
    self.name = name or "Shot"
    return self
end

return Shot
