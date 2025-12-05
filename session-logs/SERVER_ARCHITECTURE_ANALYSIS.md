# 🏗️ AzerothCore Server Architecture - Comprehensive Analysis

**Generated:** December 3, 2025  
**Purpose:** Complete understanding of server architecture for improvements  
**Status:** In Progress

---

## 📊 Server Overview

AzerothCore is a World of Warcraft 3.3.5a (WotLK) server emulator written in C++.

### **Main Components:**
1. **WorldServer** - Main game server
2. **AuthServer** - Authentication server
3. **Database Layer** - MySQL persistence
4. **Script System** - Custom logic & encounters
5. **Module System** - Extensible plugins

---

## 🗂️ Directory Structure Analysis

### **src/server/ (Top Level)**
```
server/
├── apps/          - Server executables
│   ├── authserver/    - Authentication server
│   └── worldserver/   - Main game server
├── database/      - Database abstraction layer
├── game/          - Core game logic (MAIN FOCUS)
├── scripts/       - Scripted content (zones, bosses, etc.)
└── shared/        - Shared code between servers
```

---

## 🎮 src/server/game/ - CORE GAME SYSTEMS

This is where all the magic happens. **79 subsystems identified.**

### **1. Entities (Most Complex)**
Player, Creature, GameObject, Item, Pet, Unit, Object hierarchy

**Files:** 79 files (40 .h, 39 .cpp)

