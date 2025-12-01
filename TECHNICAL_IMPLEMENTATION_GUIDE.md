# 🔧 Technical Implementation Guide
## Detailed Implementation Steps for Critical Systems

---

## 1. STAT APPLICATION SYSTEM

### Problem
Item upgrades and paragon stats are stored in database but not applied to character stats.

### Solution Architecture

#### Step 1: Create Stat Enhancement Hook

**File:** `modules/mod-progressive-systems/src/UnifiedStatSystem.cpp`

```cpp
// Add to UnifiedStatSystem class
float UnifiedStatSystem::GetItemUpgradeBonus(Player* player, Item* item, uint32 statType)
{
    if (!player || !item)
        return 0.0f;
    
    uint64 itemGuid = item->GetGUID().GetCounter();
    
    // Check cache first
    auto cacheKey = std::make_pair(itemGuid, statType);
    auto it = itemUpgradeCache.find(cacheKey);
    if (it != itemUpgradeCache.end())
        return it->second;
    
    // Query database
    QueryResult result = CharacterDatabase.Query(
        "SELECT stat_bonus_percent FROM item_upgrades WHERE item_guid = {}",
        itemGuid
    );
    
    if (!result)
    {
        itemUpgradeCache[cacheKey] = 0.0f;
        return 0.0f;
    }
    
    float bonusPercent = result->Fetch()[0].Get<float>();
    
    // Get base stat value from item
    ItemTemplate const* proto = item->GetTemplate();
    float baseStat = GetItemStatValue(proto, statType);
    
    // Calculate bonus
    float bonus = baseStat * (bonusPercent / 100.0f);
    
    // Cache result
    itemUpgradeCache[cacheKey] = bonus;
    
    return bonus;
}

float UnifiedStatSystem::GetParagonStatBonus(Player* player, uint32 statType)
{
    if (!player)
        return 0.0f;
    
    uint32 guid = player->GetGUID().GetCounter();
    
    // Check cache
    auto cacheKey = std::make_pair(guid, statType);
    auto it = paragonStatCache.find(cacheKey);
    if (it != paragonStatCache.end())
        return it->second;
    
    // Query database
    QueryResult result = CharacterDatabase.Query(
        "SELECT ps.points_allocated, pd.points_per_level "
        "FROM character_paragon_stats ps "
        "JOIN paragon_stat_definitions pd ON ps.stat_id = pd.stat_id "
        "WHERE ps.guid = {} AND pd.stat_type = {}",
        guid, statType
    );
    
    float totalBonus = 0.0f;
    if (result)
    {
        do
        {
            Field* fields = result->Fetch();
            uint32 points = fields[0].Get<uint32>();
            float pointsPerLevel = fields[1].Get<float>();
            totalBonus += points * pointsPerLevel;
        } while (result->NextRow());
    }
    
    // Cache result
    paragonStatCache[cacheKey] = totalBonus;
    
    return totalBonus;
}
```

#### Step 2: Hook into Player Stat Calculation

**File:** `src/server/game/Entities/Player/Player.cpp`

Find `Player::GetStatValue()` or similar function and add:

```cpp
float Player::GetStatValue(Stats stat) const
{
    float value = Unit::GetStatValue(stat);
    
    // Apply item upgrade bonuses
    for (uint8 i = 0; i < EQUIPMENT_SLOT_END; ++i)
    {
        Item* item = GetItemByPos(INVENTORY_SLOT_BAG_0, i);
        if (item)
        {
            value += sUnifiedStatSystem->GetItemUpgradeBonus(
                const_cast<Player*>(this), item, stat
            );
        }
    }
    
    // Apply paragon stat bonus
    value += sUnifiedStatSystem->GetParagonStatBonus(
        const_cast<Player*>(this), stat
    );
    
    // Apply prestige bonus
    uint8 prestigeLevel = GetPrestigeLevel();
    if (prestigeLevel > 0)
    {
        value *= (1.0f + prestigeLevel * 0.01f); // 1% per prestige level
    }
    
    return value;
}
```

