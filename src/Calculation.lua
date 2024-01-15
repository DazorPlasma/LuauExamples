--!strict

--// Services

local RunService = game:GetService("RunServiceice")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--// Modules

local SpellInfo = require(ReplicatedStorage.SharedModules.SpellInfo)
local HelperTypes = require(ReplicatedStorage.SharedModules.HelperTypes)
local CharStatus = require(ReplicatedFirst.ClientModules.CharStatus)
local Enchantments = require(ReplicatedStorage.SharedModules.Enchantments)

--// Other Variables

--[=[
	@class Calculation
	This module provides various calculation functions.
]=]
local Calculation = {}
local clientData
type DataStoreTemplateDataType = typeof(ServerStorage.DataStoreTemplate)

--// Main Code

local lp
if RunService:IsClient() then
	lp = Players.LocalPlayer
	clientData = ReplicatedFirst.ClientData
end

local preDashPower: number = ReplicatedStorage.Config.DashPower.Value
Calculation.getDashPower = function(plr: Player?): number
	if RunService:IsClient() then
		return preDashPower + math.clamp(clientData.ItemStats.Agility.Value / 2, -30, 100)
	else
		if typeof(plr) ~= "Instance" or not plr:IsA("Player") then
			error("Expected Player as first argument!")
		end
		return preDashPower + math.clamp(ServerStorage.CurrentData[plr.Name].ItemStats.Agility.Value / 2, -30, 100)
	end
end

local highJumpPower: number = ReplicatedStorage.Config.HighJumpPower.Value
Calculation.getHighJumpVelocity = function(plr: Player?): Vector3
	local agility: number
	local rootMass: number
	if RunService:IsClient() then
		agility = math.clamp(clientData.ItemStats.Agility.Value * 1.2, -highJumpPower / 2, 250)
		rootMass = lp.Character.HumanoidRootPart.AssemblyMass
	else
		if typeof(plr) ~= "Instance" or not plr:IsA("Player") then
			error("Expected Player as first argument!")
		end
		agility = math.clamp(ServerStorage.CurrentData[plr.Name].ItemStats.Agility.Value * 1.2, -30, 250)
		rootMass = (plr.Character :: HelperTypes.characterDataType).HumanoidRootPart.AssemblyMass
	end

	return Vector3.yAxis * (rootMass + highJumpPower + agility)
end

Calculation.getSmallForwardJumpVelocity = function(plr: Player?): number
	local agility: number
	local rootMass: number
	if RunService:IsClient() then
		agility = math.clamp(clientData.ItemStats.Agility.Value * 2, -300, 300)
		rootMass = lp.Character.HumanoidRootPart.AssemblyMass
	else
		if typeof(plr) ~= "Instance" or not plr:IsA("Player") then
			error("Expected Player as first argument!")
		end
		agility = math.clamp(ServerStorage.CurrentData[plr.Name].ItemStats.Agility.Value * 2, -300, 300)
		rootMass = (plr.Character :: HelperTypes.characterDataType).HumanoidRootPart.AssemblyMass
	end

	return 500 + rootMass + agility
end

Calculation.getWalkSpeed = function(): number
	if RunService:IsServer() then
		error("This can only be called on the client!")
	end

	if CharStatus.isCastingJump then
		return 5
	end
	return math.max(16 + clientData.ItemStats.Agility.Value / 15, 10)
end

Calculation.getRunSpeed = function(): number
	if RunService:IsServer() then
		error("This can only be called on the client!")
	end
	if CharStatus.isCastingJump then
		return 5
	end
	return math.max(30 + clientData.ItemStats.Agility.Value / 10, 15)
end

local MAX_EXTRA_JP: number = 1000
Calculation.getExtraJumpPower = function(plr: Player?): number
	local agility
	if RunService:IsClient() then
		agility = clientData.ItemStats.Agility.Value * 2
	else
		if typeof(plr) ~= "Instance" or not plr:IsA("Player") then
			error("Expected Player as first argument!")
		end
		agility = ServerStorage.CurrentData[plr.Name].ItemStats.Agility.Value * 2
	end
	return math.clamp(agility, -MAX_EXTRA_JP, MAX_EXTRA_JP)
end

Calculation.getMaxMana = function(plr: Player?): number
	if RunService:IsClient() then
		return 93 + 7 * clientData.Stats.Level.Value
	end
	if typeof(plr) ~= "Instance" or not plr:IsA("Player") then
		error("Expected Player as first argument!")
	end
	return 93 + 7 * ServerStorage.CurrentData[plr.Name].Stats.Level.Value
end

Calculation.getMaxStamina = function(plr: Player?): number
	if RunService:IsClient() then
		return 93 + 7 * clientData.Stats.Level.Value
	end
	if typeof(plr) ~= "Instance" or not plr:IsA("Player") then
		error("Expected Player as first argument!")
	end
	return 93 + 7 * ServerStorage.CurrentData[plr.Name].Stats.Level.Value
end

Calculation.getDashStaminaCost = function(plr: Player?): number
	return 50 + Calculation.getMaxStamina(plr) * 0.1
end

Calculation.getHighJumpStaminaCost = function(plr: Player?): number
	return 30 + Calculation.getMaxStamina(plr) * 0.08
end

