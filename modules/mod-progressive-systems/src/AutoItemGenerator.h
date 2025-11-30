/*
 * Automatic Item Generator
 * Generates items dynamically based on difficulty, tier, boss, etc.
 */

#ifndef AUTO_ITEM_GENERATOR_H
#define AUTO_ITEM_GENERATOR_H

#include "Define.h"
#include "Item.h"
#include "Player.h"
#include "Creature.h"
#include <string>
#include <vector>
#include <map>

// Item generation rules
struct ItemGenerationRule
{
    uint32 baseItemEntry = 0;        // Base item template
    uint32 difficultyTier = 0;      // Difficulty tier (0=Normal, 1=Heroic, etc.)
    uint32 progressionTier = 0;      // Progression tier
    uint32 bossEntry = 0;            // Specific boss entry (0 = any)
    uint32 mapId = 0;                // Specific map (0 = any)
    
    // Stat scaling
    float statMultiplier = 1.0f;    // Multiplier for item stats
    uint32 ilvlBonus = 0;            // Item level bonus
    uint32 qualityBonus = 0;         // Quality upgrade (0-6)
    
    // Special properties
    bool allowRandomEnchant = true;
    bool allowSocket = true;
    uint32 minSockets = 0;
    uint32 maxSockets = 0;
    
    // Drop chance
    float dropChance = 1.0f;         // 0.0 - 1.0
    
    // Name suffix/prefix
    std::string namePrefix;
    std::string nameSuffix;
    
    // Description
    std::string description;
};

// Generated item data
struct GeneratedItemData
{
    uint32 itemEntry = 0;
    uint32 itemLevel = 0;
    uint32 quality = 0;
    std::map<uint32, int32> statModifiers; // Stat type -> value
    std::vector<uint32> enchantments;
    std::vector<uint32> sockets;
    std::string customName;
    std::string customDescription;
};

class AC_GAME_API AutoItemGenerator
{
public:
    static AutoItemGenerator* instance();
    
    // Initialize system
    void Initialize();
    void LoadRules();
    
    // Generate item based on context
    Item* GenerateItem(Player* player, Creature* boss, uint32 difficultyTier, uint32 progressionTier);
    
    // Generate item from rule
    Item* GenerateItemFromRule(Player* player, const ItemGenerationRule& rule);
    
    // Register generation rule
    void RegisterRule(const ItemGenerationRule& rule);
    
    // Get available rules for context
    std::vector<ItemGenerationRule> GetRulesForContext(uint32 difficultyTier, uint32 progressionTier, uint32 bossEntry, uint32 mapId);
    
    // Create item with custom stats
    Item* CreateItemWithStats(Player* player, uint32 baseItemEntry, const GeneratedItemData& data);
    
    // Apply stat modifiers to item
    void ApplyStatModifiers(Item* item, const std::map<uint32, int32>& modifiers);
    
    // Apply enchantments to item
    void ApplyEnchantments(Item* item, const std::vector<uint32>& enchantments);
    
    // Apply sockets to item
    void ApplySockets(Item* item, uint32 minSockets, uint32 maxSockets);
    
    // Generate item name
    std::string GenerateItemName(uint32 baseItemEntry, const ItemGenerationRule& rule, uint32 quality);
    
    // Generate item description
    std::string GenerateItemDescription(const ItemGenerationRule& rule, const GeneratedItemData& data);
    
private:
    AutoItemGenerator() = default;
    ~AutoItemGenerator() = default;
    AutoItemGenerator(AutoItemGenerator const&) = delete;
    AutoItemGenerator& operator=(AutoItemGenerator const&) = delete;
    
    // Item generation rules
    std::vector<ItemGenerationRule> m_rules;
    
    // Cache for generated items
    std::map<std::string, GeneratedItemData> m_generatedItemCache;
    
    // Quality names
    static const char* s_qualityNames[];
    static const char* s_tierNames[];
};

#define sAutoItemGenerator AutoItemGenerator::instance()

#endif // AUTO_ITEM_GENERATOR_H

