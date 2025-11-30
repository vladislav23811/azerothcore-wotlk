-- ============================================================
-- Progressive Systems Core - Unified Infinite Progression
-- ============================================================
-- This is the MAIN script that ties everything together
-- Based on your previous systems but improved and unified
-- ============================================================

local PROGRESSIVE_CORE = {}

-- ============================================================
-- Load Configuration
-- ============================================================
dofile("config.lua")
-- Config is now in _G.Config from config.lua
local Config = _G.Config or {}

-- ============================================================
-- CONFIGURATION (for backward compatibility)
-- ============================================================
PROGRESSIVE_CORE.Config = {
    -- NPC IDs
    NPC_MAIN_MENU = Config.NPC.MAIN_MENU,
    NPC_ITEM_UPGRADE = Config.NPC.ITEM_UPGRADE,
    NPC_PRESTIGE = Config.NPC.PRESTIGE,
    NPC_DIFFICULTY = Config.NPC.DIFFICULTY,
    NPC_REWARD_SHOP = Config.NPC.REWARD_SHOP,
    NPC_INFINITE_DUNGEON = Config.NPC.INFINITE_DUNGEON,
    
    -- Currency Items
    EMBLEM_FROST = Config.Currency.EMBLEM_FROST,
    BLOODY_TOKEN = Config.Currency.BLOODY_TOKEN,
    CELESTIAL_TOKEN = Config.Currency.CELESTIAL_TOKEN,
    PROGRESSION_TOKEN = Config.Currency.PROGRESSION_TOKEN,
    
    -- Point System
    POINTS_PER_KILL_NORMAL = Config.Points.PER_KILL_NORMAL,
    POINTS_PER_KILL_ELITE = Config.Points.PER_KILL_ELITE,
    POINTS_PER_KILL_BOSS = Config.Points.PER_KILL_BOSS,
    POINTS_PER_KILL_WORLDBOSS = Config.Points.PER_KILL_WORLDBOSS,
    
    -- Tier Multipliers
    TIER_MULTIPLIERS = Config.TierMultipliers,
    
    -- Difficulty Scaling
    DIFFICULTIES = Config.Difficulties,
    
    -- Upgrade Costs
    BASE_UPGRADE_COST = Config.Upgrade.BASE_COST,
    UPGRADE_COST_MULTIPLIER = Config.Upgrade.COST_MULTIPLIER,
    MAX_UPGRADE_LEVEL = Config.Upgrade.MAX_LEVEL,
    
    -- Prestige
    PRESTIGE_STAT_BONUS = Config.Prestige.STAT_BONUS_PER_LEVEL,
    PRESTIGE_LOOT_BONUS = Config.Prestige.LOOT_BONUS_PER_LEVEL,
}

