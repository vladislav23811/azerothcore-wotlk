/*
 * Progressive Systems Database Auto-Setup
 * Automatically creates/updates all database tables on server startup
 * Uses existing database connection from worldserver.conf - NO PASSWORDS NEEDED!
 */

#include "ProgressiveSystemsDatabase.h"
#include "DatabaseEnv.h"
#include "QueryResult.h"
#include "DatabaseWorkerPool.h"
#include "Log.h"
#include "World.h"
#include "Config.h"
#include <fstream>
#include <sstream>
#include <filesystem>

ProgressiveSystemsDatabase* ProgressiveSystemsDatabase::instance()
{
    static ProgressiveSystemsDatabase instance;
    return &instance;
}

void ProgressiveSystemsDatabase::LoadAll()
{
    LOG_INFO("module", "===========================================");
    LOG_INFO("module", "Progressive Systems: Auto-Setting Up Database...");
    LOG_INFO("module", "Using existing database connection from worldserver.conf");
    LOG_INFO("module", "===========================================");
    
    // Load character database tables
    LoadCharacterDatabase();
    
    // Load world database tables
    LoadWorldDatabase();
    
    LOG_INFO("module", "Progressive Systems: Database setup complete!");
    LOG_INFO("module", "All tables created/verified. No manual SQL import needed!");
    LOG_INFO("module", "===========================================");
}

// Explicit template instantiation
template bool ProgressiveSystemsDatabase::ExecuteSQLFile<CharacterDatabaseConnection>(const std::string&, DatabaseWorkerPool<CharacterDatabaseConnection>&);
template bool ProgressiveSystemsDatabase::ExecuteSQLFile<WorldDatabaseConnection>(const std::string&, DatabaseWorkerPool<WorldDatabaseConnection>&);

void ProgressiveSystemsDatabase::LoadCharacterDatabase()
{
    LOG_INFO("module", "Setting up Character Database tables...");
    
    // Try multiple paths for SQL file (works in different environments)
    // Uses existing database connection - no passwords needed!
    std::vector<std::string> possiblePaths = {
        // Path relative to source directory (development/build)
        "../modules/mod-progressive-systems/data/sql/characters/base/00_AUTO_SETUP_ALL.sql",
        // Path relative to data directory (if configured)
        sConfigMgr->GetOption<std::string>("DataDir", ".") + "/modules/mod-progressive-systems/data/sql/characters/base/00_AUTO_SETUP_ALL.sql",
        // Path relative to current working directory
        "modules/mod-progressive-systems/data/sql/characters/base/00_AUTO_SETUP_ALL.sql",
        // Path from build directory
        "../../modules/mod-progressive-systems/data/sql/characters/base/00_AUTO_SETUP_ALL.sql",
        // Absolute path from common source location
        "../../../modules/mod-progressive-systems/data/sql/characters/base/00_AUTO_SETUP_ALL.sql",
    };
    
    bool loaded = false;
    for (const auto& sqlFile : possiblePaths)
    {
        if (ExecuteSQLFile<CharacterDatabaseConnection>(sqlFile, CharacterDatabase))
        {
            LOG_INFO("module", "  ✓ Character database tables created/updated");
            LOG_DEBUG("module", "    Loaded from: {}", sqlFile);
            loaded = true;
            break;
        }
    }
    
    if (!loaded)
    {
        LOG_WARN("module", "  ⚠ SQL file not found, using embedded SQL (fallback)");
        // Fallback: Execute SQL directly (embedded in code)
        ExecuteCharacterSQL();
    }
}

void ProgressiveSystemsDatabase::LoadWorldDatabase()
{
    LOG_INFO("module", "Setting up World Database tables...");
    
    // Try multiple paths for SQL file
    std::vector<std::string> possiblePaths = {
        "../modules/mod-progressive-systems/data/sql/world/base/00_AUTO_SETUP_ALL.sql",
        sConfigMgr->GetOption<std::string>("DataDir", ".") + "/modules/mod-progressive-systems/data/sql/world/base/00_AUTO_SETUP_ALL.sql",
        "modules/mod-progressive-systems/data/sql/world/base/00_AUTO_SETUP_ALL.sql",
        "../../modules/mod-progressive-systems/data/sql/world/base/00_AUTO_SETUP_ALL.sql",
        "../../../modules/mod-progressive-systems/data/sql/world/base/00_AUTO_SETUP_ALL.sql",
    };
    
    bool loaded = false;
    for (const auto& sqlFile : possiblePaths)
    {
        if (ExecuteSQLFile<WorldDatabaseConnection>(sqlFile, WorldDatabase))
        {
            LOG_INFO("module", "  ✓ World database tables created/updated");
            LOG_DEBUG("module", "    Loaded from: {}", sqlFile);
            loaded = true;
            break;
        }
    }
    
    if (!loaded)
    {
        LOG_WARN("module", "  ⚠ SQL file not found, using embedded SQL (fallback)");
        // Fallback: Execute SQL directly
        ExecuteWorldSQL();
    }
}

