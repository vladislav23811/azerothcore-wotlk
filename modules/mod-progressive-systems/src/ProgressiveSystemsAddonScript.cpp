/*
 * Progressive Systems Addon Script Implementation
 * Handles addon messages from clients
 */

#include "ProgressiveSystemsAddonScript.h"
#include "ProgressiveSystemsAddon.h"
#include "UnifiedStatSystem.h"
#include "World.h"
#include "Log.h"
#include <algorithm>

void ProgressiveSystemsAddonScript::OnPlayerChat(Player* player, uint32 type, uint32 lang, std::string& msg, Player* receiver)
{
    // Only handle addon messages (whisper to self)
    if (lang != LANG_ADDON || type != CHAT_MSG_WHISPER || !receiver || receiver != player)
        return;
    
    // Parse addon message format: "PREFIX|MESSAGE"
    size_t pipePos = msg.find('|');
    if (pipePos == std::string::npos)
        return;
    
    std::string prefix = msg.substr(0, pipePos);
    std::string message = msg.substr(pipePos + 1);
    
    // Handle our addon messages
    if (prefix == "PS_DATA_REQUEST" || prefix == "PS_INSTANCE_RESET")
    {
        sProgressiveSystemsAddon->HandleAddonMessage(player, prefix, message);
    }
}

void ProgressiveSystemsAddonScript::OnPlayerLogin(Player* player)
{
    if (!player)
        return;
    
    // Load and apply stat bonuses from item upgrades, paragon, prestige
    // This must be called after player is fully loaded
    if (player->IsInWorld())
    {
        // Load stat bonuses from database
        sUnifiedStatSystem->LoadPlayerStatBonuses(player);
        
        // Send initial data to addon
        sProgressiveSystemsAddon->SendProgressionData(player);
        sProgressiveSystemsAddon->SendInstanceData(player);
    }
}

