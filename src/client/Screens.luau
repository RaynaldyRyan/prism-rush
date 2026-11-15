-- Prism Rush: the screens (start, HUD, banners, end, popups, flash, confetti). Reads State on refresh. All HUD text stays clear of the top-left corner, where Roblox's menu buttons sit.

local TweenService = game:GetService("TweenService")

local Config = require(script.Parent.Config)
local State = require(script.Parent.State)

local Screens = {}

local arenaFrame = nil
local hud = nil
local zoneLabel = nil
local crystalLabel = nil
local chargeFill = nil
local chargeBar = nil
local bossLabel = nil
local bossFill = nil
local bossBar = nil
local rapidFill = nil
local rapidBar = nil
local scoreLabel = nil
local bestLabel = nil
local comboLabel = nil
local heartDots = {}
local dashFill = nil
local dashLabel = nil
local startOverlay = nil
local startBestLabel = nil
local endOverlay = nil
local endTitle = nil
local endStats = nil
local bannerTitle = nil
local bannerSub = nil
local bannerFrame = nil
local flash = nil
local confettiBox = nil

local bannerToken = 0
local confettiToken = 0

local function label(parent, text, size, color, font, zIndex)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = color
	l.TextSize = size
	l.Font = font or Enum.Font.GothamBold
	l.ZIndex = zIndex or 20
	l.Parent = parent
	return l
end

local function bar(parent, x, y, w, h, fillColor)
	local bg = Instance.new("Frame")
	bg.AnchorPoint = Vector2.new(0.5, 0)
	bg.Position = UDim2.fromOffset(x, y)
	bg.Size = UDim2.fromOffset(w, h)
	bg.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	bg.BackgroundTransparency = 0.3
	bg.BorderSizePixel = 0
	bg.ZIndex = 20
	bg.Parent = parent
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, h / 2)
	c.Parent = bg
	local fill = Instance.new("Frame")
	fill.AnchorPoint = Vector2.new(0, 0.5)
	fill.Position = UDim2.fromScale(0, 0.5)
	fill.Size = UDim2.fromOffset(0, h)
	fill.BackgroundColor3 = fillColor
	fill.BorderSizePixel = 0
	fill.ZIndex = 21
	fill.Parent = bg
	local c2 = Instance.new("UICorner")
	c2.CornerRadius = UDim.new(0, h / 2)
	c2.Parent = fill
	return bg, fill
end

