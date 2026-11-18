-- StealSystem: stealing, carrying, slapping and the run home.
-- A thief presses E on a brainrot on someone else's base, carries it over
-- their head at reduced speed, and must reach their own base to keep it.
-- Anyone can press F near a carrier to slap the catch loose; a dropped
-- brainrot walks home to its own pedestal after a few seconds. A locked
-- base cannot be stolen from at all.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("BrainrotShared")
local BrainrotData = require(Shared:WaitForChild("BrainrotData"))
local Config = require(Shared:WaitForChild("Config"))

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local BaseManager = require(script.Parent:WaitForChild("BaseManager"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))

local StealSystem = {}

local started = false

-- Welds a brainrot model above a player's head for the carry.
local function weldModelToPlayer(model, player)
	local character = player.Character
	if character == nil then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if root == nil or humanoid == nil then
		return nil
	end
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = false
			part.Massless = true
		end
	end
	local weld = Instance.new("Weld")
	weld.Name = "CarryWeld"
	weld.Part0 = root
	weld.Part1 = model.PrimaryPart
	weld.C0 = CFrame.new(Config.CARRY_OFFSET)
	weld.Parent = root
	humanoid.WalkSpeed = Config.CARRY_WALK_SPEED
	return weld
end

-- Restores a player's walk speed after a carry ends.
local function restoreWalkSpeed(player)
	local character = player.Character
	if character == nil then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid ~= nil then
		humanoid.WalkSpeed = Config.NORMAL_WALK_SPEED
	end
end

-- Arms the steal prompt on a placed brainrot so others can grab it.
function StealSystem.armPlacedBrainrot(ownerPlayer, entry)
	local model = entry.model
	if model == nil or model.PrimaryPart == nil then
		return
	end
	local prompt = model.PrimaryPart:FindFirstChild("InteractPrompt")
	if prompt == nil then
		return
	end
	local character = BrainrotData.getCharacter(entry.characterId)
	local objectText = character ~= nil and character.name or entry.characterId
	prompt.ActionText = "Steal"
	prompt.ObjectText = objectText
	prompt.Enabled = true
	if entry.promptConnection ~= nil then
		entry.promptConnection:Disconnect()
	end
	entry.promptConnection = prompt.Triggered:Connect(function(thief)
		StealSystem.tryStealBrainrot(thief, ownerPlayer, entry)
	end)
end

-- Tries to steal one placed brainrot. Returns ok, message.
function StealSystem.tryStealBrainrot(thief, ownerPlayer, entry)
	if thief == ownerPlayer then
		Remotes.toastPlayer(thief, "That brainrot is already yours!")
		return false, "own brainrot"
	end
	local thiefState = PlayerData.getState(thief)
	local ownerState = PlayerData.getState(ownerPlayer)
	if thiefState == nil or ownerState == nil then
		return false, "missing state"
	end
	if thiefState.carrying ~= nil then
		Remotes.toastPlayer(thief, "You are already carrying a brainrot!")
		return false, "already carrying"
	end
	if BaseManager.isBaseLocked(ownerPlayer) then
		Remotes.toastPlayer(thief, ownerPlayer.Name .. "'s base is LOCKED!")
		return false, "base locked"
	end
	if BaseManager.getFreePedestalIndex(thief) == nil then
		Remotes.toastPlayer(thief, "Your base is full! Buy more pedestals first.")
		return false, "base full"
	end
	local taken = PlayerData.removeBrainrot(ownerPlayer, entry.pedestalIndex)
	if taken == nil then
		Remotes.toastPlayer(thief, "Too slow - that brainrot is gone!")
		return false, "already taken"
	end
	if entry.promptConnection ~= nil then
		entry.promptConnection:Disconnect()
		entry.promptConnection = nil
	end
	local prompt = entry.model.PrimaryPart:FindFirstChild("InteractPrompt")
	if prompt ~= nil then
		prompt.Enabled = false
	end
	local weld = weldModelToPlayer(entry.model, thief)
	if weld == nil then
		return false, "no character"
	end
	thiefState.carrying = {
		model = entry.model,
		characterId = entry.characterId,
		mutation = entry.mutation,
		phase = entry.phase or 0,
		fromPlayer = ownerPlayer,
		fromPedestalIndex = entry.pedestalIndex,
		weld = weld,
	}
	local character = BrainrotData.getCharacter(entry.characterId)
	local displayName = character ~= nil and BrainrotData.getDisplayName(character, entry.mutation) or entry.characterId
	Remotes.toastPlayer(thief, "You stole " .. displayName .. "! RUN HOME!")
	Remotes.toastPlayer(ownerPlayer, thief.Name .. " is stealing your " .. displayName .. "! Slap them (F)!")
	return true, "stolen"
end

-- Returns a carried brainrot to its original owner's base.
local function returnCarriedBrainrot(carrier)
	local state = PlayerData.getState(carrier)
	if state == nil or state.carrying == nil then
		return
	end
	local carried = state.carrying
	state.carrying = nil
	if carried.weld ~= nil then
		carried.weld:Destroy()
	end
	restoreWalkSpeed(carrier)
	local ownerPlayer = carried.fromPlayer
	local ownerState = ownerPlayer ~= nil and PlayerData.getState(ownerPlayer) or nil
	if ownerState == nil then
		carried.model:Destroy()
		return
	end
	local pedestalIndex = BaseManager.getFreePedestalIndex(ownerPlayer)
	if pedestalIndex == nil then
		carried.model:Destroy()
		Remotes.toastPlayer(ownerPlayer, "Your stolen brainrot had nowhere to go and vanished!")
		return
	end
	BaseManager.placeBrainrotOnPedestal(ownerPlayer, carried.model, pedestalIndex)
	local entry = {
		characterId = carried.characterId,
		mutation = carried.mutation,
		pedestalIndex = pedestalIndex,
		model = carried.model,
		phase = carried.phase,
		promptConnection = nil,
	}
	PlayerData.addBrainrot(ownerPlayer, entry)
	StealSystem.armPlacedBrainrot(ownerPlayer, entry)
	Remotes.toastPlayer(ownerPlayer, "Your brainrot walked home safely.")
