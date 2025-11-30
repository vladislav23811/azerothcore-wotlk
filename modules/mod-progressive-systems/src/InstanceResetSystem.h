/*
 * Instance Reset System
 * Allows players to reset instances and track completion counts
 */

#ifndef INSTANCE_RESET_SYSTEM_H
#define INSTANCE_RESET_SYSTEM_H

#include "Define.h"
#include "Player.h"
#include "Map.h"
#include <map>
#include <string>
#include <vector>

struct InstanceCompletionData
{
    uint32 mapId;
    uint32 completionCount;
    uint32 lastCompletionTime;
    uint32 bestTime; // Best completion time in seconds
    uint8 highestDifficultyTier;
    uint32 totalKills;
    uint32 totalDeaths;
};

struct InstanceResetInfo
{
    uint32 mapId;
    std::string mapName;
    uint32 instanceId;
    bool canReset;
    bool isRaid;
    uint32 completionCount;
    time_t lastResetTime;
    time_t nextResetTime;
};

class AC_GAME_API InstanceResetSystem
{
public:
    static InstanceResetSystem* instance();
    
    void Initialize();
    void Shutdown();
    
    // Reset instance for player
    bool ResetInstance(Player* player, uint32 mapId, bool force = false);
    bool ResetAllInstances(Player* player, bool raidsOnly = false);
    
    // Track instance completion
    void OnInstanceComplete(Player* player, Map* map, uint8 difficultyTier);
    
    // Get completion data
    InstanceCompletionData GetCompletionData(Player* player, uint32 mapId);
    std::vector<InstanceCompletionData> GetAllCompletions(Player* player);
    
    // Get reset info for player
    std::vector<InstanceResetInfo> GetResetInfo(Player* player);
    InstanceResetInfo GetInstanceResetInfo(Player* player, uint32 mapId);
    
    // Check if instance can be reset
    bool CanResetInstance(Player* player, uint32 mapId);
    
    // Get completion count
    uint32 GetCompletionCount(Player* player, uint32 mapId);
    
    // Configuration
    struct ResetConfig
    {
        bool unlimitedResets = true;        // Allow unlimited resets
        uint32 maxResetsPerDay = 0;         // 0 = unlimited
        bool requireProgressionPoints = false; // Require points to reset
        uint32 resetCostPoints = 0;         // Cost in progression points
        bool allowRaidResets = true;        // Allow raid resets
        bool allowDungeonResets = true;     // Allow dungeon resets
        uint32 cooldownSeconds = 0;         // Cooldown between resets (0 = no cooldown)
    };
    
    void SetConfig(const ResetConfig& config) { m_config = config; }
    const ResetConfig& GetConfig() const { return m_config; }
    
private:
    InstanceResetSystem() = default;
    ~InstanceResetSystem() = default;
    InstanceResetSystem(InstanceResetSystem const&) = delete;
    InstanceResetSystem& operator=(InstanceResetSystem const&) = delete;
    
    // Load completion data from database
    void LoadCompletionData(Player* player);
    
    // Save completion data to database
    void SaveCompletionData(Player* player, uint32 mapId, const InstanceCompletionData& data);
    
    // Track reset usage
    void TrackResetUsage(Player* player, uint32 mapId);
    bool CanPlayerReset(Player* player, uint32 mapId);
    
    ResetConfig m_config;
    
    // Cache for completion data (playerGuid -> mapId -> data)
    std::map<uint32, std::map<uint32, InstanceCompletionData>> m_completionCache;
};

#define sInstanceResetSystem InstanceResetSystem::instance()

#endif // INSTANCE_RESET_SYSTEM_H