template<typename T>
bool ProgressiveSystemsDatabase::ExecuteSQLFile(const std::string& filePath, DatabaseWorkerPool<T>& database)
{
    // Check if file exists
    std::filesystem::path path(filePath);
    if (!std::filesystem::exists(path))
    {
        return false; // File doesn't exist, try next path
    }
    
    std::ifstream file(filePath);
    if (!file.is_open())
    {
        return false; // Couldn't open file
    }
    
    std::stringstream buffer;
    buffer << file.rdbuf();
    std::string sql = buffer.str();
    file.close();
    
    if (sql.empty())
    {
        LOG_ERROR("module", "SQL file is empty: {}", filePath);
        return false;
    }
    
    // Execute the entire SQL file as one statement (MySQL supports this)
    // This is better than splitting by semicolon which can break on complex statements
    try
    {
        // Use DirectExecute which handles multiple statements
        database.DirectExecute(sql);
        return true;
    }
    catch (const std::exception& e)
    {
        // Some errors are expected (like "table already exists")
        // Only log if it's a real error
        std::string error = e.what();
        if (error.find("already exists") == std::string::npos &&
            error.find("Duplicate") == std::string::npos)
        {
            LOG_ERROR("module", "Error executing SQL file {}: {}", filePath, error);
            return false;
        }
        // Table already exists is fine - means it was already set up
        return true;
    }
}

