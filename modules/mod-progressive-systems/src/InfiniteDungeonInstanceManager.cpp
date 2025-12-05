/*
 * Infinite Dungeon Instance Manager
 * Manages private instances for infinite dungeon system
 */

#include "InfiniteDungeonInstanceManager.h"
#include "MapMgr.h"
#include "MapInstanced.h"
#include "Map.h"
#include "ObjectMgr.h"
#include "World.h"
#include "Chat.h"
#include "StringFormat.h"
#include "Timer.h"
#include "GameTime.h"
#include "Group.h"
#include "ObjectAccessor.h"
#include "DatabaseEnv.h"
#include "DBCStores.h"

void InfiniteDungeonInstanceManager::Initialize()
{
    m_cleanupTimer = 0;
    LOG_INFO("module", "InfiniteDungeonInstanceManager initialized");
}

bool InfiniteDungeonInstanceManager::GetMapEntrancePosition(uint32 mapId, Position& pos) const
{
    // Try to get entrance from instance_template
    QueryResult result = WorldDatabase.Query(
        "SELECT entrance_x, entrance_y, entrance_z FROM instance_template WHERE map = {}", mapId);
    
    if (result)
    {
        Field* fields = result->Fetch();
        pos.Relocate(fields[0].Get<float>(), fields[1].Get<float>(), 
                    fields[2].Get<float>(), 0.0f);
        return true;
    }
    
    // Fallback: Hardcoded positions for common instances
    switch (mapId)
    {
        case 36: // Deadmines
            pos.Relocate(-11208.1f, 1686.29f, 24.6361f, 1.55334f);
            return true;
        case 33: // Shadowfang Keep
            pos.Relocate(-234.495f, 1561.63f, 76.8921f, 1.24031f);
            return true;
        case 34: // Stormwind Stockades
            pos.Relocate(-8766.11f, 846.175f, 87.4842f, 3.77931f);
            return true;
        case 43: // Wailing Caverns
            pos.Relocate(-722.53f, -2226.30f, 16.94f, 2.71f);
            return true;
        case 47: // Razorfen Kraul
            pos.Relocate(-4470.28f, -1677.77f, 81.39f, 1.16302f);
            return true;
        case 48: // Blackfathom Deeps
            pos.Relocate(4249.99f, 740.102f, -25.671f, 1.34062f);
            return true;
        default:
            // Use map entry entrance if available
            if (MapEntry const* entry = sMapStore.LookupEntry(mapId))
            {
                if (entry->entrance_map >= 0)
                {
                    // MapEntry doesn't have entrance_z, use a default height
                    pos.Relocate(entry->entrance_x, entry->entrance_y, 
                                entry->entrance_map == mapId ? 0.0f : 500.0f, 0.0f);
                    return true;
                }
            }
            return false;
    }
}

Position InfiniteDungeonInstanceManager::GetSpawnPosition(uint32 mapId) const
{
    Position pos;
    if (!GetMapEntrancePosition(mapId, pos))
    {
        // Default fallback
        pos.Relocate(-11208.1f, 1686.29f, 24.6361f, 1.55334f);
    }
    return pos;
}

std::vector<std::pair<uint32, std::string>> InfiniteDungeonInstanceManager::GetAvailableInstances() const
{
    std::vector<std::pair<uint32, std::string>> instances;
    
    // Query from dungeon_access_template for available instances
    QueryResult result = WorldDatabase.Query(
        "SELECT DISTINCT map_id, comment FROM dungeon_access_template WHERE difficulty = 0 ORDER BY map_id");
    
    if (result)
    {
        do
        {
            Field* fields = result->Fetch();
            uint32 mapId = fields[0].Get<uint32>();
            std::string name = fields[1].Get<std::string>();
            
            // Verify map is instanceable
            MapEntry const* entry = sMapStore.LookupEntry(mapId);
            if (entry && entry->Instanceable())
            {
                instances.push_back({mapId, name});
            }
        } while (result->NextRow());
    }
    
    // Add some hardcoded common instances if DB doesn't have them
    if (instances.empty())
    {
        instances.push_back({36, "Deadmines"});
        instances.push_back({33, "Shadowfang Keep"});
        instances.push_back({34, "Stormwind Stockades"});
        instances.push_back({43, "Wailing Caverns"});
        instances.push_back({47, "Razorfen Kraul"});
        instances.push_back({48, "Blackfathom Deeps"});
    }
    
    return instances;
}

