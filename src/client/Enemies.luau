-- Prism Rush: enemies. Chasers drift in from the arena edges and home in
-- on the player; splitters (zone 2+) take two hits and break into two fast
-- minis. Touching the player destroys the enemy and hurts the player —
-- the caller decides shield, invulnerability and damage.

local Config = require(script.Parent.Config)
local Arena = require(script.Parent.Arena)

local Enemies = {}

local list = {} -- { frame, kind, x, y, hp, speed, radius }
local spawnTimer = 0
local callbacks = nil

function Enemies.init(cb)
	callbacks = cb
end

function Enemies.getAll()
	return list
end

function Enemies.reset()
	for _, e in ipairs(list) do
		pcall(function()
			e.frame:Destroy()
		end)
	end
	list = {}
	spawnTimer = 1.0
end

local function spawnPos(playerX, playerY)
	for _ = 1, 8 do
		local edge = math.random(0, 3)
		local x, y
		if edge == 0 then
			x, y = math.random(20, Config.ARENA_WIDTH - 20), 20
		elseif edge == 1 then
			x, y = math.random(20, Config.ARENA_WIDTH - 20), Config.ARENA_HEIGHT - 20
		elseif edge == 2 then
			x, y = 20, math.random(20, Config.ARENA_HEIGHT - 20)
		else
			x, y = Config.ARENA_WIDTH - 20, math.random(20, Config.ARENA_HEIGHT - 20)
		end
		local dx = x - playerX
		local dy = y - playerY
		if dx * dx + dy * dy >= 150 * 150 then
			return x, y
		end
	end
	return 20, 20
end

local function addEnemy(kind, x, y, zoneIdx)
	local def = Config.ENEMY_TYPES[kind]
	local zone = Config.ZONES[zoneIdx]
	local frame = Arena.newEnemy(kind, x, y)
	local enemy = {
		frame = frame,
		kind = kind,
		x = x,
		y = y,
		hp = def.hp,
		speed = zone.enemySpeed * def.speedScale,
		radius = def.radius,
		zoneIdx = zoneIdx,
	}
	table.insert(list, enemy)
	return enemy
end

function Enemies.damage(enemy, amount)
	for i, e in ipairs(list) do
		if e == enemy then
			e.hp -= amount
			Arena.sparkle(e.x, e.y, Color3.fromRGB(255, 255, 255), 3)
			if e.hp <= 0 then
				local kind, x, y = e.kind, e.x, e.y
				pcall(function()
					e.frame:Destroy()
				end)
				table.remove(list, i)
				if kind == "splitter" then
					-- Splits into two fast minis at the death spot, scaled
					-- to the zone the splitter came from.
					local z = e.zoneIdx or 2
					addEnemy("mini", math.clamp(x - 18, 14, Config.ARENA_WIDTH - 14), y, z)
					addEnemy("mini", math.clamp(x + 18, 14, Config.ARENA_WIDTH - 14), y, z)
				end
				if callbacks and callbacks.onKilled then
					callbacks.onKilled(kind, x, y)
				end
			end
			return
		end
	end
end

function Enemies.update(dt, playerX, playerY, zoneIdx, paused)
	if paused then
		return
	end
	local zone = Config.ZONES[zoneIdx]
	spawnTimer -= dt
	if spawnTimer <= 0 and #list < zone.enemyCap then
		spawnTimer = zone.spawnInterval
		local kind = "chaser"
		if zone.splitterChance > 0 and math.random() < zone.splitterChance then
			kind = "splitter"
		end
		local x, y = spawnPos(playerX, playerY)
		addEnemy(kind, x, y, zoneIdx)
	end

	for i = #list, 1, -1 do
		local e = list[i]
		local dx = playerX - e.x
		local dy = playerY - e.y
		local len = math.sqrt(dx * dx + dy * dy)
		if len > 0.01 then
			e.x += (dx / len) * e.speed * dt
			e.y += (dy / len) * e.speed * dt
			e.frame.Position = UDim2.fromOffset(math.floor(e.x + 0.5), math.floor(e.y + 0.5))
		end
		local ndx = playerX - e.x
		local ndy = playerY - e.y
		local reach = e.radius + Config.PLAYER_RADIUS - 2
		if ndx * ndx + ndy * ndy <= reach * reach then
			pcall(function()
				e.frame:Destroy()
			end)
			table.remove(list, i)
			if callbacks and callbacks.onPlayerHit then
				callbacks.onPlayerHit()
			end
		end
	end
end

return Enemies
