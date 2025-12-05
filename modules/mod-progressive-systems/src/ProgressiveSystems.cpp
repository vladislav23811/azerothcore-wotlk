/*
 * Progressive Systems Module
 * Infinite progression system implementation
 */

#include "ProgressiveSystems.h"
#include "ProgressiveSystemsAddon.h"
#include "ProgressiveSystemsCache.h"
#include "ProgressiveSystemsHelpers.h"
#include "UnifiedStatSystem.h"
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

using namespace ProgressiveSystems;

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
    std::string query = Acore::StringFormat("SELECT difficulty_tier FROM character_progression_unified WHERE guid = {}", guid);
    auto result = DatabaseHelper::SafeQuery(CharacterDatabase, query);
    
    if (result.has_value() && result.value())
    {
        Field* fields = result.value()->Fetch();
        return fields[0].Get<uint8>();
    }

    return DIFFICULTY_NORMAL;
}

uint8 ProgressiveSystems::GetDifficultyTierByInstanceId(uint32 instanceId)
{
    if (instanceId == 0)
        return DIFFICULTY_NORMAL;

    std::string query = Acore::StringFormat("SELECT difficulty_tier FROM instance_difficulty_tracking WHERE instance_id = {}", instanceId);
    auto result = DatabaseHelper::SafeQuery(CharacterDatabase, query);
    
    if (result.has_value() && result.value())
    {
        Field* fields = result.value()->Fetch();
        return fields[0].Get<uint8>();
    }

    return DIFFICULTY_NORMAL;
}

void ProgressiveSystems::SetDifficultyTier(Player* player, Map* map, uint8 tier)
{
    if (!ValidationHelper::ValidatePlayer(player, "SetDifficultyTier") || !map)
        return;
    
    if (!ValidationHelper::ValidateDifficultyTier(tier))
        return;

    // If in an instance, set per-instance difficulty (Mythic+)
    if (map->IsDungeon() || map->IsRaid())
    {
        uint32 instanceId = map->GetInstanceId();
        if (instanceId > 0)
        {
            SetDifficultyTierByInstanceId(instanceId, map->GetId(), player->GetGUID().GetCounter(), tier);
            LogHelper::LogPlayerAction(player, "SetDifficultyTier", Acore::StringFormat("Tier: {}", tier));
            return;
        }
    }

    // Otherwise, set as player's default difficulty tier
    uint32 guid = player->GetGUID().GetCounter();
    std::string query = Acore::StringFormat("INSERT INTO character_progression_unified (guid, difficulty_tier) VALUES ({}, {}) ON DUPLICATE KEY UPDATE difficulty_tier = {}", guid, tier, tier);
    bool success = DatabaseHelper::SafeExecute(CharacterDatabase, query);
    LogHelper::LogDBOperation("SetDifficultyTier", success, Acore::StringFormat("Player: {}, Tier: {}", guid, tier));
}

void ProgressiveSystems::SetDifficultyTierByInstanceId(uint32 instanceId, uint32 mapId, uint32 playerGuid, uint8 tier)
{
    if (instanceId == 0 || !ValidationHelper::ValidateDifficultyTier(tier))
        return;

    std::string query = Acore::StringFormat(
        "INSERT INTO instance_difficulty_tracking (instance_id, map_id, difficulty_tier, set_by_guid) "
        "VALUES ({}, {}, {}, {}) "
        "ON DUPLICATE KEY UPDATE difficulty_tier = {}, set_by_guid = {}, set_time = CURRENT_TIMESTAMP",
        instanceId, mapId, tier, playerGuid, tier, playerGuid);
    
    bool success = DatabaseHelper::SafeExecute(CharacterDatabase, query);
    LogHelper::LogDBOperation("SetDifficultyTierByInstanceId", success, Acore::StringFormat("Instance: {}, Tier: {}", instanceId, tier));
}

