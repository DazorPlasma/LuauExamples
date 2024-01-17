--!strict

--// Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

--// Modules

local WalkSounds = require(ReplicatedFirst.ClientModules.WalkSounds)
local _CamShake = require(ReplicatedFirst.ClientModules.WorldEffects._CamShake)
local Framerate = require(ReplicatedFirst.ClientModules.Framerate)
local Particles = require(ReplicatedFirst.ClientModules.Particles)
local HelperTypes = require(ReplicatedStorage.SharedModules.HelperTypes)

--// Other Variables

local lp = Players.LocalPlayer
local assets = ReplicatedStorage.Assets
local effectsFolder = assets.Effects
local clientEffects = workspace.ClientEffects
local heartbeat = RunService.Heartbeat
local renderStepped = RunService.RenderStepped

--// Main Code

local WorldEffects = {}

-- Shockwave Parts

local wave = effectsFolder.DefaultShockwave
local _coilShockwave = effectsFolder.CoilShockwave
local _ballShockwave = effectsFolder.BallShockwave
local textureShockwave = effectsFolder.TextureShockwave
local hqBallShockwave = effectsFolder.hqsphere
local _smokeShockwave = effectsFolder.Smoke

-- If playSound is given a position and not a part, make one

local soundPart = Instance.new("Part")
soundPart.Anchored = true
soundPart.CanCollide = false
soundPart.CanTouch = false
soundPart.CanQuery = false
soundPart.Size = Vector3.new(0, 0, 0)
soundPart.Transparency = 1

local soundsFolder = assets.Sounds
WorldEffects.playSound = function(
	name: string,
	parent: Vector3 | CFrame | BasePart | nil,
	volume: number?,
	pitch: number?,
	looped: boolean?,
	distance: number?,
	new_name: string?
): Sound
	local sound = soundsFolder
	for _, v in string.split(name, "/") do
		sound = sound:FindFirstChild(v)
	end
	if typeof(sound) ~= "Instance" then
		error("Couldn't find sound named \"" .. tostring(name) .. '"!')
	end
	if not sound:IsA("Sound") then
		error("Instance was found but isn't a sound! (" .. tostring(name) .. ")")
	end
	sound = sound:Clone()
	if looped then
		sound.Looped = true
	end
	if distance then
		sound.RollOffMaxDistance = distance
	end
	if new_name then
		sound.Name = new_name
	end
	if volume then
		sound.Volume = volume
	end
	if pitch then
		sound.PlaybackSpeed = pitch
	end
	if parent == nil then
		sound.Parent = workspace.ClientEffects
	elseif typeof(parent) == "Vector3" or typeof(parent) == "CFrame" then
		local newSoundPart: Part = soundPart:Clone()
		if typeof(parent) == "CFrame" then
			newSoundPart.Position = parent.Position
		else
			newSoundPart.Position = parent
		end
		newSoundPart.Name = "SoundEmit"
		sound.Parent = newSoundPart
		newSoundPart.Parent = clientEffects
		if not looped then
			Debris:AddItem(newSoundPart, sound.TimeLength / sound.PlaybackSpeed + 3)
		end
	else
		sound.Parent = parent
	end
	sound:Play()
	if not looped then
		Debris:AddItem(sound, sound.TimeLength / sound.PlaybackSpeed + 3)
	end
	return sound
end

export type magicEventSentDataType = {
	action: "StartSpell" | "FireSpell",
	spellName: string,
	spellData: { [string]: any },
	sentTime: number,
}

type waveEffectDataType =
	typeof(wave)
	| typeof(_coilShockwave)
	| typeof(_ballShockwave)
	| typeof(textureShockwave)
	| typeof(hqBallShockwave)
	| typeof(_smokeShockwave)

type shockwaveDataType = {
	FirstSize: Vector3,
	NewSize: Vector3,
	Time: number,
	FirstFrame: CFrame,
	PartToUse: waveEffectDataType?,
	EasingStyle: Enum.EasingStyle?,
	EasingDirection: Enum.EasingDirection?,
	Color: Color3?,
	Material: Enum.Material?,
	Transparency: number?,
	SpinFrame: { [number]: number } | nil,
	NewFrame: CFrame?,
	NewPosition: Vector3?,
	ExtraDespawnTime: number?,
}