#### Step 3: Cache Invalidation

**File:** `modules/mod-progressive-systems/src/UnifiedStatSystem.cpp`

```cpp
void UnifiedStatSystem::InvalidateItemCache(uint64 itemGuid)
{
    // Remove all cache entries for this item
    for (auto it = itemUpgradeCache.begin(); it != itemUpgradeCache.end();)
    {
        if (it->first.first == itemGuid)
            it = itemUpgradeCache.erase(it);
        else
            ++it;
    }
}

void UnifiedStatSystem::InvalidateParagonCache(uint32 guid)
{
    // Remove all cache entries for this player
    for (auto it = paragonStatCache.begin(); it != paragonStatCache.end();)
    {
        if (it->first.first == guid)
            it = paragonStatCache.erase(it);
        else
            ++it;
    }
}
```

Call these when:
- Item is upgraded
- Paragon points are allocated
- Player logs in (clear old cache)

#### Step 4: Testing

```cpp
// Test function
void TestStatApplication(Player* player)
{
    // Get base stat
    float baseStr = player->GetStatValue(STAT_STRENGTH);
    
    // Upgrade an item
    UpgradeItem(player, itemGuid);
    
    // Get new stat
    float newStr = player->GetStatValue(STAT_STRENGTH);
    
    // Verify increase
    ASSERT(newStr > baseStr);
}
```

---

## 2. ADDON COMMUNICATION SYSTEM

### Problem
Addon shows placeholder data instead of real server data.

### Solution Architecture

#### Step 1: Create Data Structure

**File:** `modules/mod-progressive-systems/src/ProgressiveSystemsAddon.h`

```cpp
struct ProgressionData
{
    uint32 guid;
    uint32 progressionPoints;
    uint32 currentTier;
    uint32 prestigeLevel;
    uint32 powerLevel;
    
    // Paragon data
    struct ParagonData
    {
        uint32 level;
        uint32 tier;
        uint32 points;
        uint64 experience;
        uint64 expNeeded;
    } paragon;
    
    // Item upgrade data
    struct ItemUpgradeData
    {
        uint64 itemGuid;
        uint32 upgradeLevel;
    };
    std::vector<ItemUpgradeData> itemUpgrades;
};
```

#### Step 2: Serialize to Lua Table Format

**File:** `modules/mod-progressive-systems/src/ProgressiveSystemsAddon.cpp`

```cpp
std::string SerializeProgressionData(const ProgressionData& data)
{
    std::ostringstream ss;
    
    ss << "{";
    ss << "guid=" << data.guid << ",";
    ss << "points=" << data.progressionPoints << ",";
    ss << "tier=" << data.currentTier << ",";
    ss << "prestige=" << data.prestigeLevel << ",";
    ss << "power=" << data.powerLevel << ",";
    
    // Paragon data
    ss << "paragon={";
    ss << "level=" << data.paragon.level << ",";
    ss << "tier=" << data.paragon.tier << ",";
    ss << "points=" << data.paragon.points << ",";
    ss << "exp=" << data.paragon.experience << ",";
    ss << "expNeeded=" << data.paragon.expNeeded;
    ss << "},";
    
    // Item upgrades
    ss << "items={";
    for (size_t i = 0; i < data.itemUpgrades.size(); ++i)
    {
        if (i > 0) ss << ",";
        ss << "{guid=" << data.itemUpgrades[i].itemGuid;
        ss << ",level=" << data.itemUpgrades[i].upgradeLevel << "}";
    }
    ss << "}";
    
    ss << "}";
    
    return ss.str();
}
```

#### Step 3: Send Data to Client

**File:** `modules/mod-progressive-systems/src/ProgressiveSystemsAddon.cpp`

