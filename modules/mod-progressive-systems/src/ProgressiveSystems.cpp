/*
 * Progressive Systems Module
 * Infinite progression system implementation
 */

#include "ProgressiveSystems.h"
#include "ProgressiveSystemsAddon.h"
#include "ProgressiveSystemsCache.h"
#include "ProgressiveSystemsHelpers.h"
#include "UnifiedStatSystem.h"
#include "DailyChallengeSystem.h"
#include "SeasonalSystem.h"
#include "DatabaseEnv.h"
#include "ObjectMgr.h"
#include "ScriptMgr.h"
#include "World.h"
#include "Chat.h"
#include "Language.h"
#include "Log.h"
#include "Config.h"
#include <cmath>
#include <stdexcept>

using namespace ProgressiveSystemsHelpers;

ProgressiveSystems* ProgressiveSystems::instance()
{
    static ProgressiveSystems instance;
    return &instance;
}

// Difficulty Scaling
uint8 ProgressiveSystems::GetDifficultyTier(Player* player, Map* map)
{
    if (!ValidationHelper::ValidatePlayer(player, "GetDifficultyTier") || !map)
        return DIFFICULTY_NORMAL;

    // Check if instance
    if (!map->IsDungeon() && !map->IsRaid())
        return DIFFICULTY_NORMAL;

    // Get instance ID
    uint32 instanceId = map->GetInstanceId();
    if (instanceId == 0)
        return DIFFICULTY_NORMAL;

    // Try to get from instance-specific tracking first (Mythic+)
    uint8 tier = GetDifficultyTierByInstanceId(instanceId);
    if (tier > 0)
        return tier;

    // Fallback to player's default difficulty tier
    uint32 guid = player->GetGUID().GetCounter();
    QueryResult result = CharacterDatabase.Query("SELECT difficulty_tier FROM character_progression_unified WHERE guid = {}", guid);
    
    if (result)
    {
        Field* fields = result->Fetch();
        return fields[0].Get<uint8>();
    }

    return DIFFICULTY_NORMAL;
}

uint8 ProgressiveSystems::GetDifficultyTierByInstanceId(uint32 instanceId)
{
    if (instanceId == 0)
        return DIFFICULTY_NORMAL;

    QueryResult result = CharacterDatabase.Query("SELECT difficulty_tier FROM instance_difficulty_tracking WHERE instance_id = {}", instanceId);
    
    if (result)
    {
        Field* fields = result->Fetch();
        return fields[0].Get<uint8>();
    }

    return DIFFICULTY_NORMAL;
}

void ProgressiveSystems::SetDifficultyTier(Player* player, Map* map, uint8 tier)
{
    if (!ValidationHelper::ValidatePlayer(player, "SetDifficultyTier") || !map)
        return;
    
    if (tier > MAX_DIFFICULTY_TIER)
    {
        LOG_WARN("module", "ProgressiveSystems::SetDifficultyTier - Invalid tier: {} (max: {})", tier, MAX_DIFFICULTY_TIER);
        return;
    }

    // If in an instance, set per-instance difficulty (Mythic+)
    if (map->IsDungeon() || map->IsRaid())
    {
        uint32 instanceId = map->GetInstanceId();
        if (instanceId > 0)
        {
            SetDifficultyTierByInstanceId(instanceId, map->GetId(), player->GetGUID().GetCounter(), tier);
            LOG_INFO("module", "ProgressiveSystems::SetDifficultyTier - Player {} set tier to {} in instance {}", player->GetName(), tier, instanceId);
            return;
        }
    }

    // Otherwise, set as player's default difficulty tier
    uint32 guid = player->GetGUID().GetCounter();
    CharacterDatabase.Execute("INSERT INTO character_progression_unified (guid, difficulty_tier) VALUES ({}, {}) ON DUPLICATE KEY UPDATE difficulty_tier = {}", guid, tier, tier);
    LOG_INFO("module", "ProgressiveSystems::SetDifficultyTier - Player {} tier set to {}", guid, tier);
}

