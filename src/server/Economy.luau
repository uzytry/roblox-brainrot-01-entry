-- Economy: money in, money out.
-- Every second each player earns their brainrots' combined money-per-second
-- with every multiplier applied. Buying a brainrot off the conveyor, the
-- three upgrades and the rebirth all run through here, and the leaderboard
-- board in the plaza is kept fresh from the same numbers.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("BrainrotShared")
local BrainrotData = require(Shared:WaitForChild("BrainrotData"))
local Config = require(Shared:WaitForChild("Config"))

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local BaseManager = require(script.Parent:WaitForChild("BaseManager"))
local BrainrotSpawner = require(script.Parent:WaitForChild("BrainrotSpawner"))
local StealSystem = require(script.Parent:WaitForChild("StealSystem"))
local EventManager = require(script.Parent:WaitForChild("EventManager"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))

local Economy = {}

local started = false

-- Returns the event multiplier on income right now (2 during Golden Hour).
function Economy.getEventMultiplier()
	if EventManager.isGoldenHourActive() then
		return Config.GOLDEN_HOUR_MULTIPLIER
	end
	return 1
end

-- Sends one player their fresh HUD state.
function Economy.sendStateUpdate(player)
	local state = PlayerData.getState(player)
	if state == nil then
		return
	end
	local income = PlayerData.getIncomePerSecond(player, Economy.getEventMultiplier())
	local data = PlayerData.serializeState(player, income, Economy.getEventMultiplier())
	if data ~= nil then
		Remotes.StateUpdate:FireClient(player, data)
	end
end

-- Buys a brainrot off the conveyor and places it on the buyer's base.
-- Called from the conveyor prompt; returns true when the buy went through.
function Economy.buyBrainrotFromConveyor(player, entry)
	local character = BrainrotData.getCharacter(entry.characterId)
	if character == nil then
		return false
	end
	local state = PlayerData.getState(player)
	if state == nil then
		return false
	end
	if PlayerData.getPlotName(player) == nil then
		Remotes.toastPlayer(player, "You have no base yet!")
		return false
	end
	local pedestalIndex = BaseManager.getFreePedestalIndex(player)
	if pedestalIndex == nil then
		Remotes.toastPlayer(player, "Your base is full! Buy more pedestals (U).")
		return false
	end
	if PlayerData.getCash(player) < character.cost then
		Remotes.toastPlayer(player, "Not enough cash! " .. character.name .. " costs $" .. character.cost .. ".")
		return false
	end
	-- First buy wins the race: take returns nil when another player got it.
	local taken = BrainrotSpawner.takeConveyorBrainrot(entry.model)
	if taken == nil then
		Remotes.toastPlayer(player, "Too slow - someone else bought it!")
		return false
	end
	PlayerData.spendCash(player, character.cost)
	BaseManager.placeBrainrotOnPedestal(player, entry.model, pedestalIndex)
	local ownedEntry = {
		characterId = entry.characterId,
		mutation = entry.mutation,
		pedestalIndex = pedestalIndex,
		model = entry.model,
		phase = entry.phase or 0,
		promptConnection = nil,
	}
	PlayerData.addBrainrot(player, ownedEntry)
	StealSystem.armPlacedBrainrot(player, ownedEntry)
	local displayName = BrainrotData.getDisplayName(character, entry.mutation)
	Remotes.toastPlayer(player, "Bought " .. displayName .. " for $" .. character.cost .. "! It earns $" .. BrainrotData.getIncomePerSecond(character, entry.mutation) .. "/s.")
	local plotName = PlayerData.getPlotName(player)
	if plotName ~= nil then
		Remotes.playEffect("BuyBurst", BaseManager.getPedestalPosition(plotName, pedestalIndex))
	end
	Economy.sendStateUpdate(player)
	return true
end

