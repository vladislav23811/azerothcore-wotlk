-- ============================================================
-- Infinite Dungeon Wave Spawning System
-- Handles wave spawning, scaling, and completion
-- ============================================================

local InfiniteDungeonWaves = {}
InfiniteDungeonWaves.activeWaves = {}
InfiniteDungeonWaves.playerFloors = {}

-- Get wave data for a floor
function InfiniteDungeonWaves.GetWaveData(floor)
    local result = WorldDBQuery(string.format(
        "SELECT wave_number, creature_entry, creature_count, spawn_delay, spawn_radius, scaling_multiplier " ..
        "FROM infinite_dungeon_waves " ..
        "WHERE %d BETWEEN floor_range_start AND floor_range_end " ..
        "ORDER BY wave_number",
        floor
    ))
    
    local waves = {}
    if result then
        repeat
            table.insert(waves, {
                wave = result:GetUInt8(0),
                entry = result:GetUInt32(1),
                count = result:GetUInt8(2),
                delay = result:GetUInt32(3),
                radius = result:GetFloat(4),
                scaling = result:GetFloat(5)
            })
        until not result:NextRow()
    end
    
    -- If no waves defined, generate default waves
    if #waves == 0 then
        waves = InfiniteDungeonWaves.GenerateDefaultWaves(floor)
    end
    
    return waves
end

-- Generate default waves if none defined
function InfiniteDungeonWaves.GenerateDefaultWaves(floor)
    local waves = {}
    local baseCreature = 26529  -- Skeletal Construct
    local waveCount = math.min(5, math.floor(floor / 5) + 3)  -- 3-5 waves
    
    for i = 1, waveCount do
        local creatureCount = math.floor(3 + (floor * 0.5) + (i * 0.3))
        table.insert(waves, {
            wave = i,
            entry = baseCreature,
            count = creatureCount,
            delay = (i - 1) * 5000,  -- 5 seconds between waves
            radius = 10.0 + (floor * 0.2),
            scaling = 1.0
        })
    end
    
    return waves
end

-- Spawn a wave
function InfiniteDungeonWaves.SpawnWave(player, floor, waveData)
    if not player or not player:IsInWorld() then
        return
    end
    
    local map = player:GetMap()
    if not map then
        return
    end
    
    local x, y, z, o = player:GetLocation()
    local guid = player:GetGUIDLow()
    
    -- Store active wave info
    if not InfiniteDungeonWaves.activeWaves[guid] then
        InfiniteDungeonWaves.activeWaves[guid] = {
            floor = floor,
            waves = {},
            creatures = {},
            startTime = time()
        }
    end
    
    local waveInfo = {
        waveNumber = waveData.wave,
        creatures = {}
    }
    
    -- Spawn creatures
    for i = 1, waveData.count do
        local angle = (math.pi * 2 * i) / waveData.count
        local spawnX = x + (math.cos(angle) * waveData.radius)
        local spawnY = y + (math.sin(angle) * waveData.radius)
        
        -- Spawn creature using player (WorldObject method)
        local creature = player:SpawnCreature(
            waveData.entry,
            spawnX,
            spawnY,
            z,
            o,
            1,  -- temp spawn (TEMPSUMMON_TIMED_OR_DEAD_DESPAWN)
            300000  -- 5 min despawn
        )
        
        if creature then
            -- Scale creature for floor
            InfiniteDungeonWaves.ScaleCreatureForFloor(creature, floor, waveData.scaling)
            
            -- Set AI
            creature:SetAIEnabled(true)
            creature:SetReactState(1)  -- REACT_AGGRESSIVE
            
            -- Make aggressive to player
            creature:SetFaction(14)  -- Hostile
            
            -- Store creature GUID for tracking
            local creatureGuid = creature:GetGUIDLow()
            table.insert(waveInfo.creatures, creatureGuid)
            table.insert(InfiniteDungeonWaves.activeWaves[guid].creatures, creatureGuid)
            InfiniteDungeonWaves.activeWaves[guid].creaturesSpawned = InfiniteDungeonWaves.activeWaves[guid].creaturesSpawned + 1
        end
    end
    
    table.insert(InfiniteDungeonWaves.activeWaves[guid].waves, waveInfo)
    
    player:SendBroadcastMessage(string.format(
        "|cFF00FF00Wave %d spawned!|r (%d creatures)",
        waveData.wave, waveData.count
    ))
end

-- Scale creature for floor
function InfiniteDungeonWaves.ScaleCreatureForFloor(creature, floor, additionalScaling)
    if not creature then
        return
    end
    
    -- Base multipliers
    local hpMultiplier = 1.0 + (floor * 0.15)  -- 15% per floor
    local dmgMultiplier = 1.0 + (floor * 0.12)  -- 12% per floor
    
    -- Apply additional scaling
    hpMultiplier = hpMultiplier * (additionalScaling or 1.0)
    dmgMultiplier = dmgMultiplier * (additionalScaling or 1.0)
    
    -- Get base health
    local baseHealth = creature:GetMaxHealth()
    if baseHealth == 0 then
        baseHealth = creature:GetCreateHealth()
    end
    
    -- Apply health scaling
    local newHealth = math.floor(baseHealth * hpMultiplier)
    creature:SetMaxHealth(newHealth)
    creature:SetHealth(newHealth)
    
    -- Note: Damage scaling is handled by DifficultyScaling system
    -- This just sets health
end

