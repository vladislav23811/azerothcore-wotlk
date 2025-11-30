/*
 * Difficulty Scaling System
 * Handles creature scaling based on difficulty tier
 */

#include "DifficultyScaling.h"
#include "ProgressiveSystems.h"
#include "ProgressiveSystemsAddon.h"
#include "ProgressiveSystemsDatabase.h"
#include "UnifiedStatSystem.h"
#include "AutoItemGenerator.h"
#include "GameplayEnhancements.h"
#include "PersonalLootSystem.h"
#include "EnhancedGlyphSystem.h"
#include "EnhancedGemSystem.h"
#include "ItemTemplateHotReload.h"
#include "InstanceResetSystem.h"
#include "ProgressiveSystemsAddonScript.h"
#include "ScriptMgr.h"

// Forward declaration
void AddSC_ProgressiveSystemsAddonScript();
#include "Creature.h"
#include "Player.h"
#include "Map.h"
#include "Log.h"
#include "DatabaseEnv.h"
#include "Unit.h"
#include "SpellInfo.h"
#include "InstanceScript.h"
#include "World.h"
#include <unordered_map>
#include <mutex>

class ProgressiveSystemsDifficultyScaling : public AllCreatureScript
{
public:
    ProgressiveSystemsDifficultyScaling() : AllCreatureScript("ProgressiveSystemsDifficultyScaling") { }

    void OnCreatureAddWorld(Creature* creature) override
    {
        if (!creature)
            return;

        // Only scale in instances
        Map* map = creature->GetMap();
        if (!map || (!map->IsDungeon() && !map->IsRaid()))
            return;

        // Get difficulty tier from first player in instance
        Map::PlayerList const& players = map->GetPlayers();
        if (players.isEmpty())
        {
            // If no players yet, try to get from instance ID
            uint32 instanceId = map->GetInstanceId();
            if (instanceId > 0)
            {
                uint8 difficultyTier = sProgressiveSystems->GetDifficultyTierByInstanceId(instanceId);
                if (difficultyTier > 0)
                {
                    ScaleCreature(creature, map, difficultyTier);
                }
            }
            return;
        }

        Player* firstPlayer = players.begin()->getSource();
        if (!firstPlayer)
            return;

        uint8 difficultyTier = sProgressiveSystems->GetDifficultyTier(firstPlayer, map);
        if (difficultyTier == 0)
            return;

        ScaleCreature(creature, map, difficultyTier);
    }
    
private:
    void ScaleCreature(Creature* creature, Map* map, uint8 difficultyTier)
    {
        uint32 mapId = map->GetId();
        float healthMultiplier = sProgressiveSystems->GetHealthMultiplier(mapId, difficultyTier);
        float damageMultiplier = sProgressiveSystems->GetDamageMultiplier(mapId, difficultyTier);

        // Scale creature health
        uint32 baseMaxHealth = creature->GetMaxHealth();
        uint32 newMaxHealth = static_cast<uint32>(baseMaxHealth * healthMultiplier);
        creature->SetMaxHealth(newMaxHealth);
        creature->SetHealth(newMaxHealth);

        // Store damage multiplier in static map
        {
            std::lock_guard<std::mutex> lock(s_damageMultiplierMutex);
            s_creatureDamageMultipliers[creature->GetGUID()] = damageMultiplier;
        }
        
        LOG_DEBUG("module", "ProgressiveSystems: Scaled creature {} (entry {}) in map {} to tier {} (HP: {}x, DMG: {}x)",
            creature->GetName(), creature->GetEntry(), mapId, difficultyTier, healthMultiplier, damageMultiplier);
    }
};

// Static map to store damage multipliers (declared before use)
namespace
{
    std::unordered_map<ObjectGuid, float> s_creatureDamageMultipliers;
    std::mutex s_damageMultiplierMutex;
    
    // Cleanup function to remove dead creatures
    void CleanupDamageMultipliers()
    {
        std::lock_guard<std::mutex> lock(s_damageMultiplierMutex);
        auto itr = s_creatureDamageMultipliers.begin();
        while (itr != s_creatureDamageMultipliers.end())
        {
            if (!ObjectAccessor::GetCreature(*itr->first))
            {
                itr = s_creatureDamageMultipliers.erase(itr);
            }
            else
            {
                ++itr;
            }
        }
    }
}

// Unit script to apply damage scaling in combat
class ProgressiveSystemsUnitScript : public UnitScript
{
public:
    ProgressiveSystemsUnitScript() : UnitScript("ProgressiveSystemsUnitScript") { }

