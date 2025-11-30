-- Bloody Palace Statistics
-- Tracks player performance in infinite dungeon

DROP TABLE IF EXISTS `palace_stats`;
CREATE TABLE `palace_stats` (
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

DROP TABLE IF EXISTS `palace_scores`;
CREATE TABLE `palace_scores` (
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

