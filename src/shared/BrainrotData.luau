-- BrainrotData: the cast of Brainrot Rush.
-- Every collectible brainrot, the rarity ladder, the mutation table and the
-- weighted rolls the spawner uses. Shared by the server (spawning, income)
-- and the client (labels, shop hints) so both sides agree on names, prices
-- and money-per-second rates.

local BrainrotData = {}

-- Rarity ladder, weakest first. Weight is the spawn weight on the conveyor.
BrainrotData.RARITIES = {
	{ name = "Common", color = Color3.fromRGB(170, 170, 170), weight = 40 },
	{ name = "Rare", color = Color3.fromRGB(80, 160, 255), weight = 28 },
	{ name = "Epic", color = Color3.fromRGB(170, 90, 255), weight = 16 },
	{ name = "Legendary", color = Color3.fromRGB(255, 170, 0), weight = 9 },
	{ name = "Mythic", color = Color3.fromRGB(255, 70, 120), weight = 4.5 },
	{ name = "Brainrot God", color = Color3.fromRGB(255, 230, 0), weight = 2 },
	{ name = "Secret", color = Color3.fromRGB(0, 230, 200), weight = 0.5 },
}

-- During a tsunami wave the rare end of the ladder gets much likelier.
BrainrotData.WAVE_WEIGHT_MULTIPLIER = {
	Common = 0.4,
	Rare = 0.7,
	Epic = 1.5,
	Legendary = 4,
	Mythic = 8,
	["Brainrot God"] = 12,
	Secret = 20,
}

-- Mutations multiply a brainrot's money-per-second rate.
BrainrotData.MUTATIONS = {
	{ name = "Normal", multiplier = 1, weight = 88 },
	{ name = "Golden", multiplier = 2, weight = 8 },
	{ name = "Diamond", multiplier = 3, weight = 3 },
	{ name = "Rainbow", multiplier = 5, weight = 1 },
}

