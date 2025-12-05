# tools Directory Deletion

**Date:** December 4, 2025  
**Directory:** `C:\servery\WOTLK-BOTS\azerothcore-wotlk\tools`

---

## ✅ DELETED

### Contents (Removed):
- `batch_process.ps1` - PowerShell script for batch processing
- `extract_todos.ps1` - PowerShell script for extracting TODOs
- `issue_progress.ps1` - PowerShell script for tracking issue progress

**Total Size:** ~13.8 KB (3 PowerShell scripts)

---

## 📊 WHAT IT WAS

These were **custom helper scripts** for project management tasks:
- **batch_process.ps1** - Batch processing operations
- **extract_todos.ps1** - Extract TODO comments from codebase
- **issue_progress.ps1** - Track GitHub issue progress

---

## 🔍 IMPORTANT NOTE

**This is NOT the same as `src/tools/`**

- ❌ **`tools/`** (root) - Custom helper scripts (deleted)
- ✅ **`src/tools/`** - Core build tools (kept - part of AzerothCore)

The CMake build system references `src/tools/` for building tools like:
- `dbimport` - Database import tool
- `map_extractor` - Map extraction tool
- `mmaps_generator` - Movement maps generator
- `vmap4_extractor` - VMap extraction tool

---

## ✅ STATUS

**Deleted:** ✅ Complete  
**Core Tools:** ✅ Unaffected (`src/tools/` remains)

---

## 📝 NOTES

- These were custom development helper scripts
- Not part of the core AzerothCore build system
- Safe to delete - no impact on compilation or server functionality

