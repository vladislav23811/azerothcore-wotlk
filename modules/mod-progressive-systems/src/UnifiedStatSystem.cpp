/*
 * Unified Stat System Implementation
 * Modern, modular stat system
 */

#include "UnifiedStatSystem.h"
#include "DatabaseEnv.h"
#include "Log.h"
#include "Chat.h"
#include "Item.h"
#include "ItemTemplate.h"
#include "Config.h"
#include "SharedDefines.h"
#include <sstream>
#include <iomanip>
#include <algorithm>

UnifiedStatSystem* UnifiedStatSystem::instance()
{
    static UnifiedStatSystem instance;
    return &instance;
}

void UnifiedStatSystem::Initialize()
{
    LOG_INFO("module", "Initializing Unified Stat System...");
    
    // Register default stat displays
    RegisterStatDisplay(StatType::STRENGTH, "Strength", "INV_Shield_02");
    RegisterStatDisplay(StatType::AGILITY, "Agility", "INV_Boots_Chain_04");
    RegisterStatDisplay(StatType::STAMINA, "Stamina", "INV_Chest_Chain_15");
    RegisterStatDisplay(StatType::INTELLECT, "Intellect", "INV_Helmet_15");
    RegisterStatDisplay(StatType::SPIRIT, "Spirit", "INV_Jewelry_Amulet_01");
    
    RegisterStatDisplay(StatType::ATTACK_POWER, "Attack Power", "INV_Sword_04");
    RegisterStatDisplay(StatType::SPELL_POWER, "Spell Power", "INV_Staff_01");
    RegisterStatDisplay(StatType::CRITICAL_STRIKE, "Critical Strike", "INV_Weapon_ShortBlade_05");
    RegisterStatDisplay(StatType::HASTE, "Haste", "INV_Bracer_07");
    RegisterStatDisplay(StatType::MASTERY, "Mastery", "INV_Jewelry_Ring_01");
    
    RegisterStatDisplay(StatType::ARMOR, "Armor", "INV_Chest_Plate16");
    RegisterStatDisplay(StatType::HEALTH, "Health", "INV_Potion_93");
    RegisterStatDisplay(StatType::MOVEMENT_SPEED, "Movement Speed", "INV_Boots_08");
    
    LOG_INFO("module", "Unified Stat System initialized.");
}

void UnifiedStatSystem::Shutdown()
{
    m_statModifiers.clear();
    m_statDisplayInfo.clear();
}

float UnifiedStatSystem::GetStatValue(Player* player, StatType statType)
{
    if (!player)
        return 0.0f;
    
    StatBreakdown breakdown = GetStatBreakdown(player, statType);
    return CalculateStatValue(player, statType, breakdown);
}

UnifiedStatSystem::StatBreakdown UnifiedStatSystem::GetStatBreakdown(Player* player, StatType statType)
{
    StatBreakdown breakdown;
    
    if (!player)
        return breakdown;
    
    uint32 guid = player->GetGUID().GetCounter();
    
    // Get base value
    switch (statType)
    {
        case StatType::STRENGTH:
            breakdown.baseValue = player->GetStat(STAT_STRENGTH);
            break;
        case StatType::AGILITY:
            breakdown.baseValue = player->GetStat(STAT_AGILITY);
            break;
        case StatType::STAMINA:
            breakdown.baseValue = player->GetStat(STAT_STAMINA);
            break;
        case StatType::INTELLECT:
            breakdown.baseValue = player->GetStat(STAT_INTELLECT);
            break;
        case StatType::SPIRIT:
            breakdown.baseValue = player->GetStat(STAT_SPIRIT);
            break;
        case StatType::ATTACK_POWER:
            breakdown.baseValue = player->GetTotalAttackPowerValue(BASE_ATTACK);
            break;
        case StatType::SPELL_POWER:
            breakdown.baseValue = player->GetBaseSpellPowerBonus();
            break;
        case StatType::HEALTH:
            breakdown.baseValue = player->GetMaxHealth();
            break;
        case StatType::ARMOR:
            breakdown.baseValue = player->GetArmor();
            break;
        default:
            breakdown.baseValue = 0.0f;
            break;
    }
    
    // Get modifiers from all sources
    auto& modifiers = m_statModifiers[guid][statType];
    
    for (const auto& mod : modifiers)
    {
        float value = mod.flatValue;
        
        switch (mod.source)
        {
            case StatSource::EQUIPMENT:
                breakdown.equipmentBonus += value;
                break;
            case StatSource::PARAGON:
                breakdown.paragonBonus += value;
                break;
            case StatSource::CUSTOM:
                breakdown.customBonus += value;
                break;
            case StatSource::BUFF:
                breakdown.buffBonus += value;
                break;
            case StatSource::PRESTIGE:
                breakdown.prestigeBonus += value;
                break;
            case StatSource::ENHANCEMENT:
                breakdown.enhancementBonus += value;
                break;
            default:
                break;
        }
    }
    
    // Calculate total
    breakdown.totalValue = breakdown.baseValue +
                          breakdown.equipmentBonus +
                          breakdown.paragonBonus +
                          breakdown.customBonus +
                          breakdown.buffBonus +
                          breakdown.prestigeBonus +
                          breakdown.enhancementBonus;
    
    return breakdown;
}

