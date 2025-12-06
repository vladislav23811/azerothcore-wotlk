-- ============================================================
-- CHECK AND FIX NPC SETUP
-- Run this on the WORLD database (w_world)
-- ============================================================

USE w_world;

-- ============================================================
-- 1. CHECK CURRENT NPC STATUS
-- ============================================================
SELECT 
    '=== CURRENT NPC STATUS ===' AS info;

SELECT 
    entry,
    name,
    subname,
    ScriptName,
    npcflag,
    minlevel,
    maxlevel,
    faction,
    CASE 
        WHEN entry = 190000 AND ScriptName = 'npc_progressive_main_menu' THEN '✓ CORRECT'
        WHEN entry = 190001 AND ScriptName = 'npc_item_upgrade' THEN '✓ CORRECT'
        WHEN entry = 190002 AND ScriptName = 'npc_prestige' THEN '✓ CORRECT'
        WHEN entry = 190003 AND ScriptName = 'npc_stat_enhancement' THEN '✓ CORRECT'
        WHEN entry = 190005 AND ScriptName = 'npc_infinite_dungeon' THEN '✓ CORRECT'
        WHEN entry = 190006 AND ScriptName = 'npc_progressive_items' THEN '✓ CORRECT'
        WHEN ScriptName IS NULL OR ScriptName = '' THEN '✗ MISSING SCRIPT'
        ELSE '✗ WRONG SCRIPT'
    END AS status
FROM creature_template
WHERE entry IN (190000, 190001, 190002, 190003, 190005, 190006)
ORDER BY entry;

-- ============================================================
-- 2. FIX NPC SCRIPT ASSIGNMENTS
-- ============================================================
SELECT 
    '=== FIXING NPC SCRIPTS ===' AS info;

-- Main Menu NPC (190000)
UPDATE creature_template 
SET ScriptName = 'npc_progressive_main_menu',
    name = 'Progressive Systems',
    subname = 'Main Menu',
    npcflag = 1,
    minlevel = 80,
    maxlevel = 80,
    faction = 35
WHERE entry = 190000;

-- Item Upgrade NPC (190001)
UPDATE creature_template 
SET ScriptName = 'npc_item_upgrade',
    name = 'Item Upgrade Master',
    subname = 'Upgrade Your Items',
    npcflag = 1,
    minlevel = 80,
    maxlevel = 80,
    faction = 35
WHERE entry = 190001;

-- Prestige NPC (190002)
UPDATE creature_template 
SET ScriptName = 'npc_prestige',
    name = 'Prestige Master',
    subname = 'Reset for Power',
    npcflag = 1,
    minlevel = 80,
    maxlevel = 80,
    faction = 35
WHERE entry = 190002;

-- Stat Enhancement NPC (190003)
UPDATE creature_template 
SET ScriptName = 'npc_stat_enhancement',
    name = 'Stat Enhancement',
    subname = 'Enhance Your Stats',
    npcflag = 1,
    minlevel = 80,
    maxlevel = 80,
    faction = 35
WHERE entry = 190003;

-- Infinite Dungeon NPC (190005)
UPDATE creature_template 
SET ScriptName = 'npc_infinite_dungeon',
    name = 'Infinite Dungeon',
    subname = 'Enter the Challenge',
    npcflag = 1,
    minlevel = 80,
    maxlevel = 80,
    faction = 35
WHERE entry = 190005;

-- Progressive Items NPC (190006)
UPDATE creature_template 
SET ScriptName = 'npc_progressive_items',
    name = 'Progressive Items',
    subname = 'Tiered Cosmetics',
    npcflag = 1,
    minlevel = 80,
    maxlevel = 80,
    faction = 35
WHERE entry = 190006;

-- ============================================================
-- 3. VERIFY FIXES
-- ============================================================
SELECT 
    '=== VERIFICATION ===' AS info;

SELECT 
    entry,
    name,
    subname,
    ScriptName,
    CASE 
        WHEN entry = 190000 AND ScriptName = 'npc_progressive_main_menu' AND name = 'Progressive Systems' THEN '✓ OK'
        WHEN entry = 190001 AND ScriptName = 'npc_item_upgrade' AND name = 'Item Upgrade Master' THEN '✓ OK'
        WHEN entry = 190002 AND ScriptName = 'npc_prestige' AND name = 'Prestige Master' THEN '✓ OK'
        WHEN entry = 190003 AND ScriptName = 'npc_stat_enhancement' AND name = 'Stat Enhancement' THEN '✓ OK'
        WHEN entry = 190005 AND ScriptName = 'npc_infinite_dungeon' AND name = 'Infinite Dungeon' THEN '✓ OK'
        WHEN entry = 190006 AND ScriptName = 'npc_progressive_items' AND name = 'Progressive Items' THEN '✓ OK'
        ELSE '✗ NEEDS FIX'
    END AS status
FROM creature_template
WHERE entry IN (190000, 190001, 190002, 190003, 190005, 190006)
ORDER BY entry;

