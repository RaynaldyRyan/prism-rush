-- Prism Rush: the client entry point. Builds the GUI, wires the modules
-- together and runs the game loop. It stays thin on purpose: tuning lives
-- in Config, state in State, drawing in Arena and Screens, mining in
-- Miner, bolts in Shooter, enemies in Enemies, pickups in Pickups.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(script.Parent.Config)
local State = require(script.Parent.State)
local Arena = require(script.Parent.Arena)
local Screens = require(script.Parent.Screens)
local Input = require(script.Parent.Input)
local Miner = require(script.Parent.Miner)
local Shooter = require(script.Parent.Shooter)
local Enemies = require(script.Parent.Enemies)
local Pickups = require(script.Parent.Pickups)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- The server's best-score RemoteFunction. It may be absent (a Studio run
-- with the server script disabled); the game plays on with a local best.
local remote = ReplicatedStorage:WaitForChild("BestScore", 5)

local loopConnection = nil
local dashing = false
local dashTimer = 0
local dashCooldown = 0
local dashDx = 1
local dashDy = 0
local lastDx = 1
local lastDy = 0
local invulnTimer = 0
local portalCharged = false

local function getBestFromServer()
	if not remote then
		return 0
	end
	local ok, result = pcall(function()
		return remote:InvokeServer("get")
	end)
	if ok and typeof(result) == "number" then
		return result
	end
	return 0
end

local function saveBestToServer(score)
	if not remote then
		return score
	end
	local ok, result = pcall(function()
		return remote:InvokeServer("save", score)
	end)
	if ok and typeof(result) == "number" then
		return result
	end
	return score
end

local function stopLoop()
	if loopConnection then
		loopConnection:Disconnect()
		loopConnection = nil
	end
end

local function winGame()
	if State.phase ~= "playing" then
		return
	end
	State.phase = "won"
	stopLoop()
	State.best = saveBestToServer(State.score)
	Screens.hideHUD()
	Screens.showWin(State.score, State.elapsed, State.crystalsMined, State.best)
	Screens.startConfetti()
end

local function loseGame()
	if State.phase ~= "playing" then
		return
	end
	State.phase = "lost"
	stopLoop()
	State.best = saveBestToServer(State.score)
	Screens.hideHUD()
	Screens.showGameOver(State.zone, State.score, State.crystalsMined, State.best)
end

local function advanceZone()
	State.score += Config.SCORES.zoneClear
	if State.zone >= #Config.ZONES then
		winGame()
		return
	end
	State.zone += 1
	State.portalCharge = 0
	portalCharged = false
	local zone = Config.ZONES[State.zone]
	Arena.applyZone(State.zone)
	Arena.setPortalAccent(zone.accent)
	Miner.spawnCrystals(State.zone)
	Enemies.reset()
	Pickups.reset()
	State.breather = 1
	Screens.showBanner("ZONE " .. tostring(State.zone) .. " — " .. string.upper(zone.name), zone.subtitle)
	Screens.showPopup(State.playerX, State.playerY - 40, "+200", zone.accent)
end

local function onFrame(dt)
	if State.phase ~= "playing" then
		return
	end
	State.elapsed += dt
	State.tickCombo(dt)
	Input.update()

	-- Movement, with a dash that locks its direction at the press.
	local dx, dy = Input.moveVector()
	if dx ~= 0 or dy ~= 0 then
		lastDx, lastDy = dx, dy
	end
	if Input.dashPressed() and dashCooldown <= 0 then
		dashing = true
		dashTimer = Config.DASH_TIME
		dashCooldown = Config.DASH_COOLDOWN
		dashDx, dashDy = lastDx, lastDy
	end
	local moveX, moveY = dx, dy
	local speed = Config.PLAYER_SPEED
	if dashing then
		moveX, moveY = dashDx, dashDy
		speed = Config.PLAYER_SPEED * Config.DASH_MULTIPLIER
		Arena.spawnGhost(State.playerX, State.playerY, Config.PLAYER_COLOR)
	end
	local r = Config.PLAYER_RADIUS
	local newX = math.clamp(State.playerX + moveX * speed * dt, r, Config.ARENA_WIDTH - r)
	local newY = math.clamp(State.playerY + moveY * speed * dt, r, Config.ARENA_HEIGHT - r)
	State.playerX = newX
	State.playerY = newY
	Arena.setPlayerPosition(newX, newY)
	Arena.updateTrail(newX, newY, moveX ~= 0 or moveY ~= 0, dt)

	if dashing then
		dashTimer -= dt
		if dashTimer <= 0 then
			dashing = false
		end
	end
	dashCooldown = math.max(0, dashCooldown - dt)

	if State.breather > 0 then
		State.breather -= dt
	end
	if invulnTimer > 0 then
		invulnTimer -= dt
	end
	Arena.setPlayerDim(invulnTimer > 0 and math.floor(State.elapsed * 10) % 2 == 0)

	local mouseX, mouseY = Input.mouseArenaPos(Arena.getFrame())
	Miner.update(dt, newX, newY, Input.isMining())
	Shooter.update(dt, newX, newY, Input.isFiring(), mouseX, mouseY)
	Enemies.update(dt, newX, newY, State.zone, State.breather > 0)
	Pickups.update(dt, newX, newY)

	-- Touching a charged portal advances the zone (or wins the game).
	if portalCharged then
		local px, py = Arena.getPortalPosition()
		local ox = newX - px
		local oy = newY - py
		if ox * ox + oy * oy <= 52 * 52 then
			advanceZone()
		end
	end

	Screens.refresh()
	Screens.setDashFraction(1 - dashCooldown / Config.DASH_COOLDOWN)
	Arena.updateShake(dt)
	Arena.updatePortalPulse(State.elapsed)