void ProgressiveSystems::SetDifficultyTierByInstanceId(uint32 instanceId, uint32 mapId, uint32 playerGuid, uint8 tier)
{
    if (instanceId == 0 || !ValidationHelper::ValidateDifficultyTier(tier))
        return;

    CharacterDatabase.Execute(
        "INSERT INTO instance_difficulty_tracking (instance_id, map_id, difficulty_tier, set_by_guid) "
        "VALUES ({}, {}, {}, {}) "
        "ON DUPLICATE KEY UPDATE difficulty_tier = {}, set_by_guid = {}, set_time = CURRENT_TIMESTAMP",
        instanceId, mapId, tier, playerGuid, tier, playerGuid);
    LOG_INFO("module", "ProgressiveSystems::SetDifficultyTierByInstanceId - Instance {} tier set to {}", instanceId, tier);
}

float ProgressiveSystems::GetHealthMultiplier(uint32 mapId, uint8 difficultyTier)
{
    if (difficultyTier == 0)
        return 1.0f;

    QueryResult result = WorldDatabase.Query("SELECT health_multiplier FROM custom_difficulty_scaling WHERE map_id = {} AND difficulty_tier = {}", mapId, difficultyTier);
    
    if (result)
    {
        Field* fields = result->Fetch();
        return fields[0].Get<float>();
    }

    // Default scaling: exponential growth
    return 1.0f + (difficultyTier * 0.15f);
}

float ProgressiveSystems::GetDamageMultiplier(uint32 mapId, uint8 difficultyTier)
{
    if (difficultyTier == 0)
        return 1.0f;

    QueryResult result = WorldDatabase.Query("SELECT damage_multiplier FROM custom_difficulty_scaling WHERE map_id = {} AND difficulty_tier = {}", mapId, difficultyTier);
    
    if (result)
    {
        Field* fields = result->Fetch();
        return fields[0].Get<float>();
    }

    // Default scaling
    return 1.0f + (difficultyTier * 0.12f);
}

uint32 ProgressiveSystems::GetRequiredItemLevel(uint32 mapId, uint8 difficultyTier)
{
    QueryResult result = WorldDatabase.Query("SELECT required_item_level FROM custom_difficulty_scaling WHERE map_id = {} AND difficulty_tier = {}", mapId, difficultyTier);
    
    if (result)
    {
        Field* fields = result->Fetch();
        return fields[0].Get<uint32>();
    }

    return 0;
}

uint32 ProgressiveSystems::GetRewardPoints(uint32 mapId, uint8 difficultyTier)
{
    QueryResult result = WorldDatabase.Query("SELECT reward_points FROM custom_difficulty_scaling WHERE map_id = {} AND difficulty_tier = {}", mapId, difficultyTier);
    
    if (result)
    {
        Field* fields = result->Fetch();
        return fields[0].Get<uint32>();
    }

    return 100 * (1 + difficultyTier);
}