**Subsystems:**
- **Corpse/** - Dead player bodies
- **Creature/** - NPCs and monsters (10 files)
- **DynamicObject/** - AOE effects, traps
- **GameObject/** - Interactive world objects (3 files)
- **Item/** - Equipment and inventory (8 files)
- **Object/** - Base object class (17 files)
- **Pet/** - Player pets (3 files)
- **Player/** - Player characters (19 files - LARGEST)
- **Totem/** - Shaman totems
- **Transport/** - Boats, zeppelins
- **Unit/** - Base combat unit (8 files)
- **Vehicle/** - Mounted combat (3 files)

**Improvement Opportunities:**
- Player system is massive (19 files, 16k+ lines in Player.cpp)
- Could benefit from further modularity
- Item system has complex interactions

---

### **2. Spells System**
Spell casting, auras, effects, modifications

**Files:** 16 files (8 .cpp, 8 .h) + Auras subfolder

**Key Components:**
- `Spell.cpp` - Main spell casting (9k+ lines)
- `SpellInfo.cpp` - Spell data definitions
- `SpellEffects.cpp` - Spell effect handlers (6k+ lines)
- `SpellAuras.cpp` - Aura management
- `SpellAuraEffects.cpp` - Aura effect handlers

**Improvement Opportunities:**
- Spell.cpp is 9,112 lines - needs refactoring
- Complex effect chains could be optimized
- Aura stacking logic could be clearer

---

### **3. AI System**
Creature AI, smart scripts, scripted behaviors

**Subsystems:**
- **CoreAI/** - Basic AI types (16 files)
  - `PetAI.cpp` - Pet behavior
  - `TotemAI.cpp` - Totem behavior
  - `GuardAI.cpp` - Guard NPC behavior
  - `ReactorAI.cpp` - Passive creatures
- **ScriptedAI/** - Boss/encounter AI (8 files)
- **SmartScripts/** - Data-driven AI (6 files)

**Improvement Opportunities:**
- Smart script system is powerful but complex
- Could use better debugging tools
- AI state machine could be more explicit

---

### **4. Combat & Threat**
Threat management, combat calculations, formulas

**Files:** 5 files in Combat/

**Key Components:**
- `ThreatMgr.cpp` - Threat/aggro system
- `HostileRefMgr.cpp` - Enemy reference tracking
- `Formulas.h` - Combat math (XP, honor, damage)

**Already Fixed:**
- ✅ Division by zero in honor calculation
- ✅ Raid XP scaling implemented

**Improvement Opportunities:**
- Threat calculation could be optimized
- Combat formulas need retail verification

---

### **5. Network & Handlers**
Packet handling, client communication, opcodes

**Files:** 36 handlers + 47 server files

**Handlers (36 files):**
- Character creation/deletion
- Movement
- Combat
- Chat
- Trade
- Guild
- Mail
- Pet
- Quest
- Spell casting
- Social

**Server Components:**
- `WorldSession.cpp` - Session management
- `WorldSocket.cpp` - Network layer
- `PacketIO.cpp` - Packet serialization
- `Opcodes.cpp` - Packet type definitions

**Already Fixed:**
- ✅ Combat logout exploit
- ✅ Logout delay in combat

**Improvement Opportunities:**
- Packet validation could be stricter
- Input sanitization audit needed
- Error handling could be more robust

---

### **6. Database Layer**
Database operations, queries, caching

**Components:**
- `DatabaseWorkerPool` - Connection pooling
- `PreparedStatement` - SQL injection prevention
- `QueryCallback` - Async query system
- `Transaction` - ACID operations

**Improvement Opportunities:**
- Query optimization opportunities
- Cache hit rates could be measured
- Connection pool tuning

---

### **7. Maps & Grids**
World management, grid system, terrain

**Files:** 16 in Maps/ + 18 in Grids/

**Key Systems:**
- `Map.cpp` - Main map container
- `MapManager.cpp` - Map lifecycle
- `GridObjectLoader.cpp` - Dynamic loading
- `GridTerrainData.cpp` - Terrain information

**Improvement Opportunities:**
- Grid loading could be optimized
- Visibility calculations are expensive
- LOD system for distant objects

---

### **8. Movement System**
Pathfinding, splines, motion generators

**Files:** 42 files (23 .h, 19 .cpp)

**Key Components:**
- `MotionMaster.cpp` - Movement state machine
- `PathGenerator.cpp` - Pathfinding (uses Recast)
- `MoveSpline.cpp` - Smooth movement curves
- Movement generators for various behaviors

**Improvement Opportunities:**
- Pathfinding is CPU-intensive
- Could cache common paths
- Movement prediction improvements

---

### **9. Battlegrounds & PvP**
BGs, arenas, outdoor PvP, seasons

**Files:** 46 files

**BG Zones:**
- Alterac Valley (AV)
- Warsong Gulch (WSG)
- Arathi Basin (AB)
- Eye of the Storm (EotS)
- Strand of the Ancients (SoA)
- Isle of Conquest (IoC)
- Various arenas

**Already Fixed:**
- ✅ AV Captain buff timer
- ✅ AV quest honor rewards
- ✅ AV quest reputation

**Improvement Opportunities:**
- BG queue system optimization
- Rating calculations audit
- Season transitions

---

### **10. Scripting System**
Hook system, custom scripts, events

**Files:** 106 files (54 .h, 52 .cpp)

**Hook Types:**
- Player hooks
- Creature hooks
- Item hooks
- Spell hooks
- World hooks
- Server hooks

**Script Locations:**
- `scripts/Commands/` - GM commands (50 files)
- `scripts/EasternKingdoms/` - EK content (162 files)
- `scripts/Kalimdor/` - Kalimdor content (91 files)
- `scripts/Northrend/` - Northrend content (200 files)
- `scripts/Outland/` - BC content (118 files)

**Improvement Opportunities:**
- Script performance profiling
- Memory usage optimization
- Better error handling in scripts

---

## 📦 Module System Analysis

### **Installed Modules (20+ detected):**

1. **mod-playerbots** - AI-controlled player bots
2. **mod-progressive-systems** - Custom progression
3. **mod-autobalance** - Solo content scaling
4. **mod-transmog** - Appearance system
5. **mod-1v1-arena** - 1v1 PvP
6. **mod-solo-lfg** - Solo dungeon finder
7. **mod-premium** - Premium features
8. **mod-reward-shop** - Item shop
9. **mod-random-enchants** - Randomized gear
10. **mod-character-tools** - Character management
11. **mod-npc-beastmaster** - Pet management NPC
12. **mod-arena-3v3-solo-queue** - 3v3 solo queue
13. And more...

**Improvement Opportunities:**
- Module dependency management
- Performance impact analysis
- Integration testing between modules

---

## 🔍 Analysis Progress

**Current Status:** Architecture mapped  
**Next Steps:** Deep dive into each system

---

## 📝 Notes

This document will be continuously updated as we analyze each system in detail.

**Target:** Complete understanding of all systems for improvement planning.

