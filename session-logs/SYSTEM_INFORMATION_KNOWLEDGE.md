# System Information Knowledge Base
## MyClubGames.com - Browser Multiplayer Game Project

**Purpose:** Comprehensive reference for all game systems, architecture, and technical implementation details  
**Project Type:** Browser-based multiplayer strategy game (Tribal Wars-inspired, Warhammer universe themed)  
**Technology Stack:** AzerothCore (C++), MySQL, Lua Scripts, Server-Side Only Implementation

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Core Architecture](#core-architecture)
3. [Game Systems](#game-systems)
4. [Progression Systems](#progression-systems)
5. [Combat & PvP](#combat--pvp)
6. [Economy & Trading](#economy--trading)
7. [Social Features](#social-features)
8. [Technical Infrastructure](#technical-infrastructure)
9. [Module System](#module-system)
10. [Database Schema](#database-schema)
11. [API Reference](#api-reference)
12. [Quick Reference](#quick-reference)

---

## Project Overview

### Vision
MyClubGames.com is a browser-based multiplayer game combining:
- **Strategic Gameplay**: Tribal Wars-style base building and resource management
- **Age Progression**: Players advance through different historical/fantasy ages
- **Warhammer Universe Flavor**: Dark fantasy themes and faction warfare
- **Infinite Progression**: Never-ending character development systems

### Core Pillars
1. **Accessibility**: Browser-based, no client modifications required
2. **Depth**: Multiple interconnected progression systems
3. **Competition**: PvP, leaderboards, and seasonal content
4. **Longevity**: Infinite scaling ensures long-term engagement

---

## Core Architecture

### Server Components

| Component | Purpose | Technology |
|-----------|---------|------------|
| **WorldServer** | Main game logic, player interactions | C++ |
| **AuthServer** | Authentication, account management | C++ |
| **Database Layer** | Persistent storage | MySQL |
| **Script System** | Custom content, encounters | C++/Lua |
| **Module System** | Extensible plugins | C++ |

### Directory Structure

```
src/server/
├── apps/           - Server executables
│   ├── authserver/     - Authentication server
│   └── worldserver/    - Main game server
├── database/       - Database abstraction layer
├── game/           - Core game logic (79 subsystems)
│   ├── AI/             - Creature AI systems
│   ├── Battlegrounds/  - PvP content
│   ├── Combat/         - Combat mechanics
│   ├── Entities/       - Player, Creature, Item, etc.
│   ├── Grids/          - World grid system
│   ├── Maps/           - Map management
│   ├── Movement/       - Pathfinding, motion
│   ├── Scripting/      - Script hooks
│   └── Spells/         - Spell system
├── scripts/        - Scripted content
└── shared/         - Shared utilities
```

### Request Flow

```
Client Request → AuthServer (Login) → WorldServer → Handler
     ↓
Database Query → Business Logic → Response → Client
```

---

## Game Systems

### 1. Entity System

#### Player Entity
- **Location**: `src/server/game/Entities/Player/`
- **Complexity**: Highest in codebase (~30,000 lines)
- **Responsibilities**: 
  - Character data (race, class, level, stats)
  - Inventory management
  - Quest tracking
  - Talents and spells
  - Social features

#### Creature Entity
- **Location**: `src/server/game/Entities/Creature/`
- **Types**: NPCs, monsters, bosses
- **AI Systems**: CoreAI, ScriptedAI, SmartScripts

#### Item Entity
- **Location**: `src/server/game/Entities/Item/`
- **Features**: Equipment, consumables, upgrades

### 2. Spell System

| Component | Lines | Purpose |
|-----------|-------|---------|
| Spell.cpp | 9,112 | Main spell casting logic |
| SpellInfo.cpp | - | Spell data definitions |
| SpellEffects.cpp | 6,000+ | Effect handlers |
| SpellAuras.cpp | - | Aura management |

**Key Features:**
- 1000+ spell types
- Complex effect chains
- Aura stacking/unstacking
- Cooldown management

### 3. AI System

**AI Types:**
- **CoreAI**: Basic behaviors (Pet, Totem, Guard, Reactor)
- **ScriptedAI**: Boss encounters with phases
- **SmartScripts**: Data-driven AI (database-configured)

**Threat System:**
- ThreatMgr for aggro management
- HostileRefMgr for enemy tracking
- Combat formulas in Formulas.h

### 4. Map & Grid System

**Components:**
- Map.cpp: Main map container
- MapManager.cpp: Map lifecycle
- GridObjectLoader.cpp: Dynamic loading
- GridTerrainData.cpp: Terrain information

**Grid System:**
- World divided into grids for efficiency
- Visibility calculations per grid
- Dynamic loading/unloading

### 5. Movement System

**Files:** 42 files (23 .h, 19 .cpp)

**Key Components:**
- MotionMaster: Movement state machine
- PathGenerator: Pathfinding (uses Recast library)
- MoveSpline: Smooth movement curves
- Various motion generators

---

## Progression Systems

### 1. Infinite Difficulty Scaling

**Concept:** Unlimited difficulty tiers beyond standard content
- Normal → Heroic → Mythic+1 → Mythic+2 → ... → Mythic+∞

**Database Schema:**
```sql
CREATE TABLE `custom_difficulty_scaling` (
  `map_id` INT UNSIGNED NOT NULL,
  `difficulty_tier` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `health_multiplier` FLOAT NOT NULL DEFAULT 1.0,
  `damage_multiplier` FLOAT NOT NULL DEFAULT 1.0,
  `loot_quality_bonus` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `experience_multiplier` FLOAT NOT NULL DEFAULT 1.0,
  `required_item_level` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `reward_points` INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`map_id`, `difficulty_tier`)
);
```

**Scaling Formula:**
- Health: Base × (1.0 + tier × 0.15)
- Damage: Base × (1.0 + tier × 0.12)

### 2. Item Upgrade System

**Features:**
- Infinite upgrade levels
- Stat bonus per upgrade (+5-10%)
- Progressive cost scaling

**Database Schema:**
```sql
CREATE TABLE `item_upgrades` (
  `item_guid` BIGINT UNSIGNED NOT NULL,
  `upgrade_level` INT UNSIGNED NOT NULL DEFAULT 0,
  `stat_bonus_percent` FLOAT NOT NULL DEFAULT 0.0,
  `upgrade_cost_progression_points` INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`item_guid`)
);
```

### 3. Prestige System

**Concept:** After max level, "prestige" to gain permanent bonuses

**Bonuses per Prestige Level:**
- +1% all stats
- Higher loot quality chance
- Faster leveling (if reset)
- Unique titles and cosmetics

### 4. Paragon System

**Concept:** Post-prestige progression for advanced players

**Database Schema:**
```sql
CREATE TABLE `character_paragon` (
  `guid` INT UNSIGNED NOT NULL,
  `paragon_level` INT UNSIGNED NOT NULL DEFAULT 0,
  `paragon_tier` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `paragon_points_available` INT UNSIGNED NOT NULL DEFAULT 0,
  `paragon_experience` BIGINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`guid`)
);

CREATE TABLE `character_paragon_stats` (
  `guid` INT UNSIGNED NOT NULL,
  `stat_id` INT UNSIGNED NOT NULL,
  `points_allocated` INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`guid`, `stat_id`)
);
```

### 5. Power Level System

**Calculation Formula:**
```cpp
uint32 CalculatePlayerPowerLevel(Player* player)
{
    uint32 power = 0;
    
    // Base stats contribution
    power += player->GetTotalStatValue(STAT_STRENGTH);
    power += player->GetTotalStatValue(STAT_AGILITY);
    power += player->GetTotalStatValue(STAT_STAMINA);
    power += player->GetTotalStatValue(STAT_INTELLECT);
    power += player->GetTotalStatValue(STAT_SPIRIT);
    
    // Item level contribution
    power += GetAverageItemLevel(player) * 10;
    
    // Upgrade bonuses
    power += GetTotalUpgradeLevels(player) * 50;
    
    // Prestige bonus
    power += GetPrestigeLevel(player) * 1000;
    
    return power;
}
```

### 6. Infinite Dungeon Mode

**Features:**
- Procedurally selected encounters
- Floor-based progression
- Scaling difficulty per floor
- Boss every 5 floors
- Reward scaling every 10 floors

**Database Schema:**
```sql
CREATE TABLE `infinite_dungeon_progress` (
  `guid` INT UNSIGNED NOT NULL,
  `current_floor` INT UNSIGNED NOT NULL DEFAULT 1,
  `highest_floor` INT UNSIGNED NOT NULL DEFAULT 1,
  `total_floors_cleared` INT UNSIGNED NOT NULL DEFAULT 0,
  `dungeon_type` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`guid`)
);
```

---

## Combat & PvP

### Combat System

**Key Files:**
- `Combat/ThreatMgr.cpp`: Threat/aggro management
- `Combat/HostileRefMgr.cpp`: Enemy tracking
- `Combat/Formulas.h`: Damage, XP, honor calculations

**Combat Flow:**
1. Spell/Attack initiated
2. Hit/miss calculation
3. Damage calculation (with modifiers)
4. Threat generated
5. Effects applied (debuffs, procs)
6. Rewards distributed

### Battlegrounds

**Available BGs (46 files):**
- Alterac Valley (AV)
- Warsong Gulch (WSG)
- Arathi Basin (AB)
- Eye of the Storm (EotS)
- Strand of the Ancients (SoA)
- Isle of Conquest (IoC)
- Various arenas (2v2, 3v3, 5v5)

### Arena System

**Features:**
- Rating-based matchmaking
- Seasonal rewards
- Team and solo queue options
- 1v1, 2v2, 3v3, 5v5 formats

---

## Economy & Trading

### Currency Systems

1. **Gold**: Standard currency
2. **Honor Points**: PvP currency
3. **Arena Points**: Competitive PvP currency
4. **Progression Points**: Custom upgrade currency

### Progression Points Sources

| Activity | Base Points | Notes |
|----------|-------------|-------|
| Dungeon Completion | 100+ | × difficulty multiplier |
| Boss Kills | 50+ | Based on boss tier |
| Daily Quests | 25-100 | Bonus for first completion |
| Achievements | Varies | One-time rewards |
| BG Wins | 50+ | Points for participation too |

### Trading System

- Player-to-player trades
- Auction House integration
- Mail system with attachments

---

## Social Features

### Guild System

**Features:**
- Guild banks
- Guild ranks with permissions
- Guild achievements
- Guild progression bonuses (planned)

### Party/Raid System

- 5-player parties
- 10/25-player raids
- Cross-faction support (mod-cfbg)
- Loot distribution systems

### Communication

- Chat channels
- Whispers
- Guild chat
- Mail system

---

## Technical Infrastructure

### Database Layer

**Databases:**
- `auth`: Account data
- `characters`: Player data
- `world`: Game content

**Connection Pooling:**
- DatabaseWorkerPool for connections
- PreparedStatements for SQL injection prevention
- QueryCallback for async operations
- Transaction support for ACID operations

### Network Layer

**Components:**
- WorldSession: Session management
- WorldSocket: Network communication
- PacketIO: Serialization
- Opcodes: Packet type definitions

**Handler Count:** 36 handler files covering all packet types

### Caching Strategy

```cpp
class ProgressionCache
{
private:
    std::unordered_map<uint32, CacheEntry> playerCache;
    std::mutex cacheMutex;
    static constexpr auto CACHE_TTL = std::chrono::minutes(5);
    
public:
    template<typename T>
    bool Get(uint32 guid, T& value);
    
    template<typename T>
    void Set(uint32 guid, const T& value);
    
    void Invalidate(uint32 guid);
    void Clear();
};
```

### Performance Indexes

```sql
-- Critical indexes for performance
CREATE INDEX `idx_progression_guid` ON `character_progression_unified` (`guid`);
CREATE INDEX `idx_item_upgrade_guid` ON `item_upgrades` (`item_guid`);
CREATE INDEX `idx_paragon_guid` ON `character_paragon` (`guid`);
CREATE INDEX `idx_paragon_stats_guid` ON `character_paragon_stats` (`guid`, `stat_type`);
```

---

## Module System

### Overview

The module system allows extending server functionality without modifying core code.

**Location:** `modules/`

### Installed/Planned Modules

| Module | Purpose | Status |
|--------|---------|--------|
| mod-playerbots | AI-controlled player bots | Installed |
| mod-progressive-systems | Custom progression | In Development |
| mod-autobalance | Solo content scaling | Installed |
| mod-transmog | Appearance system | Installed |
| mod-1v1-arena | 1v1 PvP | Installed |
| mod-solo-lfg | Solo dungeon finder | Installed |
| mod-premium | Premium features | Installed |
| mod-reward-shop | Item shop | Installed |
| mod-random-enchants | Randomized gear | Installed |
| mod-character-tools | Character management | Installed |
| mod-npc-beastmaster | Pet management NPC | Installed |
| mod-arena-3v3-solo-queue | 3v3 solo queue | Installed |

### Creating Modules

See `modules/how_to_make_a_module.md` for detailed instructions.

**Basic Structure:**
```
mod-example/
├── CMakeLists.txt
├── src/
│   ├── ModuleLoader.cpp
│   └── ExampleScript.cpp
├── data/
│   └── sql/
│       ├── world/
│       └── characters/
└── conf/
    └── example.conf.dist
```

---

## Database Schema

### Core Tables

#### Character Progression
```sql
CREATE TABLE `character_progression_unified` (
  `guid` INT UNSIGNED NOT NULL,
  `progression_points` BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `current_tier` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `prestige_level` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `total_power_level` INT UNSIGNED NOT NULL DEFAULT 0,
  `highest_difficulty` INT UNSIGNED NOT NULL DEFAULT 0,
  `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`)
);
```

#### Infinite Dungeon Waves
```sql
CREATE TABLE `infinite_dungeon_waves` (
  `wave_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `floor_range_start` INT UNSIGNED NOT NULL,
  `floor_range_end` INT UNSIGNED NOT NULL,
  `wave_number` TINYINT UNSIGNED NOT NULL,
  `creature_entry` INT UNSIGNED NOT NULL,
  `creature_count` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `spawn_delay` INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`wave_id`)
);
```

#### Seasonal Progress
```sql
CREATE TABLE `seasonal_progress` (
  `guid` INT UNSIGNED NOT NULL,
  `season_id` INT UNSIGNED NOT NULL,
  `seasonal_level` INT UNSIGNED NOT NULL DEFAULT 0,
  `seasonal_points` BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `rewards_claimed` TEXT,
  PRIMARY KEY (`guid`, `season_id`)
);
```

---

## API Reference

### Script Hooks

| Hook | Purpose | Usage |
|------|---------|-------|
| `OnPlayerCustomScalingStatValue` | Modify item stats | Item upgrades |
| `OnCreatureKill` | Track kills | Progression points |
| `OnItemRoll` | Modify loot | Dynamic loot quality |
| `OnPlayerLogin` | Login processing | Apply bonuses |
| `OnPlayerCalculateStat` | Stat calculation | Prestige/paragon bonuses |
| `OnBeforeRollMeleeOutcomeAgainst` | Combat modification | Custom combat rules |

### Player Commands

| Command | Description |
|---------|-------------|
| `.powerlevel` | Show current power level |
| `.progression` | Show progression stats |
| `.upgrade info` | Show item upgrade info |
| `.prestige` | Prestige interface |
| `.infinite start` | Start infinite dungeon |

### GM Commands

| Command | Description |
|---------|-------------|
| `.set progression` | Set progression points |
| `.set prestige` | Set prestige level |
| `.difficulty set` | Set instance difficulty |
| `.upgrade item` | Upgrade player item |

---

## Quick Reference

### Key Formulas

**Stat Bonus from Upgrades:**
```
final_stat = base_stat × (1.0 + upgrade_level × 0.05)
```

**Prestige Stat Bonus:**
```
final_stat = base_stat × (1.0 + prestige_level × 0.01)
```

**Difficulty Scaling:**
```
creature_health = base_health × (1.0 + tier × 0.15)
creature_damage = base_damage × (1.0 + tier × 0.12)
```

**Loot Chance Bonus:**
```
final_chance = base_chance × (1.0 + difficulty_tier × 0.10)
```

### Important File Locations

| System | Location |
|--------|----------|
| Player System | `src/server/game/Entities/Player/` |
| Spell System | `src/server/game/Spells/` |
| AI System | `src/server/game/AI/` |
| Combat | `src/server/game/Combat/` |
| Battlegrounds | `src/server/game/Battlegrounds/` |
| Scripts | `src/server/scripts/` |
| Modules | `modules/` |
| SQL Data | `data/sql/` |

### Configuration Files

| File | Purpose |
|------|---------|
| `worldserver.conf` | World server settings |
| `authserver.conf` | Auth server settings |
| `acore.json` | Project metadata |
| Module `.conf` files | Module-specific settings |

### Build Commands

```bash
# Full build
./acore.sh compiler build

# Database setup
./acore.sh db-assembler

# Start servers
./acore.sh start
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | Jan 2026 | Initial knowledge base creation |

---

## Contributing

To update this knowledge base:
1. Document new systems as they're implemented
2. Keep API references current
3. Update formulas when changed
4. Add new modules to the module list

---

*This document serves as the central knowledge repository for the MyClubGames.com project. For detailed implementation guides, see the individual session-log files.*
