-- BrainrotSpawner: the conveyor belt.
-- Brainrots roll off the belt on a timer, walk from one end to the other,
-- and despawn at the end. Rarity rolls come from BrainrotData; during a
-- tsunami wave the rare end of the ladder gets much likelier, and the wave
-- guarantees a Mythic or better. The buy callback is wired by the bootstrap
-- (init.server.luau) so this module never requires Economy back.

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("BrainrotShared")
local BrainrotData = require(Shared:WaitForChild("BrainrotData"))
local Config = require(Shared:WaitForChild("Config"))

local BrainrotFactory = require(script.Parent:WaitForChild("BrainrotFactory"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))

local BrainrotSpawner = {}

-- Called when a player presses E on a conveyor brainrot:
-- onPrompt(player, entry) -> true when the buy went through.
BrainrotSpawner.onPrompt = nil

local active = {}
local random = Random.new()
local waveActive = false
local started = false

-- Picks one character of a rarity at random.
local function pickCharacterOfRarity(rarityName)
	local candidates = BrainrotData.getCharactersByRarity(rarityName)
	if #candidates == 0 then
		return BrainrotData.CHARACTERS[1]
	end
	return candidates[random:NextInteger(1, #candidates)]
end

-- Spawns one brainrot at the conveyor's start and arms its buy prompt.
local function spawnEntry(character, mutation)
	local model = BrainrotFactory.buildBrainrotModel(character, mutation)
	local nameLine, rateLine = BrainrotData.getLabelLines(character, mutation)
	BrainrotFactory.attachLabel(model, nameLine, rateLine, BrainrotData.getRarityColor(character.rarity))
	local prompt = BrainrotFactory.attachPrompt(model, "Buy $" .. character.cost, character.name)
	model:PivotTo(CFrame.new(Config.CONVEYOR_START_X, Config.CONVEYOR_Y, Config.CONVEYOR_Z))
	model.Parent = Workspace

	local entry = {
		model = model,
		characterId = character.id,
		mutation = mutation,
		x = Config.CONVEYOR_START_X,
		phase = random:NextNumber(0, math.pi * 2),
		promptConnection = nil,
	}
	entry.promptConnection = prompt.Triggered:Connect(function(player)
		if BrainrotSpawner.onPrompt ~= nil then
			BrainrotSpawner.onPrompt(player, entry)
		end
	end)
	table.insert(active, entry)

	local rarityIndex = BrainrotData.getRarityIndex(character.rarity)
	if rarityIndex >= 4 then
		local displayName = BrainrotData.getDisplayName(character, mutation)
		Remotes.announceAll("A " .. string.upper(character.rarity) .. " appeared!", displayName .. " is walking the conveyor.")
	end
	return entry
end

-- Rolls and spawns one brainrot on the conveyor.
function BrainrotSpawner.spawnBrainrotOnConveyor()
	if #active >= Config.MAX_CONVEYOR_BRAINROTS then
		return nil
	end
	local rarityName = BrainrotData.rollRarityName(random, waveActive)
	local character = pickCharacterOfRarity(rarityName)
	local mutation = BrainrotData.rollMutationName(random)
	return spawnEntry(character, mutation)
end

-- Spawns a brainrot of one chosen rarity (the TOUR.json showcase call,
-- so reviewers can bring a Legendary to the belt on demand).
function BrainrotSpawner.spawnBrainrotForShowcase(rarityName)
	local character = pickCharacterOfRarity(rarityName)
	if character == nil then
		return false
	end
	spawnEntry(character, "Normal")
	return true
end

-- Spawns one guaranteed Mythic-or-better brainrot, for the tsunami wave.
function BrainrotSpawner.spawnGuaranteedMythic()
	local pool = {}
	for _, character in ipairs(BrainrotData.CHARACTERS) do
		if BrainrotData.getRarityIndex(character.rarity) >= 5 then
			table.insert(pool, character)
		end
	end
	if #pool == 0 then
		return nil
	end
	local character = pool[random:NextInteger(1, #pool)]
	local mutation = BrainrotData.rollMutationName(random)
	return spawnEntry(character, mutation)
end

-- Takes one conveyor brainrot off the belt WITHOUT destroying its model, so
-- the buyer can place it on their base. Returns its entry, or nil when
-- another player already took it (the first buy wins the race).
function BrainrotSpawner.takeConveyorBrainrot(model)
	for index, entry in ipairs(active) do
		if entry.model == model then
			table.remove(active, index)
			if entry.promptConnection ~= nil then
				entry.promptConnection:Disconnect()
			end
			return entry
		end
	end
	return nil
end

-- Returns how many brainrots are walking the belt right now.
function BrainrotSpawner.getActiveCount()
	return #active
end

-- Turns the wave's rare-boost on or off.
function BrainrotSpawner.setWaveActive(activeFlag)
	waveActive = activeFlag
end

-- Returns whether the wave's rare-boost is on.
function BrainrotSpawner.getWaveActive()
	return waveActive
end

-- Walks every conveyor brainrot toward the end of the belt.
local function moveConveyorBrainrots(dt, now)
	for index = #active, 1, -1 do
		local entry = active[index]
		entry.x += Config.CONVEYOR_SPEED * dt
		if entry.x > Config.CONVEYOR_END_X then
			if entry.promptConnection ~= nil then
				entry.promptConnection:Disconnect()
			end
			entry.model:Destroy()
			table.remove(active, index)
		else
			local bob = math.sin(now * 3 + entry.phase) * 0.12
			local sway = math.sin(now * 1.5 + entry.phase) * 0.08
			entry.model:PivotTo(CFrame.new(entry.x, Config.CONVEYOR_Y + bob, Config.CONVEYOR_Z + sway))
		end
	end
end

-- Starts the spawn timer and the belt movement loop.
function BrainrotSpawner.start()
	if started then
		return
	end
	started = true
	RunService.Heartbeat:Connect(function(dt)
		moveConveyorBrainrots(dt, os.clock())
	end)
	task.spawn(function()
		while true do
			task.wait(Config.SPAWN_INTERVAL)
			BrainrotSpawner.spawnBrainrotOnConveyor()
		end
	end)
end

return BrainrotSpawner