function Screens.build(gui, arena, callbacks)
	arenaFrame = arena

	hud = Instance.new("Frame")
	hud.Name = "HUD"
	hud.Size = UDim2.fromScale(1, 1)
	hud.BackgroundTransparency = 1
	hud.Visible = false
	hud.Parent = gui

	zoneLabel = label(hud, "ZONE 1 — EMBER GROTTO", 22, Color3.fromRGB(255, 255, 255), Enum.Font.GothamBlack)
	zoneLabel.AnchorPoint = Vector2.new(0.5, 0)
	zoneLabel.Position = UDim2.new(0.5, 0, 0, 10)
	zoneLabel.Size = UDim2.fromOffset(500, 28)

	crystalLabel = label(hud, "CRYSTALS 0/6", 17, Color3.fromRGB(255, 220, 120), Enum.Font.GothamBold)
	crystalLabel.AnchorPoint = Vector2.new(0.5, 0)
	crystalLabel.Position = UDim2.new(0.5, 0, 0, 40)
	crystalLabel.Size = UDim2.fromOffset(300, 22)

	chargeBar, chargeFill = bar(hud, 0, 66, 220, 14, Color3.fromRGB(255, 180, 40))
	chargeBar.AnchorPoint = Vector2.new(0.5, 0)
	chargeBar.Position = UDim2.new(0.5, 0, 0, 66)

	bossLabel = label(hud, "PRISM TITAN", 17, Color3.fromRGB(255, 120, 200), Enum.Font.GothamBlack)
	bossLabel.AnchorPoint = Vector2.new(0.5, 0)
	bossLabel.Position = UDim2.new(0.5, 0, 0, 40)
	bossLabel.Size = UDim2.fromOffset(300, 22)
	bossLabel.Visible = false

	bossBar, bossFill = bar(hud, 0, 66, 220, 14, Color3.fromRGB(255, 80, 160))
	bossBar.AnchorPoint = Vector2.new(0.5, 0)
	bossBar.Position = UDim2.new(0.5, 0, 0, 66)
	bossBar.Visible = false

	scoreLabel = label(hud, "SCORE 0", 26, Color3.fromRGB(255, 255, 255), Enum.Font.GothamBlack)
	scoreLabel.AnchorPoint = Vector2.new(1, 0)
	scoreLabel.Position = UDim2.new(1, -16, 0, 10)
	scoreLabel.Size = UDim2.fromOffset(300, 32)
	scoreLabel.TextXAlignment = Enum.TextXAlignment.Right

	bestLabel = label(hud, "BEST 0", 16, Color3.fromRGB(200, 200, 210), Enum.Font.GothamBold)
	bestLabel.AnchorPoint = Vector2.new(1, 0)
	bestLabel.Position = UDim2.new(1, -16, 0, 44)
	bestLabel.Size = UDim2.fromOffset(300, 20)
	bestLabel.TextXAlignment = Enum.TextXAlignment.Right

	-- Bottom center: combo (top-right is covered by Roblox's player-list chip).
	comboLabel = label(hud, "COMBO x1", 24, Color3.fromRGB(160, 160, 170), Enum.Font.GothamBlack)
	comboLabel.AnchorPoint = Vector2.new(0.5, 1)
	comboLabel.Position = UDim2.new(0.5, 0, 1, -16)
	comboLabel.Size = UDim2.fromOffset(300, 30)
	comboLabel.TextXAlignment = Enum.TextXAlignment.Center

	for i = 1, Config.MAX_LIVES do
		local dot = Instance.new("Frame")
		dot.AnchorPoint = Vector2.new(0, 1)
		dot.Position = UDim2.new(0, 16 + (i - 1) * 36, 1, -16)
		dot.Size = UDim2.fromOffset(28, 28)
		dot.BackgroundColor3 = Color3.fromRGB(255, 70, 90)
		dot.BorderSizePixel = 0
		dot.ZIndex = 20
		dot.Parent = hud
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 14)
		c.Parent = dot
		table.insert(heartDots, dot)
	end

	dashLabel = label(hud, "DASH READY [SPACE]", 15, Color3.fromRGB(140, 240, 255), Enum.Font.GothamBold)
	dashLabel.AnchorPoint = Vector2.new(1, 1)
	dashLabel.Position = UDim2.new(1, -16, 1, -46)
	dashLabel.Size = UDim2.fromOffset(220, 20)
	dashLabel.TextXAlignment = Enum.TextXAlignment.Right

	local dashBar, fill = bar(hud, 0, 0, 180, 12, Color3.fromRGB(140, 240, 255))
	dashBar.AnchorPoint = Vector2.new(1, 1)
	dashBar.Position = UDim2.new(1, -16, 1, -16)
	dashFill = fill

	rapidBar, rapidFill = bar(hud, 0, 0, 180, 8, Color3.fromRGB(255, 210, 60))
	rapidBar.AnchorPoint = Vector2.new(1, 1)
	rapidBar.Position = UDim2.new(1, -16, 1, -62)
	rapidBar.Visible = false

	bannerFrame = Instance.new("Frame")
	bannerFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	bannerFrame.Position = UDim2.fromScale(0.5, 0.32)
	bannerFrame.Size = UDim2.fromOffset(560, 110)
	bannerFrame.BackgroundTransparency = 1
	bannerFrame.Parent = gui
	bannerTitle = label(bannerFrame, "", 40, Color3.fromRGB(255, 255, 255), Enum.Font.GothamBlack, 30)
	bannerTitle.AnchorPoint = Vector2.new(0.5, 0)
	bannerTitle.Position = UDim2.fromScale(0.5, 0)
	bannerTitle.Size = UDim2.fromOffset(560, 52)
	bannerTitle.TextTransparency = 1
	bannerSub = label(bannerFrame, "", 20, Color3.fromRGB(230, 230, 240), Enum.Font.GothamBold, 30)
	bannerSub.AnchorPoint = Vector2.new(0.5, 0)
	bannerSub.Position = UDim2.fromScale(0.5, 0.55)
	bannerSub.Size = UDim2.fromOffset(560, 30)
	bannerSub.TextTransparency = 1

	flash = Instance.new("Frame")
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = Color3.fromRGB(255, 40, 50)
	flash.BackgroundTransparency = 1
	flash.BorderSizePixel = 0
	flash.ZIndex = 40
	flash.Parent = gui

	confettiBox = Instance.new("Frame")
	confettiBox.Size = UDim2.fromScale(1, 1)
	confettiBox.BackgroundTransparency = 1
	confettiBox.ZIndex = 35
	confettiBox.Parent = gui

	startOverlay = Instance.new("Frame")
	startOverlay.Size = UDim2.fromScale(1, 1)
	startOverlay.BackgroundColor3 = Color3.fromRGB(10, 8, 24)
	startOverlay.BackgroundTransparency = 0.35
	startOverlay.BorderSizePixel = 0
	startOverlay.ZIndex = 50
	startOverlay.Parent = gui

	local title = label(startOverlay, "PRISM RUSH", 54, Color3.fromRGB(255, 255, 255), Enum.Font.GothamBlack, 51)
	title.AnchorPoint = Vector2.new(0.5, 0)
	title.Position = UDim2.new(0.5, 0, 0.14, 0)
	title.Size = UDim2.fromOffset(640, 64)
	local titleGrad = Instance.new("UIGradient")
	titleGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 120, 120)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 220, 100)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 220, 255)),
	})
	titleGrad.Parent = title

	local sub = label(startOverlay, "Mine crystals. Blast drones. Restore the Prism.", 20, Color3.fromRGB(230, 230, 240), Enum.Font.GothamBold, 51)
	sub.AnchorPoint = Vector2.new(0.5, 0)
	sub.Position = UDim2.new(0.5, 0, 0.14, 70)
	sub.Size = UDim2.fromOffset(640, 28)

	local howto = label(
		startOverlay,
		"WASD / Arrows — move     SPACE — dash\nHold E near a crystal — mine it     CLICK — shoot\nClear 4 zones, then defeat the Prism Titan to win",
		18,
		Color3.fromRGB(210, 210, 220),
		Enum.Font.Gotham,
		51
	)
	howto.AnchorPoint = Vector2.new(0.5, 0)
	howto.Position = UDim2.new(0.5, 0, 0.32, 0)
	howto.Size = UDim2.fromOffset(640, 90)

	local playButton = Instance.new("TextButton")
	playButton.AnchorPoint = Vector2.new(0.5, 0)
	playButton.Position = UDim2.new(0.5, 0, 0.52, 0)
	playButton.Size = UDim2.fromOffset(260, 60)
	playButton.BackgroundColor3 = Color3.fromRGB(255, 180, 40)
	playButton.Text = "PLAY"
	playButton.TextColor3 = Color3.fromRGB(40, 20, 0)
	playButton.TextSize = 28
	playButton.Font = Enum.Font.GothamBlack
	playButton.ZIndex = 51
	playButton.Parent = startOverlay
	local pc = Instance.new("UICorner")
	pc.CornerRadius = UDim.new(0, 16)
	pc.Parent = playButton
	playButton.MouseButton1Click:Connect(callbacks.onPlay)

	startBestLabel = label(startOverlay, "BEST 0", 18, Color3.fromRGB(200, 200, 210), Enum.Font.GothamBold, 51)
	startBestLabel.AnchorPoint = Vector2.new(0.5, 0)
	startBestLabel.Position = UDim2.new(0.5, 0, 0.52, 76)
	startBestLabel.Size = UDim2.fromOffset(300, 24)

	endOverlay = Instance.new("Frame")
	endOverlay.Size = UDim2.fromScale(1, 1)
	endOverlay.BackgroundColor3 = Color3.fromRGB(10, 8, 24)
	endOverlay.BackgroundTransparency = 0.35
	endOverlay.BorderSizePixel = 0
	endOverlay.ZIndex = 50
	endOverlay.Visible = false
	endOverlay.Parent = gui

	endTitle = label(endOverlay, "", 48, Color3.fromRGB(255, 255, 255), Enum.Font.GothamBlack, 51)
	endTitle.AnchorPoint = Vector2.new(0.5, 0)
	endTitle.Position = UDim2.new(0.5, 0, 0.2, 0)
	endTitle.Size = UDim2.fromOffset(640, 60)

	endStats = label(endOverlay, "", 22, Color3.fromRGB(230, 230, 240), Enum.Font.GothamBold, 51)
	endStats.AnchorPoint = Vector2.new(0.5, 0)
	endStats.Position = UDim2.new(0.5, 0, 0.34, 0)
	endStats.Size = UDim2.fromOffset(640, 120)

	local againButton = Instance.new("TextButton")
	againButton.AnchorPoint = Vector2.new(0.5, 0)
	againButton.Position = UDim2.new(0.5, 0, 0.56, 0)
	againButton.Size = UDim2.fromOffset(280, 60)
	againButton.BackgroundColor3 = Color3.fromRGB(120, 220, 255)
	againButton.Text = "PLAY AGAIN"
	againButton.TextColor3 = Color3.fromRGB(10, 30, 50)
	againButton.TextSize = 26
	againButton.Font = Enum.Font.GothamBlack
	againButton.ZIndex = 51
	againButton.Parent = endOverlay
	local ac = Instance.new("UICorner")
	ac.CornerRadius = UDim.new(0, 16)
	ac.Parent = againButton
	againButton.MouseButton1Click:Connect(callbacks.onPlayAgain)
