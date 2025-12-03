# 📊 SQL Auto-Import Status
## Automatic Database Setup Analysis

---

## ✅ **HOW AZEROTHCORE AUTO-IMPORTS SQL**

AzerothCore automatically imports SQL files on server startup:

1. **Base Files** (`data/sql/{database}/base/*.sql`):
   - Automatically executed on first server start
   - Uses `CREATE TABLE IF NOT EXISTS` (safe)
   - Files starting with `00_` are executed first (alphabetical order)

2. **Update Files** (`data/sql/{database}/updates/*.sql`):
   - Tracked in `updates` table
   - Only executed once per file
   - For incremental updates

**Location:**
- Character DB: `modules/mod-progressive-systems/data/sql/characters/base/`
- World DB: `modules/mod-progressive-systems/data/sql/world/base/`

---

## ✅ **CURRENT STATUS**

### **Character Database** (`00_AUTO_SETUP_ALL.sql`)
**Status:** ✅ MOSTLY COMPLETE

**Tables Included:**
- ✅ `character_progression_unified`
- ✅ `character_progression`
- ✅ `character_prestige`
- ✅ `item_upgrades`
- ✅ `character_stat_enhancements`
- ✅ `infinite_dungeon_progress`
- ✅ `seasonal_progress`
- ✅ `instance_difficulty_tracking`
- ✅ `daily_challenges`
- ✅ `character_challenge_progress`
- ✅ `character_pvp_progression`
- ✅ `guild_progression`
- ✅ `progressive_achievements`
- ✅ `character_enhanced_glyphs`
- ✅ `character_item_gems`
- ✅ `instance_completion_tracking`
- ✅ `instance_reset_usage`

**Tables MISSING:**
- ❌ `character_paragon` (Paragon system)
- ❌ `character_paragon_stats` (Paragon stat allocations)
- ❌ `paragon_stat_definitions` (Paragon stat definitions - WORLD DB)

### **World Database** (`00_AUTO_SETUP_ALL.sql`)
**Status:** ⚠️ MISSING TABLES

**Tables Included:**
- ✅ `custom_difficulty_scaling`
- ✅ `bloody_palace_waves`
- ✅ `bloody_palace_bosses`
- ✅ `auto_item_rules`
- ✅ `enhanced_glyphs`
- ✅ `enhanced_gems`

**Tables MISSING:**
- ❌ `infinite_dungeon_waves` (NEW - we just created this!)
- ❌ `paragon_stat_definitions` (Paragon stat definitions)
- ❌ `unified_stat_modifiers` (If needed)

---

## 🔧 **FIXES NEEDED**

### 1. Add Missing Tables to Auto-Setup Files

**Character DB:**
- Add `character_paragon` table
- Add `character_paragon_stats` table

**World DB:**
- Add `infinite_dungeon_waves` table
- Add `paragon_stat_definitions` table

---

## 📋 **NEXT STEPS**

1. **Update `00_AUTO_SETUP_ALL.sql` files** to include missing tables
2. **Verify all tables** are using `CREATE TABLE IF NOT EXISTS`
3. **Test auto-import** on fresh database

---

**Status:** ⚠️ Needs updates to auto-setup files

