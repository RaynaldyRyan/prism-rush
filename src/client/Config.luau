-- Prism Rush: tuning numbers and the five zone palettes in one place.

local Config = {}

Config.ARENA_WIDTH = 1040
Config.ARENA_HEIGHT = 600

Config.PLAYER_RADIUS = 16
Config.PLAYER_SPEED = 260
Config.PLAYER_COLOR = Color3.fromRGB(170, 240, 255)

Config.DASH_MULTIPLIER = 2.5
Config.DASH_TIME = 0.22
Config.DASH_COOLDOWN = 2.5

Config.MINE_RANGE = 70
Config.MINE_TIME = 0.8
Config.CRYSTALS_PER_ZONE = 6

Config.BOLT_SPEED = 700
Config.FIRE_RATE = 0.25
Config.RAPID_RATE = 0.1
Config.RAPID_TIME = 8
Config.BOLT_DAMAGE = 1

Config.COMBO_WINDOW = 3
Config.MAX_COMBO = 3
Config.MAX_LIVES = 3
Config.INVULN_TIME = 1.0

Config.SCORES = {
	crystal = 50,
	star = 10,
	chaser = 25,
	splitter = 40,
	mini = 15,
	shooter = 35,
	zoneClear = 200,
}

-- One entry per zone: look first, then difficulty.
Config.ZONES = {
	{
		name = "Ember Grotto",
		subtitle = "Mine 6 crystals to charge the portal",
		bgTop = Color3.fromRGB(58, 28, 18),
		bgBottom = Color3.fromRGB(96, 40, 20),
		grid = Color3.fromRGB(255, 140, 60),
		crystal = Color3.fromRGB(255, 180, 40),
		accent = Color3.fromRGB(255, 110, 60),
		enemyCap = 3,
		enemySpeed = 70,
		spawnInterval = 3.0,
		splitterChance = 0,
	},
	{
		name = "Tide Cavern",
		subtitle = "Splitters ahead — they break into minis",
		bgTop = Color3.fromRGB(8, 32, 64),
		bgBottom = Color3.fromRGB(10, 60, 110),
		grid = Color3.fromRGB(60, 200, 255),
		crystal = Color3.fromRGB(80, 230, 255),
		accent = Color3.fromRGB(0, 200, 255),
		enemyCap = 4,
		enemySpeed = 85,
		spawnInterval = 2.8,
		splitterChance = 0.25,
	},
	{
		name = "Bloom Hollow",
		subtitle = "Faster chasers — keep moving",
		bgTop = Color3.fromRGB(8, 48, 40),
		bgBottom = Color3.fromRGB(16, 90, 60),
		grid = Color3.fromRGB(90, 255, 170),
		crystal = Color3.fromRGB(120, 255, 140),
		accent = Color3.fromRGB(80, 255, 160),
		enemyCap = 5,
		enemySpeed = 100,
		spawnInterval = 2.6,
		splitterChance = 0.3,
	},
	{
		name = "Prism Core",
		subtitle = "The portal leads to the Titan",
		bgTop = Color3.fromRGB(38, 16, 72),
		bgBottom = Color3.fromRGB(80, 24, 120),
		grid = Color3.fromRGB(220, 120, 255),
		crystal = Color3.fromRGB(255, 120, 230),
		accent = Color3.fromRGB(200, 100, 255),
		enemyCap = 6,
		enemySpeed = 115,
		spawnInterval = 2.4,
		splitterChance = 0.35,
	},
	-- Zone 5: no crystals, no spawns — the Titan boss lives here.
	{
		name = "Titan's Sanctum",
		subtitle = "Defeat the Prism Titan",
		bgTop = Color3.fromRGB(24, 8, 44),
		bgBottom = Color3.fromRGB(60, 12, 90),
		grid = Color3.fromRGB(255, 90, 220),
		crystal = Color3.fromRGB(255, 120, 230),
		accent = Color3.fromRGB(255, 60, 200),
		enemyCap = 0,
		enemySpeed = 100,
		spawnInterval = 3.0,
		splitterChance = 0,
	},
}

Config.ENEMY_TYPES = {
	chaser = { radius = 15, hp = 1, speedScale = 1.0, color = Color3.fromRGB(255, 70, 80) },
	splitter = { radius = 19, hp = 2, speedScale = 0.6, color = Color3.fromRGB(190, 90, 255) },
	mini = { radius = 10, hp = 1, speedScale = 1.5, color = Color3.fromRGB(255, 90, 200) },
	shooter = { radius = 14, hp = 2, speedScale = 0.9, color = Color3.fromRGB(255, 60, 180) },
	boss = { radius = 45, hp = 30, speedScale = 1.0, color = Color3.fromRGB(255, 80, 160) },
}

return Config
