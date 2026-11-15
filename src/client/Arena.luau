-- Prism Rush: everything drawn in the arena (background, grid, player, portal, entity frames). All positions are arena-local pixels, entity center at (x, y).

local TweenService = game:GetService("TweenService")

local Config = require(script.Parent.Config)

local Arena = {}

local guiRoot = nil
local background = nil
local bgGradient = nil
local arenaFrame = nil
local gridLines = {}
local entities = nil
local playerToken = nil
local playerGlow = nil
local playerCore = nil
local shieldRing = nil
local portalFrame = nil
local portalInner = nil
local portalLabel = nil
local portalActive = false

local shakeTime = 0
local shakeMag = 0
local trailTimer = 0

local PORTAL_X = Config.ARENA_WIDTH / 2
local PORTAL_Y = 46

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
	return c
end

local function frameAt(parent, x, y, w, h, color, transparency, zIndex)
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromOffset(x, y)
	f.Size = UDim2.fromOffset(w, h)
	f.BackgroundColor3 = color
	f.BackgroundTransparency = transparency or 0
	f.BorderSizePixel = 0
	f.ZIndex = zIndex or 5
	f.Parent = parent
	return f
end

function Arena.build(gui)
	guiRoot = gui

	background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.fromScale(1, 1)
	background.BackgroundColor3 = Color3.fromRGB(20, 12, 30)
	background.BorderSizePixel = 0
	background.ZIndex = 1
	background.Parent = gui

	bgGradient = Instance.new("UIGradient")
	bgGradient.Rotation = 90
	bgGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(58, 28, 18)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(96, 40, 20)),
	})
	bgGradient.Parent = background

	arenaFrame = Instance.new("Frame")
	arenaFrame.Name = "Arena"
	arenaFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	arenaFrame.Position = UDim2.fromScale(0.5, 0.5)
	arenaFrame.Size = UDim2.fromOffset(Config.ARENA_WIDTH, Config.ARENA_HEIGHT)
	arenaFrame.BackgroundColor3 = Color3.fromRGB(12, 10, 26)
	arenaFrame.BackgroundTransparency = 0.15
	arenaFrame.BorderSizePixel = 0
	arenaFrame.ZIndex = 2
	arenaFrame.ClipsDescendants = true
	arenaFrame.Parent = gui
	corner(arenaFrame, 14)

	local stroke = Instance.new("UIStroke")
	stroke.Color = Config.ZONES[1].accent
	stroke.Thickness = 3
	stroke.Parent = arenaFrame
	Arena._stroke = stroke

	for x = 40, Config.ARENA_WIDTH - 40, 40 do
		local line = Instance.new("Frame")
		line.AnchorPoint = Vector2.new(0.5, 0)
		line.Position = UDim2.fromOffset(x, 0)
		line.Size = UDim2.fromOffset(1, Config.ARENA_HEIGHT)
		line.BackgroundColor3 = Config.ZONES[1].grid
		line.BackgroundTransparency = 0.82
		line.BorderSizePixel = 0
		line.ZIndex = 3
		line.Parent = arenaFrame
		table.insert(gridLines, line)
	end
	for y = 40, Config.ARENA_HEIGHT - 40, 40 do
		local line = Instance.new("Frame")
		line.AnchorPoint = Vector2.new(0, 0.5)
		line.Position = UDim2.fromOffset(0, y)
		line.Size = UDim2.fromOffset(Config.ARENA_WIDTH, 1)
		line.BackgroundColor3 = Config.ZONES[1].grid
		line.BackgroundTransparency = 0.82
		line.BorderSizePixel = 0
		line.ZIndex = 3
		line.Parent = arenaFrame
		table.insert(gridLines, line)
	end

	entities = Instance.new("Frame")
	entities.Name = "Entities"
	entities.Size = UDim2.fromScale(1, 1)
	entities.BackgroundTransparency = 1
	entities.ZIndex = 5
	entities.Parent = arenaFrame

	portalFrame = frameAt(arenaFrame, PORTAL_X, PORTAL_Y, 56, 56, Color3.fromRGB(60, 60, 80), 0.25, 4)
	corner(portalFrame, 28)
	local portalStroke = Instance.new("UIStroke")
	portalStroke.Color = Color3.fromRGB(140, 140, 160)
	portalStroke.Thickness = 3
	portalStroke.Parent = portalFrame
	Arena._portalStroke = portalStroke
	portalInner = frameAt(portalFrame, 0, 0, 30, 30, Color3.fromRGB(120, 120, 140), 0.2, 4)
	portalInner.AnchorPoint = Vector2.new(0.5, 0.5)
	portalInner.Position = UDim2.fromScale(0.5, 0.5)
	portalInner.Rotation = 45
	corner(portalInner, 6)
	portalLabel = Instance.new("TextLabel")
	portalLabel.AnchorPoint = Vector2.new(0.5, 0)
	portalLabel.Position = UDim2.new(0.5, 0, 1, 4)
	portalLabel.Size = UDim2.fromOffset(110, 18)
	portalLabel.BackgroundTransparency = 1
	portalLabel.Text = "PORTAL LOCKED"
	portalLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
	portalLabel.TextSize = 13
	portalLabel.Font = Enum.Font.GothamBold
	portalLabel.ZIndex = 4
	portalLabel.Parent = portalFrame

	playerToken = frameAt(arenaFrame, Config.ARENA_WIDTH / 2, Config.ARENA_HEIGHT / 2, 32, 32, Config.PLAYER_COLOR, 0, 8)
	corner(playerToken, 16)
	playerGlow = frameAt(arenaFrame, Config.ARENA_WIDTH / 2, Config.ARENA_HEIGHT / 2, 50, 50, Config.PLAYER_COLOR, 0.65, 7)
	corner(playerGlow, 25)
	playerCore = frameAt(playerToken, 0, 0, 12, 12, Color3.fromRGB(255, 255, 255), 0, 9)
	playerCore.AnchorPoint = Vector2.new(0.5, 0.5)
	playerCore.Position = UDim2.fromScale(0.5, 0.5)
	corner(playerCore, 6)

	shieldRing = frameAt(arenaFrame, Config.ARENA_WIDTH / 2, Config.ARENA_HEIGHT / 2, 52, 52, Color3.fromRGB(80, 230, 255), 1, 8)
	corner(shieldRing, 26)
	local shieldStroke = Instance.new("UIStroke")
	shieldStroke.Color = Color3.fromRGB(80, 230, 255)
	shieldStroke.Thickness = 3
	shieldStroke.Parent = shieldRing
	shieldRing.Visible = false