// Progression Points
void ProgressiveSystems::AddProgressionPoints(Player* player, uint32 points)
{
    if (!ValidationHelper::ValidatePlayer(player, "AddProgressionPoints") || points == 0)
        return;

    uint32 guid = player->GetGUID().GetCounter();
    
    // Get current tier for multiplier
    QueryResult tierResult = CharacterDatabase.Query("SELECT current_tier FROM character_progression_unified WHERE guid = {}", guid);
    uint8 tier = 1;
    if (tierResult)
    {
        tier = tierResult->Fetch()[0].Get<uint8>();
    }
    
    // Apply tier multiplier (5x, 15x, 30x, etc.)
    float multiplier = 1.0f;
    if (tier == 1) multiplier = 5.0f;
    else if (tier == 2) multiplier = 15.0f;
    else if (tier == 3) multiplier = 30.0f;
    else if (tier == 4) multiplier = 50.0f;
    else if (tier >= 5) multiplier = 75.0f + ((tier - 5) * 30.0f);
    
    uint32 finalPoints = static_cast<uint32>(points * multiplier);
    
    // Add progression points atomically
    CharacterDatabase.Execute(
        "INSERT INTO character_progression_unified (guid, progression_points, total_progression_points_earned) "
        "VALUES ({}, {}, {}) "
        "ON DUPLICATE KEY UPDATE progression_points = progression_points + {}, total_progression_points_earned = COALESCE(total_progression_points_earned, 0) + {}",
        guid, finalPoints, finalPoints, finalPoints, finalPoints);

    // Also update characters.reward_points (legacy support)
    CharacterDatabase.Execute("UPDATE characters SET reward_points = COALESCE(reward_points, 0) + {} WHERE guid = {}", finalPoints, guid);

    // Invalidate cache
    if (sProgressiveSystemsCache)
        sProgressiveSystemsCache->InvalidateCache(guid);

    // Log action
    LOG_INFO("module", "ProgressiveSystems::AddProgressionPoints - Player {} earned {} points (multiplier: {:.1f}x)", player->GetName(), finalPoints, multiplier);

        // Notify player
        if (player->GetSession())
        {
            ChatHandler(player->GetSession()).PSendSysMessage("You earned %u progression points! (Total: %llu)", 
                finalPoints, GetProgressionPoints(player));
        }
        
        // Send addon updates
        uint64 newTotal = GetProgressionPoints(player);
        sProgressiveSystemsAddon->SendPointsUpdate(player, newTotal);
        
        // Get updated kill count
        QueryResult killResult = CharacterDatabase.Query("SELECT total_kills FROM character_progression_unified WHERE guid = {}", guid);
        if (killResult)
        {
            uint32 totalKills = killResult->Fetch()[0].Get<uint32>();
            if (sProgressiveSystemsAddon)
                sProgressiveSystemsAddon->SendKillUpdate(player, totalKills);
        }
}

bool ProgressiveSystems::SpendProgressionPoints(Player* player, uint32 points)
{
    if (!ValidationHelper::ValidatePlayer(player, "SpendProgressionPoints") || points == 0)
        return false;

    uint32 guid = player->GetGUID().GetCounter();
    
    // Check if player has enough points
    uint64 currentPoints = GetProgressionPoints(player);
    if (currentPoints < points)
    {
        LOG_WARN("module", "ProgressiveSystems::SpendProgressionPoints - Player {} has insufficient points (has: {}, needs: {})", player->GetName(), currentPoints, points);
        return false;
    }
    
    // Spend progression points atomically
    CharacterDatabase.Execute(
        "UPDATE character_progression_unified SET progression_points = GREATEST(progression_points - {}, 0) WHERE guid = {} AND progression_points >= {}",
        points, guid, points);

    // Also update characters.reward_points (legacy support)
    CharacterDatabase.Execute("UPDATE characters SET reward_points = GREATEST(COALESCE(reward_points, 0) - {}, 0) WHERE guid = {}", points, guid);

    // Invalidate cache
    if (sProgressiveSystemsCache)
        sProgressiveSystemsCache->InvalidateCache(guid);

    // Log action
    LOG_INFO("module", "ProgressiveSystems::SpendProgressionPoints - Player {} spent {} points", player->GetName(), points);

    // Send addon update
    if (sProgressiveSystemsAddon)
        sProgressiveSystemsAddon->SendPointsUpdate(player, GetProgressionPoints(player));

    return true;
}

