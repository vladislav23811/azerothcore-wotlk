-- Unified Character Progression Table
-- This table is used by both C++ and Lua scripts
-- Matches the structure expected by progressive_systems_core.lua

DROP TABLE IF EXISTS `character_progression_unified`;
CREATE TABLE `character_progression_unified` (
  `guid` INT UNSIGNED NOT NULL PRIMARY KEY,
  `total_kills` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total creatures killed',
  `claimed_milestone` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Last milestone claimed',
  `prestige_level` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Prestige level',
  `difficulty_tier` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Current difficulty tier (0=Easy, 1=Normal, etc.)',
  `current_tier` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Current progression tier (affects point multipliers)',
  `total_power_level` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Calculated power level',
  `progression_points` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total progression points earned',
  `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT `fk_progression_unified_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Unified character progression tracking';

