-- Prism Rush: the single game state. Every module reads and writes this one
-- table; nothing keeps a second copy of the score, the lives or the phase.

local Config = require(script.Parent.Config)

local State = {}

State.score = 0
State.combo = 1
State.comboTimer = 0
State.lives = Config.MAX_LIVES
State.zone = 1
State.crystalsMined = 0 -- total across all zones, for the end screen
State.portalCharge = 0 -- crystals mined in the current zone (0..6)
State.shield = false
State.phase = "menu" -- menu | playing | won | lost
State.best = 0
State.elapsed = 0
State.playerX = Config.ARENA_WIDTH / 2
State.playerY = Config.ARENA_HEIGHT / 2
State.breather = 0 -- seconds of enemy pause after a zone change

function State.reset(best)
	State.score = 0
	State.combo = 1
	State.comboTimer = 0
	State.lives = Config.MAX_LIVES
	State.zone = 1
	State.crystalsMined = 0
	State.portalCharge = 0
	State.shield = false
	State.phase = "playing"
	State.best = best or 0
	State.elapsed = 0
	State.playerX = Config.ARENA_WIDTH / 2
	State.playerY = Config.ARENA_HEIGHT / 2
	State.breather = 0
end

-- Adds a score event, multiplied by the current combo, then chains the
-- combo up one step (to x3 at most) and restarts the combo window.
-- Returns the points actually gained, for the popup text.
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
