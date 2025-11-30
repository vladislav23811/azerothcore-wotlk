-- ============================================================
-- UNIFIED STAT SYSTEM - Database Schema
-- ============================================================

-- Stat modifiers table (stores all stat bonuses from all sources)
CREATE TABLE IF NOT EXISTS `unified_stat_modifiers` (
  `guid` INT UNSIGNED NOT NULL COMMENT 'Player GUID',
  `stat_type` TINYINT UNSIGNED NOT NULL COMMENT 'Stat type (0-50)',
  `stat_source` TINYINT UNSIGNED NOT NULL COMMENT 'Source (0=Base, 1=Equipment, 2=Paragon, etc.)',
  `flat_value` FLOAT NOT NULL DEFAULT 0.0 COMMENT 'Flat stat bonus',
  `percent_value` FLOAT NOT NULL DEFAULT 0.0 COMMENT 'Percentage stat bonus',
  `priority` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Modifier priority',
  `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`, `stat_type`, `stat_source`),
  INDEX `idx_guid` (`guid`),
  INDEX `idx_stat_type` (`stat_type`),
  CONSTRAINT `fk_unified_stat_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Unified stat modifiers from all sources';

