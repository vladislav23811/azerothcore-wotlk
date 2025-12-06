-- Check NPC Script Assignments in Database
-- Run this on the world database (w_world)

USE w_world;

-- Check if NPC entries exist and their script assignments
SELECT 
    entry,
    name,
    subname,
    ScriptName,
    npcflag,
    minlevel,
    maxlevel,
    faction
FROM creature_template
WHERE entry IN (190000, 190001, 190002, 190003, 190005, 190006)
ORDER BY entry;

-- Check if any NPCs are missing scripts
SELECT 
    entry,
    name,
    ScriptName,
    CASE 
        WHEN ScriptName IS NULL OR ScriptName = '' THEN 'MISSING SCRIPT'
        ELSE 'OK'
    END AS status
FROM creature_template
WHERE entry IN (190000, 190001, 190002, 190003, 190005, 190006);

