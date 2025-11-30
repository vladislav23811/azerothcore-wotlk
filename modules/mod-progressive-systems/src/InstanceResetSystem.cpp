/*
 * Instance Reset System Implementation
 * Allows players to reset instances and track completion counts
 */

#include "InstanceResetSystem.h"
#include "ProgressiveSystems.h"
#include "InstanceSaveMgr.h"
#include "MapMgr.h"
#include "DatabaseEnv.h"
#include "Log.h"
#include "Chat.h"
#include "ObjectMgr.h"
#include "DBCStores.h"
#include <ctime>

InstanceResetSystem* InstanceResetSystem::instance()
{
    static InstanceResetSystem instance;
    return &instance;
}

void InstanceResetSystem::Initialize()
{
    LOG_INFO("module", "Instance Reset System: Initializing...");
    
    // Default configuration
    m_config.unlimitedResets = true;
    m_config.maxResetsPerDay = 0; // Unlimited
    m_config.requireProgressionPoints = false;
    m_config.resetCostPoints = 0;
    m_config.allowRaidResets = true;
    m_config.allowDungeonResets = true;
    m_config.cooldownSeconds = 0; // No cooldown
    
    LOG_INFO("module", "Instance Reset System: Initialized (Unlimited resets: {})", m_config.unlimitedResets);
}

void InstanceResetSystem::Shutdown()
{
    m_completionCache.clear();
    LOG_INFO("module", "Instance Reset System: Shutdown");
}

void InstanceResetSystem::OnInstanceComplete(Player* player, Map* map, uint8 difficultyTier)
{
    if (!player || !map || !map->IsDungeon() && !map->IsRaid())
        return;
    
    uint32 mapId = map->GetId();
    uint32 guid = player->GetGUID().GetCounter();
    
    // Get or create completion data
    InstanceCompletionData& data = m_completionCache[guid][mapId];
    data.mapId = mapId;
    data.completionCount++;
    data.lastCompletionTime = static_cast<uint32>(time(nullptr));
    
    // Update highest difficulty
    if (difficultyTier > data.highestDifficultyTier)
        data.highestDifficultyTier = difficultyTier;
    
    // Save to database
    SaveCompletionData(player, mapId, data);
    
    LOG_DEBUG("module", "Instance Reset System: Player {} completed instance {} (Count: {})", 
              player->GetName(), mapId, data.completionCount);
}

