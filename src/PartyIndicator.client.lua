--!strict

--// Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

--// Modules

local HelperTypes = require(ReplicatedStorage.SharedModules.HelperTypes)
local PartyColors = require(ReplicatedStorage.SharedModules.PartyColors)
local Party = require(ReplicatedFirst.ClientModules.Party)
local PartyRankColors = require(ReplicatedStorage.SharedModules.PartyRankColors)

--// Other Variables

local partyIndicator = ReplicatedStorage.Assets.Gui.Party
local partyRemote = ReplicatedStorage.Remotes.Party
local indicators: { [string]: typeof(partyIndicator) } = {}
local indicatorConnections: { [string]: RBXScriptConnection } = {}
local lp = Players.LocalPlayer
if not game:GetAttribute("Loaded") then
	game:GetAttributeChangedSignal("Loaded"):Wait()
end

--// Main Code

local function nextPartyColor(): Color3
	local colorIndex = 1
	for _, _ in indicatorConnections do
		colorIndex += 1
	end
	return PartyColors[colorIndex]
end

local function addIndicator(stringUserId: string, rank: number, character: HelperTypes.characterDataType)
	if indicators[stringUserId] then
		indicators[stringUserId]:Destroy()
		indicators[stringUserId] = nil
	end
	local color = nextPartyColor()
	local head = character:WaitForChild("Head", 2)
	if not head then
		error("Couldn't find head!")
	end
	local newPartyIndicator = partyIndicator:Clone()
	newPartyIndicator.Head.BackgroundColor3 = color
	newPartyIndicator.Head.Visible = true
	newPartyIndicator.Head.UIStroke.Color = PartyRankColors[rank]
	newPartyIndicator.Parent = head
	newPartyIndicator.Adornee = head

	indicators[stringUserId] = newPartyIndicator
end

local function markPlayer(plr: Player)
	if typeof(plr) ~= "Instance" or not plr:IsA("Player") then
		error("Expected Player as first argument!")
	end
	local stringUserId: string = tostring(plr.UserId)
	if indicatorConnections[stringUserId] then
		warn("Already marked!")
		return
	end
	local partyRank = plr:WaitForChild("PartyRank", 2) :: IntValue
	if not partyRank then
		error("Couldn't find partyRank!")
	end
	local rank = partyRank.Value
	if plr.Character then
		addIndicator(stringUserId, rank, plr.Character)
	end
	indicatorConnections[stringUserId] = plr.CharacterAppearanceLoaded:Connect(function(char)
		addIndicator(stringUserId, rank, char)
	end)
end

local function unmarkAll()
	for i, v in indicators do
		if v then
			v:Destroy()
		end
		indicators[i] = nil
	end
	for i, v in indicatorConnections do
		if v then
			v:Disconnect()
			indicatorConnections[i] = nil
		end
	end
end

local function clearParty()
	Party.currentPartyMembers = {}
	unmarkAll()
end

local function updateCurrentParty()
	clearParty()
	if lp.PartyId.Value == "" then
		return
	end
	for _, v in Players:GetPlayers() do
		if v == lp or not v:FindFirstChild("DataLoaded") then
			continue
		end
		if v.PartyId.Value ~= lp.PartyId.Value then
			continue
		end
		table.insert(Party.currentPartyMembers, v)
	end
	for _, v in pairs(Party.currentPartyMembers) do
		markPlayer(v)
	end
end

lp:WaitForChild("PartyId"):GetPropertyChangedSignal("Value"):Connect(updateCurrentParty)
lp:WaitForChild("PartyRank"):GetPropertyChangedSignal("Value"):Connect(updateCurrentParty)
partyRemote.OnClientEvent:Connect(updateCurrentParty)

updateCurrentParty()
