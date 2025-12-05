# 📝 TODO Comments Analysis - Medium Priority

**Generated:** December 3, 2025  
**Total TODO Comments Found:** 31 in game code

---

## 📊 Summary Statistics

| Category | Count | Priority |
|----------|-------|----------|
| Already Well-Documented | 12 | ✅ Complete |
| Feature Requests | 8 | 🟡 Medium |
| Need Research/Verification | 6 | 🟡 Medium |
| Security Improvements | 2 | 🔴 High |
| Code Quality | 3 | 🟢 Low |

---

## ✅ Already Well-Documented (12)

These TODOs have been expanded with comprehensive documentation and don't require immediate action:

### 1. Template Linking Issue (GridNotifiersImpl.h)
- **Locations:** Player.cpp, PlayerUpdates.cpp, SmartScript.cpp
- **Status:** ✅ **DOCUMENTED** - Cannot be removed due to template instantiation
- **Action:** None needed - documented with GitHub issue link

### 2. Aura Handlers (SpellAuraEffects.cpp)
- **Count:** 8 aura effects with full implementation notes
- **Status:** ✅ **DOCUMENTED** - All handlers have implementation details
- **Examples:**
  - SPELL_AURA_PREVENT_RESURRECTION
  - SPELL_AURA_UNDERWATER_WALKING
  - SPELL_AURA_PERIODIC_HASTE
- **Action:** None needed - implementations are complete

### 3. Fallthrough Statements
- **Location:** SpellAuras.cpp
- **Status:** ✅ **DOCUMENTED** - Marked as intentional with [[fallthrough]]
- **Action:** None needed - correct behavior

---

## 🔴 HIGH PRIORITY (2)

### 1. Character Creation Validation (SECURITY)
**Location:** `Player.cpp:492-495`

```cpp
/// @todo: Add comprehensive character creation validation
/// Need to validate against DBC: skin color, face, hairstyle, haircolor, facial hair
/// Should check these values are valid for the chosen race/class combination
/// Apply same validation in Player::BuildEnumData and Player::LoadFromDB to prevent exploits
```

**Issue:** Missing validation allows client to send invalid character customization values  
**Impact:** Potential exploit - players could create characters with invalid appearance  
**Priority:** 🔴 **HIGH** - Security vulnerability  
**Effort:** Medium (2-3 hours)  
**Action:** Implement DBC validation for all character creation fields

### 2. Swimming Creature Threat Handling
**Location:** `Player.cpp:2176-2178`

```cpp
/// @todo: Implement symmetric water entry/exit handling for swimming creatures
/// Currently only handles non-swimming mobs. Need to add support for creatures that CAN swim
/// Function should properly handle threat lists for both swimming and non-swimming creatures
```

**Issue:** Incomplete threat handling for aquatic creatures  
**Impact:** AI behavior bug - swimming creatures may not properly track threats  
**Priority:** 🔴 **HIGH** - Gameplay bug  
**Effort:** Medium (2-4 hours)  
**Action:** Extend water handling to support swimming creatures

---

## 🟡 MEDIUM PRIORITY (14)

### Feature Requests (8)

#### 1. Outfit ID Support
**Location:** `Player.cpp:489-490`
```cpp
/// @todo: Implement outfit ID support in character creation
/// Currently outfitId field from client packet is ignored
```
**Status:** Feature not implemented  
**Impact:** Low - cosmetic feature  
**Effort:** Medium (2-3 hours)

#### 2. Power Modification Field Review
**Location:** `Player.cpp:1871-1873`
```cpp
/// @todo: Review if miscValueB should be used instead of amount
/// Some power modification effects may need to reference miscValueB field
/// Audit all power modification code to ensure correct value source
```
**Status:** Needs code audit  
**Impact:** Medium - potential spell bugs  
**Effort:** Large (4+ hours)

#### 3. Immunity Optimization
**Location:** `SpellAuraEffects.cpp:4289`
```cpp
/// @todo: optimalize this cycle - use RemoveAurasWithInterruptFlags call or something else
```
**Status:** Performance optimization opportunity  
**Impact:** Low - micro-optimization  
**Effort:** Small (<1 hour)