WorldEffects.shockwave = function(data: shockwaveDataType): BasePart
	local new_wave = if data.PartToUse then data.PartToUse:Clone() else wave:Clone()
	local easingStyle = if data.EasingStyle then data.EasingStyle else Enum.EasingStyle.Linear
	local easingDirection = if data.EasingDirection then data.EasingDirection else Enum.EasingDirection.InOut
	local transp: number = 1
	local tweenInfo = TweenInfo.new(data.Time, easingStyle, easingDirection, 0, false, 0)
	local special_mesh: SpecialMesh? = new_wave:FindFirstChildOfClass("SpecialMesh")
	if data.Color then
		new_wave.Color = data.Color
		if special_mesh then
			special_mesh.VertexColor = Vector3.new(data.Color.R, data.Color.G, data.Color.B)
		else
			new_wave.Color = data.Color
		end
	end
	if data.Material then
		new_wave.Material = data.Material
	end
	if data.Transparency then
		transp = data.Transparency
	end
	new_wave.Size = data.FirstSize
	if special_mesh then
		local original_scale = special_mesh.Scale
		special_mesh.Scale = Vector3.new(
			original_scale.X * data.FirstSize.X,
			original_scale.Y * data.FirstSize.Y,
			original_scale.Z * data.FirstSize.Z
		)
		TweenService:Create(special_mesh, tweenInfo, {
			["Scale"] = Vector3.new(
				original_scale.X * data.NewSize.X,
				original_scale.Y * data.NewSize.Y,
				original_scale.Z * data.NewSize.Z
			),
		}):Play()
	end
	new_wave.CFrame = data.FirstFrame
	new_wave.Parent = clientEffects
	if data.SpinFrame then
		local spinCoefficient = 1 / 60 / Framerate.HeartbeatDeltaTime
		local sp = CFrame.Angles(
			math.rad(data.SpinFrame[1] * spinCoefficient),
			math.rad(data.SpinFrame[2] * spinCoefficient),
			math.rad(data.SpinFrame[3] * spinCoefficient)
		)
		local beat_conn = heartbeat:Connect(function()
			new_wave.CFrame = new_wave.CFrame * sp
		end)
		new_wave.Destroying:Connect(function()
			beat_conn:Disconnect()
		end)
	end
	local tweenData = { Size = data.NewSize }
	if new_wave.Transparency ~= transp then
		tweenData.Transparency = transp
	end
	if data.NewFrame then
		tweenData.CFrame = data.NewSize
	elseif data.NewPosition then
		tweenData.Position = data.NewPosition
	end
	TweenService:Create(new_wave, tweenInfo, tweenData):Play()
	if data.ExtraDespawnTime then
		Debris:AddItem(new_wave, data.Time + data.ExtraDespawnTime)
	else
		Debris:AddItem(new_wave, data.Time)
	end
	return new_wave
end

WorldEffects.makeWeldConstraint = function(part1: BasePart | string, part2: BasePart | string): WeldConstraint
	if type(part1) == "string" then
		part1 = clientEffects:FindFirstChild(part1)
	end
	if type(part2) == "string" then
		part2 = clientEffects:FindFirstChild(part2)
	end
	if typeof(part1) ~= "Instance" or not part1:IsA("BasePart") then
		error("Invalid First Part!")
	end
	if typeof(part2) ~= "Instance" or not part2:IsA("BasePart") then
		error("Invalid Second Part!")
	end
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = part1
	weld.Part1 = part2
	weld.Parent = part1
	return weld
end

WorldEffects.makeStepSound = function(where, what: Enum.Material | "water", kind: string)
	local multiplier1: number = 1
	local multiplier2: number = 1
	if kind == "run" then
		multiplier1 = 1.2
		multiplier2 = 1.5
	elseif kind == "landing" then
		multiplier1 = 4
		multiplier2 = 0.8
	end
	local soundName = WalkSounds[what]
	local actualSound = assets.Sounds.Movement.Footsteps[soundName]
	WorldEffects.playSound(
		"Movement/Footsteps/" .. soundName,
		where,
		actualSound.Volume * multiplier1,
		actualSound.PlaybackSpeed * multiplier2
	)
end

WorldEffects.destroyEffect = function(name: string)
	for _, v in clientEffects:GetChildren() do
		if v.Name == name then
			v:Destroy()
			-- we could break here since there
			-- should only be one named as such,
			-- but I'd prefer to get rid of any possible
			-- duplicates
		end
	end
