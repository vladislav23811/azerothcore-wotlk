# Auto DBC Patch System - Automated Custom Item Support

## 🎯 Vision
Create an **automated system** that:
1. ✅ Monitors `item_template` for new custom items
2. ✅ Auto-generates DBC entries (Item.dbc, ItemDisplayInfo.dbc)
3. ✅ Auto-generates MPQ patch files for clients
4. ✅ Auto-distributes patches via addon or download system
5. ✅ **Zero manual work** - fully automated!

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    CUSTOM ITEM CREATED                       │
│              (INSERT INTO item_template)                      │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│         PROGRESSIVE SYSTEMS DBC GENERATOR                    │
│  (C++ Hook in ObjectMgr::LoadItemTemplates)                 │
│  - Detects custom items (entry > 99999 or custom flag)      │
│  - Generates DBC entries automatically                      │
│  - Updates server-side DBC cache                             │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│         MPQ PATCH GENERATOR                                  │
│  (C++ Tool or External Program)                             │
│  - Reads generated DBC files                                 │
│  - Creates patch-Z.MPQ with DBFilesClient/                  │
│  - Signs/validates patch file                                │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│         PATCH DISTRIBUTION                                   │
│  Option A: Addon Auto-Download                              │
│  Option B: HTTP Server (worldserver serves patches)         │
│  Option C: Direct file share (manual)                       │
└─────────────────────────────────────────────────────────────┘
```

## 🔧 Implementation Strategy

### Phase 1: Server-Side DBC Generation (C++)

**Location**: `modules/mod-progressive-systems/src/DBCGenerator.cpp`

**How It Works**:
1. Hook into `ObjectMgr::LoadItemTemplates()`
2. After items load, scan for custom items
3. Generate DBC entries in memory or file
4. Server uses generated DBC data

**Key Functions**:
```cpp
class DBCGenerator
{
    // Generate Item.dbc entry from item_template
    bool GenerateItemDBCEntry(uint32 entry, ItemTemplate const* item);
    
    // Generate ItemDisplayInfo.dbc entry
    bool GenerateDisplayInfoDBCEntry(uint32 displayId, ...);
    
    // Write DBC files to disk
    bool WriteDBCFiles(const std::string& outputPath);
    
    // Load custom DBC entries into server memory
    bool LoadCustomDBCEntries();
};
```

### Phase 2: Hybrid DBC Loading (C++)

**Idea**: Server reads DBC first, then **overrides** with database entries!

```cpp
// In ObjectMgr::LoadItemTemplates()
void ObjectMgr::LoadItemTemplates()
{
    // 1. Load standard DBC files (existing code)
    LoadItemDBC();
    
    // 2. Load custom items from database
    LoadCustomItemsFromDB();
    
    // 3. Merge: Database entries override DBC entries
    for (auto& customItem : customItems)
    {
        if (customItem.entry > 99999 || customItem.flags & CUSTOM_ITEM_FLAG)
        {
            // Override DBC entry with database entry
            _itemTemplateStore[customItem.entry] = customItem;
        }
    }
}
```

**Benefits**:
- ✅ Server works immediately (reads from DB)
- ✅ Can generate DBC for clients
- ✅ No server restart needed for new items

### Phase 3: MPQ Patch Generator

**Option A: C++ Tool (Recommended)**
```cpp
class MPQGenerator
{
    // Create MPQ archive
    bool CreateMPQ(const std::string& outputPath);
    
    // Add DBC file to MPQ
    bool AddDBCFile(const std::string& dbcPath, const std::string& mpqPath);
    
    // Generate complete patch
    bool GeneratePatch(const std::string& dbcDir, const std::string& outputMPQ);
};
```

**Option B: External Python/Node.js Script**
- Uses `pympq` or similar library
- Called from C++ via system() or HTTP API
- More flexible, easier to maintain

### Phase 4: Auto-Distribution

**Option A: Addon Auto-Download (Best UX)**
```lua
-- ProgressiveSystemsAutoPatch.lua
local function DownloadPatch()
    local url = "http://your-server.com/patches/latest/patch-Z.MPQ"
    -- Download and save to Data folder
    -- Verify checksum
    -- Notify player to restart client
end
```

**Option B: Worldserver HTTP Endpoint**
```cpp
// In worldserver, serve patches via HTTP
void HandlePatchRequest(HTTPRequest& req)
{
    std::string patchFile = "patches/patch-Z.MPQ";
    SendFile(req, patchFile);
}
```

**Option C: Database-Driven Distribution**
- Store patch info in database
- Addon queries database for patch version
- Downloads if newer version available

## 📋 Detailed Implementation Plan

### Step 1: Custom Item Detection

**Database Flag**:
```sql
ALTER TABLE `item_template` 
ADD COLUMN `is_custom` TINYINT(1) DEFAULT 0 
COMMENT '1 = Custom item requiring DBC generation';

