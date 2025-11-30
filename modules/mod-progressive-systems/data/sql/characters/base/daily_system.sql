-- Daily System Integration
-- From old server - Daily login rewards and bounties

DROP TABLE IF EXISTS `custom_daily_login`;
CREATE TABLE `custom_daily_login` (
  `player_guid` INT UNSIGNED NOT NULL,
  `last_login_date` DATE DEFAULT NULL,
  `consecutive_days` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Consecutive login days',
  `total_days` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total login days',
  `rewards_claimed` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Tracks claimed rewards',
  `last_reward_date` DATE DEFAULT NULL COMMENT 'Last date reward was claimed',
  PRIMARY KEY (`player_guid`),
  CONSTRAINT `fk_daily_login_guid` FOREIGN KEY (`player_guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Daily login reward tracking';

DROP TABLE IF EXISTS `custom_pve_bounty`;
CREATE TABLE `custom_pve_bounty` (
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

DROP TABLE IF EXISTS `character_daily_progress`;
CREATE TABLE `character_daily_progress` (
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

