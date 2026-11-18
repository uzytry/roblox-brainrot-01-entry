-- Config: every tuning number of Brainrot Rush in one place.
-- The server reads these for spawning, stealing, locking, waves and rebirths;
-- the client reads the plot list to point the player at their own base.

local Config = {}

Config.GAME_NAME = "Brainrot Rush"
Config.GAME_TAGLINE = "Steal, stack, rebirth!"

-- A new player starts with this much cash.
Config.START_CASH = 100
-- One base plot per player, eight plots on the map.
Config.MAX_PLAYERS = 8

-- The conveyor belt: brainrots walk from START_X to END_X along CONVEYOR_Z.
Config.CONVEYOR_START_X = -40
Config.CONVEYOR_END_X = 42
Config.CONVEYOR_Z = -24
Config.CONVEYOR_Y = 2.6
Config.CONVEYOR_SPEED = 4
Config.SPAWN_INTERVAL = 6
Config.MAX_CONVEYOR_BRAINROTS = 10

-- Pedestals: every base starts with 6 and can buy up to 12.
Config.PEDESTALS_PER_BASE = 6
Config.MAX_PEDESTALS = 12

-- Base plots: two rows of four around the conveyor. The static world in
-- default.project.json builds one folder per plot with this name and center.
Config.PLOTS = {
	{ name = "Plot1", center = Vector3.new(-45, 0, -48), color = "Bright blue" },
	{ name = "Plot2", center = Vector3.new(-15, 0, -48), color = "Bright green" },
	{ name = "Plot3", center = Vector3.new(15, 0, -48), color = "Bright orange" },
	{ name = "Plot4", center = Vector3.new(45, 0, -48), color = "Bright violet" },
	{ name = "Plot5", center = Vector3.new(-45, 0, 8), color = "Bright yellow" },
	{ name = "Plot6", center = Vector3.new(-15, 0, 8), color = "Hot pink" },
	{ name = "Plot7", center = Vector3.new(15, 0, 8), color = "Lime green" },
	{ name = "Plot8", center = Vector3.new(45, 0, 8), color = "Bright red" },
}

-- Pedestal offsets from a plot center. Slots 1-6 are open from the start;
-- slots 7-12 are bought two at a time with the pedestal upgrade. Rows sit
-- 2 studs apart and clear of the back wall by design.
Config.PEDESTAL_OFFSETS = {
	Vector3.new(-5, 0, -2),
	Vector3.new(0, 0, -2),
	Vector3.new(5, 0, -2),
	Vector3.new(-5, 0, 2),
	Vector3.new(0, 0, 2),
	Vector3.new(5, 0, 2),
	Vector3.new(-5, 0, -4),
	Vector3.new(0, 0, -4),
	Vector3.new(5, 0, -4),
	Vector3.new(-5, 0, 4),
	Vector3.new(0, 0, 4),
	Vector3.new(5, 0, 4),
}

-- Stealing: the carrier is slower, a slap drops the catch, and a dropped
-- brainrot walks home to its own pedestal after RETURN_DELAY seconds.
Config.CARRY_OFFSET = Vector3.new(0, 3.4, 0)
Config.CARRY_WALK_SPEED = 12
Config.NORMAL_WALK_SPEED = 16
Config.SLAP_RANGE = 10
Config.SLAP_COOLDOWN = 3
Config.SLAP_STUN_SECONDS = 1.5
Config.RETURN_DELAY = 3

-- Base lock: L locks your own base so nobody can steal from it.
Config.LOCK_DURATION = 30
Config.LOCK_COOLDOWN = 90
Config.LOCK_BONUS_PER_LEVEL = 15

-- The tsunami wave sweeps the map on a timer; standing on your own base
-- keeps you safe, and rare brainrots rain while it runs.
Config.WAVE_INTERVAL = 180
Config.WAVE_WARNING_SECONDS = 15
Config.WAVE_DURATION = 20
Config.WAVE_KNOCKBACK = 90

-- Golden Hour doubles every income for a short while.
Config.GOLDEN_HOUR_INTERVAL = 240
Config.GOLDEN_HOUR_DURATION = 30
Config.GOLDEN_HOUR_MULTIPLIER = 2

-- Rebirth: cash and brainrots reset, income multiplies forever.
Config.REBIRTH_BASE_CASH = 50000
Config.REBIRTH_MIN_BRAINROTS = 4

-- Upgrades sold from the U panel.
Config.UPGRADE_PEDESTAL_BASE_COST = 1500
Config.UPGRADE_PEDESTAL_SLOTS = 2
Config.UPGRADE_INCOME_BASE_COST = 2000
Config.UPGRADE_INCOME_PER_LEVEL = 0.25
Config.UPGRADE_INCOME_MAX_LEVEL = 5
Config.UPGRADE_LOCK_BASE_COST = 3000

Config.LEADERBOARD_SIZE = 5

-- Cash a player needs to rebirth at their current rebirth count.
function Config.getRebirthCashNeeded(rebirthCount)
	return Config.REBIRTH_BASE_CASH * (2 ^ rebirthCount)
end

-- Brainrots a player needs on their base to rebirth.
function Config.getRebirthBrainrotsNeeded(rebirthCount)
	return Config.REBIRTH_MIN_BRAINROTS + rebirthCount
end

-- Permanent income multiplier from rebirths: 1x, 2x, 3x, ...
function Config.getRebirthMultiplier(rebirthCount)
	return 1 + rebirthCount
end

-- Cost of the next pedestal upgrade (two more slots).
function Config.getPedestalUpgradeCost(pedestalsOwned)
	return Config.UPGRADE_PEDESTAL_BASE_COST * (pedestalsOwned - Config.PEDESTALS_PER_BASE + 1)
end

-- Cost of the next income upgrade level.
function Config.getIncomeUpgradeCost(incomeLevel)
	return Config.UPGRADE_INCOME_BASE_COST * (incomeLevel + 1)
end

-- Cost of the next base-lock upgrade level.
function Config.getLockUpgradeCost(lockLevel)
	return Config.UPGRADE_LOCK_BASE_COST * (lockLevel + 1)
end

return Config
