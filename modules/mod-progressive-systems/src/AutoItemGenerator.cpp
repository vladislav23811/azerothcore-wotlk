/*
 * Automatic Item Generator Implementation
 * Generates items dynamically based on difficulty, tier, boss, etc.
 */

#include "AutoItemGenerator.h"
#include "DatabaseEnv.h"
#include "ObjectMgr.h"
#include "Item.h"
#include "Log.h"
#include "Chat.h"
#include <sstream>
#include <random>

AutoItemGenerator* AutoItemGenerator::instance()
{
    static AutoItemGenerator instance;
    return &instance;
}

void AutoItemGenerator::Initialize()
{
    LOG_INFO("module", "Initializing Auto Item Generator...");
    LoadRules();
    LOG_INFO("module", "Auto Item Generator initialized with {} rules", m_rules.size());
}

void AutoItemGenerator::LoadRules()
{
    m_rules.clear();
    
    QueryResult result = WorldDatabase.Query(
        "SELECT rule_id, base_item_entry, difficulty_tier, progression_tier, boss_entry, map_id, "
        "stat_multiplier, ilvl_bonus, quality_bonus, allow_random_enchant, allow_socket, "
        "min_sockets, max_sockets, drop_chance, name_prefix, name_suffix, description "
        "FROM auto_item_rules WHERE active = 1 ORDER BY sort_order");
    
    if (result)
    {
        do
        {
            Field* fields = result->Fetch();
            ItemGenerationRule rule;
            
            rule.baseItemEntry = fields[1].Get<uint32>();
            rule.difficultyTier = fields[2].Get<uint8>();
            rule.progressionTier = fields[3].Get<uint8>();
            rule.bossEntry = fields[4].Get<uint32>();
            rule.mapId = fields[5].Get<uint32>();
            rule.statMultiplier = fields[6].Get<float>();
            rule.ilvlBonus = fields[7].Get<uint32>();
            rule.qualityBonus = fields[8].Get<uint8>();
            rule.allowRandomEnchant = fields[9].Get<bool>();
            rule.allowSocket = fields[10].Get<bool>();
            rule.minSockets = fields[11].Get<uint8>();
            rule.maxSockets = fields[12].Get<uint8>();
            rule.dropChance = fields[13].Get<float>();
            
            if (!fields[14].IsNull())
                rule.namePrefix = fields[14].Get<std::string>();
            if (!fields[15].IsNull())
                rule.nameSuffix = fields[15].Get<std::string>();
            if (!fields[16].IsNull())
                rule.description = fields[16].Get<std::string>();
            
            m_rules.push_back(rule);
        } while (result->NextRow());
    }
}

Item* AutoItemGenerator::GenerateItem(Player* player, Creature* boss, uint32 difficultyTier, uint32 progressionTier)
{
    if (!player || !boss)
        return nullptr;
    
    uint32 bossEntry = boss->GetEntry();
    uint32 mapId = boss->GetMapId();
    
    // Get matching rules
    auto rules = GetRulesForContext(difficultyTier, progressionTier, bossEntry, mapId);
    
    if (rules.empty())
        return nullptr;
    
    // Select random rule (weighted by drop chance)
    std::random_device rd;
    std::mt19937 gen(rd());
    std::discrete_distribution<> dist(rules.size(), 0.0, 1.0,
        [&rules](size_t i) { return rules[i].dropChance; });
    
    size_t selectedIndex = dist(gen);
    const ItemGenerationRule& rule = rules[selectedIndex];
    
    // Generate item
    return GenerateItemFromRule(player, rule);
}