end

WorldEffects.makeCameraShake = function(pos: Vector3, pow: number, fadeTime: number?, fadeInTime: number?)
	if typeof(pos) ~= "Vector3" then
		error("Expected Vector3 as first argument")
	end
	if type(pow) ~= "number" then
		error("Expected number as second argument!")
	end
	local dist: number = nil
	pcall(function()
		dist = (lp.Character.HumanoidRootPart.Position - pos).Magnitude
	end)
	if type(dist) ~= "number" then
		warn("Couldn't calculate distance for camera shake!")
		return
	end
	local percentageSize: number = ((pow * ((200 - (dist / 2)) / 200)) / 100) * 35
	if not fadeTime then
		fadeTime = 0.5
	end
	if not fadeInTime then
		fadeInTime = 0.1
	end
	if percentageSize <= 3 then
		return
	end -- skip weak shakes
	if percentageSize > 200 then
		percentageSize = 200
	end
	_CamShake:ShakeOnce(percentageSize, 25, 0.1, fadeTime)
end

WorldEffects.removeCharacterVelocity = function()
	if not lp.Character then
		return
	end
	for _, v: BasePart in lp.Character:GetDescendants() do
		if not v:IsA("BasePart") then
			continue
		end
		v.AssemblyLinearVelocity = Vector3.zero
		v.AssemblyAngularVelocity = Vector3.zero
	end
end

local spinTrail = effectsFolder.Trail
WorldEffects.makeSpinTrail = function(
	size: number,
	spin_speed: number,
	color: Color3,
	lifeTime: number,
	anchorPart: BasePart
)
	local newSpinTrail = spinTrail:Clone()
	local tt1 = newSpinTrail.trailtest1
	local tt2 = newSpinTrail.trailtest2
	local tt3 = newSpinTrail.trailtest3
	local main = newSpinTrail.main
	main.anchor.Part0 = main
	main.anchor.Part1 = anchorPart
	tt1.Trail.Color = ColorSequence.new(color)
	tt2.Trail.Color = ColorSequence.new(color)
	tt3.Trail.Color = ColorSequence.new(color)
	tt1.Trail.Lifetime = lifeTime
	tt2.Trail.Lifetime = lifeTime
	tt3.Trail.Lifetime = lifeTime
	main.CFrame = anchorPart.CFrame
	newSpinTrail.Parent = anchorPart
	local idx: number = 0
	task.spawn(function()
		while newSpinTrail.Parent and main.Parent and anchorPart.Parent do
			tt1.Position = main.Position + (main.CFrame * CFrame.Angles(0, 0, math.rad(-30 + idx))).RightVector * size
			tt2.Position = main.Position + (main.CFrame * CFrame.Angles(0, 0, math.rad(90 + idx))).RightVector * size
			tt3.Position = main.Position + (main.CFrame * CFrame.Angles(0, 0, math.rad(210 + idx))).RightVector * size
			idx += spin_speed * (1 / 60 / Framerate.HeartbeatDeltaTime)
			heartbeat:Wait()
		end
	end)
	return spinTrail
end

local jumpWaveTweenInfo = TweenInfo.new(0.5)
WorldEffects.tJumpShockwave = function(frm: CFrame)
	local size: number = 40
	local shockwave_data3: shockwaveDataType = {
		["Time"] = 0.3,
		["Transparency"] = 0.05,
		["FirstSize"] = Vector3.new(size, size / 8, size) / 50,
		["NewSize"] = Vector3.new(size, size / 8, size),
		["FirstFrame"] = frm - frm.UpVector * 2.7 + (frm.UpVector * ((size / 8) / 50) / 2),
		["NewPosition"] = (frm - frm.UpVector * 2.7 + frm.UpVector * (size / 8) / 2).Position,
		["Color"] = Color3.new(1, 1, 1),
		["EasingStyle"] = Enum.EasingStyle.Quad,
		["EasingDirection"] = Enum.EasingDirection.Out,
		["PartToUse"] = textureShockwave,
		["ExtraDespawnTime"] = 2,
	}
	local sw1 = WorldEffects.shockwave(shockwave_data3)
	TweenService:Create(sw1, jumpWaveTweenInfo, { ["Transparency"] = 1 }):Play()
