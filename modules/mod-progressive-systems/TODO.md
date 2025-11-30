# Progressive Systems Module - TODO / What's Not Done

## 🔴 Critical - Core Functionality Missing

### 1. Item Upgrade System - **INCOMPLETE**
**Status:** Partially implemented, needs C++ integration

**Issues:**
- ❌ Lua script can't get upgrade level from database/C++
- ❌ Lua script can't actually upgrade items (just deducts points)
- ❌ Need to expose C++ `GetItemUpgradeLevel()` and `UpgradeItem()` to Lua
- ❌ Item stat bonuses not applied (need hook in stat calculation)

**Files:**
- `lua_scripts/item_upgrade_npc.lua` - Lines 36, 89, 110 have TODOs
- `src/ProgressiveSystems.cpp` - Functions exist but not exposed to Lua

**Fix Needed:**
- Create Eluna bindings for item upgrade functions
- OR: Use database queries directly in Lua
- Add stat bonus application hook

---

### 2. Infinite Dungeon NPC - **MISSING**
**Status:** C++ functions exist, but no NPC/Lua script

**Missing:**
- ❌ No `infinite_dungeon_npc.lua` script
- ❌ No NPC interaction system
- ❌ No floor selection UI
- ❌ No wave spawning logic
- ❌ No rewards system

**Files:**
- `src/ProgressiveSystems.cpp` - Functions exist (GetCurrentFloor, AdvanceFloor, etc.)
- `lua_scripts/main_menu_npc.lua` - Line 78 has TODO

**Fix Needed:**
- Create `lua_scripts/infinite_dungeon_npc.lua`
- Implement floor selection
- Implement wave spawning (can use your old `icc_wave_logic.lua` as reference)
- Implement rewards (can use your old `icc_rewards.lua` as reference)

---

### 3. Damage Scaling - **INCOMPLETE**
**Status:** Only health scales, damage doesn't

**Issues:**
- ❌ Damage multiplier calculated but not applied
- ❌ Need combat calculation hook
- ❌ Currently only `SetMaxHealth()` is called

**Files:**
- `src/DifficultyScaling.cpp` - Lines 53-55 have comment about missing damage scaling

**Fix Needed:**
- Hook into `Unit::DealDamage()` or `Unit::CalculateDamage()`
- Apply damage multiplier in combat calculations
- OR: Use aura system to apply damage bonus

---

## 🟡 Medium Priority - Missing Features

### 4. Progressive Items NPC - **MISSING**
**Status:** Referenced but not implemented

**Missing:**
- ❌ No `progressive_items_npc.lua` script
- ❌ No vendor for tiered shirts/tabards
- ❌ No tier progression system

**Files:**
- `lua_scripts/main_menu_npc.lua` - Line 82 has TODO
- Your old `progressive_items.lua` exists as reference

**Fix Needed:**
- Create `lua_scripts/progressive_items_npc.lua`
- Implement vendor with tiered items
- Track shirt_tier and tabard_tier in database

---

### 5. Main Menu NPC Links - **INCOMPLETE**
**Status:** Placeholder messages, don't actually open NPCs

**Issues:**
- ❌ Menu items show messages but don't open other NPCs
- ❌ Should either open NPCs directly or implement inline menus

**Files:**
- `lua_scripts/main_menu_npc.lua` - Lines 52, 56, 78, 82 have TODOs

**Fix Needed:**
- Either spawn/teleport to other NPCs
- OR: Implement inline sub-menus
- OR: Use gossip menu system to chain menus

---

### 6. Reward Shop Database Update - **MINOR**
**Status:** Works but uses direct SQL instead of C++ function

**Issues:**
- ⚠️ Uses `CharDBExecute` directly instead of C++ function
- ⚠️ Should use `ProgressiveCore.SpendProgressionPoints()` if available

**Files:**
- `lua_scripts/reward_shop_npc.lua` - Line 135 has TODO

**Fix Needed:**
- Use `ProgressiveCore.SpendProgressionPoints()` function
- OR: Keep direct SQL if it works fine

---

## 🟢 Low Priority - Nice to Have

### 7. Prestige NPC - **BASIC IMPLEMENTATION**
**Status:** Basic info display, but no actual prestige action

**Missing:**
- ⚠️ Shows prestige info but can't actually prestige
- ⚠️ No confirmation dialog
- ⚠️ No prestige requirements check

**Fix Needed:**
- Add prestige confirmation
- Add requirements check (level 80, etc.)
- Call C++ `PrestigeCharacter()` function

---

### 8. Stat Enhancement System - **C++ ONLY**
**Status:** C++ functions exist, but no NPC/Lua interface

**Missing:**
- ⚠️ No NPC to enhance stats
- ⚠️ No UI for stat enhancement

**Fix Needed:**
- Create stat enhancement NPC
- Add UI for selecting which stat to enhance
- Show costs and bonuses

---

## 📋 Summary

### Must Fix (Core Functionality):
1. ✅ Item Upgrade - Connect Lua to C++ functions
2. ✅ Infinite Dungeon - Create NPC script
3. ✅ Damage Scaling - Add combat hook

### Should Fix (Features):
4. Progressive Items NPC
5. Main Menu NPC links
6. Reward Shop C++ integration

### Nice to Have:
7. Prestige NPC full implementation
8. Stat Enhancement NPC

---

## Quick Wins (Easy Fixes):

1. **Item Upgrade** - Can use database queries directly in Lua instead of C++:
   ```lua
   local q = CharDBQuery(string.format("SELECT upgrade_level FROM item_upgrades WHERE item_guid = %d", itemGuid))
   ```

2. **Main Menu Links** - Can use gossip menu chaining instead of separate NPCs

3. **Reward Shop** - Already works, just needs to use ProgressiveCore function if available

---

## Estimated Time:
- **Critical fixes:** 2-3 hours
- **Medium priority:** 1-2 hours  
- **Low priority:** 1 hour

**Total:** ~4-6 hours to complete everything