uint64 ProgressiveSystems::GetProgressionPoints(Player* player)
{
    if (!ValidationHelper::ValidatePlayer(player, "GetProgressionPoints"))
        return 0;

    uint32 guid = player->GetGUID().GetCounter();
    
    // Try cache first
    CachedProgressionData cachedData;
    if (sProgressiveSystemsCache->GetProgressionData(guid, cachedData))
    {
        return cachedData.progressionPoints;
    }
    
    // Query database
    QueryResult result = CharacterDatabase.Query("SELECT progression_points FROM character_progression_unified WHERE guid = {}", guid);
    if (result)
    {
        uint64 points = result->Fetch()[0].Get<uint64>();
        // Update cache
        cachedData.progressionPoints = points;
        if (sProgressiveSystemsCache)
            sProgressiveSystemsCache->UpdateProgressionData(guid, cachedData);
        return points;
    }

    return 0;
}

void ProgressiveSystems::UpdateProgressionPoints(Player* player)
{
    // Refresh from database - called after major changes
    if (!ValidationHelper::ValidatePlayer(player, "UpdateProgressionPoints"))
        return;
    
    uint32 guid = player->GetGUID().GetCounter();
    QueryResult result = CharacterDatabase.Query("SELECT progression_points FROM character_progression_unified WHERE guid = {}", guid);
    if (result)
    {
        // Data is already in database, this is just a refresh call
        return;
    }
    
    // Initialize if doesn't exist
    CharacterDatabase.Execute("INSERT INTO character_progression_unified (guid, progression_points) VALUES ({}, 0)", guid);
    LOG_INFO("module", "ProgressiveSystems::UpdateProgressionPoints - Initialized progression for player {}", guid);
}

// Item Upgrades
uint32 ProgressiveSystems::GetItemUpgradeLevel(Item* item)
{
    if (!ValidationHelper::ValidateItem(item, "GetItemUpgradeLevel"))
        return 0;

    uint64 itemGuid = item->GetGUID().GetCounter();
    QueryResult result = CharacterDatabase.Query("SELECT upgrade_level FROM item_upgrades WHERE item_guid = {}", itemGuid);
    
    if (result)
    {
        Field* fields = result->Fetch();
        return fields[0].Get<uint32>();
    }

    return 0;
}

bool ProgressiveSystems::UpgradeItem(Player* player, Item* item)
{
    if (!player || !item)
        return false;

    try
    {
        uint32 currentLevel = GetItemUpgradeLevel(item);
        if (currentLevel >= MAX_ITEM_UPGRADE_LEVEL)
            return false;

        uint32 cost = GetUpgradeCost(currentLevel);
        if (!SpendProgressionPoints(player, cost))
            return false;

        uint64 itemGuid = item->GetGUID().GetCounter();
        CharacterDatabase.Execute(
            "INSERT INTO item_upgrades (item_guid, upgrade_level, stat_bonus_percent, upgrade_cost_progression_points) "
            "VALUES ({}, {}, {}, {}) "
            "ON DUPLICATE KEY UPDATE upgrade_level = upgrade_level + 1, stat_bonus_percent = stat_bonus_percent + {}, upgrade_cost_progression_points = upgrade_cost_progression_points + {}",
            itemGuid, currentLevel + 1, (currentLevel + 1) * UPGRADE_STAT_BONUS_PER_LEVEL * 100.0f, cost,
            UPGRADE_STAT_BONUS_PER_LEVEL * 100.0f, cost);

        // Recalculate stats - force item update
        item->SetState(ITEM_CHANGED, player);
        player->SetVisibleItemSlot(item->GetSlot(), item);
        
        // Reload stat bonuses from database (includes item upgrades)
        sUnifiedStatSystem->LoadPlayerStatBonuses(player);
        
        // Send addon update
        if (sProgressiveSystemsAddon)
            sProgressiveSystemsAddon->SendItemUpgradeData(player);

        if (player->GetSession())
        {
            ChatHandler(player->GetSession()).PSendSysMessage("Item upgraded to level %u!", currentLevel + 1);
        }
        return true;
    }
    catch (const std::exception& e)
    {
        LOG_ERROR("module", "ProgressiveSystems: Exception in UpgradeItem: {}", e.what());
        if (player->GetSession())
        {
            ChatHandler(player->GetSession()).PSendSysMessage("Failed to upgrade item. Please try again.");
        }
        return false;
    }
}

