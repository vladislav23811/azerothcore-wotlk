/*
 * Infinite Dungeon Wave Spawner
 * Handles spawning waves of creatures for infinite dungeon
 */

#include "InfiniteDungeonWaveSpawner.h"
#include "ProgressiveSystems.h"
#include "RewardDistributionSystem.h"
#include "DailyChallengeSystem.h"
#include "ObjectMgr.h"
#include "Creature.h"
#include "ObjectMgr.h"
#include "CreatureAI.h"
#include "Map.h"
#include "Chat.h"
#include "World.h"
#include "Timer.h"
#include "ObjectAccessor.h"
#include "TemporarySummon.h"
#include "Random.h"
#include "DatabaseEnv.h"
#include "SharedDefines.h"
#include <cmath>
#include <algorithm>
#include <unordered_set>

void InfiniteDungeonWaveSpawner::Initialize()
{
    m_updateTimer = 0;
    LOG_INFO("module", "InfiniteDungeonWaveSpawner initialized");
}

std::vector<uint32> InfiniteDungeonWaveSpawner::GetInstanceCreatureEntries(uint32 mapId) const
{
    std::vector<uint32> creatureEntries;
    std::unordered_set<uint32> seenEntries; // Avoid duplicates
    
    // Query creatures from the instance map
    QueryResult result = WorldDatabase.Query(
        "SELECT DISTINCT id1, id2, id3 FROM creature WHERE map = {} AND (id1 != 0 OR id2 != 0 OR id3 != 0)",
        mapId);
    
    if (result)
    {
        do
        {
            Field* fields = result->Fetch();
            
            // Add all non-zero creature entries
            for (uint8 i = 0; i < 3; ++i)
            {
                uint32 entry = fields[i].Get<uint32>();
                if (entry != 0 && seenEntries.find(entry) == seenEntries.end())
                {
                    // Verify creature template exists and is not a critter/npc
                    if (CreatureTemplate const* cInfo = sObjectMgr->GetCreatureTemplate(entry))
                    {
                        // Only include hostile creatures (exclude critters, NPCs, etc.)
                        if (cInfo->type != CREATURE_TYPE_CRITTER && 
                            (cInfo->flags_extra & CREATURE_FLAG_EXTRA_IGNORE_COMBAT) == 0)
                        {
                            creatureEntries.push_back(entry);
                            seenEntries.insert(entry);
                        }
                    }
                }
            }
        } while (result->NextRow());
    }
    
    // If no creatures found in DB, try creature_template by area or use fallback
    if (creatureEntries.empty())
    {
        LOG_WARN("module", "InfiniteDungeonWaveSpawner: No creatures found for map {}. Using fallback.", mapId);
        // Fallback: use some common creature entries
        creatureEntries.push_back(16360); // Defias Thug (Deadmines)
    }
    
    return creatureEntries;
}

std::vector<uint32> InfiniteDungeonWaveSpawner::GetInstanceBossEntries(uint32 mapId) const
{
    std::vector<uint32> bossEntries;
    std::unordered_set<uint32> seenEntries;
    
    // Query boss encounters from instance_encounters table
    // creditType: 0 = kill creature, 1 = cast spell
    // First, get all creature IDs from this map
    QueryResult creatureResult = WorldDatabase.Query(
        "SELECT DISTINCT id1, id2, id3 FROM creature WHERE map = {}",
        mapId);
    
    std::unordered_set<uint32> mapCreatureIds;
    if (creatureResult)
    {
        do
        {
            Field* fields = creatureResult->Fetch();
            for (uint8 i = 0; i < 3; ++i)
            {
                uint32 id = fields[i].Get<uint32>();
                if (id != 0)
                    mapCreatureIds.insert(id);
            }
        } while (creatureResult->NextRow());
    }
    
    // Now query bosses from instance_encounters that match this map's creatures
    QueryResult result = WorldDatabase.Query("SELECT creditEntry FROM instance_encounters WHERE creditType = 0");
    
    if (result)
    {
        do
        {
            Field* fields = result->Fetch();
            uint32 entry = fields[0].Get<uint32>();
            
            // Only include bosses that exist in this map
            if (entry != 0 && mapCreatureIds.find(entry) != mapCreatureIds.end() && 
                seenEntries.find(entry) == seenEntries.end())
            {
                // Verify it's actually a boss (usually has elite flags)
                if (CreatureTemplate const* cInfo = sObjectMgr->GetCreatureTemplate(entry))
                {
                    // Check if it's flagged as a boss (rank 3 = world boss, rank 1 = elite boss)
                    if (cInfo->rank >= CREATURE_ELITE_ELITE || 
                        (cInfo->flags_extra & CREATURE_FLAG_EXTRA_INSTANCE_BIND) != 0)
                    {
                        bossEntries.push_back(entry);
                        seenEntries.insert(entry);
                    }
                }
            }
        } while (result->NextRow());
    }
    
    // Fallback: If no bosses found, try to find elite creatures with high rank
    if (bossEntries.empty())
    {
        result = WorldDatabase.Query(
            "SELECT DISTINCT id1 FROM creature c "
            "INNER JOIN creature_template ct ON c.id1 = ct.entry "
            "WHERE c.map = {} AND (ct.rank >= 1 OR ct.flags_extra & 0x00000001 != 0) "
            "LIMIT 5",
            mapId);
        
        if (result)
        {
            do
            {
                Field* fields = result->Fetch();
                uint32 entry = fields[0].Get<uint32>();
                if (entry != 0 && seenEntries.find(entry) == seenEntries.end())
                {
                    bossEntries.push_back(entry);
                    seenEntries.insert(entry);
                }
            } while (result->NextRow());
        }
    }
    
    return bossEntries;
}