bool InstanceResetSystem::ResetInstance(Player* player, uint32 mapId, bool force)
{
    if (!player)
        return false;
    
    // Check if player can reset
    if (!force && !CanPlayerReset(player, mapId))
        return false;
    
    // Check if instance exists and can be reset
    if (!CanResetInstance(player, mapId))
        return false;
    
    MapEntry const* mapEntry = sMapStore.LookupEntry(mapId);
    if (!mapEntry || !mapEntry->Instanceable())
        return false;
    
    // Check if raid/dungeon resets are allowed
    if (mapEntry->IsRaid() && !m_config.allowRaidResets)
    {
        ChatHandler(player->GetSession()).PSendSysMessage("Raid instance resets are not allowed.");
        return false;
    }
    
    if (mapEntry->IsDungeon() && !m_config.allowDungeonResets)
    {
        ChatHandler(player->GetSession()).PSendSysMessage("Dungeon instance resets are not allowed.");
        return false;
    }
    
    try
    {
        // Get instance save
        Difficulty difficulty = player->GetDifficulty(mapEntry->IsRaid());
        InstanceSave* save = sInstanceSaveMgr->PlayerGetInstanceSave(player->GetGUID(), mapId, difficulty);
        
        if (!save)
        {
            if (player->GetSession())
            {
                ChatHandler(player->GetSession()).PSendSysMessage("You are not bound to this instance.");
            }
            return false;
        }
        
        // Check if can reset
        if (!save->CanReset() && !force)
        {
            if (player->GetSession())
            {
                ChatHandler(player->GetSession()).PSendSysMessage("This instance cannot be reset.");
            }
            return false;
        }
        
        // Charge progression points if required
        if (m_config.requireProgressionPoints && m_config.resetCostPoints > 0)
        {
            if (!sProgressiveSystems->SpendProgressionPoints(player, m_config.resetCostPoints))
            {
                if (player->GetSession())
                {
                    ChatHandler(player->GetSession()).PSendSysMessage(
                        "Not enough progression points! Required: %u", m_config.resetCostPoints);
                }
                return false;
            }
        }
    }
    catch (const std::exception& e)
    {
        LOG_ERROR("module", "InstanceResetSystem: Exception in ResetInstance (pre-check): {}", e.what());
        return false;
    }
    
    try
    {
        // Get instance save (re-fetch in case it changed)
        Difficulty difficulty = player->GetDifficulty(mapEntry->IsRaid());
        InstanceSave* save = sInstanceSaveMgr->PlayerGetInstanceSave(player->GetGUID(), mapId, difficulty);
        if (!save)
        {
            if (player->GetSession())
            {
                ChatHandler(player->GetSession()).PSendSysMessage("Instance save not found.");
            }
            return false;
        }
        
        // Get instance map
        uint32 instanceId = save->GetInstanceId();
        Map* map = sMapMgr->FindMap(mapId, instanceId);
        
        if (map && map->ToInstanceMap())
        {
            // Reset the instance
            if (map->ToInstanceMap()->Reset(INSTANCE_RESET_ALL))
            {
                // Unbind player from instance
                sInstanceSaveMgr->UnbindAllFor(save);
                sInstanceSaveMgr->DeleteInstanceSavedData(instanceId);
                
                // Track reset usage
                TrackResetUsage(player, mapId);
                
                if (player->GetSession())
                {
                    ChatHandler(player->GetSession()).PSendSysMessage(
                        "|cFF00FF00Instance reset successfully!|r You can now enter %s again.", 
                        mapEntry->name[player->GetSession()->GetSessionDbcLocale()]);
                }
                
                LOG_INFO("module", "Instance Reset System: Player {} reset instance {} (ID: {})", 
                         player->GetName(), mapId, instanceId);
                
                return true;
            }
            else
            {
                if (player->GetSession())
                {
                    ChatHandler(player->GetSession()).PSendSysMessage(
                        "|cFFFF0000Failed to reset instance.|r Instance may still have players inside.");
                }
                return false;
            }
        }
        else
        {
            // Instance not loaded, just unbind
            sInstanceSaveMgr->UnbindAllFor(save);
            sInstanceSaveMgr->DeleteInstanceSavedData(instanceId);
            
            TrackResetUsage(player, mapId);
            
            if (player->GetSession())
            {
                ChatHandler(player->GetSession()).PSendSysMessage(
                    "|cFF00FF00Instance reset successfully!|r You can now enter %s again.", 
                    mapEntry->name[player->GetSession()->GetSessionDbcLocale()]);
            }
            
            return true;
        }
    }
    catch (const std::exception& e)
    {
        LOG_ERROR("module", "InstanceResetSystem: Exception in ResetInstance: {}", e.what());
        if (player->GetSession())
        {
            ChatHandler(player->GetSession()).PSendSysMessage("An error occurred while resetting the instance.");
        }
        return false;
    }
}

bool InstanceResetSystem::ResetAllInstances(Player* player, bool raidsOnly)
{
    if (!player)
        return false;
    
    BoundInstancesMap const& boundInstances = sInstanceSaveMgr->PlayerGetBoundInstances(
        player->GetGUID(), player->GetDifficulty(raidsOnly));
    
    uint32 resetCount = 0;
    for (BoundInstancesMap::const_iterator itr = boundInstances.begin(); itr != boundInstances.end(); ++itr)
    {
        InstanceSave* save = itr->second.save;
        MapEntry const* entry = sMapStore.LookupEntry(itr->first);
        
        if (!entry || !entry->Instanceable())
            continue;
        
        if (raidsOnly && !entry->IsRaid())
            continue;
        
        if (!entry->IsRaid() && raidsOnly)
            continue;
        
        if (ResetInstance(player, itr->first, false))
            resetCount++;
    }
    
    if (resetCount > 0)
    {
        ChatHandler(player->GetSession()).PSendSysMessage(
            "|cFF00FF00Reset %u instance(s) successfully!|r", resetCount);
    }
    else
    {
        ChatHandler(player->GetSession()).PSendSysMessage("No instances to reset.");
    }
    
    return resetCount > 0;
}

