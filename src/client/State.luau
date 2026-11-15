-- Prism Rush: the single game state. Every module reads and writes this one table.

local Config = require(script.Parent.Config)

local State = {}

State.score = 0
State.combo = 1
State.comboTimer = 0
State.lives = Config.MAX_LIVES
State.zone = 1
State.crystalsMined = 0 -- total mined
State.portalCharge = 0 -- mined this zone
State.shield = false
State.bossHp = 0 -- boss HP
State.bossMax = 0 -- boss max HP
State.rapidTimer = 0 -- rapid fire left
State.phase = "menu" -- menu | playing | won | lost
State.best = 0
State.elapsed = 0
State.playerX = Config.ARENA_WIDTH / 2
State.playerY = Config.ARENA_HEIGHT / 2
State.breather = 0 -- zone-change pause

function State.reset(best)
	State.score = 0
	State.combo = 1
	State.comboTimer = 0
	State.lives = Config.MAX_LIVES
	State.zone = 1
	State.crystalsMined = 0
	State.portalCharge = 0
	State.shield = false
	State.bossHp = 0
	State.bossMax = 0
	State.rapidTimer = 0
	State.phase = "playing"
	State.best = best or 0
	State.elapsed = 0
	State.playerX = Config.ARENA_WIDTH / 2
	State.playerY = Config.ARENA_HEIGHT / 2
	State.breather = 0
end

-- Adds base x combo to the score, chains the combo up (max x3), restarts
-- the combo window. Returns the points gained, for the popup text.
function State.addScore(base)
	local gained = base * State.combo
	State.score += gained
	State.combo = math.min(Config.MAX_COMBO, State.combo + 1)
	State.comboTimer = Config.COMBO_WINDOW
	return gained
end

function State.tickCombo(dt)
	if State.comboTimer > 0 then
		State.comboTimer -= dt
		if State.comboTimer <= 0 then
			State.combo = 1
		end
	end
end

return State
