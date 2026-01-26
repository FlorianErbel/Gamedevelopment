-- Enemies.lua
-- Zentrales Enemy-Subsystem:
--  - Verwaltung aktiver Gegner
--  - Director-basierte Spawn-Planung (höhe- & difficulty-abhängig)
--  - Update-, Draw- und Interaktionslogik
--
-- Enemy-Typen:
--  - Hedgehog: läuft auf Plattformen, tödlich bei Berührung, abschießbar
--  - Bat: patrouilliert, pausiert bei Nähe, charged auf gespeicherte Spielerposition

enemies = {}

function enemies:init()
    self.enemies_list = {}

    -- Director: steuert Spawn-Abstände und Skalierung
    self.director = {
        next_spawn_height = 60,

        amplitude = 40,        -- Differenz zwischen min_gap und max_gap
        step_height = 1500,    -- Höhenintervall für Skalierung
        step_drop = 10,        -- Reduktion des max_gap pro Intervall

        -- Basiswerte pro Difficulty (bei geringer Höhe)
        base_max_by_diff = {
            [Difficulty.EASY] = 180,
            [Difficulty.MEDIUM] = 150,
            [Difficulty.HARD] = 130
        },

        -- Untergrenzen für min_gap
        min_floor_by_diff = {
            [Difficulty.EASY] = 60,
            [Difficulty.MEDIUM] = 40,
            [Difficulty.HARD] = 15
        }
    }

    -- Debug- und Testoptionen
    self.debug = {
        enabled = false,

        spawn_first = false,      -- erster Spawn garantiert
        did_first = false,
        force_plan = false,       -- ignoriert Höhenlogik
        force_kind = nil,         -- erzwingt Enemy-Typ
        ignore_max_alive = false, -- deaktiviert max_alive Limit
    }
end

-- -------------------------------------------------
-- Utility-Funktionen
-- -------------------------------------------------

