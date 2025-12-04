-- Add reward_points column to characters table if it doesn't exist
-- This is used by many Lua scripts

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

-- Add shirt tier tracking if it doesn't exist
CREATE TABLE IF NOT EXISTS `character_shirt_tiers` (
  `guid` INT UNSIGNED NOT NULL,
  `current_tier` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Current progression tier (1-15)',
  `total_tiers_unlocked` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Highest tier unlocked',
  PRIMARY KEY (`guid`),
  CONSTRAINT `fk_shirt_tiers_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Character shirt/tabard tier progression';

