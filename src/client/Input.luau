-- Prism Rush: keyboard and mouse polling. Everything is read with IsKeyDown
-- every frame: Roblox's default camera scripts swallow the arrow keys in
-- InputBegan when gameProcessedEvent is true, so a handler that returns on
-- gameProcessedEvent never sees them. Dash uses edge detection on top of
-- the same poll; shooting is hold-to-fire with its own rate gate.

local UserInputService = game:GetService("UserInputService")

local Input = {}

local prevSpace = false
local dashQueued = false

-- Call once per frame, before reading anything else.
function Input.update()
	local space = UserInputService:IsKeyDown(Enum.KeyCode.Space)
	dashQueued = space and not prevSpace
	prevSpace = space
end

-- True once per Space press; consuming it clears the flag.
function Input.dashPressed()
	local queued = dashQueued
	dashQueued = false
	return queued
end

function Input.moveVector()
	local dx = 0
	local dy = 0
	if UserInputService:IsKeyDown(Enum.KeyCode.Left) or UserInputService:IsKeyDown(Enum.KeyCode.A) then
		dx -= 1
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.Right) or UserInputService:IsKeyDown(Enum.KeyCode.D) then
		dx += 1
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.Up) or UserInputService:IsKeyDown(Enum.KeyCode.W) then
		dy -= 1
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.Down) or UserInputService:IsKeyDown(Enum.KeyCode.S) then
		dy += 1
	end
	if dx ~= 0 and dy ~= 0 then
		-- Diagonals cover the same distance as straight lines.
		dx *= 0.7071
		dy *= 0.7071
	end
	return dx, dy
end

function Input.isMining()
	return UserInputService:IsKeyDown(Enum.KeyCode.E)
end

function Input.isFiring()
	return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
end

-- The mouse position in arena-local pixels, or nil when the mouse is
-- outside the arena frame. The ScreenGui ignores the topbar inset, so
-- GetMouseLocation and AbsolutePosition share the same origin.
function Input.mouseArenaPos(arenaFrame)
	local mouse = UserInputService:GetMouseLocation()
	local origin = arenaFrame.AbsolutePosition
	local x = mouse.X - origin.X
	local y = mouse.Y - origin.Y
	if x < 0 or y < 0 or x > arenaFrame.AbsoluteSize.X or y > arenaFrame.AbsoluteSize.Y then
		return nil
	end
	return x, y
end

function Input.reset()
	prevSpace = false
	dashQueued = false
end

return Input
