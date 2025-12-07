/*
 * Progressive Systems Module Loader
 * Initializes the module and registers scripts
 */

#include "ProgressiveSystems.h"
#include "ProgressiveSystemsDatabase.h"
#include "DifficultyScaling.h"
#include "ProgressiveSystemsAddonScript.h"
#include "ParagonSystem.h"
#include "InfiniteDungeonSystem.h"
#include "DailyChallengeSystem.h"
#include "UnifiedStatSystem.h"
#include "ProgressiveSystemsCommands.h"
#include "ProgressiveSystemsWorldScript.h"
#include "DBCGenerator.h"
#include "ScriptMgr.h"
#include "World.h"
#include "Log.h"
#include "Config.h"

// Forward declarations - Core Progressive Systems
void AddSC_ProgressiveSystemsDifficultyScaling();
void AddSC_ProgressiveSystemsAddonScript();
void AddSC_progressive_systems_commands();
void AddSC_progressive_systems_world_script();

// Forward declarations - Reforging System
void AddSC_mod_reforging_worldscript();
void AddSC_npc_reforger();
void AddSC_mod_reforging_playerscript();
void AddSC_mod_reforging_itemscript();

// Forward declarations - Item Upgrade System (Advanced)
void AddSC_item_upgrade_worldscript();
void AddSC_npc_item_upgrade();
void AddSC_item_upgrade_commandscript();
void AddSC_item_upgrade_playerscript();
void AddSC_item_upgrade_itemscript();

// Forward declarations - Mythic Plus (Araxia version - now the only version)
void Addmod_mythic_plusScripts();
void Add_MP_Schedulers();

// Forward declarations - Multi Vendor
void AddMultiVendor_scripts();

// Forward declarations - Global Chat
void AddSC_GlobalChat();

// Forward declarations - Quest Loot Party
void AddLootPartyScripts();

// Forward declarations - Additional Modules
void Addmod_1v1_arenaScripts();
void Addmod_account_achievementsScripts();
void Addmod_account_mountsScripts();
void Addmod_arena_3v3_solo_queueScripts();
void Addmod_autobalanceScripts();
void Addmod_bg_rewardScripts();
void Addmod_character_toolsScripts();
void Addmod_congrats_on_levelScripts();
void Addmod_gain_honor_guardScripts();
void Addmod_instance_resetScripts();
void Addmod_learn_spellsScripts();
void Addmod_premiumScripts();
void Addmod_random_enchantsScripts();
void Addmod_reward_shopScripts();
void Addmod_reward_played_timeScripts();
void Addmod_solo_lfgScripts();
void Addmod_transmogScripts();
void Addmod_azerothshardScripts();
void Addmod_npc_beastmasterScripts();
void AddRewardSystemScripts();