```cpp
void SendProgressionData(Player* player)
{
    if (!player)
        return;
    
    // Get real data
    ProgressionData data = GetProgressionData(player);
    
    // Serialize
    std::string luaData = SerializeProgressionData(data);
    
    // Send via addon message
    WorldPacket data(SMSG_MESSAGE_CHAT);
    data << uint8(CHAT_MSG_ADDON);
    data << std::string("ProgressiveSystems");
    data << std::string("PROGRESSION_DATA");
    data << luaData;
    data << uint8(0); // Chat tag
    
    player->SendDirectMessage(&data);
}

ProgressionData GetProgressionData(Player* player)
{
    ProgressionData data;
    data.guid = player->GetGUID().GetCounter();
    
    // Get progression points
    QueryResult result = CharacterDatabase.Query(
        "SELECT progression_points, current_tier, prestige_level "
        "FROM character_progression_unified WHERE guid = {}",
        data.guid
    );
    
    if (result)
    {
        Field* fields = result->Fetch();
        data.progressionPoints = fields[0].Get<uint32>();
        data.currentTier = fields[1].Get<uint8>();
        data.prestigeLevel = fields[2].Get<uint8>();
    }
    
    // Get power level
    data.powerLevel = CalculatePowerLevel(player);
    
    // Get paragon data
    result = CharacterDatabase.Query(
        "SELECT paragon_level, paragon_tier, paragon_points_available, "
        "paragon_experience FROM character_paragon WHERE guid = {}",
        data.guid
    );
    
    if (result)
    {
        Field* fields = result->Fetch();
        data.paragon.level = fields[0].Get<uint32>();
        data.paragon.tier = fields[1].Get<uint8>();
        data.paragon.points = fields[2].Get<uint32>();
        data.paragon.experience = fields[3].Get<uint64>();
        data.paragon.expNeeded = GetExpForNextParagonLevel(data.paragon.level);
    }
    
    // Get item upgrades
    result = CharacterDatabase.Query(
        "SELECT item_guid, upgrade_level FROM item_upgrades "
        "WHERE item_guid IN (SELECT item_guid FROM character_inventory WHERE guid = {})",
        data.guid
    );
    
    if (result)
    {
        do
        {
            Field* fields = result->Fetch();
            ProgressionData::ItemUpgradeData upgrade;
            upgrade.itemGuid = fields[0].Get<uint64>();
            upgrade.upgradeLevel = fields[1].Get<uint32>();
            data.itemUpgrades.push_back(upgrade);
        } while (result->NextRow());
    }
    
    return data;
}
```

#### Step 4: Receive in Addon

**File:** `modules/mod-progressive-systems/addon/ProgressiveSystems/ProgressiveSystems.lua`

```lua
local frame = CreateFrame("Frame")
frame:RegisterEvent("CHAT_MSG_ADDON")

frame:SetScript("OnEvent", function(self, event, prefix, message, ...)
    if prefix == "ProgressiveSystems" then
        if message:match("^PROGRESSION_DATA:") then
            local dataStr = message:match("^PROGRESSION_DATA:(.*)")
            local data = loadstring("return " .. dataStr)()
            
            if data then
                ProgressiveSystems:UpdateProgressionData(data)
            end
        end
    end
end)

function ProgressiveSystems:UpdateProgressionData(data)
    -- Update UI with real data
    if self.UI then
        self.UI:UpdateProgressionTab(data)
        self.UI:UpdateParagonTab(data.paragon)
        self.UI:UpdateItemsTab(data.items)
    end
end
```

#### Step 5: Send on Events

**File:** `modules/mod-progressive-systems/src/ProgressiveSystemsAddon.cpp`

```cpp
// On player login
void OnPlayerLogin(Player* player)
{
    SendProgressionData(player);
}

// On progression points change
void OnProgressionPointsChanged(Player* player)
{
    SendProgressionData(player);
}

// On item upgrade
void OnItemUpgraded(Player* player, uint64 itemGuid)
{
    SendProgressionData(player);
}

// Periodic update (every 5 seconds)
void UpdateAddonData()
{
    SessionMap const& sessions = sWorld->GetAllSessions();
    for (auto& session : sessions)
    {
        if (Player* player = session.second->GetPlayer())
        {
            SendProgressionData(player);
        }
    }
}
```

