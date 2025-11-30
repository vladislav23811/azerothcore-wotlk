-- ============================================================
-- Enhanced Gem System
-- Progressive gems with better stats and socket bonuses
-- ============================================================

CREATE TABLE IF NOT EXISTS `enhanced_gems` (
  `gem_id` INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
  `item_entry` INT UNSIGNED NOT NULL COMMENT 'Item entry ID for this gem',
  `name` VARCHAR(255) NOT NULL,
  `description` TEXT,
  `quality` TINYINT UNSIGNED NOT NULL DEFAULT 2 COMMENT '0=Normal, 1=Uncommon, 2=Rare, 3=Epic, 4=Legendary',
  `type` TINYINT UNSIGNED NOT NULL DEFAULT 64 COMMENT 'Gem type (1=Red, 2=Yellow, 4=Blue, 8=Purple, 16=Green, 32=Orange, 64=Prismatic)',
  `required_level` INT UNSIGNED NOT NULL DEFAULT 80,
  `required_tier` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Progression tier required',
  `required_prestige` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Prestige level required',
  `stat_bonus` INT NOT NULL DEFAULT 0 COMMENT 'Flat stat bonus',
  `stat_percent_bonus` FLOAT NOT NULL DEFAULT 0.0 COMMENT 'Percentage stat bonus',
  `socket_bonus_multiplier` FLOAT NOT NULL DEFAULT 1.0 COMMENT 'Multiplier for socket bonus',
  `is_active` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  INDEX `idx_quality` (`quality`),
  INDEX `idx_type` (`type`),
  INDEX `idx_required_tier` (`required_tier`),
  INDEX `idx_required_prestige` (`required_prestige`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Enhanced gem definitions';

-- Example gems
INSERT IGNORE INTO `enhanced_gems` (`gem_id`, `item_entry`, `name`, `description`, `quality`, `type`, `required_level`, `required_tier`, `required_prestige`, `stat_bonus`, `stat_percent_bonus`, `socket_bonus_multiplier`, `is_active`) VALUES
(80001, 80001, 'Progressive Gem of Strength', '+20 Strength', 2, 1, 80, 1, 0, 20, 0.0, 1.0, 1),
(80002, 80002, 'Elite Gem of Power', '+50 Strength, +5% All Stats', 3, 64, 80, 5, 0, 50, 0.05, 1.5, 1),
(80003, 80003, 'Legendary Gem of Mastery', '+100 All Stats, +10% All Stats', 4, 64, 80, 10, 1, 100, 0.10, 2.0, 1),
(80004, 80004, 'Progressive Gem of Agility', '+20 Agility', 2, 2, 80, 1, 0, 20, 0.0, 1.0, 1),
(80005, 80005, 'Progressive Gem of Intellect', '+20 Intellect', 2, 4, 80, 1, 0, 20, 0.0, 1.0, 1),
(80006, 80006, 'Progressive Gem of Stamina', '+20 Stamina', 2, 8, 80, 1, 0, 20, 0.0, 1.0, 1);

CREATE TABLE IF NOT EXISTS `character_item_gems` (
  `item_guid` BIGINT UNSIGNED NOT NULL,
  `socket_slot` TINYINT UNSIGNED NOT NULL COMMENT 'Socket slot (0-2)',
  `gem_id` INT UNSIGNED NOT NULL,
  `applied_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`item_guid`, `socket_slot`),
  CONSTRAINT `fk_char_item_gems_guid` FOREIGN KEY (`item_guid`) REFERENCES `item_instance` (`guid`) ON DELETE CASCADE,
  CONSTRAINT `fk_char_item_gems_id` FOREIGN KEY (`gem_id`) REFERENCES `enhanced_gems` (`gem_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Gems applied to player items';