end

function Arena.getFrame()
	return arenaFrame
end

function Arena.getPortalPosition()
	return PORTAL_X, PORTAL_Y
end

-- Re-skins the arena for a zone: gradient, grid, border and portal accent.
function Arena.applyZone(zoneIdx)
	local zone = Config.ZONES[zoneIdx]
	bgGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, zone.bgTop),
		ColorSequenceKeypoint.new(1, zone.bgBottom),
	})
	for _, line in ipairs(gridLines) do
		line.BackgroundColor3 = zone.grid
	end
	Arena._stroke.Color = zone.accent
	Arena.setPortalActive(false)
end

function Arena.setPortalActive(active)
	portalActive = active
	if active then
		local accent = Config.ZONES[1].accent
		portalFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		portalFrame.BackgroundTransparency = 0.1
		Arena._portalStroke.Color = accent
		portalInner.BackgroundColor3 = accent
		portalLabel.Text = "PORTAL OPEN"
		portalLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	else
		portalFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
		portalFrame.BackgroundTransparency = 0.25
		Arena._portalStroke.Color = Color3.fromRGB(140, 140, 160)
		portalInner.BackgroundColor3 = Color3.fromRGB(120, 120, 140)
		portalLabel.Text = "PORTAL LOCKED"
		portalLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
	end
end

function Arena.setPortalAccent(color)
	if portalActive then
		Arena._portalStroke.Color = color
		portalInner.BackgroundColor3 = color
	end
end

function Arena.updatePortalPulse(t)
	if not portalActive then
		return
	end
	local s = 1 + 0.07 * math.sin(t * 5)
	portalFrame.Size = UDim2.fromOffset(math.floor(56 * s + 0.5), math.floor(56 * s + 0.5))
end

