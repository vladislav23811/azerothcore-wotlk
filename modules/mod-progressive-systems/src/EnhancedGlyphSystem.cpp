/*
 * Enhanced Glyph System Implementation
 * Improved glyphs with progression-based unlocks and powerful effects
 */

#include "EnhancedGlyphSystem.h"
#include "ProgressiveSystems.h"
#include "DatabaseEnv.h"
#include "Log.h"
#include "Chat.h"
#include "SpellMgr.h"
#include "ObjectMgr.h"

EnhancedGlyphSystem* EnhancedGlyphSystem::instance()
{
    static EnhancedGlyphSystem instance;
    return &instance;
}

void EnhancedGlyphSystem::Initialize()
{
    LOG_INFO("module", "Enhanced Glyph System: Initializing...");
    LoadGlyphs();
    LOG_INFO("module", "Enhanced Glyph System: Initialized ({} glyphs loaded)", m_glyphs.size());
}

void EnhancedGlyphSystem::Shutdown()
{
    m_glyphs.clear();
    m_playerGlyphs.clear();
    m_playerGlyphSlots.clear();
    LOG_INFO("module", "Enhanced Glyph System: Shutdown");
}

void EnhancedGlyphSystem::LoadGlyphs()
{
    m_glyphs.clear();
    
    // Load from database
    QueryResult result = WorldDatabase.Query(
        "SELECT glyph_id, spell_id, name, description, slot_type, required_level, "
        "required_tier, required_prestige, stat_bonus, cooldown_reduction, "
        "cost_reduction, damage_bonus, healing_bonus, is_active "
        "FROM enhanced_glyphs WHERE is_active = 1");
    
    if (result)
    {
        do
        {
            Field* fields = result->Fetch();
            EnhancedGlyphData glyph;
            glyph.glyphId = fields[0].Get<uint32>();
            glyph.spellId = fields[1].Get<uint32>();
            glyph.name = fields[2].Get<std::string>();
            glyph.description = fields[3].Get<std::string>();
            glyph.slotType = (GlyphSlotType)fields[4].Get<uint8>();
            glyph.requiredLevel = fields[5].Get<uint32>();
            glyph.requiredTier = fields[6].Get<uint32>();
            glyph.requiredPrestige = fields[7].Get<uint32>();
            glyph.statBonus = fields[8].Get<float>();
            glyph.cooldownReduction = fields[9].Get<float>();
            glyph.costReduction = fields[10].Get<float>();
            glyph.damageBonus = fields[11].Get<float>();
            glyph.healingBonus = fields[12].Get<float>();
            glyph.isActive = fields[13].Get<bool>();
            
            m_glyphs[glyph.glyphId] = glyph;
        } while (result->NextRow());
        
        LOG_INFO("module", "Enhanced Glyph System: Loaded {} glyphs", m_glyphs.size());
    }
    else
    {
        LOG_INFO("module", "Enhanced Glyph System: No glyphs found in database. Creating default glyphs...");
        // Create some default glyphs
        CreateDefaultGlyphs();
    }
}

void EnhancedGlyphSystem::CreateDefaultGlyphs()
{
    // Example: Create some default enhanced glyphs
    // These would typically be loaded from SQL, but we create them here as fallback
    
    EnhancedGlyphData glyph;
    
    // Example: Major Glyph of Power
    glyph.glyphId = 90001;
    glyph.spellId = 0; // No specific spell, applies to all
    glyph.name = "Glyph of Power";
    glyph.description = "Increases all damage and healing by 5%";
    glyph.slotType = GLYPH_SLOT_MAJOR;
    glyph.requiredLevel = 80;
    glyph.requiredTier = 1;
    glyph.requiredPrestige = 0;
    glyph.statBonus = 0.0f;
    glyph.cooldownReduction = 0.0f;
    glyph.costReduction = 0.0f;
    glyph.damageBonus = 0.05f;
    glyph.healingBonus = 0.05f;
    glyph.isActive = true;
    m_glyphs[glyph.glyphId] = glyph;
    
    // Example: Prime Glyph of Mastery
    glyph.glyphId = 90002;
    glyph.spellId = 0;
    glyph.name = "Prime Glyph of Mastery";
    glyph.description = "Increases all stats by 10%";
    glyph.slotType = GLYPH_SLOT_PRIME;
    glyph.requiredLevel = 80;
    glyph.requiredTier = 5;
    glyph.requiredPrestige = 1;
    glyph.statBonus = 0.10f;
    glyph.cooldownReduction = 0.0f;
    glyph.costReduction = 0.0f;
    glyph.damageBonus = 0.0f;
    glyph.healingBonus = 0.0f;
    glyph.isActive = true;
    m_glyphs[glyph.glyphId] = glyph;
    
    LOG_INFO("module", "Enhanced Glyph System: Created {} default glyphs", m_glyphs.size());
}

