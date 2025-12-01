-- ============================================================
-- PROGRESSIVE SYSTEMS - WORLD DATABASE AUTO SETUP
-- This file is automatically executed on server startup
-- Creates all world tables if they don't exist
-- ============================================================

-- ============================================================
-- 1. DIFFICULTY SCALING CONFIGURATION
-- ============================================================
CREATE TABLE IF NOT EXISTS `custom_difficulty_scaling` (
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

-- Insert default difficulty scaling data if not exists
INSERT IGNORE INTO `custom_difficulty_scaling` (`map_id`, `difficulty_tier`, `health_multiplier`, `damage_multiplier`, `loot_quality_bonus`, `experience_multiplier`, `required_item_level`, `reward_points`, `point_multiplier`, `comment`) VALUES
-- Naxxramas (Map 533)
(533, 0, 1.0, 1.0, 0, 1.0, 0, 100, 1.0, 'Naxxramas Normal'),
(533, 1, 2.0, 1.8, 1, 2.0, 200, 500, 1.0, 'Naxxramas Heroic'),
(533, 2, 3.5, 3.0, 1, 3.0, 220, 1000, 1.2, 'Naxxramas Mythic+1'),
(533, 3, 5.0, 4.5, 2, 4.0, 240, 2000, 1.5, 'Naxxramas Mythic+2'),
(533, 5, 10.0, 8.0, 2, 6.0, 260, 5000, 2.0, 'Naxxramas Mythic+5'),
(533, 10, 25.0, 20.0, 3, 10.0, 300, 20000, 3.0, 'Naxxramas Mythic+10'),

-- Icecrown Citadel (Map 631)
(631, 0, 1.0, 1.0, 0, 1.0, 0, 200, 1.0, 'ICC Normal'),
(631, 1, 2.5, 2.2, 1, 2.5, 250, 1000, 1.0, 'ICC Heroic'),
(631, 2, 4.0, 3.5, 1, 3.5, 270, 2500, 1.3, 'ICC Mythic+1'),
(631, 3, 6.0, 5.0, 2, 5.0, 290, 5000, 1.6, 'ICC Mythic+2'),
(631, 5, 12.0, 10.0, 2, 8.0, 320, 15000, 2.5, 'ICC Mythic+5'),
(631, 10, 30.0, 25.0, 3, 15.0, 350, 50000, 4.0, 'ICC Mythic+10'),

-- Ulduar (Map 603)
(603, 0, 1.0, 1.0, 0, 1.0, 0, 150, 1.0, 'Ulduar Normal'),
(603, 1, 2.2, 2.0, 1, 2.2, 220, 800, 1.0, 'Ulduar Heroic'),
(603, 2, 3.8, 3.2, 1, 3.2, 240, 2000, 1.2, 'Ulduar Mythic+1'),
(603, 3, 5.5, 4.8, 2, 4.5, 260, 4000, 1.5, 'Ulduar Mythic+2'),
(603, 5, 11.0, 9.5, 2, 7.5, 300, 12000, 2.2, 'Ulduar Mythic+5'),
(603, 10, 28.0, 24.0, 3, 12.0, 340, 40000, 3.5, 'Ulduar Mythic+10'),

-- Utgarde Keep (Map 574) - Example 5-man
(574, 0, 1.0, 1.0, 0, 1.0, 0, 50, 1.0, 'Utgarde Keep Normal'),
(574, 1, 1.8, 1.6, 0, 1.8, 180, 200, 1.0, 'Utgarde Keep Heroic'),
(574, 2, 2.5, 2.2, 0, 2.5, 200, 400, 1.1, 'Utgarde Keep Mythic+1'),
(574, 3, 3.5, 3.0, 1, 3.5, 220, 800, 1.3, 'Utgarde Keep Mythic+2'),
(574, 5, 6.0, 5.0, 1, 5.0, 250, 2000, 1.8, 'Utgarde Keep Mythic+5'),
(574, 10, 15.0, 12.0, 2, 10.0, 300, 8000, 2.5, 'Utgarde Keep Mythic+10');

-- ============================================================
-- 2. BLOODY PALACE WAVES
-- ============================================================
CREATE TABLE IF NOT EXISTS `bloody_palace_waves` (
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

-- Insert default wave data if not exists
INSERT IGNORE INTO `bloody_palace_waves` (`wave`, `creature_entry`, `count`, `boss_chance`, `floor_min`, `floor_max`, `scaling_multiplier`) VALUES
-- Floors 1-10 (Easy)
(1, 16360, 3, 0, 1, 10, 1.0),
(2, 17252, 3, 0, 1, 10, 1.0),
(3, 36805, 4, 0, 1, 10, 1.0),
(4, 31306, 4, 0, 1, 10, 1.0),
(5, 0, 0, 100, 1, 10, 1.0),
(6, 37012, 5, 0, 1, 10, 1.0),
(7, 25593, 5, 0, 1, 10, 1.0),
(8, 36808, 6, 0, 1, 10, 1.0),
(9, 16021, 6, 0, 1, 10, 1.0),
(10, 0, 0, 100, 1, 10, 1.0),
-- Floors 11-20 (Medium)
(11, 37007, 7, 0, 11, 20, 1.2),
(12, 18945, 7, 0, 11, 20, 1.2),
(13, 16360, 8, 0, 11, 20, 1.2),
(14, 17252, 8, 0, 11, 20, 1.2),
(15, 0, 0, 100, 11, 20, 1.5),
(16, 36805, 9, 0, 11, 20, 1.2),
(17, 31306, 9, 0, 11, 20, 1.2),
(18, 37012, 10, 0, 11, 20, 1.2),
(19, 25593, 10, 0, 11, 20, 1.2),
(20, 0, 0, 100, 11, 20, 1.5),
-- Floors 21-30 (Hard)
(21, 36808, 11, 0, 21, 30, 1.5),
(22, 16021, 11, 0, 21, 30, 1.5),
(23, 37007, 12, 0, 21, 30, 1.5),
(24, 18945, 12, 0, 21, 30, 1.5),
(25, 0, 0, 100, 21, 30, 2.0),
(26, 16360, 13, 0, 21, 30, 1.5),
(27, 17252, 13, 0, 21, 30, 1.5),
(28, 36805, 14, 0, 21, 30, 1.5),
(29, 31306, 14, 0, 21, 30, 1.5),
(30, 0, 0, 100, 21, 30, 2.0),
-- Floors 31+ (Very Hard - Infinite scaling)
(31, 37012, 15, 0, 31, 255, 2.0),
(32, 25593, 15, 0, 31, 255, 2.0),
(33, 36808, 16, 0, 31, 255, 2.0),
(34, 16021, 16, 0, 31, 255, 2.0),
(35, 0, 0, 100, 31, 255, 2.5),
(36, 37007, 17, 0, 31, 255, 2.0),
(37, 18945, 17, 0, 31, 255, 2.0),
(38, 16360, 18, 0, 31, 255, 2.0),
(39, 17252, 18, 0, 31, 255, 2.0),
(40, 0, 0, 100, 31, 255, 2.5);

-- ============================================================
-- 3. BLOODY PALACE BOSSES
-- ============================================================
CREATE TABLE IF NOT EXISTS `bloody_palace_bosses` (
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

-- Insert default boss data if not exists (replace with actual boss entries)
INSERT IGNORE INTO `bloody_palace_bosses` (`creature_entry`, `floor_min`, `floor_max`, `spawn_weight`, `name`) VALUES
-- Early floors (1-10)
(36597, 1, 10, 100, 'The Lich King (Easy)'),
(36612, 1, 10, 100, 'Frostmourne Guardian'),
-- Mid floors (11-30)
(36612, 11, 30, 80, 'Frostmourne Guardian (Hard)'),
(36597, 11, 30, 60, 'The Lich King (Hard)'),
-- High floors (31+)
(36597, 31, 255, 50, 'The Lich King (Nightmare)'),
(36612, 31, 255, 40, 'Frostmourne Guardian (Nightmare)');

-- ============================================================
-- 4. AUTO ITEM GENERATOR
-- ============================================================
CREATE TABLE IF NOT EXISTS `auto_item_rules` (
  `rule_id` INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
  `base_item_entry` INT UNSIGNED NOT NULL COMMENT 'Base item template entry (MUST be existing item with icon!)',
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Automatic item generation rules - NOTE: base_item_entry MUST be existing item with DisplayInfoID!';

-- ============================================================
-- 5. ENHANCED GLYPH SYSTEM
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

-- ============================================================
-- 6. ENHANCED GEM SYSTEM
-- ============================================================
CREATE TABLE IF NOT EXISTS `enhanced_gems` (
  `gem_id` INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
  `item_entry` INT UNSIGNED NOT NULL COMMENT 'Item entry ID for this gem (MUST be existing item with icon!)',
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Enhanced gem definitions - NOTE: item_entry MUST be existing item with DisplayInfoID!';

-- ============================================================
-- 7. INFINITE DUNGEON WAVES
-- ============================================================
CREATE TABLE IF NOT EXISTS `infinite_dungeon_waves` (
    `wave_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `floor_range_start` INT UNSIGNED NOT NULL COMMENT 'Starting floor for this wave',
    `floor_range_end` INT UNSIGNED NOT NULL COMMENT 'Ending floor for this wave',
    `wave_number` TINYINT UNSIGNED NOT NULL COMMENT 'Wave number within floor (1-5)',
    `creature_entry` INT UNSIGNED NOT NULL COMMENT 'Creature template entry',
    `creature_count` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Number of creatures to spawn',
    `spawn_delay` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Delay in milliseconds before spawning',
    `spawn_radius` FLOAT NOT NULL DEFAULT 10.0 COMMENT 'Spawn radius around player',
    `scaling_multiplier` FLOAT NOT NULL DEFAULT 1.0 COMMENT 'Additional scaling multiplier',
    PRIMARY KEY (`wave_id`),
    INDEX `idx_floor_range` (`floor_range_start`, `floor_range_end`),
    INDEX `idx_creature_entry` (`creature_entry`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Infinite dungeon wave definitions';

-- Insert example waves for floors 1-20
INSERT IGNORE INTO `infinite_dungeon_waves` (`floor_range_start`, `floor_range_end`, `wave_number`, `creature_entry`, `creature_count`, `spawn_delay`, `spawn_radius`) VALUES
-- Floor 1-5: Easy mobs
(1, 5, 1, 26529, 3, 0, 10.0),      -- Skeletal Construct
(1, 5, 2, 26530, 2, 5000, 10.0),   -- Skeletal Construct (delayed)
(1, 5, 3, 26528, 1, 10000, 10.0),  -- Bone Giant (boss wave)
-- Floor 6-10: Medium mobs
(6, 10, 1, 26529, 5, 0, 12.0),
(6, 10, 2, 26530, 3, 5000, 12.0),
(6, 10, 3, 26528, 2, 10000, 12.0),
(6, 10, 4, 26527, 1, 15000, 12.0), -- Abomination (boss wave)
-- Floor 11-20: Hard mobs
(11, 20, 1, 26529, 7, 0, 15.0),
(11, 20, 2, 26530, 5, 5000, 15.0),
(11, 20, 3, 26528, 3, 10000, 15.0),
(11, 20, 4, 26527, 2, 15000, 15.0),
(11, 20, 5, 26532, 1, 20000, 15.0); -- Lich (boss wave)

-- ============================================================
-- 8. PARAGON STAT DEFINITIONS
-- ============================================================
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
INSERT IGNORE INTO `paragon_stat_definitions` (`stat_type`, `stat_name`, `stat_description`, `class_mask`, `max_points`, `points_per_level`, `sort_order`) VALUES
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

-- ============================================================
-- 9. NPC CREATURE TEMPLATES
-- ============================================================
-- Note: These NPCs need to be created in creature_template
-- They are included here for reference, but should be added manually
-- or via a separate SQL file that runs after base setup

-- Main Menu NPC (190000)
INSERT IGNORE INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `scale`, `rank`, `dmgschool`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `mechanic_immune_mask`, `spell_school_immune_mask`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
(190000, 'Progression Master', 'Progressive Systems', 'Speak', 0, 80, 80, 0, 35, 1, 1, 1.14286, 1, 0, 0, 2000, 2000, 1, 1, 1, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, '', 0),
(190001, 'Item Upgrader', 'Upgrade Your Items', 'Speak', 0, 80, 80, 0, 35, 128, 1, 1.14286, 1, 0, 0, 2000, 2000, 1, 1, 1, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, '', 0),
(190002, 'Prestige Master', 'Reset for Power', 'Speak', 0, 80, 80, 0, 35, 1, 1, 1.14286, 1, 0, 0, 2000, 2000, 1, 1, 1, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, '', 0),
(190003, 'Difficulty Selector', 'Choose Your Challenge', 'Speak', 0, 80, 80, 0, 35, 1, 1, 1.14286, 1, 0, 0, 2000, 2000, 1, 1, 1, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, '', 0),
(190004, 'Reward Shop', 'Spend Your Points', 'Speak', 0, 80, 80, 0, 35, 128, 1, 1.14286, 1, 0, 0, 2000, 2000, 1, 1, 1, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, '', 0),
(190005, 'Infinite Dungeon', 'Endless Challenge', 'Speak', 0, 80, 80, 0, 35, 1, 1, 1.14286, 1, 0, 0, 2000, 2000, 1, 1, 1, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, '', 0),
(190006, 'Progressive Items', 'Tiered Gear Vendor', 'Speak', 0, 80, 80, 0, 35, 128, 1, 1.14286, 1, 0, 0, 2000, 2000, 1, 1, 1, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, '', 0),
(190007, 'Daily Challenges', 'Daily & Weekly Tasks', 'Speak', 0, 80, 80, 0, 35, 1, 1, 1.14286, 1, 0, 0, 2000, 2000, 1, 1, 1, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, '', 0),
(190020, 'Paragon Master', 'Unlimited Progression', 'Speak', 0, 80, 80, 0, 35, 1, 1, 1.14286, 1, 0, 0, 2000, 2000, 1, 1, 1, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, '', 0);

-- ============================================================
-- COMPLETE!
-- ============================================================

