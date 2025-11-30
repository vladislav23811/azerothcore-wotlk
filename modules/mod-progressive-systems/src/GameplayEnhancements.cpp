/*
 * Gameplay Enhancements Implementation
 * New features and gameplay options
 */

#include "GameplayEnhancements.h"
#include "DatabaseEnv.h"
#include "Log.h"
#include "Chat.h"
#include "World.h"
#include "WorldSessionMgr.h"
#include <ctime>

// ============================================================
// COMBAT ENHANCEMENTS
// ============================================================
CombatEnhancements* CombatEnhancements::instance()
{
    static CombatEnhancements instance;
    return &instance;
}

void CombatEnhancements::ScaleCreatureForPlayer(Creature* creature, Player* player)
{
    if (!creature || !player)
        return;
    
    // Get player's progression tier
    uint32 guid = player->GetGUID().GetCounter();
    QueryResult result = CharacterDatabase.Query(
        "SELECT current_tier FROM character_progression_unified WHERE guid = {}", guid);
    
    uint8 tier = 1;
    if (result)
        tier = result->Fetch()[0].Get<uint8>();
    
    // Scale creature stats based on tier
    float healthMultiplier = 1.0f + (tier * 0.1f); // 10% per tier
    float damageMultiplier = 1.0f + (tier * 0.08f); // 8% per tier
    
    uint32 newHealth = static_cast<uint32>(creature->GetMaxHealth() * healthMultiplier);
    creature->SetMaxHealth(newHealth);
    creature->SetHealth(newHealth);
    
    // Damage scaling handled by difficulty system
}

void CombatEnhancements::RegisterCombo(Player* player, uint32 spellId)
{
    if (!player)
        return;
    
    uint32 guid = player->GetGUID().GetCounter();
    auto& data = m_playerCombatData[guid];
    
    // Reset combo if too much time passed
    time_t now = time(nullptr);
    if (now - data.lastKillTime > 10) // 10 seconds combo window
        data.comboCount = 0;
    
    data.comboCount++;
    data.lastKillTime = now;
}

uint32 CombatEnhancements::GetComboCount(Player* player)
{
    if (!player)
        return 0;
    
    uint32 guid = player->GetGUID().GetCounter();
    auto it = m_playerCombatData.find(guid);
    if (it != m_playerCombatData.end())
        return it->second.comboCount;
    
    return 0;
}

void CombatEnhancements::ApplyComboBonus(Player* player, float multiplier)
{
    if (!player)
        return;
    
    uint32 combo = GetComboCount(player);
    if (combo > 0)
    {
        float bonus = 1.0f + (combo * multiplier);
        // Apply damage bonus via aura
        // This would need aura system integration
    }
}

float CombatEnhancements::GetExecutionBonus(Player* player, Creature* target)
{
    if (!player || !target)
        return 1.0f;
    
    float targetHealthPercent = target->GetHealthPct();
    
    // Bonus damage when target is below 20% health
    if (targetHealthPercent < 20.0f)
    {
        return 1.0f + ((20.0f - targetHealthPercent) / 100.0f); // Up to 20% bonus
    }
    
    return 1.0f;
}

void CombatEnhancements::RegisterKill(Player* player)
{
    if (!player)
        return;
    
    uint32 guid = player->GetGUID().GetCounter();
    auto& data = m_playerCombatData[guid];
    
    time_t now = time(nullptr);
    
    // Reset if too much time passed
    if (now - data.lastKillTime > 30) // 30 seconds momentum window
        data.consecutiveKills = 0;
    
    data.consecutiveKills++;
    data.lastKillTime = now;
    
    // Update database
    CharacterDatabase.Execute(
        "INSERT INTO player_combat_data (guid, consecutive_kills, last_kill_time) "
        "VALUES ({}, {}, FROM_UNIXTIME({})) "
        "ON DUPLICATE KEY UPDATE consecutive_kills = {}, last_kill_time = FROM_UNIXTIME({})",
        guid, data.consecutiveKills, now, data.consecutiveKills, now);
}

float CombatEnhancements::GetMomentumMultiplier(Player* player)
{
    if (!player)
        return 1.0f;
    
    uint32 guid = player->GetGUID().GetCounter();
    auto it = m_playerCombatData.find(guid);
    if (it != m_playerCombatData.end())
    {
        uint32 kills = it->second.consecutiveKills;
        // 1% bonus per kill, max 50% (50 kills)
        return 1.0f + (std::min(kills, 50u) * 0.01f);
    }
    
    return 1.0f;
}