end

WorldEffects.ultJumpShockwave = function(hrp: BasePart)
	WorldEffects.playSound("Movement/HighJump", hrp, 1, 0.4)
	local frm: CFrame = hrp.CFrame
	local size = 50
	local size2 = 100
	local shockwave_data3: shockwaveDataType = {
		["Time"] = 0.4,
		["Transparency"] = 0.1,
		["FirstSize"] = Vector3.new(size, size / 8, size) / 50,
		["NewSize"] = Vector3.new(size, size / 8, size),
		["FirstFrame"] = frm - frm.UpVector * 2.7 + (frm.UpVector * ((size / 8) / 50) / 2),
		["NewPosition"] = (frm - frm.UpVector * 2.7 + frm.UpVector * (size / 8) / 2).Position,
		["Color"] = Color3.fromRGB(100, 100, 100),
		["EasingStyle"] = Enum.EasingStyle.Quad,
		["EasingDirection"] = Enum.EasingDirection.Out,
		["PartToUse"] = textureShockwave,
		["ExtraDespawnTime"] = 2,
	}
	local shockwave_data4: shockwaveDataType = {
		["Time"] = 0.4,
		["Transparency"] = 0.1,
		["FirstSize"] = Vector3.new(size2, size2 / 8, size2) / 50,
		["NewSize"] = Vector3.new(size2, size2 / 8, size2),
		["FirstFrame"] = frm - frm.UpVector * 2.7 + (frm.UpVector * ((size2 / 8) / 50) / 2),
		["NewPosition"] = (frm - frm.UpVector * 2.7 + frm.UpVector * (size2 / 8) / 2).Position,
		["Color"] = Color3.fromRGB(100, 100, 100),
		["EasingStyle"] = Enum.EasingStyle.Quad,
		["EasingDirection"] = Enum.EasingDirection.Out,
		["PartToUse"] = textureShockwave,
		["ExtraDespawnTime"] = 2,
	}
	local sw1 = WorldEffects.shockwave(shockwave_data3)
	local sw2 = WorldEffects.shockwave(shockwave_data4)
	task.spawn(function()
		task.wait(0.5)
		TweenService:Create(sw1, TweenInfo.new(0.5), { ["Transparency"] = 1 }):Play()
		TweenService:Create(sw2, TweenInfo.new(0.5), { ["Transparency"] = 1 }):Play()
	end)
end

WorldEffects.poseidonJumpShockwave = function(hrp: BasePart)
	WorldEffects.playSound("Magic/Poseidon/Pulse", hrp)
	local frm: CFrame = hrp.CFrame
	local size = 50
	local shockwave_data3: shockwaveDataType = {
		["Time"] = 0.4,
		["Transparency"] = 0.1,
		["FirstSize"] = Vector3.new(size, size / 8, size) / 50,
		["NewSize"] = Vector3.new(size, size / 8, size),
		["FirstFrame"] = frm - frm.UpVector * 2.7 + (frm.UpVector * ((size / 8) / 50) / 2),
		["NewPosition"] = (frm - frm.UpVector * 2.7 + frm.UpVector * (size / 8) / 2).Position,
		["Color"] = Color3.fromRGB(80, 80, 255),
		["EasingStyle"] = Enum.EasingStyle.Quad,
		["EasingDirection"] = Enum.EasingDirection.Out,
		["PartToUse"] = textureShockwave,
		["ExtraDespawnTime"] = 2,
	}
	local sw1 = WorldEffects.shockwave(shockwave_data3)
	task.spawn(function()
		task.wait(0.5)
		TweenService:Create(sw1, TweenInfo.new(0.5), { ["Transparency"] = 1 }):Play()
	end)
end

local function spawnPreFireArrowEffect(arrow)
	local particle = hqBallShockwave:Clone()
	particle.Size = Vector3.new(0.2, 0.2, 1)
	particle.Color = arrow.Color
	particle.CFrame = arrow.CFrame
	particle.Material = Enum.Material.Neon
	particle.Orientation = Vector3.new(math.random(-360, 360), math.random(-360, 360), math.random(-360, 360))
	TweenService:Create(particle, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		Transparency = 1,
		CFrame = particle.CFrame + particle.CFrame.LookVector * 3,
	}):Play()
	particle.Parent = clientEffects
	Debris:AddItem(particle, 1)
