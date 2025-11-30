/*
 * Enhanced Gem System Implementation
 * Progressive gems with better stats and socket bonuses
 */

#include "EnhancedGemSystem.h"
#include "ProgressiveSystems.h"
#include "DatabaseEnv.h"
#include "Log.h"
#include "Chat.h"
#include "ObjectMgr.h"
#include "ItemTemplate.h"
#include "SpellMgr.h"
#include "DBCStores.h"

EnhancedGemSystem* EnhancedGemSystem::instance()
{
    static EnhancedGemSystem instance;
    return &instance;
}

void EnhancedGemSystem::Initialize()
{
    LOG_INFO("module", "Enhanced Gem System: Initializing...");
    LoadGems();
    LOG_INFO("module", "Enhanced Gem System: Initialized ({} gems loaded)", m_gems.size());
}

void EnhancedGemSystem::Shutdown()
{
    m_gems.clear();
    m_itemGems.clear();
    LOG_INFO("module", "Enhanced Gem System: Shutdown");
}

void EnhancedGemSystem::LoadGems()
{
    m_gems.clear();
    
    // Load from database
    QueryResult result = WorldDatabase.Query(
        "SELECT gem_id, item_entry, name, description, quality, type, required_level, "
        "required_tier, required_prestige, stat_bonus, stat_percent_bonus, "
        "socket_bonus_multiplier, is_active "
        "FROM enhanced_gems WHERE is_active = 1");
    
    if (result)
    {
        do
        {
            Field* fields = result->Fetch();
            EnhancedGemData gem;
            gem.gemId = fields[0].Get<uint32>();
            gem.itemEntry = fields[1].Get<uint32>();
            gem.name = fields[2].Get<std::string>();
            gem.description = fields[3].Get<std::string>();
            gem.quality = (GemQuality)fields[4].Get<uint8>();
            gem.type = (GemType)fields[5].Get<uint8>();
            gem.requiredLevel = fields[6].Get<uint32>();
            gem.requiredTier = fields[7].Get<uint32>();
            gem.requiredPrestige = fields[8].Get<uint32>();
            gem.statBonus = fields[9].Get<int32>();
            gem.statPercentBonus = fields[10].Get<float>();
            gem.socketBonusMultiplier = fields[11].Get<float>();
            gem.isActive = fields[12].Get<bool>();
            
            m_gems[gem.gemId] = gem;
        } while (result->NextRow());
        
        LOG_INFO("module", "Enhanced Gem System: Loaded {} gems", m_gems.size());
    }
    else
    {
        LOG_INFO("module", "Enhanced Gem System: No gems found in database. Creating default gems...");
        CreateDefaultGems();
    }
}

void EnhancedGemSystem::CreateDefaultGems()
{
    // Create default progressive gems
    EnhancedGemData gem;
    
    // Tier 1 Gems
    gem.gemId = 80001;
    gem.itemEntry = 80001;
    gem.name = "Progressive Gem of Strength";
    gem.description = "+20 Strength";
    gem.quality = GEM_QUALITY_RARE;
    gem.type = GEM_TYPE_RED;
    gem.requiredLevel = 80;
    gem.requiredTier = 1;
    gem.requiredPrestige = 0;
    gem.statBonus = 20;
    gem.statPercentBonus = 0.0f;
    gem.socketBonusMultiplier = 1.0f;
    gem.isActive = true;
    m_gems[gem.gemId] = gem;
    
    // Tier 5 Gems
    gem.gemId = 80002;
    gem.itemEntry = 80002;
    gem.name = "Elite Gem of Power";
    gem.description = "+50 Strength, +5% All Stats";
    gem.quality = GEM_QUALITY_EPIC;
    gem.type = GEM_TYPE_PRISMATIC;
    gem.requiredLevel = 80;
    gem.requiredTier = 5;
    gem.requiredPrestige = 0;
    gem.statBonus = 50;
    gem.statPercentBonus = 0.05f;
    gem.socketBonusMultiplier = 1.5f;
    gem.isActive = true;
    m_gems[gem.gemId] = gem;
    
    // Prestige Gems
    gem.gemId = 80003;
    gem.itemEntry = 80003;
    gem.name = "Legendary Gem of Mastery";
    gem.description = "+100 All Stats, +10% All Stats";
    gem.quality = GEM_QUALITY_LEGENDARY;
    gem.type = GEM_TYPE_PRISMATIC;
    gem.requiredLevel = 80;
    gem.requiredTier = 10;
    gem.requiredPrestige = 1;
    gem.statBonus = 100;
    gem.statPercentBonus = 0.10f;
    gem.socketBonusMultiplier = 2.0f;
    gem.isActive = true;
    m_gems[gem.gemId] = gem;
    
    LOG_INFO("module", "Enhanced Gem System: Created {} default gems", m_gems.size());
}

