/*
 * Progressive Systems Addon Communication
 * Production-Ready Implementation with Error Handling
 */

#include "ProgressiveSystemsAddon.h"
#include "ProgressiveSystems.h"
#include "InstanceResetSystem.h"
#include "Chat.h"
#include "WorldPacket.h"
#include "DatabaseEnv.h"
#include "Log.h"
#include <sstream>
#include <iomanip>

ProgressiveSystemsAddon* ProgressiveSystemsAddon::instance()
{
    static ProgressiveSystemsAddon instance;
    return &instance;
}

void ProgressiveSystemsAddon::SendAddonMessage(Player* player, const std::string& prefix, const std::string& message)
{
    if (!player || !player->GetSession())
    {
        LOG_DEBUG("module", "ProgressiveSystemsAddon: Cannot send message - player or session is null");
        return;
    }
    
    try
    {
        // Use proper addon message system via ChatHandler
        WorldPacket data;
        ChatHandler::BuildChatPacket(data, CHAT_MSG_WHISPER, LANG_ADDON, player, player, message);
        player->SendDirectMessage(&data);
    }
    catch (const std::exception& e)
    {
        LOG_ERROR("module", "ProgressiveSystemsAddon: Exception sending addon message: {}", e.what());
    }
}

void ProgressiveSystemsAddon::SendProgressionData(Player* player)
{
    if (!player)
    {
        LOG_DEBUG("module", "ProgressiveSystemsAddon: Cannot send progression data - player is null");
        return;
    }
    
    try
    {
        uint32 guid = player->GetGUID().GetCounter();
        
        // Get progression data with error handling
        QueryResult result = CharacterDatabase.Query(
            "SELECT total_kills, current_tier, difficulty_tier, progression_points, prestige_level, "
            "total_power_level FROM character_progression_unified WHERE guid = {}", guid);
        
        if (!result)
        {
            // Player might not have progression data yet - send defaults
            std::ostringstream msg;
            msg << "PROGRESSION_DATA|"
                << "kills:0|"
                << "tier:1|"
                << "difficulty:1|"
                << "points:0|"
                << "prestige:0|"
                << "power:0";
            SendAddonMessage(player, "PROGRESSIVE_SYSTEMS", msg.str());
            return;
        }
        
        Field* fields = result->Fetch();
        uint32 totalKills = fields[0].Get<uint32>();
        uint8 currentTier = fields[1].Get<uint8>();
        uint8 difficultyTier = fields[2].Get<uint8>();
        uint64 progressionPoints = fields[3].Get<uint64>();
        uint32 prestigeLevel = fields[4].Get<uint32>();
        uint32 powerLevel = fields[5].Get<uint32>();
        
        // Build message
        std::ostringstream msg;
        msg << "PROGRESSION_DATA|"
            << "kills:" << totalKills << "|"
            << "tier:" << (int)currentTier << "|"
            << "difficulty:" << (int)difficultyTier << "|"
            << "points:" << progressionPoints << "|"
            << "prestige:" << prestigeLevel << "|"
            << "power:" << powerLevel;
        
        SendAddonMessage(player, "PROGRESSIVE_SYSTEMS", msg.str());
        
        LOG_DEBUG("module", "ProgressiveSystemsAddon: Sent progression data to player {} (Kills: {}, Points: {})", 
                  player->GetName(), totalKills, progressionPoints);
    }
    catch (const std::exception& e)
    {
        LOG_ERROR("module", "ProgressiveSystemsAddon: Exception in SendProgressionData: {}", e.what());
    }
}

void ProgressiveSystemsAddon::SendPointsUpdate(Player* player, uint64 points)
{
    if (!player)
        return;
    
    try
    {
        std::ostringstream msg;
        msg << "POINTS_UPDATE|points:" << points;
        SendAddonMessage(player, "PROGRESSIVE_SYSTEMS", msg.str());
    }
    catch (const std::exception& e)
    {
        LOG_ERROR("module", "ProgressiveSystemsAddon: Exception in SendPointsUpdate: {}", e.what());
    }
}

