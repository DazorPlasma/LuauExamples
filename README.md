# Luau Examples
This repository contains examples/snippets of my Roblox luau scripts.

Code Convention:
```lua
--!strict

--// Services

-- service variables have the exact name (in upper camel case) of the service
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- game:GetService("Workspace") is never used, the global 'workspace' variable is used instead

--// Modules

-- module variables have the exact name (in upper camel case) of the module
local ExampleModule = require(ReplicatedStorage.SharedModules.ExampleModule)

--// Other Variables

-- this section contains variables expected to be used troughout the whole script
-- constants are upper snake case
local EXAMPLE_CONSTANT = 4.6692016091
-- variables are in lower camel case and rarely abbreviated; exception if frequently
-- used and well-known (localPlayer -> lp, index -> i, value -> v, identification -> id)
local lp = Players.LocalPlayer

--// Main Code

-- this section contains the rest of the script

print(ExampleModule.getPlayerHealth(lp))

-- OOP usually isn't needed. Used on few occasions. (see src/ProjectileHitbox.lua)
```