    void ModifyMeleeDamage(Unit* target, Unit* attacker, uint32& damage) override
    {
        if (!attacker || !target || damage == 0)
            return;

        // Only scale damage from creatures in instances
        if (!attacker->IsCreature() || !target->IsPlayer())
            return;

        Creature* creature = attacker->ToCreature();
        Map* map = creature->GetMap();
        if (!map || (!map->IsDungeon() && !map->IsRaid()))
            return;

        // Get stored damage multiplier
        {
            std::lock_guard<std::mutex> lock(s_damageMultiplierMutex);
            auto itr = s_creatureDamageMultipliers.find(creature->GetGUID());
            if (itr != s_creatureDamageMultipliers.end())
            {
                float damageMultiplier = itr->second;
                if (damageMultiplier > 1.0f)
                {
                    damage = static_cast<uint32>(damage * damageMultiplier);
                }
            }
        }
    }

    void ModifySpellDamageTaken(Unit* target, Unit* attacker, int32& damage, SpellInfo const* /*spellInfo*/) override
    {
        if (!attacker || !target)
            return;

        // Only scale damage from creatures in instances
        if (!attacker->IsCreature())
            return;

        Creature* creature = attacker->ToCreature();
        Map* map = creature->GetMap();
        if (!map || (!map->IsDungeon() && !map->IsRaid()))
            return;

        // Get stored damage multiplier
        {
            std::lock_guard<std::mutex> lock(s_damageMultiplierMutex);
            auto itr = s_creatureDamageMultipliers.find(creature->GetGUID());
            if (itr != s_creatureDamageMultipliers.end())
            {
                float damageMultiplier = itr->second;
                if (damageMultiplier > 1.0f && damage > 0)
                {
                    damage = static_cast<int32>(damage * damageMultiplier);
                }
            }
        }
    }
};

class ProgressiveSystemsPlayerScript : public PlayerScript
{
public:
    ProgressiveSystemsPlayerScript() : PlayerScript("ProgressiveSystemsPlayerScript") { }
    
    void OnMapChanged(Player* player) override
    {
        // Cleanup damage multipliers periodically when player changes maps
        static std::unordered_map<ObjectGuid, time_t> lastCleanup;
        time_t now = GameTime::GetGameTime().count();
        ObjectGuid playerGuid = player->GetGUID();
        
        auto itr = lastCleanup.find(playerGuid);
        if (itr == lastCleanup.end() || now - itr->second > 60)
        {
            CleanupDamageMultipliers();
            lastCleanup[playerGuid] = now;
        }
    }

    void OnCreatureKill(Player* player, Creature* killed) override
    {
        if (!player || !killed)
            return;

        // Generate personal loot for this player
        if (sPersonalLootSystem && sPersonalLootSystem->IsPersonalLootEnabled())
        {
            Group* group = player->GetGroup();
            if (group)
            {
                // Generate personal loot for all group members
                sPersonalLootSystem->GeneratePersonalLootForGroup(killed, group);
            }
            else
            {
                // Generate personal loot for solo player
                sPersonalLootSystem->GeneratePersonalLoot(player, killed);
            }
        }

        // Award progression points based on creature type
        uint32 basePoints = 5; // Normal
        
        if (killed->IsWorldBoss())
            basePoints = 75;
        else if (killed->IsDungeonBoss())
            basePoints = 25;
        else if (killed->IsElite())
            basePoints = 10;

        // Apply difficulty multiplier
        Map* map = player->GetMap();
        if (map && (map->IsDungeon() || map->IsRaid()))
        {
            uint8 difficultyTier = sProgressiveSystems->GetDifficultyTier(player, map);
            if (difficultyTier > 0)
            {
                // Get multiplier from database for this map/difficulty
                float diffMultiplier = sProgressiveSystems->GetDamageMultiplier(map->GetId(), difficultyTier);
                if (diffMultiplier > 1.0f)
                {
                    basePoints = static_cast<uint32>(basePoints * diffMultiplier);
                }
            }
        }

        sProgressiveSystems->AddProgressionPoints(player, basePoints);

        // Update kill count
        uint32 guid = player->GetGUID().GetCounter();
        CharacterDatabase.Execute(
            "INSERT INTO character_progression_unified (guid, total_kills) VALUES ({}, 1) "
            "ON DUPLICATE KEY UPDATE total_kills = total_kills + 1",
            guid);
        
        // Get updated kill count and send to addon
        QueryResult killResult = CharacterDatabase.Query("SELECT total_kills FROM character_progression_unified WHERE guid = {}", guid);
        if (killResult)
        {
            uint32 totalKills = killResult->Fetch()[0].Get<uint32>();
            sProgressiveSystemsAddon->SendKillUpdate(player, totalKills);
        }
    }
    
