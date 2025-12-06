# Client Auto-Patch System - ZERO WORK for Players!

## 🎯 Goal
Make it so players have **ZERO work** - patches download and install automatically!

## 📋 How It Works

### Server Side (Already Done! ✅)
1. Server detects custom items (entry >= 999000)
2. Auto-generates DBC entries
3. Auto-creates MPQ patch (`patches/patch-Z.MPQ`)
4. **Server reads from DATABASE** (not DBC files!)
   - ✅ Server uses `item_template` table
   - ✅ DBC files are ONLY for clients
   - ✅ No conversion needed - server already works!

### Client Side (What We Need)

## Option 1: Addon + HTTP Server (Recommended) ⭐

### How It Works:
1. **Addon checks server** for patch version
2. **Downloads MPQ** if newer version available
3. **Places in Data folder** automatically
4. **Notifies player** to restart client

### Implementation:

#### Server Side:
- HTTP server serves patches (port 8080)
- Endpoints:
  - `GET /patches/version.txt` - Returns patch version
  - `GET /patches/latest/patch-Z.MPQ` - Downloads patch file

#### Addon Side:
- `ProgressiveSystemsAutoPatch.lua` checks for updates
- Downloads and installs patch automatically
- Zero work for player!

### Limitations:
- WoW addons **can't directly download files** (security restriction)
- Need external tool or launcher

## Option 2: Custom Launcher (Best UX) ⭐⭐⭐

### How It Works:
1. **Custom launcher** checks server for updates
2. **Downloads MPQ** before starting WoW
3. **Places in Data folder**
4. **Starts WoW** automatically

### Benefits:
- ✅ Works perfectly (no addon limitations)
- ✅ Updates before game starts
- ✅ Can check on launcher startup
- ✅ Can verify file integrity

### Implementation:
- Launcher checks: `http://server:8080/patches/version.txt`
- Compares with local version
- Downloads if newer: `http://server:8080/patches/latest/patch-Z.MPQ`
- Saves to: `WoW/Data/patch-Z.MPQ`
- Starts WoW

## Option 3: Hybrid - Addon + External Tool

### How It Works:
1. **Addon detects** new patch version
2. **Calls external tool** (small .exe/.bat script)
3. **Tool downloads** MPQ from server
4. **Tool places** in Data folder
5. **Addon notifies** player

### Benefits:
- ✅ Works around addon limitations
- ✅ Still automated
- ✅ Player just needs to run tool once

## 📝 Implementation Details

### Server HTTP Endpoints:

```
GET /patches/version.txt
Response: "20240101120000" (timestamp or version string)

GET /patches/latest/patch-Z.MPQ
Response: Binary MPQ file
Headers: Content-Type: application/octet-stream
         Content-Disposition: attachment; filename="patch-Z.MPQ"
```

### Addon Logic:

```lua
-- Check version on login
local serverVersion = GetServerVersion() -- HTTP GET
local localVersion = GetLocalVersion()   -- Read from file

if serverVersion > localVersion then
    DownloadPatch()  -- HTTP GET to download MPQ
    SaveToDataFolder()  -- Copy to WoW/Data/
    NotifyPlayer("Patch updated! Please restart client.")
end
```

### Launcher Logic:

```python
# Check for updates
server_version = requests.get("http://server:8080/patches/version.txt").text
local_version = read_version_file()

if server_version > local_version:
    # Download patch
    patch = requests.get("http://server:8080/patches/latest/patch-Z.MPQ")
    save_to_file("WoW/Data/patch-Z.MPQ", patch.content)
    print("Patch updated!")

# Start WoW
subprocess.run(["WoW/Wow.exe"])
```

## 🔧 Current Status

### ✅ What's Done:
- Server auto-generates DBC entries
- Server auto-creates MPQ patch
- Configurable entry threshold (default: 999000)
- Server reads from database (no DBC needed)

### 🚧 What's Needed:
- HTTP server on worldserver (or separate service)
- Addon or launcher to download patches
- Version checking system

## 💡 Recommended Approach

**Use Custom Launcher** - It's the most reliable:
1. ✅ No addon limitations
2. ✅ Updates before game starts
3. ✅ Can verify file integrity
4. ✅ Better user experience

**Alternative**: If launcher is too complex, use **Option 3** (Addon + External Tool)

## 📦 Files Needed

1. **HTTP Server** (C++ or Python)
   - Serves patches from `patches/` folder
   - Provides version endpoint

2. **Addon** (`ProgressiveSystemsAutoPatch.lua`)
   - Checks for updates
   - Downloads patches (via external tool)

3. **External Tool** (optional)
   - Downloads MPQ if addon can't
   - Places in Data folder

4. **Launcher** (optional, recommended)
   - Checks and downloads patches
   - Starts WoW

## 🎯 Next Steps

1. Implement HTTP server in worldserver (or separate service)
2. Create addon for version checking
3. Create launcher or external tool for downloading
4. Test end-to-end flow

## ✅ Result

**ZERO WORK for players:**
- ✅ Launcher/Addon checks for updates
- ✅ Downloads patch automatically
- ✅ Installs to Data folder
- ✅ Player just restarts client
- ✅ Everything works!

