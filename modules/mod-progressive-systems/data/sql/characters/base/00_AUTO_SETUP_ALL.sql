-- ============================================================
-- PROGRESSIVE SYSTEMS - AUTOMATIC SETUP
-- This file is automatically executed on server startup
-- Creates all tables if they don't exist
-- Updates existing tables if needed
-- ============================================================

-- ============================================================
-- 1. ADD REWARD_POINTS COLUMN TO CHARACTERS TABLE
-- ============================================================
SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = DATABASE() 
  AND TABLE_NAME = 'characters' 
  AND COLUMN_NAME = 'reward_points';

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `characters` ADD COLUMN `reward_points` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT ''Progression/reward points for player''',
    'SELECT ''Column reward_points already exists'' AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ============================================================
-- 2. MAIN PROGRESSION TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS `character_progression_unified` (
  `guid` INT UNSIGNED NOT NULL PRIMARY KEY,
  `total_kills` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total creatures killed',
  `claimed_milestone` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Last milestone claimed',
  `prestige_level` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Prestige level',
  `difficulty_tier` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Current difficulty tier (0=Easy, 1=Normal, etc.)',
  `current_tier` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Current progression tier (affects point multipliers)',
  `total_power_level` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Calculated power level',
  `progression_points` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total progression points earned',
  `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT `fk_progression_unified_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE,
  INDEX `idx_prestige_level` (`prestige_level`),
  INDEX `idx_current_tier` (`current_tier`),
  INDEX `idx_progression_points` (`progression_points`),
  INDEX `idx_total_power_level` (`total_power_level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Unified character progression tracking';

-- ============================================================
-- 3. ADDITIONAL PROGRESSION TABLES
-- ============================================================
CREATE TABLE IF NOT EXISTS `character_progression` (
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

CREATE TABLE IF NOT EXISTS `character_prestige` (
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

CREATE TABLE IF NOT EXISTS `item_upgrades` (
  `item_guid` BIGINT UNSIGNED NOT NULL,
  `upgrade_level` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Current upgrade level',
  `stat_bonus_percent` FLOAT NOT NULL DEFAULT 0.0 COMMENT 'Total stat bonus percentage',
  `upgrade_cost_progression_points` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total points spent on this item',
  `last_upgrade_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`item_guid`),
  INDEX `idx_upgrade_level` (`upgrade_level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Item upgrade tracking';

-- Add foreign key if item_instance table exists and column types are compatible
SET @fk_exists = 0;
SELECT COUNT(*) INTO @fk_exists 
FROM information_schema.TABLE_CONSTRAINTS 
WHERE TABLE_SCHEMA = DATABASE() 
  AND TABLE_NAME = 'item_upgrades' 
  AND CONSTRAINT_NAME = 'fk_item_upgrades_guid'
  AND CONSTRAINT_TYPE = 'FOREIGN KEY';

SET @table_exists = 0;
SELECT COUNT(*) INTO @table_exists
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = DATABASE() 
  AND TABLE_NAME = 'item_instance';

SET @col_type_match = 0;
SELECT COUNT(*) INTO @col_type_match
FROM information_schema.COLUMNS c1
JOIN information_schema.COLUMNS c2 ON c1.DATA_TYPE = c2.DATA_TYPE 
  AND c1.COLUMN_TYPE = c2.COLUMN_TYPE
WHERE c1.TABLE_SCHEMA = DATABASE() AND c1.TABLE_NAME = 'item_upgrades' AND c1.COLUMN_NAME = 'item_guid'
  AND c2.TABLE_SCHEMA = DATABASE() AND c2.TABLE_NAME = 'item_instance' AND c2.COLUMN_NAME = 'guid';

SET @sql = IF(@fk_exists = 0 AND @table_exists > 0 AND @col_type_match > 0,
    'ALTER TABLE `item_upgrades` ADD CONSTRAINT `fk_item_upgrades_guid` FOREIGN KEY (`item_guid`) REFERENCES `item_instance` (`guid`) ON DELETE CASCADE',
    'SELECT ''Foreign key already exists, item_instance table not found, or column types incompatible'' AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

CREATE TABLE IF NOT EXISTS `character_stat_enhancements` (
  `guid` INT UNSIGNED NOT NULL,
  `stat_type` TINYINT UNSIGNED NOT NULL COMMENT 'Stat type (0=Strength, 1=Agility, etc.)',
  `enhancement_level` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Enhancement level for this stat',
  `total_invested_points` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total points invested',
  PRIMARY KEY (`guid`, `stat_type`),
  CONSTRAINT `fk_stat_enhancements_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Permanent stat enhancements';

CREATE TABLE IF NOT EXISTS `infinite_dungeon_progress` (
  `guid` INT UNSIGNED NOT NULL,
  `current_floor` INT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Current floor in infinite dungeon',
  `highest_floor` INT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Highest floor reached',
  `total_floors_cleared` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total floors cleared',
  `dungeon_type` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Dungeon type (0=normal, 1=elite, etc.)',
  `best_time` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Best completion time in seconds',
  `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`),
  CONSTRAINT `fk_infinite_dungeon_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE,
  INDEX `idx_highest_floor` (`highest_floor`),
  INDEX `idx_best_time` (`best_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Infinite dungeon progression';

CREATE TABLE IF NOT EXISTS `seasonal_progress` (
  `guid` INT UNSIGNED NOT NULL,
  `season_id` INT UNSIGNED NOT NULL COMMENT 'Season identifier',
  `seasonal_level` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Seasonal progression level',
  `seasonal_points` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Points earned this season',
  `rewards_claimed` TEXT COMMENT 'JSON array of claimed reward IDs',
  `season_start_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`, `season_id`),
  CONSTRAINT `fk_seasonal_progress_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Seasonal progression tracking';

CREATE TABLE IF NOT EXISTS `character_shirt_tiers` (
  `guid` INT UNSIGNED NOT NULL,
  `current_tier` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Current progression tier (1-15)',
  `total_tiers_unlocked` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Highest tier unlocked',
  PRIMARY KEY (`guid`),
  CONSTRAINT `fk_shirt_tiers_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Character shirt/tabard tier progression';

-- ============================================================
-- 4. INSTANCE DIFFICULTY TRACKING
-- ============================================================
CREATE TABLE IF NOT EXISTS `instance_difficulty_tracking` (
  `instance_id` INT UNSIGNED NOT NULL COMMENT 'Instance ID from instance table',
  `map_id` SMALLINT UNSIGNED NOT NULL COMMENT 'Map ID',
  `difficulty_tier` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Mythic+ difficulty tier (0=Normal, 1=Heroic, 2+=Mythic+)',
  `set_by_guid` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Player GUID who set this difficulty',
  `set_time` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'When difficulty was set',
  PRIMARY KEY (`instance_id`),
  INDEX `idx_map_id` (`map_id`),
  INDEX `idx_difficulty_tier` (`difficulty_tier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Mythic+ difficulty tracking per instance';

-- Add foreign key if instance table exists
SET @fk_exists = 0;
SELECT COUNT(*) INTO @fk_exists 
FROM information_schema.TABLE_CONSTRAINTS 
WHERE TABLE_SCHEMA = DATABASE() 
  AND TABLE_NAME = 'instance_difficulty_tracking' 
  AND CONSTRAINT_NAME = 'fk_instance_difficulty_instance'
  AND CONSTRAINT_TYPE = 'FOREIGN KEY';

SET @sql = IF(@fk_exists = 0 AND EXISTS (SELECT 1 FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'instance'),
    'ALTER TABLE `instance_difficulty_tracking` ADD CONSTRAINT `fk_instance_difficulty_instance` FOREIGN KEY (`instance_id`) REFERENCES `instance` (`id`) ON DELETE CASCADE',
    'SELECT ''Foreign key already exists or instance table not found'' AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ============================================================
-- 5. DAILY SYSTEM
-- ============================================================
CREATE TABLE IF NOT EXISTS `custom_daily_login` (
  `player_guid` INT UNSIGNED NOT NULL,
  `last_login_date` DATE DEFAULT NULL,
  `consecutive_days` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Consecutive login days',
  `total_days` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total login days',
  `rewards_claimed` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Tracks claimed rewards',
  `last_reward_date` DATE DEFAULT NULL COMMENT 'Last date reward was claimed',
  PRIMARY KEY (`player_guid`),
  CONSTRAINT `fk_daily_login_guid` FOREIGN KEY (`player_guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Daily login reward tracking';

CREATE TABLE IF NOT EXISTS `custom_pve_bounty` (
  `bounty_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `target_entry` INT UNSIGNED NOT NULL COMMENT 'Creature template entry',
  `target_name` VARCHAR(255) DEFAULT NULL COMMENT 'Creature name',
  `total_kills_needed` INT UNSIGNED NOT NULL DEFAULT 1000 COMMENT 'Total kills needed',
  `current_kills` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Current kills',
  `expiry_time` TIMESTAMP NULL DEFAULT NULL COMMENT 'Bounty expiry',
  `reward_item` INT UNSIGNED DEFAULT NULL COMMENT 'Reward item entry',
  `reward_points` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Progression points reward',
  `is_active` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Is bounty active',
  `created_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`bounty_id`),
  INDEX `idx_target_entry` (`target_entry`),
  INDEX `idx_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='PvE bounty system';

CREATE TABLE IF NOT EXISTS `character_daily_progress` (
  `guid` INT UNSIGNED NOT NULL,
  `daily_date` DATE NOT NULL,
  `dungeons_completed` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Dungeons completed today',
  `raids_completed` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Raids completed today',
  `pvp_kills` SMALLINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'PvP kills today',
  `quests_completed` SMALLINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Quests completed today',
  `daily_reward_claimed` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Daily reward claimed',
  PRIMARY KEY (`guid`, `daily_date`),
  CONSTRAINT `fk_daily_progress_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Daily progression tracking';

-- ============================================================
-- 6. PVP PROGRESSION
-- ============================================================
CREATE TABLE IF NOT EXISTS `character_pvp_progression` (
  `guid` INT UNSIGNED NOT NULL,
  `pvp_tier` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'PvP progression tier',
  `pvp_rating` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'PvP rating',
  `total_pvp_kills` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total PvP kills',
  `total_pvp_deaths` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total PvP deaths',
  `pvp_points` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'PvP progression points',
  `pvp_points_spent` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'PvP points spent',
  `highest_rating` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Highest rating achieved',
  `arena_wins` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Arena wins',
  `arena_losses` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Arena losses',
  `bg_wins` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Battleground wins',
  `bg_losses` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Battleground losses',
  `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`),
  CONSTRAINT `fk_pvp_progression_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='PvP progression tracking';

-- ============================================================
-- 7. PALACE STATISTICS
-- ============================================================
CREATE TABLE IF NOT EXISTS `palace_stats` (
  `guid` INT UNSIGNED NOT NULL,
  `total_damage_dealt` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total damage dealt',
  `total_healing_done` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total healing done',
  `highest_floor_reached` INT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Highest floor',
  `best_floor_time` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Best completion time (seconds)',
  `total_floors_completed` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total floors completed',
  `total_deaths` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total deaths in palace',
  `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`),
  CONSTRAINT `fk_palace_stats_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Bloody Palace player statistics';

CREATE TABLE IF NOT EXISTS `palace_scores` (
  `score_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `guid` INT UNSIGNED NOT NULL,
  `floor` INT UNSIGNED NOT NULL COMMENT 'Floor completed',
  `completion_time` INT UNSIGNED NOT NULL COMMENT 'Time in seconds',
  `damage_dealt` BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `healing_done` BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `score_date` DATE NOT NULL COMMENT 'Date of completion',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`score_id`),
  INDEX `idx_guid_date` (`guid`, `score_date`),
  INDEX `idx_floor_time` (`floor`, `completion_time`),
  CONSTRAINT `fk_palace_scores_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Daily palace scores for leaderboards';

-- ============================================================
-- 8. DAILY CHALLENGES
-- ============================================================
CREATE TABLE IF NOT EXISTS `daily_challenges` (
  `challenge_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `challenge_type` TINYINT UNSIGNED NOT NULL COMMENT '0=Daily, 1=Weekly',
  `challenge_name` VARCHAR(255) NOT NULL COMMENT 'Challenge name',
  `challenge_description` TEXT COMMENT 'Challenge description',
  `target_type` TINYINT UNSIGNED NOT NULL COMMENT '0=Kills, 1=Dungeons, 2=Raids, 3=PvP, 4=Quests',
  `target_value` INT UNSIGNED NOT NULL COMMENT 'Target value to complete',
  `reward_points` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Progression points reward',
  `reward_item` INT UNSIGNED DEFAULT NULL COMMENT 'Item reward entry',
  `reward_item_count` INT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Item count',
  `is_active` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Is challenge active',
  `start_date` DATE NOT NULL COMMENT 'Challenge start date',
  `end_date` DATE NOT NULL COMMENT 'Challenge end date',
  PRIMARY KEY (`challenge_id`),
  INDEX `idx_type_active` (`challenge_type`, `is_active`),
  INDEX `idx_dates` (`start_date`, `end_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Daily and weekly challenges';

CREATE TABLE IF NOT EXISTS `character_challenge_progress` (
  `guid` INT UNSIGNED NOT NULL,
  `challenge_id` INT UNSIGNED NOT NULL,
  `progress` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Current progress',
  `completed` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Is completed',
  `completed_date` TIMESTAMP NULL DEFAULT NULL COMMENT 'Completion date',
  `reward_claimed` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Reward claimed',
  PRIMARY KEY (`guid`, `challenge_id`),
  CONSTRAINT `fk_challenge_progress_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE,
  CONSTRAINT `fk_challenge_progress_challenge` FOREIGN KEY (`challenge_id`) REFERENCES `daily_challenges` (`challenge_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Character challenge progress';

-- ============================================================
-- 9. GUILD PROGRESSION
-- ============================================================
CREATE TABLE IF NOT EXISTS `guild_progression` (
  `guild_id` INT UNSIGNED NOT NULL,
  `guild_power_level` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total guild power level',
  `total_guild_kills` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total kills by all members',
  `total_guild_points` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total progression points',
  `guild_tier` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Guild progression tier',
  `challenges_completed` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Guild challenges completed',
  `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`guild_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Guild progression tracking';

-- Add foreign key if guild table exists
SET @fk_exists = 0;
SELECT COUNT(*) INTO @fk_exists 
FROM information_schema.TABLE_CONSTRAINTS 
WHERE TABLE_SCHEMA = DATABASE() 
  AND TABLE_NAME = 'guild_progression' 
  AND CONSTRAINT_NAME = 'fk_guild_progression_id'
  AND CONSTRAINT_TYPE = 'FOREIGN KEY';

SET @sql = IF(@fk_exists = 0 AND EXISTS (SELECT 1 FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'guild'),
    'ALTER TABLE `guild_progression` ADD CONSTRAINT `fk_guild_progression_id` FOREIGN KEY (`guild_id`) REFERENCES `guild` (`guildid`) ON DELETE CASCADE',
    'SELECT ''Foreign key already exists or guild table not found'' AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

CREATE TABLE IF NOT EXISTS `guild_challenges` (
  `challenge_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `guild_id` INT UNSIGNED NOT NULL,
  `challenge_type` TINYINT UNSIGNED NOT NULL COMMENT '0=Kills, 1=Dungeons, 2=Raids, 3=PvP',
  `target_value` INT UNSIGNED NOT NULL COMMENT 'Target value',
  `current_progress` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Current progress',
  `reward_points` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Reward points',
  `is_completed` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Is completed',
  `start_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `end_date` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`challenge_id`),
  INDEX `idx_guild_id` (`guild_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Guild challenges';

-- Add foreign key if guild table exists
SET @fk_exists = 0;
SELECT COUNT(*) INTO @fk_exists 
FROM information_schema.TABLE_CONSTRAINTS 
WHERE TABLE_SCHEMA = DATABASE() 
  AND TABLE_NAME = 'guild_challenges' 
  AND CONSTRAINT_NAME = 'fk_guild_challenges_id'
  AND CONSTRAINT_TYPE = 'FOREIGN KEY';

SET @sql = IF(@fk_exists = 0 AND EXISTS (SELECT 1 FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'guild'),
    'ALTER TABLE `guild_challenges` ADD CONSTRAINT `fk_guild_challenges_id` FOREIGN KEY (`guild_id`) REFERENCES `guild` (`guildid`) ON DELETE CASCADE',
    'SELECT ''Foreign key already exists or guild table not found'' AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ============================================================
-- 10. ACHIEVEMENT INTEGRATION
-- ============================================================
CREATE TABLE IF NOT EXISTS `progressive_achievements` (
  `achievement_id` INT UNSIGNED NOT NULL COMMENT 'Achievement entry ID',
  `achievement_type` TINYINT UNSIGNED NOT NULL COMMENT '0=Kills, 1=Tier, 2=Prestige, 3=Floor, 4=Points',
  `requirement_value` INT UNSIGNED NOT NULL COMMENT 'Required value',
  `reward_points` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Bonus progression points',
  `is_active` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  PRIMARY KEY (`achievement_id`),
  INDEX `idx_type` (`achievement_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Progressive system achievements';

CREATE TABLE IF NOT EXISTS `character_progressive_achievements` (
  `guid` INT UNSIGNED NOT NULL,
  `achievement_id` INT UNSIGNED NOT NULL,
  `completed_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`, `achievement_id`),
  CONSTRAINT `fk_prog_ach_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE,
  CONSTRAINT `fk_prog_ach_id` FOREIGN KEY (`achievement_id`) REFERENCES `progressive_achievements` (`achievement_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Character progressive achievements';

-- Insert default achievements if they don't exist
INSERT IGNORE INTO `progressive_achievements` (`achievement_id`, `achievement_type`, `requirement_value`, `reward_points`) VALUES
(9001, 0, 100, 100),      -- Kill 100 creatures
(9002, 0, 1000, 1000),   -- Kill 1000 creatures
(9003, 0, 10000, 10000), -- Kill 10000 creatures
(9004, 1, 5, 5000),       -- Reach Tier 5
(9005, 1, 10, 20000),     -- Reach Tier 10
(9006, 2, 1, 50000),      -- Prestige Level 1
(9007, 3, 10, 2000),      -- Reach Floor 10
(9008, 3, 50, 10000),     -- Reach Floor 50
(9009, 4, 100000, 5000),  -- Earn 100k points
(9010, 4, 1000000, 50000); -- Earn 1M points

-- ============================================================
-- 15. ENHANCED GLYPH SYSTEM (CHARACTER DATA)
-- ============================================================
CREATE TABLE IF NOT EXISTS `character_enhanced_glyphs` (
  `guid` INT UNSIGNED NOT NULL,
  `glyph_id` INT UNSIGNED NOT NULL,
  `slot` TINYINT UNSIGNED NOT NULL COMMENT 'Glyph slot (0-5)',
  `applied_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`, `slot`),
  CONSTRAINT `fk_char_enhanced_glyphs_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Player applied enhanced glyphs';

-- ============================================================
-- 16. ENHANCED GEM SYSTEM (CHARACTER DATA)
-- ============================================================
CREATE TABLE IF NOT EXISTS `character_item_gems` (
  `item_guid` BIGINT UNSIGNED NOT NULL,
  `socket_slot` TINYINT UNSIGNED NOT NULL COMMENT 'Socket slot (0-2)',
  `gem_id` INT UNSIGNED NOT NULL,
  `applied_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`item_guid`, `socket_slot`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Gems applied to player items';

-- Add foreign key if item_instance table exists and column types are compatible
SET @fk_exists = 0;
SELECT COUNT(*) INTO @fk_exists 
FROM information_schema.TABLE_CONSTRAINTS 
WHERE TABLE_SCHEMA = DATABASE() 
  AND TABLE_NAME = 'character_item_gems' 
  AND CONSTRAINT_NAME = 'fk_char_item_gems_guid'
  AND CONSTRAINT_TYPE = 'FOREIGN KEY';

SET @table_exists = 0;
SELECT COUNT(*) INTO @table_exists
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = DATABASE() 
  AND TABLE_NAME = 'item_instance';

SET @col_type_match = 0;
SELECT COUNT(*) INTO @col_type_match
FROM information_schema.COLUMNS c1
JOIN information_schema.COLUMNS c2 ON c1.DATA_TYPE = c2.DATA_TYPE 
  AND c1.COLUMN_TYPE = c2.COLUMN_TYPE
WHERE c1.TABLE_SCHEMA = DATABASE() AND c1.TABLE_NAME = 'character_item_gems' AND c1.COLUMN_NAME = 'item_guid'
  AND c2.TABLE_SCHEMA = DATABASE() AND c2.TABLE_NAME = 'item_instance' AND c2.COLUMN_NAME = 'guid';

SET @sql = IF(@fk_exists = 0 AND @table_exists > 0 AND @col_type_match > 0,
    'ALTER TABLE `character_item_gems` ADD CONSTRAINT `fk_char_item_gems_guid` FOREIGN KEY (`item_guid`) REFERENCES `item_instance` (`guid`) ON DELETE CASCADE',
    'SELECT ''Foreign key already exists, item_instance table not found, or column types incompatible'' AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ============================================================
-- 17. INSTANCE RESET SYSTEM
-- ============================================================
CREATE TABLE IF NOT EXISTS `instance_completion_tracking` (
  `guid` INT UNSIGNED NOT NULL,
  `map_id` INT UNSIGNED NOT NULL,
  `completion_count` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Number of times completed',
  `last_completion_time` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Unix timestamp of last completion',
  `best_time` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Best completion time in seconds',
  `highest_difficulty_tier` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Highest difficulty tier completed',
  `total_kills` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total kills in this instance',
  `total_deaths` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total deaths in this instance',
  `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`, `map_id`),
  INDEX `idx_map_id` (`map_id`),
  INDEX `idx_completion_count` (`completion_count`),
  CONSTRAINT `fk_instance_completion_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Instance completion tracking per player';

CREATE TABLE IF NOT EXISTS `instance_reset_usage` (
  `usage_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `guid` INT UNSIGNED NOT NULL,
  `map_id` INT UNSIGNED NOT NULL,
  `reset_time` INT UNSIGNED NOT NULL COMMENT 'Unix timestamp of reset',
  PRIMARY KEY (`usage_id`),
  INDEX `idx_guid_map` (`guid`, `map_id`),
  INDEX `idx_reset_time` (`reset_time`),
  CONSTRAINT `fk_instance_reset_usage_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Instance reset usage tracking for daily limits and cooldowns';

-- ============================================================
-- 18. PARAGON SYSTEM
-- ============================================================
CREATE TABLE IF NOT EXISTS `character_paragon` (
  `guid` INT UNSIGNED NOT NULL PRIMARY KEY,
  `paragon_level` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Current paragon level',
  `paragon_experience` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Experience towards next paragon level',
  `total_paragon_experience` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total paragon experience earned',
  `paragon_points_available` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Unspent paragon points',
  `paragon_points_total` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total paragon points earned',
  `paragon_tier` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Paragon tier (every 100 levels)',
  `highest_paragon_level` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Highest paragon level reached',
  `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT `fk_paragon_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE,
  INDEX `idx_paragon_level` (`paragon_level`),
  INDEX `idx_paragon_tier` (`paragon_tier`),
  INDEX `idx_total_paragon_experience` (`total_paragon_experience`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Paragon system progression';

CREATE TABLE IF NOT EXISTS `character_paragon_stats` (
  `guid` INT UNSIGNED NOT NULL,
  `stat_type` TINYINT UNSIGNED NOT NULL COMMENT '0=Core, 1=Offense, 2=Defense, 3=Utility',
  `stat_id` TINYINT UNSIGNED NOT NULL COMMENT 'Stat ID within category',
  `points_allocated` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Points allocated to this stat',
  `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`, `stat_type`, `stat_id`),
  CONSTRAINT `fk_paragon_stats_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Paragon stat point allocation';

CREATE TABLE IF NOT EXISTS `character_paragon_milestones` (
  `guid` INT UNSIGNED NOT NULL,
  `milestone_id` INT UNSIGNED NOT NULL COMMENT 'Milestone level (100, 200, 500, etc.)',
  `reward_claimed` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Whether milestone reward was claimed',
  `date_achieved` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`, `milestone_id`),
  CONSTRAINT `fk_paragon_milestones_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Paragon milestone achievements';

CREATE TABLE IF NOT EXISTS `character_paragon_seasonal` (
  `guid` INT UNSIGNED NOT NULL,
  `season_id` INT UNSIGNED NOT NULL,
  `seasonal_paragon_level` INT UNSIGNED NOT NULL DEFAULT 0,
  `seasonal_experience` BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `seasonal_points_allocated` INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`guid`, `season_id`),
  CONSTRAINT `fk_paragon_seasonal_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Seasonal paragon progression';

-- ============================================================
-- COMPLETE!
-- ============================================================

