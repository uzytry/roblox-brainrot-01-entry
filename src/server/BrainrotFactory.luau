-- BrainrotFactory: builds a brainrot character as a 3D Model of parts.
-- Every character gets a body, a head and the accessories its shape calls
-- for, a floating name label with its rarity and money-per-second, and a
-- ProximityPrompt the buyer or the thief presses. Models are built from
-- plain parts only, so they load in any Studio with no uploaded assets.

local BrainrotFactory = {}

-- Adds one part to a model at an offset from the model's origin.
local function addPart(model, name, size, color, offset, shape, material, orientation)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Shape = shape or Enum.PartType.Block
	part.Material = material or Enum.Material.SmoothPlastic
	part.CFrame = CFrame.new(offset)
	if orientation ~= nil then
		part.Orientation = orientation
	end
	part.Anchored = true
	part.CanCollide = false
	part.Parent = model
	return part
end

-- Adds a wedge part (fins, tails, horns) to a model.
local function addWedge(model, name, size, color, offset, orientation)
	local wedge = Instance.new("WedgePart")
	wedge.Name = name
	wedge.Size = size
	wedge.Color = color
	wedge.Material = Enum.Material.SmoothPlastic
	wedge.CFrame = CFrame.new(offset)
	if orientation ~= nil then
		wedge.Orientation = orientation
	end
	wedge.Anchored = true
	wedge.CanCollide = false
	wedge.Parent = model
	return wedge
end

-- The common body and head every character starts from.
local function buildBodyAndHead(model, character, bodySize, headSize)
	local body = addPart(model, "Body", bodySize, character.bodyColor, Vector3.new(0, 0, 0))
	local head = addPart(model, "Head", headSize, character.headColor, Vector3.new(0, bodySize.Y / 2 + headSize.Y / 2, 0))
	model.PrimaryPart = body
	return body, head
end

-- One accessory builder per shape. Each adds the parts that make the
-- character read as itself from across the map.
local SHAPE_BUILDERS = {}

SHAPE_BUILDERS.Pizza = function(model, character)
	local body = addPart(model, "Body", Vector3.new(1.9, 0.4, 1.9), character.bodyColor, Vector3.new(0, 0, 0))
	addPart(model, "Tomato", Vector3.new(0.7, 0.7, 0.7), character.headColor, Vector3.new(0, 0.6, 0), Enum.PartType.Ball)
	addPart(model, "Basil1", Vector3.new(0.4, 0.4, 0.4), character.accentColor, Vector3.new(0.6, 0.3, 0.4), Enum.PartType.Ball)
	addPart(model, "Basil2", Vector3.new(0.4, 0.4, 0.4), character.accentColor, Vector3.new(-0.5, 0.3, -0.5), Enum.PartType.Ball)
	model.PrimaryPart = body
end

SHAPE_BUILDERS.Bird = function(model, character)
	buildBodyAndHead(model, character, Vector3.new(1.3, 1.3, 1.3), Vector3.new(0.9, 0.9, 0.9))
	addPart(model, "Beak", Vector3.new(0.4, 0.3, 0.6), character.accentColor, Vector3.new(0, 1.4, 0.8))
	addPart(model, "WingLeft", Vector3.new(0.3, 0.9, 0.8), character.headColor, Vector3.new(-0.85, 0.1, 0))
	addPart(model, "WingRight", Vector3.new(0.3, 0.9, 0.8), character.headColor, Vector3.new(0.85, 0.1, 0))
	addPart(model, "Tail", Vector3.new(0.8, 0.2, 0.8), character.accentColor, Vector3.new(0, 0.3, -0.9))
end

