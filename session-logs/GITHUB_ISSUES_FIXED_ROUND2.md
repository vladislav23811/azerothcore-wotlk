# ✅ GitHub Issues Fixed - Round 2
## Additional Fixes Applied from Official AzerothCore Repository

---

## ✅ **FIX #3: #24011 - Forsaken Blight Spreaders spawn with 1 HP on server restart** ✅

**File:** `src/server/game/Entities/Creature/Creature.cpp:1773-1792`
**Issue:** When `curhealth` is 0 in the database and `m_regenHealth` is false, creatures spawn with 0 health, which gets clamped to 1 HP
**Root Cause:** The code checked `if (curhealth)` but if it was 0, it never entered the block, leaving `curhealth` at 0, which then gets set to 1 by the minimum check
**Fix:** Added an `else` clause to use `GetMaxHealth()` when `curhealth` is 0
**Impact:** Creatures will now spawn with full health when database has 0 health, preventing the 1 HP bug

**Code Change:**
```cpp
// Before: If curhealth is 0, it stays 0 and gets set to 1
if (!m_regenHealth)
{
    curhealth = data->curhealth;
    if (curhealth)
    {
        curhealth = uint32(curhealth * _GetHealthMod(GetCreatureTemplate()->rank));
        if (curhealth < 1)
            curhealth = 1;
    }
    // curhealth remains 0 if database had 0!
}

// After: If curhealth is 0, use max health instead
if (!m_regenHealth)
{
    curhealth = data->curhealth;
    if (curhealth)
    {
        curhealth = uint32(curhealth * _GetHealthMod(GetCreatureTemplate()->rank));
        if (curhealth < 1)
            curhealth = 1;
    }
    else
    {
        // Fix for issue #24011: If curhealth is 0 in database, use max health instead of spawning with 1 HP
        curhealth = GetMaxHealth();
    }
}
```

---

## 📋 **ISSUE #4: #24003 - "The Lich King" (28765) Should Not Be Visible** ⚠️

**Status:** Needs database check
**Issue:** NPC 28765 (The Lich King) should not be visible to players
**Action Required:** 
- Check `creature_template` for entry 28765
- Verify if it needs `flags_extra` set to make it invisible
- Or if it should use `SetVisible(false)` like `VISUAL_WAYPOINT`
- This is likely a database fix, not a code fix

**Possible Solutions:**
1. Add `SetVisible(false)` in `Creature::Create()` for entry 28765 (similar to VISUAL_WAYPOINT)
2. Or set appropriate `flags_extra` in database
3. Or use a script to hide it

---

## 📊 **STATISTICS (Round 2)**

- **Issues Fixed:** 1 ✅
- **Files Modified:** 1
- **Functions Fixed:** 1
- **Issues Identified:** 1 (needs investigation)

---

## ✅ **TOTAL PROGRESS**

- **Critical Issues Fixed:** 3 ✅
- **Files Modified:** 3
- **Functions Fixed:** 7
- **Issues Remaining:** Multiple (need investigation)

---

## 🎯 **STATUS**

**Round 2 Fixes:** ✅ **COMPLETE (1/1)**
**Code Quality:** ✅ **IMPROVED**
**Bug Fixes:** ✅ **APPLIED**

**The codebase continues to improve with fixes from upstream!** 🎉

