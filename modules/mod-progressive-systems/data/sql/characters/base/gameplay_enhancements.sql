-- ============================================================
-- GAMEPLAY ENHANCEMENTS - Database Schema
-- ============================================================

-- Player enhancement settings
CREATE TABLE IF NOT EXISTS `player_enhancement_settings` (
  `guid` INT UNSIGNED NOT NULL PRIMARY KEY,
  `auto_loot` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Auto-loot enabled',
  `auto_vendor` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Auto-vendor enabled',
  `auto_repair` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Auto-repair enabled',
  `auto_sort_inventory` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Auto-sort inventory enabled',
  `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT `fk_enhancement_settings_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Player gameplay enhancement settings';

-- Player teleport locations
CREATE TABLE IF NOT EXISTS `player_teleport_locations` (
  `guid` INT UNSIGNED NOT NULL,
  `location_name` VARCHAR(255) NOT NULL,
  `map_id` INT UNSIGNED NOT NULL,
  `x` FLOAT NOT NULL,
  `y` FLOAT NOT NULL,
  `z` FLOAT NOT NULL,
  `o` FLOAT NOT NULL DEFAULT 0.0,
  `created_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`, `location_name`),
  CONSTRAINT `fk_teleport_locations_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Player custom teleport locations';

-- Player combat data (for combo/momentum systems)
CREATE TABLE IF NOT EXISTS `player_combat_data` (
  `guid` INT UNSIGNED NOT NULL PRIMARY KEY,
  `combo_count` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Current combo count',
  `consecutive_kills` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Consecutive kills',
  `last_kill_time` TIMESTAMP NULL DEFAULT NULL COMMENT 'Last kill timestamp',
  `momentum_multiplier` FLOAT NOT NULL DEFAULT 1.0 COMMENT 'Current momentum multiplier',
  `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT `fk_combat_data_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Player combat enhancement data';