SHAPE_BUILDERS.Log = function(model, character)
	local body = addPart(model, "Body", Vector3.new(2.2, 1.4, 1.4), character.bodyColor, Vector3.new(0, 0, 0), Enum.PartType.Cylinder, Enum.Material.Wood, Vector3.new(0, 0, 90))
	addPart(model, "Head", Vector3.new(1.1, 1.1, 1.1), character.headColor, Vector3.new(0, 1.5, 0), Enum.PartType.Cylinder, Enum.Material.Wood, Vector3.new(0, 0, 90))
	addPart(model, "Bat", Vector3.new(0.3, 1.7, 0.3), character.accentColor, Vector3.new(0.9, 0.6, 0.4), Enum.PartType.Block, Enum.Material.Wood, Vector3.new(0, 0, 25))
	addPart(model, "EyeLeft", Vector3.new(0.25, 0.25, 0.25), Color3.fromRGB(255, 255, 255), Vector3.new(-0.3, 1.6, 0.55), Enum.PartType.Ball)
	addPart(model, "EyeRight", Vector3.new(0.25, 0.25, 0.25), Color3.fromRGB(255, 255, 255), Vector3.new(0.3, 1.6, 0.55), Enum.PartType.Ball)
	model.PrimaryPart = body
end

SHAPE_BUILDERS.Ballerina = function(model, character)
	local body = addPart(model, "Body", Vector3.new(1.4, 1.6, 1.4), character.bodyColor, Vector3.new(0, 0, 0), Enum.PartType.Cylinder, Enum.Material.SmoothPlastic, Vector3.new(0, 0, 90))
	addPart(model, "Head", Vector3.new(1, 1, 1), character.headColor, Vector3.new(0, 1.4, 0), Enum.PartType.Ball)
	addPart(model, "Tutu", Vector3.new(0.25, 2.3, 2.3), character.accentColor, Vector3.new(0, -0.3, 0), Enum.PartType.Cylinder, Enum.Material.SmoothPlastic, Vector3.new(0, 0, 90))
	addPart(model, "LegLeft", Vector3.new(0.3, 1, 0.3), character.headColor, Vector3.new(-0.35, -1.2, 0))
	addPart(model, "LegRight", Vector3.new(0.3, 1, 0.3), character.headColor, Vector3.new(0.35, -1.2, 0))
	addPart(model, "Bun", Vector3.new(0.5, 0.5, 0.5), character.accentColor, Vector3.new(0, 2, 0), Enum.PartType.Ball)
	model.PrimaryPart = body
end

SHAPE_BUILDERS.Shark = function(model, character)
	buildBodyAndHead(model, character, Vector3.new(1.4, 1, 2.2), Vector3.new(1.1, 0.9, 1))
	addWedge(model, "Fin", Vector3.new(0.3, 0.9, 1), character.headColor, Vector3.new(0, 0.9, -0.2))
	addWedge(model, "Tail", Vector3.new(0.3, 1, 0.8), character.headColor, Vector3.new(0, 0.2, -1.5), Vector3.new(0, 180, 0))
	addPart(model, "Leg1", Vector3.new(0.35, 0.9, 0.35), character.accentColor, Vector3.new(-0.5, -0.9, 0.4))
	addPart(model, "Leg2", Vector3.new(0.35, 0.9, 0.35), character.accentColor, Vector3.new(0.5, -0.9, 0.4))
	addPart(model, "Leg3", Vector3.new(0.35, 0.9, 0.35), character.accentColor, Vector3.new(0, -0.9, -0.5))
	addPart(model, "Shoe1", Vector3.new(0.5, 0.3, 0.8), Color3.fromRGB(255, 255, 255), Vector3.new(-0.5, -1.4, 0.5))
	addPart(model, "Shoe2", Vector3.new(0.5, 0.3, 0.8), Color3.fromRGB(255, 255, 255), Vector3.new(0.5, -1.4, 0.5))
	addPart(model, "Shoe3", Vector3.new(0.5, 0.3, 0.8), Color3.fromRGB(255, 255, 255), Vector3.new(0, -1.4, -0.4))
end

