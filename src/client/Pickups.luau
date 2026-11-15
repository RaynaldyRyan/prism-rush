-- Prism Rush: pickups. Stars drift in every few seconds for combo score,
-- a shield drops about every 30 seconds, and hearts only ever drop from
-- killed splitters (the caller spawns them). Everything expires if it is
-- left alone for too long.

local Config = require(script.Parent.Config)
local Arena = require(script.Parent.Arena)

local Pickups = {}

local stars = {} -- { frame, x, y, age }
local shieldPickup = nil -- { frame, x, y, age } or nil
local hearts = {} -- { frame, x, y, age }
local starTimer = 2
local shieldTimer = 30
local callbacks = nil

local STAR_LIFETIME = 12
local SHIELD_LIFETIME = 20
local HEART_LIFETIME = 10

function Pickups.init(cb)
	callbacks = cb
end

function Pickups.reset()
	for _, s in ipairs(stars) do
		pcall(function()
			s.frame:Destroy()
		end)
	end
	for _, h in ipairs(hearts) do
		pcall(function()
			h.frame:Destroy()
		end)
	end
	if shieldPickup then
		pcall(function()
			shieldPickup.frame:Destroy()
		end)
	end
	stars = {}
	hearts = {}
	shieldPickup = nil
	starTimer = 2
	shieldTimer = 30
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

	local function inReach(px, py, x, y)
		local dx = px - x
		local dy = py - y
		return dx * dx + dy * dy <= 30 * 30
	end

	for i = #stars, 1, -1 do
		local s = stars[i]
		s.age += dt
		if s.age > STAR_LIFETIME then
			pcall(function()
				s.frame:Destroy()
			end)
			table.remove(stars, i)
		elseif inReach(playerX, playerY, s.x, s.y) then
			pcall(function()
				s.frame:Destroy()
			end)
			table.remove(stars, i)
			if callbacks and callbacks.onStar then
				callbacks.onStar(s.x, s.y)
			end
		end
	end

	if shieldPickup then
		shieldPickup.age += dt
		if shieldPickup.age > SHIELD_LIFETIME then
			pcall(function()
				shieldPickup.frame:Destroy()
			end)
			shieldPickup = nil
		elseif inReach(playerX, playerY, shieldPickup.x, shieldPickup.y) then
			local x, y = shieldPickup.x, shieldPickup.y
			pcall(function()
				shieldPickup.frame:Destroy()
			end)
			shieldPickup = nil
			shieldTimer = 30
			if callbacks and callbacks.onShield then
				callbacks.onShield(x, y)
			end
		end
	end

	for i = #hearts, 1, -1 do
		local h = hearts[i]
		h.age += dt
		if h.age > HEART_LIFETIME then
			pcall(function()
				h.frame:Destroy()
			end)
			table.remove(hearts, i)
		elseif inReach(playerX, playerY, h.x, h.y) then
			pcall(function()
				h.frame:Destroy()
			end)
			table.remove(hearts, i)
			if callbacks and callbacks.onHeart then
				callbacks.onHeart(h.x, h.y)
			end
		end
	end
end

return Pickups
