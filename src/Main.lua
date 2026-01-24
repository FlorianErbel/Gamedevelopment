---
--- Main-Modul
--- Verwaltung von Spielzustand, Score, Input, Kamera, Plattformen und Gegnern
---

---@class Game
---@field STARTING_HEIGHT number         -- Start-Höhe beim Spielstart
---@field state GameState                -- Aktueller Spielzustand
---@field difficulty Difficulty          -- Schwierigkeitsgrad
---@field height number                  -- Aktuelle Höhe des Spielers
---@field best_height number             -- Höchste erreichte Höhe
local game = {
    STARTING_HEIGHT = 0,
    state = GameState.MENU,
    difficulty = Difficulty.EASY,
    height = 0,
    best_height = 0
}

---Initialisiert alle Spielkomponenten
function game_setup()
    cam:init()                       -- Kamera initialisieren
    enemies:init()                   -- Gegnerliste initialisieren
    plats = PlatformManager.new(game.difficulty) -- Plattform-Manager initialisieren
    player:init()                    -- Spieler initialisieren

    game.height = game.STARTING_HEIGHT
    game.best_height = game.STARTING_HEIGHT
end

---Standard-PICO-8 Initialisierung
function _init()
    poke(0x5f2d, 1)                 -- Tastatureingaben aktivieren
    cartdata("doodlejump_hs")       -- Highscore-Speicher vorbereiten
    game_setup()
    game.state = GameState.MENU
end

---Setzt das Spiel zurück und startet neu
function reset_game()
    game_setup()
    game.state = GameState.PLAY
end

---Beendet das Spiel, speichert ggf. Highscore
function game_over()
    game.state = GameState.OVER
    player.is_alive = false
    local highscore = load_highscore(game.difficulty)
    if game.best_height > highscore then
        save_highscore(game.difficulty, game.best_height)
    end
end

---Update-Logik für 60 FPS
function _update60()
    -- Menü-Logik
    if game.state == GameState.MENU then
        local k = stat(31) -- Tasteneingabe als String

        if k == "1" then
            game.difficulty = Difficulty.EASY
            reset_game()
        elseif k == "2" then
            game.difficulty = Difficulty.MEDIUM
            reset_game()
        elseif k == "3" then
            game.difficulty = Difficulty.HARD
            reset_game()
        end

        return
    end

    -- GameOver-Logik
    if game.state == GameState.OVER then
        if btnp(4) or btnp(5) then
            game.state = GameState.MENU
            return
        end
        return
    end

    -- Spieler aktualisieren (Bewegung, Sprünge, Schüsse)
    player:update(plats, cam.pos_y)
    enemies:update()
    enemies:shots_hit(player)

    -- Spieler trifft Gegner => Game Over
    if enemies:player_hit(player) then
        game_over()
        return
    end

    -- Kamera folgt Spieler
    cam:update(player)

    -- Plattformen aktualisieren / nachspawnen
    plats:update(cam.pos_y)

    -- Höhe messen: kleiner y-Wert => höhere Plattform
    game.height = max(0, flr(120 - player.pos_y))
    if game.height > game.best_height then
        game.best_height = game.height
    end

    -- Spieler fällt unter Bildschirmrand => Game Over
    if player.pos_y > cam.pos_y + 140 then
        game_over()
    end
end

---Berechnet Highscore-Slot je Schwierigkeitsgrad
---@param difficulty Difficulty
---@return number slot
function highscore_slot(difficulty)
    return difficulty - 1 -- Slots: 0,1,2
end

---Lädt den Highscore aus persistentem Speicher
---@param difficulty Difficulty
---@return number highscore
function load_highscore(difficulty)
    return dget(highscore_slot(difficulty)) or 0
end

---Speichert den Highscore im persistenten Speicher
---@param difficulty Difficulty
---@param new_highscore number
function save_highscore(difficulty, new_highscore)
    dset(highscore_slot(difficulty), new_highscore)
end

---Zeichnet Spielobjekte und UI
function _draw()
    cls(1)                      -- Bildschirm löschen

    -- UI ohne Kamera
    camera()

    if game.state == GameState.MENU then
        -- Highscores laden
        local hs_easy = load_highscore(Difficulty.EASY)
        local hs_medium = load_highscore(Difficulty.MEDIUM)
        local hs_hard = load_highscore(Difficulty.HARD)

        -- Menü anzeigen
        print("highjump", 50, 18, 7)
        print("select mode:", 40, 34, 6)
        print("1 easy   hs: " .. hs_easy, 34, 50, 7)
        print("2 medium hs: " .. hs_medium, 34, 60, 7)
        print("3 hard   hs: " .. hs_hard, 34, 70, 7)

        return
    end

    -- Spiel-Rendering
    cam:apply()
    plats:draw()
    enemies:draw()
    player:draw()
    cam:reset()

    -- UI mit Kamera zurücksetzen
    camera()
    print("height: " .. game.height, 2, 2, 7)
    print("best: " .. game.best_height, 2, 10, 6)

    if game.state == GameState.OVER then
        rectfill(18, 48, 110, 80, 0)
        rect(18, 48, 110, 80, 7)
        print("game over", 44, 56, 8)
        print("z/x -> menu", 36, 66, 7)
    end
end