void ProgressiveSystemsAddon::SendKillUpdate(Player* player, uint32 totalKills)
{
    if (!player)
        return;
    
    try
    {
        std::ostringstream msg;
        msg << "KILL_UPDATE|kills:" << totalKills;
        SendAddonMessage(player, "PROGRESSIVE_SYSTEMS", msg.str());
    }
    catch (const std::exception& e)
    {
        LOG_ERROR("module", "ProgressiveSystemsAddon: Exception in SendKillUpdate: {}", e.what());
    }
}

void ProgressiveSystemsAddon::SendDifficultyUpdate(Player* player, uint8 difficultyTier)
{
    if (!player)
        return;
    
    try
    {
        std::ostringstream msg;
        msg << "DIFFICULTY_UPDATE|tier:" << (int)difficultyTier;
        SendAddonMessage(player, "PROGRESSIVE_SYSTEMS", msg.str());
    }
    catch (const std::exception& e)
    {
        LOG_ERROR("module", "ProgressiveSystemsAddon: Exception in SendDifficultyUpdate: {}", e.what());
    }
}

void ProgressiveSystemsAddon::SendChallengeUpdate(Player* player, uint32 challengeId, uint32 progress)
{
    if (!player)
        return;
    
    try
    {
        std::ostringstream msg;
        msg << "CHALLENGE_UPDATE|id:" << challengeId << "|progress:" << progress;
        SendAddonMessage(player, "PROGRESSIVE_SYSTEMS", msg.str());
    }
    catch (const std::exception& e)
    {
        LOG_ERROR("module", "ProgressiveSystemsAddon: Exception in SendChallengeUpdate: {}", e.what());
    }
}

void ProgressiveSystemsAddon::SendInstanceData(Player* player)
{
    if (!player)
        return;
    
    try
    {
        // Get instance reset info
        std::vector<InstanceResetInfo> instances = sInstanceResetSystem->GetResetInfo(player);
        
        // Build message with all instance data
        std::ostringstream msg;
        msg << "INSTANCE_DATA|count:" << instances.size();
        
        for (size_t i = 0; i < instances.size() && i < 50; ++i) // Limit to 50 instances
        {
            const InstanceResetInfo& inst = instances[i];
            msg << "|instance" << i << ":"
                << "mapId:" << inst.mapId << ","
                << "name:" << inst.mapName << ","
                << "completions:" << inst.completionCount << ","
                << "canReset:" << (inst.canReset ? 1 : 0);
        }
        
        SendAddonMessage(player, "PROGRESSIVE_SYSTEMS", msg.str());
        
        LOG_DEBUG("module", "ProgressiveSystemsAddon: Sent instance data to player {} ({} instances)", 
                  player->GetName(), instances.size());
    }
    catch (const std::exception& e)
    {
        LOG_ERROR("module", "ProgressiveSystemsAddon: Exception in SendInstanceData: {}", e.what());
    }
}

void ProgressiveSystemsAddon::HandleAddonMessage(Player* player, const std::string& prefix, const std::string& message)
{
    if (!player)
        return;
    
    try
    {
        if (prefix == "PS_DATA_REQUEST")
        {
            // Parse request type
            if (message == "PROGRESSION" || message == "ALL")
            {
                SendProgressionData(player);
            }
            if (message == "INSTANCE_DATA" || message == "ALL")
            {
                SendInstanceData(player);
            }
        }
        else if (prefix == "PS_INSTANCE_RESET")
        {
            // Handle instance reset request
            if (message == "all_dungeons")
            {
                sInstanceResetSystem->ResetAllInstances(player, false);
            }
            else if (message == "all_raids")
            {
                sInstanceResetSystem->ResetAllInstances(player, true);
            }
            else
            {
                // Try to parse as map ID
                uint32 mapId = 0;
                try
                {
                    mapId = static_cast<uint32>(std::stoul(message));
                    if (mapId > 0)
                    {
                        sInstanceResetSystem->ResetInstance(player, mapId, false);
                    }
                }
                catch (...)
                {
                    LOG_DEBUG("module", "ProgressiveSystemsAddon: Invalid map ID in reset request: {}", message);
                }
            }
        }
    }
    catch (const std::exception& e)
    {
        LOG_ERROR("module", "ProgressiveSystemsAddon: Exception in HandleAddonMessage: {}", e.what());
    }
}
