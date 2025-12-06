/*
 * Progressive Systems Module Loader
 * Initializes the module and registers scripts
 */

#include "ProgressiveSystems.h"
#include "ProgressiveSystemsDatabase.h"
#include "DifficultyScaling.h"
#include "ProgressiveSystemsAddonScript.h"
#include "ProgressiveSystemsNPCs.h"
#include "ItemUpgradeSystem.h"
#include "ParagonSystem.h"
#include "InfiniteDungeonSystem.h"
#include "VisualEnchantmentSystem.h"
#include "RewardDistributionSystem.h"
#include "DailyChallengeSystem.h"
#include "SeasonalSystem.h"
#include "UnifiedStatSystem.h"
#include "ProgressiveSystemsCommands.h"
#include "ProgressiveSystemsPlayerScript.h"
#include "ProgressiveSystemsWorldScript.h"
#include "ProgressiveSystemsMapScript.h"
#include "ScriptMgr.h"
#include "World.h"
#include "Log.h"
#include "Config.h"

// Forward declarations
void AddSC_ProgressiveSystemsDifficultyScaling();
void AddSC_ProgressiveSystemsAddonScript();
void AddSC_progressive_systems_commands();
void AddSC_progressive_systems_npcs(); // Defined in ProgressiveSystemsNPCs.cpp
// Note: Daily Challenge and Seasonal NPCs are handled in ProgressiveSystemsNPCs

// Script registration functions - DEFINED here (not just declared) so linker can find them
// These functions MUST exist even though scripts are registered elsewhere
// Note: ProgressiveSystemsPlayerScript and ProgressiveSystemsWorldScript are already
// registered in AddSC_ProgressiveSystemsDifficultyScaling(), so these functions
// are just placeholders to satisfy the loader. They don't create new instances.

// Script registration functions - These must be defined (not just declared) for the linker
void AddSC_progressive_systems_player_script()
{
    // Already registered in AddSC_ProgressiveSystemsDifficultyScaling()
    // This function exists for compatibility with the loader
    // Scripts are registered in DifficultyScaling.cpp
    LOG_DEBUG("module", "AddSC_progressive_systems_player_script called (scripts already registered)");
}

void AddSC_progressive_systems_world_script()
{
    // Already registered in AddSC_ProgressiveSystemsDifficultyScaling()
    // This function exists for compatibility with the loader
    // Scripts are registered in DifficultyScaling.cpp
    LOG_DEBUG("module", "AddSC_progressive_systems_world_script called (scripts already registered)");
}

void AddSC_progressive_systems_map_script()
{
    // Map script can be added here if needed
    // Currently no map-specific script is implemented
    LOG_DEBUG("module", "AddSC_progressive_systems_map_script called");
}

// NPC script registration - Implementation is in ProgressiveSystemsNPCs.cpp
// Forward declaration only - actual implementation is in ProgressiveSystemsNPCs.cpp

// Configuration validation
static bool ValidateProgressiveSystemsConfig()
{
    bool isValid = true;
    
    // Validate module enable
    bool enabled = sConfigMgr->GetOption<bool>("ProgressiveSystems.Enable", true);
    if (!enabled)
    {
        LOG_INFO("module", "Progressive Systems Module is DISABLED in configuration.");
        return true; // Not an error, just disabled
    }
    
    // Validate NPC entries (must be > 0)
    uint32 mainMenuNPC = sConfigMgr->GetOption<uint32>("ProgressiveSystems.NPC.MainMenu", 190000);
    if (mainMenuNPC == 0)
    {
        LOG_ERROR("module", "ProgressiveSystems.NPC.MainMenu is invalid (0). Using default 190000.");
        isValid = false;
    }
    
    // Validate point values (must be >= 0)
    int32 normalPoints = sConfigMgr->GetOption<int32>("ProgressiveSystems.Points.Normal", 5);
    if (normalPoints < 0)
    {
        LOG_ERROR("module", "ProgressiveSystems.Points.Normal is negative ({}). Using default 5.", normalPoints);
        isValid = false;
    }
    
    // Validate upgrade settings
    float upgradeMultiplier = sConfigMgr->GetOption<float>("ProgressiveSystems.Upgrade.CostMultiplier", 1.15f);
    if (upgradeMultiplier <= 1.0f || upgradeMultiplier > 2.0f)
    {
        LOG_ERROR("module", "ProgressiveSystems.Upgrade.CostMultiplier is invalid ({}). Should be between 1.0 and 2.0. Using default 1.15.", upgradeMultiplier);
        isValid = false;
    }
    
    uint32 maxUpgradeLevel = sConfigMgr->GetOption<uint32>("ProgressiveSystems.Upgrade.MaxLevel", 1000);
    if (maxUpgradeLevel == 0 || maxUpgradeLevel > 10000)
    {
        LOG_ERROR("module", "ProgressiveSystems.Upgrade.MaxLevel is invalid ({}). Should be between 1 and 10000. Using default 1000.", maxUpgradeLevel);
        isValid = false;
    }
    
    // Validate difficulty settings
    uint32 maxTier = sConfigMgr->GetOption<uint32>("ProgressiveSystems.Difficulty.MaxTier", 1000);
    if (maxTier == 0 || maxTier > 10000)
    {
        LOG_ERROR("module", "ProgressiveSystems.Difficulty.MaxTier is invalid ({}). Should be between 1 and 10000. Using default 1000.", maxTier);
        isValid = false;
    }
    
    // Validate prestige settings
    uint32 prestigeMinLevel = sConfigMgr->GetOption<uint32>("ProgressiveSystems.Prestige.MinLevel", 80);
    if (prestigeMinLevel > 80)
    {
        LOG_WARN("module", "ProgressiveSystems.Prestige.MinLevel is {} (higher than max level 80). Players may not be able to prestige.", prestigeMinLevel);
    }
    
    if (isValid)
    {
        LOG_INFO("module", "Progressive Systems Module configuration validated successfully.");
    }
    else
    {
        LOG_WARN("module", "Progressive Systems Module configuration has some issues. Check logs above.");
    }
    
    return true; // Don't prevent module from loading, just warn
}

void Addmod_progressive_systemsScripts()
{
    // Validate configuration first
    ValidateProgressiveSystemsConfig();
    
    // Initialize core systems
    LOG_INFO("module", "Initializing Progressive Systems subsystems...");
    
    sUnifiedStatSystem->Initialize();
    sItemUpgradeSystem->Initialize();
    sParagonSystem->Initialize();
    sInfiniteDungeonSystem->Initialize();
    sVisualEnchantmentSystem->Initialize();
    sRewardDistributionSystem->Initialize();
    sDailyChallengeSystem->Initialize();
    sSeasonalSystem->Initialize();
    
    LOG_INFO("module", "Progressive Systems subsystems initialized.");
    
    // Register scripts
    AddSC_ProgressiveSystemsDifficultyScaling();  // This already registers PlayerScript and WorldScript
    AddSC_ProgressiveSystemsAddonScript();        // Addon message handler
    AddSC_progressive_systems_commands();        // Commands (.ps upgrade, etc.)
    AddSC_progressive_systems_npcs();            // NPC scripts (placeholder)
    AddSC_progressive_systems_player_script();    // Player event hooks (already registered, but function must exist)
    AddSC_progressive_systems_world_script();     // World update hooks (already registered, but function must exist)
    AddSC_progressive_systems_map_script();       // Map/instance event hooks
    
    LOG_INFO("module", "Progressive Systems Module: All scripts registered successfully!");
}
