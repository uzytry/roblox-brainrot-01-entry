-- BaseManager: base plots, pedestals and the base lock.
-- Eight plots ring the conveyor. Each player claims one on join, places the
-- brainrots they buy on its pedestals, and can lock it so nobody steals.
-- The static world (default.project.json) builds every plot's floor, wall,
-- pedestal pads and owner sign; this module runs them.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("BrainrotShared")
local Config = require(Shared:WaitForChild("Config"))

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local BaseManager = {}

local Plots = Workspace:WaitForChild("Plots")
local plotOwners = {}

-- Writes the owner's name on a plot's back-wall sign.
local function updatePlotSign(plotName, ownerName)
	local plot = Plots:FindFirstChild(plotName)
	if plot == nil then
		return
	end
	local wall = plot:FindFirstChild("BackWall")
	if wall == nil then
		return
	end
	local signGui = wall:FindFirstChild("SignGui")
	if signGui == nil then
		return
	end
	local label = signGui:FindFirstChild("OwnerLabel")
	if label ~= nil then
		if ownerName == nil or ownerName == "" then
			label.Text = plotName .. "\nEMPTY BASE"
		else
			label.Text = plotName .. "\n" .. ownerName .. "'s BASE"
		end
	end
end

-- Returns the folder of one plot, or nil.
function BaseManager.getPlotFolder(plotName)
	return Plots:FindFirstChild(plotName)
end

-- Returns the player who owns a plot, or nil.
function BaseManager.getPlotOwner(plotName)
	return plotOwners[plotName]
end

-- Claims the first free plot for a player and signs it. Returns its name.
function BaseManager.assignFreePlot(player)
	for _, plot in ipairs(Config.PLOTS) do
		if plotOwners[plot.name] == nil then
			plotOwners[plot.name] = player
			PlayerData.setPlot(player, plot.name)
			updatePlotSign(plot.name, player.Name)
			BaseManager.hideLockedPedestals(player)
			return plot.name
		end
	end
	return nil
end

-- Frees a player's plot when they leave and wipes its sign.
function BaseManager.releasePlot(player)
	local plotName = PlayerData.getPlotName(player)
	if plotName ~= nil then
		plotOwners[plotName] = nil
		updatePlotSign(plotName, nil)
	end
end

-- Returns a plot's config entry by name.
local function getPlotConfig(plotName)
	for _, plot in ipairs(Config.PLOTS) do
		if plot.name == plotName then
			return plot
		end
	end
	return nil
end

-- Returns the world position a brainrot model pivots to on one pedestal.
function BaseManager.getPedestalPosition(plotName, pedestalIndex)
	local plot = getPlotConfig(plotName)
	if plot == nil then
		return Vector3.new(0, 2.5, 0)
	end
	local offset = Config.PEDESTAL_OFFSETS[pedestalIndex] or Vector3.new(0, 0, 0)
	return Vector3.new(plot.center.X + offset.X, 2.5, plot.center.Z + offset.Z)
end

-- Returns the pad part of one pedestal, or nil.
function BaseManager.getPedestalPart(plotName, pedestalIndex)
	local folder = Plots:FindFirstChild(plotName)
	if folder == nil then
		return nil
	end
	return folder:FindFirstChild("Pedestal" .. pedestalIndex)
end

-- Hides the pedestal pads a player has not bought yet.
function BaseManager.hideLockedPedestals(player)
	local plotName = PlayerData.getPlotName(player)
	local state = PlayerData.getState(player)
	if plotName == nil or state == nil then
		return
	end
	for index = 1, Config.MAX_PEDESTALS do
		local pad = BaseManager.getPedestalPart(plotName, index)
		if pad ~= nil then
			if index <= state.pedestalsOwned then
				pad.Transparency = 0
				pad.CanCollide = true
			else
				pad.Transparency = 1
				pad.CanCollide = false
			end
		end
	end
end