    void OnMapChanged(Player* player) override
    {
        // Cleanup damage multipliers periodically when player changes maps
        static std::unordered_map<ObjectGuid, time_t> lastCleanup;
        time_t now = GameTime::GetGameTime().count();
        ObjectGuid playerGuid = player->GetGUID();
        
        auto itr = lastCleanup.find(playerGuid);
        if (itr == lastCleanup.end() || now - itr->second > 60)
        {
            CleanupDamageMultipliers();
            lastCleanup[playerGuid] = now;
        }
    }
};

class ProgressiveSystemsWorldScript : public WorldScript
{
public:
    ProgressiveSystemsWorldScript() : WorldScript("ProgressiveSystemsWorldScript", { WORLDHOOK_ON_AFTER_CONFIG_LOAD, WORLDHOOK_ON_STARTUP }) { }

    void OnAfterConfigLoad(bool reload) override
    {
        if (!reload)
        {
            // Validate configuration
            bool enabled = sConfigMgr->GetOption<bool>("ProgressiveSystems.Enable", true);
            if (!enabled)
            {
                LOG_INFO("module", "Progressive Systems Module is DISABLED in configuration.");
                return;
            }
            
            LOG_INFO("module", "===========================================");
            LOG_INFO("module", "Progressive Systems Module Loaded!");
            LOG_INFO("module", "Infinite Progression System Active");
            
            // Log configuration summary
            uint32 mainMenuNPC = sConfigMgr->GetOption<uint32>("ProgressiveSystems.NPC.MainMenu", 190000);
            uint32 maxTier = sConfigMgr->GetOption<uint32>("ProgressiveSystems.Difficulty.MaxTier", 1000);
            bool debug = sConfigMgr->GetOption<bool>("ProgressiveSystems.Debug", false);
            
            LOG_INFO("module", "Main Menu NPC: {}", mainMenuNPC);
            LOG_INFO("module", "Max Difficulty Tier: {}", maxTier);
            LOG_INFO("module", "Debug Mode: {}", debug ? "ENABLED" : "DISABLED");
            LOG_INFO("module", "===========================================");
        }
    }
    
    void OnStartup() override
    {
        // Check if module is enabled
        bool enabled = sConfigMgr->GetOption<bool>("ProgressiveSystems.Enable", true);
        if (!enabled)
        {
            return;
        }
        
        // Auto-setup database tables on server startup
        // This runs automatically when world is initialized
        // Uses existing database connection from worldserver.conf - no passwords needed!
        // Delay slightly to ensure databases are fully connected and ready
        sWorld->GetScheduler().Schedule(2s, [](TaskContext /*context*/)
        {
            LOG_INFO("module", "Initializing Progressive Systems database...");
            sProgressiveSystemsDB->LoadAll();
            LOG_INFO("module", "Progressive Systems database initialized successfully!");
        });
    }
    
    void OnAfterUpdateEncounterState(Map* map, EncounterCreditType /*type*/, uint32 /*creditEntry*/, Unit* /*source*/, Difficulty /*difficulty_fixed*/, std::list<DungeonEncounter const*> const* /*encounters*/, uint32 dungeonCompleted, bool /*updated*/) override
    {
        // Check if dungeon/raid was completed
        if (dungeonCompleted > 0 && map && (map->IsDungeon() || map->IsRaid()))
        {
            // Award completion rewards to all players in instance
            Map::PlayerList const& players = map->GetPlayers();
            for (Map::PlayerList::const_iterator itr = players.begin(); itr != players.end(); ++itr)
            {
                if (Player* player = itr->GetSource())
                {
                    uint8 difficultyTier = sProgressiveSystems->GetDifficultyTier(player, map);
                    sProgressiveSystems->OnInstanceComplete(player, map, difficultyTier);
                    
                    // Track instance completion
                    sInstanceResetSystem->OnInstanceComplete(player, map, difficultyTier);
                }
            }
        }
    }
};

void AddSC_ProgressiveSystemsDifficultyScaling()
{
    new ProgressiveSystemsDifficultyScaling();
    new ProgressiveSystemsPlayerScript();
    new ProgressiveSystemsUnitScript();
    new ProgressiveSystemsWorldScript();
}

// Add addon script registration
void AddSC_ProgressiveSystemsAddonScript()
{
    new ProgressiveSystemsAddonScript();
}

