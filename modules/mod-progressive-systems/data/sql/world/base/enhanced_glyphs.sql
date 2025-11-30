-- ============================================================
-- Enhanced Glyph System
-- Progressive glyphs with powerful effects
-- ============================================================

CREATE TABLE IF NOT EXISTS `enhanced_glyphs` (
  `glyph_id` INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
  `spell_id` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Spell ID this glyph affects (0 = all spells)',
  `name` VARCHAR(255) NOT NULL,
  `description` TEXT,
  `slot_type` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '0=Major, 1=Minor, 2=Prime',
  `required_level` INT UNSIGNED NOT NULL DEFAULT 80,
  `required_tier` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Progression tier required',
  `required_prestige` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Prestige level required',
  `stat_bonus` FLOAT NOT NULL DEFAULT 0.0 COMMENT 'Stat bonus percentage',
  `cooldown_reduction` FLOAT NOT NULL DEFAULT 0.0 COMMENT 'Cooldown reduction percentage',
  `cost_reduction` FLOAT NOT NULL DEFAULT 0.0 COMMENT 'Cost reduction percentage',
  `damage_bonus` FLOAT NOT NULL DEFAULT 0.0 COMMENT 'Damage bonus percentage',
  `healing_bonus` FLOAT NOT NULL DEFAULT 0.0 COMMENT 'Healing bonus percentage',
  `is_active` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  INDEX `idx_slot_type` (`slot_type`),
  INDEX `idx_required_tier` (`required_tier`),
  INDEX `idx_required_prestige` (`required_prestige`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Enhanced glyph definitions';

-- Example glyphs
INSERT IGNORE INTO `enhanced_glyphs` (`glyph_id`, `spell_id`, `name`, `description`, `slot_type`, `required_level`, `required_tier`, `required_prestige`, `stat_bonus`, `cooldown_reduction`, `cost_reduction`, `damage_bonus`, `healing_bonus`, `is_active`) VALUES
(90001, 0, 'Glyph of Power', 'Increases all damage and healing by 5%', 0, 80, 1, 0, 0.0, 0.0, 0.0, 0.05, 0.05, 1),
(90002, 0, 'Prime Glyph of Mastery', 'Increases all stats by 10%', 2, 80, 5, 1, 0.10, 0.0, 0.0, 0.0, 0.0, 1),
(90003, 0, 'Glyph of Haste', 'Reduces all cooldowns by 10%', 0, 80, 3, 0, 0.0, 0.10, 0.0, 0.0, 0.0, 1),
(90004, 0, 'Glyph of Efficiency', 'Reduces all spell costs by 15%', 1, 80, 2, 0, 0.0, 0.0, 0.15, 0.0, 0.0, 1);

CREATE TABLE IF NOT EXISTS `character_enhanced_glyphs` (
  `guid` INT UNSIGNED NOT NULL,
  `glyph_id` INT UNSIGNED NOT NULL,
  `slot` TINYINT UNSIGNED NOT NULL COMMENT 'Glyph slot (0-5)',
  `applied_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`, `slot`),
  CONSTRAINT `fk_char_enhanced_glyphs_guid` FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE,
  CONSTRAINT `fk_char_enhanced_glyphs_id` FOREIGN KEY (`glyph_id`) REFERENCES `enhanced_glyphs` (`glyph_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Player applied enhanced glyphs';

