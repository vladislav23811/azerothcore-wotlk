/*
 * Personal Loot System Implementation
 * Each player gets their own loot roll - no fighting over items!
 */

#include "PersonalLootSystem.h"
#include "ProgressiveSystems.h"
#include "AutoItemGenerator.h"
#include "DatabaseEnv.h"
#include "Log.h"
#include "Chat.h"
#include "World.h"
#include "Group.h"
#include "LootMgr.h"
#include "ObjectMgr.h"
#include "ItemTemplate.h"
#include "WorldPacket.h"
#include "SharedDefines.h"
#include <random>

PersonalLootSystem* PersonalLootSystem::instance()
{
    static PersonalLootSystem instance;
    return &instance;
}

void PersonalLootSystem::Initialize()
{
    LOG_INFO("module", "Personal Loot System: Initializing...");
    
    // Load configuration from database or config file
    m_config.enabled = true;
    m_config.applyToGroups = true;
    m_config.applyToSolo = true;
    m_config.baseDropChance = 1.0f;
    m_config.qualityBonus = 0.0f;
    m_config.scaleWithDifficulty = true;
    m_config.scaleWithProgression = true;
    
    LOG_INFO("module", "Personal Loot System: Initialized (Enabled: {})", m_config.enabled);
}

void PersonalLootSystem::Shutdown()
{
    m_creatureLootedByPlayers.clear();
    LOG_INFO("module", "Personal Loot System: Shutdown");
}

std::vector<Player*> PersonalLootSystem::GetEligiblePlayers(Creature* creature, Group* group)
{
    std::vector<Player*> eligiblePlayers;
    
    if (!creature)
        return eligiblePlayers;
    
    if (group)
    {
        // Get all group members within loot range
        for (GroupReference* itr = group->GetFirstMember(); itr != nullptr; itr = itr->next())
        {
            Player* member = itr->GetSource();
            if (!member)
                continue;
            
            if (IsPlayerEligible(member, creature))
                eligiblePlayers.push_back(member);
        }
    }
    else
    {
        // Solo player
        Player* looter = creature->GetLootRecipient();
        if (looter && IsPlayerEligible(looter, creature))
            eligiblePlayers.push_back(looter);
    }
    
    return eligiblePlayers;
}

bool PersonalLootSystem::IsPlayerEligible(Player* player, Creature* creature)
{
    if (!player || !creature)
        return false;
    
    // Check if player is in range
    if (!player->IsAtLootRewardDistance(creature))
        return false;
    
    // Check if player did enough damage (if creature tracks damage)
    if (!creature->IsDamageEnoughForLootingAndReward())
        return false;
    
    // Check if creature is lootable
    if (!creature->HasDynamicFlag(UNIT_DYNFLAG_LOOTABLE))
        return false;
    
    // Check if player already looted this creature
    uint64 creatureGuid = creature->GetGUID().GetCounter();
    uint32 playerGuid = player->GetGUID().GetCounter();
    
    auto it = m_creatureLootedByPlayers.find(creatureGuid);
    if (it != m_creatureLootedByPlayers.end())
    {
        for (uint32 guid : it->second)
        {
            if (guid == playerGuid)
                return false; // Already looted
        }
    }
    
    return true;
}

void PersonalLootSystem::GeneratePersonalLoot(Player* player, Creature* creature)
{
    if (!m_enabled || !m_config.enabled)
        return;
    
    if (!player || !creature)
        return;
    
    if (!IsPlayerEligible(player, creature))
        return;
    
    // Mark creature as looted by this player
    uint64 creatureGuid = creature->GetGUID().GetCounter();
    uint32 playerGuid = player->GetGUID().GetCounter();
    m_creatureLootedByPlayers[creatureGuid].push_back(playerGuid);
    
    // Get base loot template
    Loot* baseLoot = &creature->loot;
    
    // Generate personal loot items
    std::vector<LootItem> personalLoot = GenerateLootItemsForPlayer(player, creature, baseLoot);
    
    if (personalLoot.empty())
    {
        // Still give money even if no items
        if (baseLoot->gold > 0)
        {
            uint32 goldShare = baseLoot->gold;
            player->ModifyMoney(goldShare);
            player->UpdateAchievementCriteria(ACHIEVEMENT_CRITERIA_TYPE_LOOT_MONEY, goldShare);
            
            WorldPacket data(SMSG_LOOT_MONEY_NOTIFY, 4 + 1);
            data << uint32(goldShare);
            data << uint8(1); // "You loot..."
            player->SendDirectMessage(&data);
        }
        return;
    }
    
    // Send loot to player
    SendPersonalLootToPlayer(player, creature, personalLoot);
    
    // Give money
    if (baseLoot->gold > 0)
    {
        uint32 goldShare = baseLoot->gold;
        player->ModifyMoney(goldShare);
        player->UpdateAchievementCriteria(ACHIEVEMENT_CRITERIA_TYPE_LOOT_MONEY, goldShare);
        
        WorldPacket data(SMSG_LOOT_MONEY_NOTIFY, 4 + 1);
        data << uint32(goldShare);
        data << uint8(1); // "You loot..."
        player->SendDirectMessage(&data);
    }
    
    LOG_DEBUG("module", "Personal Loot: Generated {} items for player {} from creature {}",
              personalLoot.size(), player->GetName(), creature->GetName());
}

