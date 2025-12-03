# 🔍 GitHub Issues Round 3 - Analysis
## Investigating Additional Issues

---

## 📋 **ISSUES TO INVESTIGATE**

### **#24004 - Dalaran Cooking Daily Quests - Can continue to loot items after gaining all you need** ⚠️
**Status:** Investigating
**Issue:** Players can continue looting quest items after completing quest requirements
**Location:** Quest item looting logic

**Analysis:**
- `HasQuestForItem()` checks if player has a quest that needs the item
- `GetQuestItemCount()` tracks how many items the player has
- `RequiredItemCount` is the quest requirement
- Need to check if looting is prevented when `ItemCount >= RequiredItemCount`

**Code Location:**
- `src/server/game/Entities/Player/PlayerQuest.cpp:HasQuestForItem()`
- `src/server/game/Loot/LootMgr.cpp:FillLoot()`
- `src/server/game/Entities/Player/Player.cpp:StoreLootItem()`

---

### **#23998 - Troll Patrol: The Alchemist's Apprentice uses racial identifier when it shouldn't** ⚠️
**Status:** Investigating
**Issue:** Quest incorrectly uses racial identifier when it shouldn't
**Location:** Quest race condition checks

**Analysis:**
- `SatisfyQuestRace()` checks if player's race matches quest requirements
- `AllowableRaces` is the quest's race requirement
- Need to find where racial identifier is incorrectly used

**Code Location:**
- `src/server/game/Entities/Player/PlayerQuest.cpp:SatisfyQuestRace()`
- `src/server/game/Quests/QuestDef.cpp:AllowableRaces`

---

## 🔍 **FINDINGS**

### **Quest Item Looting:**
The `HasQuestForItem()` function checks:
1. If player has an active quest that needs the item
2. If the item count is less than required
3. But it might not check if the quest is already complete

**Potential Fix:**
- Check `GetQuestStatus() == QUEST_STATUS_COMPLETE` before allowing loot
- Or check `ItemCount >= RequiredItemCount` more strictly

### **Racial Identifier:**
The `SatisfyQuestRace()` function checks:
1. If `AllowableRaces` is 0 (all races allowed)
2. If player's race matches the allowable races
3. But might be incorrectly applied in some quest conditions

**Potential Fix:**
- Check if the quest should ignore race requirements
- Verify quest flags for race restrictions

---

## 📝 **NEXT STEPS**

1. Read `HasQuestForItem()` implementation fully
2. Check quest completion status in loot logic
3. Find the specific Troll Patrol quest
4. Check racial identifier usage in quest conditions