float ProgressiveSystems::GetItemStatBonus(Item* item)
{
    uint32 level = GetItemUpgradeLevel(item);
    return 1.0f + (level * UPGRADE_STAT_BONUS_PER_LEVEL);
}

uint32 ProgressiveSystems::GetUpgradeCost(uint32 currentLevel)
{
    return static_cast<uint32>(BASE_UPGRADE_COST * pow(UPGRADE_COST_MULTIPLIER, currentLevel));
}

// Prestige System
uint32 ProgressiveSystems::GetPrestigeLevel(Player* player)
{
    if (!ValidationHelper::ValidatePlayer(player, "GetPrestigeLevel"))
        return 0;

    uint32 guid = player->GetGUID().GetCounter();
    QueryResult result = CharacterDatabase.Query("SELECT prestige_level FROM character_progression_unified WHERE guid = {}", guid);
    if (result)
    {
        return result->Fetch()[0].Get<uint32>();
    }

    return 0;
}

bool ProgressiveSystems::PrestigeCharacter(Player* player)
{
    if (!ValidationHelper::ValidatePlayer(player, "PrestigeCharacter"))
        return false;

    // Check requirements (e.g., level 80, certain progression points)
    uint32 minLevel = sConfigMgr->GetOption<uint32>("ProgressiveSystems.Prestige.MinLevel", 80);
    if (player->GetLevel() < minLevel)
    {
        LOG_WARN("module", "ProgressiveSystems::PrestigeCharacter - Player {} attempted prestige at level {} (min: {})", player->GetName(), player->GetLevel(), minLevel);
        return false;
    }

    uint32 guid = player->GetGUID().GetCounter();
    QueryResult result = CharacterDatabase.Query("SELECT prestige_level FROM character_progression_unified WHERE guid = {}", guid);
    uint32 currentPrestige = 0;
    if (result)
    {
        currentPrestige = result->Fetch()[0].Get<uint32>();
    }

    if (currentPrestige >= MAX_PRESTIGE_LEVEL)
    {
        LOG_WARN("module", "ProgressiveSystems::PrestigeCharacter - Player {} already at max prestige level", player->GetName());
        return false;
    }

    uint32 newPrestige = currentPrestige + 1;
    
    // Update prestige
    CharacterDatabase.Execute(
        "INSERT INTO character_progression_unified (guid, prestige_level) VALUES ({}, {}) "
        "ON DUPLICATE KEY UPDATE prestige_level = {}",
        guid, newPrestige, newPrestige);
    
    LOG_INFO("module", "ProgressiveSystems::PrestigeCharacter - Player {} reached prestige level {}", player->GetName(), newPrestige);
    if (player->GetSession())
    {
        ChatHandler(player->GetSession()).PSendSysMessage("Congratulations! You reached Prestige Level %u!", newPrestige);
    }
    return true;
}

float ProgressiveSystems::GetPrestigeStatBonus(Player* player)
{
    uint32 prestige = GetPrestigeLevel(player);
    float bonusPerLevel = sConfigMgr->GetOption<float>("ProgressiveSystems.Prestige.StatBonusPerLevel", PRESTIGE_STAT_BONUS_PER_LEVEL);
    return 1.0f + (prestige * bonusPerLevel);
}

float ProgressiveSystems::GetPrestigeLootBonus(Player* player)
{
    uint32 prestige = GetPrestigeLevel(player);
    float bonusPerLevel = sConfigMgr->GetOption<float>("ProgressiveSystems.Prestige.LootBonusPerLevel", PRESTIGE_LOOT_BONUS_PER_LEVEL);
    return 1.0f + (prestige * bonusPerLevel);
}

