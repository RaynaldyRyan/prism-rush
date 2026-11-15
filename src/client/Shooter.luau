-- Prism Rush: shooting. Hold left mouse to fire bolts at the mouse; bolts die at the arena edge and damage the first enemy they overlap.

local Config = require(script.Parent.Config)
local Arena = require(script.Parent.Arena)
local State = require(script.Parent.State)

local Shooter = {}

local bolts = {} -- { frame, x, y, vx, vy }
local cooldown = 0
local callbacks = nil

function Shooter.init(cb)
	callbacks = cb
end

function Shooter.reset()
	for _, b in ipairs(bolts) do
		pcall(function()
			b.frame:Destroy()
		end)
	end
	bolts = {}
	cooldown = 0
end

function Shooter.update(dt, playerX, playerY, firing, mouseX, mouseY)
	cooldown -= dt
	if firing and mouseX ~= nil and cooldown <= 0 then
		local dx = mouseX - playerX
		local dy = mouseY - playerY
		local len = math.sqrt(dx * dx + dy * dy)
		if len > 1 then
			cooldown = State.rapidTimer > 0 and Config.RAPID_RATE or Config.FIRE_RATE
			local nx = dx / len
			local ny = dy / len
			local sx = playerX + nx * (Config.PLAYER_RADIUS + 8)
			local sy = playerY + ny * (Config.PLAYER_RADIUS + 8)
			local frame = Arena.newBolt(sx, sy, math.atan2(dy, dx))
			table.insert(bolts, {
				frame = frame,
				x = sx,
				y = sy,
				vx = nx * Config.BOLT_SPEED,
				vy = ny * Config.BOLT_SPEED,
			})
		end
	end

	local enemies = callbacks and callbacks.getEnemies and callbacks.getEnemies() or {}
	for i = #bolts, 1, -1 do
		local b = bolts[i]
		b.x += b.vx * dt
		b.y += b.vy * dt
		local dead = false
		if b.x < -20 or b.x > Config.ARENA_WIDTH + 20 or b.y < -20 or b.y > Config.ARENA_HEIGHT + 20 then
			dead = true
		else
			for _, e in ipairs(enemies) do
				local dx = b.x - e.x
				local dy = b.y - e.y
				local r = e.radius + 8
				if dx * dx + dy * dy <= r * r then
					dead = true
					if callbacks and callbacks.onHit then
						callbacks.onHit(e, b.x, b.y)
					end
					break
				end
			end
		end
		if dead then
			pcall(function()
				b.frame:Destroy()
			end)
			table.remove(bolts, i)
		else
			b.frame.Position = UDim2.fromOffset(math.floor(b.x + 0.5), math.floor(b.y + 0.5))
		end
	end
end

return Shooter