end

-- Drops what a carrier holds; it walks home after RETURN_DELAY seconds.
function StealSystem.dropCarriedBrainrot(carrier)
	local state = PlayerData.getState(carrier)
	if state == nil or state.carrying == nil then
		return
	end
	task.delay(Config.RETURN_DELAY, function()
		returnCarriedBrainrot(carrier)
	end)
end

-- Delivers a carried brainrot onto the thief's own base.
local function deliverCarriedBrainrot(player)
	local state = PlayerData.getState(player)
	if state == nil or state.carrying == nil then
		return
	end
	local carried = state.carrying
	local pedestalIndex = BaseManager.getFreePedestalIndex(player)
	if pedestalIndex == nil then
		Remotes.toastPlayer(player, "Your base is full - the brainrot slips away!")
		StealSystem.dropCarriedBrainrot(player)
		return
	end
	state.carrying = nil
	if carried.weld ~= nil then
		carried.weld:Destroy()
	end
	restoreWalkSpeed(player)
	BaseManager.placeBrainrotOnPedestal(player, carried.model, pedestalIndex)
	local entry = {
		characterId = carried.characterId,
		mutation = carried.mutation,
		pedestalIndex = pedestalIndex,
		model = carried.model,
		phase = carried.phase,
		promptConnection = nil,
	}
	PlayerData.addBrainrot(player, entry)
	StealSystem.armPlacedBrainrot(player, entry)
	local character = BrainrotData.getCharacter(carried.characterId)
	local displayName = character ~= nil and BrainrotData.getDisplayName(character, carried.mutation) or carried.characterId
	Remotes.toastPlayer(player, "Stolen " .. displayName .. " secured on your base!")
	local characterModel = player.Character
	if characterModel ~= nil then
		local root = characterModel:FindFirstChild("HumanoidRootPart")
		if root ~= nil then
			Remotes.playEffect("StealSuccess", root.Position)
		end
	end
end

-- Slaps the nearest carrier in range and drops their catch.
function StealSystem.trySlapPlayer(player)
	local state = PlayerData.getState(player)
	if state == nil then
		return
	end
	local now = os.clock()
	if now - state.lastSlapAt < Config.SLAP_COOLDOWN then
		return
	end
	local character = player.Character
	if character == nil then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root == nil then
		return
	end
	local target = nil
	local targetDistance = Config.SLAP_RANGE
	for otherPlayer, otherState in pairs(PlayerData.getAllStates()) do
		if otherPlayer ~= player and otherState.carrying ~= nil then
			local otherCharacter = otherPlayer.Character
			if otherCharacter ~= nil then
				local otherRoot = otherCharacter:FindFirstChild("HumanoidRootPart")
				if otherRoot ~= nil then
					local distance = (otherRoot.Position - root.Position).Magnitude
					if distance < targetDistance then
						target = otherPlayer
						targetDistance = distance
					end
				end
			end
		end
	end
	if target == nil then
		Remotes.toastPlayer(player, "Nobody carrying a brainrot is in slap range.")
		return
	end
	state.lastSlapAt = now
	StealSystem.dropCarriedBrainrot(target)
	local targetCharacter = target.Character
	if targetCharacter ~= nil then
		local humanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
		if humanoid ~= nil then
			humanoid.WalkSpeed = 0
			task.delay(Config.SLAP_STUN_SECONDS, function()
				if humanoid.Parent ~= nil then
					humanoid.WalkSpeed = Config.NORMAL_WALK_SPEED
				end
			end)
		end
		local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
		if targetRoot ~= nil then
			Remotes.playEffect("Slap", targetRoot.Position)
		end
	end
	Remotes.toastPlayer(player, "SLAP! " .. target.Name .. " dropped the brainrot!")
	Remotes.toastPlayer(target, player.Name .. " slapped you! Your brainrot is loose!")
end

-- Drops a player's catch when they die, and watches for respawns.
function StealSystem.watchCharacter(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			StealSystem.dropCarriedBrainrot(player)
		end)
	end)
end

-- Returns a leaving player's carried brainrot to its owner at once.
function StealSystem.handlePlayerLeaving(player)
	local state = PlayerData.getState(player)
	if state ~= nil and state.carrying ~= nil then
		returnCarriedBrainrot(player)
	end
end

-- Watches carriers every frame: stepping onto your own base delivers.
function StealSystem.start()
	if started then
		return
	end
	started = true
	RunService.Heartbeat:Connect(function()
		for player, state in pairs(PlayerData.getAllStates()) do
			if state.carrying ~= nil then
				local plotName = PlayerData.getPlotName(player)
				local character = player.Character
				if plotName ~= nil and character ~= nil then
					local root = character:FindFirstChild("HumanoidRootPart")
					if root ~= nil and BaseManager.isPositionOnPlot(root.Position, plotName) then
						deliverCarriedBrainrot(player)
					end
				end
			end
		end
	end)
end

return StealSystem