bool EnhancedGemSystem::CanPlayerUseGem(Player* player, uint32 gemId)
{
    if (!player)
        return false;
    
    auto it = m_gems.find(gemId);
    if (it == m_gems.end())
        return false;
    
    const EnhancedGemData& gem = it->second;
    
    // Check level requirement
    if (player->GetLevel() < gem.requiredLevel)
        return false;
    
    // Check tier requirement
    if (gem.requiredTier > 0)
    {
        uint32 guid = player->GetGUID().GetCounter();
        QueryResult result = CharacterDatabase.Query(
            "SELECT current_tier FROM character_progression_unified WHERE guid = {}", guid);
        
        uint8 tier = 0;
        if (result)
            tier = result->Fetch()[0].Get<uint8>();
        
        if (tier < gem.requiredTier)
            return false;
    }
    
    // Check prestige requirement
    if (gem.requiredPrestige > 0)
    {
        uint32 guid = player->GetGUID().GetCounter();
        QueryResult result = CharacterDatabase.Query(
            "SELECT prestige_level FROM character_progression_unified WHERE guid = {}", guid);
        
        uint32 prestige = 0;
        if (result)
            prestige = result->Fetch()[0].Get<uint32>();
        
        if (prestige < gem.requiredPrestige)
            return false;
    }
    
    return true;
}

std::vector<EnhancedGemData> EnhancedGemSystem::GetAvailableGems(Player* player, GemType gemType)
{
    std::vector<EnhancedGemData> available;
    
    if (!player)
        return available;
    
    for (const auto& [gemId, gem] : m_gems)
    {
        if ((gemType == GEM_TYPE_PRISMATIC || gem.type == gemType || gem.type == GEM_TYPE_PRISMATIC) 
            && CanPlayerUseGem(player, gemId))
            available.push_back(gem);
    }
    
    return available;
}

bool EnhancedGemSystem::ApplyGemToItem(Player* player, Item* item, uint32 gemId, uint8 socketSlot)
{
    if (!player || !item)
        return false;
    
    if (!CanPlayerUseGem(player, gemId))
        return false;
    
    auto it = m_gems.find(gemId);
    if (it == m_gems.end())
        return false;
    
    const EnhancedGemData& gem = it->second;
    
    // Check if item has socket at this slot
    ItemTemplate const* itemTemplate = item->GetTemplate();
    if (!itemTemplate)
        return false;
    
    if (socketSlot >= MAX_GEM_SOCKETS)
        return false;
    
    // Check socket color compatibility
    uint8 socketColor = itemTemplate->Socket[socketSlot].Color;
    if (socketColor && !(gem.type & socketColor) && gem.type != GEM_TYPE_PRISMATIC)
        return false;
    
    // Apply gem (this would use the existing socket system)
    // For now, we track it in our system
    uint64 itemGuid = item->GetGUID().GetCounter();
    m_itemGems[itemGuid][socketSlot] = gemId;
    
    // Save to database
    CharacterDatabase.Execute(
        "INSERT INTO character_item_gems (item_guid, socket_slot, gem_id) VALUES ({}, {}, {}) "
        "ON DUPLICATE KEY UPDATE gem_id = {}",
        itemGuid, socketSlot, gemId, gemId);
    
    // Recalculate socket bonus
    std::vector<uint32> gemIds;
    for (const auto& [slot, id] : m_itemGems[itemGuid])
        gemIds.push_back(id);
    
    int32 socketBonus = CalculateSocketBonus(item, gemIds);
    
    ChatHandler(player->GetSession()).PSendSysMessage("Gem applied: %s (Socket Bonus: +%d)", 
                                                       gem.name.c_str(), socketBonus);
    
    return true;
}

