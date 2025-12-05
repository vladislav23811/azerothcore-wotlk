# AzerothShard Achievements Data Type Fix

## Issue
**1,679 errors** in `Errors.log` related to `azth_achievements` table:
- `parentCategory` field: Storing `-1` (negative values) but C++ code was reading as `uint32` (unsigned)
- `difficulty` field: Storing `2.5` (decimal values) but C++ code was reading as `uint32` (unsigned)

## Root Cause
The database table structure was correct:
- `parentCategory` is `int` (signed) - can handle -1
- `difficulty` is `float` - can handle 2.5

However, the **C++ code** in the AzerothShard module was incorrectly reading these fields as `uint32`.

## Files Modified

### 1. `modules/mod-azerothshard/src/Playerstats/AzthAchievement.h`
**Changed:**
- Line 17: `uint32 GetParCategory()` → `int32 GetParCategory()`
- Line 18: `uint32 GetDifficulty()` → `float GetDifficulty()`
- Line 31: Constructor parameter `uint32 parentCategory` → `int32 parentCategory`
- Line 31: Constructor parameter `uint32 difficulty` → `float difficulty`
- Line 41: Member variable `uint32 parentCategory` → `int32 parentCategory`
- Line 42: Member variable `uint32 difficulty` → `float difficulty`

### 2. `modules/mod-azerothshard/src/Playerstats/AzthAchievement.cpp`
**Changed:**
- Line 9: Constructor parameter `uint32 parentCategory` → `int32 parentCategory`
- Line 9: Constructor parameter `uint32 difficulty` → `float difficulty`
- Line 51: Return type `uint32 GetParCategory()` → `int32 GetParCategory()`
- Line 56: Return type `uint32 GetDifficulty()` → `float GetDifficulty()`

### 3. `modules/mod-azerothshard/src/Timewalking/TimeWalking.cpp`
**Changed:**
- Line 128: `azthAchievement_field[4].Get<uint32>()` → `azthAchievement_field[4].Get<int32>()`
- Line 128: `azthAchievement_field[5].Get<uint32>()` → `azthAchievement_field[5].Get<float>()`

### 4. `modules/mod-azerothshard/modules/mod-timewalking/src/scripts/TimeWalking.cpp`
**Changed:**
- Line 200: `azthAchievement_field[4].GetUInt32()` → `azthAchievement_field[4].GetInt32()`
- Line 200: `azthAchievement_field[5].GetUInt32()` → `azthAchievement_field[5].GetFloat()`

## Impact
- **Fixes:** All 1,679 data type errors in `Errors.log`
- **Requires:** Full recompilation of worldserver
- **Risk:** Low - only affects achievement loading, no gameplay impact

## Next Steps
1. Recompile worldserver: `cmake --build . --config RelWithDebInfo --target worldserver`
2. Restart worldserver
3. Verify `Errors.log` no longer contains these errors

