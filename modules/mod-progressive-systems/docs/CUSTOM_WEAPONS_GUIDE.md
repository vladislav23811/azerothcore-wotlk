# Custom Weapons Guide - No Client Patch Required!

## 🎯 Problem
Custom weapons are **much more complex** than currency items because they need:
- ✅ Weapon type (sword, axe, mace, etc.)
- ✅ 3D display models (not just icons!)
- ✅ Proper animations
- ✅ Spell associations
- ✅ Damage types
- ✅ Without DBC patches: **Question marks (???) everywhere!**

## ✅ Solution: Weapon Template System

We solve this by creating a **Weapon Template System** that maps custom weapon IDs to existing weapons. This way, custom weapons are actually **reskins** of existing weapons that already work!

### Strategy Options

## Option 1: Direct Reuse (Simplest) ⭐ RECOMMENDED

**Use existing weapon entries as templates** - Create "custom" weapons that are actually copies of existing weapons with new names/stats.

### How It Works:
1. Find a similar existing weapon (e.g., "Frostmourne" or "Thunderfury")
2. Copy ALL its properties (displayid, subclass, material, etc.)
3. Change only: `entry`, `name`, `description`, and stats
4. Result: Works perfectly, looks like the original weapon!

### Example:
```sql
-- Custom weapon based on existing weapon (entry 19019 = Thunderfury)
INSERT INTO `item_template` (
    `entry`, `class`, `subclass`, `name`, `displayid`, `Quality`, `Flags`,
    `BuyPrice`, `SellPrice`, `InventoryType`, `AllowableClass`, `AllowableRace`,
    `ItemLevel`, `RequiredLevel`, `RequiredSkill`, `RequiredSkillRank`,
    `maxcount`, `stackable`, `Material`, `sheath`, `delay`,
    `dmg_min1`, `dmg_max1`, `dmg_type1`, `dmg_min2`, `dmg_max2`, `dmg_type2`,
    `dmg_min3`, `dmg_max3`, `dmg_type3`, `dmg_min4`, `dmg_max4`, `dmg_type4`,
    `dmg_min5`, `dmg_max5`, `dmg_type5`,
    `armor`, `holy_res`, `fire_res`, `nature_res`, `frost_res`, `shadow_res`, `arcane_res`,
    `spellid_1`, `spelltrigger_1`, `spellcharges_1`, `spellppmRate_1`, `spellcooldown_1`,
    `spellcategory_1`, `spellcategorycooldown_1`,
    `spellid_2`, `spelltrigger_2`, `spellcharges_2`, `spellppmRate_2`, `spellcooldown_2`,
    `spellcategory_2`, `spellcategorycooldown_2`,
    -- ... copy ALL fields from existing weapon
    `description`
) 
SELECT 
    99990,  -- New custom entry
    2,      -- Class: Weapon
    subclass, displayid, Quality, Flags,
    BuyPrice, SellPrice, InventoryType, AllowableClass, AllowableRace,
    ItemLevel, RequiredLevel, RequiredSkill, RequiredSkillRank,
    maxcount, stackable, Material, sheath, delay,
    dmg_min1, dmg_max1, dmg_type1, dmg_min2, dmg_max2, dmg_type2,
    dmg_min3, dmg_max3, dmg_type3, dmg_min4, dmg_max4, dmg_type4,
    dmg_min5, dmg_max5, dmg_type5,
    armor, holy_res, fire_res, nature_res, frost_res, shadow_res, arcane_res,
    spellid_1, spelltrigger_1, spellcharges_1, spellppmRate_1, spellcooldown_1,
    spellcategory_1, spellcategorycooldown_1,
    spellid_2, spelltrigger_2, spellcharges_2, spellppmRate_2, spellcooldown_2,
    spellcategory_2, spellcategorycooldown_2,
    -- ... copy ALL other fields
    'Custom weapon based on Thunderfury'
FROM `item_template` 
WHERE `entry` = 19019;  -- Thunderfury (or any existing weapon)
```

## Option 2: Weapon Template Mapping System

Create a **mapping table** that links custom weapon IDs to existing weapon templates.

