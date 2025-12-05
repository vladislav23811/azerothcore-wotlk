/*
 * Infinite Dungeon Wave Spawner
 * Handles spawning waves of creatures for infinite dungeon
 */

#ifndef INFINITE_DUNGEON_WAVE_SPAWNER_H
#define INFINITE_DUNGEON_WAVE_SPAWNER_H

#include "Define.h"
#include "Player.h"
#include "Creature.h"
#include "Map.h"
#include "DatabaseEnv.h"
#include "Log.h"
#include "Position.h"
#include <vector>
#include <unordered_set>

struct WaveData
{
    uint32 wave;
    uint32 creatureEntry;
    uint8 count;
    uint8 bossChance;
    uint32 floorMin;
    uint32 floorMax;
    float scalingMultiplier;
    
    WaveData() : wave(0), creatureEntry(0), count(0), bossChance(0), 
        floorMin(1), floorMax(255), scalingMultiplier(1.0f) {}
};

struct ActiveWave
{
    uint32 playerGuid;
    uint32 mapId;
    uint32 floor;
    uint32 wave;
    std::unordered_set<ObjectGuid> spawnedCreatures;
    Position spawnPosition;
    
    ActiveWave() : playerGuid(0), mapId(0), floor(1), wave(0) {}
};

class InfiniteDungeonWaveSpawner
{
public:
    static InfiniteDungeonWaveSpawner* instance()
    {
        static InfiniteDungeonWaveSpawner instance;
        return &instance;
    }
    
    void Initialize();
    
    // Start wave spawning for a player
    bool StartWaves(Player* player, uint32 mapId, uint32 floor);
    
    // Spawn a specific wave
    bool SpawnWave(Player* player, uint32 mapId, uint32 floor, uint32 wave);
    
    // Check if all creatures in current wave are dead
    bool IsWaveComplete(Player* player);
    
    // Advance to next wave
    bool AdvanceToNextWave(Player* player);
    
    // Get active wave data
    ActiveWave* GetActiveWave(uint32 playerGuid);
    
    // Handle creature death
    void OnCreatureDeath(Creature* creature, Player* killer);
    
    // End wave spawning for player
    void EndWaves(Player* player);
    
    // Update (check for wave completion, etc.)
    void Update(uint32 diff);
    
private:
    InfiniteDungeonWaveSpawner() = default;
    ~InfiniteDungeonWaveSpawner() = default;
    InfiniteDungeonWaveSpawner(const InfiniteDungeonWaveSpawner&) = delete;
    InfiniteDungeonWaveSpawner& operator=(const InfiniteDungeonWaveSpawner&) = delete;
    
    // Load wave data from database for a floor
    std::vector<WaveData> GetWaveDataForFloor(uint32 floor);
    
    // Get creatures from instance map_id (for loot purposes)
    std::vector<uint32> GetInstanceCreatureEntries(uint32 mapId) const;
    
    // Get boss creatures from instance map_id
    std::vector<uint32> GetInstanceBossEntries(uint32 mapId) const;
    
    // Spawn a single creature
    Creature* SpawnCreature(Player* player, uint32 entry, Position pos, uint32 floor);
    
    // Scale creature for floor
    void ScaleCreatureForFloor(Creature* creature, uint32 floor, float multiplier);
    
    // Generate spawn position near player
    Position GenerateSpawnPosition(Position playerPos);
    
    // Active waves: playerGuid -> ActiveWave
    std::unordered_map<uint32, ActiveWave> m_activeWaves;
    
    // Update timer for checking wave completion
    uint32 m_updateTimer;
    
    // Wave delay timers (for delay between waves)
    std::unordered_map<uint32, uint32> m_waveDelayTimers;
};

#define sInfiniteDungeonWaveSpawner InfiniteDungeonWaveSpawner::instance()

#endif // INFINITE_DUNGEON_WAVE_SPAWNER_H

