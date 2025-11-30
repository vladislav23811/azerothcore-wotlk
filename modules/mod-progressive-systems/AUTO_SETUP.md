# 🔄 Automatic Database Setup

## ✅ Fully Automatic!

The Progressive Systems module now **automatically sets up all database tables** when the server starts!

### How It Works

1. **Server Startup** → Module loads
2. **World Initialization** → `OnStartup()` hook fires
3. **Auto-Setup** → All SQL files are automatically executed
4. **Tables Created** → All tables created if they don't exist
5. **Data Inserted** → Default data inserted if missing
6. **Ready to Go!** → No manual SQL import needed!

## 📁 SQL Files

### Character Database (`acore_characters`)
**Auto-loaded file:** `data/sql/characters/base/00_AUTO_SETUP_ALL.sql`

**Creates:**
- ✅ `character_progression_unified` - Main progression
- ✅ `character_progression` - Additional data
- ✅ `character_prestige` - Prestige system
- ✅ `item_upgrades` - Item upgrades
- ✅ `character_stat_enhancements` - Stat enhancements
- ✅ `infinite_dungeon_progress` - Infinite dungeon
- ✅ `seasonal_progress` - Seasonal tracking
- ✅ `character_shirt_tiers` - Tier progression
- ✅ `instance_difficulty_tracking` - Mythic+ tracking
- ✅ `custom_daily_login` - Daily login
- ✅ `custom_pve_bounty` - Bounty system
- ✅ `character_daily_progress` - Daily tracking
- ✅ `character_pvp_progression` - PvP progression
- ✅ `palace_stats` - Palace statistics
- ✅ `palace_scores` - Score tracking
- ✅ `daily_challenges` - Daily/weekly challenges
- ✅ `character_challenge_progress` - Challenge progress
- ✅ `guild_progression` - Guild progression
- ✅ `guild_challenges` - Guild challenges
- ✅ `progressive_achievements` - Achievements
- ✅ `character_progressive_achievements` - Player achievements
- ✅ `reward_points` column in `characters` table

### World Database (`acore_world`)
**Auto-loaded file:** `data/sql/world/base/00_AUTO_SETUP_ALL.sql`

**Creates:**
- ✅ `custom_difficulty_scaling` - Difficulty config (with default data)
- ✅ `bloody_palace_waves` - Wave definitions (with default data)
- ✅ `bloody_palace_bosses` - Boss pool (with default data)

## 🔧 Features

### Smart Table Creation
- Uses `CREATE TABLE IF NOT EXISTS` - Won't overwrite existing tables
- Checks for columns before adding - Won't duplicate columns
- Checks for foreign keys before adding - Won't duplicate constraints

### Default Data
- Inserts default difficulty scaling for popular instances
- Inserts default wave data for Bloody Palace
- Inserts default boss pool
- Inserts default achievements
- Uses `INSERT IGNORE` - Won't duplicate data

### Fallback System
- If SQL file can't be read, executes SQL directly in C++
- Ensures tables are always created
- Logs all operations for debugging

## 📊 What Gets Created

### On First Server Start
- All tables created
- Default data inserted
- Foreign keys added
- Indexes created

### On Subsequent Starts
- Checks if tables exist (they do)
- Checks if data exists (it does)
- Skips creation (no errors)
- Updates if needed

## 🚀 Installation

**NO MANUAL SQL IMPORT NEEDED!**

Just:
1. Compile the module
2. Start the server
3. Everything is automatic!

The module will:
- ✅ Create all tables
- ✅ Insert default data
- ✅ Set up foreign keys
- ✅ Create indexes
- ✅ Add missing columns

## 📝 Logs

You'll see in server logs:
```
===========================================
Progressive Systems: Auto-Setting Up Database...
===========================================
Setting up Character Database tables...
  ✓ Character database tables created/updated
Setting up World Database tables...
  ✓ World database tables created/updated
Progressive Systems: Database setup complete!
===========================================
```

## ⚠️ Notes

- **First Start:** Takes a few seconds to create all tables
- **Subsequent Starts:** Very fast (just checks)
- **No Data Loss:** Existing data is never deleted
- **Safe:** Can run multiple times without issues

## 🔍 Verification

After server starts, check logs for:
- ✅ "Character database tables created/updated"
- ✅ "World database tables created/updated"
- ✅ "Database setup complete!"

If you see errors, check:
- Database connection is working
- User has CREATE TABLE permissions
- SQL files are in correct location

## 🎉 Benefits

- ✅ **Zero Manual Work** - Everything automatic
- ✅ **No Missing Tables** - All created on startup
- ✅ **No Missing Data** - Default data inserted
- ✅ **Always Up to Date** - New tables auto-added
- ✅ **Safe** - Won't break existing data
- ✅ **Fast** - Only creates what's missing

## 📚 Technical Details

### Execution Order
1. Server starts
2. Databases connect
3. World initializes
4. `OnStartup()` hook fires
5. `ProgressiveSystemsDatabase::LoadAll()` called
6. SQL files executed
7. Fallback SQL executed if needed
8. Logs completion

### Error Handling
- SQL file errors are logged but don't stop server
- Fallback SQL ensures tables are created
- Missing files use direct SQL execution
- All errors are logged for debugging

## 🎯 Summary

**Everything is now automatic!** Just start the server and all database tables will be created automatically. No manual SQL import needed!

