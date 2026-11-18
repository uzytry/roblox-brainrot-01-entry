-- Game: the client of Brainrot Rush.
-- Builds the HUD (cash, income, rebirths, collection, buttons), binds the
-- keys (F slap, L lock, U upgrades) and renders every state update the
-- server sends. Roblox's own menu buttons sit over the top-left corner, so
-- nothing important lives there.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local StateUpdate = Remotes:WaitForChild("StateUpdate")
local Announce = Remotes:WaitForChild("Announce")
local Toast = Remotes:WaitForChild("Toast")
local SlapPlayer = Remotes:WaitForChild("SlapPlayer")
local LockBase = Remotes:WaitForChild("LockBase")
local Rebirth = Remotes:WaitForChild("Rebirth")
local BuyUpgrade = Remotes:WaitForChild("BuyUpgrade")
local RequestState = Remotes:WaitForChild("RequestState")

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local function makeLabel(parent, name, position, size, text, textSize, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = position
	label.Size = size
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextSize = textSize
	label.TextColor3 = color
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextStrokeTransparency = 0.5
	label.Parent = parent
	return label
end

local function makeButton(parent, name, position, size, text, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Position = position
	button.Size = size
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Text = text
	button.TextSize = 18
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.GothamBold
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button
	button.Parent = parent
	return button
end

-- Top-right money panel: cash, income per second, rebirths.
local moneyPanel = Instance.new("Frame")
moneyPanel.Name = "MoneyPanel"
moneyPanel.AnchorPoint = Vector2.new(1, 0)
moneyPanel.Position = UDim2.new(1, -16, 0, 16)
moneyPanel.Size = UDim2.fromOffset(280, 110)
moneyPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
moneyPanel.BackgroundTransparency = 0.25
moneyPanel.BorderSizePixel = 0
moneyPanel.Parent = gui
local moneyCorner = Instance.new("UICorner")
moneyCorner.CornerRadius = UDim.new(0, 10)
moneyCorner.Parent = moneyPanel

local cashLabel = makeLabel(moneyPanel, "CashLabel", UDim2.new(0, 14, 0, 8), UDim2.new(1, -28, 0, 34), "CASH  $100", 28, Color3.fromRGB(255, 220, 0))
local incomeLabel = makeLabel(moneyPanel, "IncomeLabel", UDim2.new(0, 14, 0, 44), UDim2.new(1, -28, 0, 26), "+$0 / sec", 20, Color3.fromRGB(120, 230, 120))
local rebirthLabel = makeLabel(moneyPanel, "RebirthLabel", UDim2.new(0, 14, 0, 72), UDim2.new(1, -28, 0, 26), "REBIRTHS  0  (x1 income)", 18, Color3.fromRGB(170, 140, 255))

-- Left collection panel: every brainrot on the player's base.
local collectionPanel = Instance.new("Frame")
collectionPanel.Name = "CollectionPanel"
collectionPanel.Position = UDim2.new(0, 16, 0, 120)
collectionPanel.Size = UDim2.fromOffset(260, 300)
collectionPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
collectionPanel.BackgroundTransparency = 0.25
collectionPanel.BorderSizePixel = 0
collectionPanel.Parent = gui
local collectionCorner = Instance.new("UICorner")
collectionCorner.CornerRadius = UDim.new(0, 10)
collectionCorner.Parent = collectionPanel

local collectionTitle = makeLabel(collectionPanel, "Title", UDim2.new(0, 12, 0, 8), UDim2.new(1, -24, 0, 26), "MY BRAINROTS  (0)", 18, Color3.fromRGB(255, 255, 255))
local collectionList = Instance.new("TextLabel")
collectionList.Name = "List"
collectionList.Position = UDim2.new(0, 12, 0, 38)
collectionList.Size = UDim2.new(1, -24, 1, -46)
collectionList.BackgroundTransparency = 1
collectionList.Text = "None yet!\nBuy one at the conveyor."
collectionList.TextSize = 16
collectionList.TextColor3 = Color3.fromRGB(220, 220, 220)
collectionList.Font = Enum.Font.Gotham
collectionList.TextXAlignment = Enum.TextXAlignment.Left
collectionList.TextYAlignment = Enum.TextYAlignment.Top
collectionList.TextWrapped = true
collectionList.Parent = collectionPanel

-- Bottom-center controls hint.
local hintLabel = makeLabel(gui, "HintLabel", UDim2.new(0.5, -320, 1, -46), UDim2.fromOffset(640, 30), "E  Buy / Steal      F  Slap a thief      L  Lock base      U  Upgrades", 18, Color3.fromRGB(255, 255, 255))
hintLabel.TextXAlignment = Enum.TextXAlignment.Center
hintLabel.AnchorPoint = Vector2.new(0.5, 0)

-- Bottom-right action buttons.
local lockButton = makeButton(gui, "LockButton", UDim2.new(1, -296, 1, -116), UDim2.fromOffset(130, 48), "LOCK BASE (L)", Color3.fromRGB(60, 120, 220))
local rebirthButton = makeButton(gui, "RebirthButton", UDim2.new(1, -156, 1, -116), UDim2.fromOffset(140, 48), "REBIRTH", Color3.fromRGB(150, 70, 220))
local upgradeButton = makeButton(gui, "UpgradeButton", UDim2.new(1, -156, 1, -60), UDim2.fromOffset(140, 48), "UPGRADES (U)", Color3.fromRGB(40, 170, 90))

-- Top-center announcement banner.
local banner = Instance.new("Frame")
banner.Name = "Banner"
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.new(0.5, 0, 0, 16)
banner.Size = UDim2.fromOffset(520, 76)
banner.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
banner.BackgroundTransparency = 0.15
banner.BorderSizePixel = 0
banner.Visible = false
banner.Parent = gui
local bannerCorner = Instance.new("UICorner")
bannerCorner.CornerRadius = UDim.new(0, 10)
bannerCorner.Parent = banner
local bannerTitle = makeLabel(banner, "Title", UDim2.new(0, 12, 0, 6), UDim2.new(1, -24, 0, 34), "", 24, Color3.fromRGB(255, 255, 255))
bannerTitle.TextXAlignment = Enum.TextXAlignment.Center
local bannerSubtitle = makeLabel(banner, "Subtitle", UDim2.new(0, 12, 0, 40), UDim2.new(1, -24, 0, 28), "", 17, Color3.fromRGB(255, 230, 180))
bannerSubtitle.TextXAlignment = Enum.TextXAlignment.Center

-- Toast line under the banner.
local toastLabel = makeLabel(gui, "ToastLabel", UDim2.new(0.5, -320, 0, 100), UDim2.fromOffset(640, 30), "", 19, Color3.fromRGB(255, 255, 255))
toastLabel.TextXAlignment = Enum.TextXAlignment.Center
toastLabel.Visible = false

-- Upgrade panel (hidden until U).
local upgradePanel = Instance.new("Frame")
upgradePanel.Name = "UpgradePanel"
upgradePanel.AnchorPoint = Vector2.new(0.5, 0.5)
upgradePanel.Position = UDim2.fromScale(0.5, 0.5)
upgradePanel.Size = UDim2.fromOffset(420, 300)
upgradePanel.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
upgradePanel.BorderSizePixel = 0
upgradePanel.Visible = false
upgradePanel.Parent = gui
local upgradeCorner = Instance.new("UICorner")
upgradeCorner.CornerRadius = UDim.new(0, 12)
upgradeCorner.Parent = upgradePanel
local upgradeTitle = makeLabel(upgradePanel, "Title", UDim2.new(0, 16, 0, 12), UDim2.new(1, -32, 0, 30), "UPGRADES", 24, Color3.fromRGB(255, 255, 255))
upgradeTitle.TextXAlignment = Enum.TextXAlignment.Center

local pedestalButton = makeButton(upgradePanel, "PedestalButton", UDim2.new(0, 16, 0, 56), UDim2.new(1, -32, 0, 52), "+2 PEDESTALS", Color3.fromRGB(60, 120, 220))
local incomeButton = makeButton(upgradePanel, "IncomeButton", UDim2.new(0, 16, 0, 120), UDim2.new(1, -32, 0, 52), "+25% INCOME", Color3.fromRGB(40, 170, 90))
local lockUpgradeButton = makeButton(upgradePanel, "LockUpgradeButton", UDim2.new(0, 16, 0, 184), UDim2.new(1, -32, 0, 52), "+15s BASE LOCK", Color3.fromRGB(150, 70, 220))
local closeButton = makeButton(upgradePanel, "CloseButton", UDim2.new(0, 16, 0, 248), UDim2.new(1, -32, 0, 40), "CLOSE (U)", Color3.fromRGB(90, 90, 100))

local latestState = nil
local bannerToken = 0
local toastToken = 0

-- Renders one state update into every HUD element.
local function renderState(state)
	latestState = state
	cashLabel.Text = "CASH  $" .. state.cash
	local incomeText = "+$" .. state.incomePerSec .. " / sec"
	if state.eventMultiplier ~= nil and state.eventMultiplier > 1 then
		incomeText ..= "  (GOLDEN HOUR x" .. state.eventMultiplier .. ")"
	end
	incomeLabel.Text = incomeText
	rebirthLabel.Text = "REBIRTHS  " .. state.rebirths .. "  (x" .. (state.rebirths + 1) .. " income)"
	if state.plotName ~= nil then
		collectionTitle.Text = "MY BRAINROTS  (" .. state.brainrotCount .. "/" .. state.pedestalsOwned .. ")  -  " .. state.plotName
	else
		collectionTitle.Text = "MY BRAINROTS  (" .. state.brainrotCount .. ")"
	end
	if state.brainrotCount == 0 then
		collectionList.Text = "None yet!\nBuy one at the conveyor."
	else
		local lines = {}
		for _, owned in ipairs(state.owned) do
			table.insert(lines, owned.name .. "  -  $" .. owned.rate .. "/s")
		end
		collectionList.Text = table.concat(lines, "\n")
	end
	if state.lockRemaining > 0 then
		lockButton.Text = "LOCKED " .. math.ceil(state.lockRemaining) .. "s"
	elseif state.lockCooldown > 0 then
		lockButton.Text = "LOCK (" .. math.ceil(state.lockCooldown) .. "s)"
	else
		lockButton.Text = "LOCK BASE (L)"
	end
	if state.canRebirth then
		rebirthButton.Text = "REBIRTH! (ready)"
	else
		rebirthButton.Text = "REBIRTH $" .. state.rebirthCashNeeded
	end
	pedestalButton.Text = "+2 PEDESTALS  -  $" .. state.pedestalCost
	incomeButton.Text = "+25% INCOME  (Lv " .. state.incomeLevel .. ")  -  $" .. state.incomeCost
	lockUpgradeButton.Text = "+15s BASE LOCK  (Lv " .. state.lockLevel .. ")  -  $" .. state.lockCost
	if state.carrying then
		hintLabel.Text = "YOU ARE CARRYING A BRAINROT - RUN TO YOUR BASE!"
		hintLabel.TextColor3 = Color3.fromRGB(255, 120, 120)
	else
		hintLabel.Text = "E  Buy / Steal      F  Slap a thief      L  Lock base      U  Upgrades"
		hintLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
end

-- Shows a banner announcement for a few seconds.
local function showBanner(title, subtitle)
	bannerToken += 1
	local token = bannerToken
	bannerTitle.Text = title
	bannerSubtitle.Text = subtitle
	banner.Visible = true
	task.delay(5, function()
		if token == bannerToken then
			banner.Visible = false
		end
	end)
end

-- Shows a one-line toast for a few seconds.
local function showToast(text)
	toastToken += 1
	local token = toastToken
	toastLabel.Text = text
	toastLabel.Visible = true
	task.delay(4, function()
		if token == toastToken then
			toastLabel.Visible = false
		end
	end)
end

local function toggleUpgrades()
	upgradePanel.Visible = not upgradePanel.Visible
end

StateUpdate.OnClientEvent:Connect(renderState)
Announce.OnClientEvent:Connect(showBanner)
Toast.OnClientEvent:Connect(showToast)

lockButton.MouseButton1Click:Connect(function()
	LockBase:FireServer()
end)
rebirthButton.MouseButton1Click:Connect(function()
	Rebirth:FireServer()
end)
upgradeButton.MouseButton1Click:Connect(toggleUpgrades)
closeButton.MouseButton1Click:Connect(toggleUpgrades)
pedestalButton.MouseButton1Click:Connect(function()
	BuyUpgrade:FireServer("pedestal")
end)
incomeButton.MouseButton1Click:Connect(function()
	BuyUpgrade:FireServer("income")
end)
lockUpgradeButton.MouseButton1Click:Connect(function()
	BuyUpgrade:FireServer("lock")
end)

ContextActionService:BindAction("BrainrotSlap", function(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		SlapPlayer:FireServer()
	end
	return Enum.ContextActionResult.Pass
end, false, Enum.KeyCode.F)

ContextActionService:BindAction("BrainrotLock", function(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		LockBase:FireServer()
	end
	return Enum.ContextActionResult.Pass
end, false, Enum.KeyCode.L)

ContextActionService:BindAction("BrainrotUpgrades", function(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		toggleUpgrades()
	end
	return Enum.ContextActionResult.Pass
end, false, Enum.KeyCode.U)

-- Ask for the first state as soon as the client is ready.
RequestState:FireServer()
