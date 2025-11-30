-- Difficulty Scaling Configuration
-- Defines scaling for different difficulty tiers

DROP TABLE IF EXISTS `custom_difficulty_scaling`;
CREATE TABLE `custom_difficulty_scaling` (
  `map_id` INT UNSIGNED NOT NULL COMMENT 'Map/Instance ID',
  `difficulty_tier` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Difficulty tier (0=Normal, 1=Heroic, 2=Mythic+1, etc.)',
  `health_multiplier` FLOAT NOT NULL DEFAULT 1.0 COMMENT 'Creature health multiplier',
  `damage_multiplier` FLOAT NOT NULL DEFAULT 1.0 COMMENT 'Creature damage multiplier',
  `loot_quality_bonus` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Bonus to loot quality (0-6)',
  `experience_multiplier` FLOAT NOT NULL DEFAULT 1.0 COMMENT 'Experience multiplier',
  `required_item_level` SMALLINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Minimum average item level required',
  `reward_points` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Progression points awarded on completion',
  `point_multiplier` FLOAT NOT NULL DEFAULT 1.0 COMMENT 'Multiplier for progression points',
  `comment` VARCHAR(255) DEFAULT NULL COMMENT 'Description',
  PRIMARY KEY (`map_id`, `difficulty_tier`),
  INDEX `idx_map_id` (`map_id`),
  INDEX `idx_difficulty_tier` (`difficulty_tier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Difficulty scaling configuration';

-- Example data for popular instances
-- Naxxramas (Map 533)
INSERT INTO `custom_difficulty_scaling` VALUES
(533, 0, 1.0, 1.0, 0, 1.0, 0, 100, 1.0, 'Naxxramas Normal'),
(533, 1, 2.0, 1.8, 1, 2.0, 200, 500, 1.0, 'Naxxramas Heroic'),
(533, 2, 3.5, 3.0, 1, 3.0, 220, 1000, 1.2, 'Naxxramas Mythic+1'),
(533, 3, 5.0, 4.5, 2, 4.0, 240, 2000, 1.5, 'Naxxramas Mythic+2'),
(533, 5, 10.0, 8.0, 2, 6.0, 260, 5000, 2.0, 'Naxxramas Mythic+5'),
(533, 10, 25.0, 20.0, 3, 10.0, 300, 20000, 3.0, 'Naxxramas Mythic+10');

-- Icecrown Citadel (Map 631)
INSERT INTO `custom_difficulty_scaling` VALUES
(631, 0, 1.0, 1.0, 0, 1.0, 0, 200, 1.0, 'ICC Normal'),
(631, 1, 2.5, 2.2, 1, 2.5, 250, 1000, 1.0, 'ICC Heroic'),
(631, 2, 4.0, 3.5, 1, 3.5, 270, 2500, 1.3, 'ICC Mythic+1'),
(631, 3, 6.0, 5.0, 2, 5.0, 290, 5000, 1.6, 'ICC Mythic+2'),
(631, 5, 12.0, 10.0, 2, 8.0, 320, 15000, 2.5, 'ICC Mythic+5'),
(631, 10, 30.0, 25.0, 3, 15.0, 350, 50000, 4.0, 'ICC Mythic+10');

-- Ulduar (Map 603)
INSERT INTO `custom_difficulty_scaling` VALUES
(603, 0, 1.0, 1.0, 0, 1.0, 0, 150, 1.0, 'Ulduar Normal'),
(603, 1, 2.2, 2.0, 1, 2.2, 220, 800, 1.0, 'Ulduar Heroic'),
(603, 2, 3.8, 3.2, 1, 3.2, 240, 2000, 1.2, 'Ulduar Mythic+1'),
(603, 3, 5.5, 4.8, 2, 4.5, 260, 4000, 1.5, 'Ulduar Mythic+2'),
(603, 5, 11.0, 9.5, 2, 7.5, 300, 12000, 2.2, 'Ulduar Mythic+5'),
(603, 10, 28.0, 24.0, 3, 12.0, 340, 40000, 3.5, 'Ulduar Mythic+10');

-- Example 5-man dungeons
-- Utgarde Keep (Map 574)
INSERT INTO `custom_difficulty_scaling` VALUES
(574, 0, 1.0, 1.0, 0, 1.0, 0, 50, 1.0, 'Utgarde Keep Normal'),
(574, 1, 1.8, 1.6, 0, 1.8, 180, 200, 1.0, 'Utgarde Keep Heroic'),
(574, 2, 2.5, 2.2, 0, 2.5, 200, 400, 1.1, 'Utgarde Keep Mythic+1'),
(574, 3, 3.5, 3.0, 1, 3.5, 220, 800, 1.3, 'Utgarde Keep Mythic+2'),
(574, 5, 6.0, 5.0, 1, 5.0, 250, 2000, 1.8, 'Utgarde Keep Mythic+5'),
(574, 10, 15.0, 12.0, 2, 10.0, 300, 8000, 2.5, 'Utgarde Keep Mythic+10');