end

local preFireArrow = assets.Effects.PreFireArrow
WorldEffects.makePreFireArrow = function(char: HelperTypes.characterDataType, name: string)
	local newPreFireArrow = preFireArrow:Clone()
	local rightHand = char.RightHand
	newPreFireArrow.CFrame = rightHand.CFrame - rightHand.CFrame.UpVector * 2
	WorldEffects.makeWeldConstraint(newPreFireArrow, rightHand)
	newPreFireArrow.Name = name
	newPreFireArrow.Parent = clientEffects
	TweenService:Create(
		newPreFireArrow,
		TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
		{ Size = Vector3.new(1, 1, 1) }
	):Play()
	task.spawn(function()
		while newPreFireArrow.Parent == clientEffects do
			spawnPreFireArrowEffect(newPreFireArrow)
			task.wait(0.05)
		end
	end)
	return newPreFireArrow
end

local function spawnPreFireExplosionEffect(position: Vector3)
	local particle = hqBallShockwave:Clone()
	particle.Size = Vector3.new(1.5, 1.5, 1.5)
	particle.Color = Color3.fromRGB(255, 85, 0)
	particle.Position = position
	particle.Material = Enum.Material.Neon
	particle.Orientation = Vector3.new(math.random(-360, 360), math.random(-360, 360), math.random(-360, 360))
	TweenService:Create(particle, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		Transparency = 1,
		CFrame = particle.CFrame + particle.CFrame.LookVector * 5,
	}):Play()
	particle.Parent = clientEffects
	Debris:AddItem(particle, 1)
end

WorldEffects.makePreFireExplosion = function(char: HelperTypes.characterDataType, name: string)
	local inst = Instance.new("BoolValue")
	inst.Name = name
	inst.Parent = clientEffects
	task.spawn(function()
		while inst.Parent == clientEffects do
			spawnPreFireExplosionEffect(char.HumanoidRootPart.Position)
			task.wait(0.1)
		end
	end)
	return inst
end

WorldEffects.makeFireArrowExplosion = function(position: Vector3, size: Vector3)
	local sphere = hqBallShockwave:Clone()
	sphere.Color = preFireArrow.Color
	sphere.Material = Enum.Material.Neon
	sphere.Position = position
	sphere.Size = size
	sphere.Parent = clientEffects
	TweenService:Create(sphere, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Size = size * 2,
		Transparency = 1,
	}):Play()
	Debris:AddItem(sphere, 1)
end

local preFireBall = assets.Effects.PreFireBall

WorldEffects.makePreFireBall = function(char: HelperTypes.characterDataType, size: number, name: string)
	local newPreFireBall = preFireBall:Clone()
	local rightHand = char.RightHand
	newPreFireBall.CFrame = rightHand.CFrame - rightHand.CFrame.UpVector * 2
	WorldEffects.makeWeldConstraint(newPreFireBall, rightHand)
	newPreFireBall.Name = name
	newPreFireBall.Parent = clientEffects
	task.spawn(function()
		local start = tick()
		local diff: number = 0
		while newPreFireBall.Parent do
			diff = tick() - start
			if diff >= 0.5 then
				return
			end
			newPreFireBall.Flames.Size = NumberSequence.new(0, size)
			renderStepped:Wait()
		end
	end)
	return newPreFireBall
end
type preFireBalType = typeof(preFireBall)
WorldEffects.unmakePreFireBall = function(thisPreFireBall: string | preFireBalType)
	if type(thisPreFireBall) == "string" then
		thisPreFireBall = clientEffects:FindFirstChild(thisPreFireBall)
		if not thisPreFireBall then
			warn("prefireball not found!")
			return
		end
	end
	thisPreFireBall.Flames.Enabled = false
	Debris:AddItem(thisPreFireBall, 0.5)
end

local function getFloorMaterial(character): Enum.Material
	local controllerManager = character:FindFirstChild("ControllerManager")
	if not controllerManager then
		return Enum.Material.Air
	end
	local groundSensor = controllerManager.GroundSensor :: ControllerPartSensor
	if groundSensor and groundSensor.SensedPart then
		return groundSensor.SensedPart.Material
	else
		return Enum.Material.Air
	end
end