// ============================================================
// PROGRESSION ENHANCEMENTS
// ============================================================
ProgressionEnhancements* ProgressionEnhancements::instance()
{
    static ProgressionEnhancements instance;
    return &instance;
}

void ProgressionEnhancements::EnhanceQuestReward(Player* player, uint32 questId, uint32& xp, uint32& gold)
{
    if (!player)
        return;
    
    // Get player's progression tier
    uint32 guid = player->GetGUID().GetCounter();
    QueryResult result = CharacterDatabase.Query(
        "SELECT current_tier FROM character_progression_unified WHERE guid = {}", guid);
    
    uint8 tier = 1;
    if (result)
        tier = result->Fetch()[0].Get<uint8>();
    
    // Scale rewards by tier
    float xpMultiplier = 1.0f + (tier * 0.05f); // 5% per tier
    float goldMultiplier = 1.0f + (tier * 0.03f); // 3% per tier
    
    xp = static_cast<uint32>(xp * xpMultiplier);
    gold = static_cast<uint32>(gold * goldMultiplier);
}

void ProgressionEnhancements::CheckMilestones(Player* player)
{
    if (!player)
        return;
    
    uint32 guid = player->GetGUID().GetCounter();
    QueryResult result = CharacterDatabase.Query(
        "SELECT total_kills, current_tier FROM character_progression_unified WHERE guid = {}", guid);
    
    if (!result)
        return;
    
    Field* fields = result->Fetch();
    uint32 kills = fields[0].Get<uint32>();
    uint8 tier = fields[1].Get<uint8>();
    
    // Check milestone thresholds
    uint32 milestones[] = {100, 500, 1000, 5000, 10000, 50000, 100000};
    
    for (uint32 milestone : milestones)
    {
        if (kills >= milestone)
        {
            // Check if already awarded
            QueryResult check = CharacterDatabase.Query(
                "SELECT COUNT(*) FROM character_paragon_milestones WHERE guid = {} AND milestone_id = {}",
                guid, milestone);
            
            if (check && check->Fetch()[0].Get<uint64>() == 0)
            {
                AwardMilestone(player, milestone);
            }
        }
    }
}

void ProgressionEnhancements::AwardMilestone(Player* player, uint32 milestoneId)
{
    if (!player)
        return;
    
    uint32 guid = player->GetGUID().GetCounter();
    
    // Record milestone
    CharacterDatabase.Execute(
        "INSERT INTO character_paragon_milestones (guid, milestone_id, reward_claimed) "
        "VALUES ({}, {}, 1)", guid, milestoneId);
    
    // Award bonus points
    uint32 bonusPoints = milestoneId / 10; // 10 points per 100 kills
    CharacterDatabase.Execute(
        "UPDATE character_progression_unified SET progression_points = progression_points + {} WHERE guid = {}",
        bonusPoints, guid);
    
    ChatHandler(player->GetSession()).PSendSysMessage(
        "|cFF00FF00Milestone Reached!|r %u kills! You earned %u bonus progression points!",
        milestoneId, bonusPoints);
    
    // World announcement for major milestones
    if (milestoneId >= 10000)
    {
        std::string msg = Acore::StringFormat("|cFF00FF00%s|r has reached |cFFFF0000%d kills|r milestone!",
            player->GetName().c_str(), milestoneId);
        sWorldSessionMgr->SendServerMessage(SERVER_MSG_STRING, msg);
    }
}

void ProgressionEnhancements::CheckProgressionAchievements(Player* player)
{
    if (!player)
        return;
    
    // Check various achievement criteria
    // This would integrate with achievement system
}

void ProgressionEnhancements::AwardTitle(Player* player, const std::string& title)
{
    if (!player)
        return;
    
    // Award custom title
    // This would integrate with title system
    ChatHandler(player->GetSession()).PSendSysMessage(
        "|cFF00FF00You earned the title:|r %s", title.c_str());
}

// ============================================================
// QUALITY OF LIFE ENHANCEMENTS
// ============================================================
QoLEnhancements* QoLEnhancements::instance()
{
    static QoLEnhancements instance;
    return &instance;
}

void QoLEnhancements::EnableAutoLoot(Player* player, bool enable)
{
    if (!player)
        return;
    
    uint32 guid = player->GetGUID().GetCounter();
    CharacterDatabase.Execute(
        "INSERT INTO player_enhancement_settings (guid, auto_loot) VALUES ({}, {}) "
        "ON DUPLICATE KEY UPDATE auto_loot = {}",
        guid, enable, enable);
}