-- Mark custom items
UPDATE `item_template` 
SET `is_custom` = 1 
WHERE `entry` >= 99990 OR `entry` IN (99997, 99998, 99999);
```

**C++ Detection**:
```cpp
bool IsCustomItem(ItemTemplate const* item)
{
    // Method 1: Entry range
    if (item->ItemId >= 99990)
        return true;
    
    // Method 2: Custom flag (if we add it)
    // if (item->FlagsCu & CUSTOM_ITEM_FLAG)
    //     return true;
    
    // Method 3: Check custom_weapon_templates table
    QueryResult result = WorldDatabase.Query(
        "SELECT 1 FROM custom_weapon_templates WHERE custom_entry = {}", 
        item->ItemId);
    if (result)
        return true;
    
    return false;
}
```

### Step 2: DBC Entry Generation

**Item.dbc Structure** (simplified):
```
struct ItemDBCEntry
{
    uint32 ID;                    // Item entry
    uint32 ClassID;                // Item class (from item_template.class)
    uint32 SubclassID;            // Item subclass
    int32  SoundOverrideSubclass; // Sound override
    uint32 Material;               // Material type
    uint32 DisplayInfoID;         // Display ID (from item_template.displayid)
    uint32 InventoryType;         // Inventory slot
    uint32 SheatheType;           // Sheath type
};
```

**C++ Implementation**:
```cpp
bool DBCGenerator::GenerateItemDBCEntry(uint32 entry, ItemTemplate const* item)
{
    ItemDBCEntry dbcEntry;
    dbcEntry.ID = entry;
    dbcEntry.ClassID = item->Class;
    dbcEntry.SubclassID = item->SubClass;
    dbcEntry.SoundOverrideSubclass = item->SoundOverrideSubclass;
    dbcEntry.Material = item->Material;
    dbcEntry.DisplayInfoID = item->DisplayInfoID;
    dbcEntry.InventoryType = item->InventoryType;
    dbcEntry.SheatheType = item->Sheath;
    
    // Add to in-memory DBC store
    _customItemDBCStore[entry] = dbcEntry;
    
    // Write to file for MPQ generation
    WriteItemDBCEntry(dbcEntry);
    
    return true;
}
```

### Step 3: Server-Side DBC Override

**Modify ObjectMgr**:
```cpp
// In ObjectMgr::LoadItemTemplates()
void ObjectMgr::LoadItemTemplates()
{
    // ... existing DBC loading code ...
    
    // NEW: Load custom items and override DBC
    LoadCustomItemsFromDatabase();
}

void ObjectMgr::LoadCustomItemsFromDatabase()
{
    QueryResult result = WorldDatabase.Query(
        "SELECT * FROM item_template WHERE is_custom = 1 OR entry >= 99990");
    
    if (!result)
        return;
    
    do
    {
        Field* fields = result->Fetch();
        uint32 entry = fields[0].Get<uint32>();
        
        // Load item template from database
        ItemTemplate& itemTemplate = _itemTemplateStore[entry];
        // ... populate from database fields ...
        
        // Generate DBC entry for client patches
        if (sDBCGenerator)
        {
            sDBCGenerator->GenerateItemDBCEntry(entry, &itemTemplate);
        }
        
    } while (result->NextRow());
    
    // Generate DBC files for client
    if (sDBCGenerator)
    {
        sDBCGenerator->WriteDBCFiles("dbc/custom/");
        sDBCGenerator->GenerateMPQPatch("patches/patch-Z.MPQ");
    }
}
```

### Step 4: MPQ Patch Generation

**Using External Library** (StormLib or similar):
```cpp
#include "StormLib.h"

bool MPQGenerator::GeneratePatch(const std::string& dbcDir, const std::string& outputMPQ)
{
    // Create MPQ archive
    HANDLE hMpq = NULL;
    if (!SFileCreateArchive(outputMPQ.c_str(), MPQ_CREATE_ARCHIVE_V2, 0, &hMpq))
    {
        LOG_ERROR("dbc", "Failed to create MPQ: {}", outputMPQ);
        return false;
    }
    
    // Add DBC files
    std::vector<std::string> dbcFiles = {
        "Item.dbc",
        "ItemDisplayInfo.dbc",
        // ... other DBC files ...
    };
    
    for (const auto& dbcFile : dbcFiles)
    {
        std::string fullPath = dbcDir + "/" + dbcFile;
        std::string mpqPath = "DBFilesClient/" + dbcFile;
        
        if (!SFileAddFile(hMpq, fullPath.c_str(), mpqPath.c_str(), MPQ_FILE_COMPRESS, MPQ_COMPRESSION_ZLIB, NULL))
        {
            LOG_ERROR("dbc", "Failed to add {} to MPQ", dbcFile);
        }
    }
    
    // Close MPQ
    SFileCloseArchive(hMpq);
    
    LOG_INFO("dbc", "Generated MPQ patch: {}", outputMPQ);
    return true;
}
```

**Alternative: Python Script** (Easier):
```python
# generate_patch.py
import pympq
import os

