-- ============================================================
-- PROGRESSIVE SYSTEMS - DATABASE VERIFICATION SCRIPT
-- Run this to verify all tables, foreign keys, and NPCs are set up correctly
-- ============================================================

-- ============================================================
-- 1. CHECK CHARACTER DATABASE TABLES
-- ============================================================
USE w_characters;

SELECT '=== CHARACTER DATABASE TABLES ===' AS info;

SELECT 
    TABLE_NAME,
    TABLE_ROWS,
    CASE 
        WHEN TABLE_NAME IN (
            'character_progression_unified',
            'character_progression',
            'character_prestige',
            'item_upgrades',
            'character_stat_enhancements',
            'infinite_dungeon_progress',
            'daily_challenges',
            'character_challenge_progress'
        ) THEN '✓ REQUIRED'
        ELSE '? OPTIONAL'
    END AS status
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'w_characters'
  AND TABLE_NAME LIKE '%progressive%' 
     OR TABLE_NAME LIKE '%paragon%'
     OR TABLE_NAME LIKE '%upgrade%'
     OR TABLE_NAME LIKE '%challenge%'
     OR TABLE_NAME LIKE '%dungeon%'
ORDER BY TABLE_NAME;

-- ============================================================
-- 2. CHECK FOREIGN KEY CONSTRAINTS
-- ============================================================
SELECT '=== FOREIGN KEY CONSTRAINTS ===' AS info;

SELECT 
    CONSTRAINT_NAME,
    TABLE_NAME,
    REFERENCED_TABLE_NAME,
    CASE 
        WHEN REFERENCED_TABLE_NAME IS NOT NULL THEN '✓ VALID'
        ELSE '✗ INVALID'
    END AS status
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'w_characters'
  AND CONSTRAINT_NAME LIKE 'fk_%'
  AND TABLE_NAME LIKE '%progressive%' 
     OR TABLE_NAME LIKE '%paragon%'
     OR TABLE_NAME LIKE '%upgrade%'
ORDER BY TABLE_NAME, CONSTRAINT_NAME;

-- ============================================================
-- 3. CHECK WORLD DATABASE NPCs
-- ============================================================
USE w_world;

SELECT '=== NPC SETUP VERIFICATION ===' AS info;

SELECT 
    ct.entry,
    ct.name,
    ct.subname,
    ct.ScriptName,
    ct.npcflag,
    CASE 
        WHEN ct.entry = 190000 AND ct.ScriptName = 'npc_progressive_main_menu' THEN '✓ OK'
        WHEN ct.entry = 190001 AND ct.ScriptName = 'npc_item_upgrade' THEN '✓ OK'
        WHEN ct.entry = 190002 AND ct.ScriptName = 'npc_prestige' THEN '✓ OK'
        WHEN ct.entry = 190003 AND ct.ScriptName = 'npc_stat_enhancement' THEN '✓ OK'
        WHEN ct.entry = 190005 AND ct.ScriptName = 'npc_infinite_dungeon' THEN '✓ OK'
        WHEN ct.entry = 190006 AND ct.ScriptName = 'npc_progressive_items' THEN '✓ OK'
        WHEN ct.ScriptName IS NULL OR ct.ScriptName = '' THEN '✗ MISSING SCRIPT'
        ELSE '✗ WRONG SCRIPT'
    END AS script_status,
    CASE 
        WHEN ct.npcflag & 128 = 128 THEN '✓ VENDOR'
        ELSE '✗ NOT VENDOR'
    END AS vendor_status
FROM creature_template ct
WHERE ct.entry IN (190000, 190001, 190002, 190003, 190005, 190006)
ORDER BY ct.entry;

-- ============================================================
-- 4. CHECK VENDOR ITEMS
-- ============================================================
SELECT '=== VENDOR ITEMS ===' AS info;

SELECT 
    nv.entry,
    ct.name AS npc_name,
    nv.item,
    it.name AS item_name,
    nv.maxcount,
    nv.incrtime,
    CASE 
        WHEN it.entry IS NULL THEN '✗ ITEM NOT FOUND'
        ELSE '✓ OK'
    END AS item_status
FROM npc_vendor nv
LEFT JOIN creature_template ct ON nv.entry = ct.entry
LEFT JOIN item_template it ON nv.item = it.entry
WHERE nv.entry IN (190004, 190006)
ORDER BY nv.entry, nv.slot;

-- ============================================================
-- 5. CHECK WORLD DATABASE TABLES
-- ============================================================
SELECT '=== WORLD DATABASE TABLES ===' AS info;

SELECT 
    TABLE_NAME,
    TABLE_ROWS,
    CASE 
        WHEN TABLE_NAME IN (
            'custom_difficulty_scaling',
            'bloody_palace_waves',
            'bloody_palace_bosses'
        ) THEN '✓ REQUIRED'
        ELSE '? OPTIONAL'
    END AS status
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'w_world'
  AND (TABLE_NAME LIKE '%progressive%' 
       OR TABLE_NAME LIKE '%difficulty%'
       OR TABLE_NAME LIKE '%palace%'
       OR TABLE_NAME LIKE '%dungeon%')
ORDER BY TABLE_NAME;

-- ============================================================
-- SUMMARY
-- ============================================================
SELECT '=== VERIFICATION COMPLETE ===' AS info;
SELECT 'Review the results above to identify any issues.' AS note;

