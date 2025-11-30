-- ============================================================
-- PARAGON SYSTEM - Diablo 3 Style
-- Unlimited levels beyond max level with stat point allocation
-- ============================================================

-- Main paragon progression table
CREATE TABLE IF NOT EXISTS `character_paragon` (
  `guid` INT UNSIGNED NOT NULL PRIMARY KEY,
  `paragon_level` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Current paragon level',
  `paragon_experience` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Experience towards next paragon level',
  `total_paragon_experience` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total paragon experience earned',
  `paragon_points_available` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Unspent paragon points',
  `paragon_points_total` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total paragon points earned',
  `paragon_tier` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Paragon tier (every 100 levels)',
  `highest_paragon_level` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Highest paragon level reached',
  `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT `fk_paragon_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Paragon system progression';

-- Paragon stat allocation (class-specific)
CREATE TABLE IF NOT EXISTS `character_paragon_stats` (
  `guid` INT UNSIGNED NOT NULL,
  `stat_type` TINYINT UNSIGNED NOT NULL COMMENT '0=Core, 1=Offense, 2=Defense, 3=Utility',
  `stat_id` TINYINT UNSIGNED NOT NULL COMMENT 'Stat ID within category',
  `points_allocated` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Points allocated to this stat',
  `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`, `stat_type`, `stat_id`),
  CONSTRAINT `fk_paragon_stats_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Paragon stat point allocation';

-- Paragon milestones and achievements
CREATE TABLE IF NOT EXISTS `character_paragon_milestones` (
  `guid` INT UNSIGNED NOT NULL,
  `milestone_id` INT UNSIGNED NOT NULL COMMENT 'Milestone level (100, 200, 500, etc.)',
  `reward_claimed` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Whether milestone reward was claimed',
  `date_achieved` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`, `milestone_id`),
  CONSTRAINT `fk_paragon_milestones_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Paragon milestone achievements';

-- Paragon seasonal tracking (optional)
CREATE TABLE IF NOT EXISTS `character_paragon_seasonal` (
  `guid` INT UNSIGNED NOT NULL,
  `season_id` INT UNSIGNED NOT NULL,
  `seasonal_paragon_level` INT UNSIGNED NOT NULL DEFAULT 0,
  `seasonal_experience` BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `seasonal_points_allocated` INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`guid`, `season_id`),
  CONSTRAINT `fk_paragon_seasonal_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Seasonal paragon progression';

-- Paragon stat definitions (world database)
CREATE TABLE IF NOT EXISTS `paragon_stat_definitions` (
  `stat_id` INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
  `stat_type` TINYINT UNSIGNED NOT NULL COMMENT '0=Core, 1=Offense, 2=Defense, 3=Utility',
  `stat_name` VARCHAR(255) NOT NULL,
  `stat_description` TEXT,
  `class_mask` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Bitmask for allowed classes (0=all)',
  `max_points` INT UNSIGNED NOT NULL DEFAULT 50 COMMENT 'Maximum points that can be allocated',
  `points_per_level` FLOAT NOT NULL DEFAULT 1.0 COMMENT 'Stat value per point allocated',
  `icon_display_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `sort_order` INT UNSIGNED NOT NULL DEFAULT 0,
  `active` TINYINT UNSIGNED NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Paragon stat definitions';

-- Insert default paragon stats
INSERT INTO `paragon_stat_definitions` (`stat_type`, `stat_name`, `stat_description`, `class_mask`, `max_points`, `points_per_level`, `sort_order`) VALUES
-- Core Stats (Type 0)
(0, 'Strength', 'Increases Attack Power', 0, 50, 1.0, 1),
(0, 'Agility', 'Increases Critical Strike and Dodge', 0, 50, 1.0, 2),
(0, 'Intellect', 'Increases Spell Power and Mana', 0, 50, 1.0, 3),
(0, 'Stamina', 'Increases Health', 0, 50, 1.0, 4),
(0, 'Spirit', 'Increases Mana Regeneration', 0, 50, 1.0, 5),
-- Offense Stats (Type 1)
(1, 'Attack Speed', 'Increases attack speed by percentage', 0, 50, 0.5, 1),
(1, 'Critical Strike', 'Increases critical strike chance', 0, 50, 0.1, 2),
(1, 'Spell Power', 'Increases spell damage and healing', 0, 50, 1.0, 3),
(1, 'Attack Power', 'Increases physical damage', 0, 50, 1.0, 4),
(1, 'Haste', 'Increases casting and attack speed', 0, 50, 0.1, 5),
-- Defense Stats (Type 2)
(2, 'Armor', 'Increases physical damage reduction', 0, 50, 1.0, 1),
(2, 'Resistance', 'Increases magical damage reduction', 0, 50, 1.0, 2),
(2, 'Health', 'Increases maximum health', 0, 50, 10.0, 3),
(2, 'Dodge', 'Increases dodge chance', 0, 50, 0.1, 4),
(2, 'Block', 'Increases block chance and value', 0, 50, 0.1, 5),
-- Utility Stats (Type 3)
(3, 'Movement Speed', 'Increases movement speed', 0, 50, 0.5, 1),
(3, 'Experience', 'Increases experience gain', 0, 50, 0.5, 2),
(3, 'Gold Find', 'Increases gold dropped', 0, 50, 0.5, 3),
(3, 'Loot Quality', 'Increases chance for better loot', 0, 50, 0.1, 4),
(3, 'Resource Regeneration', 'Increases mana/energy/rage regeneration', 0, 50, 0.5, 5);