void ProgressiveSystemsDatabase::ExecuteCharacterSQL()
{
    LOG_INFO("module", "  Executing character database setup (embedded fallback)...");
    
    // Create main progression table
    CharacterDatabase.DirectExecute(R"(
        CREATE TABLE IF NOT EXISTS `character_progression_unified` (
          `guid` INT UNSIGNED NOT NULL PRIMARY KEY,
          `total_kills` INT UNSIGNED NOT NULL DEFAULT 0,
          `claimed_milestone` INT UNSIGNED NOT NULL DEFAULT 0,
          `prestige_level` INT UNSIGNED NOT NULL DEFAULT 0,
          `difficulty_tier` TINYINT UNSIGNED NOT NULL DEFAULT 1,
          `current_tier` TINYINT UNSIGNED NOT NULL DEFAULT 1,
          `total_power_level` INT UNSIGNED NOT NULL DEFAULT 0,
          `progression_points` BIGINT UNSIGNED NOT NULL DEFAULT 0,
          `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          CONSTRAINT `fk_progression_unified_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    )");
    
    // Add reward_points column if not exists (safe check)
    QueryResult colCheck = CharacterDatabase.Query(
        "SELECT COUNT(*) as cnt FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'characters' AND COLUMN_NAME = 'reward_points'");
    if (colCheck && colCheck->NextRow())
    {
        Field* fields = colCheck->Fetch();
        if (fields[0].Get<uint64>() == 0)
        {
            CharacterDatabase.DirectExecute("ALTER TABLE `characters` ADD COLUMN `reward_points` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Progression/reward points for player'");
            LOG_INFO("module", "  ✓ Added reward_points column to characters table");
        }
    }
    
    // Create instance difficulty tracking
    CharacterDatabase.DirectExecute(R"(
        CREATE TABLE IF NOT EXISTS `instance_difficulty_tracking` (
          `instance_id` INT UNSIGNED NOT NULL,
          `map_id` SMALLINT UNSIGNED NOT NULL,
          `difficulty_tier` TINYINT UNSIGNED NOT NULL DEFAULT 0,
          `set_by_guid` INT UNSIGNED NOT NULL DEFAULT 0,
          `set_time` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          PRIMARY KEY (`instance_id`),
          INDEX `idx_map_id` (`map_id`),
          INDEX `idx_difficulty_tier` (`difficulty_tier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    )");
    
    // Create other essential tables
    CharacterDatabase.DirectExecute(R"(
        CREATE TABLE IF NOT EXISTS `item_upgrades` (
          `item_guid` BIGINT UNSIGNED NOT NULL,
          `upgrade_level` INT UNSIGNED NOT NULL DEFAULT 0,
          `stat_bonus_percent` FLOAT NOT NULL DEFAULT 0.0,
          `upgrade_cost_progression_points` INT UNSIGNED NOT NULL DEFAULT 0,
          `last_upgrade_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          PRIMARY KEY (`item_guid`),
          CONSTRAINT `fk_item_upgrades_guid` FOREIGN KEY (`item_guid`) REFERENCES `item_instance` (`guid`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    )");
    
    CharacterDatabase.DirectExecute(R"(
        CREATE TABLE IF NOT EXISTS `infinite_dungeon_progress` (
          `guid` INT UNSIGNED NOT NULL,
          `current_floor` INT UNSIGNED NOT NULL DEFAULT 1,
          `highest_floor` INT UNSIGNED NOT NULL DEFAULT 1,
          `total_floors_cleared` INT UNSIGNED NOT NULL DEFAULT 0,
          `dungeon_type` TINYINT UNSIGNED NOT NULL DEFAULT 0,
          `best_time` INT UNSIGNED NOT NULL DEFAULT 0,
          `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          PRIMARY KEY (`guid`),
          CONSTRAINT `fk_infinite_dungeon_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    )");
    
    // Create daily challenges (in world database - shared across all characters)
    WorldDatabase.DirectExecute(R"(
        CREATE TABLE IF NOT EXISTS `daily_challenges` (
          `challenge_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
          `challenge_type` TINYINT UNSIGNED NOT NULL,
          `challenge_name` VARCHAR(255) NOT NULL,
          `challenge_description` TEXT,
          `target_type` TINYINT UNSIGNED NOT NULL,
          `target_value` INT UNSIGNED NOT NULL,
          `reward_points` INT UNSIGNED NOT NULL DEFAULT 0,
          `reward_item` INT UNSIGNED DEFAULT NULL,
          `reward_item_count` INT UNSIGNED NOT NULL DEFAULT 1,
          `is_active` TINYINT UNSIGNED NOT NULL DEFAULT 1,
          `start_date` DATE NOT NULL,
          `end_date` DATE NOT NULL,
          PRIMARY KEY (`challenge_id`),
          INDEX `idx_type_active` (`challenge_type`, `is_active`),
          INDEX `idx_dates` (`start_date`, `end_date`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    )");
    
    CharacterDatabase.DirectExecute(R"(
        CREATE TABLE IF NOT EXISTS `character_challenge_progress` (
          `guid` INT UNSIGNED NOT NULL,
          `challenge_id` INT UNSIGNED NOT NULL,
          `progress` INT UNSIGNED NOT NULL DEFAULT 0,
          `completed` TINYINT UNSIGNED NOT NULL DEFAULT 0,
          `completed_date` TIMESTAMP NULL DEFAULT NULL,
          `reward_claimed` TINYINT UNSIGNED NOT NULL DEFAULT 0,
          PRIMARY KEY (`guid`, `challenge_id`),
          CONSTRAINT `fk_challenge_progress_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
          -- Note: Cannot reference daily_challenges (WorldDatabase) from CharacterDatabase with foreign key
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    )");
    
    // Create additional tables
    CharacterDatabase.DirectExecute(R"(
        CREATE TABLE IF NOT EXISTS `character_progression` (
          `guid` INT UNSIGNED NOT NULL,
          `prestige_level` INT UNSIGNED NOT NULL DEFAULT 0,
          `total_power_level` INT UNSIGNED NOT NULL DEFAULT 0,
          `highest_difficulty_cleared` INT UNSIGNED NOT NULL DEFAULT 0,
          `total_mythic_plus_completed` INT UNSIGNED NOT NULL DEFAULT 0,
          `progression_points` BIGINT UNSIGNED NOT NULL DEFAULT 0,
          `progression_points_spent` BIGINT UNSIGNED NOT NULL DEFAULT 0,
          `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          PRIMARY KEY (`guid`),
          CONSTRAINT `fk_character_progression_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    )");
    
    CharacterDatabase.DirectExecute(R"(
        CREATE TABLE IF NOT EXISTS `character_prestige` (
          `guid` INT UNSIGNED NOT NULL,
          `prestige_level` INT UNSIGNED NOT NULL DEFAULT 0,
          `total_prestige_points` BIGINT UNSIGNED NOT NULL DEFAULT 0,
          `permanent_stat_bonus` FLOAT NOT NULL DEFAULT 0.0,
          `loot_quality_bonus` FLOAT NOT NULL DEFAULT 0.0,
          `experience_bonus` FLOAT NOT NULL DEFAULT 0.0,
          `prestige_rewards_unlocked` TEXT,
          `last_prestige_date` TIMESTAMP NULL DEFAULT NULL,
          PRIMARY KEY (`guid`),
          CONSTRAINT `fk_character_prestige_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    )");
    
    CharacterDatabase.DirectExecute(R"(
        CREATE TABLE IF NOT EXISTS `character_stat_enhancements` (
          `guid` INT UNSIGNED NOT NULL,
          `stat_type` TINYINT UNSIGNED NOT NULL,
          `enhancement_level` INT UNSIGNED NOT NULL DEFAULT 0,
          `total_invested_points` BIGINT UNSIGNED NOT NULL DEFAULT 0,
          PRIMARY KEY (`guid`, `stat_type`),
          CONSTRAINT `fk_stat_enhancements_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    )");
    
    // Create seasons table (world database - shared across all characters)
    WorldDatabase.DirectExecute(R"(
        CREATE TABLE IF NOT EXISTS `seasons` (
          `season_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
          `season_name` VARCHAR(255) NOT NULL,
          `start_time` BIGINT UNSIGNED NOT NULL,
          `end_time` BIGINT UNSIGNED NOT NULL,
          `exp_bonus` FLOAT NOT NULL DEFAULT 1.0,
          `loot_bonus` FLOAT NOT NULL DEFAULT 1.0,
          `progression_bonus` FLOAT NOT NULL DEFAULT 1.0,
          `is_active` TINYINT UNSIGNED NOT NULL DEFAULT 1,
          PRIMARY KEY (`season_id`),
          INDEX `idx_active` (`is_active`),
          INDEX `idx_time` (`start_time`, `end_time`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    )");
    
    CharacterDatabase.DirectExecute(R"(
        CREATE TABLE IF NOT EXISTS `character_seasonal_stats` (
          `guid` INT UNSIGNED NOT NULL,
          `season_id` INT UNSIGNED NOT NULL,
          `score` INT UNSIGNED NOT NULL DEFAULT 0,
          `kills` INT UNSIGNED NOT NULL DEFAULT 0,
          `dungeons_completed` INT UNSIGNED NOT NULL DEFAULT 0,
          `floors_cleared` INT UNSIGNED NOT NULL DEFAULT 0,
          `prestige_level` INT UNSIGNED NOT NULL DEFAULT 0,
          PRIMARY KEY (`guid`, `season_id`),
          CONSTRAINT `fk_seasonal_stats_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    )");
    
    CharacterDatabase.DirectExecute(R"(
        CREATE TABLE IF NOT EXISTS `seasonal_progress` (
          `guid` INT UNSIGNED NOT NULL,
          `season_id` INT UNSIGNED NOT NULL,
          `seasonal_level` INT UNSIGNED NOT NULL DEFAULT 0,
          `seasonal_points` BIGINT UNSIGNED NOT NULL DEFAULT 0,
          `rewards_claimed` TEXT,
          `season_start_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          PRIMARY KEY (`guid`, `season_id`),
          CONSTRAINT `fk_seasonal_progress_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    )");
    
    CharacterDatabase.DirectExecute(R"(
        CREATE TABLE IF NOT EXISTS `character_shirt_tiers` (
          `guid` INT UNSIGNED NOT NULL,
          `current_tier` TINYINT UNSIGNED NOT NULL DEFAULT 1,
          `total_tiers_unlocked` TINYINT UNSIGNED NOT NULL DEFAULT 1,
          PRIMARY KEY (`guid`),
          CONSTRAINT `fk_shirt_tiers_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    )");
    
    CharacterDatabase.DirectExecute(R"(
        CREATE TABLE IF NOT EXISTS `custom_daily_login` (
          `player_guid` INT UNSIGNED NOT NULL,
          `last_login_date` DATE DEFAULT NULL,
          `consecutive_days` INT UNSIGNED NOT NULL DEFAULT 0,
          `total_days` INT UNSIGNED NOT NULL DEFAULT 0,
          `rewards_claimed` INT UNSIGNED NOT NULL DEFAULT 0,
          `last_reward_date` DATE DEFAULT NULL,
          PRIMARY KEY (`player_guid`),
          CONSTRAINT `fk_daily_login_guid` FOREIGN KEY (`player_guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    )");
    
    CharacterDatabase.DirectExecute(R"(
        CREATE TABLE IF NOT EXISTS `custom_pve_bounty` (
          `bounty_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
          `target_entry` INT UNSIGNED NOT NULL,
          `target_name` VARCHAR(255) DEFAULT NULL,
          `total_kills_needed` INT UNSIGNED NOT NULL DEFAULT 1000,
          `current_kills` INT UNSIGNED NOT NULL DEFAULT 0,
          `expiry_time` TIMESTAMP NULL DEFAULT NULL,
          `reward_item` INT UNSIGNED DEFAULT NULL,
          `reward_points` INT UNSIGNED NOT NULL DEFAULT 0,
          `is_active` TINYINT UNSIGNED NOT NULL DEFAULT 1,
          `created_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          PRIMARY KEY (`bounty_id`),
          INDEX `idx_target_entry` (`target_entry`),
          INDEX `idx_active` (`is_active`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    )");
    
    CharacterDatabase.DirectExecute(R"(
        CREATE TABLE IF NOT EXISTS `character_daily_progress` (
          `guid` INT UNSIGNED NOT NULL,
          `daily_date` DATE NOT NULL,
          `dungeons_completed` TINYINT UNSIGNED NOT NULL DEFAULT 0,
          `raids_completed` TINYINT UNSIGNED NOT NULL DEFAULT 0,
          `pvp_kills` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
          `quests_completed` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
          `daily_reward_claimed` TINYINT UNSIGNED NOT NULL DEFAULT 0,
          PRIMARY KEY (`guid`, `daily_date`),
          CONSTRAINT `fk_daily_progress_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    )");
    
    CharacterDatabase.DirectExecute(R"(
        CREATE TABLE IF NOT EXISTS `character_pvp_progression` (
          `guid` INT UNSIGNED NOT NULL,
          `pvp_tier` TINYINT UNSIGNED NOT NULL DEFAULT 1,
          `pvp_rating` INT UNSIGNED NOT NULL DEFAULT 0,
          `total_pvp_kills` INT UNSIGNED NOT NULL DEFAULT 0,
          `total_pvp_deaths` INT UNSIGNED NOT NULL DEFAULT 0,
          `pvp_points` BIGINT UNSIGNED NOT NULL DEFAULT 0,
          `pvp_points_spent` BIGINT UNSIGNED NOT NULL DEFAULT 0,
          `highest_rating` INT UNSIGNED NOT NULL DEFAULT 0,
          `arena_wins` INT UNSIGNED NOT NULL DEFAULT 0,
          `arena_losses` INT UNSIGNED NOT NULL DEFAULT 0,
          `bg_wins` INT UNSIGNED NOT NULL DEFAULT 0,
          `bg_losses` INT UNSIGNED NOT NULL DEFAULT 0,
          `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          PRIMARY KEY (`guid`),
          CONSTRAINT `fk_pvp_progression_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    )");
    
    CharacterDatabase.DirectExecute(R"(
        CREATE TABLE IF NOT EXISTS `palace_stats` (
          `guid` INT UNSIGNED NOT NULL,
          `total_damage_dealt` BIGINT UNSIGNED NOT NULL DEFAULT 0,
          `total_healing_done` BIGINT UNSIGNED NOT NULL DEFAULT 0,
          `highest_floor_reached` INT UNSIGNED NOT NULL DEFAULT 1,
          `best_floor_time` INT UNSIGNED NOT NULL DEFAULT 0,
          `total_floors_completed` INT UNSIGNED NOT NULL DEFAULT 0,
          `total_deaths` INT UNSIGNED NOT NULL DEFAULT 0,
          `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          PRIMARY KEY (`guid`),
          CONSTRAINT `fk_palace_stats_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    )");
    
    CharacterDatabase.DirectExecute(R"(
        CREATE TABLE IF NOT EXISTS `palace_scores` (
          `score_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
          `guid` INT UNSIGNED NOT NULL,
          `floor` INT UNSIGNED NOT NULL,
          `completion_time` INT UNSIGNED NOT NULL,
          `damage_dealt` BIGINT UNSIGNED NOT NULL DEFAULT 0,
          `healing_done` BIGINT UNSIGNED NOT NULL DEFAULT 0,
          `score_date` DATE NOT NULL,
          `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          PRIMARY KEY (`score_id`),
          INDEX `idx_guid_date` (`guid`, `score_date`),
          INDEX `idx_floor_time` (`floor`, `completion_time`),
          CONSTRAINT `fk_palace_scores_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    )");
    
    CharacterDatabase.DirectExecute(R"(
        CREATE TABLE IF NOT EXISTS `guild_progression` (
          `guild_id` INT UNSIGNED NOT NULL,
          `guild_power_level` INT UNSIGNED NOT NULL DEFAULT 0,
          `total_guild_kills` BIGINT UNSIGNED NOT NULL DEFAULT 0,
          `total_guild_points` BIGINT UNSIGNED NOT NULL DEFAULT 0,
          `guild_tier` TINYINT UNSIGNED NOT NULL DEFAULT 1,
          `challenges_completed` INT UNSIGNED NOT NULL DEFAULT 0,
          `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          PRIMARY KEY (`guild_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    )");
    
    CharacterDatabase.DirectExecute(R"(
        CREATE TABLE IF NOT EXISTS `guild_challenges` (
          `challenge_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
          `guild_id` INT UNSIGNED NOT NULL,
          `challenge_type` TINYINT UNSIGNED NOT NULL,
          `target_value` INT UNSIGNED NOT NULL,
          `current_progress` INT UNSIGNED NOT NULL DEFAULT 0,
          `reward_points` INT UNSIGNED NOT NULL DEFAULT 0,
          `is_completed` TINYINT UNSIGNED NOT NULL DEFAULT 0,
          `start_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          `end_date` TIMESTAMP NULL DEFAULT NULL,
          PRIMARY KEY (`challenge_id`),
          INDEX `idx_guild_id` (`guild_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    )");
    
    CharacterDatabase.DirectExecute(R"(
        CREATE TABLE IF NOT EXISTS `progressive_achievements` (
          `achievement_id` INT UNSIGNED NOT NULL,
          `achievement_type` TINYINT UNSIGNED NOT NULL,
          `requirement_value` INT UNSIGNED NOT NULL,
          `reward_points` INT UNSIGNED NOT NULL DEFAULT 0,
          `is_active` TINYINT UNSIGNED NOT NULL DEFAULT 1,
          PRIMARY KEY (`achievement_id`),
          INDEX `idx_type` (`achievement_type`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    )");
    
    CharacterDatabase.DirectExecute(R"(
        CREATE TABLE IF NOT EXISTS `character_progressive_achievements` (
          `guid` INT UNSIGNED NOT NULL,
          `achievement_id` INT UNSIGNED NOT NULL,
          `completed_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          PRIMARY KEY (`guid`, `achievement_id`),
          CONSTRAINT `fk_prog_ach_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE,
          CONSTRAINT `fk_prog_ach_id` FOREIGN KEY (`achievement_id`) REFERENCES `progressive_achievements` (`achievement_id`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    )");
    
    // Insert default achievements
    CharacterDatabase.DirectExecute(R"(
        INSERT IGNORE INTO `progressive_achievements` (`achievement_id`, `achievement_type`, `requirement_value`, `reward_points`) VALUES
        (9001, 0, 100, 100),
        (9002, 0, 1000, 1000),
        (9003, 0, 10000, 10000),
        (9004, 1, 5, 5000),
        (9005, 1, 10, 20000),
        (9006, 2, 1, 50000),
        (9007, 3, 10, 2000),
        (9008, 3, 50, 10000),
        (9009, 4, 100000, 5000),
        (9010, 4, 1000000, 50000);
    )");
    
    LOG_INFO("module", "  ✓ Character database tables created (embedded fallback method)");
}

void ProgressiveSystemsDatabase::ExecuteWorldSQL()
{
    LOG_INFO("module", "  Executing world database setup (embedded fallback)...");
    
    // Create difficulty scaling table
    WorldDatabase.DirectExecute(R"(
        CREATE TABLE IF NOT EXISTS `custom_difficulty_scaling` (
          `map_id` INT UNSIGNED NOT NULL,
          `difficulty_tier` TINYINT UNSIGNED NOT NULL DEFAULT 0,
          `health_multiplier` FLOAT NOT NULL DEFAULT 1.0,
          `damage_multiplier` FLOAT NOT NULL DEFAULT 1.0,
          `loot_quality_bonus` TINYINT UNSIGNED NOT NULL DEFAULT 0,
          `experience_multiplier` FLOAT NOT NULL DEFAULT 1.0,
          `required_item_level` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
          `reward_points` INT UNSIGNED NOT NULL DEFAULT 0,
          `point_multiplier` FLOAT NOT NULL DEFAULT 1.0,
          `comment` VARCHAR(255) DEFAULT NULL,
          PRIMARY KEY (`map_id`, `difficulty_tier`),
          INDEX `idx_map_id` (`map_id`),
          INDEX `idx_difficulty_tier` (`difficulty_tier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    )");
    
    // Insert default data if not exists
    WorldDatabase.DirectExecute(R"(
        INSERT IGNORE INTO `custom_difficulty_scaling` (`map_id`, `difficulty_tier`, `health_multiplier`, `damage_multiplier`, `loot_quality_bonus`, `experience_multiplier`, `required_item_level`, `reward_points`, `point_multiplier`, `comment`) VALUES
        (533, 0, 1.0, 1.0, 0, 1.0, 0, 100, 1.0, 'Naxxramas Normal'),
        (533, 1, 2.0, 1.8, 1, 2.0, 200, 500, 1.0, 'Naxxramas Heroic'),
        (533, 2, 3.5, 3.0, 1, 3.0, 220, 1000, 1.2, 'Naxxramas Mythic+1'),
        (533, 3, 5.0, 4.5, 2, 4.0, 240, 2000, 1.5, 'Naxxramas Mythic+2'),
        (533, 5, 10.0, 8.0, 2, 6.0, 260, 5000, 2.0, 'Naxxramas Mythic+5'),
        (533, 10, 25.0, 20.0, 3, 10.0, 300, 20000, 3.0, 'Naxxramas Mythic+10'),
        (631, 0, 1.0, 1.0, 0, 1.0, 0, 200, 1.0, 'ICC Normal'),
        (631, 1, 2.5, 2.2, 1, 2.5, 250, 1000, 1.0, 'ICC Heroic'),
        (631, 2, 4.0, 3.5, 1, 3.5, 270, 2500, 1.3, 'ICC Mythic+1'),
        (631, 3, 6.0, 5.0, 2, 5.0, 290, 5000, 1.6, 'ICC Mythic+2'),
        (631, 5, 12.0, 10.0, 2, 8.0, 320, 15000, 2.5, 'ICC Mythic+5'),
        (631, 10, 30.0, 25.0, 3, 15.0, 350, 50000, 4.0, 'ICC Mythic+10'),
        (603, 0, 1.0, 1.0, 0, 1.0, 0, 150, 1.0, 'Ulduar Normal'),
        (603, 1, 2.2, 2.0, 1, 2.2, 220, 800, 1.0, 'Ulduar Heroic'),
        (603, 2, 3.8, 3.2, 1, 3.2, 240, 2000, 1.2, 'Ulduar Mythic+1'),
        (603, 3, 5.5, 4.8, 2, 4.5, 260, 4000, 1.5, 'Ulduar Mythic+2'),
        (603, 5, 11.0, 9.5, 2, 7.5, 300, 12000, 2.2, 'Ulduar Mythic+5'),
        (603, 10, 28.0, 24.0, 3, 12.0, 340, 40000, 3.5, 'Ulduar Mythic+10'),
        (574, 0, 1.0, 1.0, 0, 1.0, 0, 50, 1.0, 'Utgarde Keep Normal'),
        (574, 1, 1.8, 1.6, 0, 1.8, 180, 200, 1.0, 'Utgarde Keep Heroic'),
        (574, 2, 2.5, 2.2, 0, 2.5, 200, 400, 1.1, 'Utgarde Keep Mythic+1'),
        (574, 3, 3.5, 3.0, 1, 3.5, 220, 800, 1.3, 'Utgarde Keep Mythic+2'),
        (574, 5, 6.0, 5.0, 1, 5.0, 250, 2000, 1.8, 'Utgarde Keep Mythic+5'),
        (574, 10, 15.0, 12.0, 2, 10.0, 300, 8000, 2.5, 'Utgarde Keep Mythic+10');
    )");
    
    // Create bloody palace tables
    WorldDatabase.DirectExecute(R"(
        CREATE TABLE IF NOT EXISTS `bloody_palace_waves` (
          `wave` TINYINT UNSIGNED NOT NULL,
          `creature_entry` MEDIUMINT UNSIGNED NOT NULL,
          `count` TINYINT UNSIGNED NOT NULL DEFAULT 1,
          `boss_chance` TINYINT UNSIGNED NOT NULL DEFAULT 0,
          `floor_min` TINYINT UNSIGNED NOT NULL DEFAULT 1,
          `floor_max` TINYINT UNSIGNED NOT NULL DEFAULT 255,
          `scaling_multiplier` FLOAT NOT NULL DEFAULT 1.0,
          PRIMARY KEY (`wave`),
          INDEX `idx_floor_range` (`floor_min`, `floor_max`),
          INDEX `idx_creature_entry` (`creature_entry`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    )");
    
    WorldDatabase.DirectExecute(R"(
        CREATE TABLE IF NOT EXISTS `bloody_palace_bosses` (
          `boss_id` TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
          `creature_entry` MEDIUMINT UNSIGNED NOT NULL,
          `floor_min` TINYINT UNSIGNED NOT NULL DEFAULT 1,
          `floor_max` TINYINT UNSIGNED NOT NULL DEFAULT 255,
          `spawn_weight` TINYINT UNSIGNED NOT NULL DEFAULT 100,
          `name` VARCHAR(255) DEFAULT NULL,
          PRIMARY KEY (`boss_id`),
          INDEX `idx_floor_range` (`floor_min`, `floor_max`),
          INDEX `idx_creature_entry` (`creature_entry`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    )");
    
    // Insert default wave data
    WorldDatabase.DirectExecute(R"(
        INSERT IGNORE INTO `bloody_palace_waves` (`wave`, `creature_entry`, `count`, `boss_chance`, `floor_min`, `floor_max`, `scaling_multiplier`) VALUES
        (1, 16360, 3, 0, 1, 10, 1.0),
        (2, 17252, 3, 0, 1, 10, 1.0),
        (3, 36805, 4, 0, 1, 10, 1.0),
        (4, 31306, 4, 0, 1, 10, 1.0),
        (5, 0, 0, 100, 1, 10, 1.0),
        (6, 37012, 5, 0, 1, 10, 1.0),
        (7, 25593, 5, 0, 1, 10, 1.0),
        (8, 36808, 6, 0, 1, 10, 1.0),
        (9, 16021, 6, 0, 1, 10, 1.0),
        (10, 0, 0, 100, 1, 10, 1.0),
        (11, 37007, 7, 0, 11, 20, 1.2),
        (12, 18945, 7, 0, 11, 20, 1.2),
        (13, 16360, 8, 0, 11, 20, 1.2),
        (14, 17252, 8, 0, 11, 20, 1.2),
        (15, 0, 0, 100, 11, 20, 1.5),
        (16, 36805, 9, 0, 11, 20, 1.2),
        (17, 31306, 9, 0, 11, 20, 1.2),
        (18, 37012, 10, 0, 11, 20, 1.2),
        (19, 25593, 10, 0, 11, 20, 1.2),
        (20, 0, 0, 100, 11, 20, 1.5),
        (21, 36808, 11, 0, 21, 30, 1.5),
        (22, 16021, 11, 0, 21, 30, 1.5),
        (23, 37007, 12, 0, 21, 30, 1.5),
        (24, 18945, 12, 0, 21, 30, 1.5),
        (25, 0, 0, 100, 21, 30, 2.0),
        (26, 16360, 13, 0, 21, 30, 1.5),
        (27, 17252, 13, 0, 21, 30, 1.5),
        (28, 36805, 14, 0, 21, 30, 1.5),
        (29, 31306, 14, 0, 21, 30, 1.5),
        (30, 0, 0, 100, 21, 30, 2.0),
        (31, 37012, 15, 0, 31, 255, 2.0),
        (32, 25593, 15, 0, 31, 255, 2.0),
        (33, 36808, 16, 0, 31, 255, 2.0),
        (34, 16021, 16, 0, 31, 255, 2.0),
        (35, 0, 0, 100, 31, 255, 2.5),
        (36, 37007, 17, 0, 31, 255, 2.0),
        (37, 18945, 17, 0, 31, 255, 2.0),
        (38, 16360, 18, 0, 31, 255, 2.0),
        (39, 17252, 18, 0, 31, 255, 2.0),
        (40, 0, 0, 100, 31, 255, 2.5);
    )");
    
    // Insert default boss data
    WorldDatabase.DirectExecute(R"(
        INSERT IGNORE INTO `bloody_palace_bosses` (`creature_entry`, `floor_min`, `floor_max`, `spawn_weight`, `name`) VALUES
        (36597, 1, 10, 100, 'The Lich King (Easy)'),
        (36612, 1, 10, 100, 'Frostmourne Guardian'),
        (36612, 11, 30, 80, 'Frostmourne Guardian (Hard)'),
        (36597, 11, 30, 60, 'The Lich King (Hard)'),
        (36597, 31, 255, 50, 'The Lich King (Nightmare)'),
        (36612, 31, 255, 40, 'Frostmourne Guardian (Nightmare)');
    )");
    
    LOG_INFO("module", "  ✓ World database tables created (embedded fallback method)");
}
