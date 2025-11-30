-- ============================================================
-- Progressive Systems Configuration File
-- Easy to modify - all settings in one place!
-- ============================================================

local Config = {}

-- ============================================================
-- NPC ENTRIES
-- ============================================================
Config.NPC = {
    MAIN_MENU = 190000,
    ITEM_UPGRADE = 190001,
    PRESTIGE = 190002,
    DIFFICULTY = 190003,
    REWARD_SHOP = 190004,
    INFINITE_DUNGEON = 190005,
    PROGRESSIVE_ITEMS = 190006,
}

-- ============================================================
-- CURRENCY ITEMS
-- ============================================================
Config.Currency = {
    EMBLEM_FROST = 49426,
    BLOODY_TOKEN = 99999,
    CELESTIAL_TOKEN = 99998,
    PROGRESSION_TOKEN = 99997,
}

-- ============================================================
-- POINT SYSTEM
-- ============================================================
Config.Points = {
    PER_KILL_NORMAL = 5,
    PER_KILL_ELITE = 10,
    PER_KILL_BOSS = 25,
    PER_KILL_WORLDBOSS = 75,
    PER_DUNGEON_COMPLETE = 500,
    PER_RAID_COMPLETE = 2000,
}

-- ============================================================
-- TIER MULTIPLIERS
-- Higher tier = more points per kill
-- ============================================================
Config.TierMultipliers = {
    [1] = 5.0,
    [2] = 15.0,
    [3] = 30.0,
    [4] = 50.0,
    [5] = 75.0,
    [6] = 105.0,
    [7] = 140.0,
    [8] = 180.0,
    [9] = 225.0,
    [10] = 275.0,
    [11] = 330.0,
    [12] = 390.0,
    [13] = 455.0,
    [14] = 525.0,
    [15] = 600.0,
    -- Add more tiers as needed (infinite scaling!)
    [20] = 1000.0,
    [30] = 2000.0,
    [50] = 5000.0,
    [100] = 15000.0,
}

-- ============================================================
-- DIFFICULTY SETTINGS
-- ============================================================
Config.Difficulties = {
    [0] = { name = "Easy",    hp = 0.5,  dmg = 0.5,  points = 0.5,  color = "00FF00" },
    [1] = { name = "Normal",  hp = 1.0,  dmg = 1.0,  points = 1.0,  color = "00FF00" },
    [2] = { name = "Hard",    hp = 2.0,  dmg = 2.0,  points = 1.5,  color = "FFFF00" },
    [3] = { name = "Extreme", hp = 3.0,  dmg = 3.0,  points = 2.0,  color = "FFA500" },
    [4] = { name = "Insane",  hp = 5.0,  dmg = 5.0,  points = 3.0,  color = "FF0000" },
    [5] = { name = "Nightmare", hp = 8.0,  dmg = 8.0,  points = 5.0,  color = "8B00FF" },
    [6] = { name = "Hell",    hp = 12.0, dmg = 12.0, points = 8.0,  color = "FF00FF" },
}

-- ============================================================
-- UPGRADE SYSTEM
-- ============================================================
Config.Upgrade = {
    BASE_COST = 100,
    COST_MULTIPLIER = 1.15,  -- 15% increase per level
    MAX_LEVEL = 1000,
    STAT_BONUS_PER_LEVEL = 0.05,  -- 5% per level
}

-- ============================================================
-- PRESTIGE SYSTEM
-- ============================================================
Config.Prestige = {
    MAX_LEVEL = 1000,
    STAT_BONUS_PER_LEVEL = 0.01,      -- 1% per level
    LOOT_BONUS_PER_LEVEL = 0.005,      -- 0.5% per level
    MIN_LEVEL_REQUIRED = 80,
}

-- ============================================================
-- MILESTONE SYSTEM
-- ============================================================
Config.Milestone = {
    FIRST_MILESTONE = 5,
    MULTIPLIER = 1.5,  -- Each milestone is 1.5x the previous
    XP_REWARD_BASE = 1000,  -- Base XP = level * 1000
    GOLD_REWARD_BASE = 10000,  -- Base gold per 10 kills
    WORLD_ANNOUNCE_THRESHOLD = 500,  -- Announce every 500 kills
}

-- ============================================================
-- REWARD SHOP ITEMS
-- Format: { itemId, cost, name }
-- ============================================================
Config.RewardShop = {
    -- Potions
    { itemId = 33447, cost = 100, name = "Runic Healing Potion" },
    { itemId = 33448, cost = 100, name = "Runic Mana Potion" },
    
    -- Elixirs
    { itemId = 40078, cost = 500, name = "Elixir of Mighty Strength" },
    { itemId = 40079, cost = 500, name = "Elixir of Mighty Agility" },
    { itemId = 40081, cost = 500, name = "Elixir of Mighty Intellect" },
    
    -- Flasks
    { itemId = 46376, cost = 2000, name = "Flask of the Frost Wyrm" },
    { itemId = 46377, cost = 2000, name = "Flask of Endless Rage" },
    { itemId = 46378, cost = 2000, name = "Flask of Pure Mojo" },
    { itemId = 46379, cost = 2000, name = "Flask of Stoneblood" },
    
    -- Add more items as needed
}

-- ============================================================
-- INFINITE DUNGEON SETTINGS
-- ============================================================
Config.InfiniteDungeon = {
    START_FLOOR = 1,
    HEALTH_MULTIPLIER_PER_FLOOR = 0.1,  -- 10% more HP per floor
    DAMAGE_MULTIPLIER_PER_FLOOR = 0.1,  -- 10% more damage per floor
    POINTS_PER_FLOOR = 100,
    POINTS_MULTIPLIER_PER_FLOOR = 0.05,  -- 5% more points per floor
}

-- ============================================================
-- EXPORT
-- ============================================================
return Config