float ProgressiveSystems::GetHealthMultiplier(uint32 mapId, uint8 difficultyTier)
{
    if (difficultyTier == 0)
        return 1.0f;

    std::string query = Acore::StringFormat("SELECT health_multiplier FROM custom_difficulty_scaling WHERE map_id = {} AND difficulty_tier = {}", mapId, difficultyTier);
    auto result = DatabaseHelper::SafeQuery(WorldDatabase, query);
    
    if (result.has_value() && result.value())
    {
        Field* fields = result.value()->Fetch();
        return fields[0].Get<float>();
    }

    // Default scaling: exponential growth
    return 1.0f + (difficultyTier * 0.15f);
}

float ProgressiveSystems::GetDamageMultiplier(uint32 mapId, uint8 difficultyTier)
{
    if (difficultyTier == 0)
        return 1.0f;

    std::string query = Acore::StringFormat("SELECT damage_multiplier FROM custom_difficulty_scaling WHERE map_id = {} AND difficulty_tier = {}", mapId, difficultyTier);
    auto result = DatabaseHelper::SafeQuery(WorldDatabase, query);
    
    if (result.has_value() && result.value())
    {
        Field* fields = result.value()->Fetch();
        return fields[0].Get<float>();
    }

    // Default scaling
    return 1.0f + (difficultyTier * 0.12f);
}

uint32 ProgressiveSystems::GetRequiredItemLevel(uint32 mapId, uint8 difficultyTier)
{
    std::string query = Acore::StringFormat("SELECT required_item_level FROM custom_difficulty_scaling WHERE map_id = {} AND difficulty_tier = {}", mapId, difficultyTier);
    auto result = DatabaseHelper::SafeQuery(WorldDatabase, query);
    
    if (result.has_value() && result.value())
    {
        Field* fields = result.value()->Fetch();
        return fields[0].Get<uint32>();
    }

    return 0;
}

