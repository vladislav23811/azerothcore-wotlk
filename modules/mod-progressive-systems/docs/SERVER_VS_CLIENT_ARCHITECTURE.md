# Server vs Client Architecture - How It Works

## 🎯 Key Understanding

### Server Side (AzerothCore)
- ✅ **Reads from DATABASE** (`item_template` table)
- ✅ **Does NOT read DBC files**
- ✅ **Works immediately** when you create items in database
- ✅ **No conversion needed** - server already works!

### Client Side (WoW Client)
- ✅ **Reads from DBC files** (in MPQ archives)
- ✅ **Needs MPQ patch** with `Item.dbc` for custom items
- ✅ **Without patch**: Items show as `???` or don't work
- ✅ **With patch**: Items display correctly

## 📋 Data Flow

```
┌─────────────────────────────────────────────────────────┐
│                    YOU CREATE ITEM                       │
│         INSERT INTO item_template (entry >= 999000)     │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│              SERVER READS FROM DATABASE                  │
│  ObjectMgr::LoadItemTemplates() reads item_template     │
│  ✅ Server works immediately - no DBC needed!           │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│         DBC GENERATOR (For Clients Only)                 │
│  OnAfterDatabasesLoaded() fires automatically           │
│  - Detects custom items (entry >= 999000)               │
│  - Generates DBC entries from database                  │
│  - Writes CSV file (dbc/custom/Item.dbc.csv)            │
│  - Creates MPQ patch (patches/patch-Z.MPQ)              │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│              CLIENT NEEDS MPQ PATCH                      │
│  - Client reads DBC from MPQ file                        │
│  - Without patch: Items show ???                        │
│  - With patch: Items work perfectly                     │
└─────────────────────────────────────────────────────────┘
```

## 🔍 Detailed Explanation

### Why Server Doesn't Need DBC

**AzerothCore Architecture:**
1. Server loads items from `item_template` table
2. Server uses database data directly
3. DBC files are **optional** for server (only used for validation)
4. Server works perfectly without DBC files!

**Code Evidence:**
```cpp
// In ObjectMgr::LoadItemTemplates()
QueryResult result = WorldDatabase.Query(
    "SELECT entry, class, subclass, ... FROM item_template");
// Server reads directly from database - no DBC needed!
```

### Why Clients Need DBC

**WoW Client Architecture:**
1. Client reads item data from DBC files (in MPQ archives)
2. Client does NOT connect to database
3. Without DBC entry: Item shows as `???`
4. With DBC entry: Item displays correctly

**Solution:**
- Generate DBC entries from database
- Package in MPQ patch
- Client reads from MPQ

## 📁 File Formats

### CSV Format (dbc/custom/Item.dbc.csv)
- **Purpose**: Easy to read/edit/convert
- **Server**: Doesn't use it (reads from DB)
- **Client**: Can't use it directly (needs binary DBC)
- **Conversion**: CSV → Binary DBC → MPQ

### Binary DBC Format (Item.dbc)
- **Purpose**: Client-readable format
- **Server**: Doesn't need it
- **Client**: Reads from MPQ
- **Location**: Inside `patch-Z.MPQ/DBFilesClient/Item.dbc`

### MPQ Patch (patch-Z.MPQ)
- **Purpose**: Package DBC files for client
- **Server**: Generates it
- **Client**: Needs it in `Data/` folder
- **Structure**: `DBFilesClient/Item.dbc` inside MPQ

## ✅ Summary

| Component | Server | Client |
|-----------|--------|--------|
| **Data Source** | Database (`item_template`) | DBC files (in MPQ) |
| **Needs DBC?** | ❌ No | ✅ Yes |
| **Needs MPQ?** | ❌ No | ✅ Yes |
| **Works Without Patch?** | ✅ Yes | ❌ No |
| **Reads CSV?** | ❌ No | ❌ No |
| **Reads Database?** | ✅ Yes | ❌ No |

## 🎯 Bottom Line

1. **Server**: Just create items in database - it works!
2. **Client**: Needs MPQ patch with DBC files
3. **DBC Generator**: Auto-creates patch for clients
4. **Zero Work**: Server works immediately, clients get patch automatically

**You don't need to convert anything for the server - it already works from the database!**