InfiniteDungeonInstance* InfiniteDungeonInstanceManager::CreatePrivateInstance(Player* player, uint32 mapId, uint32 floor)
{
    if (!player)
        return nullptr;
    
    // Determine group leader (player if solo, group leader if in group)
    Player* leader = player;
    Group* group = player->GetGroup();
    if (group && !group->isBGGroup() && !group->isBFGroup())
    {
        leader = ObjectAccessor::FindConnectedPlayer(group->GetLeaderGUID());
        if (!leader)
            leader = player; // Fallback if leader offline
    }
    
    uint32 leaderGuid = leader->GetGUID().GetCounter();
    
    // Check if leader already has an instance
    auto itr = m_instances.find(leaderGuid);
    if (itr != m_instances.end())
    {
        LOG_WARN("module", "InfiniteDungeonInstanceManager: Leader {} already has an active instance", leaderGuid);
        return &itr->second;
    }
    
    // Verify map is instanceable
    MapEntry const* entry = sMapStore.LookupEntry(mapId);
    if (!entry || !entry->Instanceable())
    {
        LOG_ERROR("module", "InfiniteDungeonInstanceManager: Map {} is not instanceable", mapId);
        return nullptr;
    }
    
    // Generate new instance ID
    uint32 instanceId = sMapMgr->GenerateInstanceId();
    if (!instanceId)
    {
        LOG_ERROR("module", "InfiniteDungeonInstanceManager: Failed to generate instance ID");
        return nullptr;
    }
    
    // Get or create base map
    Map* baseMap = sMapMgr->CreateBaseMap(mapId);
    if (!baseMap)
    {
        LOG_ERROR("module", "InfiniteDungeonInstanceManager: Failed to create base map {}", mapId);
        return nullptr;
    }
    
    MapInstanced* mapInstanced = static_cast<MapInstanced*>(baseMap);
    
    // Use CreateInstanceForPlayer to create the instance - this handles everything
    Map* instanceMap = mapInstanced->CreateInstanceForPlayer(mapId, leader);
    
    if (!instanceMap)
    {
        LOG_ERROR("module", "InfiniteDungeonInstanceManager: Failed to create instance for map {}", mapId);
        return nullptr;
    }
    
    // Get the instance ID and difficulty from the created map
    InstanceMap* instMap = instanceMap->ToInstanceMap();
    if (!instMap)
    {
        LOG_ERROR("module", "InfiniteDungeonInstanceManager: Created map is not an instance map for map {}", mapId);
        return nullptr;
    }
    
    uint32 actualInstanceId = instMap->GetInstanceId();
    Difficulty diff = instMap->GetDifficulty();
    
    // Instance save is created automatically by CreateInstanceForPlayer, but we can retrieve it
    InstanceSave* save = sInstanceSaveMgr->GetInstanceSave(actualInstanceId);
    
    // Bind leader and all group members to instance
    if (!BindPlayerToInstance(leader, actualInstanceId, mapId))
    {
        LOG_ERROR("module", "InfiniteDungeonInstanceManager: Failed to bind leader to instance");
        return nullptr;
    }
    
    // Create instance data
    InfiniteDungeonInstance instance;
    instance.instanceId = actualInstanceId;
    instance.mapId = mapId;
    instance.playerGuid = leaderGuid;
    instance.currentFloor = floor;
    instance.currentWave = 0;
    instance.createdTime = GameTime::GetGameTime().count();
    instance.map = instMap;
    instance.groupMemberGuids.insert(leaderGuid);
    
    // Add group members
    if (group && !group->isBGGroup() && !group->isBFGroup())
    {
        for (GroupReference* itr = group->GetFirstMember(); itr != nullptr; itr = itr->next())
        {
            if (Player* member = itr->GetSource())
            {
                if (member != leader)
                {
                    BindPlayerToInstance(member, actualInstanceId, mapId);
                    instance.groupMemberGuids.insert(member->GetGUID().GetCounter());
                }
            }
        }
    }
    
    m_instances[leaderGuid] = instance;
    
    LOG_INFO("module", "InfiniteDungeonInstanceManager: Created private instance {} for leader {} (map {}, floor {})", 
        instanceId, leaderGuid, mapId, floor);
    
    return &m_instances[leaderGuid];
}

InfiniteDungeonInstance* InfiniteDungeonInstanceManager::GetPlayerInstance(Player* player)
{
    if (!player)
        return nullptr;
    
    // Check by player's GUID first
    uint32 playerGuid = player->GetGUID().GetCounter();
    auto itr = m_instances.find(playerGuid);
    if (itr != m_instances.end())
        return &itr->second;
    
    // Check if player is in a group and group leader has instance
    Group* group = player->GetGroup();
    if (group && !group->isBGGroup() && !group->isBFGroup())
    {
        Player* leader = ObjectAccessor::FindConnectedPlayer(group->GetLeaderGUID());
        if (leader)
        {
            uint32 leaderGuid = leader->GetGUID().GetCounter();
            auto leaderItr = m_instances.find(leaderGuid);
            if (leaderItr != m_instances.end())
            {
                // Verify player is in the group member list
                if (leaderItr->second.groupMemberGuids.find(playerGuid) != leaderItr->second.groupMemberGuids.end())
                {
                    return &leaderItr->second;
                }
            }
        }
    }
    
    return nullptr;
}

InfiniteDungeonInstance* InfiniteDungeonInstanceManager::GetInstanceByLeader(uint32 leaderGuid)
{
    auto itr = m_instances.find(leaderGuid);
    return (itr != m_instances.end()) ? &itr->second : nullptr;
}