SHAPE_BUILDERS.Monkey = function(model, character)
	buildBodyAndHead(model, character, Vector3.new(1.4, 1.4, 1.2), Vector3.new(1.1, 1, 1))
	addPart(model, "EarLeft", Vector3.new(0.4, 0.4, 0.4), character.headColor, Vector3.new(-0.7, 1.3, 0), Enum.PartType.Ball)
	addPart(model, "EarRight", Vector3.new(0.4, 0.4, 0.4), character.headColor, Vector3.new(0.7, 1.3, 0), Enum.PartType.Ball)
	addPart(model, "ArmLeft", Vector3.new(0.35, 1.2, 0.35), character.bodyColor, Vector3.new(-0.9, 0, 0.2), Enum.PartType.Block, Enum.Material.SmoothPlastic, Vector3.new(0, 0, 20))
	addPart(model, "ArmRight", Vector3.new(0.35, 1.2, 0.35), character.bodyColor, Vector3.new(0.9, 0, 0.2), Enum.PartType.Block, Enum.Material.SmoothPlastic, Vector3.new(0, 0, -20))
	addPart(model, "Tail", Vector3.new(0.25, 1.4, 0.25), character.bodyColor, Vector3.new(0.5, -0.5, -0.8), Enum.PartType.Block, Enum.Material.SmoothPlastic, Vector3.new(30, 0, 0))
	addPart(model, "Leaf", Vector3.new(0.8, 0.2, 0.8), character.accentColor, Vector3.new(0, 1.95, 0))
end

SHAPE_BUILDERS.Ninja = function(model, character)
	local body = addPart(model, "Body", Vector3.new(1.3, 1.7, 1.3), character.bodyColor, Vector3.new(0, 0, 0), Enum.PartType.Cylinder, Enum.Material.SmoothPlastic, Vector3.new(0, 0, 90))
	addPart(model, "Head", Vector3.new(1.1, 1, 1.1), character.headColor, Vector3.new(0, 1.4, 0), Enum.PartType.Ball)
	addPart(model, "Headband", Vector3.new(1.2, 0.25, 1.2), character.accentColor, Vector3.new(0, 1.6, 0))
	addPart(model, "Katana", Vector3.new(0.15, 2, 0.15), Color3.fromRGB(200, 200, 210), Vector3.new(-0.7, 0.6, -0.6), Enum.PartType.Block, Enum.Material.Metal, Vector3.new(0, 0, 35))
	addPart(model, "EyeBand", Vector3.new(0.9, 0.25, 0.2), Color3.fromRGB(255, 255, 255), Vector3.new(0, 1.35, 0.55))
	model.PrimaryPart = body
end

SHAPE_BUILDERS.Croc = function(model, character)
	buildBodyAndHead(model, character, Vector3.new(1.2, 0.9, 2.6), Vector3.new(1, 0.8, 0.9))
	addPart(model, "Snout", Vector3.new(0.8, 0.4, 0.9), character.headColor, Vector3.new(0, 0.7, 1.5))
	addWedge(model, "Tail", Vector3.new(0.4, 0.8, 1.2), character.headColor, Vector3.new(0, 0, -1.8), Vector3.new(0, 180, 0))
	addPart(model, "Bomb", Vector3.new(0.9, 0.9, 0.9), Color3.fromRGB(30, 30, 30), Vector3.new(0, 1, -0.3), Enum.PartType.Ball)
	addPart(model, "Fuse", Vector3.new(0.15, 0.5, 0.15), character.accentColor, Vector3.new(0, 1.6, -0.3))
	addPart(model, "LegFL", Vector3.new(0.35, 0.6, 0.35), character.headColor, Vector3.new(-0.6, -0.7, 0.9))
	addPart(model, "LegFR", Vector3.new(0.35, 0.6, 0.35), character.headColor, Vector3.new(0.6, -0.7, 0.9))
	addPart(model, "LegBL", Vector3.new(0.35, 0.6, 0.35), character.headColor, Vector3.new(-0.6, -0.7, -0.9))
	addPart(model, "LegBR", Vector3.new(0.35, 0.6, 0.35), character.headColor, Vector3.new(0.6, -0.7, -0.9))