-- Finds the first empty pedestal a player owns, or nil when the base is full.
function BaseManager.getFreePedestalIndex(player)
	local state = PlayerData.getState(player)
	if state == nil then
		return nil
	end
	for index = 1, state.pedestalsOwned do
		if PlayerData.findBrainrotByPedestal(player, index) == nil then
			return index
		end
	end
	return nil
end

-- Anchors a brainrot model on one pedestal of a player's base.
function BaseManager.placeBrainrotOnPedestal(player, model, pedestalIndex)
	local plotName = PlayerData.getPlotName(player)
	if plotName == nil then
		return false
	end
	local position = BaseManager.getPedestalPosition(plotName, pedestalIndex)
	model:PivotTo(CFrame.new(position))
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end
	return true
end

-- Returns true while a player's base lock is still running.
function BaseManager.isBaseLocked(player)
	local state = PlayerData.getState(player)
	if state == nil then
		return false
	end
	return os.clock() < state.lockedUntil
end

-- Returns the seconds left on a player's base lock.
function BaseManager.getLockRemaining(player)
	local state = PlayerData.getState(player)
	if state == nil then
		return 0
	end
	return math.max(0, state.lockedUntil - os.clock())
end

-- Locks a player's base when the cooldown has passed. Returns ok, message.
function BaseManager.tryLockBase(player)
	local state = PlayerData.getState(player)
	if state == nil then
		return false, "No player state."
	end
	if PlayerData.getPlotName(player) == nil then
		return false, "You have no base yet."
	end
	local now = os.clock()
	if now < state.lockedUntil then
		return false, "Your base is already locked."
	end
	if now - state.lastLockAt < Config.LOCK_COOLDOWN then
		local wait = math.ceil(Config.LOCK_COOLDOWN - (now - state.lastLockAt))
		return false, "Lock recharges in " .. wait .. "s."
	end
	local duration = Config.LOCK_DURATION + state.lockLevel * Config.LOCK_BONUS_PER_LEVEL
	state.lockedUntil = now + duration
	state.lastLockAt = now
	return true, "Base locked for " .. duration .. "s!"
end

-- Destroys every brainrot model on a player's base (rebirth, or leaving).
function BaseManager.clearBasePlot(player)
	local state = PlayerData.getState(player)
	if state == nil then
		return
	end
	for _, entry in ipairs(state.brainrots) do
		if entry.promptConnection ~= nil then
			entry.promptConnection:Disconnect()
		end
		if entry.model ~= nil then
			entry.model:Destroy()
		end
	end
	state.brainrots = {}
end

-- Returns true when a position stands inside one plot's floor.
function BaseManager.isPositionOnPlot(position, plotName)
	local plot = getPlotConfig(plotName)
	if plot == nil then
		return false
	end
	local dx = math.abs(position.X - plot.center.X)
	local dz = math.abs(position.Z - plot.center.Z)
	return dx <= 8 and dz <= 6
end

-- Returns true when a position stands on ANY owned plot (wave shelter).
function BaseManager.isPositionOnAnyPlot(position)
	for _, plot in ipairs(Config.PLOTS) do
		if BaseManager.isPositionOnPlot(position, plot.name) then
			return true
		end
	end
	return false
end

-- Spins and bobs every placed brainrot a little, called every Heartbeat.
function BaseManager.animatePlacedBrainrots(now)
	for player, state in pairs(PlayerData.getAllStates()) do
		for _, entry in ipairs(state.brainrots) do
			if entry.model ~= nil and entry.model.Parent ~= nil then
				local plotName = PlayerData.getPlotName(player)
				if plotName ~= nil then
					local base = BaseManager.getPedestalPosition(plotName, entry.pedestalIndex)
					local bob = math.sin(now * 2 + (entry.phase or 0)) * 0.15
					local spin = now * 0.6 + (entry.phase or 0)
					entry.model:PivotTo(CFrame.new(base.X, base.Y + bob, base.Z) * CFrame.Angles(0, spin, 0))
				end
			end
		end
	end
end

return BaseManager