// Stat Enhancements
uint32 ProgressiveSystems::GetStatEnhancementLevel(Player* player, uint8 statType)
{
    if (!player)
        return 0;

    uint32 guid = player->GetGUID().GetCounter();
    QueryResult result = CharacterDatabase.Query("SELECT enhancement_level FROM character_stat_enhancements WHERE guid = {} AND stat_type = {}", guid, statType);
    
    if (result)
    {
        Field* fields = result->Fetch();
        return fields[0].Get<uint32>();
    }

    return 0;
}

bool ProgressiveSystems::EnhanceStat(Player* player, uint8 statType, uint32 levels)
{
    if (!player || levels == 0)
        return false;

    uint32 currentLevel = GetStatEnhancementLevel(player, statType);
    uint32 totalCost = 0;

    for (uint32 i = 0; i < levels; ++i)
    {
        totalCost += GetStatEnhancementCost(currentLevel + i);
    }

    if (!SpendProgressionPoints(player, totalCost))
        return false;

    uint32 guid = player->GetGUID().GetCounter();
    CharacterDatabase.Execute(
        "INSERT INTO character_stat_enhancements (guid, stat_type, enhancement_level, total_invested_points) "
        "VALUES ({}, {}, {}, {}) "
        "ON DUPLICATE KEY UPDATE enhancement_level = enhancement_level + {}, total_invested_points = total_invested_points + {}",
        guid, statType, currentLevel + levels, totalCost, levels, totalCost);

    // Recalculate stats
    if (statType < MAX_STATS)
        player->UpdateStats(static_cast<Stats>(statType));

    return true;
}

uint32 ProgressiveSystems::GetStatEnhancementCost(uint32 currentLevel)
{
    return 50 * (currentLevel + 1); // Linear cost increase
}

// Power Level
uint32 ProgressiveSystems::CalculatePowerLevel(Player* player)
{
    if (!player)
        return 0;

    uint32 power = 0;

    // Base stats
    power += player->GetTotalStatValue(STAT_STRENGTH);
    power += player->GetTotalStatValue(STAT_AGILITY);
    power += player->GetTotalStatValue(STAT_STAMINA);
    power += player->GetTotalStatValue(STAT_INTELLECT);
    power += player->GetTotalStatValue(STAT_SPIRIT);

    // Item level contribution
    float avgItemLevel = player->GetAverageItemLevel();
    power += static_cast<uint32>(avgItemLevel * 10);

    // Upgrade bonuses (sum of all item upgrade levels)
    for (uint8 i = 0; i < INVENTORY_SLOT_BAG_END; ++i)
    {
        if (Item* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, i))
        {
            power += GetItemUpgradeLevel(item) * 50;
        }
    }

    // Prestige bonus
    power += GetPrestigeLevel(player) * 1000;

    // Stat enhancements
    for (uint8 i = 0; i < 5; ++i)
    {
        power += GetStatEnhancementLevel(player, i) * 10;
    }

    return power;
}

void ProgressiveSystems::UpdatePowerLevel(Player* player)
{
    if (!player)
        return;

    uint32 powerLevel = CalculatePowerLevel(player);
    uint32 guid = player->GetGUID().GetCounter();

    CharacterDatabase.Execute(
        "INSERT INTO character_progression_unified (guid, total_power_level) VALUES ({}, {}) "
        "ON DUPLICATE KEY UPDATE total_power_level = {}",
        guid, powerLevel, powerLevel);
}

// Infinite Dungeon
uint32 ProgressiveSystems::GetCurrentFloor(Player* player)
{
    if (!ValidationHelper::ValidatePlayer(player, "GetCurrentFloor"))
        return 1;

    uint32 guid = player->GetGUID().GetCounter();
    QueryResult result = CharacterDatabase.Query("SELECT current_floor FROM infinite_dungeon_progress WHERE guid = {}", guid);
    
    if (result)
    {
        Field* fields = result->Fetch();
        return fields[0].Get<uint32>();
    }

    return 1;
}