end

SHAPE_BUILDERS.Cow = function(model, character)
	buildBodyAndHead(model, character, Vector3.new(1.4, 1.2, 2), Vector3.new(1.1, 1, 1))
	addPart(model, "Snout", Vector3.new(0.8, 0.5, 0.4), Color3.fromRGB(255, 180, 200), Vector3.new(0, 0.9, 1.1))
	addPart(model, "HornLeft", Vector3.new(0.25, 0.6, 0.25), Color3.fromRGB(255, 240, 200), Vector3.new(-0.45, 1.9, 0.2))
	addPart(model, "HornRight", Vector3.new(0.25, 0.6, 0.25), Color3.fromRGB(255, 240, 200), Vector3.new(0.45, 1.9, 0.2))
	addPart(model, "Spot1", Vector3.new(0.5, 0.5, 0.2), Color3.fromRGB(40, 40, 40), Vector3.new(0.4, 0.3, 0.95))
	addPart(model, "Spot2", Vector3.new(0.4, 0.4, 0.2), Color3.fromRGB(40, 40, 40), Vector3.new(-0.4, -0.2, -0.95))
	addPart(model, "Ring", Vector3.new(0.15, 3.6, 3.6), character.accentColor, Vector3.new(0, 0.2, 0), Enum.PartType.Cylinder, Enum.Material.Neon, Vector3.new(0, 0, 65))
end

SHAPE_BUILDERS.Giraffe = function(model, character)
	buildBodyAndHead(model, character, Vector3.new(1.3, 1.2, 1.8), Vector3.new(0.9, 0.9, 0.9))
	addPart(model, "Neck", Vector3.new(0.55, 2.2, 0.55), character.bodyColor, Vector3.new(0, 1.8, 0.3))
	local head = model:FindFirstChild("Head")
	if head ~= nil then
		head.CFrame = CFrame.new(0, 3.2, 0.3)
	end
	addPart(model, "Spot1", Vector3.new(0.5, 0.5, 0.2), character.accentColor, Vector3.new(0.3, 0.2, 0.85))
	addPart(model, "Spot2", Vector3.new(0.4, 0.4, 0.2), character.accentColor, Vector3.new(-0.4, -0.1, -0.85))
	addPart(model, "Star", Vector3.new(0.5, 0.5, 0.5), Color3.fromRGB(255, 240, 120), Vector3.new(0, 3.9, 0.3), Enum.PartType.Ball, Enum.Material.Neon)
	addPart(model, "LegFL", Vector3.new(0.3, 1.1, 0.3), character.headColor, Vector3.new(-0.5, -1, 0.6))
	addPart(model, "LegFR", Vector3.new(0.3, 1.1, 0.3), character.headColor, Vector3.new(0.5, -1, 0.6))
	addPart(model, "LegBL", Vector3.new(0.3, 1.1, 0.3), character.headColor, Vector3.new(-0.5, -1, -0.6))
	addPart(model, "LegBR", Vector3.new(0.3, 1.1, 0.3), character.headColor, Vector3.new(0.5, -1, -0.6))
end

SHAPE_BUILDERS.Robot = function(model, character)
	buildBodyAndHead(model, character, Vector3.new(1.5, 1.5, 1), Vector3.new(1.1, 0.9, 0.9))
	addPart(model, "Antenna", Vector3.new(0.12, 0.8, 0.12), character.headColor, Vector3.new(0, 2, 0))
	addPart(model, "AntennaTip", Vector3.new(0.35, 0.35, 0.35), character.accentColor, Vector3.new(0, 2.5, 0), Enum.PartType.Ball, Enum.Material.Neon)
	addPart(model, "ChestLight", Vector3.new(0.6, 0.6, 0.15), character.accentColor, Vector3.new(0, 0.2, 0.55), Enum.PartType.Block, Enum.Material.Neon)
	addPart(model, "ArmLeft", Vector3.new(0.35, 1.2, 0.35), character.headColor, Vector3.new(-1, 0, 0))
	addPart(model, "ArmRight", Vector3.new(0.35, 1.2, 0.35), character.headColor, Vector3.new(1, 0, 0))
	addPart(model, "Hat", Vector3.new(1.3, 0.25, 1.3), character.accentColor, Vector3.new(0, 1.8, 0))
