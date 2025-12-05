/*
 * Infinite Dungeon Instance Manager
 * Manages private instances for infinite dungeon system
 */

#ifndef INFINITE_DUNGEON_INSTANCE_MANAGER_H
#define INFINITE_DUNGEON_INSTANCE_MANAGER_H

#include "Define.h"
#include "Player.h"
#include "Map.h"
#include "InstanceSaveMgr.h"
#include "MapMgr.h"
#include "DatabaseEnv.h"
#include "Log.h"
#include <unordered_map>
#include <unordered_set>
#include <memory>
#include <vector>
#include <string>
#include <utility>

struct InfiniteDungeonInstance
{
    uint32 instanceId;
    uint32 mapId;
    uint32 playerGuid;      // Group leader's GUID for group instances
    uint32 currentFloor;
    uint32 currentWave;
    uint64 createdTime;
    Map* map;
    std::unordered_set<uint32> groupMemberGuids; // For group support
    
    InfiniteDungeonInstance() : instanceId(0), mapId(0), playerGuid(0), 
        currentFloor(1), currentWave(0), createdTime(0), map(nullptr) {}
};

class InfiniteDungeonInstanceManager
{
public:
    static InfiniteDungeonInstanceManager* instance()
    {
        static InfiniteDungeonInstanceManager instance;
        return &instance;
    }
    
    void Initialize();
    
    // Create a private instance for a player (or group)
    InfiniteDungeonInstance* CreatePrivateInstance(Player* player, uint32 mapId, uint32 floor);
    
    // Get player's active instance (checks group membership)
    InfiniteDungeonInstance* GetPlayerInstance(Player* player);
    
    // Get instance by group leader GUID
    InfiniteDungeonInstance* GetInstanceByLeader(uint32 leaderGuid);
    
    // Teleport player to their private instance
    bool TeleportPlayerToInstance(Player* player);
    
    // End/cleanup instance
    void EndInstance(uint32 leaderGuid);
    
    // Update instance (called periodically)
    void Update(uint32 diff);
    
    // Get spawn position for instance (safe location based on mapId)
    Position GetSpawnPosition(uint32 mapId) const;
    
    // Get available instances (returns map_id -> name pairs)
    std::vector<std::pair<uint32, std::string>> GetAvailableInstances() const;
    
private:
    InfiniteDungeonInstanceManager() = default;
    ~InfiniteDungeonInstanceManager() = default;
    InfiniteDungeonInstanceManager(const InfiniteDungeonInstanceManager&) = delete;
    InfiniteDungeonInstanceManager& operator=(const InfiniteDungeonInstanceManager&) = delete;
    
    // Map ID for infinite dungeon (using Deadmines as base - map 36)
    static constexpr uint32 INFINITE_DUNGEON_MAP_ID = 36;
    
    // Instance storage: leaderGuid -> instance
    std::unordered_map<uint32, InfiniteDungeonInstance> m_instances;
    
    // Instance cleanup timer
    uint32 m_cleanupTimer;
    
    // Cleanup old instances (called periodically)
    void CleanupOldInstances();
    
    // Bind player (and group members) to instance
    bool BindPlayerToInstance(Player* player, uint32 instanceId, uint32 mapId);
    
    // Get entrance position for a map (from instance_template or hardcoded)
    bool GetMapEntrancePosition(uint32 mapId, Position& pos) const;
};

#define sInfiniteDungeonInstanceManager InfiniteDungeonInstanceManager::instance()

#endif // INFINITE_DUNGEON_INSTANCE_MANAGER_H

