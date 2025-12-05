/*
 * Infinite Dungeon System
 * Handles infinite dungeon wave spawning and progression
 */

#ifndef INFINITE_DUNGEON_SYSTEM_H
#define INFINITE_DUNGEON_SYSTEM_H

#include "Define.h"
#include "Player.h"
#include "DatabaseEnv.h"
#include "Log.h"
#include "Chat.h"
#include "Map.h"
#include "InfiniteDungeonInstanceManager.h"
#include "InfiniteDungeonWaveSpawner.h"
#include "DBCStores.h"
#include "Group.h"
#include "ObjectAccessor.h"

struct DungeonSession
{
    uint32 currentFloor;
    uint32 currentWave;
    uint32 totalKills;
    
    DungeonSession() : currentFloor(1), currentWave(0), totalKills(0) {}
};

class InfiniteDungeonSystem
{
public:
    static InfiniteDungeonSystem* instance()
    {
        static InfiniteDungeonSystem instance;
        return &instance;
    }
    
    void Initialize()
    {
        sInfiniteDungeonInstanceManager->Initialize();
        sInfiniteDungeonWaveSpawner->Initialize();
    }
    
    bool IsPlayerInDungeon(Player* player)
    {
        if (!player)
            return false;
        
        // Check if player has an active instance
        if (sInfiniteDungeonInstanceManager->GetPlayerInstance(player))
            return true;
            
        // Also check database
        uint32 playerGuid = player->GetGUID().GetCounter();
        QueryResult result = CharacterDatabase.Query(
            "SELECT current_floor FROM infinite_dungeon_progress WHERE guid = {}",
            playerGuid);
            
        return result != nullptr;
    }
    
    DungeonSession GetDungeonSession(Player* player)
    {
        DungeonSession session;
        
        if (!player)
            return session;
            
        QueryResult result = CharacterDatabase.Query(
            "SELECT current_floor FROM infinite_dungeon_progress WHERE guid = {}",
            player->GetGUID().GetCounter());
            
        if (result)
        {
            Field* fields = result->Fetch();
            session.currentFloor = fields[0].Get<uint32>();
            session.currentWave = 0;
            session.totalKills = 0;
        }
        
        return session;
    }
    
    bool StartDungeon(Player* player, uint32 mapId, uint32 startFloor = 1)
    {
        if (!player)
            return false;
            
        // Check if player is already in a dungeon
        if (IsPlayerInDungeon(player))
        {
            if (player->GetSession())
            {
                ChatHandler(player->GetSession()).PSendSysMessage("You are already in an Infinite Dungeon!");
            }
            return false;
        }
        
        // Verify map is instanceable
        MapEntry const* entry = sMapStore.LookupEntry(mapId);
        if (!entry || !entry->Instanceable())
        {
            if (player->GetSession())
            {
                ChatHandler(player->GetSession()).PSendSysMessage("|cFFFF0000Invalid instance map ID!|r");
            }
            return false;
        }
        
        uint32 guid = player->GetGUID().GetCounter();
        
        // Use provided startFloor or get from ProgressiveSystems
        uint32 currentFloor = startFloor;
        if (currentFloor == 0)
        {
            currentFloor = 1; // Default to floor 1, will be set by ProgressiveSystems if available
            if (currentFloor == 0)
                currentFloor = 1;
        }
        
        // Create private instance
        InfiniteDungeonInstance* instance = sInfiniteDungeonInstanceManager->CreatePrivateInstance(player, mapId, currentFloor);
        if (!instance)
        {
            if (player->GetSession())
            {
                ChatHandler(player->GetSession()).PSendSysMessage("|cFFFF0000Failed to create Infinite Dungeon instance!|r");
            }
            return false;
        }
        
        // Initialize dungeon progress
        CharacterDatabase.Execute(
            "INSERT INTO infinite_dungeon_progress (guid, current_floor, highest_floor) "
            "VALUES ({}, {}, {}) "
            "ON DUPLICATE KEY UPDATE current_floor = {}",
            guid, currentFloor, currentFloor, currentFloor);
        
        // Teleport player (and group members) to instance
        if (!sInfiniteDungeonInstanceManager->TeleportPlayerToInstance(player))
        {
            LOG_ERROR("module", "InfiniteDungeonSystem: Failed to teleport player to instance");
            EndDungeon(player);
            return false;
        }
        
        // Teleport group members
        Group* group = player->GetGroup();
        if (group && !group->isBGGroup() && !group->isBFGroup())
        {
            for (GroupReference* itr = group->GetFirstMember(); itr != nullptr; itr = itr->next())
            {
                if (Player* member = itr->GetSource())
                {
                    if (member != player && member->IsInWorld())
                    {
                        sInfiniteDungeonInstanceManager->TeleportPlayerToInstance(member);
                    }
                }
            }
        }
        
        // Start wave spawning
        if (!sInfiniteDungeonWaveSpawner->StartWaves(player, mapId, currentFloor))
        {
            LOG_ERROR("module", "InfiniteDungeonSystem: Failed to start waves");
            EndDungeon(player);
            return false;
        }
        
        LOG_INFO("module", "InfiniteDungeonSystem: Player {} started dungeon on floor {} (map {}, instance {})", 
            guid, currentFloor, mapId, instance->instanceId);
        
        if (player->GetSession())
        {
            std::string mapName = entry->name[LOCALE_enUS] ? entry->name[LOCALE_enUS] : "Unknown";
            ChatHandler(player->GetSession()).PSendSysMessage("|cFF00FF00Infinite Dungeon started!|r Map: %s, Floor: %u", mapName.c_str(), currentFloor);
            ChatHandler(player->GetSession()).PSendSysMessage("|cFFFFFF00Wave 1 spawning...|r");
        }
        
        return true;
    }
    
    void EndDungeon(Player* player)
    {
        if (!player)
            return;
            
        uint32 guid = player->GetGUID().GetCounter();
        
        // End wave spawning
        sInfiniteDungeonWaveSpawner->EndWaves(player);
        
        // Get current session data
        DungeonSession session = GetDungeonSession(player);
        
        // Update total floors cleared
        CharacterDatabase.Execute(
            "UPDATE infinite_dungeon_progress SET total_floors_cleared = COALESCE(total_floors_cleared, 0) + {} WHERE guid = {}",
            session.currentFloor, guid);
        
        // Reset current floor to 1 for next run
        CharacterDatabase.Execute(
            "UPDATE infinite_dungeon_progress SET current_floor = 1 WHERE guid = {}",
            guid);
        
        // End instance - get leader GUID for group support
        InfiniteDungeonInstance* instance = sInfiniteDungeonInstanceManager->GetPlayerInstance(player);
        if (instance)
        {
            sInfiniteDungeonInstanceManager->EndInstance(instance->playerGuid); // Uses leaderGuid from instance
        }
        
        LOG_INFO("module", "InfiniteDungeonSystem: Player {} ended dungeon at floor {}", guid, session.currentFloor);
        
        if (player->GetSession())
        {
            ChatHandler(player->GetSession()).PSendSysMessage("|cFF00FF00Infinite Dungeon ended!|r Completed floor %u.", 
                session.currentFloor);
        }
    }
    
    // Update systems (called from world update)
    void Update(uint32 diff)
    {
        sInfiniteDungeonInstanceManager->Update(diff);
        sInfiniteDungeonWaveSpawner->Update(diff);
    }
};

#define sInfiniteDungeonSystem InfiniteDungeonSystem::instance()

#endif // INFINITE_DUNGEON_SYSTEM_H

