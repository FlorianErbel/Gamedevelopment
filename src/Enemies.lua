enemies = {}

function enemies:init()
    self.list = {}
end

-- AABB collision
-- TODO: Umbenennen der Variablen in verständliche Variablen --> Lars fragen, was was sein soll
local function aabb(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and ax + aw > bx and ay < by + bh and ay + ah > by
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
    if not self.list then self.list = {} end
    if #self.list >= self:max_alive(difficulty) then return end
    if platform.ground then return end
    if platform.w < 18 then return end -- zu klein für igel-laufen

-- TODO: p = player, propability oder plat?
    local p = self:spawn_prob(difficulty, height)

    -- TODO: Wenn wir die Kontrolle umdrehen und den folgenden Code-Block hier einbauen, kommen wir dann nicht zum selben Erbenis, nur ohne den Funktionsabbruch (return)
    if rnd() > p then return end

    local new_enemie = {
        kind = "hedgehog",
        plat = platform, -- referenz
        w = 8,
        h = 6,
        dir = (rnd() < 0.5) and -1 or 1,
        speed = (difficulty == 1 and 0.45) or (difficulty == 2 and 0.6) or 0.8,
        x = platform.x + 4,
        y = platform.y - 6,
        alive = true
    }
    add(self.list, new_enemie)
end

function enemies:update()
    for i = #self.list, 1, -1 do
        local enemies = self.list[i]
        if not enemies.alive then
            del(self.list, enemies)
        else
            local plat = enemies.plat
            -- falls plattform gelöscht wurde: entfernen
            if not plat then
                del(self.list, enemies)
            else
                -- y an plattform binden
                enemies.y = plat.y - enemies.h

                -- hin und her laufen auf der plattform
                enemies.x = enemies.x + enemies.dir * enemies.speed
                local left = plat.x
                local right = plat.x + plat.w - enemies.w
                if enemies.x < left then
                    enemies.x = left; enemies.dir = 1
                end
                if enemies.x > right then
                    enemies.x = right; enemies.dir = -1
                end
            end
        end
    end
end

function enemies:draw()
    for enemie in all(self.list) do
        -- einfacher "igel": kleiner block + stacheln
        rectfill(enemie.x, enemie.y, enemie.x + enemie.w - 1, enemie.y + enemie.h - 1, 4)
        -- stacheln oben
        pset(enemie.x + 1, enemie.y - 1, 0)
        pset(enemie.x + 3, enemie.y - 2, 0)
        pset(enemie.x + 5, enemie.y - 1, 0)
    end
end

function enemies:player_hit(player)
    for e in all(self.list) do
        if aabb(player.x, player.y, player.w, player.h, e.x, e.y, e.w, e.h) then
            return true
        end
    end
    return false
end

function enemies:shots_hit(player)
    -- player.shots ist die projektil-liste
    local shots = player.shots
    if not shots then return 0 end

    local kills = 0

    for si = #shots, 1, -1 do
        local s = shots[si]
        -- treat shot as small box
        local sx, sy = s.x - 2, s.y - 2
        local sw, sh = 4, 4

        local hit = false

        for ei = #self.list, 1, -1 do
            local e = self.list[ei]
            if e.alive then
                if sx < e.x + e.w and sx + sw > e.x and sy < e.y + e.h and sy + sh > e.y then
                    -- kill enemy + consume shot
                    e.alive = false
                    del(self.list, e)
                    hit = true
                    kills = kills + 1
                    break
                end
            end
        end

        if hit then
            del(shots, s)
        end
    end

    return kills
end