bool InfiniteDungeonInstanceManager::BindPlayerToInstance(Player* player, uint32 instanceId, uint32 mapId)
{
    if (!player)
        return false;
    
    // Get instance save
    InstanceSave* save = sInstanceSaveMgr->GetInstanceSave(instanceId);
    if (!save)
    {
        LOG_ERROR("module", "InfiniteDungeonInstanceManager: Instance save not found for instance {}", instanceId);
        return false;
    }
    
    // Unbind from any existing instance of this map first
    sInstanceSaveMgr->PlayerUnbindInstance(player->GetGUID(), mapId, 
        save->GetDifficulty(), true);
    
    // Bind player to instance
    InstancePlayerBind* bind = sInstanceSaveMgr->PlayerBindToInstance(player->GetGUID(), save, false, player);
    if (!bind)
    {
        LOG_ERROR("module", "InfiniteDungeonInstanceManager: Failed to bind player {} to instance {}", 
            player->GetGUID().GetCounter(), instanceId);
        return false;
    }
    
    LOG_INFO("module", "InfiniteDungeonInstanceManager: Bound player {} to instance {}", 
        player->GetGUID().GetCounter(), instanceId);
    
    return true;
}

bool InfiniteDungeonInstanceManager::TeleportPlayerToInstance(Player* player)
{
    if (!player)
        return false;
    
    InfiniteDungeonInstance* instance = GetPlayerInstance(player);
    
    if (!instance || !instance->map)
    {
        LOG_ERROR("module", "InfiniteDungeonInstanceManager: Player {} has no active instance", 
            player->GetGUID().GetCounter());
        return false;
    }
    
    Position spawnPos = GetSpawnPosition(instance->mapId);
    
    // Teleport player to instance - use the correct TeleportTo signature
    if (!player->TeleportTo(instance->mapId, spawnPos.GetPositionX(), spawnPos.GetPositionY(), 
        spawnPos.GetPositionZ(), spawnPos.GetOrientation(), 0))
    {
        LOG_ERROR("module", "InfiniteDungeonInstanceManager: Failed to teleport player {} to instance {}", 
            player->GetGUID().GetCounter(), instance->instanceId);
        return false;
    }
    
    LOG_INFO("module", "InfiniteDungeonInstanceManager: Teleported player {} to instance {}", 
        player->GetGUID().GetCounter(), instance->instanceId);
    
    if (player->GetSession())
    {
        ChatHandler(player->GetSession()).PSendSysMessage("|cFF00FF00Teleported to Infinite Dungeon!|r");
    }
    
    return true;
}

void InfiniteDungeonInstanceManager::EndInstance(uint32 leaderGuid)
{
    auto itr = m_instances.find(leaderGuid);
    if (itr != m_instances.end())
    {
        LOG_INFO("module", "InfiniteDungeonInstanceManager: Ending instance {} for leader {}", 
            itr->second.instanceId, leaderGuid);
        
        // Unbind all group members from instance
        InstanceSave* save = sInstanceSaveMgr->GetInstanceSave(itr->second.instanceId);
        Difficulty diff = save ? save->GetDifficulty() : DUNGEON_DIFFICULTY_NORMAL;
        
        for (uint32 memberGuid : itr->second.groupMemberGuids)
        {
            if (save)
            {
                sInstanceSaveMgr->PlayerUnbindInstance(ObjectGuid::Create<HighGuid::Player>(memberGuid), 
                    itr->second.mapId, diff, true);
            }
        }
        
        m_instances.erase(itr);
    }
}

void InfiniteDungeonInstanceManager::CleanupOldInstances()
{
    // Cleanup instances older than 1 hour with no players
    uint64 currentTime = GameTime::GetGameTime().count();
    const uint64 CLEANUP_TIME = 3600; // 1 hour
    
    for (auto itr = m_instances.begin(); itr != m_instances.end();)
    {
        if (currentTime - itr->second.createdTime > CLEANUP_TIME)
        {
            // Check if instance has players
            if (itr->second.map && !itr->second.map->HavePlayers())
            {
                LOG_INFO("module", "InfiniteDungeonInstanceManager: Cleaning up old instance {} for player {}", 
                    itr->second.instanceId, itr->first);
                
                // Unbind all group members
                InstanceSave* save = sInstanceSaveMgr->GetInstanceSave(itr->second.instanceId);
                Difficulty diff = save ? save->GetDifficulty() : DUNGEON_DIFFICULTY_NORMAL;
                
                for (uint32 memberGuid : itr->second.groupMemberGuids)
                {
                    if (save)
                    {
                        sInstanceSaveMgr->PlayerUnbindInstance(ObjectGuid::Create<HighGuid::Player>(memberGuid), 
                            itr->second.mapId, diff, true);
                    }
                }
                
                itr = m_instances.erase(itr);
            }
            else
            {
                ++itr;
            }
        }
        else
        {
            ++itr;
        }
    }
}

void InfiniteDungeonInstanceManager::Update(uint32 diff)
{
    m_cleanupTimer += diff;
    
    // Cleanup old instances every 5 minutes
    if (m_cleanupTimer >= 300000) // 5 minutes
    {
        CleanupOldInstances();
        m_cleanupTimer = 0;
    }
}