Item* AutoItemGenerator::GenerateItemFromRule(Player* player, const ItemGenerationRule& rule)
{
    if (!player)
        return nullptr;
    
    // IMPORTANT: Get base item template - this MUST be an existing item with an icon
    ItemTemplate const* baseTemplate = sObjectMgr->GetItemTemplate(rule.baseItemEntry);
    if (!baseTemplate)
    {
        LOG_ERROR("module", "AutoItemGenerator: Base item {} not found! Cannot generate item without base template.", rule.baseItemEntry);
        return nullptr;
    }
    
    // Verify the base item has a display ID (icon)
    if (baseTemplate->DisplayInfoID == 0)
    {
        LOG_WARN("module", "AutoItemGenerator: Base item {} has no DisplayInfoID! Icon may not display. Consider using a different base item.", rule.baseItemEntry);
    }
    
    // Create generated item data
    GeneratedItemData data;
    data.itemEntry = rule.baseItemEntry;
    data.itemLevel = baseTemplate->ItemLevel + rule.ilvlBonus;
    data.quality = std::min(static_cast<uint32>(ITEM_QUALITY_LEGENDARY), 
                           baseTemplate->Quality + rule.qualityBonus);
    
    // Calculate stat modifiers
    // Scale base stats by multiplier
    for (uint8 i = 0; i < MAX_ITEM_PROTO_STATS; ++i)
    {
        if (baseTemplate->ItemStat[i].ItemStatValue > 0)
        {
            uint32 statType = baseTemplate->ItemStat[i].ItemStatType;
            int32 statValue = static_cast<int32>(baseTemplate->ItemStat[i].ItemStatValue * rule.statMultiplier);
            data.statModifiers[statType] = statValue;
        }
    }
    
    // Generate name
    data.customName = GenerateItemName(rule.baseItemEntry, rule, data.quality);
    
    // Generate description
    data.customDescription = GenerateItemDescription(rule, data);
    
    // Create item
    return CreateItemWithStats(player, rule.baseItemEntry, data);
}

Item* AutoItemGenerator::CreateItemWithStats(Player* player, uint32 baseItemEntry, const GeneratedItemData& data)
{
    if (!player)
        return nullptr;
    
    // IMPORTANT: Always use existing item entries to preserve icons!
    // The baseItemEntry must be a valid item from item_template that has an icon in ItemDisplayInfo.dbc
    ItemTemplate const* baseTemplate = sObjectMgr->GetItemTemplate(baseItemEntry);
    if (!baseTemplate)
    {
        LOG_ERROR("module", "AutoItemGenerator: Base item {} not found! Cannot create item without icon.", baseItemEntry);
        return nullptr;
    }
    
    // Verify the item has a display ID (icon)
    if (baseTemplate->DisplayInfoID == 0)
    {
        LOG_WARN("module", "AutoItemGenerator: Base item {} has no DisplayInfoID! Icon may not display.", baseItemEntry);
    }
    
    // Create base item (this preserves the icon from DisplayInfoID)
    Item* item = Item::CreateItem(baseItemEntry, 1, player);
    if (!item)
        return nullptr;
    
    // Apply stat modifiers via enchantments (this preserves the base item's icon)
    ApplyStatModifiers(item, data.statModifiers);
    
    // Apply enchantments if allowed
    if (!data.enchantments.empty())
    {
        ApplyEnchantments(item, data.enchantments);
    }
    
    // Apply sockets
    if (data.sockets.size() > 0)
    {
        // Sockets already set in data
    }
    
    // Set custom name if provided (this doesn't affect the icon)
    // Note: Item::SetCustomName() doesn't exist in AzerothCore
    // Custom names would need to be stored separately or use item_template modifications
    // if (!data.customName.empty())
    // {
    //     item->SetCustomName(data.customName);
    // }
    
    // Store generation data in item's dynamic data for reference
    // This allows us to track that it's a generated item while keeping the base icon
    
    LOG_DEBUG("module", "AutoItemGenerator: Created item {} (base: {}) with icon DisplayInfoID: {}", 
              data.customName.empty() ? baseTemplate->Name1 : data.customName, 
              baseItemEntry, baseTemplate->DisplayInfoID);
    
    return item;
}

void AutoItemGenerator::ApplyStatModifiers(Item* item, const std::map<uint32, int32>& modifiers)
{
    if (!item || modifiers.empty())
        return;
    
    // IMPORTANT: We use enchantments to modify stats while preserving the base item's icon
    // This way, the item keeps its original DisplayInfoID (icon) but gets enhanced stats
    
    ItemTemplate const* itemTemplate = item->GetTemplate();
    if (!itemTemplate)
        return;
    
    // Find or create enchantments that add the desired stats
    // We'll use existing enchantment IDs that add stats, or create custom ones
    // For now, we'll apply stat bonuses via enchantments
    
    // Note: In a full implementation, you would:
    // 1. Look up enchantments that add the desired stat types
    // 2. Apply them to the item in available enchantment slots
    // 3. Or use item bonuses/modifiers if the system supports it
    
    // Example: Apply stat bonuses via temporary enchantments
    // This preserves the base item icon while adding stats
    for (const auto& [statType, statValue] : modifiers)
    {
        if (statValue <= 0)
            continue;
        
        // Find an enchantment that adds this stat type
        // For now, we'll log it - full implementation would apply enchantments
        LOG_DEBUG("module", "AutoItemGenerator: Would apply stat modifier: StatType={}, Value={} to item {}",
                  statType, statValue, item->GetEntry());
        
        // TODO: Apply enchantment here
        // Example: item->SetEnchantment(ENCHANTMENT_SLOT_TEMP, enchantId, 0, 0, player->GetGUID());
    }
    
    // Alternative: Use item bonuses if the system supports it
    // This is the preferred method as it doesn't consume enchantment slots
}

