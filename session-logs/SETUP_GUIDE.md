# 🚀 Complete Setup Guide
## Step-by-Step Installation

---

## ✅ **AUTOMATIC (On Server Start)**

1. **SQL Import** ✅
   - All SQL files in `data/sql/{database}/base/` are auto-imported
   - Tables created automatically
   - Default data inserted

2. **C++ Module Loading** ✅
   - Module loads automatically
   - Hooks registered
   - Commands available

---

## ⚠️ **MANUAL STEPS REQUIRED**

### **Step 1: Copy Lua Scripts**

Eluna loads scripts from `lua_scripts/` directory (server root).

**Windows:**
```powershell
# Copy all Lua scripts to server root
Copy-Item -Path "modules\mod-progressive-systems\lua_scripts\*" -Destination "lua_scripts\" -Recurse -Force
```

**Linux:**
```bash
# Copy all Lua scripts to server root
cp -r modules/mod-progressive-systems/lua_scripts/* lua_scripts/
```

**Or create symlink (Linux):**
```bash
ln -s modules/mod-progressive-systems/lua_scripts lua_scripts/progressive-systems
```

### **Step 2: Copy Config Files**

Copy all `.conf.dist` files to `etc/` directory:

**Windows:**
```powershell
# Copy config files
Copy-Item -Path "modules\mod-progressive-systems\*.conf.dist" -Destination "etc\" -Force
```

**Linux:**
```bash
# Copy config files
cp modules/mod-progressive-systems/*.conf.dist etc/
```

**Then rename (remove .dist):**
```bash
cd etc
mv mod-progressive-systems.conf.dist mod-progressive-systems.conf
# Edit as needed
```

### **Step 3: Spawn NPCs**

NPCs are NOT auto-spawned. You need to spawn them manually:

**Option A: In-Game (GM Command)**
```
.npc add 190000  -- Main Menu
.npc add 190001  -- Item Upgrade
.npc add 190002  -- Prestige
.npc add 190003  -- Difficulty Selector
.npc add 190004  -- Reward Shop
.npc add 190005  -- Infinite Dungeon
.npc add 190006  -- Progressive Items
.npc add 190007  -- Daily Challenges
.npc add 190020  -- Paragon Master
```

**Option B: SQL (Spawn at specific location)**
```sql
-- Example: Spawn at Stormwind (adjust coordinates as needed)
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `modelid`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`) VALUES
(1900000, 190000, 0, 0, 0, 1, 1, 0, 0, -8949.95, -132.493, 83.5312, 0, 300, 0, 0, 5342, 0, 0, 1, 0, 0, ''),
(1900001, 190001, 0, 0, 0, 1, 1, 0, 0, -8947.95, -132.493, 83.5312, 0, 300, 0, 0, 5342, 0, 0, 128, 0, 0, ''),
(1900002, 190002, 0, 0, 0, 1, 1, 0, 0, -8945.95, -132.493, 83.5312, 0, 300, 0, 0, 128, 0, 0, 1, 0, 0, ''),
(1900003, 190003, 0, 0, 0, 1, 1, 0, 0, -8943.95, -132.493, 83.5312, 0, 300, 0, 0, 128, 0, 0, 1, 0, 0, ''),
(1900004, 190004, 0, 0, 0, 1, 1, 0, 0, -8941.95, -132.493, 83.5312, 0, 300, 0, 0, 128, 0, 0, 1, 0, 0, ''),
(1900005, 190005, 0, 0, 0, 1, 1, 0, 0, -8939.95, -132.493, 83.5312, 0, 300, 0, 0, 128, 0, 0, 1, 0, 0, ''),
(1900006, 190006, 0, 0, 0, 1, 1, 0, 0, -8937.95, -132.493, 83.5312, 0, 300, 0, 0, 128, 0, 0, 1, 0, 0, ''),
(1900007, 190007, 0, 0, 0, 1, 1, 0, 0, -8935.95, -132.493, 83.5312, 0, 300, 0, 0, 128, 0, 0, 1, 0, 0, ''),
(1900020, 190020, 0, 0, 0, 1, 1, 0, 0, -8933.95, -132.493, 83.5312, 0, 300, 0, 0, 128, 0, 0, 1, 0, 0, '');
```

---

## ✅ **VERIFICATION**

After setup, verify:

1. **SQL Tables:**
   ```sql
   SHOW TABLES LIKE '%progression%';
   SHOW TABLES LIKE '%paragon%';
   SHOW TABLES LIKE '%infinite%';
   ```

2. **Lua Scripts:**
   - Check `lua_scripts/` directory has all scripts
   - Check server logs for "Loading Lua scripts..."

3. **NPCs:**
   - Check `creature_template` has entries 190000-190007, 190020
   - Spawn NPCs and test interaction

4. **Config:**
   - Check `etc/mod-progressive-systems.conf` exists
   - Verify settings are correct

---

## 🎯 **QUICK SETUP SCRIPT**

Create `setup_progressive_systems.ps1` (Windows) or `setup_progressive_systems.sh` (Linux):

**Windows (PowerShell):**
```powershell
# Copy Lua scripts
Copy-Item -Path "modules\mod-progressive-systems\lua_scripts\*" -Destination "lua_scripts\" -Recurse -Force

# Copy config files
Copy-Item -Path "modules\mod-progressive-systems\*.conf.dist" -Destination "etc\" -Force

Write-Host "Setup complete! Now:"
Write-Host "1. Edit etc/mod-progressive-systems.conf"
Write-Host "2. Start server"
Write-Host "3. Spawn NPCs with .npc add commands"
```

**Linux (Bash):**
```bash
#!/bin/bash
# Copy Lua scripts
cp -r modules/mod-progressive-systems/lua_scripts/* lua_scripts/

# Copy config files
cp modules/mod-progressive-systems/*.conf.dist etc/

echo "Setup complete! Now:"
echo "1. Edit etc/mod-progressive-systems.conf"
echo "2. Start server"
echo "3. Spawn NPCs with .npc add commands"
```

---

**Status:** Everything documented! Just follow the manual steps above.

