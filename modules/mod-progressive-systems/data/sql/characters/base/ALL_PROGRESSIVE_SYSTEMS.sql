-- ============================================================
-- PROGRESSIVE SYSTEMS - COMPLETE DATABASE SETUP
-- Run this file to set up all progressive systems
-- ============================================================
-- 
-- Installation Order:
-- 1. Run this file (ALL_PROGRESSIVE_SYSTEMS.sql)
-- 2. Run world/base/difficulty_scaling.sql
-- 3. Run world/base/bloody_palace_waves.sql
-- 4. Run world/base/bloody_palace_bosses.sql
--
-- ============================================================

-- ============================================================
-- CHARACTER PROGRESSION TABLES
-- ============================================================

-- Main unified progression table (used by both C++ and Lua)
DROP TABLE IF EXISTS `character_progression_unified`;
CREATE TABLE `character_progression_unified` (
  `guid` INT UNSIGNED NOT NULL PRIMARY KEY,
  `total_kills` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total creatures killed',
  `claimed_milestone` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Last milestone claimed',
  `prestige_level` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Prestige level',
  `difficulty_tier` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Current difficulty tier (0=Easy, 1=Normal, etc.)',
  `current_tier` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Current progression tier (affects point multipliers)',
  `total_power_level` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Calculated power level',
  `progression_points` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total progression points earned',
  `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT `fk_progression_unified_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Unified character progression tracking';

-- Additional progression data
DROP TABLE IF EXISTS `character_progression`;
CREATE TABLE `character_progression` (
  `guid` INT UNSIGNED NOT NULL,
  `prestige_level` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Prestige level (resets for bonuses)',
  `total_power_level` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Calculated power level',
  `highest_difficulty_cleared` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Highest difficulty tier completed',
  `total_mythic_plus_completed` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total M+ runs completed',
  `progression_points` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total progression points earned',
  `progression_points_spent` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total progression points spent',
  `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`),
  CONSTRAINT `fk_character_progression_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Character progression tracking';

-- Prestige system
DROP TABLE IF EXISTS `character_prestige`;
CREATE TABLE `character_prestige` (
  `guid` INT UNSIGNED NOT NULL,
  `prestige_level` INT UNSIGNED NOT NULL DEFAULT 0,
  `total_prestige_points` BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `permanent_stat_bonus` FLOAT NOT NULL DEFAULT 0.0 COMMENT 'Percentage bonus to all stats',
  `loot_quality_bonus` FLOAT NOT NULL DEFAULT 0.0 COMMENT 'Percentage bonus to loot quality',
  `experience_bonus` FLOAT NOT NULL DEFAULT 0.0 COMMENT 'Percentage bonus to experience',
  `prestige_rewards_unlocked` TEXT COMMENT 'JSON array of unlocked rewards',
  `last_prestige_date` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`guid`),
  CONSTRAINT `fk_character_prestige_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Prestige system data';

-- Item upgrades
DROP TABLE IF EXISTS `item_upgrades`;
CREATE TABLE `item_upgrades` (
  `item_guid` BIGINT UNSIGNED NOT NULL,
  `upgrade_level` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Current upgrade level',
  `stat_bonus_percent` FLOAT NOT NULL DEFAULT 0.0 COMMENT 'Total stat bonus percentage',
  `upgrade_cost_progression_points` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total points spent on this item',
  `last_upgrade_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`item_guid`),
  CONSTRAINT `fk_item_upgrades_guid` FOREIGN KEY (`item_guid`) REFERENCES `item_instance` (`guid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Item upgrade tracking';

-- Stat enhancements
DROP TABLE IF EXISTS `character_stat_enhancements`;
CREATE TABLE `character_stat_enhancements` (
  `guid` INT UNSIGNED NOT NULL,
  `stat_type` TINYINT UNSIGNED NOT NULL COMMENT 'Stat type (0=Strength, 1=Agility, etc.)',
  `enhancement_level` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Enhancement level for this stat',
  `total_invested_points` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total points invested',
  PRIMARY KEY (`guid`, `stat_type`),
  CONSTRAINT `fk_stat_enhancements_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Permanent stat enhancements';

-- Infinite dungeon progress
DROP TABLE IF EXISTS `infinite_dungeon_progress`;
CREATE TABLE `infinite_dungeon_progress` (
  `guid` INT UNSIGNED NOT NULL,
  `current_floor` INT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Current floor in infinite dungeon',
  `highest_floor` INT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Highest floor reached',
  `total_floors_cleared` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total floors cleared',
  `dungeon_type` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Dungeon type (0=normal, 1=elite, etc.)',
  `best_time` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Best completion time in seconds',
  `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`),
  CONSTRAINT `fk_infinite_dungeon_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Infinite dungeon progression';

-- Seasonal progress
DROP TABLE IF EXISTS `seasonal_progress`;
CREATE TABLE `seasonal_progress` (
  `guid` INT UNSIGNED NOT NULL,
  `season_id` INT UNSIGNED NOT NULL COMMENT 'Season identifier',
  `seasonal_level` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Seasonal progression level',
  `seasonal_points` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Points earned this season',
  `rewards_claimed` TEXT COMMENT 'JSON array of claimed reward IDs',
  `season_start_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`, `season_id`),
  CONSTRAINT `fk_seasonal_progress_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Seasonal progression tracking';

-- ============================================================
-- ADD REWARD_POINTS COLUMN TO CHARACTERS TABLE
-- ============================================================

-- Add reward_points column if it doesn't exist (used by Lua scripts)
ALTER TABLE `characters` 
ADD COLUMN IF NOT EXISTS `reward_points` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Progression/reward points for player';

-- Shirt tier tracking (from old server)
DROP TABLE IF EXISTS `character_shirt_tiers`;
CREATE TABLE IF NOT EXISTS `character_shirt_tiers` (
  `guid` INT UNSIGNED NOT NULL,
  `current_tier` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Current progression tier (1-15)',
  `total_tiers_unlocked` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Highest tier unlocked',
  PRIMARY KEY (`guid`),
  CONSTRAINT `fk_shirt_tiers_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Character shirt/tabard tier progression';

