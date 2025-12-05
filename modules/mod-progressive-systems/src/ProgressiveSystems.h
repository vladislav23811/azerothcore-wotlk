/*
 * Progressive Systems Module
 * Infinite progression system for AzerothCore
 */

#ifndef PROGRESSIVE_SYSTEMS_H
#define PROGRESSIVE_SYSTEMS_H

#include "Define.h"
#include "ScriptMgr.h"
#include "Player.h"
#include "Item.h"
#include "Map.h"
#include "Creature.h"

// Difficulty tier constants
#define DIFFICULTY_NORMAL 0
#define DIFFICULTY_HEROIC 1
#define DIFFICULTY_MYTHIC_PLUS_START 2
#define MAX_DIFFICULTY_TIER 1000

// Upgrade constants
#define MAX_ITEM_UPGRADE_LEVEL 1000
#define UPGRADE_STAT_BONUS_PER_LEVEL 0.05f  // 5% per level
#define BASE_UPGRADE_COST 100
#define UPGRADE_COST_MULTIPLIER 1.15f  // 15% increase per level

// Prestige constants
#define MAX_PRESTIGE_LEVEL 1000
#define PRESTIGE_STAT_BONUS_PER_LEVEL 0.01f  // 1% per level
#define PRESTIGE_LOOT_BONUS_PER_LEVEL 0.005f  // 0.5% per level

// Progression point sources
#define PROGRESSION_POINTS_BOSS_KILL 100
#define PROGRESSION_POINTS_DUNGEON_COMPLETE 500
#define PROGRESSION_POINTS_RAID_COMPLETE 2000

class AC_GAME_API ProgressiveSystems
{
public:
    static ProgressiveSystems* instance();

    // Difficulty Scaling
    uint8 GetDifficultyTier(Player* player, Map* map);
    uint8 GetDifficultyTierByInstanceId(uint32 instanceId);
    void SetDifficultyTier(Player* player, Map* map, uint8 tier);
    void SetDifficultyTierByInstanceId(uint32 instanceId, uint32 mapId, uint32 playerGuid, uint8 tier);
    float GetHealthMultiplier(uint32 mapId, uint8 difficultyTier);
    float GetDamageMultiplier(uint32 mapId, uint8 difficultyTier);
    uint32 GetRequiredItemLevel(uint32 mapId, uint8 difficultyTier);
    uint32 GetRewardPoints(uint32 mapId, uint8 difficultyTier);
    
    // Instance Completion
    void OnInstanceComplete(Player* player, Map* map, uint8 difficultyTier);

    // Progression Points
    void AddProgressionPoints(Player* player, uint32 points);
    bool SpendProgressionPoints(Player* player, uint32 points);
    uint64 GetProgressionPoints(Player* player);
    void UpdateProgressionPoints(Player* player);

    // Item Upgrades
    uint32 GetItemUpgradeLevel(Item* item);
    bool UpgradeItem(Player* player, Item* item);
    float GetItemStatBonus(Item* item);
    uint32 GetUpgradeCost(uint32 currentLevel);

    // Prestige System
    uint32 GetPrestigeLevel(Player* player);
    bool PrestigeCharacter(Player* player);
    float GetPrestigeStatBonus(Player* player);
    float GetPrestigeLootBonus(Player* player);

    // Stat Enhancements
    uint32 GetStatEnhancementLevel(Player* player, uint8 statType);
    bool EnhanceStat(Player* player, uint8 statType, uint32 levels);
    uint32 GetStatEnhancementCost(uint32 currentLevel);

    // Power Level
    uint32 CalculatePowerLevel(Player* player);
    void UpdatePowerLevel(Player* player);

    // Infinite Dungeon
    uint32 GetCurrentFloor(Player* player);
    uint32 GetHighestFloor(Player* player);
    void SetCurrentFloor(Player* player, uint32 floor);
    void AdvanceFloor(Player* player);

    // Seasonal
    uint32 GetCurrentSeason();
    void ResetSeason(uint32 newSeasonId);
    
    // Creature kill handling
    void OnCreatureKilled(Player* player, Creature* creature);
    
    // Addon data getters
    uint32 GetTotalKills(Player* player);
    uint8 GetCurrentProgressionTier(Player* player);

private:
    ProgressiveSystems() = default;
    ~ProgressiveSystems() = default;
    ProgressiveSystems(ProgressiveSystems const&) = delete;
    ProgressiveSystems& operator=(ProgressiveSystems const&) = delete;
};

#define sProgressiveSystems ProgressiveSystems::instance()

#endif

