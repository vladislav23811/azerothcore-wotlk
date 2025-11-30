/*
 * Enhanced Gem System
 * Progressive gems with better stats and socket bonuses
 */

#ifndef ENHANCED_GEM_SYSTEM_H
#define ENHANCED_GEM_SYSTEM_H

#include "Define.h"
#include "Player.h"
#include "Item.h"
#include <map>
#include <vector>
#include <string>

enum GemQuality : uint8
{
    GEM_QUALITY_NORMAL = 0,
    GEM_QUALITY_UNCOMMON = 1,
    GEM_QUALITY_RARE = 2,
    GEM_QUALITY_EPIC = 3,
    GEM_QUALITY_LEGENDARY = 4,
    GEM_QUALITY_MAX
};

enum GemType : uint8
{
    GEM_TYPE_RED = 1,      // Strength, Attack Power
    GEM_TYPE_YELLOW = 2,   // Agility, Critical Strike
    GEM_TYPE_BLUE = 4,     // Intellect, Spell Power
    GEM_TYPE_PURPLE = 8,   // Stamina, Health
    GEM_TYPE_GREEN = 16,   // Spirit, Mana
    GEM_TYPE_ORANGE = 32,  // Hybrid (Red+Yellow)
    GEM_TYPE_PRISMATIC = 64 // All colors
};

struct EnhancedGemData
{
    uint32 gemId;
    uint32 itemEntry;
    std::string name;
    std::string description;
    GemQuality quality;
    GemType type;
    uint32 requiredLevel;
    uint32 requiredTier;      // Progression tier required
    uint32 requiredPrestige;  // Prestige level required
    int32 statBonus;          // Flat stat bonus
    float statPercentBonus;   // Percentage stat bonus
    float socketBonusMultiplier; // Multiplier for socket bonus
    bool isActive;
};

class AC_GAME_API EnhancedGemSystem
{
public:
    static EnhancedGemSystem* instance();
    
    void Initialize();
    void Shutdown();
    
    // Load gems from database
    void LoadGems();
    
    // Get available gems for player
    std::vector<EnhancedGemData> GetAvailableGems(Player* player, GemType gemType = GEM_TYPE_PRISMATIC);
    
    // Check if player can use gem
    bool CanPlayerUseGem(Player* player, uint32 gemId);
    
    // Apply gem to item
    bool ApplyGemToItem(Player* player, Item* item, uint32 gemId, uint8 socketSlot);
    bool RemoveGemFromItem(Player* player, Item* item, uint8 socketSlot);
    
    // Get gem data
    EnhancedGemData* GetGemData(uint32 gemId);
    
    // Calculate socket bonus with enhancements
    int32 CalculateSocketBonus(Item* item, const std::vector<uint32>& gemIds);
    
    // Progression-based gem unlocks
    void UnlockGemsForTier(Player* player, uint8 tier);
    void UnlockGemsForPrestige(Player* player, uint32 prestigeLevel);
    
    // Generate progressive gem
    Item* GenerateProgressiveGem(Player* player, GemQuality quality, GemType type);
    
    // Create default gems (fallback)
    void CreateDefaultGems();
    
private:
    EnhancedGemSystem() = default;
    ~EnhancedGemSystem() = default;
    EnhancedGemSystem(EnhancedGemSystem const&) = delete;
    EnhancedGemSystem& operator=(EnhancedGemSystem const&) = delete;
    
    std::map<uint32, EnhancedGemData> m_gems; // gemId -> data
    std::map<uint32, std::map<uint32, uint32>> m_itemGems; // itemGuid -> socketSlot -> gemId
};

#define sEnhancedGemSystem EnhancedGemSystem::instance()

#endif // ENHANCED_GEM_SYSTEM_H

