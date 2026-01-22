---@class Shot
---@field pos_x number
---@field pos_y number
---@field velocity_x number
---@field velocity_y number
---@field life number
local Shot = {}
Shot.__index = Shot

function Shot.new(x, y, vx, vy)
    local self = setmetatable({}, Shot)
    self.pos_x = x
    self.pos_y = y
    self.velocity_x = vx
    self.velocity_y = vy
    self.life = 60
    return self
end

function Shot:update()
    self.pos_x = self.pos_x + self.velocity_x
    self.pos_y = self.pos_y + self.velocity_y
    self.life = self.life - 1
end

function Shot:draw()
    circfill(self.pos_x, self.pos_y, 2, 10)
    pset(self.pos_x + 1, self.pos_y, 7)
end

function Shot:is_dead(cam_y)
    return self.life <= 0
        or self.pos_x < -4
        or self.pos_x > 132
        or self.pos_y < cam_y - 4
        or self.pos_y > cam_y + 132
end

