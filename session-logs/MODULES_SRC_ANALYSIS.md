# modules/src Directory Analysis

**Date:** December 4, 2025  
**Directory:** `C:\servery\WOTLK-BOTS\azerothcore-wotlk\modules\src`

---

## 📊 WHAT IS IT?

The `modules/src` directory is a **build output directory** that contains:

1. **Generated Script Loader** (`server/scripts/gen_scriptloader/`)
   - Auto-generated `ScriptLoader.cpp` file
   - Created by CMake during build process
   - Contains function declarations for all module scripts

2. **Build Artifacts** (`genrev/x64/Release/`)
   - `revision.h` generation files
   - Visual Studio build artifacts (.tlog files)
   - Build state files

3. **Empty Directories** (structure for potential use)
   - `common/` - empty
   - `server/apps/` - empty
   - `server/database/` - empty
   - `server/game/` - empty
   - `server/shared/` - empty

---

## 🔍 HOW IT WORKS

### Module Source Path Resolution

From `src/cmake/macros/ConfigureModules.cmake`:
```cmake
function(GetPathToModuleSource module variable)
  GetModulesBasePath(MODULE_BASE_PATH)
  set(${variable} "${MODULE_BASE_PATH}/${module}/src" PARENT_SCOPE)
endfunction()
```

**Important:** This function looks for `modules/{module-name}/src`, NOT `modules/src/{module-name}`.

**Example:**
- Module: `mod-progressive-systems`
- Source path: `modules/mod-progressive-systems/src/` ✅
- NOT: `modules/src/mod-progressive-systems/` ❌

---

## 🗑️ IS IT BLOAT?

### Build Artifacts: YES ✅

**Should be deleted:**
- `genrev/x64/Release/` - Build artifacts (revision.h generation)
- All `.tlog` files
- All build state files

**Should be kept:**
- `server/scripts/gen_scriptloader/static/ScriptLoader.cpp` - Generated but needed for build

### Empty Directories: MAYBE ⚠️

The empty directories (`common/`, `server/apps/`, etc.) might be:
1. **Leftover structure** from old build system
2. **Placeholder** for future use
3. **Unused** and can be deleted

---

## ✅ RECOMMENDATION

### Safe to Delete:
```powershell
# Delete build artifacts
Remove-Item -Path "modules\src\genrev" -Recurse -Force

# Delete empty directories (if not used)
Remove-Item -Path "modules\src\common" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "modules\src\server\apps" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "modules\src\server\database" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "modules\src\server\game" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "modules\src\server\shared" -Force -ErrorAction SilentlyContinue
```

### Keep:
- `modules/src/server/scripts/gen_scriptloader/` - Generated but needed

---

## 📝 NOTES

- `modules/src` is **NOT** where module source code lives
- Module source code is in: `modules/{module-name}/src/`
- This directory is for **build system output** and **generated files**
- Most of it is **build bloat** that can be cleaned up

---

## 🎯 CONCLUSION

**Status:** Mostly build bloat ✅

**Action:** Can safely delete `genrev/` and empty directories. The `gen_scriptloader` directory will be regenerated on next build.