end

SHAPE_BUILDERS.Pot = function(model, character)
	local body = addPart(model, "Body", Vector3.new(1.7, 1.6, 1.7), character.bodyColor, Vector3.new(0, 0, 0), Enum.PartType.Cylinder, Enum.Material.SmoothPlastic, Vector3.new(0, 0, 90))
	addPart(model, "Lid", Vector3.new(0.3, 1.9, 1.9), character.headColor, Vector3.new(0, 0.9, 0), Enum.PartType.Cylinder, Enum.Material.SmoothPlastic, Vector3.new(0, 0, 90))
	addPart(model, "Knob", Vector3.new(0.4, 0.4, 0.4), character.accentColor, Vector3.new(0, 1.3, 0), Enum.PartType.Ball)
	addPart(model, "Steam1", Vector3.new(0.5, 0.5, 0.5), Color3.fromRGB(240, 240, 240), Vector3.new(-0.3, 1.9, 0), Enum.PartType.Ball)
	addPart(model, "Steam2", Vector3.new(0.4, 0.4, 0.4), Color3.fromRGB(240, 240, 240), Vector3.new(0.35, 2.3, 0.1), Enum.PartType.Ball)
	addPart(model, "HandleLeft", Vector3.new(0.5, 0.3, 0.3), character.headColor, Vector3.new(-1.1, 0.2, 0))
	addPart(model, "HandleRight", Vector3.new(0.5, 0.3, 0.3), character.headColor, Vector3.new(1.1, 0.2, 0))
	addPart(model, "Flame", Vector3.new(0.7, 0.7, 0.7), character.accentColor, Vector3.new(0, -1.1, 0), Enum.PartType.Ball, Enum.Material.Neon)
	model.PrimaryPart = body
end

SHAPE_BUILDERS.SharkTrio = function(model, character)
	for i = -1, 1 do
		local x = i * 1.1
		addPart(model, "SharkBody" .. i, Vector3.new(0.9, 0.7, 1.4), character.bodyColor, Vector3.new(x, 0, 0))
		addPart(model, "SharkHead" .. i, Vector3.new(0.8, 0.6, 0.7), character.headColor, Vector3.new(x, 0.2, 0.9))
		addWedge(model, "SharkFin" .. i, Vector3.new(0.2, 0.6, 0.6), character.headColor, Vector3.new(x, 0.6, -0.1))
	end
	addPart(model, "Mic", Vector3.new(0.25, 1.1, 0.25), Color3.fromRGB(60, 60, 60), Vector3.new(0, 0.9, 1.2))
	addPart(model, "MicTop", Vector3.new(0.45, 0.45, 0.45), character.accentColor, Vector3.new(0, 1.6, 1.2), Enum.PartType.Ball)
	local body = model:FindFirstChild("SharkBody0")
	if body ~= nil then
		model.PrimaryPart = body
	end
end

