/*
 * Unified Stat System
 * Modern, modular stat system combining all stat bonuses
 * Supports: Base stats, Custom stats, Paragon stats, Item stats
 */

#ifndef UNIFIED_STAT_SYSTEM_H
#define UNIFIED_STAT_SYSTEM_H

#include "Define.h"
#include "Player.h"
#include <map>
#include <string>
#include <memory>

// Stat types enum
enum class StatType : uint8
{
    // Base Stats
    STRENGTH = 0,
    AGILITY = 1,
    STAMINA = 2,
    INTELLECT = 3,
    SPIRIT = 4,
    
    // Combat Stats
    ATTACK_POWER = 10,
    SPELL_POWER = 11,
    CRITICAL_STRIKE = 12,
    HASTE = 13,
    MASTERY = 14,
    VERSATILITY = 15,
    LIFESTEAL = 16,
    MULTISTRIKE = 17,
    
    // Defense Stats
    ARMOR = 20,
    RESISTANCE = 21,
    DODGE = 22,
    PARRY = 23,
    BLOCK = 24,
    HEALTH = 25,
    
    // Utility Stats
    MOVEMENT_SPEED = 30,
    ATTACK_SPEED = 31,
    CAST_SPEED = 32,
    HEALTH_REGEN = 33,
    MANA_REGEN = 34,
    
    // Progression Stats
    EXPERIENCE_BONUS = 40,
    GOLD_BONUS = 41,
    LOOT_BONUS = 42,
    
    MAX_STAT_TYPES = 50
};

// Stat source enum
enum class StatSource : uint8
{
    BASE = 0,           // Base character stats
    EQUIPMENT = 1,      // From equipped items
    PARAGON = 2,        // From paragon system
    CUSTOM = 3,         // From custom stat system
    BUFF = 4,           // From temporary buffs
    PRESTIGE = 5,       // From prestige system
    ENHANCEMENT = 6,    // From stat enhancements
    MAX_SOURCES = 7
};

// Stat modifier structure
struct StatModifier
{
    StatSource source;
    float flatValue = 0.0f;
    float percentValue = 0.0f;
    uint32 priority = 0; // Higher priority applied last
    
    StatModifier() = default;
    StatModifier(StatSource src, float flat, float percent = 0.0f, uint32 prio = 0)
        : source(src), flatValue(flat), percentValue(percent), priority(prio) {}
};

// Unified Stat System class
class AC_GAME_API UnifiedStatSystem
{
public:
    static UnifiedStatSystem* instance();
    
    // Initialize system
    void Initialize();
    void Shutdown();
    
    // Get stat value (final calculated value)
    float GetStatValue(Player* player, StatType statType);
    
    // Get stat breakdown (for tooltips/display)
    struct StatBreakdown
    {
        float baseValue = 0.0f;
        float equipmentBonus = 0.0f;
        float paragonBonus = 0.0f;
        float customBonus = 0.0f;
        float buffBonus = 0.0f;
        float prestigeBonus = 0.0f;
        float enhancementBonus = 0.0f;
        float totalValue = 0.0f;
        
        std::string GetTooltipText() const;
    };
    StatBreakdown GetStatBreakdown(Player* player, StatType statType);
    
    // Apply stat modifiers
    void ApplyStatModifier(Player* player, StatType statType, StatModifier modifier);
    void RemoveStatModifier(Player* player, StatType statType, StatSource source);
    
    // Update all stats for player (call on login, stat change, etc.)
    void UpdateAllStats(Player* player);
    
    // Get stat name (non-static to access instance data)
    std::string GetStatName(StatType statType);
    
    // Get stat description
    static std::string GetStatDescription(StatType statType);
    
    // Register stat display (for addon)
    void RegisterStatDisplay(StatType statType, const std::string& displayName, const std::string& icon);
    
    // Load and apply stat bonuses from database (call on login, item upgrade, paragon allocation)
    void LoadPlayerStatBonuses(Player* player);
    void InvalidatePlayerCache(uint32 guid);
    
    // Load item upgrade bonuses (public for commands)
    void LoadItemUpgradeBonuses(Player* player);
    
    // Load paragon stat bonuses (public for commands)
    void LoadParagonStatBonuses(Player* player);
    
    // Load prestige bonuses (public for commands)
    void LoadPrestigeBonuses(Player* player);
    
private:
    UnifiedStatSystem() = default;
    ~UnifiedStatSystem() = default;
    UnifiedStatSystem(UnifiedStatSystem const&) = delete;
    UnifiedStatSystem& operator=(UnifiedStatSystem const&) = delete;
    
    // Internal stat calculation
    float CalculateStatValue(Player* player, StatType statType, const StatBreakdown& breakdown);
    
    // Apply stat to player
    void ApplyStatToPlayer(Player* player, StatType statType, float value);
    
    // Convert WoW stat enum to StatType
    StatType ConvertWoWStatToStatType(Stats stat);
    
    // Convert item stat type to StatType
    StatType ConvertItemStatToStatType(uint32 itemStatType);
    
    // Convert paragon stat name to StatType
    StatType ConvertParagonStatNameToStatType(const std::string& statName);
    
    // Stat modifiers storage (per player, per stat)
    std::map<uint32, std::map<StatType, std::vector<StatModifier>>> m_statModifiers;
    
    // Cache for loaded bonuses (to avoid repeated DB queries)
    std::map<uint32, bool> m_loadedBonuses;
    
    // Stat display info
    struct StatDisplayInfo
    {
        std::string displayName;
        std::string icon;
    };
    std::map<StatType, StatDisplayInfo> m_statDisplayInfo;
};

#define sUnifiedStatSystem UnifiedStatSystem::instance()

#endif // UNIFIED_STAT_SYSTEM_H

