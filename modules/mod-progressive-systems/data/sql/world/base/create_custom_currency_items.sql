-- ============================================================
-- CREATE CUSTOM CURRENCY ITEMS
-- Creates custom currency items for Progressive Systems
-- These items are referenced in the config and used as currency
-- ============================================================

USE w_world;

-- ============================================================
-- CUSTOM CURRENCY ITEMS
-- ============================================================
-- Based on Emblem of Frost (49426) structure
-- Class 10 = Currency (Miscellaneous)
-- Subclass 0 = Junk
-- Quality 4 = Epic (purple)
-- Flags 2048 = Currency Token
-- Stackable = 2147483647 (unlimited stacking)

-- Progression Token (99997)
INSERT INTO `item_template` (
    `entry`, `class`, `subclass`, `name`, `displayid`, `Quality`, `Flags`, 
    `BuyPrice`, `SellPrice`, `stackable`, `InventoryType`, `ItemLevel`, 
    `RequiredLevel`, `maxcount`, `AllowableClass`, `AllowableRace`, `description`
) VALUES (
    99997, 10, 0, 'Progression Token', 64062, 4, 2048,
    0, 0, 2147483647, 0, 80, 80, 0, -1, -1, 
    'Currency used in the Progressive Systems reward shop.'
) ON DUPLICATE KEY UPDATE 
    `name` = 'Progression Token',
    `description` = 'Currency used in the Progressive Systems reward shop.';

-- Celestial Token (99998)
INSERT INTO `item_template` (
    `entry`, `class`, `subclass`, `name`, `displayid`, `Quality`, `Flags`, 
    `BuyPrice`, `SellPrice`, `stackable`, `InventoryType`, `ItemLevel`, 
    `RequiredLevel`, `maxcount`, `AllowableClass`, `AllowableRace`, `description`
) VALUES (
    99998, 10, 0, 'Celestial Token', 64062, 4, 2048,
    0, 0, 2147483647, 0, 80, 80, 0, -1, -1, 
    'Rare celestial currency for purchasing premium rewards.'
) ON DUPLICATE KEY UPDATE 
    `name` = 'Celestial Token',
    `description` = 'Rare celestial currency for purchasing premium rewards.';

-- Bloody Token (99999)
INSERT INTO `item_template` (
    `entry`, `class`, `subclass`, `name`, `displayid`, `Quality`, `Flags`, 
    `BuyPrice`, `SellPrice`, `stackable`, `InventoryType`, `ItemLevel`, 
    `RequiredLevel`, `maxcount`, `AllowableClass`, `AllowableRace`, `description`
) VALUES (
    99999, 10, 0, 'Bloody Token', 64062, 4, 2048,
    0, 0, 2147483647, 0, 80, 80, 0, -1, -1, 
    'Blood-soaked currency earned from the Bloody Palace challenges.'
) ON DUPLICATE KEY UPDATE 
    `name` = 'Bloody Token',
    `description` = 'Blood-soaked currency earned from the Bloody Palace challenges.';

-- ============================================================
-- UPDATE VENDOR ITEMS
-- ============================================================
-- Now that items exist, update vendor to use them
-- Use INSERT IGNORE to avoid duplicate key errors if items already exist
INSERT IGNORE INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`) VALUES
(190004, 0, 49426, 0, 0, 0),  -- Emblem of Frost
(190004, 1, 99997, 0, 0, 0),  -- Progression Token
(190004, 2, 99998, 0, 0, 0),  -- Celestial Token
(190004, 3, 99999, 0, 0, 0);  -- Bloody Token

-- ============================================================
-- VERIFICATION
-- ============================================================
SELECT 'Custom currency items created successfully!' AS result;
SELECT entry, name, class, Quality, stackable FROM item_template WHERE entry IN (99997, 99998, 99999);

