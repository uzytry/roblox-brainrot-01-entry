-- EventManager: the tsunami wave and Golden Hour.
-- Every few minutes a giant wave sweeps the map from north to south: players
-- caught outside a base plot are flung away, while rare brainrots rain onto
-- the conveyor. Between waves, Golden Hour doubles every income for a while.
-- startTsunamiWave is the function TOUR.json calls for reviewers.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("BrainrotShared")
local Config = require(Shared:WaitForChild("Config"))

local BaseManager = require(script.Parent:WaitForChild("BaseManager"))
local BrainrotSpawner = require(script.Parent:WaitForChild("BrainrotSpawner"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))

local EventManager = {}

local goldenHourActive = false
local waveRunning = false
local started = false

-- Returns true while Golden Hour doubles income.
function EventManager.isGoldenHourActive()
	return goldenHourActive
end

-- Runs one Golden Hour: double income for GOLDEN_HOUR_DURATION seconds.
local function startGoldenHour()
	if goldenHourActive then
		return
	end
	goldenHourActive = true
	Remotes.announceAll("GOLDEN HOUR!", "All income x" .. Config.GOLDEN_HOUR_MULTIPLIER .. " for " .. Config.GOLDEN_HOUR_DURATION .. "s!")
	task.wait(Config.GOLDEN_HOUR_DURATION)
	goldenHourActive = false
	Remotes.announceAll("Golden Hour is over.", "Your brainrots go back to normal pay.")
end

-- Flings one player up and south, away from the wave wall.
local function flingPlayer(player)
	local character = player.Character
	if character == nil then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root == nil then
		return
	end
	root.AssemblyLinearVelocity = Vector3.new(0, 55, Config.WAVE_KNOCKBACK)
	Remotes.toastPlayer(player, "The wave got you! Next time, stand on your base!")
end

-- Sweeps one tsunami wave across the map. durationSeconds overrides the
-- configured sweep length (the TOUR.json call passes 20).
function EventManager.startTsunamiWave(durationSeconds)
	if waveRunning then
		return false
	end
	waveRunning = true
	local duration = durationSeconds or Config.WAVE_DURATION
	if duration < 5 then
		duration = 5
	end
	task.spawn(function()
		BrainrotSpawner.setWaveActive(true)
		BrainrotSpawner.spawnGuaranteedMythic()
		Remotes.announceAll("TSUNAMI WAVE INCOMING!", "Get onto your base! Rare brainrots are raining!")
		task.wait(Config.WAVE_WARNING_SECONDS)

		local wall = Instance.new("Part")
		wall.Name = "TsunamiWall"
		wall.Size = Vector3.new(140, 18, 4)
		wall.Color = Color3.fromRGB(40, 140, 255)
		wall.Material = Enum.Material.Neon
		wall.Transparency = 0.45
		wall.Anchored = true
		wall.CanCollide = false
		wall.CFrame = CFrame.new(0, 9, -70)
		wall.Parent = Workspace

		local hitPlayers = {}
		local startZ = -70
		local endZ = 70
		local steps = math.floor(duration / 0.1)
		for step = 1, steps do
			local z = startZ + (endZ - startZ) * (step / steps)
			wall.CFrame = CFrame.new(0, 9, z)
			for _, player in ipairs(Players:GetPlayers()) do
				if hitPlayers[player] == nil then
					local character = player.Character
					if character ~= nil then
						local root = character:FindFirstChild("HumanoidRootPart")
						if root ~= nil and math.abs(root.Position.Z - z) < 5 then
							if BaseManager.isPositionOnAnyPlot(root.Position) == false then
								hitPlayers[player] = true
								flingPlayer(player)
							end
						end
					end
				end
			end
			task.wait(0.1)
		end

		wall:Destroy()
		BrainrotSpawner.setWaveActive(false)
		waveRunning = false
		Remotes.announceAll("The wave has passed!", "Did you catch anything rare?")
	end)
	return true
end

-- Starts the wave timer and the Golden Hour timer.
function EventManager.start()
	if started then
		return
	end
	started = true
	task.spawn(function()
		while true do
			task.wait(Config.WAVE_INTERVAL)
			EventManager.startTsunamiWave()
		end
	end)
	task.spawn(function()
		while true do
			task.wait(Config.GOLDEN_HOUR_INTERVAL)
			startGoldenHour()
		end
	end)
end

return EventManager