std::string UnifiedStatSystem::StatBreakdown::GetTooltipText() const
{
    std::ostringstream ss;
    ss << "Base: " << std::fixed << std::setprecision(1) << baseValue << "\n";
    
    if (equipmentBonus != 0.0f)
        ss << "Equipment: +" << equipmentBonus << "\n";
    if (paragonBonus != 0.0f)
        ss << "Paragon: +" << paragonBonus << "\n";
    if (customBonus != 0.0f)
        ss << "Custom: +" << customBonus << "\n";
    if (buffBonus != 0.0f)
        ss << "Buffs: +" << buffBonus << "\n";
    if (prestigeBonus != 0.0f)
        ss << "Prestige: +" << prestigeBonus << "\n";
    if (enhancementBonus != 0.0f)
        ss << "Enhancement: +" << enhancementBonus << "\n";
    
    ss << "Total: " << totalValue;
    
    return ss.str();
}

void UnifiedStatSystem::ApplyStatModifier(Player* player, StatType statType, StatModifier modifier)
{
    if (!player)
        return;
    
    uint32 guid = player->GetGUID().GetCounter();
    auto& modifiers = m_statModifiers[guid][statType];
    
    // Add modifier
    modifiers.push_back(modifier);
    
    // Sort by priority
    std::sort(modifiers.begin(), modifiers.end(),
        [](const StatModifier& a, const StatModifier& b) {
            return a.priority < b.priority;
        });
    
    // Update player stats
    UpdateAllStats(player);
}

void UnifiedStatSystem::RemoveStatModifier(Player* player, StatType statType, StatSource source)
{
    if (!player)
        return;
    
    uint32 guid = player->GetGUID().GetCounter();
    auto& modifiers = m_statModifiers[guid][statType];
    
    // Remove modifiers from this source
    modifiers.erase(
        std::remove_if(modifiers.begin(), modifiers.end(),
            [source](const StatModifier& mod) {
                return mod.source == source;
            }),
        modifiers.end()
    );
    
    // Update player stats
    UpdateAllStats(player);
}

void UnifiedStatSystem::UpdateAllStats(Player* player)
{
    if (!player)
        return;
    
    // Update all stat types
    for (uint8 i = 0; i < static_cast<uint8>(StatType::MAX_STAT_TYPES); ++i)
    {
        StatType statType = static_cast<StatType>(i);
        float value = GetStatValue(player, statType);
        ApplyStatToPlayer(player, statType, value);
    }
    
    // Force stat update
    player->UpdateAllStats();
}

float UnifiedStatSystem::CalculateStatValue(Player* player, StatType statType, const StatBreakdown& breakdown)
{
    float total = breakdown.totalValue;
    
    // Apply percent modifiers (after flat bonuses)
    uint32 guid = player->GetGUID().GetCounter();
    auto& modifiers = m_statModifiers[guid][statType];
    
    for (const auto& mod : modifiers)
    {
        if (mod.percentValue != 0.0f)
        {
            total += (total * mod.percentValue / 100.0f);
        }
    }
    
    return total;
}

