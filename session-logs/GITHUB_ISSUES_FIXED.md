# ✅ GitHub Issues Fixed
## Fixes Applied from Official AzerothCore Repository

Based on: https://github.com/azerothcore/azerothcore-wotlk/issues

---

## ✅ **FIXES APPLIED**

### **1. #24012 - Dying off coast in Howling Fjord brings you to Borean Tundra spirit healer** ✅
**File:** `src/server/game/Misc/GameGraveyard.cpp`
**Issue:** When `nearCorpse` is true, the function used corpse coordinates but player's current zone/area ID
**Fix:** Now gets zone/area ID from corpse location coordinates using `Map::GetZoneAndAreaId()`
**Status:** ✅ **FIXED**

**Before:**
```cpp
if (nearCorpse)
    loc = player->GetCorpseLocation();
// ... but then uses player->GetZoneAndAreaId() which gets current location
```

**After:**
```cpp
if (nearCorpse)
{
    loc = player->GetCorpseLocation();
    // Get zone/area from corpse location, not player's current location
    Map const* map = sMapMgr->FindMap(mapId, 0);
    if (map)
        map->GetZoneAndAreaId(PHASEMASK_NORMAL, zoneId, areaId, x, y, z);
}
```

---

### **2. #24000 - Crash: ObjectAccessor::GetUnit** ✅
**File:** `src/server/game/Globals/ObjectAccessor.cpp`
**Issue:** Potential null pointer crash if `GetMap()` returns nullptr
**Fix:** Added null checks for `GetMap()` in all ObjectAccessor functions
**Status:** ✅ **FIXED**

**Functions Fixed:**
- `GetCreature()` - Added null check
- `GetCorpse()` - Added null check
- `GetGameObject()` - Added null check
- `GetTransport()` - Added null check
- `GetDynamicObject()` - Added null check
- `GetPet()` - Added null check

**Before:**
```cpp
Creature* ObjectAccessor::GetCreature(WorldObject const& u, ObjectGuid const& guid)
{
    return u.GetMap()->GetCreature(guid);  // Could crash if GetMap() is nullptr
}
```

**After:**
```cpp
Creature* ObjectAccessor::GetCreature(WorldObject const& u, ObjectGuid const& guid)
{
    Map const* map = u.GetMap();
    if (!map)
        return nullptr;
    return map->GetCreature(guid);
}
```

---

## 📋 **ISSUES TO CHECK**

### **3. #24003 - "The Lich King" (28765) Should Not Be Visible** ⚠️
**Status:** Need to check database/creature_template
**Action:** Verify creature_template flags_extra or visibility settings

### **4. #24011 - Forsaken Blight Spreaders spawn with 1 HP on server restart** ⚠️
**Status:** Need to check creature spawn/respawn code
**Action:** Verify creature health initialization

### **5. #24004 - Dalaran Cooking Daily Quests** ⚠️
**Status:** Need to check quest loot system
**Action:** Verify quest item loot restrictions

---

## 📊 **STATISTICS**

- **Critical Issues Fixed:** 2 ✅
- **Files Modified:** 2
- **Functions Fixed:** 6
- **Issues Remaining:** 3 (need investigation)

---

## ✅ **STATUS**

**Critical Fixes:** ✅ **COMPLETE**
**Code Quality:** ✅ **IMPROVED**
**Crash Prevention:** ✅ **ENHANCED**

**The codebase is now more stable and fixes critical issues from upstream!** 🎉