InstanceCompletionData InstanceResetSystem::GetCompletionData(Player* player, uint32 mapId)
{
    if (!player)
        return InstanceCompletionData();
    
    uint32 guid = player->GetGUID().GetCounter();
    
    // Load from cache or database
    if (m_completionCache[guid].find(mapId) == m_completionCache[guid].end())
    {
        LoadCompletionData(player);
    }
    
    auto it = m_completionCache[guid].find(mapId);
    if (it != m_completionCache[guid].end())
        return it->second;
    
    return InstanceCompletionData();
}

std::vector<InstanceCompletionData> InstanceResetSystem::GetAllCompletions(Player* player)
{
    std::vector<InstanceCompletionData> completions;
    
    if (!player)
        return completions;
    
    uint32 guid = player->GetGUID().GetCounter();
    
    // Load from database
    LoadCompletionData(player);
    
    for (const auto& [mapId, data] : m_completionCache[guid])
    {
        completions.push_back(data);
    }
    
    return completions;
}

std::vector<InstanceResetInfo> InstanceResetSystem::GetResetInfo(Player* player)
{
    std::vector<InstanceResetInfo> infoList;
    
    if (!player)
        return infoList;
    
    BoundInstancesMap const& boundInstances = sInstanceSaveMgr->PlayerGetBoundInstances(
        player->GetGUID(), player->GetDifficulty(false));
    
    for (BoundInstancesMap::const_iterator itr = boundInstances.begin(); itr != boundInstances.end(); ++itr)
    {
        InstanceResetInfo info = GetInstanceResetInfo(player, itr->first);
        infoList.push_back(info);
    }
    
    return infoList;
}

InstanceResetInfo InstanceResetSystem::GetInstanceResetInfo(Player* player, uint32 mapId)
{
    InstanceResetInfo info;
    info.mapId = mapId;
    info.instanceId = 0;
    info.canReset = false;
    info.isRaid = false;
    info.completionCount = 0;
    info.lastResetTime = 0;
    info.nextResetTime = 0;
    
    if (!player)
        return info;
    
    MapEntry const* mapEntry = sMapStore.LookupEntry(mapId);
    if (!mapEntry)
        return info;
    
    info.mapName = mapEntry->name[player->GetSession()->GetSessionDbcLocale()];
    info.isRaid = mapEntry->IsRaid();
    
    // Get instance save
    Difficulty difficulty = player->GetDifficulty(mapEntry->IsRaid());
    InstanceSave* save = sInstanceSaveMgr->PlayerGetInstanceSave(player->GetGUID(), mapId, difficulty);
    
    if (save)
    {
        info.instanceId = save->GetInstanceId();
        info.canReset = save->CanReset();
    }
    
    // Get completion data
    InstanceCompletionData completion = GetCompletionData(player, mapId);
    info.completionCount = completion.completionCount;
    
    return info;
}

bool InstanceResetSystem::CanResetInstance(Player* player, uint32 mapId)
{
    if (!player)
        return false;
    
    MapEntry const* mapEntry = sMapStore.LookupEntry(mapId);
    if (!mapEntry || !mapEntry->Instanceable())
        return false;
    
    Difficulty difficulty = player->GetDifficulty(mapEntry->IsRaid());
    InstanceSave* save = sInstanceSaveMgr->PlayerGetInstanceSave(player->GetGUID(), mapId, difficulty);
    
    if (!save)
        return false;
    
    return save->CanReset();
}

uint32 InstanceResetSystem::GetCompletionCount(Player* player, uint32 mapId)
{
    InstanceCompletionData data = GetCompletionData(player, mapId);
    return data.completionCount;
}