end

function Screens.showStart(best)
	startBestLabel.Text = "BEST " .. tostring(best or 0)
	startOverlay.Visible = true
	hud.Visible = false
end

function Screens.hideStart()
	startOverlay.Visible = false
end

function Screens.showHUD()
	hud.Visible = true
end

function Screens.hideHUD()
	hud.Visible = false
end

function Screens.hideEnd()
	endOverlay.Visible = false
end

function Screens.showWin(score, elapsed, crystals, best)
	endTitle.Text = "TITAN DEFEATED!"
	endTitle.TextColor3 = Color3.fromRGB(255, 220, 100)
	endStats.Text = string.format(
		"PRISM RESTORED!  •  Score %d  •  Time %d:%02d  •  Crystals %d\nBest %d",
		score,
		math.floor(elapsed / 60),
		math.floor(elapsed % 60),
		crystals,
		best
	)
	endOverlay.Visible = true
end

function Screens.showGameOver(zone, score, crystals, best)
	endTitle.Text = "GAME OVER"
	endTitle.TextColor3 = Color3.fromRGB(255, 100, 110)
	endStats.Text = string.format(
		"Reached Zone %d  •  Score %d  •  Crystals %d\nBest %d",
		zone,
		score,
		crystals,
		best
	)
	endOverlay.Visible = true