### Database Structure:
```sql
CREATE TABLE IF NOT EXISTS `custom_weapon_templates` (
    `custom_entry` INT UNSIGNED NOT NULL PRIMARY KEY COMMENT 'Custom weapon entry ID',
    `template_entry` INT UNSIGNED NOT NULL COMMENT 'Existing weapon to use as template',
    `custom_name` VARCHAR(255) NOT NULL COMMENT 'Custom weapon name',
    `custom_description` TEXT COMMENT 'Custom weapon description',
    `stat_modifier` FLOAT DEFAULT 1.0 COMMENT 'Stat multiplier (1.0 = same, 1.5 = 50% stronger)',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_template` (`template_entry`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Maps custom weapons to existing weapon templates';
```

### C++ Implementation:
- Server-side: When player equips custom weapon, server uses template weapon's display/model
- Client sees: Template weapon appearance
- Server tracks: Custom weapon stats/name

## Option 3: Progressive Weapon System (Recommended for Your Module!)

Since you have a **Progressive Systems** module, create a system that **upgrades existing weapons** instead of creating new ones!

### How It Works:
1. Player uses existing weapon (e.g., "Frostmourne")
2. System tracks upgrade level in database
3. Server applies stat bonuses based on upgrade level
4. Weapon name changes: "Frostmourne +1", "Frostmourne +2", etc.
5. **No new items needed!** Uses existing weapons with enhanced stats!

### Benefits:
- ✅ No custom items needed
- ✅ Works with any existing weapon
- ✅ No DBC patches required
- ✅ Players see familiar weapons
- ✅ Stats scale with progression

## 📋 Implementation Guide

### Step 1: Find Template Weapons

```sql
-- Find popular epic/legendary weapons to use as templates
SELECT entry, name, subclass, displayid, Quality, ItemLevel, 
       dmg_min1, dmg_max1, InventoryType
FROM item_template 
WHERE class = 2 
  AND Quality >= 4  -- Epic or Legendary
  AND RequiredLevel >= 70
ORDER BY Quality DESC, ItemLevel DESC
LIMIT 20;
```

### Step 2: Weapon Subclass Reference

| Subclass | Type | Description |
|----------|------|-------------|
| 0 | One-Handed Axe | |
| 1 | Two-Handed Axe | |
| 2 | Bow | |
| 3 | Gun | |
| 4 | One-Handed Mace | |
| 5 | Two-Handed Mace | |
| 6 | Polearm | |
| 7 | One-Handed Sword | |
| 8 | Two-Handed Sword | |
| 9 | Warglaive | |
| 10 | Staff | |
| 13 | Fist Weapon | |
| 15 | Dagger | |
| 16 | Thrown | |
| 18 | Crossbow | |
| 19 | Wand | |

### Step 3: Create Custom Weapon (Option 1 - Direct Copy)

```sql
-- Example: Create custom sword based on existing sword
-- This copies ALL properties from entry 19019 (Thunderfury)
INSERT INTO `item_template` 
SELECT 
    99990,  -- New custom entry
    class, subclass, name, displayid, Quality, Flags,
    BuyPrice, SellPrice, InventoryType, AllowableClass, AllowableRace,
    ItemLevel, RequiredLevel, RequiredSkill, RequiredSkillRank,
    maxcount, stackable, Material, sheath, delay,
    dmg_min1, dmg_max1, dmg_type1, dmg_min2, dmg_max2, dmg_type2,
    dmg_min3, dmg_max3, dmg_type3, dmg_min4, dmg_max4, dmg_type4,
    dmg_min5, dmg_max5, dmg_type5,
    armor, holy_res, fire_res, nature_res, frost_res, shadow_res, arcane_res,
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
    bonding, description, PageText, LanguageID, PageMaterial, startquest, lockid,
    Material, sheath, RandomProperty, RandomSuffix, block, itemset, MaxDurability,
    area, Map, BagFamily, TotemCategory, socketColor_1, socketContent_1,
    socketColor_2, socketContent_2, socketColor_3, socketContent_3,
    socketBonus, GemProperties, RequiredDisenchantSkill, ArmorDamageModifier,
    duration, ItemLimitCategory, HolidayId, ScriptName, DisenchantID, FoodType,
    minMoneyLoot, maxMoneyLoot, flagsCustom
FROM `item_template` 
WHERE `entry` = 19019;  -- Template weapon

-- Update name and description
UPDATE `item_template` 
SET `name` = 'Custom Progressive Sword',
    `description` = 'A powerful sword enhanced by the Progressive Systems.'
WHERE `entry` = 99990;
```

## 🎯 Recommended Approach for Progressive Systems

**Use Option 3: Progressive Weapon Upgrade System**

This fits perfectly with your module:
1. Players use existing weapons
2. System tracks upgrade levels
3. Stats scale with progression
4. No custom items needed
5. Works for everyone!

### Implementation:
- Already partially implemented in `ItemUpgradeSystem`
- Extend it to modify weapon names: "Weapon Name +5"
- Apply stat bonuses server-side
- No client changes needed!

## ⚠️ Limitations

### What You CAN'T Do Without DBC Patches:
- ❌ Create completely new weapon models
- ❌ Create new weapon types
- ❌ Create new animations
- ❌ Create new spell effects (visuals)
- ❌ Create new weapon sounds

### What You CAN Do:
- ✅ Reskin existing weapons (new name, same look)
- ✅ Modify stats (damage, stats, etc.)
- ✅ Modify spell effects (damage, procs)
- ✅ Use existing weapon models
- ✅ Upgrade existing weapons

## 📝 Summary

**For Custom Weapons:**
1. **Best**: Use existing weapons as templates (copy all properties)
2. **Better**: Create weapon upgrade system (enhance existing weapons)
3. **Good**: Create mapping system (link custom IDs to templates)

**Key Insight**: Reuse existing weapon display IDs and models - they already work!

## 🚀 Quick Start

1. Find a weapon you like: `SELECT * FROM item_template WHERE entry = 19019;`
2. Copy it: Use the SQL template above
3. Modify: Change `entry`, `name`, `description`, and stats
4. Done: Works immediately for all players!

No DBC patches needed! 🎉

