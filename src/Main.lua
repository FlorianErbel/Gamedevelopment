game = {
    state = "menu", -- menu/play/over
    difficulty = 1,
    height = 0,
    best_height = 0
}

function _init()
    poke(0x5f2d, 1) -- keyboard input enable
    cartdata("doodlejump_hs")
    cam:init()
    enemies:init()
    plats = PlatformManager.new(game.difficulty)
    player:init()

    game.state = "menu"
    game.height = 0
    game.best_height = 0
end

function reset_game()
    cam:init()
    enemies:init()
    plats = PlatformManager.new(game.difficulty)
    player:init()

    game.state = "play"
    game.height = 0
    game.best_height = 0
end

function game_over()
    game.state = "over"
    player.alive = false
    local highscore = load_highscore(game.difficulty)
    if game.best_height > highscore then
        save_highscore(game.difficulty, game.best_height)
    end
end

function _update60()
    if game.state == "menu" then
        local k = stat(31)

        if k == "1" then
            game.difficulty = 1
            reset_game()
        elseif k == "2" then
            game.difficulty = 2
            reset_game()
        elseif k == "3" then
            game.difficulty = 3
            reset_game()
        end

        return
    end

    if game.state == "over" then
        if btnp(4) or btnp(5) then
            game.state = "menu"
            return
        end
        return
    end


    player:update(plats, cam.pos_y)
    enemies:update()
    enemies:shots_hit(player)

    -- collision: player touches hedgehog => game over
    if enemies:player_hit(player) then
        game_over()
        return
    end


    -- kamera folgt (nur nach oben)
    cam:update(player)

    -- plattformen nachspawnen abhängig von kamera
    plats:update(cam.pos_y)

    -- höhe messen: je kleiner player.y, desto höher
    -- baseline ist start bei ~100..120 => wir nehmen 120 als null
    game.height = max(0, flr(120 - player.pos_y))
    if game.height > game.best_height then
        game.best_height = game.height
    end

    -- gameover: fällt unter unteren screenrand
    -- unterer sichtbarer rand in welt: cam.y + 128
    if player.pos_y > cam.pos_y + 140 then
        game.state = "over"
        player.is_alive = false
        local highscore = load_highscore(game.difficulty)
        if game.height > highscore then
            save_highscore(game.difficulty, game.height)
        end
    end
end

function highscore_slot(difficulty)
    return difficulty - 1 -- slots 0,1,2
end

function load_highscore(difficulty)
    return dget(highscore_slot(difficulty)) or 0
end

function save_highscore(difficulty, new_highscore)
    dset(highscore_slot(difficulty), new_highscore)
end

function _draw()
    cls(1)

    -- ui ohne kamera
    camera()

    if game.state == "menu" then
        local highscore_difficulty_easy = load_highscore(1)
        local highscore_difficulty_medium = load_highscore(2)
        local highscore_difficulty_hard = load_highscore(3)

        print("doodletump", 44, 18, 7)
        print("select mode:", 40, 34, 6)

        print("1 easy   hs: " .. highscore_difficulty_easy, 34, 50, 7)
        print("2 medium hs: " .. highscore_difficulty_medium, 34, 60, 7)
        print("3 hard   hs: " .. highscore_difficulty_hard, 34, 70, 7)

        return
    end

    -- ab hier: spiel zeichnen
    cam:apply()
    plats:draw()
    enemies:draw()
    player:draw()
    cam:reset()

    camera()
    print("height: " .. game.height, 2, 2, 7)
    print("best: " .. game.best_height, 2, 10, 6)

    if game.state == "over" then
        rectfill(18, 48, 110, 80, 0)
        rect(18, 48, 110, 80, 7)
        print("game over", 44, 56, 8)
        print("z/x -> menu", 36, 66, 7)
    end
end