// Script registration functions - These must be defined (not just declared) for the linker
// AddSC_progressive_systems_player_script() is defined in DifficultyScaling.cpp via AddSC_ProgressiveSystemsDifficultyScaling()
// AddSC_progressive_systems_world_script() is defined in ProgressiveSystemsWorldScript.cpp

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
    sParagonSystem->Initialize();
    sInfiniteDungeonSystem->Initialize();
    sDailyChallengeSystem->Initialize();
    
    // Initialize DBC Generator (for auto-generating client patches)
    sDBCGenerator->Initialize();
    
    LOG_INFO("module", "Progressive Systems subsystems initialized.");
    
    // Register core Progressive Systems scripts
    AddSC_ProgressiveSystemsDifficultyScaling();  // This already registers PlayerScript and WorldScript
    AddSC_ProgressiveSystemsAddonScript();        // Addon message handler
    AddSC_progressive_systems_commands();        // Commands (.ps upgrade, etc.)
    AddSC_progressive_systems_world_script();     // Database script for DBC generation
    
    // Register Reforging System scripts
    AddSC_mod_reforging_worldscript();
    AddSC_npc_reforger();
    AddSC_mod_reforging_playerscript();
    AddSC_mod_reforging_itemscript();
    
    // Register Advanced Item Upgrade System scripts (separate from core upgrade)
    AddSC_item_upgrade_worldscript();
    AddSC_npc_item_upgrade();
    AddSC_item_upgrade_commandscript();
    AddSC_item_upgrade_playerscript();
    AddSC_item_upgrade_itemscript();
    
    // Register Mythic Plus scripts (Araxia version - comprehensive implementation)
    // Silviu version removed - Araxia version is more complete and better maintained
    bool mythicPlusEnabled = sConfigMgr->GetOption<bool>("MythicPlus.Enabled", true);
    
    if (mythicPlusEnabled)
    {
        Add_MP_Schedulers();
        Addmod_mythic_plusScripts();
        LOG_INFO("module", "  - Mythic Plus: Enabled");
    }
    else
    {
        LOG_INFO("module", "  - Mythic Plus: Disabled via config");
    }
    
    // Register Multi Vendor scripts
    AddMultiVendor_scripts();
    
    // Register Global Chat scripts
    AddSC_GlobalChat();
    
    // Register Quest Loot Party scripts
    AddLootPartyScripts();
    
    // Register 1v1 Arena scripts
    Addmod_1v1_arenaScripts();
    
    // Register Account Achievements scripts
    Addmod_account_achievementsScripts();
    
    // Register Account Mounts scripts
    Addmod_account_mountsScripts();
    
    // Register Arena 3v3 Solo Queue scripts
    Addmod_arena_3v3_solo_queueScripts();
    
    // Register AutoBalance scripts
    Addmod_autobalanceScripts();
    
    // Register BG Reward scripts
    Addmod_bg_rewardScripts();
    
    // Register Character Tools scripts
    Addmod_character_toolsScripts();
    
    // Register Congrats On Level scripts
    Addmod_congrats_on_levelScripts();
    
    // Register Gain Honor Guard scripts
    Addmod_gain_honor_guardScripts();
    
    // Register Instance Reset scripts (DISABLED - Using InstanceResetSystem from Progressive Systems instead)
    // Addmod_instance_resetScripts(); // Legacy system - disabled in favor of integrated InstanceResetSystem
    
    // Register Learn Spells scripts
    Addmod_learn_spellsScripts();
    
    // Register Premium Account scripts
    Addmod_premiumScripts();
    
    // Register Random Enchants scripts
    Addmod_random_enchantsScripts();
    
    // Register Reward Shop scripts
    Addmod_reward_shopScripts();
    
    // Register Reward Played Time scripts
    AddRewardSystemScripts();
    
    // Register Solo LFG scripts
    Addmod_solo_lfgScripts();
    
    // Register Transmog scripts
    Addmod_transmogScripts();
    
    // Register AzerothShard scripts (includes many sub-systems)
    Addmod_azerothshardScripts();
    
    // Register NPC Beastmaster scripts
    Addmod_npc_beastmasterScripts();
    
    // Register Reward Played Time scripts
    AddRewardSystemScripts();
    
    LOG_INFO("module", "Progressive Systems Module: All scripts registered successfully!");
    LOG_INFO("module", "  - Core Progressive Systems: Enabled");
    LOG_INFO("module", "  - Reforging System: Enabled");
    LOG_INFO("module", "  - Advanced Item Upgrade: Enabled");
    // Mythic Plus status logged above based on config
    LOG_INFO("module", "  - Multi Vendor: Enabled");
    LOG_INFO("module", "  - Global Chat: Enabled");
    LOG_INFO("module", "  - Quest Loot Party: Enabled");
    LOG_INFO("module", "  - 1v1 Arena: Enabled");
    LOG_INFO("module", "  - Account Achievements: Enabled");
    LOG_INFO("module", "  - Account Mounts: Enabled");
    LOG_INFO("module", "  - Arena 3v3 Solo Queue: Enabled");
    LOG_INFO("module", "  - AutoBalance: Enabled");
    LOG_INFO("module", "  - BG Reward: Enabled");
    LOG_INFO("module", "  - Character Tools: Enabled");
    LOG_INFO("module", "  - Congrats On Level: Enabled");
    LOG_INFO("module", "  - Gain Honor Guard: Enabled");
    LOG_INFO("module", "  - Instance Reset: Enabled (Integrated System)");
    LOG_INFO("module", "  - Learn Spells: Enabled");
    LOG_INFO("module", "  - Premium Account: Enabled");
    LOG_INFO("module", "  - Random Enchants: Enabled");
    LOG_INFO("module", "  - Reward Shop: Enabled");
    LOG_INFO("module", "  - Solo LFG: Enabled");
    LOG_INFO("module", "  - Transmog: Enabled");
    LOG_INFO("module", "  - AzerothShard: Enabled");
}
