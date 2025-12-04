-- Daily and Weekly Challenges System
-- Provides rotating challenges for players to complete

-- Drop dependent table first to avoid foreign key constraint issues
DROP TABLE IF EXISTS `character_challenge_progress`;

DROP TABLE IF EXISTS `daily_challenges`;
CREATE TABLE `daily_challenges` (
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
CREATE TABLE `character_challenge_progress` (
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

-- Example daily challenges
INSERT INTO `daily_challenges` (`challenge_type`, `challenge_name`, `challenge_description`, `target_type`, `target_value`, `reward_points`, `is_active`, `start_date`, `end_date`) VALUES
(0, 'Kill 100 Creatures', 'Kill 100 creatures of any type', 0, 100, 500, 1, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 1 DAY)),
(0, 'Complete 3 Dungeons', 'Complete 3 dungeons', 1, 3, 1000, 1, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 1 DAY)),
(0, 'Win 5 PvP Battles', 'Win 5 PvP battles', 3, 5, 750, 1, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 1 DAY));

-- Example weekly challenges
INSERT INTO `daily_challenges` (`challenge_type`, `challenge_name`, `challenge_description`, `target_type`, `target_value`, `reward_points`, `is_active`, `start_date`, `end_date`) VALUES
(1, 'Kill 1000 Creatures', 'Kill 1000 creatures this week', 0, 1000, 5000, 1, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 7 DAY)),
(1, 'Complete 10 Raids', 'Complete 10 raids this week', 2, 10, 10000, 1, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 7 DAY)),
(1, 'Reach Floor 50', 'Reach floor 50 in Infinite Dungeon', 0, 50, 7500, 1, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 7 DAY));

