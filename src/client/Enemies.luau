-- Prism Rush: enemies. Chasers home in; splitters (zone 2+) break into minis; shooters (zone 3+) hold range and fire bolts; the Titan (zone 5) is a 30 HP boss with a 3-way volley and mini spawns. Touching the player destroys a normal enemy; the boss survives contact.

local Config = require(script.Parent.Config)
local Arena = require(script.Parent.Arena)
local State = require(script.Parent.State)

local Enemies = {}

local list = {} -- { frame, kind, x, y, hp, speed, radius, shotTimer, miniTimer }
local bolts = {} -- enemy bolts: { frame, x, y, vx, vy }
local spawnTimer = 0
local callbacks = nil

local BOSS_SHOT = 3
local BOSS_MINI = 10
local BOSS_MINI_CAP = 4
local SHOOT_DIST = 200
local SHOOT_SHOT = 2.5
local ENEMY_BOLT_SPEED = 200

local function kill(frame)
	pcall(function()
		frame:Destroy()
	end)
end

function Enemies.init(cb)
	callbacks = cb
end

function Enemies.getAll()
	return list
end

function Enemies.reset()
	for _, e in ipairs(list) do
		kill(e.frame)
	end
	for _, b in ipairs(bolts) do
		kill(b.frame)
	end
	list = {}
	bolts = {}
	spawnTimer = 1.0
end

local function spawnPos(playerX, playerY)
	local W, H = Config.ARENA_WIDTH, Config.ARENA_HEIGHT
	for _ = 1, 8 do
		local edge = math.random(0, 3)
		local x = edge == 2 and 20 or edge == 3 and W - 20 or math.random(20, W - 20)
		local y = edge == 0 and 20 or edge == 1 and H - 20 or math.random(20, H - 20)
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
		shotTimer = 1.5,
		miniTimer = BOSS_MINI,
	}
	table.insert(list, enemy)
	return enemy
end

-- The boss spawns far from the portal (bottom center), slow at 40 px/s.
function Enemies.spawnBoss()
	local boss = addEnemy("boss", Config.ARENA_WIDTH / 2, Config.ARENA_HEIGHT - 120, 5)
	boss.speed = 40
	State.bossHp = boss.hp
	State.bossMax = boss.hp
end

local function fireBolt(x, y, angle, speed)
	local frame = Arena.newBolt(x, y, angle, Color3.fromRGB(255, 60, 180))
	table.insert(bolts, {
		frame = frame,
		x = x,
		y = y,
		vx = math.cos(angle) * speed,
		vy = math.sin(angle) * speed,
	})
end

function Enemies.damage(enemy, amount)
	for i, e in ipairs(list) do
		if e == enemy then
			e.hp -= amount
			Arena.sparkle(e.x, e.y, Color3.fromRGB(255, 255, 255), 3)
			if e.kind == "boss" then
				State.bossHp = math.max(0, e.hp)
			end
			if e.hp <= 0 then
				local kind, x, y = e.kind, e.x, e.y
				kill(e.frame)
				table.remove(list, i)
				if kind == "splitter" then
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

local function updateBolts(dt, playerX, playerY)
	for i = #bolts, 1, -1 do
		local b = bolts[i]
		b.x += b.vx * dt
		b.y += b.vy * dt
		local dead = b.x < -20 or b.x > Config.ARENA_WIDTH + 20 or b.y < -20 or b.y > Config.ARENA_HEIGHT + 20
		if not dead then
			local dx = playerX - b.x
			local dy = playerY - b.y
			local reach = Config.PLAYER_RADIUS + 8
			if dx * dx + dy * dy <= reach * reach then
				dead = true
				if callbacks and callbacks.onPlayerHit then
					callbacks.onPlayerHit()
				end
			end
		end
		if dead then
			kill(b.frame)
			table.remove(bolts, i)
		else
			b.frame.Position = UDim2.fromOffset(math.floor(b.x + 0.5), math.floor(b.y + 0.5))
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
		if zoneIdx >= 3 and math.random() < 0.25 then
			kind = "shooter"
		elseif zone.splitterChance > 0 and math.random() < zone.splitterChance then
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
			local mx, my = dx / len, dy / len
			if e.kind == "shooter" then
				-- Holds ~200px: backs off when close, closes in when far, strafes between; fires every 2.5s.
				if len < SHOOT_DIST - 30 then
					mx, my = -mx, -my
				elseif len < SHOOT_DIST + 30 then
					mx, my = -my, mx
				end
				e.shotTimer -= dt
				if e.shotTimer <= 0 then
					e.shotTimer = SHOOT_SHOT
					fireBolt(e.x, e.y, math.atan2(dy, dx), 220)
				end
			elseif e.kind == "boss" then
				e.shotTimer -= dt
				if e.shotTimer <= 0 then
					e.shotTimer = BOSS_SHOT
					local base = math.atan2(dy, dx)
					fireBolt(e.x, e.y, base - 0.35, ENEMY_BOLT_SPEED)
					fireBolt(e.x, e.y, base, ENEMY_BOLT_SPEED)
					fireBolt(e.x, e.y, base + 0.35, ENEMY_BOLT_SPEED)
				end
				e.miniTimer -= dt
				if e.miniTimer <= 0 then
					e.miniTimer = BOSS_MINI
					local minis = 0
					for _, other in ipairs(list) do
						if other.kind == "mini" then
							minis += 1
						end
					end
					for _ = 1, math.min(2, BOSS_MINI_CAP - minis) do
						addEnemy("mini", math.clamp(e.x + math.random(-40, 40), 14, Config.ARENA_WIDTH - 14), math.clamp(e.y + 30, 14, Config.ARENA_HEIGHT - 14), 5)
					end
				end
			end
			e.x += mx * e.speed * dt
			e.y += my * e.speed * dt
			e.x = math.clamp(e.x, e.radius, Config.ARENA_WIDTH - e.radius)
			e.y = math.clamp(e.y, e.radius, Config.ARENA_HEIGHT - e.radius)
			e.frame.Position = UDim2.fromOffset(math.floor(e.x + 0.5), math.floor(e.y + 0.5))
		end
		local ndx = playerX - e.x
		local ndy = playerY - e.y
		local reach = e.radius + Config.PLAYER_RADIUS - 2
		if ndx * ndx + ndy * ndy <= reach * reach then
			if e.kind ~= "boss" then
				kill(e.frame)
				table.remove(list, i)
			end
			if callbacks and callbacks.onPlayerHit then
				callbacks.onPlayerHit()
			end
		end
	end

	updateBolts(dt, playerX, playerY)
end

return Enemies