local function aabb(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and ax + aw > bx and ay < by + bh and ay + ah > by
end

-- Prüft, ob ein Enemy deutlich unterhalb des sichtbaren Screens liegt
local function is_below_screen(enemie, cam_y, screen_h)
    local sy = enemie.pos_y - cam_y
    return sy > screen_h + 16
end

local function player_center(player)
    return player.pos_x + player.WIDTH/2, player.pos_y + player.HEIGHT/2
end

local function enemy_center(enemie)
    return enemie.pos_x + enemie.width/2, enemie.pos_y + enemie.height/2
end

-- Setzt nach einem Charge ein neues Patrol-Fenster um die aktuelle Position
local function reset_bat_patrol_around_current(enemie)
    enemie.base_y = enemie.pos_y

    local patrol_half = 18 + rnd(10)
    enemie.x1 = clamp(enemie.pos_x - patrol_half, 0, 128 - enemie.width)
    enemie.x2 = clamp(enemie.pos_x + patrol_half, 0, 128 - enemie.width)

    if enemie.x2 < enemie.x1 + 10 then
        enemie.x2 = min(128 - enemie.width, enemie.x1 + 10)
    end
end

-- -------------------------------------------------
-- Director / Limits
-- -------------------------------------------------

function enemies:max_alive(difficulty)
    if difficulty == 1 then return 1 end
    if difficulty == 2 then return 2 end
    if difficulty == 3 then return 4 end
end

-- Berechnet min/max Spawn-Abstände basierend auf Höhe & Difficulty
function enemies:director_gap(height_from_ground, difficulty)
    local amp = self.director.amplitude or 40
    local step_h = self.director.step_height or 1500
    local step_drop = self.director.step_drop or 10

    local base_max = self.director.base_max_by_diff[difficulty] or 150
    local floor_min = self.director.min_floor_by_diff[difficulty] or 40

    local steps = flr(height_from_ground / step_h)
    local max_gap = base_max - steps * step_drop
    local min_gap = max_gap - amp

    if min_gap < floor_min then
        min_gap = floor_min
        max_gap = floor_min + amp
    end

    if max_gap <= min_gap then
        max_gap = min_gap + 1
    end

    return min_gap, max_gap
end

-- Wählt Enemy-Typ abhängig von Höhe (Unlock + Gewichtung)
function enemies:choose_kind(height_from_ground)
    local unlock_hedgehog_height = 1000
    local unlock_bat_height = 4000
    local learn_height = 2000

    local choices = {}
    local total = 0

    local w_hedgehog = 0
    if height_from_ground >= unlock_hedgehog_height then
        w_hedgehog = 0.1 * clamp((height_from_ground - unlock_hedgehog_height) / learn_height, 0, 1)
        if w_hedgehog > 0 then
            add(choices, { kind="hedgehog", w=w_hedgehog })
            total = total + w_hedgehog
        end
    end

    local w_bat = 0
    if height_from_ground >= unlock_bat_height then
        w_bat = 0.3 * clamp((height_from_ground - unlock_bat_height) / learn_height, 0, 1)
        if w_bat > 0 then
            add(choices, { kind="bat", w=w_bat })
            total = total + w_bat
        end
    end

    if total <= 0 then return nil end

    local r = rnd(total)
    local acc = 0
    for item in all(choices) do
        acc = acc + item.w
        if r < acc then
            return item.kind
        end
    end

    return nil
end

-- -------------------------------------------------
-- Spawn-Planung
-- -------------------------------------------------
-- Entscheidet, ob ein Enemy geplant wird und welche Plattform-Anforderungen gelten
-- Rückgabe: nil oder { kind=..., platform_req={ min_width=... } }

function enemies:plan_next_spawn(difficulty, height_from_ground)
    if not (self.debug.enabled and self.debug.ignore_max_alive) then
        if #self.enemies_list >= self:max_alive(difficulty) then
            return nil
        end
    end

    if self.debug.enabled and self.debug.spawn_first and not self.debug.did_first then
        self.debug.did_first = true
        local k = self.debug.force_kind

        if not k then return nil end

        if k == "hedgehog" then
            return { kind = "hedgehog", platform_req = { min_width = 28 } }
        elseif k == "bat" then
            return { kind = "bat", platform_req = { min_width = 16 } }
        end
        return nil
    end

    if self.debug.enabled and self.debug.force_plan then
        local k = self.debug.force_kind or "hedgehog"
        if k == "hedgehog" then
            return { kind = "hedgehog", platform_req = { min_width = 28 } }
        elseif k == "bat" then
            return { kind = "bat", platform_req = { min_width = 16 } }
        end
        return nil
    end

    if height_from_ground < self.director.next_spawn_height then
        return nil
    end

    local min_gap, max_gap = self:director_gap(height_from_ground, difficulty)
    local gap = min_gap + rnd(max_gap - min_gap)
    self.director.next_spawn_height = height_from_ground + gap

    local k = self:choose_kind(height_from_ground)
    if self.debug.enabled and self.debug.force_kind then
        k = self.debug.force_kind
    end

    if k == "hedgehog" then
        return { kind = "hedgehog", platform_req = { min_width = 28 } }
    elseif k == "bat" then
        return { kind = "bat", platform_req = { min_width = 16 } }
    end
    return nil
end

-- -------------------------------------------------
-- Spawn
-- -------------------------------------------------

function enemies:spawn_from_plan(plan, plat, difficulty, height_from_ground)
    if not plan or not plat then return end
    if plat.is_ground then return end

    if plan.kind == "hedgehog" then
        if plat.width < 28 then return end

        local e = {
            kind = "hedgehog",
            plat = plat,

            width = 8,
            height = 6,

            direction = (rnd() < 0.5) and -1 or 1,
            speed = (difficulty == 1 and 0.45) or (difficulty == 2 and 0.6) or 0.8,

            pos_x = plat.pos_x + 4,
            pos_y = plat.pos_y - 6,

            is_alive = true
        }
        add(self.enemies_list, e)

    elseif plan.kind == "bat" then
        local cx = plat.pos_x + plat.width/2
        local base_y = plat.pos_y - 26

        local patrol_half = 18 + rnd(10)
        local x1 = cx - patrol_half
        local x2 = cx + patrol_half

        x1 = clamp(x1, 0, 128-8)
        x2 = clamp(x2, 0, 128-8)
        if x2 < x1 + 10 then
            x2 = min(128-8, x1 + 10)
        end

        local e = {
            kind = "bat",
            plat = plat,

            width = 8,
            height = 6,

            pos_x = cx,
            pos_y = base_y,

            x1 = x1,
            x2 = x2,
            base_y = base_y,
            dir = (rnd() < 0.5) and -1 or 1,
            speed = (difficulty == 1 and 0.55) or (difficulty == 2 and 0.75) or 0.95,

            wave_t = rnd(1),

            state = "patrol",
            timer = 0,
            target_x = cx,
            target_y = base_y,
            charge_speed = (difficulty == 1 and 2.2) or (difficulty == 2 and 2.6) or 3.0,

            trigger_dx = 32,
            trigger_dy = 28,

            is_alive = true
        }
        add(self.enemies_list, e)
    end
end

-- -------------------------------------------------
-- Update / Draw
-- -------------------------------------------------

function enemies:update(player)
    local cam_y = (cam and cam.pos_y) or 0
    local screen_h = 128

    for i = #self.enemies_list, 1, -1 do
        local enemie = self.enemies_list[i]

        if not enemie.is_alive then
            del(self.enemies_list, enemie)

        elseif is_below_screen(enemie, cam_y, screen_h) then
            del(self.enemies_list, enemie)

        else
            if enemie.kind == "hedgehog" then
                local plat = enemie.plat
                if not plat or plat.pos_y > (cam_y + screen_h + 16) then
                    del(self.enemies_list, enemie)
                else
                    enemie.pos_y = plat.pos_y - enemie.height
                    enemie.pos_x = enemie.pos_x + enemie.direction * enemie.speed

                    local left = plat.pos_x
                    local right = plat.pos_x + plat.width - enemie.width

                    if enemie.pos_x < left then
                        enemie.pos_x = left
                        enemie.direction = 1
                    elseif enemie.pos_x > right then
                        enemie.pos_x = right
                        enemie.direction = -1
                    end
                end

            elseif enemie.kind == "bat" then
                if enemie.plat and enemie.plat.pos_y > (cam_y + screen_h + 16) then
                    del(self.enemies_list, enemie)
                else
                    local px, py = player_center(player)
                    local ex, ey = enemy_center(enemie)

                    if enemie.state == "patrol" then
                        enemie.pos_x = enemie.pos_x + enemie.dir * enemie.speed
                        if enemie.pos_x < enemie.x1 then enemie.pos_x = enemie.x1; enemie.dir = 1 end
                        if enemie.pos_x > enemie.x2 then enemie.pos_x = enemie.x2; enemie.dir = -1 end

                        enemie.wave_t = enemie.wave_t + 0.05
                        enemie.pos_y = enemie.base_y + sin(enemie.wave_t) * 2

                        local dx = abs(px - ex)
                        local dy = abs(py - ey)
                        if dx < enemie.trigger_dx and dy < enemie.trigger_dy then
                            enemie.state = "pause"
                            enemie.timer = 60
                            enemie.target_x = px
                            enemie.target_y = py
                        end

                    elseif enemie.state == "pause" then
                        enemie.timer = enemie.timer - 1
                        if enemie.timer <= 0 then
                            enemie.state = "charge"
                            enemie.timer = 30
                        end

                    elseif enemie.state == "charge" then
                        local tx, ty = enemie.target_x, enemie.target_y
                        local vx = tx - ex
                        local vy = ty - ey
                        local d = sqrt(vx*vx + vy*vy)

                        if d < 2 then
                            enemie.state = "patrol"
                            reset_bat_patrol_around_current(enemie)
                        else
                            enemie.pos_x = enemie.pos_x + (vx/d) * enemie.charge_speed
                            enemie.pos_y = enemie.pos_y + (vy/d) * enemie.charge_speed
                            enemie.timer = enemie.timer - 1
                            if enemie.timer <= 0 then
                                enemie.state = "patrol"
                                reset_bat_patrol_around_current(enemie)
                            end
                        end
                    end
                end
            end
        end
    end
end

function enemies:draw()
    for enemie in all(self.enemies_list) do
        if enemie.kind == "hedgehog" then
            local x = enemie.pos_x
            local y = enemie.pos_y
            local w = enemie.width
            local h = enemie.height

            local dir = enemie.direction or -1
            local facing_right = dir > 0

            rectfill(x, y, x + w - 1, y + h - 1, 4)

            for sx = 0, w - 1, 2 do
                pset(x + sx, y - 1, 0)
                if (sx % 4) == 0 then
                    pset(x + sx, y - 2, 0)
                end
            end

            if facing_right then
                pset(x + w, y + 3, 0)
                pset(x + w - 3, y + 2, 7)
                pset(x + w - 3, y + 2, 0)
            else
                pset(x - 1, y + 3, 0)
                pset(x + 2, y + 2, 7)
                pset(x + 2, y + 2, 0)
            end

        elseif enemie.kind == "bat" then
            local x = enemie.pos_x
            local y = enemie.pos_y
            local w = enemie.width
            local h = enemie.height

            rectfill(x, y, x + w - 1, y + h - 1, 2)

            pset(x + 2, y + 2, 0)
            pset(x + 5, y + 2, 0)

            local flap = sin(enemie.wave_t or 0) * 2

            local wing_spread = 4
            if enemie.state == "pause" then
                wing_spread = 2
                flap = 0
            elseif enemie.state == "charge" then
                wing_spread = 1
                flap = -1
            end

            pset(x - 1, y + 2, 0)
            pset(x - 2, y + 2 + flap, 0)
            pset(x - 3, y + 3 + flap, 0)

            if wing_spread > 2 then
                pset(x - 4, y + 2 + flap, 0)
            else
                pset(x - 4, y + 4 + flap, 0)
            end

            if wing_spread >= 3 then
                pset(x - 5, y + 3 + flap, 0)
            end
            if wing_spread >= 4 then
                pset(x - 6, y + 4 + flap, 0)
            end

            pset(x + w,     y + 2, 0)
            pset(x + w + 1, y + 2 + flap, 0)
            pset(x + w + 2, y + 3 + flap, 0)

            if wing_spread > 2 then
                pset(x + w + 3, y + 2 + flap, 0)
            else
                pset(x + w + 3, y + 4 + flap, 0)
            end

            if wing_spread >= 3 then
                pset(x + w + 4, y + 3 + flap, 0)
            end
            if wing_spread >= 4 then
                pset(x + w + 5, y + 4 + flap, 0)
            end

            if enemie.state == "pause" then
                pset(x + 3, y - 3, 8)
            end
        end
    end
end

-- -------------------------------------------------
-- Interactions
-- -------------------------------------------------

function enemies:player_hit(player)
    for enemie in all(self.enemies_list) do
        if aabb(player.pos_x, player.pos_y, player.WIDTH, player.HEIGHT,
                enemie.pos_x, enemie.pos_y, enemie.width, enemie.height) then
            return true
        end
    end
    return false
end

function enemies:shots_hit(player)
    local shots = player.shots
    if not shots then return 0 end

    local kills = 0

    for i = #shots, 1, -1 do
        local shot = shots[i]

        local shot_pos_x = shot.pos_x - 2
        local shot_pos_y = shot.pos_y - 2
        local shot_width = 4
        local shot_height = 4

        local hit = false

        for j = #self.enemies_list, 1, -1 do
            local enemie = self.enemies_list[j]

            if enemie.is_alive then
                if aabb(shot_pos_x, shot_pos_y, shot_width, shot_height,
                        enemie.pos_x, enemie.pos_y, enemie.width, enemie.height) then
                    enemie.is_alive = false
                    del(self.enemies_list, enemie)

                    hit = true
                    kills = kills + 1
                    break
                end
            end
        end

        if hit then
            del(shots, shot)
        end
    end

    return kills
end
