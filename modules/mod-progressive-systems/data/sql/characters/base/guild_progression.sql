-- Guild Progression System
-- Tracks guild-wide progression and challenges

DROP TABLE IF EXISTS `guild_progression`;
CREATE TABLE `guild_progression` (
  `guild_id` INT UNSIGNED NOT NULL,
  `guild_power_level` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total guild power level',
  `total_guild_kills` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total kills by all members',
  `total_guild_points` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total progression points',
  `guild_tier` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Guild progression tier',
  `challenges_completed` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Guild challenges completed',
  `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`guild_id`),
  CONSTRAINT `fk_guild_progression_id` FOREIGN KEY (`guild_id`) REFERENCES `guild` (`guildid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Guild progression tracking';

DROP TABLE IF EXISTS `guild_challenges`;
CREATE TABLE `guild_challenges` (
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
  INDEX `idx_guild_id` (`guild_id`),
  CONSTRAINT `fk_guild_challenges_id` FOREIGN KEY (`guild_id`) REFERENCES `guild` (`guildid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Guild challenges';

