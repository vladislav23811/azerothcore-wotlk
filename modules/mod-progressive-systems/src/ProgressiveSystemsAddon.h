/*
 * Progressive Systems Addon Communication
 * Handles communication with client addon
 */

#ifndef PROGRESSIVE_SYSTEMS_ADDON_H
#define PROGRESSIVE_SYSTEMS_ADDON_H

#include "Define.h"
#include "Player.h"
#include "WorldPacket.h"

class AC_GAME_API ProgressiveSystemsAddon
{
public:
    static ProgressiveSystemsAddon* instance();
    
    // Send progression data to client
    void SendProgressionData(Player* player);
    
    // Send points update
    void SendPointsUpdate(Player* player, uint64 points);
    
    // Send kill update
    void SendKillUpdate(Player* player, uint32 totalKills);
    
    // Send difficulty update
    void SendDifficultyUpdate(Player* player, uint8 difficultyTier);
    
           // Send challenge update
           void SendChallengeUpdate(Player* player, uint32 challengeId, uint32 progress);
           
           // Send instance data
           void SendInstanceData(Player* player);
           
           // Handle addon messages from client
           void HandleAddonMessage(Player* player, const std::string& prefix, const std::string& message);
           
       private:
    ProgressiveSystemsAddon() = default;
    ~ProgressiveSystemsAddon() = default;
    ProgressiveSystemsAddon(ProgressiveSystemsAddon const&) = delete;
    ProgressiveSystemsAddon& operator=(ProgressiveSystemsAddon const&) = delete;
    
    void SendAddonMessage(Player* player, const std::string& prefix, const std::string& message);
};

#define sProgressiveSystemsAddon ProgressiveSystemsAddon::instance()

#endif