def generate_patch(dbc_dir, output_mpq):
    mpq = pympq.MPQArchive(output_mpq, create=True)
    
    for dbc_file in os.listdir(dbc_dir):
        if dbc_file.endswith('.dbc'):
            local_path = os.path.join(dbc_dir, dbc_file)
            mpq_path = f"DBFilesClient/{dbc_file}"
            mpq.add_file(local_path, mpq_path)
    
    mpq.close()
    print(f"Generated patch: {output_mpq}")

if __name__ == "__main__":
    generate_patch("dbc/custom", "patches/patch-Z.MPQ")
```

**C++ calls Python**:
```cpp
void GeneratePatch()
{
    std::string command = "python generate_patch.py dbc/custom patches/patch-Z.MPQ";
    system(command.c_str());
}
```

### Step 5: Auto-Distribution

**Option A: Addon Auto-Download**:
```lua
-- ProgressiveSystemsAutoPatch.lua
local PATCH_URL = "http://your-server.com/patches/latest/patch-Z.MPQ"
local PATCH_PATH = "Interface/AddOns/ProgressiveSystems/patches/patch-Z.MPQ"
local VERSION_URL = "http://your-server.com/patches/version.txt"

local function CheckForUpdates()
    -- Check server version
    -- Download if newer
    -- Extract to Data folder
    -- Notify player
end
```

**Option B: Worldserver HTTP Server**:
```cpp
// Add HTTP server to worldserver
#include "HttpServer.h"

void SetupPatchServer()
{
    HttpServer::RegisterHandler("/patches/latest", [](HTTPRequest& req) {
        std::string patchFile = "patches/patch-Z.MPQ";
        SendFile(req, patchFile, "application/octet-stream");
    });
    
    HttpServer::RegisterHandler("/patches/version", [](HTTPRequest& req) {
        std::string version = GetPatchVersion();
        SendText(req, version);
    });
}
```

## 🎯 Recommended Implementation Order

### Phase 1: Server-Side (Immediate)
1. ✅ Add `is_custom` flag to `item_template`
2. ✅ Create `DBCGenerator` class
3. ✅ Hook into `ObjectMgr::LoadItemTemplates()`
4. ✅ Generate DBC entries in memory
5. ✅ Server uses database entries (works immediately!)

### Phase 2: DBC File Generation (Short-term)
1. ✅ Write DBC files to disk
2. ✅ Create MPQ generator (Python script)
3. ✅ Auto-generate patch on server start
4. ✅ Manual distribution (players download patch)

### Phase 3: Auto-Distribution (Long-term)
1. ✅ Add HTTP server to worldserver
2. ✅ Create addon for auto-download
3. ✅ Version checking system
4. ✅ Automatic patch updates

## 💡 Alternative: Simpler Approach

**If full automation is too complex, use a hybrid**:

1. **Server**: Always reads from database (no DBC needed)
2. **Manual Tool**: Admin runs script to generate patches
3. **Distribution**: Manual download or simple HTTP server

**Tool Structure**:
```
tools/generate_custom_item_patch/
├── generate_patch.cpp (or .py)
├── read_item_template.cpp
├── generate_dbc.cpp
└── create_mpq.cpp
```

**Usage**:
```bash
# Admin runs this after creating custom items
./generate_patch --db-config worldserver.conf --output patches/patch-Z.MPQ
```

## 📝 Database Schema Additions

```sql
-- Track custom items requiring DBC generation
ALTER TABLE `item_template` 
ADD COLUMN `is_custom` TINYINT(1) DEFAULT 0 
COMMENT '1 = Custom item requiring DBC generation';

-- Track patch versions
CREATE TABLE IF NOT EXISTS `custom_item_patches` (
    `patch_version` INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    `patch_file` VARCHAR(255) NOT NULL,
    `items_count` INT UNSIGNED NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `checksum` VARCHAR(64) COMMENT 'SHA256 checksum of patch file'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

## 🚀 Quick Start Implementation

**Minimal Viable Product (MVP)**:

1. **C++ Hook** (1-2 hours):
   - Detect custom items in `LoadItemTemplates()`
   - Generate DBC entries in memory
   - Write to file: `dbc/custom/Item.dbc`

2. **Python Script** (1 hour):
   - Read `dbc/custom/Item.dbc`
   - Create `patch-Z.MPQ`
   - Place in `patches/` folder

3. **Manual Distribution** (for now):
   - Players download `patch-Z.MPQ`
   - Place in `Data/` folder
   - Restart client

**Result**: Works immediately, can automate later!

## ✅ Benefits

1. **Zero Manual Work**: Items auto-generate DBC entries
2. **Server Works Immediately**: Reads from database
3. **Client Patches Auto-Generated**: MPQ files created automatically
4. **Scalable**: Works for any number of custom items
5. **Maintainable**: All logic in one place

## 🎉 Conclusion

This system provides **full automation** for custom items:
- ✅ Server reads from database (works immediately)
- ✅ DBC files auto-generated
- ✅ MPQ patches auto-created
- ✅ Can auto-distribute via addon/HTTP

**Start with MVP**, then add automation features incrementally!