void AutoItemGenerator::ApplyEnchantments(Item* item, const std::vector<uint32>& enchantments)
{
    if (!item)
        return;
    
    for (uint32 enchantId : enchantments)
    {
        // Apply enchantment to item
        // This would need integration with enchantment system
    }
}

void AutoItemGenerator::ApplySockets(Item* item, uint32 minSockets, uint32 maxSockets)
{
    if (!item)
        return;
    
    // Generate random number of sockets
    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_int_distribution<> dis(minSockets, maxSockets);
    uint32 socketCount = dis(gen);
    
    // Apply sockets to item
    // This would need integration with gem socket system
}

std::string AutoItemGenerator::GenerateItemName(uint32 baseItemEntry, const ItemGenerationRule& rule, uint32 quality)
{
    ItemTemplate const* template_ = sObjectMgr->GetItemTemplate(baseItemEntry);
    if (!template_)
        return "";
    
    std::string baseName = template_->Name1;
    
    std::ostringstream name;
    
    // Add prefix
    if (!rule.namePrefix.empty())
        name << rule.namePrefix << " ";
    
    name << baseName;
    
    // Add suffix
    if (!rule.nameSuffix.empty())
        name << " " << rule.nameSuffix;
    
    // Add tier suffix
    if (rule.difficultyTier > 0)
    {
        name << " (Tier " << static_cast<int>(rule.difficultyTier) << ")";
    }
    
    return name.str();
}

std::string AutoItemGenerator::GenerateItemDescription(const ItemGenerationRule& rule, const GeneratedItemData& data)
{
    std::ostringstream desc;
    
    if (!rule.description.empty())
        desc << rule.description << "\n\n";
    
    desc << "Generated for Difficulty Tier " << static_cast<int>(rule.difficultyTier) << "\n";
    desc << "Progression Tier " << static_cast<int>(rule.progressionTier) << "\n";
    desc << "Item Level: " << data.itemLevel;
    
    return desc.str();
}

std::vector<ItemGenerationRule> AutoItemGenerator::GetRulesForContext(
    uint32 difficultyTier, uint32 progressionTier, uint32 bossEntry, uint32 mapId)
{
    std::vector<ItemGenerationRule> matchingRules;
    
    for (const auto& rule : m_rules)
    {
        // Check if rule matches context
        bool matches = true;
        
        // Check difficulty tier
        if (rule.difficultyTier != 0 && rule.difficultyTier != difficultyTier)
            matches = false;
        
        // Check progression tier
        if (rule.progressionTier != 0 && rule.progressionTier != progressionTier)
            matches = false;
        
        // Check boss entry
        if (rule.bossEntry != 0 && rule.bossEntry != bossEntry)
            matches = false;
        
        // Check map ID
        if (rule.mapId != 0 && rule.mapId != mapId)
            matches = false;
        
        if (matches)
            matchingRules.push_back(rule);
    }
    
    return matchingRules;
}

void AutoItemGenerator::RegisterRule(const ItemGenerationRule& rule)
{
    m_rules.push_back(rule);
    
    // Also save to database
    WorldDatabase.Execute(
        "INSERT INTO auto_item_rules (base_item_entry, difficulty_tier, progression_tier, boss_entry, map_id, "
        "stat_multiplier, ilvl_bonus, quality_bonus, allow_random_enchant, allow_socket, min_sockets, max_sockets, "
        "drop_chance, name_prefix, name_suffix, description, active) "
        "VALUES ({}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, '{}', '{}', '{}', 1)",
        rule.baseItemEntry, rule.difficultyTier, rule.progressionTier, rule.bossEntry, rule.mapId,
        rule.statMultiplier, rule.ilvlBonus, rule.qualityBonus, rule.allowRandomEnchant, rule.allowSocket,
        rule.minSockets, rule.maxSockets, rule.dropChance, rule.namePrefix, rule.nameSuffix, rule.description);
}

const char* AutoItemGenerator::s_qualityNames[] = {
    "Poor", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Artifact"
};

const char* AutoItemGenerator::s_tierNames[] = {
    "Normal", "Heroic", "Mythic+1", "Mythic+2", "Mythic+3", "Mythic+4", "Mythic+5"
};