void UnifiedStatSystem::ApplyStatToPlayer(Player* player, StatType statType, float value)
{
    if (!player)
        return;
    
    // Apply stat based on type
    switch (statType)
    {
        case StatType::STRENGTH:
            player->HandleStatFlatModifier(UNIT_MOD_STAT_STRENGTH, BASE_VALUE, value - player->GetStat(STAT_STRENGTH), true);
            break;
        case StatType::AGILITY:
            player->HandleStatFlatModifier(UNIT_MOD_STAT_AGILITY, BASE_VALUE, value - player->GetStat(STAT_AGILITY), true);
            break;
        case StatType::STAMINA:
            player->HandleStatFlatModifier(UNIT_MOD_STAT_STAMINA, BASE_VALUE, value - player->GetStat(STAT_STAMINA), true);
            break;
        case StatType::INTELLECT:
            player->HandleStatFlatModifier(UNIT_MOD_STAT_INTELLECT, BASE_VALUE, value - player->GetStat(STAT_INTELLECT), true);
            break;
        case StatType::SPIRIT:
            player->HandleStatFlatModifier(UNIT_MOD_STAT_SPIRIT, BASE_VALUE, value - player->GetStat(STAT_SPIRIT), true);
            break;
        case StatType::ATTACK_POWER:
            player->HandleStatFlatModifier(UNIT_MOD_ATTACK_POWER, TOTAL_VALUE, value, true);
            break;
        case StatType::SPELL_POWER:
            player->ApplySpellPowerBonus(static_cast<int32>(value), true);
            break;
        case StatType::HEALTH:
            player->HandleStatFlatModifier(UNIT_MOD_HEALTH, TOTAL_VALUE, value, true);
            player->UpdateMaxHealth();
            break;
        case StatType::ARMOR:
            player->HandleStatFlatModifier(UNIT_MOD_ARMOR, TOTAL_VALUE, value, true);
            player->UpdateArmor();
            break;
        default:
            // Other stats handled via auras or other systems
            break;
    }
}

std::string UnifiedStatSystem::GetStatName(StatType statType)
{
    auto it = m_statDisplayInfo.find(statType);
    if (it != m_statDisplayInfo.end())
        return it->second.displayName;
    
    // Default names
    switch (statType)
    {
        case StatType::STRENGTH: return "Strength";
        case StatType::AGILITY: return "Agility";
        case StatType::STAMINA: return "Stamina";
        case StatType::INTELLECT: return "Intellect";
        case StatType::SPIRIT: return "Spirit";
        case StatType::ATTACK_POWER: return "Attack Power";
        case StatType::SPELL_POWER: return "Spell Power";
        case StatType::CRITICAL_STRIKE: return "Critical Strike";
        case StatType::HASTE: return "Haste";
        case StatType::MASTERY: return "Mastery";
        case StatType::VERSATILITY: return "Versatility";
        case StatType::LIFESTEAL: return "Lifesteal";
        case StatType::MULTISTRIKE: return "Multistrike";
        case StatType::ARMOR: return "Armor";
        case StatType::RESISTANCE: return "Resistance";
        case StatType::DODGE: return "Dodge";
        case StatType::PARRY: return "Parry";
        case StatType::BLOCK: return "Block";
        case StatType::HEALTH: return "Health";
        case StatType::MOVEMENT_SPEED: return "Movement Speed";
        case StatType::ATTACK_SPEED: return "Attack Speed";
        case StatType::CAST_SPEED: return "Cast Speed";
        case StatType::HEALTH_REGEN: return "Health Regeneration";
        case StatType::MANA_REGEN: return "Mana Regeneration";
        case StatType::EXPERIENCE_BONUS: return "Experience Bonus";
        case StatType::GOLD_BONUS: return "Gold Bonus";
        case StatType::LOOT_BONUS: return "Loot Bonus";
        default: return "Unknown Stat";
    }
}

std::string UnifiedStatSystem::GetStatDescription(StatType statType)
{
    switch (statType)
    {
        case StatType::STRENGTH:
            return "Increases Attack Power and Block Value";
        case StatType::AGILITY:
            return "Increases Critical Strike and Dodge";
        case StatType::STAMINA:
            return "Increases Health";
        case StatType::INTELLECT:
            return "Increases Spell Power and Mana";
        case StatType::SPIRIT:
            return "Increases Mana and Health Regeneration";
        case StatType::ATTACK_POWER:
            return "Increases Physical Damage";
        case StatType::SPELL_POWER:
            return "Increases Spell Damage and Healing";
        case StatType::CRITICAL_STRIKE:
            return "Increases Critical Strike Chance";
        case StatType::HASTE:
            return "Increases Attack and Cast Speed";
        case StatType::MASTERY:
            return "Increases Mastery Rating";
        case StatType::VERSATILITY:
            return "Increases Damage and Healing, Reduces Damage Taken";
        case StatType::LIFESTEAL:
            return "Heals for a percentage of damage dealt";
        case StatType::MULTISTRIKE:
            return "Chance to hit additional times";
        default:
            return "No description available";
    }
}

