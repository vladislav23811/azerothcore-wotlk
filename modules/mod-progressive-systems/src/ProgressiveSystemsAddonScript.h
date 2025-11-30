/*
 * Progressive Systems Addon Script
 * Handles addon messages from clients
 */

#ifndef PROGRESSIVE_SYSTEMS_ADDON_SCRIPT_H
#define PROGRESSIVE_SYSTEMS_ADDON_SCRIPT_H

#include "Define.h"
#include "PlayerScript.h"

class AC_GAME_API ProgressiveSystemsAddonScript : public PlayerScript
{
public:
    ProgressiveSystemsAddonScript() : PlayerScript("ProgressiveSystemsAddonScript", 
        { PLAYERHOOK_ON_CHAT_WITH_RECEIVER, PLAYERHOOK_ON_LOGIN }) { }
    
    // Handle addon messages (whisper to self)
    void OnPlayerChat(Player* player, uint32 type, uint32 lang, std::string& msg, Player* receiver) override;
    
    // Send initial data on login
    void OnPlayerLogin(Player* player) override;
};

#endif // PROGRESSIVE_SYSTEMS_ADDON_SCRIPT_H

