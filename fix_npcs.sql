-- Fix NPC Script Assignments
-- Run this on the world database (w_world)

USE w_world;

-- Assign scripts to NPC entries (safe - only updates if entry exists)
UPDATE creature_template SET ScriptName = 'npc_progressive_main_menu' WHERE entry = 190000;
UPDATE creature_template SET ScriptName = 'npc_item_upgrade' WHERE entry = 190001;
UPDATE creature_template SET ScriptName = 'npc_prestige' WHERE entry = 190002;
UPDATE creature_template SET ScriptName = 'npc_stat_enhancement' WHERE entry = 190003;
UPDATE creature_template SET ScriptName = 'npc_infinite_dungeon' WHERE entry = 190005;
UPDATE creature_template SET ScriptName = 'npc_progressive_items' WHERE entry = 190006;

-- Verify the updates
SELECT 
    entry,
    name,
    ScriptName,
    CASE 
        WHEN ScriptName IS NULL OR ScriptName = '' THEN 'MISSING'
        WHEN entry = 190000 AND ScriptName = 'npc_progressive_main_menu' THEN 'OK'
        WHEN entry = 190001 AND ScriptName = 'npc_item_upgrade' THEN 'OK'
        WHEN entry = 190002 AND ScriptName = 'npc_prestige' THEN 'OK'
        WHEN entry = 190003 AND ScriptName = 'npc_stat_enhancement' THEN 'OK'
        WHEN entry = 190005 AND ScriptName = 'npc_infinite_dungeon' THEN 'OK'
        WHEN entry = 190006 AND ScriptName = 'npc_progressive_items' THEN 'OK'
        ELSE 'WRONG SCRIPT'
    END AS status
FROM creature_template
WHERE entry IN (190000, 190001, 190002, 190003, 190005, 190006)
ORDER BY entry;

