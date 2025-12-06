/*
 * Paragon System
 * Handles paragon point allocation and stat bonuses
 */

#ifndef PARAGON_SYSTEM_H
#define PARAGON_SYSTEM_H

#include "Define.h"
#include "Player.h"
#include "DatabaseEnv.h"
#include "Log.h"
#include "UnifiedStatSystem.h"

class ParagonSystem
{
public:
    static ParagonSystem* instance()
    {
        static ParagonSystem instance;
        return &instance;
    }
    
    void Initialize() {}
    
    // Get paragon level for player
    uint32 GetParagonLevel(Player* player)
    {
        if (!player)
            return 0;
        
        uint32 guid = player->GetGUID().GetCounter();
        QueryResult result = CharacterDatabase.Query(
            "SELECT paragon_level FROM character_paragon WHERE guid = {}",
            guid);
        
        if (result)
        {
            return result->Fetch()[0].Get<uint32>();
        }
        
        return 0;
    }
    
    // Get available paragon points
    uint32 GetAvailableParagonPoints(Player* player)
    {
        if (!player)
            return 0;
        
        uint32 level = GetParagonLevel(player);
        uint32 totalAllocated = GetTotalAllocatedPoints(player);
        
        // Each paragon level gives 1 point
        return level - totalAllocated;
    }
    
    // Get total allocated points
    uint32 GetTotalAllocatedPoints(Player* player)
    {
        if (!player)
            return 0;
        
        uint32 guid = player->GetGUID().GetCounter();
        QueryResult result = CharacterDatabase.Query(
            "SELECT SUM(points_allocated) FROM character_paragon_stats WHERE guid = {}",
            guid);
        
        if (result)
        {
            Field* fields = result->Fetch();
            if (!fields[0].IsNull())
            {
                return fields[0].Get<uint32>();
            }
        }
        
        return 0;
    }
    
    // Allocate paragon point to a stat
    bool AllocateParagonPoint(Player* player, uint32 statId, uint32 points)
    {
        if (!player || points == 0)
            return false;
        
        // Check if player has enough available points
        uint32 available = GetAvailableParagonPoints(player);
        if (available < points)
        {
            return false;
        }
        
        uint32 guid = player->GetGUID().GetCounter();
        
        // Allocate points (using stat_type=0 and stat_id)
        CharacterDatabase.Execute(
            "INSERT INTO character_paragon_stats (guid, stat_type, stat_id, points_allocated) "
            "VALUES ({}, 0, {}, {}) "
            "ON DUPLICATE KEY UPDATE points_allocated = points_allocated + {}",
            guid, statId, points, points);
        
        // Apply stat bonus via UnifiedStatSystem
        if (sUnifiedStatSystem)
        {
            // Reload stat bonuses to apply paragon points
            sUnifiedStatSystem->LoadPlayerStatBonuses(player);
        }
        
        return true;
    }
    
    // Reset all paragon points
    bool ResetParagonPoints(Player* player)
    {
        if (!player)
            return false;
        
        uint32 guid = player->GetGUID().GetCounter();
        
        // Clear all allocations
        CharacterDatabase.Execute(
            "DELETE FROM character_paragon_stats WHERE guid = {}",
            guid);
        
        // Reload stats
        if (sUnifiedStatSystem)
        {
            sUnifiedStatSystem->LoadPlayerStatBonuses(player);
        }
        
        return true;
    }
    
    // Get allocated points for a specific stat
    uint32 GetAllocatedPointsForStat(Player* player, uint32 statId)
    {
        if (!player)
            return 0;
        
        uint32 guid = player->GetGUID().GetCounter();
        QueryResult result = CharacterDatabase.Query(
            "SELECT points_allocated FROM character_paragon_stats WHERE guid = {} AND stat_id = {}",
            guid, statId);
        
        if (result)
        {
            return result->Fetch()[0].Get<uint32>();
        }
        
        return 0;
    }
};

#define sParagonSystem ParagonSystem::instance()

#endif // PARAGON_SYSTEM_H

