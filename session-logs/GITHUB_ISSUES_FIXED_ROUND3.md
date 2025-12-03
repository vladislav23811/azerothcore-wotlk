# ✅ GitHub Issues Fixed - Round 3
## Additional Fixes Applied from Official AzerothCore Repository

---

## ✅ **FIX #5: #24004 - Dalaran Cooking Daily Quests - Can continue to loot items after gaining all you need** ✅

**File:** `src/server/game/Entities/Player/PlayerQuest.cpp:2293-2316`
**Issue:** Players could continue looting quest items after collecting enough items because the code only checked quest status count, not actual inventory count
**Root Cause:** `HasQuestForItem()` checked `q_status.ItemCount[j] < qinfo->RequiredItemCount[j]` but didn't verify the actual item count in inventory
**Fix:** Added check for `GetItemCount(itemid, true)` to ensure both quest status and inventory counts are below required amount
**Impact:** Players can no longer loot quest items after they have collected enough, fixing the Dalaran Cooking Daily Quests exploit

**Code Change:**
```cpp
// Before: Only checked quest status count
if (itemid == qinfo->RequiredItemId[j] && q_status.ItemCount[j] < qinfo->RequiredItemCount[j])

// After: Checks both quest status and actual inventory count
if (itemid == qinfo->RequiredItemId[j])
{
    uint32 currentItemCount = GetItemCount(itemid, true);
    if (q_status.ItemCount[j] < qinfo->RequiredItemCount[j] && currentItemCount < qinfo->RequiredItemCount[j])
    {
        // Allow looting
    }
    // Player already has enough items, don't allow looting
}
```

---

## 📋 **ISSUE #6: #23998 - Troll Patrol: The Alchemist's Apprentice uses racial identifier when it shouldn't** ⚠️

**Status:** Needs investigation
**Issue:** Quest incorrectly uses racial identifier when it shouldn't
**Location:** Quest race condition checks or quest conditions

**Analysis:**
- `SatisfyQuestRace()` function checks `AllowableRaces` from quest template
- The function itself looks correct - it checks if race mask matches
- This might be a database issue where the quest has incorrect `AllowableRaces` set
- Or it could be in quest conditions that incorrectly check race

**Action Required:**
- Check the specific Troll Patrol quest in database
- Verify `AllowableRaces` field in `quest_template`
- Check quest conditions for incorrect racial checks
- This might require a database fix rather than code fix

---

## 📊 **STATISTICS (Round 3)**

- **Issues Fixed:** 1 ✅
- **Files Modified:** 1
- **Functions Fixed:** 1
- **Issues Identified:** 1 (needs investigation)

---

## ✅ **TOTAL PROGRESS**

- **Critical Issues Fixed:** 5 ✅
- **Files Modified:** 4
- **Functions Fixed:** 8
- **Issues Remaining:** Multiple (need investigation)

---

## 🎯 **STATUS**

**Round 3 Fixes:** ✅ **COMPLETE (1/1)**
**Code Quality:** ✅ **IMPROVED**
**Bug Fixes:** ✅ **APPLIED**

**The codebase continues to improve with fixes from upstream!** 🎉