local function queueLandingParticles(character: HelperTypes.characterDataType, fromDash: boolean)
	local root = character.HumanoidRootPart
	task.delay(0.3, function()
		if getFloorMaterial(character) ~= Enum.Material.Air then
			return
		end
		local startTime: number = tick()
		while true do
			renderStepped:Wait()
			if tick() - startTime > 10 then
				return
			end
			if getFloorMaterial(character) == Enum.Material.Air then
				continue
			end
			Particles.makeParticle({
				Type = "Shockwave",
				Image = "Smoke",
				Position = root.CFrame - root.CFrame.UpVector * 3,
				Range = 7,
				ParticleSize = 1.3,
				Color = Color3.new(0.2, 0.2, 0.2),
				Transparency = NumberSequence.new(0.5, 1),
				ParticleAmount = 5,
			})
			if fromDash then
				for _ = 1, 3 do
					task.wait(0.05)
					Particles.makeParticle({
						Type = "Shockwave",
						Image = "Smoke",
						Position = root.CFrame - root.CFrame.UpVector * 3,
						Range = 10,
						ParticleSize = 2,
						Color = Color3.new(0.2, 0.2, 0.2),
						Transparency = NumberSequence.new(0.5, 1),
						ParticleAmount = 7,
					})
				end
			end
			break
		end
	end)
end

local dashTrail = assets.Effects.DashTrail
local dashTrailHand = assets.Effects.DashTrailHand
WorldEffects.dashTrailEffect = function(character: HelperTypes.characterDataType)
	WorldEffects.playSound("Movement/Dash", character.HumanoidRootPart)
	local newTrail = dashTrail:Clone()
	newTrail.Attachment0 = character.HumanoidRootPart.RootRigAttachment
	newTrail.Attachment1 = character.Head.NeckRigAttachment

	local newTrailHandLeft = dashTrailHand:Clone()
	newTrailHandLeft.Attachment0 = character.LeftHand.LeftGripAttachment
	newTrailHandLeft.Attachment1 = character.LeftHand.LeftWristRigAttachment

	local newTrailHandRight = dashTrailHand:Clone()
	newTrailHandRight.Attachment0 = character.RightHand.RightGripAttachment
	newTrailHandRight.Attachment1 = character.RightHand.RightWristRigAttachment

	newTrail.Parent = character.HumanoidRootPart
	newTrailHandLeft.Parent = character.LeftHand
	newTrailHandRight.Parent = character.RightHand

	task.delay(0.3, function()
		newTrail.Enabled = false
		newTrailHandLeft.Enabled = false
		newTrailHandRight.Enabled = false
		Debris:AddItem(newTrail, 1)
		Debris:AddItem(newTrailHandLeft, 1)
		Debris:AddItem(newTrailHandRight, 1)
	end)

	Particles.makeParticle({
		Type = "Shockwave",
		Image = "Smoke",
		Position = character.HumanoidRootPart.CFrame - character.HumanoidRootPart.CFrame.UpVector * 3,
		Range = 7,
		ParticleSize = 1.5,
		Color = Color3.new(0.2, 0.2, 0.2),
		Transparency = NumberSequence.new(0, 1),
		ParticleAmount = 7,
	})
	queueLandingParticles(character, true)
end

WorldEffects.highJumpTrailEffect = function(character: HelperTypes.characterDataType)
	WorldEffects.playSound("Movement/HighJump", character.HumanoidRootPart)
	WorldEffects.tJumpShockwave(character.HumanoidRootPart.CFrame)
	local newTrail = dashTrail:Clone()
	newTrail.Attachment0 = character.HumanoidRootPart.RootRigAttachment
	newTrail.Attachment1 = character.Head.NeckRigAttachment

	local newTrailHandLeft = dashTrailHand:Clone()
	newTrailHandLeft.Attachment0 = character.LeftHand.LeftGripAttachment
	newTrailHandLeft.Attachment1 = character.LeftHand.LeftWristRigAttachment

	local newTrailHandRight = dashTrailHand:Clone()
	newTrailHandRight.Attachment0 = character.RightHand.RightGripAttachment
	newTrailHandRight.Attachment1 = character.RightHand.RightWristRigAttachment

	newTrail.Parent = character.HumanoidRootPart
	newTrailHandLeft.Parent = character.LeftHand
	newTrailHandRight.Parent = character.RightHand

	task.delay(0.3, function()
		newTrail.Enabled = false
		newTrailHandLeft.Enabled = false
		newTrailHandRight.Enabled = false
		Debris:AddItem(newTrail, 1)
		Debris:AddItem(newTrailHandLeft, 1)
		Debris:AddItem(newTrailHandRight, 1)
	end)

	Particles.makeParticle({
		Type = "Shockwave",
		Image = "Smoke",
		Position = character.HumanoidRootPart.CFrame - character.HumanoidRootPart.CFrame.UpVector * 3,
		Range = 20,
		ParticleSize = 2,
		Color = Color3.new(0.2, 0.2, 0.2),
		Transparency = NumberSequence.new(0, 1),
		ParticleAmount = 20,
	})
	queueLandingParticles(character, false)