bool EnhancedGemSystem::RemoveGemFromItem(Player* player, Item* item, uint8 socketSlot)
{
    if (!player || !item)
        return false;
    
    uint64 itemGuid = item->GetGUID().GetCounter();
    auto it = m_itemGems.find(itemGuid);
    if (it == m_itemGems.end())
        return false;
    
    auto gemIt = it->second.find(socketSlot);
    if (gemIt == it->second.end())
        return false;
    
    // Remove from map
    it->second.erase(socketSlot);
    
    // Remove from database
    CharacterDatabase.Execute(
        "DELETE FROM character_item_gems WHERE item_guid = {} AND socket_slot = {}",
        itemGuid, socketSlot);
    
    return true;
}

int32 EnhancedGemSystem::CalculateSocketBonus(Item* item, const std::vector<uint32>& gemIds)
{
    if (!item || gemIds.empty())
        return 0;
    
    ItemTemplate const* itemTemplate = item->GetTemplate();
    if (!itemTemplate || !itemTemplate->socketBonus)
        return 0;
    
    // Get base socket bonus
    int32 baseBonus = 0;
    SpellItemEnchantmentEntry const* enchant = sSpellItemEnchantmentStore.LookupEntry(itemTemplate->socketBonus);
    if (enchant)
    {
        // Extract stat bonus from enchant
        for (uint8 i = 0; i < MAX_SPELL_ITEM_ENCHANTMENT_EFFECTS; ++i)
        {
            if (enchant->type[i] == ITEM_ENCHANTMENT_TYPE_STAT)
                baseBonus += enchant->amount[i];
        }
    }
    
    // Apply gem multipliers
    float totalMultiplier = 1.0f;
    for (uint32 gemId : gemIds)
    {
        auto it = m_gems.find(gemId);
        if (it != m_gems.end())
        {
            // Additive multiplier stacking
            totalMultiplier += (it->second.socketBonusMultiplier - 1.0f);
        }
    }
    
    return static_cast<int32>(baseBonus * totalMultiplier);
}

EnhancedGemData* EnhancedGemSystem::GetGemData(uint32 gemId)
{
    auto it = m_gems.find(gemId);
    if (it != m_gems.end())
        return &it->second;
    return nullptr;
}

void EnhancedGemSystem::UnlockGemsForTier(Player* player, uint8 tier)
{
    if (!player)
        return;
    
    std::vector<EnhancedGemData> newlyUnlocked;
    
    for (const auto& [gemId, gem] : m_gems)
    {
        if (gem.requiredTier == tier && CanPlayerUseGem(player, gemId))
            newlyUnlocked.push_back(gem);
    }
    
    if (!newlyUnlocked.empty())
    {
        ChatHandler(player->GetSession()).PSendSysMessage("|cFF00FF00New gems unlocked at tier %d!|r", tier);
        for (const auto& gem : newlyUnlocked)
            ChatHandler(player->GetSession()).PSendSysMessage("  - %s", gem.name.c_str());
    }
}

void EnhancedGemSystem::UnlockGemsForPrestige(Player* player, uint32 prestigeLevel)
{
    if (!player)
        return;
    
    std::vector<EnhancedGemData> newlyUnlocked;
    
    for (const auto& [gemId, gem] : m_gems)
    {
        if (gem.requiredPrestige == prestigeLevel && CanPlayerUseGem(player, gemId))
            newlyUnlocked.push_back(gem);
    }
    
    if (!newlyUnlocked.empty())
    {
        ChatHandler(player->GetSession()).PSendSysMessage("|cFF00FF00New gems unlocked at prestige %d!|r", prestigeLevel);
        for (const auto& gem : newlyUnlocked)
            ChatHandler(player->GetSession()).PSendSysMessage("  - %s", gem.name.c_str());
    }
}

Item* EnhancedGemSystem::GenerateProgressiveGem(Player* player, GemQuality quality, GemType type)
{
    if (!player)
        return nullptr;
    
    // Find a gem matching the criteria
    for (const auto& [gemId, gem] : m_gems)
    {
        if (gem.quality == quality && gem.type == type && CanPlayerUseGem(player, gemId))
        {
            ItemTemplate const* itemTemplate = sObjectMgr->GetItemTemplate(gem.itemEntry);
            if (itemTemplate)
            {
                Item* item = Item::CreateItem(gem.itemEntry, 1, player);
                return item;
            }
        }
    }
    
    return nullptr;
}