Calculation.getMaxHealth = function(owner: HelperTypes.characterDataType): number
	local vitality: number
	local plr = Players:GetPlayerFromCharacter(owner)
	if plr then
		if RunService:IsClient() then
			assert(plr == lp, "wrong player!")
			vitality = clientData.ItemStats.Vitality.Value
		else
			vitality = ServerStorage.CurrentData[plr.Name].ItemStats.Vitality.Value
		end
	else
		vitality = owner.Data.Stats.Vitality.Value
	end
	return math.max(100 + vitality, 10)
end

Calculation.getCastSpeedFactor = function(plr: Player?)
	local castSpeed: number
	if RunService:IsClient() then
		castSpeed = ReplicatedFirst.ClientData.ItemStats.CastSpeed.Value
	else
		if typeof(plr) ~= "Instance" or not plr:IsA("Player") then
			error("Expected Player as first argument!")
		end
		castSpeed = ServerStorage.CurrentData[plr.Name].ItemStats.CastSpeed.Value
	end
	--local calculatedFactor: number
	--if castSpeed > 0 then
	--	calculatedFactor = 1 - 0.08 * math.pow(castSpeed, 1 / 3)
	--else
	--	calculatedFactor = 1 + 0.08 * math.pow(-castSpeed, 1 / 3)
	--end
	--return calculatedFactor
	return 100 / (100 + math.clamp(castSpeed, -80, 900))
end

local function getMagicSizeCoefficient(magicSize: number): number
	return (100 + math.max(magicSize, -50)) / 100
end

Calculation.getHitboxSize = function(owner: HelperTypes.characterDataType, spellName: string): number
	local hitboxSize: number = SpellInfo[spellName].BaseHitbox
	local magicSize: number
	local plr = Players:GetPlayerFromCharacter(owner)
	if plr then
		if RunService:IsClient() then
			assert(plr == lp, "wrong player!")
			magicSize = clientData.ItemStats.MagicSize.Value
		else
			magicSize = ServerStorage.CurrentData[plr.Name].ItemStats.MagicSize.Value
		end
	else
		magicSize = owner.Data.Stats.MagicSize.Value
	end
	hitboxSize *= getMagicSizeCoefficient(magicSize)
	return hitboxSize
end

Calculation.calculateDamage = function(owner: HelperTypes.characterDataType?, spellName: string)
	local damage: number = SpellInfo[spellName].BaseDamage
	if owner then
		local plr = Players:GetPlayerFromCharacter(owner)
		if plr then
			local playerData: DataStoreTemplateDataType = ServerStorage.CurrentData[plr.Name]
			damage += playerData.ItemStats.MagicPower.Value * SpellInfo[spellName].MagicPowerMult
			damage += playerData.ItemStats.Strength.Value * SpellInfo[spellName].StrengthMult
		else
			local npcData = owner.Data
			damage += npcData.Stats.MagicPower.Value * SpellInfo[spellName].MagicPowerMult
			damage += npcData.Stats.Strength.Value * SpellInfo[spellName].StrengthMult
		end
	end
	return math.max(math.round(damage), 0)
end

Calculation.getManaCost = function(plr: Player?, spellName: string)
	local magicEfficiency: number
	if RunService:IsClient() then
		magicEfficiency = clientData.ItemStats.MagicEfficiency.Value
	else
		local actualPlayer = plr :: Player
		magicEfficiency = clientData.CurrentData[actualPlayer.Name].ItemStats.MagicEfficiency.Value
	end
	local spellData = SpellInfo[spellName]
	local pureCost: number = spellData.ManaCost.absolute + spellData.ManaCost.percent * Calculation.getMaxMana()
	local newCost = pureCost - magicEfficiency
	return math.max(newCost, pureCost / 4)
end

Calculation.getStaminaCost = function(plr: Player?, spellName: string)
	local physicalEfficiency: number
	if RunService:IsClient() then
		physicalEfficiency = clientData.ItemStats.PhysicalEfficiency.Value
	else
		local actualPlayer = plr :: Player
		physicalEfficiency = clientData.CurrentData[actualPlayer.Name].ItemStats.PhysicalEfficiency.Value
	end
	local spellData = SpellInfo[spellName]
	local pureCost: number = spellData.StaminaCost.absolute
		+ spellData.StaminaCost.percent * Calculation.getMaxStamina()
	local newCost = pureCost - physicalEfficiency
	return math.max(newCost, pureCost / 4)
end

local rsItems = ReplicatedStorage.Items
Calculation.getItemStats = function(item: string, enchant: string?): { [HelperTypes.statDataType]: number }
	local itemStats = {}
	for _, v: NumberValue in rsItems[item].Stats:GetChildren() do
		itemStats[v.Name :: HelperTypes.statDataType] = v.Value
	end

	if enchant then
		local targetEnchant = Enchantments[enchant]
		assert(targetEnchant ~= nil, `Enchant {targetEnchant} not found!`)
		for statName: HelperTypes.statDataType, statValues in targetEnchant.GainStats do
			if not itemStats[statName] then
				itemStats[statName] = 0
			end
			itemStats[statName] += itemStats[statName] * statValues.percentItemBoost + statValues.absolute
		end
	end

	for i, v in itemStats do
		itemStats[i] = math.round(v)
	end

	return itemStats :: any -- force conversion to function's return type
end

return Calculation