void InstanceResetSystem::LoadCompletionData(Player* player)
{
    if (!player)
        return;
    
    uint32 guid = player->GetGUID().GetCounter();
    
    QueryResult result = CharacterDatabase.Query(
        "SELECT map_id, completion_count, last_completion_time, best_time, "
        "highest_difficulty_tier, total_kills, total_deaths "
        "FROM instance_completion_tracking WHERE guid = {}", guid);
    
    if (result)
    {
        do
        {
            Field* fields = result->Fetch();
            InstanceCompletionData data;
            data.mapId = fields[0].Get<uint32>();
            data.completionCount = fields[1].Get<uint32>();
            data.lastCompletionTime = fields[2].Get<uint32>();
            data.bestTime = fields[3].Get<uint32>();
            data.highestDifficultyTier = fields[4].Get<uint8>();
            data.totalKills = fields[5].Get<uint32>();
            data.totalDeaths = fields[6].Get<uint32>();
            
            m_completionCache[guid][data.mapId] = data;
        } while (result->NextRow());
    }
}

void InstanceResetSystem::SaveCompletionData(Player* player, uint32 mapId, const InstanceCompletionData& data)
{
    if (!player)
        return;
    
    uint32 guid = player->GetGUID().GetCounter();
    
    CharacterDatabase.Execute(
        "INSERT INTO instance_completion_tracking "
        "(guid, map_id, completion_count, last_completion_time, best_time, "
        "highest_difficulty_tier, total_kills, total_deaths) "
        "VALUES ({}, {}, {}, {}, {}, {}, {}, {}) "
        "ON DUPLICATE KEY UPDATE "
        "completion_count = {}, last_completion_time = {}, best_time = {}, "
        "highest_difficulty_tier = {}, total_kills = {}, total_deaths = {}",
        guid, mapId, data.completionCount, data.lastCompletionTime, data.bestTime,
        data.highestDifficultyTier, data.totalKills, data.totalDeaths,
        data.completionCount, data.lastCompletionTime, data.bestTime,
        data.highestDifficultyTier, data.totalKills, data.totalDeaths);
}

void InstanceResetSystem::TrackResetUsage(Player* player, uint32 mapId)
{
    if (!player)
        return;
    
    uint32 guid = player->GetGUID().GetCounter();
    time_t now = time(nullptr);
    
    CharacterDatabase.Execute(
        "INSERT INTO instance_reset_usage (guid, map_id, reset_time) "
        "VALUES ({}, {}, {})",
        guid, mapId, static_cast<uint32>(now));
}

bool InstanceResetSystem::CanPlayerReset(Player* player, uint32 mapId)
{
    if (!player)
        return false;
    
    // Check unlimited resets
    if (m_config.unlimitedResets)
        return true;
    
    // Check daily limit
    if (m_config.maxResetsPerDay > 0)
    {
        uint32 guid = player->GetGUID().GetCounter();
        time_t today = time(nullptr);
        today = (today / 86400) * 86400; // Start of day
        
        QueryResult result = CharacterDatabase.Query(
            "SELECT COUNT(*) FROM instance_reset_usage "
            "WHERE guid = {} AND map_id = {} AND reset_time >= {}",
            guid, mapId, static_cast<uint32>(today));
        
        if (result)
        {
            uint32 count = result->Fetch()[0].Get<uint32>();
            if (count >= m_config.maxResetsPerDay)
                return false;
        }
    }
    
    // Check cooldown
    if (m_config.cooldownSeconds > 0)
    {
        uint32 guid = player->GetGUID().GetCounter();
        time_t cooldownEnd = time(nullptr) - m_config.cooldownSeconds;
        
        QueryResult result = CharacterDatabase.Query(
            "SELECT MAX(reset_time) FROM instance_reset_usage "
            "WHERE guid = {} AND map_id = {} AND reset_time > {}",
            guid, mapId, static_cast<uint32>(cooldownEnd));
        
        if (result && !result->Fetch()[0].IsNull())
        {
            // Still on cooldown
            return false;
        }
    }
    
    return true;
}