-- Buys one upgrade: pedestal (2 more slots), income (+25% each) or lock (+15s).
function Economy.tryBuyUpgrade(player, upgradeId)
	local state = PlayerData.getState(player)
	if state == nil then
		return
	end
	if upgradeId == "pedestal" then
		if state.pedestalsOwned >= Config.MAX_PEDESTALS then
			Remotes.toastPlayer(player, "Your base already has every pedestal.")
			return
		end
		local cost = Config.getPedestalUpgradeCost(state.pedestalsOwned)
		if PlayerData.spendCash(player, cost) == false then
			Remotes.toastPlayer(player, "Not enough cash! 2 pedestals cost $" .. cost .. ".")
			return
		end
		state.pedestalsOwned = math.min(Config.MAX_PEDESTALS, state.pedestalsOwned + Config.UPGRADE_PEDESTAL_SLOTS)
		BaseManager.hideLockedPedestals(player)
		Remotes.toastPlayer(player, "Base expanded! You now have " .. state.pedestalsOwned .. " pedestals.")
	elseif upgradeId == "income" then
		if state.incomeLevel >= Config.UPGRADE_INCOME_MAX_LEVEL then
			Remotes.toastPlayer(player, "Income is already maxed out.")
			return
		end
		local cost = Config.getIncomeUpgradeCost(state.incomeLevel)
		if PlayerData.spendCash(player, cost) == false then
			Remotes.toastPlayer(player, "Not enough cash! The income boost costs $" .. cost .. ".")
			return
		end
		state.incomeLevel += 1
		Remotes.toastPlayer(player, "Income boosted! Your brainrots now earn +" .. math.floor(state.incomeLevel * Config.UPGRADE_INCOME_PER_LEVEL * 100) .. "%.")
	elseif upgradeId == "lock" then
		if state.lockLevel >= 5 then
			Remotes.toastPlayer(player, "Your base lock is already maxed out.")
			return
		end
		local cost = Config.getLockUpgradeCost(state.lockLevel)
		if PlayerData.spendCash(player, cost) == false then
			Remotes.toastPlayer(player, "Not enough cash! The lock upgrade costs $" .. cost .. ".")
			return
		end
		state.lockLevel += 1
		Remotes.toastPlayer(player, "Lock upgraded! Your base lock now lasts " .. (Config.LOCK_DURATION + state.lockLevel * Config.LOCK_BONUS_PER_LEVEL) .. "s.")
	else
		Remotes.toastPlayer(player, "Unknown upgrade.")
		return
	end
	Economy.sendStateUpdate(player)
end

-- Rebirths a player: cash and brainrots reset, income multiplies forever.
function Economy.tryRebirth(player)
	local state = PlayerData.getState(player)
	if state == nil then
		return
	end
	local cashNeeded = Config.getRebirthCashNeeded(state.rebirths)
	local brainrotsNeeded = Config.getRebirthBrainrotsNeeded(state.rebirths)
	if state.cash < cashNeeded then
		Remotes.toastPlayer(player, "Rebirth needs $" .. cashNeeded .. ". You have $" .. math.floor(state.cash) .. ".")
		return
	end
	if #state.brainrots < brainrotsNeeded then
		Remotes.toastPlayer(player, "Rebirth needs " .. brainrotsNeeded .. " brainrots on your base.")
		return
	end
	BaseManager.clearBasePlot(player)
	PlayerData.applyRebirth(player)
	local multiplier = Config.getRebirthMultiplier(state.rebirths)
	Remotes.announceAll(player.Name .. " REBIRTHED!", "Income now x" .. multiplier .. " forever. The climb starts again!")
	local character = player.Character
	if character ~= nil then
		local root = character:FindFirstChild("HumanoidRootPart")
		if root ~= nil then
			Remotes.playEffect("RebirthBurst", root.Position)
		end
	end
	Economy.sendStateUpdate(player)
	Economy.updateLeaderboard()
end

-- Writes the top players by cash onto the plaza leaderboard board.
function Economy.updateLeaderboard()
	local board = Workspace:FindFirstChild("LeaderboardBoard")
	if board == nil then
		return
	end
	local boardGui = board:FindFirstChild("BoardGui")
	if boardGui == nil then
		return
	end
	local lines = boardGui:FindFirstChild("Lines")
	if lines == nil then
		return
	end
	local ranked = {}
	for player, state in pairs(PlayerData.getAllStates()) do
		table.insert(ranked, { name = player.Name, cash = state.cash, rebirths = state.rebirths })
	end
	table.sort(ranked, function(a, b)
		return a.cash > b.cash
	end)
	local text = "RICHEST BRAINROTTERS"
	for index = 1, math.min(Config.LEADERBOARD_SIZE, #ranked) do
		local entry = ranked[index]
		text ..= "\n" .. index .. ". " .. entry.name .. " - $" .. math.floor(entry.cash) .. "  (x" .. (entry.rebirths + 1) .. ")"
	end
	if #ranked == 0 then
		text ..= "\nNobody rich yet. Be the first!"
	end
	lines.Text = text
end

-- Starts the one-second income tick and the leaderboard refresh.
function Economy.startIncomeLoop()
	if started then
		return
	end
	started = true
	task.spawn(function()
		local tick = 0
		while true do
			task.wait(1)
			tick += 1
			local eventMultiplier = Economy.getEventMultiplier()
			for player, _ in pairs(PlayerData.getAllStates()) do
				local income = PlayerData.getIncomePerSecond(player, eventMultiplier)
				if income > 0 then
					PlayerData.addCash(player, income)
				end
				Economy.sendStateUpdate(player)
			end
			if tick % 5 == 0 then
				Economy.updateLeaderboard()
			end
		end
	end)
end

return Economy