uint32 ProgressiveSystems::GetHighestFloor(Player* player)
{
    if (!ValidationHelper::ValidatePlayer(player, "GetHighestFloor"))
        return 1;

    uint32 guid = player->GetGUID().GetCounter();
    QueryResult result = CharacterDatabase.Query("SELECT highest_floor FROM infinite_dungeon_progress WHERE guid = {}", guid);
    
    if (result)
    {
        Field* fields = result->Fetch();
        return fields[0].Get<uint32>();
    }

    return 1;
}

void ProgressiveSystems::SetCurrentFloor(Player* player, uint32 floor)
{
    if (!ValidationHelper::ValidatePlayer(player, "SetCurrentFloor"))
        return;

    uint32 guid = player->GetGUID().GetCounter();
    CharacterDatabase.Execute(
        "INSERT INTO infinite_dungeon_progress (guid, current_floor) VALUES ({}, {}) "
        "ON DUPLICATE KEY UPDATE current_floor = {}",
        guid, floor, floor);
    LOG_INFO("module", "ProgressiveSystems::SetCurrentFloor - Player {} floor set to {}", guid, floor);
}

void ProgressiveSystems::AdvanceFloor(Player* player)
{
    uint32 current = GetCurrentFloor(player);
    uint32 highest = GetHighestFloor(player);

    SetCurrentFloor(player, current + 1);

    if (current + 1 > highest)
    {
        uint32 guid = player->GetGUID().GetCounter();
        CharacterDatabase.Execute(
            "INSERT INTO infinite_dungeon_progress (guid, highest_floor, current_floor) VALUES ({}, {}, {}) "
            "ON DUPLICATE KEY UPDATE highest_floor = {}, current_floor = {}",
            guid, current + 1, current + 1, current + 1, current + 1);
    }
}

// Seasonal
uint32 ProgressiveSystems::GetCurrentSeason()
{
    // Note: This is a special config that's not in ConfigHelper yet
    // Keeping direct access for now, but could be added to ConfigHelper if needed
    return sConfigMgr->GetOption<uint32>("ProgressiveSystems.Season.CurrentId", 1);
}

void ProgressiveSystems::ResetSeason(uint32 newSeasonId)
{
    // Reset seasonal progress for all players
    CharacterDatabase.Execute("UPDATE seasonal_progress SET seasonal_level = 0, seasonal_points = 0 WHERE season_id < {}", newSeasonId);
    LOG_INFO("module", "ProgressiveSystems::ResetSeason - New season ID: {}", newSeasonId);
}

// Addon data getters
uint32 ProgressiveSystems::GetTotalKills(Player* player)
{
    if (!ValidationHelper::ValidatePlayer(player, "GetTotalKills"))
        return 0;
    
    uint32 guid = player->GetGUID().GetCounter();
    QueryResult result = CharacterDatabase.Query("SELECT total_kills FROM character_progression_unified WHERE guid = {}", guid);
    
    if (result)
    {
        Field* fields = result->Fetch();
        return fields[0].Get<uint32>();
    }
    
    return 0;
}

uint8 ProgressiveSystems::GetCurrentProgressionTier(Player* player)
{
    if (!ValidationHelper::ValidatePlayer(player, "GetCurrentProgressionTier"))
        return 1;
    
    uint32 guid = player->GetGUID().GetCounter();
    QueryResult result = CharacterDatabase.Query("SELECT current_tier FROM character_progression_unified WHERE guid = {}", guid);
    if (result)
    {
        return static_cast<uint8>(result->Fetch()[0].Get<uint32>());
    }
    
    return 1;
}

