-- ============================================================
-- CREATE CUSTOM WEAPON TEMPLATE SYSTEM
-- Creates custom weapons by copying existing weapon properties
-- NO CLIENT PATCH REQUIRED - Uses existing weapon models!
-- ============================================================
-- 
-- IMPORTANT: This creates "reskins" of existing weapons
-- The weapon will look exactly like the template weapon
-- Only the name, description, and stats can be customized
-- ============================================================

USE w_world;

-- ============================================================
-- WEAPON TEMPLATE MAPPING TABLE
-- ============================================================
-- This table maps custom weapon IDs to existing weapon templates
-- Server can use this to track which template to use for display
CREATE TABLE IF NOT EXISTS `custom_weapon_templates` (
    `custom_entry` INT UNSIGNED NOT NULL PRIMARY KEY COMMENT 'Custom weapon entry ID',
    `template_entry` INT UNSIGNED NOT NULL COMMENT 'Existing weapon to use as template',
    `custom_name` VARCHAR(255) NOT NULL COMMENT 'Custom weapon name',
    `custom_description` TEXT COMMENT 'Custom weapon description',
    `stat_modifier` FLOAT DEFAULT 1.0 COMMENT 'Stat multiplier (1.0 = same, 1.5 = 50% stronger)',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_template` (`template_entry`),
    FOREIGN KEY (`template_entry`) REFERENCES `item_template`(`entry`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Maps custom weapons to existing weapon templates';

-- ============================================================
-- EXAMPLE: CREATE CUSTOM SWORD (Based on Thunderfury)
-- ============================================================
-- This copies ALL properties from Thunderfury (entry 19019)
-- and creates a new weapon with entry 99990

-- Step 1: Copy the entire weapon structure
INSERT INTO `item_template` (
    `entry`, `class`, `subclass`, `SoundOverrideSubclass`, `name`,
    `displayid`, `Quality`, `Flags`, `FlagsExtra`, `BuyCount`, `BuyPrice`, `SellPrice`,
    `InventoryType`, `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`,
    `RequiredSkill`, `RequiredSkillRank`, `RequiredSpell`, `RequiredHonorRank`,
    `RequiredCityRank`, `RequiredReputationFaction`, `RequiredReputationRank`,
    `maxcount`, `stackable`, `ContainerSlots`,
    `stat_type1`, `stat_value1`, `stat_type2`, `stat_value2`,
    `stat_type3`, `stat_value3`, `stat_type4`, `stat_value4`,
    `stat_type5`, `stat_value5`, `stat_type6`, `stat_value6`,
    `stat_type7`, `stat_value7`, `stat_type8`, `stat_value8`,
    `stat_type9`, `stat_value9`, `stat_type10`, `stat_value10`,
    `ScalingStatDistribution`, `ScalingStatValue`,
    `dmg_min1`, `dmg_max1`, `dmg_type1`, `dmg_min2`, `dmg_max2`, `dmg_type2`,
    `armor`, `holy_res`, `fire_res`, `nature_res`, `frost_res`, `shadow_res`, `arcane_res`,
    `delay`, `ammo_type`, `RangedModRange`,
    `spellid_1`, `spelltrigger_1`, `spellcharges_1`, `spellppmRate_1`, `spellcooldown_1`,
    `spellcategory_1`, `spellcategorycooldown_1`,
    `spellid_2`, `spelltrigger_2`, `spellcharges_2`, `spellppmRate_2`, `spellcooldown_2`,
    `spellcategory_2`, `spellcategorycooldown_2`,
    `spellid_3`, `spelltrigger_3`, `spellcharges_3`, `spellppmRate_3`, `spellcooldown_3`,
    `spellcategory_3`, `spellcategorycooldown_3`,
    `spellid_4`, `spelltrigger_4`, `spellcharges_4`, `spellppmRate_4`, `spellcooldown_4`,
    `spellcategory_4`, `spellcategorycooldown_4`,
    `spellid_5`, `spelltrigger_5`, `spellcharges_5`, `spellppmRate_5`, `spellcooldown_5`,
    `spellcategory_5`, `spellcategorycooldown_5`,
    `bonding`, `description`, `PageText`, `LanguageID`, `PageMaterial`,
    `startquest`, `lockid`, `Material`, `sheath`, `RandomProperty`, `RandomSuffix`,
    `block`, `itemset`, `MaxDurability`, `area`, `Map`, `BagFamily`, `TotemCategory`,
    `socketColor_1`, `socketContent_1`, `socketColor_2`, `socketContent_2`,
    `socketColor_3`, `socketContent_3`, `socketBonus`, `GemProperties`,
    `RequiredDisenchantSkill`, `ArmorDamageModifier`, `duration`, `ItemLimitCategory`,
    `HolidayId`, `ScriptName`, `DisenchantID`, `FoodType`, `minMoneyLoot`, `maxMoneyLoot`,
    `flagsCustom`
)
SELECT 
    99990,  -- NEW CUSTOM ENTRY
    class, subclass, SoundOverrideSubclass, name,
    displayid, Quality, Flags, FlagsExtra, BuyCount, BuyPrice, SellPrice,
    InventoryType, AllowableClass, AllowableRace, ItemLevel, RequiredLevel,
    RequiredSkill, RequiredSkillRank, RequiredSpell, RequiredHonorRank,
    RequiredCityRank, RequiredReputationFaction, RequiredReputationRank,
    maxcount, stackable, ContainerSlots,
    stat_type1, stat_value1, stat_type2, stat_value2,
    stat_type3, stat_value3, stat_type4, stat_value4,
    stat_type5, stat_value5, stat_type6, stat_value6,
    stat_type7, stat_value7, stat_type8, stat_value8,
    stat_type9, stat_value9, stat_type10, stat_value10,
    ScalingStatDistribution, ScalingStatValue,
    dmg_min1, dmg_max1, dmg_type1, dmg_min2, dmg_max2, dmg_type2,
    armor, holy_res, fire_res, nature_res, frost_res, shadow_res, arcane_res,
    delay, ammo_type, RangedModRange,
    spellid_1, spelltrigger_1, spellcharges_1, spellppmRate_1, spellcooldown_1,
    spellcategory_1, spellcategorycooldown_1,
    spellid_2, spelltrigger_2, spellcharges_2, spellppmRate_2, spellcooldown_2,
    spellcategory_2, spellcategorycooldown_2,
    spellid_3, spelltrigger_3, spellcharges_3, spellppmRate_3, spellcooldown_3,
    spellcategory_3, spellcategorycooldown_3,
    spellid_4, spelltrigger_4, spellcharges_4, spellppmRate_4, spellcooldown_4,
    spellcategory_4, spellcategorycooldown_4,
    spellid_5, spelltrigger_5, spellcharges_5, spellppmRate_5, spellcooldown_5,
    spellcategory_5, spellcategorycooldown_5,
    bonding, description, PageText, LanguageID, PageMaterial,
    startquest, lockid, Material, sheath, RandomProperty, RandomSuffix,
    block, itemset, MaxDurability, area, Map, BagFamily, TotemCategory,
    socketColor_1, socketContent_1, socketColor_2, socketContent_2,
    socketColor_3, socketContent_3, socketBonus, GemProperties,
    RequiredDisenchantSkill, ArmorDamageModifier, duration, ItemLimitCategory,
    HolidayId, ScriptName, DisenchantID, FoodType, minMoneyLoot, maxMoneyLoot,
    flagsCustom
FROM `item_template` 
WHERE `entry` = 19019  -- Thunderfury (Legendary Sword)
ON DUPLICATE KEY UPDATE `entry` = `entry`;  -- Skip if already exists

-- Step 2: Update name and description
UPDATE `item_template` 
SET `name` = 'Progressive Blade of Power',
    `description` = 'A legendary blade enhanced by the Progressive Systems. This weapon grows stronger with your progression.'
WHERE `entry` = 99990;

-- Step 3: Optionally modify stats (make it stronger)
UPDATE `item_template` 
SET `dmg_min1` = `dmg_min1` * 1.2,  -- 20% more damage
    `dmg_max1` = `dmg_max1` * 1.2,
    `stat_value1` = `stat_value1` * 1.2,  -- 20% more stats
    `stat_value2` = `stat_value2` * 1.2,
    `stat_value3` = `stat_value3` * 1.2
WHERE `entry` = 99990;

-- Step 4: Register in template mapping table
INSERT INTO `custom_weapon_templates` (`custom_entry`, `template_entry`, `custom_name`, `custom_description`, `stat_modifier`)
VALUES (99990, 19019, 'Progressive Blade of Power', 'Enhanced version of Thunderfury', 1.2)
ON DUPLICATE KEY UPDATE `template_entry` = 19019;

-- ============================================================
-- VERIFICATION
-- ============================================================
SELECT 'Custom weapon created successfully!' AS result;
SELECT entry, name, class, subclass, displayid, Quality, ItemLevel, dmg_min1, dmg_max1 
FROM item_template WHERE entry = 99990;
SELECT * FROM custom_weapon_templates WHERE custom_entry = 99990;

-- ============================================================
-- HELPER QUERIES
-- ============================================================
-- Find popular weapons to use as templates:
-- SELECT entry, name, subclass, displayid, Quality, ItemLevel, dmg_min1, dmg_max1 
-- FROM item_template 
-- WHERE class = 2 AND Quality >= 4 AND RequiredLevel >= 70
-- ORDER BY Quality DESC, ItemLevel DESC LIMIT 20;