-- The cast: 14 absurd characters over 7 rarities. Shape names the builder
-- BrainrotFactory uses; quirk is the joke line the label shows.
BrainrotData.CHARACTERS = {
	{
		id = "noobini",
		name = "Noobini Pizzanini",
		rarity = "Common",
		cost = 25,
		incomePerSec = 1,
		shape = "Pizza",
		bodyColor = Color3.fromRGB(255, 200, 60),
		headColor = Color3.fromRGB(220, 60, 60),
		accentColor = Color3.fromRGB(120, 200, 80),
		quirk = "Smells like victory. And cheese.",
	},
	{
		id = "pipikiwi",
		name = "Pipi Kiwi",
		rarity = "Common",
		cost = 50,
		incomePerSec = 2,
		shape = "Bird",
		bodyColor = Color3.fromRGB(140, 220, 60),
		headColor = Color3.fromRGB(90, 180, 40),
		accentColor = Color3.fromRGB(255, 220, 0),
		quirk = "Kiwi. Just kiwi.",
	},
	{
		id = "tungtung",
		name = "Tung Tung Tung Sahur",
		rarity = "Rare",
		cost = 250,
		incomePerSec = 8,
		shape = "Log",
		bodyColor = Color3.fromRGB(150, 100, 50),
		headColor = Color3.fromRGB(120, 80, 40),
		accentColor = Color3.fromRGB(90, 60, 30),
		quirk = "Tung tung tung! Wake up, it is sahur!",
	},
	{
		id = "ballerina",
		name = "Ballerina Cappuccina",
		rarity = "Rare",
		cost = 500,
		incomePerSec = 15,
		shape = "Ballerina",
		bodyColor = Color3.fromRGB(245, 245, 245),
		headColor = Color3.fromRGB(200, 150, 110),
		accentColor = Color3.fromRGB(255, 100, 180),
		quirk = "Pirouettes on espresso.",
	},
	{
		id = "tralalero",
		name = "Tralalero Tralala",
		rarity = "Epic",
		cost = 1200,
		incomePerSec = 30,
		shape = "Shark",
		bodyColor = Color3.fromRGB(120, 170, 220),
		headColor = Color3.fromRGB(90, 140, 200),
		accentColor = Color3.fromRGB(255, 255, 255),
		quirk = "Three legs. Zero fear. All sneakers.",
	},
	{
		id = "patapim",
		name = "Brr Brr Patapim",
		rarity = "Epic",
		cost = 2000,
		incomePerSec = 50,
		shape = "Monkey",
		bodyColor = Color3.fromRGB(140, 95, 55),
		headColor = Color3.fromRGB(170, 120, 70),
		accentColor = Color3.fromRGB(80, 200, 90),
		quirk = "Brr brr. Patapim. Enough said.",
	},
	{
		id = "assassino",
		name = "Cappuccino Assassino",
		rarity = "Legendary",
		cost = 5000,
		incomePerSec = 100,
		shape = "Ninja",
		bodyColor = Color3.fromRGB(40, 40, 45),
		headColor = Color3.fromRGB(30, 30, 35),
		accentColor = Color3.fromRGB(255, 60, 60),
		quirk = "Silent. Caffeinated. Deadly.",
	},
	{
		id = "bombardiro",
		name = "Bombardiro Crocodilo",
		rarity = "Legendary",
		cost = 7500,
		incomePerSec = 150,
		shape = "Croc",
		bodyColor = Color3.fromRGB(60, 180, 80),
		headColor = Color3.fromRGB(50, 150, 65),
		accentColor = Color3.fromRGB(255, 220, 0),
		quirk = "A crocodile. A bomber. A problem.",
	},
	{
		id = "lavaca",
		name = "La Vaca Saturno Saturnita",
		rarity = "Mythic",
		cost = 20000,
		incomePerSec = 400,
		shape = "Cow",
		bodyColor = Color3.fromRGB(245, 245, 245),
		headColor = Color3.fromRGB(230, 230, 230),
		accentColor = Color3.fromRGB(170, 90, 255),
		quirk = "Moo, from the rings of Saturn.",
	},
	{
		id = "giraffa",
		name = "Giraffa Celeste",
		rarity = "Mythic",
		cost = 30000,
		incomePerSec = 600,
		shape = "Giraffe",
		bodyColor = Color3.fromRGB(255, 210, 80),
		headColor = Color3.fromRGB(255, 190, 60),
		accentColor = Color3.fromRGB(255, 140, 0),
		quirk = "Reaches the stars. Eats them too.",
	},
	{
		id = "matteo",
		name = "Matteo",
		rarity = "Brainrot God",
		cost = 100000,
		incomePerSec = 1500,
		shape = "Robot",
		bodyColor = Color3.fromRGB(180, 190, 200),
		headColor = Color3.fromRGB(150, 165, 180),
		accentColor = Color3.fromRGB(0, 200, 190),
		quirk = "Beep boop. I am the hat now.",
	},
	{
		id = "pothotspot",
		name = "Pot Hotspot",
		rarity = "Brainrot God",
		cost = 150000,
		incomePerSec = 2200,
		shape = "Pot",
		bodyColor = Color3.fromRGB(230, 120, 40),
		headColor = Color3.fromRGB(200, 90, 30),
		accentColor = Color3.fromRGB(255, 60, 40),
		quirk = "A pot. A hotspot. A fortune.",
	},
	{
		id = "tralaleritas",
		name = "Las Tralaleritas",
		rarity = "Secret",
		cost = 500000,
		incomePerSec = 5000,
		shape = "SharkTrio",
		bodyColor = Color3.fromRGB(120, 170, 220),
		headColor = Color3.fromRGB(90, 140, 200),
		accentColor = Color3.fromRGB(255, 100, 180),
		quirk = "Three sharks. One song. Infinite money.",
	},
	{
		id = "cannelloni",
		name = "Dragon Cannelloni",
		rarity = "Secret",
		cost = 750000,
		incomePerSec = 8000,
		shape = "Dragon",
		bodyColor = Color3.fromRGB(230, 60, 50),
		headColor = Color3.fromRGB(200, 40, 35),
		accentColor = Color3.fromRGB(255, 220, 0),
		quirk = "Pasta with wings. Do not ask.",
	},
}

