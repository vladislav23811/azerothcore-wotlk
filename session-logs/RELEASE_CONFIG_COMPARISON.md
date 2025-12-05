# Release Folder Config Comparison

**Date:** December 4, 2025  
**Release Folder:** `C:\servery\WOTLK-BOTS\release`

---

## 📊 SUMMARY

**Status:** ✅ **Source is newer than release**

The source code has **newer/more updated** configuration files than the release folder. The release folder needs to be updated from source, not the other way around.

---

## 🔍 FINDINGS

### 1. **worldserver.conf.dist** ⚠️
**Release:** MySQL 8.0 example  
**Source:** MySQL 8.4 example ✅ (newer)

**Difference:**
- Release: `"C:/Program Files/MySQL/MySQL Server 8.0/bin/mysql.exe"`
- Source: `"C:/Program Files/MySQL/MySQL Server 8.4/bin/mysql.exe"` ✅

**Action:** ✅ Source is correct, no changes needed

---

### 2. **authserver.conf.dist** ✅
**Status:** Both have MySQL 8.4 example - **IDENTICAL**

---

### 3. **dbimport.conf.dist** ✅
**Status:** Both have MySQL 8.4 example - **IDENTICAL**

---

### 4. **mod_ale.conf.dist** ⚠️
**Release:** `ALE.AutoReload = false`  
**Source:** `ALE.AutoReload = true` ✅ (newer, as requested)

**Difference:**
- Release: `ALE.AutoReload = false`
- Source: `ALE.AutoReload = true` ✅ (enabled for dynamic Lua)

**Action:** ✅ Source is correct, no changes needed

---

### 5. **mod-progressive-systems.conf.dist** ✅
**Status:** Both files are **IDENTICAL** - same content

---

## 📋 RELEASE FOLDER CUSTOMIZATIONS

### Active Config Files (Not .dist)

These are the actual running configs with custom settings:

#### **worldserver.conf**
- Database: `w_auth`, `w_world`, `w_characters`
- DataDir: `"data"`
- LogsDir: `"logs"`
- TempDir: `"temp"`

#### **authserver.conf**
- LogsDir: `"logs"`

**Note:** These are runtime configs with actual credentials and paths. These should NOT be synced to source (they contain sensitive data).

---

## ✅ RECOMMENDATIONS

### 1. **Update Release .dist Files from Source** ✅

The release folder's `.conf.dist` files are older than source. When you rebuild, they'll be automatically updated.

**Files to update:**
- ✅ `worldserver.conf.dist` - Update MySQL 8.0 → 8.4 example
- ✅ `mod_ale.conf.dist` - Update AutoReload false → true

**How to update:**
```powershell
# After next build, these will be automatically updated
# Or manually copy from source:
Copy-Item "src\server\apps\worldserver\worldserver.conf.dist" "C:\servery\WOTLK-BOTS\release\configs\worldserver.conf.dist"
Copy-Item "modules\mod-eluna\conf\mod_ale.conf.dist" "C:\servery\WOTLK-BOTS\release\configs\modules\mod_ale.conf.dist"
```

### 2. **Keep Runtime Configs Separate** ✅

The actual `.conf` files (without `.dist`) contain:
- Database credentials
- Custom paths
- Production settings

**These should NOT be synced to source** - they're environment-specific.

---

## 🎯 CONCLUSION

**No fixes needed in source!** ✅

The source code is **up-to-date** and has the latest fixes:
- ✅ MySQL 8.4 examples
- ✅ Lua AutoReload enabled
- ✅ All module configs current

**Next Steps:**
1. ✅ Source is ready - no changes needed
2. ⚠️ Release folder will be updated on next build
3. ✅ Runtime configs (`.conf` without `.dist`) are correct as-is

---

## 📝 NOTES

- Release folder is a **deployment directory** (compiled binaries + configs)
- Source folder is the **development directory** (source code + templates)
- `.conf.dist` files are **templates** that get copied during build
- `.conf` files are **runtime configs** with actual values
- Source templates are newer than release templates (expected after updates)

