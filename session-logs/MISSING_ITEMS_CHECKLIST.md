# 🔍 Missing Items Checklist
## What We Might Have Forgotten

---

## ✅ **CHECKED & FIXED**

### 1. **SQL Auto-Import** ✅
- ✅ All tables in `00_AUTO_SETUP_ALL.sql`
- ✅ Paragon tables added
- ✅ Infinite dungeon waves added
- ✅ Paragon stat definitions added

### 2. **NPC Creature Templates** ✅
- ✅ Added to `00_AUTO_SETUP_ALL.sql`
- ✅ All 9 NPCs included (190000-190007, 190020)
- ✅ Using INSERT IGNORE (safe)

### 3. **Config Files** ✅
- ✅ Config updated with NPC 190007 and 190020
- ✅ Lua config.lua updated

---

## ⚠️ **POTENTIALLY MISSING**

### 1. **Lua Script Auto-Loading** ⚠️
**Question:** Do Lua scripts auto-load?

**Status:** Need to verify Eluna configuration
- Eluna loads scripts from configured directory
- Need to check if scripts are in correct location
- May need to configure Eluna script path

**Action:** Check Eluna config for script directory

### 2. **NPC Spawning** ⚠️
**Question:** Are NPCs automatically spawned?

**Status:** NPCs are NOT auto-spawned
- Creature templates are created (SQL)
- But NPCs must be spawned manually or via SQL
- Can use `.npc add` command or SQL INSERT

**Action:** Create spawn SQL or document manual spawning

### 3. **Config File Copying** ⚠️
**Question:** Are config files automatically copied?

**Status:** Config files are NOT auto-copied
- `.conf.dist` files are templates
- Must manually copy to `etc/` directory
- Or configure build system to copy them

**Action:** Document manual copy process or create script

### 4. **Lua Script Dependencies** ⚠️
**Question:** Are all Lua script dependencies loaded?

**Status:** Need to verify
- `progressive_systems_core.lua` must load first
- `config.lua` must load first
- Other scripts depend on these

**Action:** Check script load order

---

## 📋 **TO VERIFY**

1. **Eluna Script Loading:**
   - Check Eluna config for script directory
   - Verify scripts are in correct location
   - Test script loading on server start

2. **NPC Spawning:**
   - Create spawn SQL file (optional)
   - Document manual spawning process
   - Or create auto-spawn system

3. **Config Files:**
   - Document copy process
   - Or create setup script

4. **Script Dependencies:**
   - Verify load order
   - Test all scripts load correctly

---

## 🎯 **RECOMMENDATIONS**

1. **Create Setup Script:**
   - Copy all config files
   - Verify SQL import
   - Check Lua scripts

2. **Document Manual Steps:**
   - NPC spawning
   - Config copying
   - Lua script verification

3. **Test Everything:**
   - Fresh database install
   - Verify all systems work
   - Check for errors

---

**Status:** Most things are automatic, but some manual steps may be needed!