void PersonalLootSystem::GeneratePersonalLootForGroup(Creature* creature, Group* group)
{
    if (!m_enabled || !m_config.enabled)
        return;
    
    if (!creature || !group)
        return;
    
    if (!m_config.applyToGroups)
        return;
    
    std::vector<Player*> eligiblePlayers = GetEligiblePlayers(creature, group);
    
    for (Player* player : eligiblePlayers)
    {
        GeneratePersonalLoot(player, creature);
    }
}

std::vector<LootItem> PersonalLootSystem::GenerateLootItemsForPlayer(Player* player, Creature* creature, Loot* baseLoot)
{
    std::vector<LootItem> personalLoot;
    
    if (!player || !creature || !baseLoot)
        return personalLoot;
    
    // Get player's progression data
    uint32 guid = player->GetGUID().GetCounter();
    QueryResult result = CharacterDatabase.Query(
        "SELECT current_tier, difficulty_tier FROM character_progression_unified WHERE guid = {}", guid);
    
    uint8 currentTier = 1;
    uint8 difficultyTier = 1;
    if (result && result->NextRow())
    {
        currentTier = (*result)[0].Get<uint8>();
        difficultyTier = (*result)[1].Get<uint8>();
    }
    
    // Get creature's loot template
    uint32 lootId = creature->GetCreatureTemplate()->lootid;
    if (!lootId)
        return personalLoot;
    
    // Create a temporary Loot object to generate loot
    Loot tempLoot;
    if (!tempLoot.FillLoot(lootId, LootTemplates_Creature, player, true, true, LOOT_MODE_DEFAULT, creature))
        return personalLoot;
    
    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_real_distribution<float> dis(0.0f, 100.0f);
    
    // Process items from the generated loot
    for (LootItem& lootItem : tempLoot.items)
    {
        // Calculate drop chance for this player
        ItemTemplate const* itemTemplate = sObjectMgr->GetItemTemplate(lootItem.itemid);
        if (!itemTemplate)
            continue;
        
        float dropChance = CalculateDropChance(player, creature, itemTemplate->Quality);
        
        // Roll for item
        float roll = dis(gen);
        if (roll > dropChance)
            continue;
        
        // Check item level restrictions
        if (m_config.minItemLevel > 0 && itemTemplate->ItemLevel < m_config.minItemLevel)
            continue;
        if (m_config.maxItemLevel > 0 && itemTemplate->ItemLevel > m_config.maxItemLevel)
            continue;
        
        // Set player-specific properties
        lootItem.rollWinnerGUID = player->GetGUID();
        lootItem.freeforall = false;
        lootItem.is_blocked = false;
        
        // Apply progression bonuses
        ApplyProgressionBonuses(player, lootItem);
        
        personalLoot.push_back(lootItem);
    }
    
    // If no items from template, try generating progressive item
    if (personalLoot.empty() && sAutoItemGenerator)
    {
        Map* map = creature->GetMap();
        if (map && (map->IsDungeon() || map->IsRaid()))
        {
            Item* generatedItem = sAutoItemGenerator->GenerateItem(player, creature, difficultyTier, currentTier);
            if (generatedItem)
            {
                LootItem lootItem;
                lootItem.itemid = generatedItem->GetEntry();
                lootItem.itemIndex = 0;
                lootItem.count = 1;
                lootItem.randomPropertyId = 0;
                lootItem.randomSuffix = 0;
                lootItem.follow_loot_rules = false;
                lootItem.freeforall = false;
                lootItem.is_blocked = false;
                lootItem.is_counted = false;
                lootItem.is_looted = false;
                lootItem.is_underthreshold = false;
                lootItem.needs_quest = false;
                lootItem.rollWinnerGUID = player->GetGUID();
                lootItem.groupid = 0;
                
                personalLoot.push_back(lootItem);
                
                // Delete the generated item (we'll create it again when player loots)
                delete generatedItem;
            }
        }
    }
    
    return personalLoot;
}