function Arena.setPlayerPosition(x, y)
	playerToken.Position = UDim2.fromOffset(x, y)
	playerGlow.Position = UDim2.fromOffset(x, y)
	shieldRing.Position = UDim2.fromOffset(x, y)
end

function Arena.setPlayerVisible(visible)
	playerToken.Visible = visible
	playerGlow.Visible = visible
end

function Arena.setPlayerDim(dim)
	if dim then
		playerToken.BackgroundTransparency = 0.6
		playerGlow.BackgroundTransparency = 0.9
		playerCore.BackgroundTransparency = 0.6
	else
		playerToken.BackgroundTransparency = 0
		playerGlow.BackgroundTransparency = 0.65
		playerCore.BackgroundTransparency = 0
	end
end

function Arena.setShieldVisible(visible)
	shieldRing.Visible = visible
end

function Arena.setRapidGlow(active)
	if active then
		playerToken.BackgroundColor3 = Color3.fromRGB(255, 210, 60)
		playerGlow.BackgroundColor3 = Color3.fromRGB(255, 210, 60)
	else
		playerToken.BackgroundColor3 = Config.PLAYER_COLOR
		playerGlow.BackgroundColor3 = Config.PLAYER_COLOR
	end
end

function Arena.spawnGhost(x, y, color)
	local ghost = frameAt(entities, x, y, 24, 24, color or Config.PLAYER_COLOR, 0.4, 6)
	corner(ghost, 12)
	local tween = TweenService:Create(
		ghost,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 1, Size = UDim2.fromOffset(12, 12) }
	)
	tween.Completed:Connect(function()
		ghost:Destroy()
	end)
	tween:Play()
end

function Arena.updateTrail(x, y, moving, dt)
	trailTimer -= dt
	if moving and trailTimer <= 0 then
		trailTimer = 0.06
		Arena.spawnGhost(x, y, Config.PLAYER_COLOR)
	end
end

function Arena.sparkle(x, y, color, count)
	for _ = 1, count or 6 do
		local ox = math.random(-14, 14)
		local oy = math.random(-14, 14)
		local bit = frameAt(entities, x + ox, y + oy, 6, 6, color, 0, 9)
		corner(bit, 3)
		local tween = TweenService:Create(
			bit,
			TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 1, Position = UDim2.fromOffset(x + ox * 2, y + oy * 2 - 10) }
		)
		tween.Completed:Connect(function()
			bit:Destroy()
		end)
		tween:Play()
	end
end

function Arena.shake(magnitude)
	shakeTime = 0.25
	shakeMag = magnitude or 6
end

function Arena.updateShake(dt)
	if shakeTime > 0 then
		shakeTime -= dt
		local ox = math.random(-shakeMag, shakeMag)
		local oy = math.random(-shakeMag, shakeMag)
		arenaFrame.Position = UDim2.new(0.5, ox, 0.5, oy)
	else
		arenaFrame.Position = UDim2.fromScale(0.5, 0.5)
	end
end

function Arena.newCrystal(x, y, color)
	local glow = frameAt(entities, x, y, 44, 44, color, 0.7, 5)
	glow.Rotation = 45
	corner(glow, 8)
	local body = frameAt(entities, x, y, 28, 28, color, 0, 6)
	body.Rotation = 45
	corner(body, 5)
	local core = frameAt(body, 0, 0, 10, 10, Color3.fromRGB(255, 255, 255), 0.15, 7)
	core.AnchorPoint = Vector2.new(0.5, 0.5)
	core.Position = UDim2.fromScale(0.5, 0.5)
	corner(core, 2)
	body:GetPropertyChangedSignal("Position"):Connect(function()
		glow.Position = body.Position
	end)
	return body
end

function Arena.newStar(x, y)
	local star = frameAt(entities, x, y, 16, 16, Color3.fromRGB(255, 220, 60), 0, 6)
	star.Rotation = 45
	corner(star, 3)
	local core = frameAt(star, 0, 0, 7, 7, Color3.fromRGB(255, 255, 255), 0, 7)
	core.AnchorPoint = Vector2.new(0.5, 0.5)
	core.Position = UDim2.fromScale(0.5, 0.5)
	corner(core, 2)
	return star
end