SHAPE_BUILDERS.Dragon = function(model, character)
	buildBodyAndHead(model, character, Vector3.new(1.4, 1.2, 2), Vector3.new(1.1, 1, 1))
	addWedge(model, "HornLeft", Vector3.new(0.3, 0.8, 0.3), character.accentColor, Vector3.new(-0.4, 1.9, 0.2), Vector3.new(0, 0, -25))
	addWedge(model, "HornRight", Vector3.new(0.3, 0.8, 0.3), character.accentColor, Vector3.new(0.4, 1.9, 0.2), Vector3.new(0, 0, 25))
	addPart(model, "WingLeft", Vector3.new(1.6, 0.15, 1), character.accentColor, Vector3.new(-1.4, 0.6, -0.2), Enum.PartType.Block, Enum.Material.SmoothPlastic, Vector3.new(0, 0, 25))
	addPart(model, "WingRight", Vector3.new(1.6, 0.15, 1), character.accentColor, Vector3.new(1.4, 0.6, -0.2), Enum.PartType.Block, Enum.Material.SmoothPlastic, Vector3.new(0, 0, -25))
	addWedge(model, "Tail", Vector3.new(0.4, 0.9, 1.4), character.headColor, Vector3.new(0, 0, -1.7), Vector3.new(0, 180, 0))
	addPart(model, "Pasta1", Vector3.new(0.5, 0.5, 0.5), Color3.fromRGB(255, 220, 120), Vector3.new(0.5, 0.8, 0.6), Enum.PartType.Ball)
	addPart(model, "Pasta2", Vector3.new(0.4, 0.4, 0.4), Color3.fromRGB(255, 220, 120), Vector3.new(-0.5, 0.6, -0.4), Enum.PartType.Ball)
end

-- Builds a full brainrot Model for one character and mutation.
function BrainrotFactory.buildBrainrotModel(character, mutationName)
	local model = Instance.new("Model")
	model.Name = character.id

	local builder = SHAPE_BUILDERS[character.shape]
	if builder ~= nil then
		builder(model, character)
	else
		buildBodyAndHead(model, character, Vector3.new(1.5, 1.5, 1.2), Vector3.new(1.1, 1, 1))
	end

	if model.PrimaryPart == nil then
		model.PrimaryPart = model:FindFirstChild("Body")
	end

	-- Mutations glow: a light and a translucent aura shell.
	if mutationName ~= nil and mutationName ~= "Normal" then
		local glowColor = Color3.fromRGB(255, 210, 0)
		if mutationName == "Diamond" then
			glowColor = Color3.fromRGB(120, 220, 255)
		elseif mutationName == "Rainbow" then
			glowColor = Color3.fromRGB(255, 100, 220)
		end
		local light = Instance.new("PointLight")
		light.Color = glowColor
		light.Range = 9
		light.Brightness = 2
		light.Parent = model.PrimaryPart
		local aura = Instance.new("Part")
		aura.Name = "Aura"
		aura.Shape = Enum.PartType.Ball
		aura.Size = Vector3.new(3.4, 3.4, 3.4)
		aura.Color = glowColor
		aura.Material = Enum.Material.Neon
		aura.Transparency = 0.85
		aura.Anchored = true
		aura.CanCollide = false
		aura.Parent = model
	end

	return model
end

-- Attaches the floating name label: name on top, rarity and $/s below.
function BrainrotFactory.attachLabel(model, nameLine, rateLine, rarityColor)
	local gui = Instance.new("BillboardGui")
	gui.Name = "BrainrotLabel"
	gui.Adornee = model.PrimaryPart
	gui.Size = UDim2.new(0, 200, 0, 70)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 80
	gui.Parent = model

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0.55, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = nameLine
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0.4
	nameLabel.TextSize = 18
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = gui

	local rateLabel = Instance.new("TextLabel")
	rateLabel.Name = "RateLabel"
	rateLabel.Position = UDim2.new(0, 0, 0.55, 0)
	rateLabel.Size = UDim2.new(1, 0, 0.45, 0)
	rateLabel.BackgroundTransparency = 1
	rateLabel.Text = rateLine
	rateLabel.TextColor3 = rarityColor
	rateLabel.TextStrokeTransparency = 0.4
	rateLabel.TextSize = 16
	rateLabel.Font = Enum.Font.GothamBold
	rateLabel.Parent = gui

	return gui
end

-- Attaches the E-key prompt a buyer or a thief presses.
function BrainrotFactory.attachPrompt(model, actionText, objectText)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "InteractPrompt"
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart
	return prompt
end

return BrainrotFactory