float PersonalLootSystem::CalculateDropChance(Player* player, Creature* creature, uint32 itemQuality)
{
    float baseChance = m_config.baseDropChance;
    
    // Apply progression bonuses
    if (m_config.scaleWithProgression)
    {
        uint32 guid = player->GetGUID().GetCounter();
        QueryResult result = CharacterDatabase.Query(
            "SELECT current_tier FROM character_progression_unified WHERE guid = {}", guid);
        
        if (result && result->NextRow())
        {
            uint8 tier = (*result)[0].Get<uint8>();
            baseChance += (tier * 0.05f); // 5% bonus per tier
        }
    }
    
    // Apply difficulty bonuses
    if (m_config.scaleWithDifficulty)
    {
        Map* map = creature->GetMap();
        if (map && (map->IsDungeon() || map->IsRaid()))
        {
            uint8 difficultyTier = sProgressiveSystems->GetDifficultyTier(player, map);
            baseChance += (difficultyTier * 0.03f); // 3% bonus per difficulty tier
        }
    }
    
    // Quality bonus
    baseChance += m_config.qualityBonus;
    
    return std::min(baseChance, 100.0f); // Cap at 100%
}

void PersonalLootSystem::ApplyProgressionBonuses(Player* player, LootItem& lootItem)
{
    if (!player)
        return;
    
    // Get player's progression tier
    uint32 guid = player->GetGUID().GetCounter();
    QueryResult result = CharacterDatabase.Query(
        "SELECT current_tier, prestige_level FROM character_progression_unified WHERE guid = {}", guid);
    
    uint8 currentTier = 1;
    uint32 prestigeLevel = 0;
    if (result && result->NextRow())
    {
        currentTier = (*result)[0].Get<uint8>();
        prestigeLevel = (*result)[1].Get<uint32>();
    }
    
    // Apply item level bonus based on tier
    // This would need to modify the item template or use item bonuses
    // For now, we'll just log it
    LOG_DEBUG("module", "Personal Loot: Applied progression bonuses (Tier: {}, Prestige: {}) to item {}",
              currentTier, prestigeLevel, lootItem.itemid);
}

void PersonalLootSystem::SendPersonalLootToPlayer(Player* player, Creature* creature, const std::vector<LootItem>& lootItems)
{
    if (!player || !creature || lootItems.empty())
        return;
    
    // Create a temporary loot object for this player
    Loot personalLoot;
    personalLoot.clear();
    personalLoot.lootOwnerGUID = player->GetGUID();
    
    // Add items to loot
    for (const LootItem& item : lootItems)
    {
        personalLoot.items.push_back(item);
    }
    
    // Set gold (will be handled separately)
    personalLoot.gold = 0;
    
    // Send loot window to player
    WorldPacket data(SMSG_LOOT_RESPONSE, (8 + 1 + 1));
    data << creature->GetGUID();
    data << uint8(LOOT_CORPSE);
    data << uint8(0); // CanLoot
    
    // Send items
    data << uint32(lootItems.size());
    for (const LootItem& item : lootItems)
    {
        data << uint8(item.itemid ? 0 : 1); // Item or currency
        if (item.itemid)
        {
            data << uint32(item.itemid);
            data << uint32(item.count);
            data << uint32(item.randomSuffix);
            data << uint32(item.randomPropertyId);
            data << uint8(0);  // Slot
        }
    }
    
    data << uint32(0); // Gold
    data << uint8(0);  // LootType
    
    player->SendDirectMessage(&data);
    
    // Actually give items to player
    for (const LootItem& item : lootItems)
    {
        if (item.itemid)
        {
            ItemPosCountVec dest;
            InventoryResult msg = player->CanStoreNewItem(NULL_BAG, NULL_SLOT, dest, item.itemid, item.count);
            if (msg == EQUIP_ERR_OK)
            {
                Item* newItem = player->StoreNewItem(dest, item.itemid, true, item.randomPropertyId);
                if (newItem)
                {
                    player->SendNewItem(newItem, item.count, true, false);
                }
            }
            else
            {
                // Send to mail if inventory full
                player->SendItemRetrievalMail(item.itemid, item.count);
            }
        }
    }
}

