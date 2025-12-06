/*
 * Daily Challenge System
 * Handles daily challenge generation and progress tracking
 */

#ifndef DAILY_CHALLENGE_SYSTEM_H
#define DAILY_CHALLENGE_SYSTEM_H

#include "Define.h"
#include "Player.h"
#include "DatabaseEnv.h"
#include "ProgressiveSystems.h"

class DailyChallengeSystem
{
public:
    static DailyChallengeSystem* instance()
    {
        static DailyChallengeSystem instance;
        return &instance;
    }
    
    void Initialize() {}
    
    // Update challenge progress
    // challengeType: 1 = Dungeons, 2 = Raids, 3 = Kills, 4 = Infinite Dungeon floors, etc.
    void UpdateChallengeProgress(Player* player, uint32 challengeType, uint32 param1, uint32 progress)
    {
        if (!player)
            return;
        
        // Update challenge progress in database
        uint32 guid = player->GetGUID().GetCounter();
        // First, get the challenge_id from daily_challenges table (world DB)
        // For now, use a simple mapping: challenge_type * 1000 + param1 as challenge_id
        uint32 challengeId = challengeType * 1000 + param1;
        CharacterDatabase.Execute(
            "INSERT INTO character_challenge_progress (guid, challenge_id, progress, completed) "
            "VALUES ({}, {}, {}, 0) "
            "ON DUPLICATE KEY UPDATE progress = progress + {}",
            guid, challengeId, progress, progress);
    }
    
    // Check if challenge is completed
    bool IsChallengeCompleted(Player* player, uint32 challengeType, uint32 param1)
    {
        if (!player)
            return false;
        
        uint32 guid = player->GetGUID().GetCounter();
        uint32 challengeId = challengeType * 1000 + param1;
        QueryResult result = CharacterDatabase.Query(
            "SELECT completed FROM character_challenge_progress WHERE guid = {} AND challenge_id = {}",
            guid, challengeId);
        
        if (result)
        {
            return result->Fetch()[0].Get<bool>();
        }
        
        return false;
    }
    
    // Award challenge rewards
    void AwardChallengeRewards(Player* player, uint32 challengeType, uint32 param1)
    {
        if (!player)
            return;
        
        // Award progression points
        if (sProgressiveSystems)
        {
            uint32 points = 500; // Base reward
            sProgressiveSystems->AddProgressionPoints(player, points);
        }
    }
};

#define sDailyChallengeSystem DailyChallengeSystem::instance()

#endif // DAILY_CHALLENGE_SYSTEM_H

