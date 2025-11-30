# 📦 SQL Installation Order

## Installation Sequence

Run these SQL files **in order** to set up the progressive server database.

---

## 🔵 Characters Database (`acore_characters`)

### 1. Core Progression Tables
```sql
USE acore_characters;
SOURCE modules/mod-progressive-systems/data/sql/characters/base/ALL_PROGRESSIVE_SYSTEMS.sql;
```
**Creates:**
- `character_progression_unified` (main table)
- `character_progression`
- `character_prestige`
- `item_upgrades`
- `character_stat_enhancements`
- `infinite_dungeon_progress`
- `seasonal_progress`
- `character_shirt_tiers`
- Adds `reward_points` column to `characters`

### 2. Daily System
```sql
USE acore_characters;
SOURCE modules/mod-progressive-systems/data/sql/characters/base/daily_system.sql;
```
**Creates:**
- `custom_daily_login`
- `custom_pve_bounty`
- `character_daily_progress`

### 3. PvP Progression
```sql
USE acore_characters;
SOURCE modules/mod-progressive-systems/data/sql/characters/base/pvp_progression.sql;
```
**Creates:**
- `character_pvp_progression`

### 4. Palace Statistics
```sql
USE acore_characters;
SOURCE modules/mod-progressive-systems/data/sql/characters/base/palace_stats.sql;
```
**Creates:**
- `palace_stats`
- `palace_scores`

---

## 🟢 World Database (`acore_world`)

### 5. Difficulty Scaling
```sql
USE acore_world;
SOURCE modules/mod-progressive-systems/data/sql/world/base/difficulty_scaling.sql;
```
**Creates:**
- `custom_difficulty_scaling` (with example data)

### 6. Bloody Palace Waves
```sql
USE acore_world;
SOURCE modules/mod-progressive-systems/data/sql/world/base/bloody_palace_waves.sql;
```
**Creates:**
- `bloody_palace_waves` (with wave data)

### 7. Bloody Palace Bosses
```sql
USE acore_world;
SOURCE modules/mod-progressive-systems/data/sql/world/base/bloody_palace_bosses.sql;
```
**Creates:**
- `bloody_palace_bosses` (with boss pool)

---

## 🔴 Auth Database (`acore_auth`)

### 8. Realm List (Update)
```sql
USE acore_auth;
SOURCE data/sql/base/db_auth/realmlist.sql;
-- Or manually:
UPDATE realmlist SET name = 'Myclubgames.com' WHERE id = 1;
```

---

## ✅ Verification

After installation, verify tables exist:

```sql
-- Characters database
USE acore_characters;
SHOW TABLES LIKE '%progression%';
SHOW TABLES LIKE '%daily%';
SHOW TABLES LIKE '%pvp%';
SHOW TABLES LIKE '%palace%';

-- World database
USE acore_world;
SHOW TABLES LIKE '%difficulty%';
SHOW TABLES LIKE '%palace%';
```

**Expected Tables:**

**Characters:**
- ✅ character_progression_unified
- ✅ character_progression
- ✅ character_prestige
- ✅ item_upgrades
- ✅ character_stat_enhancements
- ✅ infinite_dungeon_progress
- ✅ seasonal_progress
- ✅ character_shirt_tiers
- ✅ custom_daily_login
- ✅ custom_pve_bounty
- ✅ character_daily_progress
- ✅ character_pvp_progression
- ✅ palace_stats
- ✅ palace_scores

**World:**
- ✅ custom_difficulty_scaling
- ✅ bloody_palace_waves
- ✅ bloody_palace_bosses

---

## 🔄 Update Existing Database

If you already have some tables, you can run individual files:

```sql
-- Only run what you need
USE acore_characters;
SOURCE modules/mod-progressive-systems/data/sql/characters/base/add_reward_points_column.sql;
```

---

## ⚠️ Notes

- **Foreign Keys:** All tables use foreign keys to `characters.guid` or `item_instance.guid`
- **Cascade Delete:** Deleting a character will automatically delete all progression data
- **Indexes:** All tables have proper indexes for performance
- **Character Set:** All tables use `utf8mb4` for full Unicode support

---

## 🐛 Troubleshooting

### Error: Table already exists
```sql
-- Drop and recreate (WARNING: Deletes data!)
DROP TABLE IF EXISTS table_name;
SOURCE path/to/file.sql;
```

### Error: Foreign key constraint fails
- Make sure `characters` table exists
- Make sure character GUID exists before inserting progression data

### Error: Column already exists
```sql
-- Check if column exists first
SHOW COLUMNS FROM characters LIKE 'reward_points';
-- If exists, skip that part of the SQL file
```

