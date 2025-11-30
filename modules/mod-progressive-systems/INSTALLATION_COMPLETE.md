# 🚀 Complete Installation Guide - Progressive Server

## 📋 Pre-Installation Checklist

- [ ] AzerothCore compiled and installed
- [ ] MySQL/MariaDB running
- [ ] Databases created (auth, characters, world)
- [ ] Eluna module installed and enabled
- [ ] All modules cloned (see MODULES_INSTALLED.md)

---

## 📦 Step 1: Database Setup

### 1.1 Update Realm Name

```sql
-- Run in acore_auth database
USE acore_auth;
SOURCE data/sql/base/db_auth/realmlist.sql;
-- Or manually update:
UPDATE realmlist SET name = 'Myclubgames.com' WHERE id = 1;
```

### 1.2 Install Progressive Systems Tables

**Run in order:**

```sql
-- Characters database
USE acore_characters;

-- Main progression tables
SOURCE modules/mod-progressive-systems/data/sql/characters/base/ALL_PROGRESSIVE_SYSTEMS.sql;

-- Daily system
SOURCE modules/mod-progressive-systems/data/sql/characters/base/daily_system.sql;

-- PvP progression
SOURCE modules/mod-progressive-systems/data/sql/characters/base/pvp_progression.sql;

-- Palace stats
SOURCE modules/mod-progressive-systems/data/sql/characters/base/palace_stats.sql;
```

```sql
-- World database
USE acore_world;

-- Difficulty scaling
SOURCE modules/mod-progressive-systems/data/sql/world/base/difficulty_scaling.sql;

-- Bloody Palace waves
SOURCE modules/mod-progressive-systems/data/sql/world/base/bloody_palace_waves.sql;

-- Bloody Palace bosses
SOURCE modules/mod-progressive-systems/data/sql/world/base/bloody_palace_bosses.sql;
```

### 1.3 Verify Installation

```sql
-- Check tables exist
USE acore_characters;
SHOW TABLES LIKE '%progression%';
SHOW TABLES LIKE '%daily%';
SHOW TABLES LIKE '%pvp%';
SHOW TABLES LIKE '%palace%';

USE acore_world;
SHOW TABLES LIKE '%difficulty%';
SHOW TABLES LIKE '%palace%';
```

---

## ⚙️ Step 2: Configuration

### 2.1 Copy Configuration Files

```bash
# Copy module config
cp modules/mod-progressive-systems/mod-progressive-systems.conf.dist etc/mod-progressive-systems.conf

# Copy progressive server config (merge with worldserver.conf)
# Copy settings from PROGRESSIVE_SERVER_CONFIG.conf to your worldserver.conf
```

### 2.2 Configure worldserver.conf

**Add these sections to your `worldserver.conf`:**

```ini
# Progressive Systems Module
[ProgressiveSystems]
ProgressiveSystems.NPC.MainMenu = 190000
ProgressiveSystems.NPC.ItemUpgrade = 190001
ProgressiveSystems.NPC.Prestige = 190002
ProgressiveSystems.NPC.Difficulty = 190003
ProgressiveSystems.NPC.RewardShop = 190004
ProgressiveSystems.NPC.InfiniteDungeon = 190005
ProgressiveSystems.NPC.ProgressiveItems = 190006

# Eluna (Lua Scripting)
[ALE]
ALE.Enabled = true
ALE.ScriptPath = "lua_scripts"
ALE.AutoReload = false
ALE.BytecodeCache = true
```

**Copy experience/loot rates from `PROGRESSIVE_SERVER_CONFIG.conf`** (see that file for recommended settings)

### 2.3 Configure mod-progressive-systems.conf

Edit `etc/mod-progressive-systems.conf` and adjust NPC entries if needed.

---

## 📜 Step 3: Lua Scripts

### 3.1 Copy Lua Scripts

```bash
# Windows PowerShell
Copy-Item -Path "modules\mod-progressive-systems\lua_scripts\*" -Destination "bin\lua_scripts\" -Recurse -Force

# Linux/Mac
cp -r modules/mod-progressive-systems/lua_scripts/* bin/lua_scripts/
```

### 3.2 Verify Scripts

Check that these files exist in `bin/lua_scripts/`:
- ✅ `config.lua`
- ✅ `progressive_systems_core.lua`
- ✅ `main_menu_npc.lua`
- ✅ `item_upgrade_npc.lua`
- ✅ `reward_shop_npc.lua`
- ✅ `infinite_dungeon_npc.lua`
- ✅ `progressive_items_npc.lua`

### 3.3 Configure Lua (Optional)

Edit `bin/lua_scripts/config.lua` to adjust:
- NPC IDs
- Point values
- Tier multipliers
- Difficulty settings
- Upgrade costs
- Reward shop items

---

## 🏗️ Step 4: Compile Module

### 4.1 Build AzerothCore with Module

```bash
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=~/azeroth-server
make -j$(nproc)  # or make -j4 on Windows
make install
```

### 4.2 Verify Module Compiled

Check that `libmod-progressive-systems.so` (Linux) or `mod-progressive-systems.dll` (Windows) exists in your `bin/` directory.

---

## 🎮 Step 5: Spawn NPCs

### 5.1 Spawn NPCs in Game

**Use GM commands or SQL:**

