-- Prism Rush: mining. Hold E within range of a crystal to channel it:
-- a progress bar fills above the crystal for 0.8 seconds, then the crystal
-- flies to the portal charge bar. Releasing E, or moving out of range,
-- cancels the channel and the progress resets.

local Config = require(script.Parent.Config)
local Arena = require(script.Parent.Arena)
local Screens = require(script.Parent.Screens)

local Miner = {}

local crystals = {} -- { frame, x, y }
local target = nil
local progress = 0
local sparkleTimer = 0
local callbacks = nil

local ringBg = nil
local ringFill = nil

local function ensureRing()
	if ringBg then
		return
	end
	local arenaFrame = Arena.getFrame()
	ringBg = Instance.new("Frame")
	ringBg.AnchorPoint = Vector2.new(0.5, 0.5)
	ringBg.Size = UDim2.fromOffset(44, 8)
	ringBg.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	ringBg.BackgroundTransparency = 0.3
	ringBg.BorderSizePixel = 0
	ringBg.ZIndex = 10
	ringBg.Visible = false
	ringBg.Parent = arenaFrame
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 4)
	c.Parent = ringBg
	ringFill = Instance.new("Frame")
	ringFill.AnchorPoint = Vector2.new(0, 0.5)
	ringFill.Position = UDim2.fromScale(0, 0.5)
	ringFill.Size = UDim2.fromOffset(0, 8)
	ringFill.BackgroundColor3 = Color3.fromRGB(255, 220, 100)
	ringFill.BorderSizePixel = 0
	ringFill.ZIndex = 11
	ringFill.Parent = ringBg
	local c2 = Instance.new("UICorner")
	c2.CornerRadius = UDim.new(0, 4)
	c2.Parent = ringFill
end

local function hideRing()
	progress = 0
	target = nil
	if ringBg then
		ringBg.Visible = false
	end
end

function Miner.init(cb)
	callbacks = cb
	ensureRing()
end

local function randomCrystalPos(placed)
	for _ = 1, 40 do
		local x = math.random(50, Config.ARENA_WIDTH - 50)
		local y = math.random(50, Config.ARENA_HEIGHT - 50)
		-- Keep clear of the player spawn (arena center) and of other crystals.
		local dx = x - Config.ARENA_WIDTH / 2
		local dy = y - Config.ARENA_HEIGHT / 2
		if dx * dx + dy * dy < 130 * 130 then
			continue
		end
		local ok = true
		for _, other in ipairs(placed) do
			local ox = x - other.x
			local oy = y - other.y
			if ox * ox + oy * oy < 100 * 100 then
				ok = false
				break
			end
		end
		if ok then
			return x, y
		end
	end
	return math.random(50, Config.ARENA_WIDTH - 50), math.random(50, Config.ARENA_HEIGHT - 50)
end

function Miner.spawnCrystals(zoneIdx)
	Miner.reset()
	local color = Config.ZONES[zoneIdx].crystal
	for _ = 1, Config.CRYSTALS_PER_ZONE do
		local x, y = randomCrystalPos(crystals)
		local frame = Arena.newCrystal(x, y, color)
		table.insert(crystals, { frame = frame, x = x, y = y })
	end
end

function Miner.reset()
	for _, c in ipairs(crystals) do
		pcall(function()
			c.frame:Destroy()
		end)
	end
	crystals = {}
	hideRing()
end

local function dist2(ax, ay, bx, by)
	local dx = ax - bx
	local dy = ay - by
	return dx * dx + dy * dy
end

function Miner.update(dt, playerX, playerY, miningHeld)
	-- (Re)acquire a target: the nearest crystal in range.
	if target == nil then
		if not miningHeld then
			return
		end
		local best = nil
		local bestD = Config.MINE_RANGE * Config.MINE_RANGE
		for _, c in ipairs(crystals) do
			local d = dist2(playerX, playerY, c.x, c.y)
			if d <= bestD then
				bestD = d
				best = c
			end
		end
		if best == nil then
			return
		end
		target = best
		progress = 0
		sparkleTimer = 0
		ringBg.Visible = true
	end

	-- Cancel paths: E released, or the player moved out of range.
	if not miningHeld or dist2(playerX, playerY, target.x, target.y) > Config.MINE_RANGE * Config.MINE_RANGE then
		hideRing()
		return
	end

	progress += dt / Config.MINE_TIME
	ringBg.Position = UDim2.fromOffset(target.x, target.y - 32)
	ringFill.Size = UDim2.fromOffset(math.floor(44 * math.min(progress, 1) + 0.5), 8)
	sparkleTimer -= dt
	if sparkleTimer <= 0 then
		sparkleTimer = 0.15
		Arena.sparkle(target.x, target.y, Color3.fromRGB(255, 230, 150), 2)
	end

	if progress >= 1 then
		local mined = target
		hideRing()
		for i, c in ipairs(crystals) do
			if c == mined then
				table.remove(crystals, i)
				break
			end
		end
		-- The crystal flies to the HUD charge bar as a pure visual; the
		-- charge itself is awarded by the callback right away.
		Arena.flyCrystalToPortal(mined.frame, Screens.getChargeBarAbsPos(), nil)
		if callbacks and callbacks.onMined then
			callbacks.onMined(mined.x, mined.y)
		end
	end
end

return Miner