end

function Screens.refresh()
	local zone = Config.ZONES[State.zone]
	zoneLabel.Text = "ZONE " .. tostring(State.zone) .. " — " .. string.upper(zone.name)
	zoneLabel.TextColor3 = zone.accent
	local bossZone = State.zone == 5
	crystalLabel.Visible = not bossZone
	chargeBar.Visible = not bossZone
	bossLabel.Visible = bossZone
	bossBar.Visible = bossZone
	if bossZone and State.bossMax > 0 then
		bossFill.Size = UDim2.fromOffset(math.floor(220 * State.bossHp / State.bossMax + 0.5), 14)
	end
	crystalLabel.Text = "CRYSTALS " .. tostring(State.portalCharge) .. "/" .. tostring(Config.CRYSTALS_PER_ZONE)
	chargeFill.Size = UDim2.fromOffset(
		math.floor(220 * State.portalCharge / Config.CRYSTALS_PER_ZONE + 0.5),
		14
	)
	chargeFill.BackgroundColor3 = zone.crystal
	rapidBar.Visible = State.rapidTimer > 0
	if State.rapidTimer > 0 then
		rapidFill.Size = UDim2.fromOffset(math.floor(180 * State.rapidTimer / Config.RAPID_TIME + 0.5), 8)
	end
	scoreLabel.Text = "SCORE " .. tostring(State.score)
	bestLabel.Text = "BEST " .. tostring(State.best)
	comboLabel.Text = "COMBO x" .. tostring(State.combo)
	if State.combo >= 3 then
		comboLabel.TextColor3 = Color3.fromRGB(255, 100, 220)
	elseif State.combo == 2 then
		comboLabel.TextColor3 = Color3.fromRGB(255, 220, 80)
	else
		comboLabel.TextColor3 = Color3.fromRGB(160, 160, 170)
	end
	for i, dot in ipairs(heartDots) do
		if i <= State.lives then
			dot.BackgroundColor3 = Color3.fromRGB(255, 70, 90)
			dot.BackgroundTransparency = 0
		else
			dot.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
			dot.BackgroundTransparency = 0.3
		end
	end
