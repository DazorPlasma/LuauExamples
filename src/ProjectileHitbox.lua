--!strict

--// Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

--// Modules

local HelperTypes = require(ReplicatedStorage.SharedModules.HelperTypes)
local Utils = require(ReplicatedFirst.ClientModules.Utils)
local Framerate = require(ReplicatedFirst.ClientModules.Framerate)
--local Debug = require(rs.SharedModules.Debug)

--// Other Variables

local ProjectileHitbox = {}
local step = RunService.Stepped

--// Main Code

ProjectileHitbox.__index = ProjectileHitbox
export type self = {
	Owner: HelperTypes.characterDataType?,
	InitialFrame: CFrame,
	CurrentFrame: CFrame,
	Speed: number,
	Size: number,
	Range: number,
	hasHit: boolean,
	forcedToStop: boolean,
	new: (projectileInfo) -> ProjectileHitbox,
	_onStep: (ProjectileHitbox) -> (),
	_onHit: (self: ProjectileHitbox) -> (),
	CallOnHit: () -> (),
}
export type ProjectileHitbox = typeof(setmetatable({} :: self, ProjectileHitbox))
export type projectileInfo = {
	Owner: HelperTypes.characterDataType?,
	Frame: CFrame,
	Speed: number,
	Size: number,
	Range: number,
	CallOnHit: () -> (),
}

ProjectileHitbox._onHit = function(self: ProjectileHitbox, _hitPosition: Vector3)
	self.hasHit = true
	self.CallOnHit()
end

local gameChars = workspace.GameCharacters
local onStep = function(self: ProjectileHitbox)
	local nowPos: Vector3 = self.CurrentFrame.Position
	local hitPart: BasePart? = nil
	-- check in radius of 1
	for _, v: BasePart in workspace:GetPartBoundsInRadius(nowPos, 1) do
		if not v.CanTouch then
			continue
		end
		if self.Owner then
			if Utils.areCharactersFriendly(self.Owner, v.Parent) then
				continue
			end
			if v:IsDescendantOf(self.Owner) then
				continue
			end
		end
		hitPart = v
		break
	end
	-- check in actual radius; fair player hitbox
	if not hitPart then
		for _, v: BasePart in workspace:GetPartBoundsInRadius(nowPos, self.Size) do
			local possibleEnemyChar = v.Parent :: HelperTypes.characterDataType
			if not possibleEnemyChar or possibleEnemyChar.Parent ~= gameChars then
				continue
			end
			if self.Owner then
				if possibleEnemyChar == self.Owner then
					continue
				end
				if Utils.areCharactersFriendly(self.Owner, possibleEnemyChar) then
					continue
				end
			end
			hitPart = v
			break
		end
	end

	if hitPart then
		ProjectileHitbox._onHit(self, nowPos)
	else
		-- move forward
		if (self.InitialFrame.Position - self.CurrentFrame.Position).Magnitude > self.Range then
			self.forcedToStop = true
			return
		end
		self.CurrentFrame += self.CurrentFrame.LookVector * self.Speed * Framerate.SteppedDeltaTime
		--Debug.visualBall(0.03, self.CurrentFrame.Position, self.Size, Color3.new(0, 1, 0))
	end
end

ProjectileHitbox.new = function(info: projectileInfo)
	local self = setmetatable({} :: self, ProjectileHitbox)
	self.Owner = info.Owner
	self.Range = info.Range
	self.Speed = info.Speed
	self.Size = info.Size
	self.CurrentFrame = info.Frame
	self.InitialFrame = info.Frame
	self.hasHit = false
	self.CallOnHit = info.CallOnHit
	task.spawn(function()
		while self.hasHit == false do
			if self.forcedToStop then
				return
			end
			onStep(self)
			step:Wait()
		end
	end)
end

return ProjectileHitbox
