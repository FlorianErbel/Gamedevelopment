cam = {}

function cam:init()
    self.pos_y = 0
    self.target_pos_y = 0
end

-- wir wollen, dass die höchste erreichte stelle auf ~20% des screens ist
-- 20% von 128 ≈ 26
function cam:update(player)
    local target_screen_pos_y = 120
    local desired = player.best_landed_pos_y - target_screen_pos_y

    if desired < self.target_pos_y then
        self.target_pos_y = desired
    end

    self.pos_y = lerp(self.pos_y, self.target_pos_y, 0.15)
end

function cam:apply()
    camera(0, self.pos_y)
end

function cam:reset()
    camera()
end
