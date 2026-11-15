-- Prism Rush: pickups. Stars for combo score, a shield ~every 30s, rapid fire ~every 25s, hearts only from killed splitters. All expire.

local Config = require(script.Parent.Config)
local Arena = require(script.Parent.Arena)

local Pickups = {}

local stars = {} -- { frame, x, y, age }
local shieldPickup = nil -- { frame, x, y, age } or nil
local rapidPickup = nil -- { frame, x, y, age } or nil
local hearts = {} -- { frame, x, y, age }
local starTimer = 2
local shieldTimer = 30
local rapidTimer = 25
local callbacks = nil

local STAR_LIFETIME = 12
local SHIELD_LIFETIME = 20
local RAPID_LIFETIME = 15
local HEART_LIFETIME = 10

local function kill(frame)
	pcall(function()
		frame:Destroy()
	end)
end

function Pickups.init(cb)
	callbacks = cb
end

function Pickups.reset()
	for _, s in ipairs(stars) do
		kill(s.frame)
	end
	for _, h in ipairs(hearts) do
		kill(h.frame)
	end
	if shieldPickup then
		kill(shieldPickup.frame)
	end
	if rapidPickup then
		kill(rapidPickup.frame)
	end
	stars = {}
	hearts = {}
	shieldPickup = nil
	rapidPickup = nil
	starTimer = 2
	shieldTimer = 30
	rapidTimer = 25
end

local function randomPos()
	return math.random(40, Config.ARENA_WIDTH - 40), math.random(40, Config.ARENA_HEIGHT - 40)
end

function Pickups.spawnHeart(x, y)
	local cx = math.clamp(x, 30, Config.ARENA_WIDTH - 30)
	local cy = math.clamp(y, 30, Config.ARENA_HEIGHT - 30)
	local frame = Arena.newHeartPickup(cx, cy)
	table.insert(hearts, { frame = frame, x = cx, y = cy, age = 0 })
end

function Pickups.spawnRapid(x, y)
	if rapidPickup then
		return
	end
	local cx = math.clamp(x, 30, Config.ARENA_WIDTH - 30)
	local cy = math.clamp(y, 30, Config.ARENA_HEIGHT - 30)
	local frame = Arena.newRapidPickup(cx, cy)
	rapidPickup = { frame = frame, x = cx, y = cy, age = 0 }
end

function Pickups.update(dt, playerX, playerY)
	starTimer -= dt
	if starTimer <= 0 and #stars < 3 then
		starTimer = 4
		local x, y = randomPos()
		local frame = Arena.newStar(x, y)
		table.insert(stars, { frame = frame, x = x, y = y, age = 0 })
	end

	shieldTimer -= dt
	if shieldTimer <= 0 and shieldPickup == nil then
		shieldTimer = 30
		local x, y = randomPos()
		local frame = Arena.newShieldPickup(x, y)
		shieldPickup = { frame = frame, x = x, y = y, age = 0 }
	end

	rapidTimer -= dt
	if rapidTimer <= 0 and rapidPickup == nil then
		rapidTimer = 25
		local x, y = randomPos()
		Pickups.spawnRapid(x, y)
	end

	local function inReach(px, py, x, y)
		local dx = px - x
		local dy = py - y
		return dx * dx + dy * dy <= 30 * 30
	end

	for i = #stars, 1, -1 do
		local s = stars[i]
		s.age += dt
		if s.age > STAR_LIFETIME then
			kill(s.frame)
			table.remove(stars, i)
		elseif inReach(playerX, playerY, s.x, s.y) then
			kill(s.frame)
			table.remove(stars, i)
			if callbacks and callbacks.onStar then
				callbacks.onStar(s.x, s.y)
			end
		end
	end

	if shieldPickup then
		shieldPickup.age += dt
		if shieldPickup.age > SHIELD_LIFETIME then
			kill(shieldPickup.frame)
			shieldPickup = nil
		elseif inReach(playerX, playerY, shieldPickup.x, shieldPickup.y) then
			local x, y = shieldPickup.x, shieldPickup.y
			kill(shieldPickup.frame)
			shieldPickup = nil
			shieldTimer = 30
			if callbacks and callbacks.onShield then
				callbacks.onShield(x, y)
			end
		end
	end

	if rapidPickup then
		rapidPickup.age += dt
		if rapidPickup.age > RAPID_LIFETIME then
			kill(rapidPickup.frame)
			rapidPickup = nil
		elseif inReach(playerX, playerY, rapidPickup.x, rapidPickup.y) then
			local x, y = rapidPickup.x, rapidPickup.y
			kill(rapidPickup.frame)
			rapidPickup = nil
			rapidTimer = 25
			if callbacks and callbacks.onRapid then
				callbacks.onRapid(x, y)
			end
		end
	end

	for i = #hearts, 1, -1 do
		local h = hearts[i]
		h.age += dt
		if h.age > HEART_LIFETIME then
			kill(h.frame)
			table.remove(hearts, i)
		elseif inReach(playerX, playerY, h.x, h.y) then
			kill(h.frame)
			table.remove(hearts, i)
			if callbacks and callbacks.onHeart then
				callbacks.onHeart(h.x, h.y)
			end
		end
	end
end

return Pickups