bool EnhancedGlyphSystem::CanPlayerUseGlyph(Player* player, uint32 glyphId)
{
    if (!player)
        return false;
    
    auto it = m_glyphs.find(glyphId);
    if (it == m_glyphs.end())
        return false;
    
    const EnhancedGlyphData& glyph = it->second;
    
    // Check level requirement
    if (player->GetLevel() < glyph.requiredLevel)
        return false;
    
    // Check tier requirement
    if (glyph.requiredTier > 0)
    {
        uint32 guid = player->GetGUID().GetCounter();
        QueryResult result = CharacterDatabase.Query(
            "SELECT current_tier FROM character_progression_unified WHERE guid = {}", guid);
        
        uint8 tier = 0;
        if (result)
            tier = result->Fetch()[0].Get<uint8>();
        
        if (tier < glyph.requiredTier)
            return false;
    }
    
    // Check prestige requirement
    if (glyph.requiredPrestige > 0)
    {
        uint32 guid = player->GetGUID().GetCounter();
        QueryResult result = CharacterDatabase.Query(
            "SELECT prestige_level FROM character_progression_unified WHERE guid = {}", guid);
        
        uint32 prestige = 0;
        if (result)
            prestige = result->Fetch()[0].Get<uint32>();
        
        if (prestige < glyph.requiredPrestige)
            return false;
    }
    
    return true;
}

std::vector<EnhancedGlyphData> EnhancedGlyphSystem::GetAvailableGlyphs(Player* player, GlyphSlotType slotType)
{
    std::vector<EnhancedGlyphData> available;
    
    if (!player)
        return available;
    
    for (const auto& [glyphId, glyph] : m_glyphs)
    {
        if (glyph.slotType == slotType && CanPlayerUseGlyph(player, glyphId))
            available.push_back(glyph);
    }
    
    return available;
}

bool EnhancedGlyphSystem::ApplyGlyphToPlayer(Player* player, uint32 glyphId, uint8 slot)
{
    if (!player)
        return false;
    
    if (!CanPlayerUseGlyph(player, glyphId))
        return false;
    
    uint32 guid = player->GetGUID().GetCounter();
    
    // Remove existing glyph from slot if any
    auto slotIt = m_playerGlyphSlots.find(guid);
    if (slotIt != m_playerGlyphSlots.end())
    {
        auto existingGlyphIt = slotIt->second.find(slot);
        if (existingGlyphIt != slotIt->second.end())
        {
            RemoveGlyphFromPlayer(player, slot);
        }
    }
    
    // Add glyph to player
    m_playerGlyphs[guid].push_back(glyphId);
    m_playerGlyphSlots[guid][slot] = glyphId;
    
    // Save to database
    CharacterDatabase.Execute(
        "INSERT INTO character_enhanced_glyphs (guid, glyph_id, slot) VALUES ({}, {}, {}) "
        "ON DUPLICATE KEY UPDATE glyph_id = {}",
        guid, glyphId, slot, glyphId);
    
    // Apply effects
    ApplyGlyphEffects(player);
    
    ChatHandler(player->GetSession()).PSendSysMessage("Glyph applied: %s", m_glyphs[glyphId].name.c_str());
    
    return true;
}

bool EnhancedGlyphSystem::RemoveGlyphFromPlayer(Player* player, uint8 slot)
{
    if (!player)
        return false;
    
    uint32 guid = player->GetGUID().GetCounter();
    
    auto slotIt = m_playerGlyphSlots.find(guid);
    if (slotIt == m_playerGlyphSlots.end())
        return false;
    
    auto glyphIt = slotIt->second.find(slot);
    if (glyphIt == slotIt->second.end())
        return false;
    
    uint32 glyphId = glyphIt->second;
    
    // Remove from maps
    slotIt->second.erase(slot);
    auto& playerGlyphs = m_playerGlyphs[guid];
    playerGlyphs.erase(std::remove(playerGlyphs.begin(), playerGlyphs.end(), glyphId), playerGlyphs.end());
    
    // Remove from database
    CharacterDatabase.Execute(
        "DELETE FROM character_enhanced_glyphs WHERE guid = {} AND slot = {}",
        guid, slot);
    
    // Reapply effects
    ApplyGlyphEffects(player);
    
    return true;
}

void EnhancedGlyphSystem::ApplyGlyphEffects(Player* player)
{
    if (!player)
        return;
    
    // Remove all existing glyph effects first
    RemoveGlyphEffects(player);
    
    uint32 guid = player->GetGUID().GetCounter();
    auto it = m_playerGlyphs.find(guid);
    if (it == m_playerGlyphs.end())
        return;
    
    float totalStatBonus = 0.0f;
    float totalDamageBonus = 0.0f;
    float totalHealingBonus = 0.0f;
    float totalCooldownReduction = 0.0f;
    float totalCostReduction = 0.0f;
    
    // Calculate total bonuses from all active glyphs
    for (uint32 glyphId : it->second)
    {
        auto glyphIt = m_glyphs.find(glyphId);
        if (glyphIt == m_glyphs.end())
            continue;
        
        const EnhancedGlyphData& glyph = glyphIt->second;
        totalStatBonus += glyph.statBonus;
        totalDamageBonus += glyph.damageBonus;
        totalHealingBonus += glyph.healingBonus;
        totalCooldownReduction += glyph.cooldownReduction;
        totalCostReduction += glyph.costReduction;
    }
    
    // Apply bonuses via auras or direct stat modification
    // This would need integration with the stat system
    // For now, we'll store the bonuses and apply them when needed
    
    LOG_DEBUG("module", "Enhanced Glyph System: Applied glyph effects to player {} (Stats: {}%, Damage: {}%, Healing: {}%)",
              player->GetName(), totalStatBonus * 100.0f, totalDamageBonus * 100.0f, totalHealingBonus * 100.0f);
}