// Creature Kill Handling
// Note: DifficultyScaling already handles progression points and kill count
// This method is for coordination with other systems
void ProgressiveSystems::OnCreatureKilled(Player* player, Creature* creature)
{
    if (!ValidationHelper::ValidatePlayer(player, "OnCreatureKilled") || !creature)
        return;
    
    // Note: Progression points and kill count are handled by DifficultyScaling::OnPlayerCreatureKill
    // This method exists for coordination with other systems that need to know about kills
    // (e.g., InfiniteDungeonSystem, which is called from PlayerScript)
    
    // Award progression points based on creature type
    uint32 basePoints = sConfigMgr->GetOption<uint32>("ProgressiveSystems.Points.NormalKill", 10);
    
    if (creature->isWorldBoss())
        basePoints = sConfigMgr->GetOption<uint32>("ProgressiveSystems.Points.WorldBossKill", 5000);
    else if (creature->IsDungeonBoss())
        basePoints = sConfigMgr->GetOption<uint32>("ProgressiveSystems.Points.BossKill", 500);
    else if (creature->isElite())
        basePoints = sConfigMgr->GetOption<uint32>("ProgressiveSystems.Points.EliteKill", 50);
    
    // Apply difficulty multiplier
    Map* map = player->GetMap();
    if (map && (map->IsDungeon() || map->IsRaid()))
    {
        uint8 difficultyTier = GetDifficultyTier(player, map);
        if (difficultyTier > 0)
        {
            float diffMultiplier = GetDamageMultiplier(map->GetId(), difficultyTier);
            if (diffMultiplier > 1.0f)
            {
                basePoints = static_cast<uint32>(basePoints * diffMultiplier);
            }
        }
    }
    
    // Apply seasonal bonus
    if (auto* seasonalSystem = SeasonalSystem::instance())
    {
        float bonus = seasonalSystem->GetProgressionBonus(player);
        basePoints = static_cast<uint32>(basePoints * bonus);
    }
    
    AddProgressionPoints(player, basePoints);
    
    // Update total kills
    uint32 guid = player->GetGUID().GetCounter();
    CharacterDatabase.Execute(
        "INSERT INTO character_progression_unified (guid, total_kills) VALUES ({}, 1) "
        "ON DUPLICATE KEY UPDATE total_kills = total_kills + 1",
        guid);
    
    // Update power level
    UpdatePowerLevel(player);
}

// Instance Completion
void ProgressiveSystems::OnInstanceComplete(Player* player, Map* map, uint8 difficultyTier)
{
    if (!player || !map || (!map->IsDungeon() && !map->IsRaid()))
        return;

    uint32 mapId = map->GetId();
    uint32 rewardPoints = GetRewardPoints(mapId, difficultyTier);
    
    // Apply seasonal bonus
    if (auto* seasonalSystem = SeasonalSystem::instance())
    {
        float bonus = seasonalSystem->GetProgressionBonus(player);
        rewardPoints = static_cast<uint32>(rewardPoints * bonus);
    }
    
    if (rewardPoints > 0)
    {
        // Award completion points
        AddProgressionPoints(player, rewardPoints);
        
        // Update completion stats
        uint32 guid = player->GetGUID().GetCounter();
        if (map->IsRaid())
        {
            CharacterDatabase.Execute(
                "INSERT INTO character_progression_unified (guid, total_mythic_plus_completed) VALUES ({}, 1) "
                "ON DUPLICATE KEY UPDATE total_mythic_plus_completed = total_mythic_plus_completed + 1",
                guid);
        }
        else
        {
            // Update dungeon completion for daily challenges
            if (auto* challengeSystem = DailyChallengeSystem::instance())
            {
                challengeSystem->UpdateChallengeProgress(player, 1, mapId, 1); // Type 1 = Dungeons
            }
        }
        
        // Update seasonal score
        if (auto* seasonalSystem = SeasonalSystem::instance())
        {
            seasonalSystem->UpdatePlayerScore(player, rewardPoints);
        }
        
        // Notify player
        if (player->GetSession())
        {
            ChatHandler(player->GetSession()).PSendSysMessage(
                "|cFF00FF00Instance Complete!|r You earned %u progression points!", rewardPoints);
        }
    }
}