```sql
-- Spawn Main Menu NPC (replace x, y, z, map with your location)
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `modelid`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`) VALUES
(1900000, 190000, 0, 0, 0, 1, 1, 0, 0, -8949.95, -132.493, 83.5312, 0, 300, 0, 0, 5342, 0, 0, 1, 0, 0, ''),
(1900001, 190001, 0, 0, 0, 1, 1, 0, 0, -8947.95, -132.493, 83.5312, 0, 300, 0, 0, 5342, 0, 0, 128, 0, 0, ''),
(1900002, 190002, 0, 0, 0, 1, 1, 0, 0, -8945.95, -132.493, 83.5312, 0, 300, 0, 0, 128, 0, 0, 1, 0, 0, ''),
(1900003, 190003, 0, 0, 0, 1, 1, 0, 0, -8943.95, -132.493, 83.5312, 0, 300, 0, 0, 128, 0, 0, 1, 0, 0, ''),
(1900004, 190004, 0, 0, 0, 1, 1, 0, 0, -8941.95, -132.493, 83.5312, 0, 300, 0, 0, 128, 0, 0, 1, 0, 0, ''),
(1900005, 190005, 0, 0, 0, 1, 1, 0, 0, -8939.95, -132.493, 83.5312, 0, 300, 0, 0, 128, 0, 0, 1, 0, 0, ''),
(1900006, 190006, 0, 0, 0, 1, 1, 0, 0, -8937.95, -132.493, 83.5312, 0, 300, 0, 0, 128, 0, 0, 1, 0, 0, '');
```

**Or use GM command in-game:**
```
.npc add 190000
.npc add 190001
.npc add 190002
.npc add 190003
.npc add 190004
.npc add 190005
.npc add 190006
```

### 5.2 Create Creature Templates (if needed)

```sql
USE acore_world;

-- Main Menu NPC
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `npcflag`, `scale`, `unit_class`, `unit_flags`, `type`, `type_flags`, `flags_extra`, `ScriptName`) VALUES
(190000, 'Progression Master', 'Progressive Systems', 1, 1.0, 1, 0, 7, 0, 0, ''),
(190001, 'Item Upgrader', 'Upgrade Your Items', 128, 1.0, 1, 0, 7, 0, 0, ''),
(190002, 'Prestige Master', 'Reset for Power', 1, 1.0, 1, 0, 7, 0, 0, ''),
(190003, 'Difficulty Selector', 'Choose Your Challenge', 1, 1.0, 1, 0, 7, 0, 0, ''),
(190004, 'Reward Shop', 'Spend Your Points', 128, 1.0, 1, 0, 7, 0, 0, ''),
(190005, 'Infinite Dungeon', 'Endless Challenge', 1, 1.0, 1, 0, 7, 0, 0, ''),
(190006, 'Progressive Items', 'Tiered Gear Vendor', 128, 1.0, 1, 0, 7, 0, 0, '');
```

---

## ✅ Step 6: Verify Installation

### 6.1 Start Server

```bash
./worldserver
```

### 6.2 Check Logs

Look for these messages:
```
[Progressive Systems] Module loaded successfully!
[Progressive Systems] Core module loaded successfully!
[Progressive Systems] Main menu NPC loaded!
[Progressive Systems] Item Upgrade NPC loaded!
[Progressive Systems] Reward Shop NPC loaded!
[Progressive Systems] Infinite Dungeon NPC loaded!
[Progressive Systems] Progressive Items NPC loaded!
```

### 6.3 Test In-Game

1. Log in with a character
2. Find NPC 190000 (Main Menu)
3. Interact - should see progression menu
4. Test each NPC:
   - Main Menu → All sub-menus work
   - Item Upgrade → Can upgrade items
   - Reward Shop → Can purchase items
   - Difficulty Selector → Can change difficulty
   - Infinite Dungeon → Can check floors
   - Progressive Items → Can view tiered items

### 6.4 Test Progression

1. Kill some creatures
2. Check if progression points are awarded
3. Check milestone rewards
4. Verify database updates:
   ```sql
   SELECT * FROM character_progression_unified WHERE guid = YOUR_GUID;
   ```

---

## 🔧 Troubleshooting

### Lua Scripts Not Loading

- Check `ALE.Enabled = true` in worldserver.conf
- Verify scripts in `bin/lua_scripts/`
- Check server logs for Lua errors
- Use `.reload ALE` command in-game

### NPCs Not Working

- Verify NPC entries in `mod-progressive-systems.conf`
- Check creature_template entries exist
- Verify NPCs are spawned
- Check Lua script errors in logs

### Database Errors

- Verify all SQL files ran successfully
- Check foreign key constraints
- Verify character GUID exists

### Module Not Loading

- Check module compiled successfully
- Verify module in `modules/` directory
- Check CMakeLists.txt includes module
- Rebuild if needed

---

## 📚 Next Steps

1. **Customize Configuration**
   - Adjust rates in `worldserver.conf`
   - Modify `config.lua` for Lua settings
   - Update NPC entries if needed

2. **Add Custom Content**
   - Integrate custom items from old server
   - Add custom enchants
   - Create custom quests

3. **Balance Testing**
   - Test progression rates
   - Adjust difficulty scaling
   - Fine-tune point rewards

4. **Community Features**
   - Set up leaderboards
   - Create events
   - Add seasonal content

---

## 🎉 You're Done!

Your progressive server is now set up and ready to go!

**Key Features:**
- ✅ Infinite progression system
- ✅ Difficulty scaling
- ✅ Item upgrades
- ✅ Prestige system
- ✅ Daily rewards
- ✅ PvP progression
- ✅ Infinite dungeon
- ✅ Reward shop

**Enjoy your progressive server!** 🚀