void UnifiedStatSystem::RegisterStatDisplay(StatType statType, const std::string& displayName, const std::string& icon)
{
    StatDisplayInfo info;
    info.displayName = displayName;
    info.icon = icon;
    m_statDisplayInfo[statType] = info;
}

void UnifiedStatSystem::LoadPlayerStatBonuses(Player* player)
{
    if (!player)
        return;
    
    uint32 guid = player->GetGUID().GetCounter();
    
    // Clear existing modifiers from our sources
    for (uint8 i = 0; i < static_cast<uint8>(StatType::MAX_STAT_TYPES); ++i)
    {
        StatType statType = static_cast<StatType>(i);
        RemoveStatModifier(player, statType, StatSource::ENHANCEMENT); // Item upgrades
        RemoveStatModifier(player, statType, StatSource::PARAGON);
        RemoveStatModifier(player, statType, StatSource::PRESTIGE);
    }
    
    // Load all bonuses
    LoadItemUpgradeBonuses(player);
    LoadParagonStatBonuses(player);
    LoadPrestigeBonuses(player);
    
    // Mark as loaded
    m_loadedBonuses[guid] = true;
    
    // Update all stats
    UpdateAllStats(player);
}

void UnifiedStatSystem::InvalidatePlayerCache(uint32 guid)
{
    m_loadedBonuses.erase(guid);
    // Stat modifiers are already per-player, so clearing loaded flag is enough
}

void UnifiedStatSystem::LoadItemUpgradeBonuses(Player* player)
{
    if (!player)
        return;
    
    uint32 guid = player->GetGUID().GetCounter();
    
    // Get upgrade stat bonus percentage from config
    float statBonusPerLevel = sConfigMgr->GetOption<float>("ProgressiveSystems.Upgrade.StatBonusPerLevel", 5.0f);
    
    // Check all equipped items
    for (uint8 i = 0; i < EQUIPMENT_SLOT_END; ++i)
    {
        Item* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, i);
        if (!item)
            continue;
        
        uint64 itemGuid = item->GetGUID().GetCounter();
        
        // Get upgrade level from database
        QueryResult result = CharacterDatabase.Query(
            "SELECT upgrade_level, stat_bonus_percent FROM item_upgrades WHERE item_guid = {}",
            itemGuid
        );
        
        if (!result)
            continue;
        
        Field* fields = result->Fetch();
        uint32 upgradeLevel = fields[0].Get<uint32>();
        float statBonusPercent = fields[1].Get<float>();
        
        if (upgradeLevel == 0)
            continue;
        
        // Get item template
        ItemTemplate const* proto = item->GetTemplate();
        if (!proto)
            continue;
        
        // Apply bonus to all stats on the item
        for (uint8 j = 0; j < MAX_ITEM_PROTO_STATS; ++j)
        {
            uint32 statType = proto->ItemStat[j].ItemStatType;
            int32 statValue = proto->ItemStat[j].ItemStatValue;
            
            if (statValue == 0)
                continue;
            
            // Convert item stat type to our StatType
            StatType ourStatType = ConvertItemStatToStatType(statType);
            if (ourStatType == StatType::MAX_STAT_TYPES)
                continue;
            
            // Calculate bonus: base stat value * (stat_bonus_percent / 100)
            float bonus = static_cast<float>(statValue) * (statBonusPercent / 100.0f);
            
            // Apply as enhancement modifier
            StatModifier modifier(StatSource::ENHANCEMENT, bonus, 0.0f, 100);
            ApplyStatModifier(player, ourStatType, modifier);
        }
    }
}

void UnifiedStatSystem::LoadParagonStatBonuses(Player* player)
{
    if (!player)
        return;
    
    uint32 guid = player->GetGUID().GetCounter();
    
    // Get paragon stat allocations
    QueryResult result = CharacterDatabase.Query(
        "SELECT ps.stat_type, ps.stat_id, ps.points_allocated, pd.points_per_level "
        "FROM character_paragon_stats ps "
        "JOIN paragon_stat_definitions pd ON ps.stat_id = pd.stat_id "
        "WHERE ps.guid = {} AND pd.active = 1",
        guid
    );
    
    if (!result)
        return;
    
    do
    {
        Field* fields = result->Fetch();
        uint8 paragonStatType = fields[0].Get<uint8>(); // 0=Core, 1=Offense, 2=Defense, 3=Utility
        uint32 statId = fields[1].Get<uint32>();
        uint32 pointsAllocated = fields[2].Get<uint32>();
        float pointsPerLevel = fields[3].Get<float>();
        
        if (pointsAllocated == 0)
            continue;
        
        // Calculate bonus value
        float bonus = static_cast<float>(pointsAllocated) * pointsPerLevel;
        
        // Map paragon stat type to our StatType
        // For now, we'll need to query the stat definition to get the actual stat
        QueryResult statDefResult = WorldDatabase.Query(
            "SELECT stat_name FROM paragon_stat_definitions WHERE stat_id = {}",
            statId
        );
        
        if (!statDefResult)
            continue;
        
        std::string statName = statDefResult->Fetch()[0].Get<std::string>();
        StatType statType = ConvertParagonStatNameToStatType(statName);
        
        if (statType == StatType::MAX_STAT_TYPES)
            continue;
        
        // Apply paragon modifier
        StatModifier modifier(StatSource::PARAGON, bonus, 0.0f, 200);
        ApplyStatModifier(player, statType, modifier);
        
    } while (result->NextRow());
}