std::vector<WaveData> InfiniteDungeonWaveSpawner::GetWaveDataForFloor(uint32 floor)
{
    std::vector<WaveData> waves;
    
    // Query wave data from database for this floor
    QueryResult result = WorldDatabase.Query(
        "SELECT wave, creature_entry, count, boss_chance, floor_min, floor_max, scaling_multiplier "
        "FROM bloody_palace_waves "
        "WHERE floor_min <= {} AND floor_max >= {} "
        "ORDER BY wave",
        floor, floor);
    
    if (result)
    {
        do
        {
            Field* fields = result->Fetch();
            WaveData wave;
            wave.wave = fields[0].Get<uint32>();
            wave.creatureEntry = fields[1].Get<uint32>();
            wave.count = fields[2].Get<uint8>();
            wave.bossChance = fields[3].Get<uint8>();
            wave.floorMin = fields[4].Get<uint32>();
            wave.floorMax = fields[5].Get<uint32>();
            wave.scalingMultiplier = fields[6].Get<float>();
            
            waves.push_back(wave);
        } while (result->NextRow());
    }
    
    // If no waves found in DB, we'll generate them dynamically from instance creatures
    // This is handled in StartWaves/SpawnWave
    
    return waves;
}

Position InfiniteDungeonWaveSpawner::GenerateSpawnPosition(Position playerPos)
{
    // Generate position near player (10-20 yard radius)
    float angle = frand(0.0f, 2.0f * float(M_PI));
    float distance = frand(10.0f, 20.0f);
    
    Position spawnPos;
    spawnPos.m_positionX = playerPos.m_positionX + (distance * cos(angle));
    spawnPos.m_positionY = playerPos.m_positionY + (distance * sin(angle));
    spawnPos.m_positionZ = playerPos.m_positionZ;
    spawnPos.m_orientation = frand(0.0f, 2.0f * float(M_PI));
    
    return spawnPos;
}

void InfiniteDungeonWaveSpawner::ScaleCreatureForFloor(Creature* creature, uint32 floor, float multiplier)
{
    if (!creature)
        return;
    
    // Base scaling: 15% health and 12% damage per floor
    float healthMult = (1.0f + (floor * 0.15f)) * multiplier;
    float damageMult = (1.0f + (floor * 0.12f)) * multiplier;
    
    // Apply health scaling
    uint32 baseHealth = creature->GetMaxHealth();
    creature->SetMaxHealth(uint32(baseHealth * healthMult));
    creature->SetHealth(creature->GetMaxHealth());
    
    // Store damage multiplier (will be applied via DifficultyScaling system)
    // We'll set difficulty tier on the instance so DifficultyScaling handles it
    Map* map = creature->GetMap();
    if (map && map->IsDungeon())
    {
        // Set difficulty tier based on floor (each floor = +1 tier)
        uint8 tier = std::min(floor, uint32(MAX_DIFFICULTY_TIER));
        if (sProgressiveSystems)
        {
            sProgressiveSystems->SetDifficultyTierByInstanceId(
                map->GetInstanceId(), map->GetId(), 0, tier);
        }
    }
    
    LOG_DEBUG("module", "InfiniteDungeonWaveSpawner: Scaled creature {} for floor {} (HP: {}x, DMG: {}x)", 
        creature->GetEntry(), floor, healthMult, damageMult);
}