-- ============================================================
-- DATABASE SETUP
-- ============================================================
CharDBExecute([[
    CREATE TABLE IF NOT EXISTS `character_progression_unified` (
        `guid` INT UNSIGNED NOT NULL PRIMARY KEY,
        `total_kills` INT UNSIGNED NOT NULL DEFAULT 0,
        `claimed_milestone` INT UNSIGNED NOT NULL DEFAULT 0,
        `prestige_level` INT UNSIGNED NOT NULL DEFAULT 0,
        `difficulty_tier` TINYINT UNSIGNED NOT NULL DEFAULT 1,
        `current_tier` TINYINT UNSIGNED NOT NULL DEFAULT 1,
        `total_power_level` INT UNSIGNED NOT NULL DEFAULT 0,
        `progression_points` BIGINT UNSIGNED NOT NULL DEFAULT 0,
        `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        CONSTRAINT `fk_progression_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]])

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================
function PROGRESSIVE_CORE.GetProgressionData(player)
    local guid = player:GetGUIDLow()
    if guid == 0 then return nil end
    
    local q = CharDBQuery(string.format(
        "SELECT total_kills, claimed_milestone, prestige_level, difficulty_tier, current_tier, progression_points " ..
        "FROM character_progression_unified WHERE guid = %d", guid))
    
    if q then
        return {
            total_kills = q:GetUInt32(0),
            claimed_milestone = q:GetUInt32(1),
            prestige_level = q:GetUInt32(2),
            difficulty_tier = q:GetUInt8(3),
            current_tier = q:GetUInt8(4),
            progression_points = q:GetUInt64(5)
        }
    else
        -- Initialize new player
        CharDBExecute(string.format(
            "INSERT INTO character_progression_unified (guid, difficulty_tier, current_tier) VALUES (%d, 1, 1)", guid))
        return {
            total_kills = 0,
            claimed_milestone = 0,
            prestige_level = 0,
            difficulty_tier = 1,
            current_tier = 1,
            progression_points = 0
        }
    end
end

function PROGRESSIVE_CORE.UpdateProgressionData(player, data)
    local guid = player:GetGUIDLow()
    if guid == 0 then return end
    
    CharDBExecute(string.format(
        "UPDATE character_progression_unified SET " ..
        "total_kills = %d, claimed_milestone = %d, prestige_level = %d, " ..
        "difficulty_tier = %d, current_tier = %d, progression_points = %d " ..
        "WHERE guid = %d",
        data.total_kills, data.claimed_milestone, data.prestige_level,
        data.difficulty_tier, data.current_tier, data.progression_points, guid))
end

function PROGRESSIVE_CORE.AddProgressionPoints(player, points)
    local guid = player:GetGUIDLow()
    if guid == 0 or points == 0 then return end
    
    -- Get current tier for multiplier
    local tierData = CharDBQuery(string.format(
        "SELECT current_tier FROM character_progression_unified WHERE guid = %d", guid))
    local tier = (tierData and tierData:GetUInt8(0)) or 1
    local multiplier = PROGRESSIVE_CORE.Config.TIER_MULTIPLIERS[tier] or 1.0
    
    -- Apply tier multiplier
    local finalPoints = math.floor(points * multiplier)
    
    -- Update both tables
    CharDBExecute(string.format(
        "UPDATE character_progression_unified SET progression_points = progression_points + %d WHERE guid = %d",
        finalPoints, guid))
    CharDBExecute(string.format(
        "UPDATE characters SET reward_points = COALESCE(reward_points, 0) + %d WHERE guid = %d",
        finalPoints, guid))
    
    return finalPoints
end

function PROGRESSIVE_CORE.GetProgressionPoints(player)
    local guid = player:GetGUIDLow()
    if guid == 0 then return 0 end
    
    local q = CharDBQuery(string.format(
        "SELECT COALESCE(progression_points, 0) FROM character_progression_unified WHERE guid = %d", guid))
    if q then
        return q:GetUInt64(0)
    end
    return 0
end

function PROGRESSIVE_CORE.CalculateMilestone(previous)
    local firstMilestone = (Config.Milestone and Config.Milestone.FIRST_MILESTONE) or 100
    local multiplier = (Config.Milestone and Config.Milestone.MULTIPLIER) or 1.5
    
    if previous == 0 then
        return firstMilestone
    else
        return math.floor(previous * multiplier)
    end
end

-- ============================================================
-- KILL EVENT HANDLER (Main Progression)
-- ============================================================
local function OnCreatureKill(event, player, victim)
    if not player or not victim then return end
    
    local data = PROGRESSIVE_CORE.GetProgressionData(player)
    if not data then return end
    
    -- Determine base reward
    local baseReward = PROGRESSIVE_CORE.Config.POINTS_PER_KILL_NORMAL
    local creatureType = "Normal"
    
    if victim:IsWorldBoss() then
        baseReward = PROGRESSIVE_CORE.Config.POINTS_PER_KILL_WORLDBOSS
        creatureType = "World Boss"
    elseif victim:IsDungeonBoss() then
        baseReward = PROGRESSIVE_CORE.Config.POINTS_PER_KILL_BOSS
        creatureType = "Dungeon Boss"
    elseif victim:IsElite() then
        baseReward = PROGRESSIVE_CORE.Config.POINTS_PER_KILL_ELITE
        creatureType = "Elite"
    end
    
    -- Apply difficulty multiplier
    local diffInfo = PROGRESSIVE_CORE.Config.DIFFICULTIES[data.difficulty_tier] or PROGRESSIVE_CORE.Config.DIFFICULTIES[1]
    local finalReward = math.floor(baseReward * diffInfo.points)
    
    -- Award points
    local pointsGained = PROGRESSIVE_CORE.AddProgressionPoints(player, finalReward)
    
    -- Update kill count
    data.total_kills = data.total_kills + 1
    
    -- Check for milestone
    local nextMilestone = PROGRESSIVE_CORE.CalculateMilestone(data.claimed_milestone)
    if data.total_kills >= nextMilestone then
        -- Milestone reward
        local xpBase = (Config.Milestone and Config.Milestone.XP_REWARD_BASE) or 1000
        local goldBase = (Config.Milestone and Config.Milestone.GOLD_REWARD_BASE) or 10000
        local announceThreshold = (Config.Milestone and Config.Milestone.WORLD_ANNOUNCE_THRESHOLD) or 500
        
        local xpReward = player:GetLevel() * xpBase * diffInfo.dmg
        local goldReward = math.floor(nextMilestone / 10) * goldBase * diffInfo.dmg
        
        player:GiveXP(xpReward)
        player:ModifyMoney(goldReward)
        player:PlayDirectSound(888)  -- Level up sound
        
        if nextMilestone % announceThreshold == 0 then
            SendWorldMessage(string.format(
                "|cFF00CCFF%s|r has reached |cffffcc00%d|r progression kills!",
                player:GetName(), nextMilestone))
        else
            player:SendBroadcastMessage(string.format(
                "|cff00ff00Milestone: %d|r (+%d XP, +%d Gold)",
                nextMilestone, xpReward, goldReward/10000))
        end
        
        data.claimed_milestone = nextMilestone
    end
    
    -- Update database
    PROGRESSIVE_CORE.UpdateProgressionData(player, data)
    
    -- Show kill notification (optional, can be disabled)
    if math.random(100) <= 10 then  -- 10% chance to show
        player:SendBroadcastMessage(string.format(
            "|cFFAAAAFFKill: %s|r |cFF00FF00+%d points|r (Tier %d: ×%.1f)",
            creatureType, pointsGained, data.current_tier,
            PROGRESSIVE_CORE.Config.TIER_MULTIPLIERS[data.current_tier] or 1.0))
    end
end

RegisterPlayerEvent(7, OnCreatureKill)  -- PLAYER_EVENT_ON_KILL_CREATURE

-- ============================================================
-- EXPORT FOR OTHER SCRIPTS
-- ============================================================
_G.ProgressiveCore = PROGRESSIVE_CORE

print("[Progressive Systems] Core module loaded successfully!")

