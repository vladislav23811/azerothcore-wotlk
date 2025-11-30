-- Add reward_points column to characters table if it doesn't exist
-- This is used by many Lua scripts

ALTER TABLE `characters` 
ADD COLUMN IF NOT EXISTS `reward_points` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Progression/reward points for player';

-- Add shirt tier tracking if it doesn't exist
CREATE TABLE IF NOT EXISTS `character_shirt_tiers` (
  `guid` INT UNSIGNED NOT NULL,
  `current_tier` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Current progression tier (1-15)',
  `total_tiers_unlocked` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Highest tier unlocked',
  PRIMARY KEY (`guid`),
  CONSTRAINT `fk_shirt_tiers_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Character shirt/tabard tier progression';

