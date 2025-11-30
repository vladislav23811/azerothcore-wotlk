-- ============================================================
-- AUTO ITEM GENERATOR - Database Schema
-- ============================================================

-- Item generation rules
CREATE TABLE IF NOT EXISTS `auto_item_rules` (
  `rule_id` INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
  `base_item_entry` INT UNSIGNED NOT NULL COMMENT 'Base item template entry',
  `difficulty_tier` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Difficulty tier (0=Normal, 1=Heroic, etc.)',
  `progression_tier` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Progression tier',
  `boss_entry` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Specific boss entry (0 = any)',
  `map_id` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Specific map (0 = any)',
  `stat_multiplier` FLOAT NOT NULL DEFAULT 1.0 COMMENT 'Multiplier for item stats',
  `ilvl_bonus` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Item level bonus',
  `quality_bonus` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Quality upgrade (0-6)',
  `allow_random_enchant` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Allow random enchantments',
  `allow_socket` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Allow sockets',
  `min_sockets` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Minimum sockets',
  `max_sockets` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Maximum sockets',
  `drop_chance` FLOAT NOT NULL DEFAULT 1.0 COMMENT 'Drop chance (0.0 - 1.0)',
  `name_prefix` VARCHAR(255) DEFAULT NULL COMMENT 'Name prefix',
  `name_suffix` VARCHAR(255) DEFAULT NULL COMMENT 'Name suffix',
  `description` TEXT COMMENT 'Item description',
  `active` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Is rule active',
  `sort_order` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Sort order for rule priority',
  INDEX `idx_difficulty_tier` (`difficulty_tier`),
  INDEX `idx_progression_tier` (`progression_tier`),
  INDEX `idx_boss_entry` (`boss_entry`),
  INDEX `idx_map_id` (`map_id`),
  INDEX `idx_active` (`active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Automatic item generation rules';

-- Example rules
INSERT INTO `auto_item_rules` (`base_item_entry`, `difficulty_tier`, `progression_tier`, `stat_multiplier`, `ilvl_bonus`, `quality_bonus`, `name_prefix`, `description`, `active`) VALUES
(0, 1, 1, 1.5, 10, 1, 'Heroic', 'Heroic difficulty item', 1),
(0, 2, 2, 2.0, 20, 1, 'Mythic', 'Mythic difficulty item', 1),
(0, 3, 3, 3.0, 30, 2, 'Legendary', 'Legendary difficulty item', 1);