end

local function startGame()
	stopLoop()
	Screens.stopConfetti()
	Arena.clearEntities()
	Miner.reset()
	Shooter.reset()
	Enemies.reset()
	Pickups.reset()
	Input.reset()
	State.reset(State.best)
	portalCharged = false
	dashing = false
	dashTimer = 0
	dashCooldown = 0
	invulnTimer = 0
	lastDx, lastDy = 1, 0

	Arena.applyZone(1)
	Arena.setPortalAccent(Config.ZONES[1].accent)
	Miner.spawnCrystals(1)
	Arena.setPlayerPosition(State.playerX, State.playerY)
	Arena.setPlayerVisible(true)
	Arena.setPlayerDim(false)
	Arena.setShieldVisible(false)
	Screens.hideStart()
	Screens.hideEnd()
	Screens.showHUD()
	Screens.refresh()
	Screens.showBanner("ZONE 1 — EMBER GROTTO", Config.ZONES[1].subtitle)
	loopConnection = RunService.RenderStepped:Connect(onFrame)
end

-- Module wiring: every scoring and damage event flows through here.
Miner.init({
	onMined = function(x, y)
		local zone = Config.ZONES[State.zone]
		State.crystalsMined += 1
		State.portalCharge += 1
		local gained = State.addScore(Config.SCORES.crystal)
		Screens.showPopup(x, y, "+" .. tostring(gained), zone.crystal)
		Arena.sparkle(x, y, zone.crystal, 8)
		if State.portalCharge >= Config.CRYSTALS_PER_ZONE then
			portalCharged = true
			Arena.setPortalActive(true)
			Screens.showBanner("PORTAL CHARGED", "Touch the portal to advance")
		end
	end,
})

Shooter.init({
	getEnemies = function()
		return Enemies.getAll()
	end,
	onHit = function(enemy)
		Enemies.damage(enemy, Config.BOLT_DAMAGE)
	end,
})

Enemies.init({
	onKilled = function(kind, x, y)
		local gained = State.addScore(Config.SCORES[kind])
		local color = Config.ENEMY_TYPES[kind].color
		Screens.showPopup(x, y, "+" .. tostring(gained), color)
		Arena.sparkle(x, y, color, 8)
		if kind == "splitter" and math.random() < 0.25 then
			Pickups.spawnHeart(x, y)
		end
	end,
	onPlayerHit = function()
		if State.phase ~= "playing" or invulnTimer > 0 then
			return
		end
		if State.shield then
			State.shield = false
			Arena.setShieldVisible(false)
			invulnTimer = 0.5
			Screens.showPopup(State.playerX, State.playerY - 34, "SHIELD DOWN", Color3.fromRGB(80, 230, 255))
			Arena.sparkle(State.playerX, State.playerY, Color3.fromRGB(80, 230, 255), 10)
			return
		end
		State.lives -= 1
		invulnTimer = Config.INVULN_TIME
		Screens.flashDamage()
		Arena.shake(6)
		if State.lives <= 0 then
			loseGame()
		end
	end,
})

Pickups.init({
	onStar = function(x, y)
		local gained = State.addScore(Config.SCORES.star)
		Screens.showPopup(x, y, "+" .. tostring(gained), Color3.fromRGB(255, 220, 60))
		Arena.sparkle(x, y, Color3.fromRGB(255, 220, 60), 6)
	end,
	onShield = function(x, y)
		State.shield = true
		Arena.setShieldVisible(true)
		Screens.showPopup(x, y, "SHIELD!", Color3.fromRGB(80, 230, 255))
	end,
	onHeart = function(x, y)
		State.lives = math.min(Config.MAX_LIVES, State.lives + 1)
		Screens.showPopup(x, y, "+1 HP", Color3.fromRGB(255, 120, 140))
	end,
})

-- Build the game, then show the menu. The arena behind the start screen
-- already shows zone 1 with its crystals, so the first screenshot reads
-- as a game, not an empty frame.
local gui = Instance.new("ScreenGui")
gui.Name = "PrismRushGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 10
gui.Parent = playerGui

Arena.build(gui)
Screens.build(gui, Arena.getFrame(), {
	onPlay = startGame,
	onPlayAgain = startGame,
})
Arena.applyZone(1)
Miner.spawnCrystals(1)
Arena.setPlayerPosition(State.playerX, State.playerY)

State.best = getBestFromServer()
Screens.showStart(State.best)