uint32 ProgressiveSystems::GetRewardPoints(uint32 mapId, uint8 difficultyTier)
{
    std::string query = Acore::StringFormat("SELECT reward_points FROM custom_difficulty_scaling WHERE map_id = {} AND difficulty_tier = {}", mapId, difficultyTier);
    auto result = DatabaseHelper::SafeQuery(WorldDatabase, query);
    
    if (result.has_value() && result.value())
    {
        Field* fields = result.value()->Fetch();
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
    std::string tierQuery = Acore::StringFormat("SELECT current_tier FROM character_progression_unified WHERE guid = {}", guid);
    auto tierResult = DatabaseHelper::SafeQuery(CharacterDatabase, tierQuery);
    uint8 tier = 1;
    if (tierResult.has_value() && tierResult.value())
    {
        tier = tierResult.value()->Fetch()[0].Get<uint8>();
    }
    
    // Apply tier multiplier (5x, 15x, 30x, etc.)
    float multiplier = 1.0f;
    if (tier == 1) multiplier = 5.0f;
    else if (tier == 2) multiplier = 15.0f;
    else if (tier == 3) multiplier = 30.0f;
    else if (tier == 4) multiplier = 50.0f;
    else if (tier >= 5) multiplier = 75.0f + ((tier - 5) * 30.0f);
    
    uint32 finalPoints = static_cast<uint32>(points * multiplier);
    
    // Use DatabaseHelper for atomic operation
    if (DatabaseHelper::AddProgressionPoints(guid, finalPoints))
    {
        // Also update characters.reward_points (legacy support)
        std::string rewardQuery = Acore::StringFormat("UPDATE characters SET reward_points = COALESCE(reward_points, 0) + {} WHERE guid = {}", finalPoints, guid);
        DatabaseHelper::SafeExecute(CharacterDatabase, rewardQuery);

        // Invalidate cache
        sProgressiveSystemsCache->InvalidateCache(guid);

        // Update power level
        UpdatePowerLevel(player);

        // Log action
        LogHelper::LogPlayerAction(player, "AddProgressionPoints", Acore::StringFormat("Points: {} (multiplier: {:.1f}x)", finalPoints, multiplier));

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
        std::string killQuery = Acore::StringFormat("SELECT total_kills FROM character_progression_unified WHERE guid = {}", guid);
        auto killResult = DatabaseHelper::SafeQuery(CharacterDatabase, killQuery);
        if (killResult.has_value() && killResult.value())
        {
            uint32 totalKills = killResult.value()->Fetch()[0].Get<uint32>();
            sProgressiveSystemsAddon->SendKillUpdate(player, totalKills);
        }
    }
    else
    {
        LogHelper::LogError("ProgressiveSystems", Acore::StringFormat("Failed to add progression points for player {} ({})", player->GetName(), guid));
    }
}

bool ProgressiveSystems::SpendProgressionPoints(Player* player, uint32 points)
{
    if (!ValidationHelper::ValidatePlayer(player, "SpendProgressionPoints") || points == 0)
        return false;

    uint32 guid = player->GetGUID().GetCounter();
    
    // Use DatabaseHelper for atomic spend operation
    if (DatabaseHelper::SpendProgressionPoints(guid, points))
    {
        // Also update characters.reward_points (legacy support)
        std::string rewardQuery = Acore::StringFormat("UPDATE characters SET reward_points = GREATEST(COALESCE(reward_points, 0) - {}, 0) WHERE guid = {}", points, guid);
        DatabaseHelper::SafeExecute(CharacterDatabase, rewardQuery);

        // Invalidate cache
        sProgressiveSystemsCache->InvalidateCache(guid);

        // Log action
        LogHelper::LogPlayerAction(player, "SpendProgressionPoints", Acore::StringFormat("Points: {}", points));

        // Send addon update
        sProgressiveSystemsAddon->SendPointsUpdate(player, GetProgressionPoints(player));

        return true;
    }
    else
    {
        LogHelper::LogWarning("ProgressiveSystems", Acore::StringFormat("Failed to spend progression points for player {} ({}): Insufficient points or DB error", player->GetName(), guid));
        return false;
    }
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
    
    // Query database using helper
    uint64 points = 0;
    uint32 tier = 0, prestige = 0;
    if (DatabaseHelper::GetPlayerProgression(guid, points, tier, prestige))
    {
        // Update cache
        cachedData.progressionPoints = points;
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
    std::string query = Acore::StringFormat("SELECT progression_points FROM character_progression_unified WHERE guid = {}", guid);
    auto result = DatabaseHelper::SafeQuery(CharacterDatabase, query);
    if (result.has_value() && result.value())
    {
        // Data is already in database, this is just a refresh call
        return;
    }
    
    // Initialize if doesn't exist
    std::string initQuery = Acore::StringFormat("INSERT INTO character_progression_unified (guid, progression_points) VALUES ({}, 0)", guid);
    bool success = DatabaseHelper::SafeExecute(CharacterDatabase, initQuery);
    LogHelper::LogDBOperation("UpdateProgressionPoints", success, Acore::StringFormat("Initialized progression for player {}", guid));
}

// Item Upgrades
uint32 ProgressiveSystems::GetItemUpgradeLevel(Item* item)
{
    if (!ValidationHelper::ValidateItem(item, "GetItemUpgradeLevel"))
        return 0;

    uint64 itemGuid = item->GetGUID().GetCounter();
    std::string query = Acore::StringFormat("SELECT upgrade_level FROM item_upgrades WHERE item_guid = {}", itemGuid);
    auto result = DatabaseHelper::SafeQuery(CharacterDatabase, query);
    
    if (result.has_value() && result.value())
    {
        Field* fields = result.value()->Fetch();
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
        
        // Update power level
        UpdatePowerLevel(player);
        
        // Send addon update
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
    uint64 points = 0;
    uint32 tier = 0, prestige = 0;
    if (DatabaseHelper::GetPlayerProgression(guid, points, tier, prestige))
    {
        return prestige;
    }

    return 0;
}

bool ProgressiveSystems::PrestigeCharacter(Player* player)
{
    if (!ValidationHelper::ValidatePlayer(player, "PrestigeCharacter"))
        return false;

    // Check requirements (e.g., level 80, certain progression points)
    uint32 minLevel = ConfigHelper::GetPrestigeMinLevel();
    if (player->GetLevel() < minLevel)
    {
        LogHelper::LogWarning("ProgressiveSystems", Acore::StringFormat("Player {} attempted prestige at level {} (min: {})", player->GetName(), player->GetLevel(), minLevel));
        return false;
    }

    uint32 guid = player->GetGUID().GetCounter();
    uint64 points = 0;
    uint32 tier = 0, currentPrestige = 0;
    if (!DatabaseHelper::GetPlayerProgression(guid, points, tier, currentPrestige))
    {
        LogHelper::LogError("ProgressiveSystems", Acore::StringFormat("Failed to get progression data for prestige: {}", guid));
        return false;
    }

    if (currentPrestige >= MAX_PRESTIGE_LEVEL)
    {
        LogHelper::LogWarning("ProgressiveSystems", Acore::StringFormat("Player {} already at max prestige level", player->GetName()));
        return false;
    }

    uint32 newPrestige = currentPrestige + 1;
    
    // Update prestige
    std::string query = Acore::StringFormat(
        "INSERT INTO character_progression_unified (guid, prestige_level) VALUES ({}, {}) "
        "ON DUPLICATE KEY UPDATE prestige_level = {}",
        guid, newPrestige, newPrestige);
    
    bool success = DatabaseHelper::SafeExecute(CharacterDatabase, query);
    if (success)
    {
        LogHelper::LogPlayerAction(player, "PrestigeCharacter", Acore::StringFormat("New Prestige: {}", newPrestige));
        if (player->GetSession())
        {
            ChatHandler(player->GetSession()).PSendSysMessage("Congratulations! You reached Prestige Level %u!", newPrestige);
        }
        return true;
    }
    else
    {
        LogHelper::LogError("ProgressiveSystems", Acore::StringFormat("Failed to update prestige for player {}", guid));
        return false;
    }
}

float ProgressiveSystems::GetPrestigeStatBonus(Player* player)
{
    uint32 prestige = GetPrestigeLevel(player);
    float bonusPerLevel = ConfigHelper::GetPrestigeStatBonusPerLevel();
    return 1.0f + (prestige * bonusPerLevel);
}

float ProgressiveSystems::GetPrestigeLootBonus(Player* player)
{
    uint32 prestige = GetPrestigeLevel(player);
    float bonusPerLevel = ConfigHelper::GetPrestigeLootBonusPerLevel();
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
    std::string query = Acore::StringFormat("SELECT current_floor FROM infinite_dungeon_progress WHERE guid = {}", guid);
    auto result = DatabaseHelper::SafeQuery(CharacterDatabase, query);
    
    if (result.has_value() && result.value())
    {
        Field* fields = result.value()->Fetch();
        return fields[0].Get<uint32>();
    }

    return 1;
}

uint32 ProgressiveSystems::GetHighestFloor(Player* player)
{
    if (!ValidationHelper::ValidatePlayer(player, "GetHighestFloor"))
        return 1;

    uint32 guid = player->GetGUID().GetCounter();
    std::string query = Acore::StringFormat("SELECT highest_floor FROM infinite_dungeon_progress WHERE guid = {}", guid);
    auto result = DatabaseHelper::SafeQuery(CharacterDatabase, query);
    
    if (result.has_value() && result.value())
    {
        Field* fields = result.value()->Fetch();
        return fields[0].Get<uint32>();
    }

    return 1;
}

void ProgressiveSystems::SetCurrentFloor(Player* player, uint32 floor)
{
    if (!ValidationHelper::ValidatePlayer(player, "SetCurrentFloor"))
        return;

    uint32 guid = player->GetGUID().GetCounter();
    std::string query = Acore::StringFormat(
        "INSERT INTO infinite_dungeon_progress (guid, current_floor) VALUES ({}, {}) "
        "ON DUPLICATE KEY UPDATE current_floor = {}",
        guid, floor, floor);
    
    bool success = DatabaseHelper::SafeExecute(CharacterDatabase, query);
    LogHelper::LogDBOperation("SetCurrentFloor", success, Acore::StringFormat("Player: {}, Floor: {}", guid, floor));
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
    std::string query = Acore::StringFormat("UPDATE seasonal_progress SET seasonal_level = 0, seasonal_points = 0 WHERE season_id < {}", newSeasonId);
    bool success = DatabaseHelper::SafeExecute(CharacterDatabase, query);
    LogHelper::LogDBOperation("ResetSeason", success, Acore::StringFormat("New Season ID: {}", newSeasonId));
}

// Addon data getters
uint32 ProgressiveSystems::GetTotalKills(Player* player)
{
    if (!ValidationHelper::ValidatePlayer(player, "GetTotalKills"))
        return 0;
    
    uint32 guid = player->GetGUID().GetCounter();
    std::string query = Acore::StringFormat("SELECT total_kills FROM character_progression_unified WHERE guid = {}", guid);
    auto result = DatabaseHelper::SafeQuery(CharacterDatabase, query);
    
    if (result.has_value() && result.value())
    {
        Field* fields = result.value()->Fetch();
        return fields[0].Get<uint32>();
    }
    
    return 0;
}

uint8 ProgressiveSystems::GetCurrentProgressionTier(Player* player)
{
    if (!ValidationHelper::ValidatePlayer(player, "GetCurrentProgressionTier"))
        return 1;
    
    uint32 guid = player->GetGUID().GetCounter();
    uint64 points = 0;
    uint32 tier = 0, prestige = 0;
    if (DatabaseHelper::GetPlayerProgression(guid, points, tier, prestige))
    {
        return static_cast<uint8>(tier);
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
    uint32 basePoints = ConfigHelper::GetNormalKillPoints();
    
    if (creature->isWorldBoss())
        basePoints = ConfigHelper::GetWorldBossKillPoints();
    else if (creature->IsDungeonBoss())
        basePoints = ConfigHelper::GetBossKillPoints();
    else if (creature->isElite())
        basePoints = ConfigHelper::GetEliteKillPoints();
    
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
    
    AddProgressionPoints(player, basePoints);
    
    // Update total kills
    uint32 guid = player->GetGUID().GetCounter();
    std::string killQuery = Acore::StringFormat(
        "INSERT INTO character_progression_unified (guid, total_kills) VALUES ({}, 1) "
        "ON DUPLICATE KEY UPDATE total_kills = total_kills + 1",
        guid);
    DatabaseHelper::SafeExecute(CharacterDatabase, killQuery);
    
    // Update power level
    UpdatePowerLevel(player);
}

// Instance Completion
void ProgressiveSystems::OnInstanceComplete(Player* player, Map* map, uint8 difficultyTier)
{
    if (!player || !map || !map->IsDungeon() && !map->IsRaid())
        return;

    uint32 mapId = map->GetId();
    uint32 rewardPoints = GetRewardPoints(mapId, difficultyTier);
    
    if (rewardPoints > 0)
    {
        // Award completion points
        AddProgressionPoints(player, rewardPoints);
        
        // Update completion stats
        uint32 guid = player->GetGUID().GetCounter();
        if (map->IsRaid())
        {
            CharacterDatabase.Execute(
                "INSERT INTO character_progression (guid, total_mythic_plus_completed) VALUES ({}, 1) "
                "ON DUPLICATE KEY UPDATE total_mythic_plus_completed = total_mythic_plus_completed + 1",
                guid);
        }
        
        // Notify player
        ChatHandler(player->GetSession()).PSendSysMessage(
            "|cFF00FF00Instance Complete!|r You earned %u progression points!", rewardPoints);
    }
}
