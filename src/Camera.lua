cam = {}

function cam:init()
    self.y = 0
    self.target_y = 0
end

-- wir wollen, dass die höchste erreichte stelle auf ~20% des screens ist
-- 20% von 128 ≈ 26
function cam:update(player)
    local target_screen_y = 90
    local desired = player.best_landed_y - target_screen_y

    if desired < self.target_y then
        self.target_y = desired
    end

    self.y = lerp(self.y, self.target_y, 0.15)
end

function cam:apply()
    camera(0, self.y)
end

function cam:reset()
    camera()
end