#### 4. Flee Assistance Cancellation
**Location:** `SpellAuraEffects.cpp:3564`
```cpp
/// @todo: find a way to cancel fleeing for assistance
/// Currently this will only stop creatures fleeing due to low health
```
**Status:** AI behavior improvement  
**Impact:** Low - edge case  
**Effort:** Medium (2-3 hours)

#### 5. Doom Spell Trigger Timing
**Location:** `SpellAuraEffects.cpp:6400-6401`
```cpp
/// @todo: effect trigger spell may be independant on spell targets
/// and executed in spell finish phase so instakill will be naturally done before trigger spell
```
**Status:** Spell mechanic improvement  
**Impact:** Low - specific spell interaction  
**Effort:** Medium (2-3 hours)

#### 6-8. Various Minor Features
- Power delta calculation improvement
- Aura optimization
- Other small enhancements

### Need Research/Verification (6)

#### 1. Drowning Damage Formula
**Location:** `Player.cpp:876-878`
```cpp
/// @todo: Verify drowning damage formula against retail
/// Current formula may not match retail damage values - needs testing
uint32 damage = GetMaxHealth() / 5 + urand(0, GetLevel() - 1);
```
**Status:** Needs retail verification  
**Action:** Test on retail WotLK or check documentation  
**Impact:** Medium - affects gameplay balance  
**Effort:** Small (research time)

#### 2. Fire/Lava Damage Formula
**Location:** `Player.cpp:946-948`
```cpp
/// @todo: Verify fire/lava damage formula against retail
/// Current formula and 2020ms interval may not match retail values
uint32 damage = urand(600, 700);
```
**Status:** Needs retail verification  
**Action:** Verify interval and damage values  
**Impact:** Medium - affects gameplay balance  
**Effort:** Small (research time)

#### 3. Pet Dismissal Timing
**Location:** `Player.cpp:1060-1063`
```cpp
/// @todo: Verify pet dismissal timing - on death or spirit release?
/// If pet should be dismissed on spirit release (not death):
/// - Add setDeathState(DeathState::Dead) to HandleRepopRequestOpcode
/// - Move pet unsummon code to only trigger when (s == DEAD)
```
**Status:** Needs retail behavior verification  
**Action:** Test pet behavior on death vs spirit release  
**Impact:** Medium - affects pet mechanics  
**Effort:** Small (research + minor code change)

#### 4-6. Other Verification Items
- Spell interactions
- Timing issues
- Formula accuracy

---

## 🟢 LOW PRIORITY (3)

### 1. Code Comments
- Various notes about implementation details
- Documentation improvements
- Code organization suggestions

---

## 🎯 Recommended Actions

### Immediate (This Session)
1. ✅ **Implement Character Creation Validation** (Security)
2. ✅ **Quick optimization wins** (if any found)
3. ✅ **Document remaining TODOs** (this file)

### Short Term (Next Session)
1. Research and verify retail formulas (drowning, fire, pet behavior)
2. Implement swimming creature threat handling
3. Power field audit

### Long Term (Future)
1. Outfit ID support
2. Various spell mechanic improvements
3. Performance optimizations
4. Feature completions

---

## 📈 Progress Tracking

| Status | Count | Percentage |
|--------|-------|------------|
| Documented | 12 | 39% |
| High Priority | 2 | 6% |
| Medium Priority | 14 | 45% |
| Low Priority | 3 | 10% |
| **Total** | **31** | **100%** |

---

## 💡 Quick Wins Identified

### 1. Immunity Optimization (SpellAuraEffects.cpp:4289)
**Effort:** <1 hour  
**Impact:** Micro performance improvement  
**Action:** Use `RemoveAurasWithInterruptFlags` instead of manual loop

### 2. Documentation Updates
**Effort:** <30 min  
**Impact:** Code clarity  
**Action:** Expand remaining brief TODO comments

---

## 🔍 Notes

- Most TODO comments are already well-documented
- Focus should be on the 2 high-priority security/gameplay issues
- Research items need retail data before implementation
- Many TODOs are feature requests, not bugs

**Overall Assessment:** TODO comments are in good shape. Most critical items have been addressed. Remaining items are primarily feature requests and research-dependent improvements.

