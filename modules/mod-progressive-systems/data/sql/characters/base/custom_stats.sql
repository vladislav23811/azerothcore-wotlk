-- ============================================================
-- CUSTOM STATS SYSTEM
-- Stores custom stats beyond standard 5 stats (STR, AGI, STA, INT, SPI)
-- ============================================================

CREATE TABLE IF NOT EXISTS `character_custom_stats` (
  `guid` INT UNSIGNED NOT NULL PRIMARY KEY,
  `intelligence_bonus` INT NOT NULL DEFAULT 0 COMMENT 'Bonus Intelligence stat',
  `attack_speed_bonus` INT NOT NULL DEFAULT 0 COMMENT 'Attack Speed bonus (percentage)',
  `cast_speed_bonus` INT NOT NULL DEFAULT 0 COMMENT 'Cast Speed bonus (percentage)',
  `movement_speed_bonus` INT NOT NULL DEFAULT 0 COMMENT 'Movement Speed bonus (percentage)',
  `critical_strike_bonus` INT NOT NULL DEFAULT 0 COMMENT 'Critical Strike bonus (rating)',
  `haste_bonus` INT NOT NULL DEFAULT 0 COMMENT 'Haste bonus (rating)',
  `mastery_bonus` INT NOT NULL DEFAULT 0 COMMENT 'Mastery bonus (rating)',
  `versatility_bonus` INT NOT NULL DEFAULT 0 COMMENT 'Versatility bonus (rating)',
  `lifesteal_bonus` INT NOT NULL DEFAULT 0 COMMENT 'Lifesteal bonus (percentage)',
  `multistrike_bonus` INT NOT NULL DEFAULT 0 COMMENT 'Multistrike bonus (rating)',
  `spell_power_bonus` INT NOT NULL DEFAULT 0 COMMENT 'Spell Power bonus',
  `attack_power_bonus` INT NOT NULL DEFAULT 0 COMMENT 'Attack Power bonus',
  `armor_bonus` INT NOT NULL DEFAULT 0 COMMENT 'Armor bonus',
  `resistance_bonus` INT NOT NULL DEFAULT 0 COMMENT 'All Resistances bonus',
  `health_regen_bonus` INT NOT NULL DEFAULT 0 COMMENT 'Health Regeneration bonus (percentage)',
  `mana_regen_bonus` INT NOT NULL DEFAULT 0 COMMENT 'Mana Regeneration bonus (percentage)',
  `experience_bonus` INT NOT NULL DEFAULT 0 COMMENT 'Experience gain bonus (percentage)',
  `gold_bonus` INT NOT NULL DEFAULT 0 COMMENT 'Gold gain bonus (percentage)',
  `loot_bonus` INT NOT NULL DEFAULT 0 COMMENT 'Loot quality bonus (percentage)',
  `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT `fk_custom_stats_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Custom character stats beyond standard stats';

-- Item custom stats tracking
CREATE TABLE IF NOT EXISTS `item_custom_stats` (
  `item_guid` BIGINT UNSIGNED NOT NULL PRIMARY KEY,
  `intelligence_bonus` INT NOT NULL DEFAULT 0,
  `attack_speed_bonus` INT NOT NULL DEFAULT 0,
  `cast_speed_bonus` INT NOT NULL DEFAULT 0,
  `movement_speed_bonus` INT NOT NULL DEFAULT 0,
  `critical_strike_bonus` INT NOT NULL DEFAULT 0,
  `haste_bonus` INT NOT NULL DEFAULT 0,
  `mastery_bonus` INT NOT NULL DEFAULT 0,
  `versatility_bonus` INT NOT NULL DEFAULT 0,
  `lifesteal_bonus` INT NOT NULL DEFAULT 0,
  `multistrike_bonus` INT NOT NULL DEFAULT 0,
  `spell_power_bonus` INT NOT NULL DEFAULT 0,
  `attack_power_bonus` INT NOT NULL DEFAULT 0,
  `armor_bonus` INT NOT NULL DEFAULT 0,
  `resistance_bonus` INT NOT NULL DEFAULT 0,
  `health_regen_bonus` INT NOT NULL DEFAULT 0,
  `mana_regen_bonus` INT NOT NULL DEFAULT 0,
  `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Custom stats on items';

-- Add foreign key if item_instance table exists and column types are compatible
SET @fk_exists = 0;
SELECT COUNT(*) INTO @fk_exists 
FROM information_schema.TABLE_CONSTRAINTS 
WHERE TABLE_SCHEMA = DATABASE() 
  AND TABLE_NAME = 'item_custom_stats' 
  AND CONSTRAINT_NAME = 'fk_item_custom_stats_guid'
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
WHERE c1.TABLE_SCHEMA = DATABASE() AND c1.TABLE_NAME = 'item_custom_stats' AND c1.COLUMN_NAME = 'item_guid'
  AND c2.TABLE_SCHEMA = DATABASE() AND c2.TABLE_NAME = 'item_instance' AND c2.COLUMN_NAME = 'guid';

SET @sql = IF(@fk_exists = 0 AND @table_exists > 0 AND @col_type_match > 0,
    'ALTER TABLE `item_custom_stats` ADD CONSTRAINT `fk_item_custom_stats_guid` FOREIGN KEY (`item_guid`) REFERENCES `item_instance` (`guid`) ON DELETE CASCADE',
    'SELECT ''Foreign key already exists, item_instance table not found, or column types incompatible'' AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Progressive stat enhancements (permanent stat increases)
CREATE TABLE IF NOT EXISTS `character_progressive_stat_enhancements` (
  `guid` INT UNSIGNED NOT NULL,
  `stat_type` TINYINT UNSIGNED NOT NULL COMMENT '0=Intelligence, 1=AttackSpeed, 2=CastSpeed, etc.',
  `enhancement_level` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Enhancement level',
  `total_invested_points` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total progression points invested',
  `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`, `stat_type`),
  CONSTRAINT `fk_progressive_stat_enhancements_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Progressive stat enhancements purchased with progression points';