---

## 3. INFINITE DUNGEON WAVE SYSTEM

### Problem
Infinite dungeon NPC exists but doesn't spawn creatures.

### Solution Architecture

#### Step 1: Create Wave Definition System

**File:** `modules/mod-progressive-systems/data/sql/world/base/infinite_dungeon_waves.sql`

```sql
CREATE TABLE IF NOT EXISTS `infinite_dungeon_waves` (
    `wave_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `floor_range_start` INT UNSIGNED NOT NULL,
    `floor_range_end` INT UNSIGNED NOT NULL,
    `wave_number` TINYINT UNSIGNED NOT NULL,
    `creature_entry` INT UNSIGNED NOT NULL,
    `creature_count` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `spawn_delay` INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`wave_id`),
    INDEX `idx_floor` (`floor_range_start`, `floor_range_end`)
) ENGINE=InnoDB;

-- Example waves
INSERT INTO `infinite_dungeon_waves` VALUES
(1, 1, 10, 1, 12345, 5, 0),  -- Floor 1-10, Wave 1: 5 creatures
(2, 1, 10, 2, 12346, 3, 5000), -- Wave 2: 3 creatures after 5 seconds
(3, 11, 20, 1, 12347, 7, 0), -- Floor 11-20: More creatures
-- etc.
```

#### Step 2: Implement Wave Spawning

**File:** `modules/mod-progressive-systems/lua_scripts/infinite_dungeon_waves.lua`

```lua
local InfiniteDungeon = {}

function InfiniteDungeon.GetWaveData(floor)
    local result = WorldDBQuery(string.format(
        "SELECT wave_number, creature_entry, creature_count, spawn_delay " ..
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
                delay = result:GetUInt32(3)
            })
        until not result:NextRow()
    end
    
    return waves
end

function InfiniteDungeon.SpawnWave(player, floor, waveData)
    local map = player:GetMap()
    if not map then return end
    
    local x, y, z, o = player:GetLocation()
    
    for i = 1, waveData.count do
        local spawnX = x + math.random(-15, 15)
        local spawnY = y + math.random(-15, 15)
        
        local creature = map:SpawnCreature(
            waveData.entry,
            spawnX,
            spawnY,
            z,
            o,
            1, -- temp spawn
            300000 -- 5 min despawn
        )
        
        if creature then
            -- Scale creature for floor
            InfiniteDungeon.ScaleCreatureForFloor(creature, floor)
            
            -- Set AI
            creature:SetAIEnabled(true)
            creature:SetReactState(1) -- REACT_AGGRESSIVE
        end
    end
end

function InfiniteDungeon.ScaleCreatureForFloor(creature, floor)
    -- Get base stats
    local baseHealth = creature:GetMaxHealth()
    local baseDamage = creature:GetBaseDamage()
    
    -- Calculate multipliers
    local healthMult = 1.0 + (floor * 0.15)  -- 15% per floor
    local damageMult = 1.0 + (floor * 0.12)  -- 12% per floor
    
    -- Apply scaling
    creature:SetMaxHealth(math.floor(baseHealth * healthMult))
    creature:SetHealth(creature:GetMaxHealth())
    
    -- Apply damage multiplier via aura or direct stat modification
    -- (Implementation depends on available Lua API)
end

function InfiniteDungeon.StartFloor(player, floor)
    local waves = InfiniteDungeon.GetWaveData(floor)
    
    if #waves == 0 then
        player:SendBroadcastMessage("No waves defined for floor " .. floor)
        return
    end
    
    -- Spawn first wave immediately
    InfiniteDungeon.SpawnWave(player, floor, waves[1])
    
    -- Schedule subsequent waves
    for i = 2, #waves do
        local delay = waves[i].delay or 0
        CreateLuaEvent(function()
            InfiniteDungeon.SpawnWave(player, floor, waves[i])
        end, delay, 1)
    end
end

