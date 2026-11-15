-- Prism Rush: keyboard and mouse polling via IsKeyDown every frame (InputBegan misses the arrows: camera scripts swallow them). Dash uses edge detection; shooting is hold-to-fire.

local UserInputService = game:GetService("UserInputService")

local Input = {}

local prevSpace = false
local dashQueued = false

function Input.update()
	local space = UserInputService:IsKeyDown(Enum.KeyCode.Space)
	dashQueued = space and not prevSpace
	prevSpace = space
end

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

-- Mouse position in arena-local pixels, or nil outside the arena frame.
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