function Arena.newShieldPickup(x, y)
	local ring = frameAt(entities, x, y, 30, 30, Color3.fromRGB(80, 230, 255), 1, 6)
	corner(ring, 15)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(80, 230, 255)
	stroke.Thickness = 3
	stroke.Parent = ring
	local core = frameAt(ring, 0, 0, 10, 10, Color3.fromRGB(200, 250, 255), 0, 7)
	core.AnchorPoint = Vector2.new(0.5, 0.5)
	core.Position = UDim2.fromScale(0.5, 0.5)
	corner(core, 5)
	return ring
end

function Arena.newHeartPickup(x, y)
	local heart = frameAt(entities, x, y, 26, 26, Color3.fromRGB(255, 70, 90), 0, 6)
	corner(heart, 13)
	local plus = Instance.new("TextLabel")
	plus.AnchorPoint = Vector2.new(0.5, 0.5)
	plus.Position = UDim2.fromScale(0.5, 0.5)
	plus.Size = UDim2.fromOffset(20, 20)
	plus.BackgroundTransparency = 1
	plus.Text = "+"
	plus.TextColor3 = Color3.fromRGB(255, 255, 255)
	plus.TextSize = 20
	plus.Font = Enum.Font.GothamBlack
	plus.ZIndex = 7
	plus.Parent = heart
	return heart
end

function Arena.newEnemy(kind, x, y)
	local def = Config.ENEMY_TYPES[kind]
	local glow = frameAt(entities, x, y, def.radius * 2 + 16, def.radius * 2 + 16, def.color, 0.75, 5)
	corner(glow, def.radius + 8)
	local body = frameAt(entities, x, y, def.radius * 2, def.radius * 2, def.color, 0, 6)
	corner(body, def.radius)
	local eye = frameAt(body, 0, 0, 8, 8, Color3.fromRGB(255, 255, 255), 0, 7)
	eye.AnchorPoint = Vector2.new(0.5, 0.5)
	eye.Position = UDim2.fromScale(0.5, 0.5)
	corner(eye, 4)
	if kind == "splitter" then
		local ring = Instance.new("UIStroke")
		ring.Color = Color3.fromRGB(255, 255, 255)
		ring.Thickness = 2
		ring.Parent = body
	elseif kind == "shooter" then
		body.Rotation = 45 -- diamond, distinct from round chasers
		glow.Rotation = 45
	elseif kind == "boss" then
		local ring = Instance.new("UIStroke") -- gold ring for the Titan
		ring.Color = Color3.fromRGB(255, 210, 60)
		ring.Thickness = 4
		ring.Parent = body
		eye.Size = UDim2.fromOffset(16, 16)
		corner(eye, 8)
	end
	body:GetPropertyChangedSignal("Position"):Connect(function()
		glow.Position = body.Position
	end)
	return body
end

function Arena.newRapidPickup(x, y)
	local pick = frameAt(entities, x, y, 26, 26, Color3.fromRGB(255, 210, 60), 0, 6)
	pick.Rotation = 45
	corner(pick, 5)
	local core = frameAt(pick, 0, 0, 10, 10, Color3.fromRGB(255, 255, 255), 0, 7)
	core.AnchorPoint = Vector2.new(0.5, 0.5)
	core.Position = UDim2.fromScale(0.5, 0.5)
	corner(core, 2)
	return pick
end

function Arena.newBolt(x, y, angle, color)
	local bolt = frameAt(entities, x, y, 18, 6, color or Color3.fromRGB(255, 250, 180), 0, 7)
	bolt.Rotation = math.deg(angle)
	corner(bolt, 3)
	return bolt
end

function Arena.flyCrystalToPortal(crystalFrame, targetAbsPos, onDone)
	local origin = arenaFrame.AbsolutePosition
	local target = UDim2.fromOffset(
		math.floor(targetAbsPos.X - origin.X + 0.5),
		math.floor(targetAbsPos.Y - origin.Y + 0.5)
	)
	local tween = TweenService:Create(
		crystalFrame,
		TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Position = target, Size = UDim2.fromOffset(8, 8) }
	)
	tween.Completed:Connect(function()
		crystalFrame:Destroy()
		if onDone then
			onDone()
		end
	end)
	tween:Play()
end

function Arena.clearEntities()
	for _, child in ipairs(entities:GetChildren()) do
		child:Destroy()
	end
end

return Arena