void UnifiedStatSystem::LoadPrestigeBonuses(Player* player)
{
    if (!player)
        return;
    
    uint32 guid = player->GetGUID().GetCounter();
    
    // Get prestige level
    QueryResult result = CharacterDatabase.Query(
        "SELECT prestige_level FROM character_progression_unified WHERE guid = {}",
        guid
    );
    
    if (!result)
        return;
    
    uint8 prestigeLevel = result->Fetch()[0].Get<uint8>();
    if (prestigeLevel == 0)
        return;
    
    // Prestige gives percentage bonus to all stats
    float prestigePercent = static_cast<float>(prestigeLevel) * 1.0f; // 1% per prestige level
    
    // Apply to all base stats
    StatType baseStats[] = {
        StatType::STRENGTH,
        StatType::AGILITY,
        StatType::STAMINA,
        StatType::INTELLECT,
        StatType::SPIRIT
    };
    
    for (StatType statType : baseStats)
    {
        StatModifier modifier(StatSource::PRESTIGE, 0.0f, prestigePercent, 300);
        ApplyStatModifier(player, statType, modifier);
    }
}

StatType UnifiedStatSystem::ConvertWoWStatToStatType(Stats stat)
{
    switch (stat)
    {
        case STAT_STRENGTH: return StatType::STRENGTH;
        case STAT_AGILITY: return StatType::AGILITY;
        case STAT_STAMINA: return StatType::STAMINA;
        case STAT_INTELLECT: return StatType::INTELLECT;
        case STAT_SPIRIT: return StatType::SPIRIT;
        default: return StatType::MAX_STAT_TYPES;
    }
}

StatType UnifiedStatSystem::ConvertItemStatToStatType(uint32 itemStatType)
{
    switch (itemStatType)
    {
        case ITEM_MOD_MANA:
        case ITEM_MOD_HEALTH:
            return StatType::HEALTH; // Close enough
        case ITEM_MOD_AGILITY:
            return StatType::AGILITY;
        case ITEM_MOD_STRENGTH:
            return StatType::STRENGTH;
        case ITEM_MOD_INTELLECT:
            return StatType::INTELLECT;
        case ITEM_MOD_SPIRIT:
            return StatType::SPIRIT;
        case ITEM_MOD_STAMINA:
            return StatType::STAMINA;
        case ITEM_MOD_ATTACK_POWER:
            return StatType::ATTACK_POWER;
        case ITEM_MOD_SPELL_POWER:
            return StatType::SPELL_POWER;
        default:
            return StatType::MAX_STAT_TYPES;
    }
}

StatType UnifiedStatSystem::ConvertParagonStatNameToStatType(const std::string& statName)
{
    // Convert paragon stat name to StatType
    if (statName == "Strength" || statName == "strength")
        return StatType::STRENGTH;
    else if (statName == "Agility" || statName == "agility")
        return StatType::AGILITY;
    else if (statName == "Stamina" || statName == "stamina")
        return StatType::STAMINA;
    else if (statName == "Intellect" || statName == "intellect")
        return StatType::INTELLECT;
    else if (statName == "Spirit" || statName == "spirit")
        return StatType::SPIRIT;
    else if (statName == "Attack Power" || statName == "attack power")
        return StatType::ATTACK_POWER;
    else if (statName == "Spell Power" || statName == "spell power")
        return StatType::SPELL_POWER;
    else if (statName == "Health" || statName == "health")
        return StatType::HEALTH;
    else if (statName == "Armor" || statName == "armor")
        return StatType::ARMOR;
    
    return StatType::MAX_STAT_TYPES;
}

