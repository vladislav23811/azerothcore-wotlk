# 🔧 GitHub Actions Build Fix
## Fixed Linking Issue for CI

---

## ❌ **PROBLEM**

The GitHub Actions build was failing because `mod-progressive-systems/CMakeLists.txt` was creating its own static library (`progressive-systems.lib`), but the module system already collects static module sources into the main `modules` library.

This caused:
- **Duplicate symbols** - Sources compiled twice (once in `progressive-systems.lib`, once in `modules.lib`)
- **Linking conflicts** - Multiple definitions of the same symbols
- **Build failures** in CI environment

---

## ✅ **SOLUTION**

For **static modules** in AzerothCore:
- ❌ **DON'T** create your own library with `add_library()`
- ✅ **DO** let the module system collect sources automatically
- ✅ **DO** only set compile options, include directories, etc.

The module system (`modules/CMakeLists.txt`) automatically:
1. Collects source files via `CollectSourceFiles()`
2. Collects include directories via `CollectIncludeDirectories()`
3. Adds everything to the main `modules` static library

---

## 📝 **CHANGES MADE**

**Before:**
```cmake
add_library(${MODULE_NAME} STATIC ${PROGRESSIVE_SYSTEMS_SOURCES})
target_link_libraries(${MODULE_NAME} ...)
```

**After:**
```cmake
# No library creation - module system handles it
# Only set compile options and configuration
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
```

---

## 🎯 **WHY THIS WORKS**

1. **Static modules** are built into the main `modules` library
2. **Dynamic modules** create their own SHARED library (but we're using static)
3. The module system handles all linking automatically
4. No duplicate symbols or linking conflicts

---

## ✅ **EXPECTED RESULT**

- ✅ Build succeeds in GitHub Actions
- ✅ No duplicate symbols
- ✅ No linking errors
- ✅ Module works correctly

---

**Reference:** [GitHub Actions Build](https://github.com/vladislav23811/azerothcore-wotlk/actions/runs/19831279310/job/56817758391)

