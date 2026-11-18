-- Effects: the juice of Brainrot Rush.
-- Particle bursts for buys, steals, slaps and rebirths, floating "+$N"
-- money ticks, a field-of-view kick while carrying a stolen brainrot, and
-- a red screen flash when the tsunami wave is announced. Visuals only: no
-- gameplay decision is ever made on the client.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Effect = Remotes:WaitForChild("Effect")
local StateUpdate = Remotes:WaitForChild("StateUpdate")
local Announce = Remotes:WaitForChild("Announce")

-- One burst recipe per effect name: colors, count and spread.
local BURSTS = {
	BuyBurst = { colors = { Color3.fromRGB(120, 230, 120), Color3.fromRGB(255, 220, 0) }, count = 30, speed = 14 },
	StealSuccess = { colors = { Color3.fromRGB(255, 120, 120), Color3.fromRGB(255, 220, 0) }, count = 40, speed = 18 },
	Slap = { colors = { Color3.fromRGB(255, 220, 0), Color3.fromRGB(255, 255, 255) }, count = 24, speed = 20 },
	RebirthBurst = { colors = { Color3.fromRGB(170, 90, 255), Color3.fromRGB(255, 100, 220) }, count = 60, speed = 22 },
}

-- Spawns a one-shot particle burst at a world position.
local function playBurst(effectName, position)
	local recipe = BURSTS[effectName]
	if recipe == nil or position == nil then
		return
	end
	local anchor = Instance.new("Part")
	anchor.Name = "EffectAnchor"
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.CFrame = CFrame.new(position)
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.Transparency = 1
	anchor.Parent = Workspace
	for _, color in ipairs(recipe.colors) do
		local emitter = Instance.new("ParticleEmitter")
		emitter.Color = ColorSequence.new(color)
		emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
		emitter.Lifetime = NumberRange.new(0.5, 1)
		emitter.Rate = 0
		emitter.Speed = NumberRange.new(recipe.speed * 0.5, recipe.speed)
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.Parent = anchor
		emitter:Emit(math.floor(recipe.count / #recipe.colors))
	end
	task.delay(2, function()
		anchor:Destroy()
	end)
end

Effect.OnClientEvent:Connect(playBurst)

-- Floating "+$N" money ticks near the money panel.
local effectGui = Instance.new("ScreenGui")
effectGui.Name = "BrainrotEffects"
effectGui.ResetOnSpawn = false
effectGui.IgnoreGuiInset = true
effectGui.Parent = player:WaitForChild("PlayerGui")

local lastCash = nil
local lastCarrying = false
local DEFAULT_FOV = 70
local CARRY_FOV = 78

local function showMoneyTick(amount)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromOffset(160, 30)
	label.Position = UDim2.new(1, -300, 0, 140)
	label.BackgroundTransparency = 1
	label.Text = "+$" .. amount
	label.TextSize = 22
	label.TextColor3 = Color3.fromRGB(120, 230, 120)
	label.Font = Enum.Font.GothamBold
	label.TextStrokeTransparency = 0.4
	label.Parent = effectGui
	task.spawn(function()
		for step = 1, 20 do
			label.Position = UDim2.new(1, -300, 0, 140 - step * 2)
			label.TextTransparency = step / 20
			task.wait(0.05)
		end
		label:Destroy()
	end)
end

StateUpdate.OnClientEvent:Connect(function(state)
	if lastCash ~= nil and state.cash > lastCash then
		showMoneyTick(state.cash - lastCash)
	end
	lastCash = state.cash
	if state.carrying ~= lastCarrying then
		lastCarrying = state.carrying
		if camera ~= nil then
			if state.carrying then
				camera.FieldOfView = CARRY_FOV
			else
				camera.FieldOfView = DEFAULT_FOV
			end
		end
	end
end)

-- Red edge flash while the tsunami warning is up.
local flashFrame = Instance.new("Frame")
flashFrame.Name = "WaveFlash"
flashFrame.Size = UDim2.fromScale(1, 1)
flashFrame.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
flashFrame.BackgroundTransparency = 0.92
flashFrame.BorderSizePixel = 0
flashFrame.Visible = false
flashFrame.Parent = effectGui

Announce.OnClientEvent:Connect(function(title, _subtitle)
	if string.find(title, "TSUNAMI") ~= nil then
		flashFrame.Visible = true
		task.delay(4, function()
			flashFrame.Visible = false
		end)
	end
end)
