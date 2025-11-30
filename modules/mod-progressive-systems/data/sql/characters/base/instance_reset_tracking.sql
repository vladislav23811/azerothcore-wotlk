-- ============================================================
-- Instance Reset System - Character Database
-- Tracks instance completions and reset usage
-- ============================================================

-- Instance completion tracking
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

-- Instance reset usage tracking
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

