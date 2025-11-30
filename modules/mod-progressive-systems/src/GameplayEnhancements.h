/*
 * Gameplay Enhancements Module
 * New features and gameplay options
 */

#ifndef GAMEPLAY_ENHANCEMENTS_H
#define GAMEPLAY_ENHANCEMENTS_H

#include "Define.h"
#include "Player.h"
#include "Creature.h"
#include "Map.h"
#include <vector>
#include <string>

// Enhancement types
enum class EnhancementType : uint8
{
    COMBAT = 0,
    PROGRESSION = 1,
    SOCIAL = 2,
    QUALITY_OF_LIFE = 3,
    CUSTOM = 4
};

// Combat enhancements
class AC_GAME_API CombatEnhancements
{
public:
    static CombatEnhancements* instance();
    
    // Dynamic difficulty scaling
    void ScaleCreatureForPlayer(Creature* creature, Player* player);
    
    // Smart loot system
    void GenerateSmartLoot(Player* player, Creature* victim);
    
    // Combo system
    void RegisterCombo(Player* player, uint32 spellId);
    uint32 GetComboCount(Player* player);
    void ApplyComboBonus(Player* player, float multiplier);
    
    // Execution system (bonus damage on low HP)
    float GetExecutionBonus(Player* player, Creature* target);
    
    // Momentum system (bonus for consecutive kills)
    void RegisterKill(Player* player);
    float GetMomentumMultiplier(Player* player);
    
private:
    CombatEnhancements() = default;
    ~CombatEnhancements() = default;
    
    struct PlayerCombatData
    {
        uint32 comboCount = 0;
        uint32 consecutiveKills = 0;
        time_t lastKillTime = 0;
    };
    std::map<uint32, PlayerCombatData> m_playerCombatData;
};

// Progression enhancements
class AC_GAME_API ProgressionEnhancements
{
public:
    static ProgressionEnhancements* instance();
    
    // Dynamic quest rewards
    void EnhanceQuestReward(Player* player, uint32 questId, uint32& xp, uint32& gold);
    
    // Milestone system
    void CheckMilestones(Player* player);
    void AwardMilestone(Player* player, uint32 milestoneId);
    
    // Achievement integration
    void CheckProgressionAchievements(Player* player);
    
    // Title system
    void AwardTitle(Player* player, const std::string& title);
    
private:
    ProgressionEnhancements() = default;
    ~ProgressionEnhancements() = default;
};

// Quality of Life enhancements
class AC_GAME_API QoLEnhancements
{
public:
    static QoLEnhancements* instance();
    
    // Auto-loot
    void EnableAutoLoot(Player* player, bool enable);
    bool IsAutoLootEnabled(Player* player);
    
    // Auto-vendor
    void EnableAutoVendor(Player* player, bool enable);
    bool IsAutoVendorEnabled(Player* player);
    
    // Smart repair
    void AutoRepair(Player* player);
    
    // Inventory management
    void AutoSortInventory(Player* player);
    
    // Teleport system
    void RegisterTeleportLocation(Player* player, const std::string& name, uint32 mapId, float x, float y, float z);
    void TeleportToLocation(Player* player, const std::string& name);
    
private:
    QoLEnhancements() = default;
    ~QoLEnhancements() = default;
    
    struct TeleportLocation
    {
        uint32 mapId;
        float x, y, z, o;
    };
    std::map<uint32, std::map<std::string, TeleportLocation>> m_playerTeleports;
};

// Main gameplay enhancements manager
class AC_GAME_API GameplayEnhancements
{
public:
    static GameplayEnhancements* instance();
    
    void Initialize();
    void Shutdown();
    
    // Get enhancement modules
    CombatEnhancements* GetCombat() { return CombatEnhancements::instance(); }
    ProgressionEnhancements* GetProgression() { return ProgressionEnhancements::instance(); }
    QoLEnhancements* GetQoL() { return QoLEnhancements::instance(); }
    
    // Configuration
    void SetEnhancementEnabled(EnhancementType type, bool enabled);
    bool IsEnhancementEnabled(EnhancementType type);
    
private:
    GameplayEnhancements() = default;
    ~GameplayEnhancements() = default;
    
    std::map<EnhancementType, bool> m_enabledEnhancements;
};

#define sGameplayEnhancements GameplayEnhancements::instance()

#endif // GAMEPLAY_ENHANCEMENTS_H

