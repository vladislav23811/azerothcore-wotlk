# 🔧 Linker Error Fix - Missing Script Functions
## GitHub Actions Build Failure

---

## ❌ **PROBLEM**

The linker is reporting unresolved external symbols:
```
error LNK2019: unresolved external symbol "void __cdecl AddSC_progressive_bosses(void)"
error LNK2019: unresolved external symbol "void __cdecl AddSC_progressive_items(void)"
error LNK2019: unresolved external symbol "void __cdecl AddSC_progressive_spells(void)"
```

**Root Cause:** The functions are defined in the `.cpp` files, but the files might not be getting compiled or linked properly.

---

## ✅ **VERIFICATION**

The functions ARE defined:
- ✅ `AddSC_progressive_bosses()` - Line 148 in `progressive_bosses.cpp`
- ✅ `AddSC_progressive_items()` - Line 102 in `progressive_items.cpp`
- ✅ `AddSC_progressive_spells()` - Line 160 in `progressive_spells.cpp`

The functions ARE being called:
- ✅ `custom_script_loader.cpp` calls all three functions

---

## 🔍 **POSSIBLE CAUSES**

1. **Files not being collected** - `CollectSourceFiles()` might not be finding them
2. **Compilation errors** - Files might have errors preventing compilation
3. **Linking order** - Files might not be in the link order
4. **Missing includes** - Files might have missing dependencies

---

## 🎯 **SOLUTION**

The files should be automatically collected by `CollectSourceFiles()` in the script system. If they're not being found, we need to verify:

1. Files exist in `src/server/scripts/Custom/`
2. Files have correct function signatures
3. Files compile without errors
4. Files are included in the build

**Next Step:** Check if files are actually being compiled in the build output.