Creature* InfiniteDungeonWaveSpawner::SpawnCreature(Player* player, uint32 entry, Position pos, uint32 floor)
{
    if (!player)
        return nullptr;
    
    Map* map = player->GetMap();
    if (!map)
        return nullptr;
    
    // Summon creature using map's SummonCreature
    TempSummon* summon = map->SummonCreature(
        entry,
        pos,
        nullptr, // properties
        300000,  // 5 minute despawn time
        player,  // summoner
        0,       // spellId
        0,       // vehicleId
        false    // visibleBySummonerOnly
    );
    
    if (!summon)
    {
        LOG_ERROR("module", "InfiniteDungeonWaveSpawner: Failed to spawn creature {}", entry);
        return nullptr;
    }
    
    // Set temporary summon type
    summon->SetTempSummonType(TEMPSUMMON_TIMED_OR_DEAD_DESPAWN);
    summon->SetTimer(300000); // 5 minutes
    
    // Scale creature for floor
    ScaleCreatureForFloor(summon, floor, 1.0f);
    
    // Make aggressive - AI is enabled by default for creatures
    summon->SetReactState(REACT_AGGRESSIVE);
    
    // Attack player - creatures with AI will auto-attack when spawned
    if (summon->IsAIEnabled && summon->AI())
    {
        summon->AI()->AttackStart(player);
    }
    
    return summon;
}

bool InfiniteDungeonWaveSpawner::StartWaves(Player* player, uint32 mapId, uint32 floor)
{
    if (!player)
        return false;
    
    uint32 playerGuid = player->GetGUID().GetCounter();
    
    // Check if already has active waves
    if (m_activeWaves.find(playerGuid) != m_activeWaves.end())
    {
        LOG_WARN("module", "InfiniteDungeonWaveSpawner: Player {} already has active waves", playerGuid);
        return false;
    }
    
    // Create active wave entry
    ActiveWave activeWave;
    activeWave.playerGuid = playerGuid;
    activeWave.mapId = mapId;
    activeWave.floor = floor;
    activeWave.wave = 1;
    activeWave.spawnPosition = player->GetPosition();
    
    m_activeWaves[playerGuid] = activeWave;
    
    // Spawn first wave
    if (!SpawnWave(player, mapId, floor, 1))
    {
        m_activeWaves.erase(playerGuid);
        return false;
    }
    
    LOG_INFO("module", "InfiniteDungeonWaveSpawner: Started waves for player {} (map {}, floor {})", playerGuid, mapId, floor);
    
    if (player->GetSession())
    {
        ChatHandler(player->GetSession()).PSendSysMessage("|cFF00FF00Wave 1 starting!|r");
    }
    
    return true;
}

