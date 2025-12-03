# Database Diagnostics Guide

## Overview
This guide helps you identify and fix common database issues using SQL diagnostic queries.

---

## 📋 **How to Use**

### Step 1: Run Diagnostic Queries
Execute the queries in `data/sql/custom/db_world/database_diagnostics.sql` to find issues:

```sql
-- Run all diagnostic queries
SOURCE data/sql/custom/db_world/database_diagnostics.sql;
```

### Step 2: Review Results
The queries will identify:
- Broken quest chain links
- Creatures with SmartAI but no scripts
- Missing quest items/creatures
- Loot template issues
- Quest relation problems

### Step 3: Fix Issues
For each issue found:
1. Note the specific IDs (Quest ID, Creature Entry, Item ID, etc.)
2. Research the correct values (check official databases, other sources)
3. Create SQL UPDATE/INSERT statements to fix the data
4. Test the fixes in-game

---

## 🔍 **Common Issues and Fixes**

### Issue 1: Broken Quest Chain
**Problem:** Quest A's `NextQuestInChain` points to Quest B, but Quest B doesn't exist or isn't offered by the same NPC.

**Fix:**
```sql
-- Option 1: Remove broken chain link
UPDATE quest_template SET NextQuestInChain = 0 WHERE Id = 12345;

-- Option 2: Fix chain link to correct quest
UPDATE quest_template SET NextQuestInChain = 54321 WHERE Id = 12345;

-- Option 3: Add missing quest relation
INSERT INTO creature_queststarter (id, quest) VALUES (67890, 54321);
```

### Issue 2: Creature with SmartAI but No Scripts
**Problem:** Creature uses SmartAI but has no entries in `smart_scripts` table.

**Fix:**
```sql
-- Option 1: Change AI to default
UPDATE creature_template SET AIName = '' WHERE entry = 12345;

-- Option 2: Add SmartAI script
INSERT INTO smart_scripts (entryorguid, source_type, id, link, event_type, event_phase_mask, event_chance, event_flags, ...)
VALUES (12345, 0, 0, 0, 0, 0, 100, 0, ...);
```

### Issue 3: Missing Quest Item
**Problem:** Quest requires an item that doesn't exist in `item_template`.

**Fix:**
```sql
-- Option 1: Remove item requirement
UPDATE quest_template SET StartItem = 0, StartItemCount = 0 WHERE Id = 12345;

-- Option 2: Add missing item (if you have item data)
INSERT INTO item_template (entry, name, displayid, ...) VALUES (54321, 'Missing Item', 12345, ...);
```

### Issue 4: Boss with No Loot
**Problem:** Boss or rare creature has no loot entries.

**Fix:**
```sql
-- Add loot template
INSERT INTO creature_loot_template (Entry, Item, Reference, Chance, QuestRequired, LootMode, GroupId, MinCount, MaxCount, Comment)
VALUES (12345, 54321, 0, 100, 0, 1, 0, 1, 1, 'Boss loot item');
```

---

## 📊 **Automated Fix Scripts**

### Fix All Broken Quest Chains
```sql
-- Remove all broken quest chain links
UPDATE quest_template q1
LEFT JOIN quest_template q2 ON q1.NextQuestInChain = q2.Id
SET q1.NextQuestInChain = 0
WHERE q1.NextQuestInChain > 0 AND q2.Id IS NULL;
```

### Fix Creatures with SmartAI but No Scripts
```sql
-- Change to default AI for creatures with SmartAI but no scripts
UPDATE creature_template ct
LEFT JOIN smart_scripts ss ON ct.entry = ss.entryorguid AND ss.source_type = 0
SET ct.AIName = ''
WHERE ct.AIName = 'SmartAI' AND ss.entryorguid IS NULL;
```

### Fix Quest Template Addon Issues
```sql
-- Remove addon entries for non-existent quests
DELETE FROM quest_template_addon
WHERE Id NOT IN (SELECT Id FROM quest_template);
```

---

## ⚠️ **Warnings**

1. **Backup First:** Always backup your database before running fix queries
2. **Test Changes:** Test fixes in-game before applying to production
3. **Research Values:** Don't guess - research correct values from official sources
4. **Incremental Fixes:** Fix issues one at a time and test each fix

---

## 📝 **Notes**

- Some "issues" may be intentional (e.g., quest chains that are meant to be broken)
- Always verify fixes match intended game behavior
- Use diagnostic queries regularly to catch issues early
- Document any manual fixes you make

---

## ✅ **Conclusion**

The diagnostic queries help identify database issues automatically. Once identified, you can:
1. Research the correct values
2. Create targeted SQL fixes
3. Test fixes in-game
4. Document changes

**Remember:** The code handles all these cases correctly - issues are data problems that need database fixes!