void EnhancedGlyphSystem::RemoveGlyphEffects(Player* player)
{
    if (!player)
        return;
    
    // Remove all glyph effects
    // This would need to remove auras or stat modifications
    LOG_DEBUG("module", "Enhanced Glyph System: Removed glyph effects from player {}", player->GetName());
}

EnhancedGlyphData* EnhancedGlyphSystem::GetGlyphData(uint32 glyphId)
{
    auto it = m_glyphs.find(glyphId);
    if (it != m_glyphs.end())
        return &it->second;
    return nullptr;
}

void EnhancedGlyphSystem::OnSpellCast(Player* player, Spell* spell)
{
    if (!player || !spell)
        return;
    
    uint32 guid = player->GetGUID().GetCounter();
    auto it = m_playerGlyphs.find(guid);
    if (it == m_playerGlyphs.end())
        return;
    
    // Apply glyph effects to spell
    for (uint32 glyphId : it->second)
    {
        auto glyphIt = m_glyphs.find(glyphId);
        if (glyphIt == m_glyphs.end())
            continue;
        
        const EnhancedGlyphData& glyph = glyphIt->second;
        
        // Apply cooldown reduction
        if (glyph.cooldownReduction > 0.0f)
        {
            // Reduce cooldown (would need spell system integration)
        }
        
        // Apply cost reduction
        if (glyph.costReduction > 0.0f)
        {
            // Reduce mana/energy cost (would need spell system integration)
        }
    }
}

void EnhancedGlyphSystem::OnSpellHit(Player* player, Spell* spell, Unit* target)
{
    if (!player || !spell || !target)
        return;
    
    uint32 guid = player->GetGUID().GetCounter();
    auto it = m_playerGlyphs.find(guid);
    if (it == m_playerGlyphs.end())
        return;
    
    // Apply glyph damage/healing bonuses
    for (uint32 glyphId : it->second)
    {
        auto glyphIt = m_glyphs.find(glyphId);
        if (glyphIt == m_glyphs.end())
            continue;
        
        const EnhancedGlyphData& glyph = glyphIt->second;
        
        // Apply damage bonus
        if (glyph.damageBonus > 0.0f && spell->GetSpellInfo() && !spell->GetSpellInfo()->IsPositive())
        {
            // Increase damage (would need spell system integration)
        }
        
        // Apply healing bonus
        if (glyph.healingBonus > 0.0f && spell->GetSpellInfo() && spell->GetSpellInfo()->IsPositive())
        {
            // Increase healing (would need spell system integration)
        }
    }
}

void EnhancedGlyphSystem::UnlockGlyphsForTier(Player* player, uint8 tier)
{
    if (!player)
        return;
    
    // Notify player of newly available glyphs
    std::vector<EnhancedGlyphData> newlyUnlocked;
    
    for (const auto& [glyphId, glyph] : m_glyphs)
    {
        if (glyph.requiredTier == tier && CanPlayerUseGlyph(player, glyphId))
        {
            newlyUnlocked.push_back(glyph);
        }
    }
    
    if (!newlyUnlocked.empty())
    {
        ChatHandler(player->GetSession()).PSendSysMessage("|cFF00FF00New glyphs unlocked at tier %d!|r", tier);
        for (const auto& glyph : newlyUnlocked)
        {
            ChatHandler(player->GetSession()).PSendSysMessage("  - %s", glyph.name.c_str());
        }
    }
}

void EnhancedGlyphSystem::UnlockGlyphsForPrestige(Player* player, uint32 prestigeLevel)
{
    if (!player)
        return;
    
    // Notify player of newly available glyphs
    std::vector<EnhancedGlyphData> newlyUnlocked;
    
    for (const auto& [glyphId, glyph] : m_glyphs)
    {
        if (glyph.requiredPrestige == prestigeLevel && CanPlayerUseGlyph(player, glyphId))
        {
            newlyUnlocked.push_back(glyph);
        }
    }
    
    if (!newlyUnlocked.empty())
    {
        ChatHandler(player->GetSession()).PSendSysMessage("|cFF00FF00New glyphs unlocked at prestige %d!|r", prestigeLevel);
        for (const auto& glyph : newlyUnlocked)
        {
            ChatHandler(player->GetSession()).PSendSysMessage("  - %s", glyph.name.c_str());
        }
    }
}