return InfiniteDungeon
```

#### Step 3: Integrate with NPC

**File:** `modules/mod-progressive-systems/lua_scripts/infinite_dungeon_npc.lua`

```lua
dofile("infinite_dungeon_waves.lua")

local function OnGossipSelect(event, player, creature, sender, intid, code)
    if intid == 1 then -- Start floor
        local floor = GetCurrentFloor(player)
        InfiniteDungeon.StartFloor(player, floor)
        player:SendBroadcastMessage("Starting floor " .. floor)
    end
end
```

---

## 4. PERFORMANCE OPTIMIZATION

### Database Indexes

**File:** `modules/mod-progressive-systems/data/sql/characters/base/performance_indexes.sql`

```sql
-- Character progression indexes
CREATE INDEX IF NOT EXISTS `idx_progression_guid` ON `character_progression_unified` (`guid`);
CREATE INDEX IF NOT EXISTS `idx_progression_tier` ON `character_progression_unified` (`current_tier`);

-- Item upgrades indexes
CREATE INDEX IF NOT EXISTS `idx_item_upgrade_guid` ON `item_upgrades` (`item_guid`);

-- Paragon indexes
CREATE INDEX IF NOT EXISTS `idx_paragon_guid` ON `character_paragon` (`guid`);
CREATE INDEX IF NOT EXISTS `idx_paragon_level` ON `character_paragon` (`paragon_level`);
CREATE INDEX IF NOT EXISTS `idx_paragon_stats_guid` ON `character_paragon_stats` (`guid`, `stat_type`);

-- Instance difficulty indexes
CREATE INDEX IF NOT EXISTS `idx_instance_id` ON `instance_difficulty_tracking` (`instance_id`);
```

### Caching Strategy

**File:** `modules/mod-progressive-systems/src/ProgressiveSystemsCache.cpp`

```cpp
class ProgressionCache
{
private:
    struct CacheEntry
    {
        std::any data;
        std::chrono::steady_clock::time_point expiry;
    };
    
    std::unordered_map<uint32, CacheEntry> playerCache;
    std::mutex cacheMutex;
    static constexpr auto CACHE_TTL = std::chrono::minutes(5);
    
public:
    template<typename T>
    bool Get(uint32 guid, T& value)
    {
        std::lock_guard<std::mutex> lock(cacheMutex);
        
        auto it = playerCache.find(guid);
        if (it == playerCache.end())
            return false;
        
        if (it->second.expiry < std::chrono::steady_clock::now())
        {
            playerCache.erase(it);
            return false;
        }
        
        try
        {
            value = std::any_cast<T>(it->second.data);
            return true;
        }
        catch (...)
        {
            return false;
        }
    }
    
    template<typename T>
    void Set(uint32 guid, const T& value)
    {
        std::lock_guard<std::mutex> lock(cacheMutex);
        
        CacheEntry entry;
        entry.data = value;
        entry.expiry = std::chrono::steady_clock::now() + CACHE_TTL;
        
        playerCache[guid] = entry;
    }
    
    void Invalidate(uint32 guid)
    {
        std::lock_guard<std::mutex> lock(cacheMutex);
        playerCache.erase(guid);
    }
    
    void Clear()
    {
        std::lock_guard<std::mutex> lock(cacheMutex);
        playerCache.clear();
    }
};
```

---

## TESTING CHECKLIST

### Stat Application Testing
- [ ] Item upgrade increases stats
- [ ] Paragon points increase stats
- [ ] Prestige bonus applies
- [ ] Stats update immediately
- [ ] Cache works correctly
- [ ] Multiple stat types work

### Addon Communication Testing
- [ ] Data sends on login
- [ ] Data updates on changes
- [ ] Addon receives data
- [ ] UI updates correctly
- [ ] Multiple players work
- [ ] No memory leaks

### Infinite Dungeon Testing
- [ ] Waves spawn correctly
- [ ] Creatures scale properly
- [ ] Rewards given on completion
- [ ] Floor progression works
- [ ] Multiple players can run simultaneously

---

**This guide provides the technical foundation. Adapt to your specific codebase structure and API availability.**

