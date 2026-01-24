---
--- GameState enum
--- Enum für den aktuellen Zustand des Spiels
---

---@enum GameState
local GameState = {
    MENU = "menu",  -- Spiel befindet sich im Menü
    PLAY = "play",  -- Spiel läuft aktiv
    OVER = "over"   -- Spiel vorbei / Game Over
}