bool InfiniteDungeonWaveSpawner::SpawnWave(Player* player, uint32 mapId, uint32 floor, uint32 wave)
{
    if (!player)
        return false;
    
    uint32 playerGuid = player->GetGUID().GetCounter();
    
    // Get wave data for this floor
    std::vector<WaveData> allWaves = GetWaveDataForFloor(floor);
    
    WaveData waveData;
    
    // If we have wave data from DB, use it
    if (!allWaves.empty())
    {
        // Find wave number (wave cycles, so use modulo)
        uint32 waveIndex = ((wave - 1) % allWaves.size()) + 1;
        
        bool found = false;
        for (const auto& w : allWaves)
        {
            if (w.wave == waveIndex)
            {
                waveData = w;
                found = true;
                break;
            }
        }
        
        if (!found)
        {
            // Use first wave if exact match not found
            waveData = allWaves[0];
        }
    }
    else
    {
        // Generate wave data dynamically from instance creatures
        std::vector<uint32> instanceCreatures = GetInstanceCreatureEntries(mapId);
        if (instanceCreatures.empty())
        {
            LOG_ERROR("module", "InfiniteDungeonWaveSpawner: No creatures found for map {}", mapId);
            return false;
        }
        
        // Create wave data using instance creatures
        waveData.wave = wave;
        // Select random creature from instance
        waveData.creatureEntry = instanceCreatures[urand(0, instanceCreatures.size() - 1)];
        waveData.count = 3 + (floor / 5); // More creatures as floor increases (3-8)
        waveData.bossChance = (wave % 10 == 0) ? 100 : 0; // Every 10th wave is boss
        waveData.floorMin = floor;
        waveData.floorMax = floor + 10;
        waveData.scalingMultiplier = 1.0f + (floor * 0.15f);
    }
    
    // Check if this should be a boss wave
    bool isBossWave = false;
    if (waveData.bossChance == 100 || (waveData.bossChance > 0 && urand(1, 100) <= waveData.bossChance))
    {
        isBossWave = true;
    }
    
    if (isBossWave)
    {
        // Get boss entries for this instance
        std::vector<uint32> bossEntries = GetInstanceBossEntries(mapId);
        
        if (bossEntries.empty())
        {
            // No bosses found, use elite creatures or fallback to normal creatures
            LOG_WARN("module", "InfiniteDungeonWaveSpawner: No bosses found for map {}, using elite creatures", mapId);
            
            // Try to find elite creatures
            std::vector<uint32> allCreatures = GetInstanceCreatureEntries(mapId);
            for (uint32 entry : allCreatures)
            {
                if (CreatureTemplate const* cInfo = sObjectMgr->GetCreatureTemplate(entry))
                {
                    if (cInfo->rank >= CREATURE_ELITE_ELITE)
                    {
                        bossEntries.push_back(entry);
                        break; // Use first elite found
                    }
                }
            }
            
            // If still no elite, use first regular creature as "boss"
            if (bossEntries.empty() && !allCreatures.empty())
            {
                bossEntries.push_back(allCreatures[0]);
            }
        }
        
        if (!bossEntries.empty())
        {
            // Select random boss from available bosses
            uint32 bossEntry = bossEntries[urand(0, bossEntries.size() - 1)];
            waveData.creatureEntry = bossEntry;
            waveData.count = 1; // Bosses are typically solo
            waveData.scalingMultiplier *= 2.0f; // Bosses are 2x stronger
            
            if (player->GetSession())
            {
                if (CreatureTemplate const* bossInfo = sObjectMgr->GetCreatureTemplate(bossEntry))
                {
                    std::string bossName = bossInfo->Name;
                    ChatHandler(player->GetSession()).PSendSysMessage(
                        "|cFFFF0000>>> BOSS WAVE! <<<|r |cFFFFFF00%s|r |cFFFF0000appears!|r", 
                        bossName.c_str());
                }
                else
                {
                    ChatHandler(player->GetSession()).PSendSysMessage("|cFFFF0000>>> BOSS WAVE! <<<|r");
                }
            }
        }
        else
        {
            LOG_ERROR("module", "InfiniteDungeonWaveSpawner: Failed to find any boss creatures for map {}", mapId);
            return false;
        }
    }
    
    // Update active wave
    ActiveWave* activeWave = GetActiveWave(playerGuid);
    if (activeWave)
    {
        activeWave->wave = wave;
        activeWave->spawnPosition = player->GetPosition();
        activeWave->spawnedCreatures.clear();
    }
    
    // Spawn creatures
    uint8 count = waveData.count;
    for (uint8 i = 0; i < count; ++i)
    {
        Position spawnPos = GenerateSpawnPosition(player->GetPosition());
        
        Creature* creature = SpawnCreature(player, waveData.creatureEntry, spawnPos, floor);
        if (creature && activeWave)
        {
            activeWave->spawnedCreatures.insert(creature->GetGUID());
        }
    }
    
    LOG_INFO("module", "InfiniteDungeonWaveSpawner: Spawned wave {} for player {} (floor {}, {} creatures)", 
        wave, playerGuid, floor, count);
    
    return true;
}

bool InfiniteDungeonWaveSpawner::IsWaveComplete(Player* player)
{
    if (!player)
        return false;
    
    uint32 playerGuid = player->GetGUID().GetCounter();
    ActiveWave* activeWave = GetActiveWave(playerGuid);
    
    if (!activeWave)
        return false;
    
    // Check if all spawned creatures are dead or despawned
    for (auto itr = activeWave->spawnedCreatures.begin(); itr != activeWave->spawnedCreatures.end();)
    {
        Creature* creature = player->GetMap()->GetCreature(*itr);
        if (!creature || creature->isDead())
        {
            itr = activeWave->spawnedCreatures.erase(itr);
        }
        else
        {
            ++itr;
        }
    }
    
    return activeWave->spawnedCreatures.empty();
}

