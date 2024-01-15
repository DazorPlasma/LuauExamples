--!strict
--!native

--// Services

local RunService = game:GetService("RunService")

--// Other Variables

local Framerate = {
	FPS = 60,
	FPSInt = 60,
	RenderSteppedDeltaTime = 1 / 60,
	SteppedDeltaTime = 1 / 60,
	HeartbeatDeltaTime = 1 / 60,
}

--// Main Code

RunService.RenderStepped:Connect(function(deltaTime: number)
	local fps: number = 1 / deltaTime
	Framerate.FPS = fps
	Framerate.FPSInt = math.round(fps)
	Framerate.RenderSteppedDeltaTime = deltaTime
end)

RunService.Stepped:Connect(function(_, deltaTime)
	Framerate.SteppedDeltaTime = deltaTime
end)

RunService.Heartbeat:Connect(function(deltaTime: number)
	Framerate.HeartbeatDeltaTime = deltaTime
end)

return Framerate