bool QoLEnhancements::IsAutoLootEnabled(Player* player)
{
    if (!player)
        return false;
    
    uint32 guid = player->GetGUID().GetCounter();
    QueryResult result = CharacterDatabase.Query(
        "SELECT auto_loot FROM player_enhancement_settings WHERE guid = {}", guid);
    
    if (result)
        return result->Fetch()[0].Get<bool>();
    
    return false;
}

void QoLEnhancements::EnableAutoVendor(Player* player, bool enable)
{
    if (!player)
        return;
    
    uint32 guid = player->GetGUID().GetCounter();
    CharacterDatabase.Execute(
        "INSERT INTO player_enhancement_settings (guid, auto_vendor) VALUES ({}, {}) "
        "ON DUPLICATE KEY UPDATE auto_vendor = {}",
        guid, enable, enable);
}

void QoLEnhancements::AutoRepair(Player* player)
{
    if (!player)
        return;
    
    // Auto-repair all items
    uint32 cost = player->DurabilityRepairAll(false, 1.0f, false);
    if (cost > 0)
    {
        player->ModifyMoney(-static_cast<int32>(cost));
        ChatHandler(player->GetSession()).PSendSysMessage(
            "|cFF00FF00Auto-repaired all items for %u gold|r", cost / 10000);
    }
}

void QoLEnhancements::AutoSortInventory(Player* player)
{
    if (!player)
        return;
    
    // Sort inventory items
    // This would need integration with inventory system
}

void QoLEnhancements::RegisterTeleportLocation(Player* player, const std::string& name, uint32 mapId, float x, float y, float z)
{
    if (!player)
        return;
    
    uint32 guid = player->GetGUID().GetCounter();
    
    CharacterDatabase.Execute(
        "INSERT INTO player_teleport_locations (guid, location_name, map_id, x, y, z, o) "
        "VALUES ({}, '{}', {}, {}, {}, {}, {}) "
        "ON DUPLICATE KEY UPDATE map_id = {}, x = {}, y = {}, z = {}, o = {}",
        guid, name, mapId, x, y, z, player->GetOrientation(),
        mapId, x, y, z, player->GetOrientation());
}

void QoLEnhancements::TeleportToLocation(Player* player, const std::string& name)
{
    if (!player)
        return;
    
    uint32 guid = player->GetGUID().GetCounter();
    QueryResult result = CharacterDatabase.Query(
        "SELECT map_id, x, y, z, o FROM player_teleport_locations WHERE guid = {} AND location_name = '{}'",
        guid, name);
    
    if (result)
    {
        Field* fields = result->Fetch();
        uint32 mapId = fields[0].Get<uint32>();
        float x = fields[1].Get<float>();
        float y = fields[2].Get<float>();
        float z = fields[3].Get<float>();
        float o = fields[4].Get<float>();
        
        player->TeleportTo(mapId, x, y, z, o);
    }
}

// ============================================================
// MAIN GAMEPLAY ENHANCEMENTS MANAGER
// ============================================================
GameplayEnhancements* GameplayEnhancements::instance()
{
    static GameplayEnhancements instance;
    return &instance;
}

void GameplayEnhancements::Initialize()
{
    LOG_INFO("module", "Initializing Gameplay Enhancements...");
    
    // Enable all enhancements by default
    m_enabledEnhancements[EnhancementType::COMBAT] = true;
    m_enabledEnhancements[EnhancementType::PROGRESSION] = true;
    m_enabledEnhancements[EnhancementType::SOCIAL] = true;
    m_enabledEnhancements[EnhancementType::QUALITY_OF_LIFE] = true;
    m_enabledEnhancements[EnhancementType::CUSTOM] = true;
    
    LOG_INFO("module", "Gameplay Enhancements initialized.");
}

void GameplayEnhancements::Shutdown()
{
    m_enabledEnhancements.clear();
}

void GameplayEnhancements::SetEnhancementEnabled(EnhancementType type, bool enabled)
{
    m_enabledEnhancements[type] = enabled;
}

bool GameplayEnhancements::IsEnhancementEnabled(EnhancementType type)
{
    auto it = m_enabledEnhancements.find(type);
    if (it != m_enabledEnhancements.end())
        return it->second;
    
    return false;
}

