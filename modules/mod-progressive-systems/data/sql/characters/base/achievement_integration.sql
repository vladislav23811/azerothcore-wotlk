-- Achievement Integration
-- Links progressive systems with achievements

DROP TABLE IF EXISTS `progressive_achievements`;
CREATE TABLE `progressive_achievements` (
  `achievement_id` INT UNSIGNED NOT NULL COMMENT 'Achievement entry ID',
  `achievement_type` TINYINT UNSIGNED NOT NULL COMMENT '0=Kills, 1=Tier, 2=Prestige, 3=Floor, 4=Points',
  `requirement_value` INT UNSIGNED NOT NULL COMMENT 'Required value',
  `reward_points` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Bonus progression points',
  `is_active` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  PRIMARY KEY (`achievement_id`),
  INDEX `idx_type` (`achievement_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Progressive system achievements';

DROP TABLE IF EXISTS `character_progressive_achievements`;
CREATE TABLE `character_progressive_achievements` (
  `guid` INT UNSIGNED NOT NULL,
  `achievement_id` INT UNSIGNED NOT NULL,
  `completed_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`, `achievement_id`),
  CONSTRAINT `fk_prog_ach_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE,
  CONSTRAINT `fk_prog_ach_id` FOREIGN KEY (`achievement_id`) REFERENCES `progressive_achievements` (`achievement_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Character progressive achievements';

-- Example achievements
INSERT INTO `progressive_achievements` (`achievement_id`, `achievement_type`, `requirement_value`, `reward_points`) VALUES
(9001, 0, 100, 100),      -- Kill 100 creatures
(9002, 0, 1000, 1000),   -- Kill 1000 creatures
(9003, 0, 10000, 10000), -- Kill 10000 creatures
(9004, 1, 5, 5000),       -- Reach Tier 5
(9005, 1, 10, 20000),     -- Reach Tier 10
(9006, 2, 1, 50000),      -- Prestige Level 1
(9007, 3, 10, 2000),      -- Reach Floor 10
(9008, 3, 50, 10000),     -- Reach Floor 50
(9009, 4, 100000, 5000),  -- Earn 100k points
(9010, 4, 1000000, 50000); -- Earn 1M points

