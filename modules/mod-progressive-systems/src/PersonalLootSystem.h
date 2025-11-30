/*
 * Personal Loot System
 * Each player gets their own loot roll - no fighting over items!
 */

#ifndef PERSONAL_LOOT_SYSTEM_H
#define PERSONAL_LOOT_SYSTEM_H

#include "Define.h"
#include "Player.h"
#include "Creature.h"
#include "Item.h"
#include <vector>
#include <map>

// Forward declarations
class Loot;

class AC_GAME_API PersonalLootSystem
{
public:
    static PersonalLootSystem* instance();
    
    void Initialize();
    void Shutdown();
    
    // Generate personal loot for a player when creature dies
    void GeneratePersonalLoot(Player* player, Creature* creature);
    
    // Generate personal loot for all eligible players in group/raid
    void GeneratePersonalLootForGroup(Creature* creature, Group* group);
    
    // Check if personal loot is enabled
    bool IsPersonalLootEnabled() const { return m_enabled; }
    void SetPersonalLootEnabled(bool enabled) { m_enabled = enabled; }
    
    // Configuration
    struct PersonalLootConfig
    {
        bool enabled = true;
        bool applyToGroups = true;      // Apply to group/raid members
        bool applyToSolo = true;         // Apply to solo players
        float baseDropChance = 1.0f;     // Base chance to get loot (100%)
        float qualityBonus = 0.0f;       // Bonus to item quality based on progression
        uint32 minItemLevel = 0;         // Minimum item level (0 = no minimum)
        uint32 maxItemLevel = 0;        // Maximum item level (0 = no maximum)
        bool scaleWithDifficulty = true; // Scale loot quality with difficulty tier
        bool scaleWithProgression = true; // Scale loot quality with progression tier
    };
    
    void SetConfig(const PersonalLootConfig& config) { m_config = config; }
    const PersonalLootConfig& GetConfig() const { return m_config; }
    
private:
    PersonalLootSystem() = default;
    ~PersonalLootSystem() = default;
    PersonalLootSystem(PersonalLootSystem const&) = delete;
    PersonalLootSystem& operator=(PersonalLootSystem const&) = delete;
    
    // Generate loot items for a specific player
    std::vector<LootItem> GenerateLootItemsForPlayer(Player* player, Creature* creature, Loot* baseLoot);
    
    // Calculate drop chance for a player
    float CalculateDropChance(Player* player, Creature* creature, uint32 itemQuality);
    
    // Get eligible players for personal loot
    std::vector<Player*> GetEligiblePlayers(Creature* creature, Group* group);
    
    // Check if player is eligible for loot
    bool IsPlayerEligible(Player* player, Creature* creature);
    
    // Apply progression bonuses to loot
    void ApplyProgressionBonuses(Player* player, LootItem& lootItem);
    
    // Send loot to player
    void SendPersonalLootToPlayer(Player* player, Creature* creature, const std::vector<LootItem>& lootItems);
    
    bool m_enabled = true;
    PersonalLootConfig m_config;
    
    // Track looted creatures to prevent duplicate loot
    std::map<uint64, std::vector<uint32>> m_creatureLootedByPlayers; // creatureGuid -> vector of playerGuids
};

#define sPersonalLootSystem PersonalLootSystem::instance()

#endif // PERSONAL_LOOT_SYSTEM_H

