-- Bloody Palace Boss Pool
-- Defines which bosses can spawn at boss waves

DROP TABLE IF EXISTS `bloody_palace_bosses`;
CREATE TABLE `bloody_palace_bosses` (
  `boss_id` TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `creature_entry` MEDIUMINT UNSIGNED NOT NULL COMMENT 'Boss creature template entry',
  `floor_min` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Minimum floor to appear',
  `floor_max` TINYINT UNSIGNED NOT NULL DEFAULT 255 COMMENT 'Maximum floor to appear',
  `spawn_weight` TINYINT UNSIGNED NOT NULL DEFAULT 100 COMMENT 'Spawn weight (higher = more common)',
  `name` VARCHAR(255) DEFAULT NULL COMMENT 'Boss name',
  PRIMARY KEY (`boss_id`),
  INDEX `idx_floor_range` (`floor_min`, `floor_max`),
  INDEX `idx_creature_entry` (`creature_entry`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Bloody Palace boss pool';

-- Example bosses (replace with actual ICC/raid bosses)
INSERT INTO `bloody_palace_bosses` (`creature_entry`, `floor_min`, `floor_max`, `spawn_weight`, `name`) VALUES
-- Early floors (1-10)
(36597, 1, 10, 100, 'The Lich King (Easy)'),  -- Example: Replace with actual entry
(36612, 1, 10, 100, 'Frostmourne Guardian'),

-- Mid floors (11-30)
(36612, 11, 30, 80, 'Frostmourne Guardian (Hard)'),
(36597, 11, 30, 60, 'The Lich King (Hard)'),

-- High floors (31+)
(36597, 31, 255, 50, 'The Lich King (Nightmare)'),
(36612, 31, 255, 40, 'Frostmourne Guardian (Nightmare)');

-- Note: Replace creature_entry values with actual boss entries from your database