bool InfiniteDungeonWaveSpawner::AdvanceToNextWave(Player* player)
{
    if (!player)
        return false;
    
    uint32 playerGuid = player->GetGUID().GetCounter();
    ActiveWave* activeWave = GetActiveWave(playerGuid);
    
    if (!activeWave)
        return false;
    
    uint32 nextWave = activeWave->wave + 1;
    uint32 mapId = activeWave->mapId;
    uint32 floor = activeWave->floor;
    
    // Check if floor is complete (10 waves per floor)
    if (nextWave > 10)
    {
        // Floor complete - advance floor
        if (sProgressiveSystems)
        {
            sProgressiveSystems->AdvanceFloor(player);
        }
        
        floor = sProgressiveSystems ? sProgressiveSystems->GetCurrentFloor(player) : floor;
        nextWave = 1;
        
        // Award floor completion reward
        if (auto* rewardSystem = RewardDistributionSystem::instance())
        {
            rewardSystem->OnFloorComplete(player, floor - 1); // Reward for completing previous floor
        }
        
        // Update daily challenge progress for floor completion
        if (auto* challengeSystem = DailyChallengeSystem::instance())
        {
            challengeSystem->UpdateChallengeProgress(player, 4, 0, 1); // Type 4 = Infinite Dungeon floors
        }
        
        if (player->GetSession())
        {
            ChatHandler(player->GetSession()).PSendSysMessage(
                "|cFF00FF00Floor {} complete! Advancing to floor {}!|r", floor - 1, floor);
        }
    }
    
    // Spawn next wave
    if (SpawnWave(player, mapId, floor, nextWave))
    {
        activeWave->floor = floor;
        activeWave->wave = nextWave;
        
        if (player->GetSession())
        {
            ChatHandler(player->GetSession()).PSendSysMessage(
                "|cFF00FF00Wave {} starting!|r", nextWave);
        }
        
        return true;
    }
    
    return false;
}

ActiveWave* InfiniteDungeonWaveSpawner::GetActiveWave(uint32 playerGuid)
{
    auto itr = m_activeWaves.find(playerGuid);
    if (itr != m_activeWaves.end())
        return &itr->second;
    return nullptr;
}

void InfiniteDungeonWaveSpawner::OnCreatureDeath(Creature* creature, Player* killer)
{
    if (!creature || !killer)
        return;
    
    uint32 playerGuid = killer->GetGUID().GetCounter();
    ActiveWave* activeWave = GetActiveWave(playerGuid);
    
    if (!activeWave)
        return;
    
    // Check if this was a boss (by checking creature rank)
    bool isBoss = false;
    if (CreatureTemplate const* cInfo = sObjectMgr->GetCreatureTemplate(creature->GetEntry()))
    {
        isBoss = (cInfo->rank >= CREATURE_ELITE_ELITE);
    }
    
    // Award rewards for kill
    if (auto* rewardSystem = RewardDistributionSystem::instance())
    {
        rewardSystem->OnCreatureKilled(killer, creature, activeWave->floor, isBoss);
    }
    
    // Remove from active creatures
    activeWave->spawnedCreatures.erase(creature->GetGUID());
    
    // Check if wave is complete (will be handled in Update)
    // We don't advance immediately to avoid issues with event timing
}

void InfiniteDungeonWaveSpawner::EndWaves(Player* player)
{
    if (!player)
        return;
    
    uint32 playerGuid = player->GetGUID().GetCounter();
    m_activeWaves.erase(playerGuid);
    m_waveDelayTimers.erase(playerGuid); // Also clear delay timer
    
    LOG_INFO("module", "InfiniteDungeonWaveSpawner: Ended waves for player {}", playerGuid);
}

void InfiniteDungeonWaveSpawner::Update(uint32 diff)
{
    m_updateTimer += diff;
    
    // Update delay timers
    for (auto delayItr = m_waveDelayTimers.begin(); delayItr != m_waveDelayTimers.end();)
    {
        if (delayItr->second <= diff)
        {
            // Delay complete - advance wave (after awarding wave completion reward)
            Player* player = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(delayItr->first));
            if (player)
            {
                ActiveWave* activeWave = GetActiveWave(delayItr->first);
                if (activeWave)
                {
                    // Award wave completion reward
                    if (auto* rewardSystem = RewardDistributionSystem::instance())
                    {
                        rewardSystem->OnWaveComplete(player, activeWave->wave, activeWave->floor);
                    }
                }
                AdvanceToNextWave(player);
            }
            delayItr = m_waveDelayTimers.erase(delayItr);
        }
        else
        {
            delayItr->second -= diff;
            ++delayItr;
        }
    }
    
    // Update every 2 seconds to check wave completion
    if (m_updateTimer >= 2000)
    {
        // Check all active waves for completion
        for (auto itr = m_activeWaves.begin(); itr != m_activeWaves.end(); ++itr)
        {
            Player* player = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(itr->first));
            if (player && IsWaveComplete(player))
            {
                // Start delay timer if not already started (3 seconds)
                if (m_waveDelayTimers.find(itr->first) == m_waveDelayTimers.end())
                {
                    m_waveDelayTimers[itr->first] = 3000;
                }
            }
        }
        
        m_updateTimer = 0;
    }
}