-- Start floor waves
function InfiniteDungeonWaves.StartFloor(player, floor)
    if not player or not player:IsInWorld() then
        return false
    end
    
    local guid = player:GetGUIDLow()
    InfiniteDungeonWaves.playerFloors[guid] = floor
    
    local waves = InfiniteDungeonWaves.GetWaveData(floor)
    
    if #waves == 0 then
        player:SendBroadcastMessage("|cFFFF0000No waves defined for floor " .. floor .. "|r")
        return false
    end
    
    -- Initialize active waves
    InfiniteDungeonWaves.activeWaves[guid] = {
        floor = floor,
        waves = {},
        creatures = {},
        creaturesSpawned = 0,
        creaturesKilled = 0,
        startTime = time(),
        completed = false
    }
    
    -- Spawn first wave immediately
    InfiniteDungeonWaves.SpawnWave(player, floor, waves[1])
    
    -- Schedule subsequent waves
    for i = 2, #waves do
        local delay = waves[i].delay or 0
        CreateLuaEvent(function()
            if InfiniteDungeonWaves.activeWaves[guid] and not InfiniteDungeonWaves.activeWaves[guid].completed then
                InfiniteDungeonWaves.SpawnWave(player, floor, waves[i])
            end
        end, delay, 1)
    end
    
    player:SendBroadcastMessage(string.format(
        "|cFF00FF00Infinite Dungeon - Floor %d Started!|r\n" ..
        "|cFFAAAAFFWaves: %d|r",
        floor, #waves
    ))
    
    return true
end

-- Check if wave is complete (all creatures dead)
function InfiniteDungeonWaves.CheckWaveComplete(player)
    local guid = player:GetGUIDLow()
    if not InfiniteDungeonWaves.activeWaves[guid] then
        return false
    end
    
    local activeWave = InfiniteDungeonWaves.activeWaves[guid]
    
    -- Check if all creatures are killed using death counter
    local allDead = (activeWave.creaturesKilled >= activeWave.creaturesSpawned) and (activeWave.creaturesSpawned > 0)
    
    if allDead and not activeWave.completed then
        activeWave.completed = true
        InfiniteDungeonWaves.OnFloorComplete(player, activeWave.floor)
        return true
    end
    
    return false
end

-- Floor completion handler
function InfiniteDungeonWaves.OnFloorComplete(player, floor)
    if not player then
        return
    end
    
    local guid = player:GetGUIDLow()
    local completionTime = time() - InfiniteDungeonWaves.activeWaves[guid].startTime
    
    -- Calculate rewards
    local pointsReward = math.floor(Config.InfiniteDungeon.POINTS_PER_FLOOR * 
        (1.0 + (floor * Config.InfiniteDungeon.POINTS_MULTIPLIER_PER_FLOOR)))
    
    -- Award points
    ProgressiveCore.AddProgressionPoints(player, pointsReward)
    
    -- Update database
    CharDBExecute(string.format(
        "UPDATE infinite_dungeon_progress SET " ..
        "current_floor = current_floor + 1, " ..
        "highest_floor = GREATEST(highest_floor, current_floor + 1), " ..
        "total_floors_cleared = total_floors_cleared + 1, " ..
        "best_time = LEAST(COALESCE(best_time, 999999), %d) " ..
        "WHERE guid = %d",
        completionTime, guid
    ))
    
    -- Initialize if doesn't exist
    if CharDBQuery(string.format("SELECT guid FROM infinite_dungeon_progress WHERE guid = %d", guid)) == nil then
        CharDBExecute(string.format(
            "INSERT INTO infinite_dungeon_progress (guid, current_floor, highest_floor, total_floors_cleared, best_time) " ..
            "VALUES (%d, %d, %d, 1, %d)",
            guid, floor + 1, floor + 1, completionTime
        ))
    end
    
    player:SendBroadcastMessage(string.format(
        "|cFF00FF00Floor %d Complete!|r\n" ..
        "|cFF00FF00Time: %d seconds|r\n" ..
        "|cFF00FF00Reward: %d progression points|r\n" ..
        "|cFFAAAAFFAdvancing to Floor %d...|r",
        floor, completionTime, pointsReward, floor + 1
    ))
    
    -- Clear active waves
    InfiniteDungeonWaves.activeWaves[guid] = nil
end

-- Hook into creature death
-- Use player kill event (more reliable than creature-specific events)
local function OnPlayerKillCreature(event, killer, killed)
    if not killer or not killed then
        return
    end
    
    local guid = killer:GetGUIDLow()
    if InfiniteDungeonWaves.activeWaves[guid] then
        local activeWave = InfiniteDungeonWaves.activeWaves[guid]
        local creatureGuid = killed:GetGUIDLow()
        
        -- Check if this creature is part of the active wave
        for _, trackedGuid in ipairs(activeWave.creatures) do
            if trackedGuid == creatureGuid then
                -- Increment kill counter
                activeWave.creaturesKilled = activeWave.creaturesKilled + 1
                
                -- Check if wave is complete
                InfiniteDungeonWaves.CheckWaveComplete(killer)
                break
            end
        end
    end
end

-- Register for all player creature kills (works for any creature)
RegisterPlayerEvent(7, OnPlayerKillCreature)  -- PLAYER_EVENT_ON_KILL_CREATURE

-- Export
_G.InfiniteDungeonWaves = InfiniteDungeonWaves

print("[Progressive Systems] Infinite Dungeon Wave System loaded!")

