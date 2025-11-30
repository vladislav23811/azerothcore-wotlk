-- Bloody Palace Wave System
-- Integrated from old server for Infinite Dungeon system
-- This defines waves of creatures for the infinite dungeon challenge

DROP TABLE IF EXISTS `bloody_palace_waves`;
CREATE TABLE `bloody_palace_waves` (
  `wave` TINYINT UNSIGNED NOT NULL COMMENT 'Wave number (floor * 10 + wave)',
  `creature_entry` MEDIUMINT UNSIGNED NOT NULL COMMENT 'Creature template entry',
  `count` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Number of creatures to spawn',
  `boss_chance` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Chance to spawn boss instead (0-100)',
  `floor_min` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Minimum floor for this wave',
  `floor_max` TINYINT UNSIGNED NOT NULL DEFAULT 255 COMMENT 'Maximum floor for this wave',
  `scaling_multiplier` FLOAT NOT NULL DEFAULT 1.0 COMMENT 'Additional scaling for this wave',
  PRIMARY KEY (`wave`),
  INDEX `idx_floor_range` (`floor_min`, `floor_max`),
  INDEX `idx_creature_entry` (`creature_entry`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Bloody Palace wave definitions for infinite dungeon';

-- Wave data from old server (integrated)
-- Format: wave, creature_entry, count, boss_chance, floor_min, floor_max, scaling_multiplier
INSERT INTO `bloody_palace_waves` (`wave`, `creature_entry`, `count`, `boss_chance`, `floor_min`, `floor_max`, `scaling_multiplier`) VALUES
-- Floors 1-10 (Easy)
(1, 16360, 3, 0, 1, 10, 1.0),
(2, 17252, 3, 0, 1, 10, 1.0),
(3, 36805, 4, 0, 1, 10, 1.0),
(4, 31306, 4, 0, 1, 10, 1.0),
(5, 0, 0, 100, 1, 10, 1.0),  -- Boss wave every 5
(6, 37012, 5, 0, 1, 10, 1.0),
(7, 25593, 5, 0, 1, 10, 1.0),
(8, 36808, 6, 0, 1, 10, 1.0),
(9, 16021, 6, 0, 1, 10, 1.0),
(10, 0, 0, 100, 1, 10, 1.0),  -- Boss wave

-- Floors 11-20 (Medium)
(11, 37007, 7, 0, 11, 20, 1.2),
(12, 18945, 7, 0, 11, 20, 1.2),
(13, 16360, 8, 0, 11, 20, 1.2),
(14, 17252, 8, 0, 11, 20, 1.2),
(15, 0, 0, 100, 11, 20, 1.5),  -- Boss wave
(16, 36805, 9, 0, 11, 20, 1.2),
(17, 31306, 9, 0, 11, 20, 1.2),
(18, 37012, 10, 0, 11, 20, 1.2),
(19, 25593, 10, 0, 11, 20, 1.2),
(20, 0, 0, 100, 11, 20, 1.5),  -- Boss wave

-- Floors 21-30 (Hard)
(21, 36808, 11, 0, 21, 30, 1.5),
(22, 16021, 11, 0, 21, 30, 1.5),
(23, 37007, 12, 0, 21, 30, 1.5),
(24, 18945, 12, 0, 21, 30, 1.5),
(25, 0, 0, 100, 21, 30, 2.0),  -- Boss wave
(26, 16360, 13, 0, 21, 30, 1.5),
(27, 17252, 13, 0, 21, 30, 1.5),
(28, 36805, 14, 0, 21, 30, 1.5),
(29, 31306, 14, 0, 21, 30, 1.5),
(30, 0, 0, 100, 21, 30, 2.0),  -- Boss wave

-- Floors 31+ (Very Hard - Infinite scaling)
(31, 37012, 15, 0, 31, 255, 2.0),
(32, 25593, 15, 0, 31, 255, 2.0),
(33, 36808, 16, 0, 31, 255, 2.0),
(34, 16021, 16, 0, 31, 255, 2.0),
(35, 0, 0, 100, 31, 255, 2.5),  -- Boss wave
(36, 37007, 17, 0, 31, 255, 2.0),
(37, 18945, 17, 0, 31, 255, 2.0),
(38, 16360, 18, 0, 31, 255, 2.0),
(39, 17252, 18, 0, 31, 255, 2.0),
(40, 0, 0, 100, 31, 255, 2.5);  -- Boss wave

-- Note: Waves cycle after 40, scaling increases with floor number
-- Boss chance = 100 means spawn a boss from boss pool instead

