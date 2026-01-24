enemies = {}
function enemies:init()
    self.enemies_list = {}
end

-- AABB collision
local function aabb(player_pos_x, player_pos_y, player_width, player_height, enemie_pos_x, enemie_pos_y, enemie_width,
                    enemie_height)
    return player_pos_x < enemie_pos_x + enemie_width and player_pos_x + player_width > enemie_pos_x and
        player_pos_y < enemie_pos_y + enemie_height and player_pos_y + player_height > enemie_pos_y
end

function enemies:max_alive(difficulty)
    if difficulty == 1 then return 1 end
    if difficulty == 2 then return 2 end
    return 3
end

-- spawnchance pro "platform level"
-- TODO: Was bedeuten die Verknüpfungen bei der difficulty?
function enemies:spawn_prob(difficulty, height)
    local base = (difficulty == 1 and 0.05) or (difficulty == 2 and 0.08) or 0.12
    -- height wächst mit fortschritt; langsam ansteigen lassen
    local hf = clamp(height / 800, 0, 1) * 0.18 -- +0..0.18
    local p = base + hf
    return min(p, 0.35)
end

-- platform: table {x,y,w,h}
function enemies:try_spawn_on_platform(platform, difficulty, height)
    if not self.enemies_list then self.enemies_list = {} end
    if #self.enemies_list >= self:max_alive(difficulty) then return end
    if platform.ground then return end
    if platform.w < 18 then return end -- zu klein für igel-laufen

    local probability = self:spawn_prob(difficulty, height)

    if rnd() < probability then
        local new_enemie = {
            kind = "hedgehog",
            plat = platform, -- referenz
            width = 8,
            height = 6,
            direction = (rnd() < 0.5) and -1 or 1,
            speed = (difficulty == 1 and 0.45) or (difficulty == 2 and 0.6) or 0.8,
            pos_x = platform.pos_x + 4,
            pos_y = platform.pos_y - 6,
            is_alive = true
        }
        add(self.enemies_list, new_enemie)
    end
end

function enemies:update()
    for i = #self.enemies_list, 1, -1 do
        local enemie = self.enemies_list[i]
        if not enemie.is_alive then
            del(self.enemies_list, enemie)
        else
            local plat = enemie.plat
            -- falls plattform gelöscht wurde: entfernen
            if not plat then
                del(self.enemies_list, enemie)
            else
                -- y an plattform binden
                enemie.pos_y = plat.pos_y - enemie.height

                -- hin und her laufen auf der plattform
                enemie.pos_x = enemie.pos_x + enemie.direction * enemie.speed
                local left = plat.pos_x
                local right = plat.pos_x + plat.width - enemie.width
                if enemie.pos_x < left then
                    enemie.pos_x = left; enemie.direction = 1
                end
                if enemie.pos_x > right then
                    enemie.pos_x = right; enemie.direction = -1
                end
            end
        end
    end
end

function enemies:draw()
    for enemie in all(self.enemies_list) do
        -- einfacher "igel": kleiner block + stacheln
        rectfill(enemie.pos_x, enemie.pos_y, enemie.pos_x + enemie.width - 1, enemie.pos_y + enemie.height - 1, 4)
        -- stacheln oben
        pset(enemie.pos_x + 1, enemie.pos_y - 1, 0)
        pset(enemie.pos_x + 3, enemie.pos_y - 2, 0)
        pset(enemie.pos_x + 5, enemie.pos_y - 1, 0)
    end
end

function enemies:player_hit(player)
    for enemie in all(self.enemies_list) do
        if aabb(player.pos_x, player.pos_y, player.width, player.height, enemie.pos_x, enemie.pos_y, enemie.width, enemie.height) then
            return true
        end
    end
    return false
end

function enemies:shots_hit(player)
    local shots = player.shots
    if not shots then return 0 end

    local kills = 0

    -- rückwärts, weil wir löschen
    for i = #shots, 1, -1 do
        local shot = shots[i]

        -- Shot als kleines AABB behandeln
        local shot_pos_x = shot.pos_x - 2
        local shot_pos_y = shot.pos_y - 2
        local shot_width = 4
        local shot_height = 4

        local hit = false

        for j = #self.enemies_list, 1, -1 do
            local enemie = self.enemies_list[j]

            if enemie.is_alive then
                if shot_pos_x < enemie.pos_x + enemie.width
                    and shot_pos_x + shot_width > enemie.pos_x
                    and shot_pos_y < enemie.pos_y + enemie.height
                    and shot_pos_y + shot_height > enemie.pos_y then
                    -- Enemy stirbt
                    enemie.is_alive = false
                    del(self.enemies_list, enemie)

                    hit = true
                    kills = kills + 1
                    break
                end
            end
        end

        -- Shot verbrauchen
        if hit then
            del(shots, shot)
        end
    end

    return kills
end