-- Returns the ladder position of a rarity (1 = Common, 7 = Secret).
function BrainrotData.getRarityIndex(rarityName)
	for index, rarity in ipairs(BrainrotData.RARITIES) do
		if rarity.name == rarityName then
			return index
		end
	end
	return 1
end

-- Returns the display color of a rarity.
function BrainrotData.getRarityColor(rarityName)
	for _, rarity in ipairs(BrainrotData.RARITIES) do
		if rarity.name == rarityName then
			return rarity.color
		end
	end
	return Color3.fromRGB(170, 170, 170)
end

-- Returns one character definition by id, or nil.
function BrainrotData.getCharacter(characterId)
	for _, character in ipairs(BrainrotData.CHARACTERS) do
		if character.id == characterId then
			return character
		end
	end
	return nil
end

-- Returns every character of one rarity.
function BrainrotData.getCharactersByRarity(rarityName)
	local found = {}
	for _, character in ipairs(BrainrotData.CHARACTERS) do
		if character.rarity == rarityName then
			table.insert(found, character)
		end
	end
	return found
end

-- Rolls one rarity name from the weighted ladder. During a wave the rare
-- end of the ladder gets its WAVE_WEIGHT_MULTIPLIER boost.
function BrainrotData.rollRarityName(random, waveActive)
	local total = 0
	for _, rarity in ipairs(BrainrotData.RARITIES) do
		local weight = rarity.weight
		if waveActive then
			weight = weight * (BrainrotData.WAVE_WEIGHT_MULTIPLIER[rarity.name] or 1)
		end
		total += weight
	end
	local pick = random:NextNumber(0, total)
	local running = 0
	for _, rarity in ipairs(BrainrotData.RARITIES) do
		local weight = rarity.weight
		if waveActive then
			weight = weight * (BrainrotData.WAVE_WEIGHT_MULTIPLIER[rarity.name] or 1)
		end
		running += weight
		if pick <= running then
			return rarity.name
		end
	end
	return "Common"
end

-- Rolls one mutation name from the weighted mutation table.
function BrainrotData.rollMutationName(random)
	local total = 0
	for _, mutation in ipairs(BrainrotData.MUTATIONS) do
		total += mutation.weight
	end
	local pick = random:NextNumber(0, total)
	local running = 0
	for _, mutation in ipairs(BrainrotData.MUTATIONS) do
		running += mutation.weight
		if pick <= running then
			return mutation.name
		end
	end
	return "Normal"
end

-- Returns the income multiplier of a mutation name.
function BrainrotData.getMutationMultiplier(mutationName)
	for _, mutation in ipairs(BrainrotData.MUTATIONS) do
		if mutation.name == mutationName then
			return mutation.multiplier
		end
	end
	return 1
end

-- Returns the money per second one brainrot earns with its mutation.
function BrainrotData.getIncomePerSecond(character, mutationName)
	return character.incomePerSec * BrainrotData.getMutationMultiplier(mutationName)
end

-- Returns the display name, with the mutation as a prefix when it has one.
function BrainrotData.getDisplayName(character, mutationName)
	if mutationName == nil or mutationName == "Normal" then
		return character.name
	end
	return mutationName .. " " .. character.name
end

-- Returns the two label lines a brainrot shows above its head.
function BrainrotData.getLabelLines(character, mutationName)
	local rate = BrainrotData.getIncomePerSecond(character, mutationName)
	local nameLine = BrainrotData.getDisplayName(character, mutationName)
	local rateLine = string.upper(character.rarity) .. "  -  $" .. rate .. "/s"
	return nameLine, rateLine
end

return BrainrotData