end

function Screens.setDashFraction(fraction)
	dashFill.Size = UDim2.fromOffset(math.floor(180 * math.clamp(fraction, 0, 1) + 0.5), 12)
	if fraction >= 1 then
		dashFill.BackgroundColor3 = Color3.fromRGB(140, 240, 255)
		dashLabel.Text = "DASH READY [SPACE]"
		dashLabel.TextColor3 = Color3.fromRGB(140, 240, 255)
	else
		dashFill.BackgroundColor3 = Color3.fromRGB(90, 140, 160)
		dashLabel.Text = "DASH..."
		dashLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
	end
end

-- A big center banner (the token guard stops a stale fade cutting a newer one).
function Screens.showBanner(title, subtitle)
	bannerToken += 1
	local token = bannerToken
	bannerTitle.Text = title
	bannerSub.Text = subtitle or ""
	bannerTitle.TextTransparency = 0
	bannerSub.TextTransparency = 0
	task.delay(1.6, function()
		if token ~= bannerToken then
			return
		end
		local t1 = TweenService:Create(bannerTitle, TweenInfo.new(0.5), { TextTransparency = 1 })
		local t2 = TweenService:Create(bannerSub, TweenInfo.new(0.5), { TextTransparency = 1 })
		t1:Play()
		t2:Play()
	end)
end

function Screens.showPopup(x, y, text, color)
	local pop = Instance.new("TextLabel")
	pop.AnchorPoint = Vector2.new(0.5, 0.5)
	pop.Position = UDim2.fromOffset(x, y)
	pop.Size = UDim2.fromOffset(120, 28)
	pop.BackgroundTransparency = 1
	pop.Text = text
	pop.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	pop.TextSize = 22
	pop.Font = Enum.Font.GothamBlack
	pop.ZIndex = 30
	pop.Parent = arenaFrame
	local tween = TweenService:Create(
		pop,
		TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = UDim2.fromOffset(x, y - 34), TextTransparency = 1 }
	)
	tween.Completed:Connect(function()
		pop:Destroy()
	end)
	tween:Play()
end

function Screens.flashDamage()
	flash.BackgroundTransparency = 0.35
	TweenService:Create(flash, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
end

function Screens.getChargeBarAbsPos()
	local pos = chargeBar.AbsolutePosition
	local size = chargeBar.AbsoluteSize
	return Vector2.new(pos.X + size.X / 2, pos.Y + size.Y / 2)
end

function Screens.startConfetti()
	confettiToken += 1
	local token = confettiToken
	local colors = {
		Color3.fromRGB(255, 100, 120),
		Color3.fromRGB(255, 200, 60),
		Color3.fromRGB(100, 255, 140),
		Color3.fromRGB(90, 200, 255),
		Color3.fromRGB(220, 120, 255),
	}
	task.spawn(function()
		while token == confettiToken do
			for _ = 1, 6 do
				if token ~= confettiToken then
					return
				end
				local piece = Instance.new("Frame")
				piece.AnchorPoint = Vector2.new(0.5, 0.5)
				piece.Position = UDim2.fromOffset(math.random(0, 1280), -10)
				piece.Size = UDim2.fromOffset(math.random(6, 12), math.random(6, 12))
				piece.BackgroundColor3 = colors[math.random(1, #colors)]
				piece.BorderSizePixel = 0
				piece.ZIndex = 35
				piece.Parent = confettiBox
				local fall = TweenService:Create(
					piece,
					TweenInfo.new(math.random(15, 30) / 10, Enum.EasingStyle.Linear),
					{ Position = UDim2.fromOffset(math.random(0, 1280), 760), Rotation = math.random(-360, 360) }
				)
				fall.Completed:Connect(function()
					piece:Destroy()
				end)
				fall:Play()
			end
			task.wait(0.25)
		end
	end)
end

function Screens.stopConfetti()
	confettiToken += 1
	for _, child in ipairs(confettiBox:GetChildren()) do
		child:Destroy()
	end
end

return Screens
