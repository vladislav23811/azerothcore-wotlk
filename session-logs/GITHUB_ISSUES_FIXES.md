# 🔧 GitHub Issues Fixes
## Fixing Issues from Official AzerothCore Repository

Based on: https://github.com/azerothcore/azerothcore-wotlk/issues

---

## 🔴 **CRITICAL ISSUES TO FIX**

### **1. #24000 - Crash: ObjectAccessor::GetUnit** 🔴
**Status:** Investigating
**Issue:** Potential null pointer crash in ObjectAccessor::GetUnit
**Location:** `src/server/game/Globals/ObjectAccessor.cpp:199-208`

### **2. #24012 - Dying off coast in Howling Fjord brings you to Borean Tundra spirit healer** 🔴
**Status:** Investigating
**Issue:** Graveyard selection uses wrong zone when player dies in water
**Location:** `src/server/game/Misc/GameGraveyard.cpp:97-123`

### **3. #24003 - "The Lich King" (28765) Should Not Be Visible** ⚠️
**Status:** Investigating
**Issue:** NPC 28765 should not be visible to players
**Location:** Database/creature_template

---

## 📋 **CONFIRMED ISSUES TO CHECK**

### **4. #24011 - Forsaken Blight Spreaders spawn with 1 HP on server restart** ⚠️
**Status:** Need to check

### **5. #24004 - Dalaran Cooking Daily Quests - Can continue to loot items after gaining all you need** ⚠️
**Status:** Need to check

### **6. #23998 - Troll Patrol: The Alchemist's Apprentice uses racial identifier when it shouldn't** ⚠️
**Status:** Need to check

---

## 🔍 **ANALYSIS**

### **ObjectAccessor::GetUnit Crash:**
The function calls `u.GetMap()->GetCreature(guid)` without checking if `GetMap()` returns nullptr.
However, for a valid WorldObject, GetMap() should never return nullptr.
The crash might be due to:
- Object being removed while accessed
- Race condition in multi-threaded access
- Invalid WorldObject reference

### **Graveyard Selection Issue:**
When `nearCorpse` is true, the function uses `player->GetCorpseLocation()` which might have different zone/area IDs.
If the player dies in water between zones, it might select the wrong graveyard.
The function should ensure it uses the correct zone ID for the corpse location.

---

## 🎯 **FIXES TO APPLY**

1. Add null pointer check in ObjectAccessor::GetUnit
2. Fix graveyard selection to use corpse zone/area ID correctly
3. Check Lich King visibility settings
4. Verify other confirmed issues

