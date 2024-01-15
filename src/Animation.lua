--!strict

--// Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--// Modules

local HelperTypes = require(ReplicatedStorage.SharedModules.HelperTypes)

--// Other Variables

local animationsFolder = ReplicatedStorage.Assets.Animations
local lp: Player = Players.LocalPlayer
local loadedAnimations: { [string]: AnimationTrack } = {}
local playingAnimations: { [string]: boolean } = {}

local Animation = {
	animationsLoaded = false
}

--// Main Code

Animation.stopAnimation = function(animationName: string)
	playingAnimations[animationName] = nil
	assert(loadedAnimations[animationName], `{animationName} not found!`)
	loadedAnimations[animationName]:Stop()
end

Animation.playAnimation = function(animationName: string): AnimationTrack
	if playingAnimations[animationName] then
		return loadedAnimations[animationName]
	end
	playingAnimations[animationName] = true
	assert(loadedAnimations[animationName], `{animationName} not found!`)
	loadedAnimations[animationName]:Play()
	return loadedAnimations[animationName]
end

local CurrentAnimatedChar: Model? = nil

local function addPathedAnimations(animator: Animator, currentPath: string, where: Instance)
	local append = if currentPath == "" then where.Name else "/" .. where.Name
	currentPath = currentPath .. append
	if where:IsA("Animation") then
		loadedAnimations[currentPath] = animator:LoadAnimation(where)
		loadedAnimations[currentPath].Stopped:Connect(function()
			playingAnimations[currentPath] = nil
		end)
	elseif where:IsA("Folder") then
		for _, v in where:GetChildren() do
			addPathedAnimations(animator, currentPath, v)
		end
	else
		error(`Foreign thing in Animation folder: {tostring(where)}`)
	end
end

local function reloadAnimations(chr: HelperTypes.characterDataType)
	if CurrentAnimatedChar == chr then
		return
	end
	Animation.animationsLoaded = false
	CurrentAnimatedChar = chr
	chr:WaitForChild("HumanoidRootPart")
	chr:WaitForChild("Head")
	local animator = chr:WaitForChild("Humanoid"):WaitForChild("Animator") :: Animator
	for i, v in loadedAnimations do
		Animation.stopAnimation(i)
		v:Destroy()
	end
	loadedAnimations = {}
	for _, v in animationsFolder:GetChildren() do
		addPathedAnimations(animator, "", v)
	end
	Animation.animationsLoaded = true
	ReplicatedStorage.Bindables.AnimationsLoaded:Fire()
end

lp.CharacterAdded:Connect(reloadAnimations)

if lp.Character then
	reloadAnimations(lp.Character :: HelperTypes.characterDataType)
end

return Animation
