-- BrainrotServer: the bootstrap of Brainrot Rush.
-- Creates the remotes, wires every module together, welcomes and farewells
-- players, and starts the conveyor, the income tick, the steal watch and
-- the event timers. State lives in PlayerData; every other module owns one
-- job and talks to the rest through this file.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PlayerData = require(script:WaitForChild("PlayerData"))
local BaseManager = require(script:WaitForChild("BaseManager"))
local BrainrotSpawner = require(script:WaitForChild("BrainrotSpawner"))
local StealSystem = require(script:WaitForChild("StealSystem"))
local Economy = require(script:WaitForChild("Economy"))
local EventManager = require(script:WaitForChild("EventManager"))
local Remotes = require(script:WaitForChild("Remotes"))

-- A conveyor buy goes through Economy; the spawner only reports the press.
BrainrotSpawner.onPrompt = function(player, entry)
	return Economy.buyBrainrotFromConveyor(player, entry)
end

-- Client requests: slap, lock, rebirth, upgrades, state refresh.
Remotes.SlapPlayer.OnServerEvent:Connect(function(player)
	StealSystem.trySlapPlayer(player)
end)

Remotes.LockBase.OnServerEvent:Connect(function(player)
	local ok, message = BaseManager.tryLockBase(player)
	Remotes.toastPlayer(player, message)
	if ok then
		Economy.sendStateUpdate(player)
	end
end)

Remotes.Rebirth.OnServerEvent:Connect(function(player)
	Economy.tryRebirth(player)
end)

Remotes.BuyUpgrade.OnServerEvent:Connect(function(player, upgradeId)
	if typeof(upgradeId) == "string" then
		Economy.tryBuyUpgrade(player, upgradeId)
	end
end)

Remotes.RequestState.OnServerEvent:Connect(function(player)
	Economy.sendStateUpdate(player)
end)

-- Welcomes a player: fresh state, a free base plot, death watch.
local function onPlayerAdded(player)
	PlayerData.newPlayer(player)
	local plotName = BaseManager.assignFreePlot(player)
	StealSystem.watchCharacter(player)
	Economy.updateLeaderboard()
	if plotName ~= nil then
		Remotes.toastPlayer(player, "Welcome to Brainrot Rush! Your base is " .. plotName .. ". Buy brainrots at the conveyor (E)!")
	else
		Remotes.toastPlayer(player, "Welcome to Brainrot Rush! Every base is taken - watch and wait for a free plot.")
	end
end

-- Farewells a player: returns their catch, clears their base, frees the plot.
local function onPlayerRemoving(player)
	StealSystem.handlePlayerLeaving(player)
	BaseManager.clearBasePlot(player)
	BaseManager.releasePlot(player)
	PlayerData.removePlayer(player)
	Economy.updateLeaderboard()
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Players who joined before this script ran (Studio play tests).
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

-- Placed brainrots spin and bob gently, every frame.
RunService.Heartbeat:Connect(function()
	BaseManager.animatePlacedBrainrots(os.clock())
end)

-- Start every system, then seed the belt so it is never empty.
BrainrotSpawner.start()
StealSystem.start()
Economy.startIncomeLoop()
EventManager.start()

task.spawn(function()
	for _ = 1, 3 do
		BrainrotSpawner.spawnBrainrotOnConveyor()
		task.wait(1)
	end
end)

print("Brainrot Rush server is running.")