end

export type lightningBoltDataType = {
	startPosition: Vector3,
	endPosition: Vector3,
	thickness: number,
	boltLength: number,
	color: Color3,
	timeUntilDespawn: number,
	tendUpwards: boolean?,
	weldTo: BasePart?,
}

-- TODO: optimize this
local lbPart = assets.Effects.LBpart
WorldEffects.makeLightningBolt = function(data: lightningBoltDataType)
	local lb = lbPart:Clone()
	local stop = false
	local LastPosition = data.startPosition
	local LightningLength = data.boltLength
	local distance = (data.startPosition - data.endPosition).Magnitude
	local offthing = 30
	for i = 1, distance do
		if stop then
			break
		end
		local from = LastPosition
		local offset
		if data.tendUpwards then
			offset = Vector3.new(
				math.random(-offthing, offthing),
				math.random(-offthing / 2, offthing),
				math.random(-offthing, offthing)
			)
		else
			offset = Vector3.new(
				math.random(-offthing, offthing),
				math.random(-offthing, offthing),
				math.random(-offthing, offthing)
			)
		end
		local to = from + ((from - data.endPosition) * -1).Unit * LightningLength + offset / 1
		if i == distance or ((i + 5) > distance) or (from - data.endPosition).Magnitude <= LightningLength then
			to = data.endPosition
			stop = true
		end
		local p = lb:Clone()
		p.Name = "LightningBolt"
		p.Size = Vector3.new((from - to).Magnitude, data.thickness, data.thickness)
		p.CFrame = CFrame.new(from:Lerp(to, 0.5), to) * CFrame.Angles(0, math.rad(90), 0)
		if data.weldTo then
			local testweld = Instance.new("WeldConstraint")
			testweld.Part0 = data.weldTo
			p.Anchored = false
			testweld.Part1 = p
			testweld.Parent = p
		end
		p.Parent = clientEffects
		LastPosition = to
		Debris:AddItem(p, data.timeUntilDespawn)
	end
end

local damageTweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local damageMessageTemplate = assets.Gui.Damage
WorldEffects.damageMessage = function(position: Vector3, text: string, color: Color3)
	local newDamageMessage = damageMessageTemplate:Clone()
	local damageGui = newDamageMessage.Damage
	local damageLabel = damageGui.DamageLabel
	local stroke = damageLabel.UIStroke
	damageLabel.TextColor3 = color
	damageLabel.Text = text
	stroke.Color = color:Lerp(Color3.new(0, 0, 0), 0.7)
	TweenService:Create(damageLabel, damageTweenInfo, { TextTransparency = 0 }):Play()
	TweenService:Create(stroke, damageTweenInfo, { Transparency = 0 }):Play()
	TweenService:Create(damageGui, damageTweenInfo, { Size = UDim2.new(6, 0, 2, 0) }):Play()
	newDamageMessage.Position = position
	newDamageMessage.Parent = workspace.ClientEffects
	Debris:AddItem(newDamageMessage, 2)
end

export type WeldToRelativeInfoDataType = {
	UpVector: number,
	LookVector: number,
	RightVector: number,
	CFrameMult: CFrame,
}
export type circleInfoDataType = {
	CircleName: string,
	Frame: CFrame?,
	Size: number,
	CastTime: number,
	WorkspaceName: string,
	Silent: boolean?,
	SoundPitch: number?,
	WeldTo: BasePart?,
	WeldToRelativeInfo: WeldToRelativeInfoDataType?,
	SpinSpeed: number?,
}

return WorldEffects
