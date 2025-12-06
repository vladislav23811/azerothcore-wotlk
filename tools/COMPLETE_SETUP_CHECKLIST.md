# Complete Setup Checklist

## 🎯 What to Do Now

Follow this checklist to get everything working!

## ✅ Step 1: Setup Web Server

### 1.1 Run Setup Script
```powershell
.\tools\setup_web_server.ps1
```

### 1.2 Extract Game
```powershell
.\tools\extract_game_to_htdocs.ps1
```
- [ ] Game extracted to `C:\xampp\htdocs\WoW\`
- [ ] `Wow.exe` exists in extracted folder

### 1.3 Verify Files
- [ ] `C:\xampp\htdocs\WoW\Wow.exe` exists
- [ ] `C:\xampp\htdocs\patches\` directory exists
- [ ] Apache is running in XAMPP

### 1.4 Test URLs
Open in browser:
- [ ] `http://localhost/WoW/Wow.exe` (downloads)
- [ ] `http://localhost/patches/version.txt` (shows number)
- [ ] `http://localhost/patches/latest/patch-Z.MPQ` (downloads)

## ✅ Step 2: Configure Server

### 2.1 Edit Server Config
Edit `modules/mod-progressive-systems/conf/mod-progressive-systems.conf`:
```ini
ProgressiveSystems.DBC.WebServerPath = C:/xampp/htdocs
```

### 2.2 Restart Server
- [ ] Stop worldserver
- [ ] Start worldserver
- [ ] Check logs for: "Patch copied to web server"

## ✅ Step 3: Build Launcher

### 3.1 Install Qt
**Option A: vcpkg (Recommended)**
```powershell
vcpkg install qt5-base qt5-widgets qt5-network
```

**Option B: System Install**
- Download Qt from qt.io
- Install Qt 5.15+ or Qt 6.x

### 3.2 Build
```powershell
cd tools/launcher
mkdir build
cd build
cmake ..
cmake --build . --config Release
```

### 3.3 Verify
- [ ] `WoWLauncher.exe` exists in build folder
- [ ] Qt DLLs are present (or use `windeployqt`)

## ✅ Step 4: Configure Launcher

### 4.1 First Run
- [ ] Run `WoWLauncher.exe`
- [ ] Click "Settings"
- [ ] Set Game Path: `C:/WoW` (or your path)
- [ ] Set Server URL: `http://localhost` (or your server IP)
- [ ] Click "Save"

### 4.2 Verify Config
Check `launcher_config.json`:
```json
{
    "server_url": "http://localhost",
    "game_zip_url": "http://localhost/WoW/",
    "patch_version_url": "http://localhost/patches/version.txt",
    "patch_download_url": "http://localhost/patches/latest/patch-Z.MPQ",
    "wow_path": "C:/WoW"
}
```

## ✅ Step 5: Test Launcher

### 5.1 Test Game Installation
- [ ] Click "Check for Updates"
- [ ] If game not installed, it should offer to download
- [ ] Download should work
- [ ] Extraction should work

### 5.2 Test Patch Updates
- [ ] Click "Check for Updates"
- [ ] Should check server version
- [ ] Should download patch if newer
- [ ] Patch should appear in `WoW/Data/patch-Z.MPQ`

### 5.3 Test Game Launch
- [ ] Click "Launch WoW"
- [ ] Game should start
- [ ] No errors in launcher log

## ✅ Step 6: Test Addons

### 6.1 Install Addon
- [ ] Copy `modules/mod-progressive-systems/addon/ProgressiveSystems/` to `WoW/Interface/AddOns/`
- [ ] Verify `ProgressiveSystems.toc` exists

### 6.2 Test in Game
- [ ] Launch game
- [ ] Check addon is loaded (no errors)
- [ ] Test addon features

## ✅ Step 7: End-to-End Test

### 7.1 Create Custom Item
```sql
INSERT INTO item_template (entry, class, subclass, name, displayid, ...)
VALUES (999001, 2, 7, 'Test Custom Sword', 133885, ...);
```

### 7.2 Restart Server
- [ ] Server generates DBC
- [ ] Server creates MPQ patch
- [ ] Server copies to web server
- [ ] Server updates version.txt

### 7.3 Update Client
- [ ] Run launcher
- [ ] Click "Check for Updates"
- [ ] Patch downloads
- [ ] Restart game
- [ ] Custom item should work!

## 🐛 Troubleshooting

### Launcher won't connect
- Check Apache is running
- Check firewall allows port 80
- Check server URL in settings

### Patch not downloading
- Check `patches/version.txt` exists
- Check `patches/latest/patch-Z.MPQ` exists
- Check `.htaccess` allows MPQ files

### Game won't launch
- Check game path is correct
- Check `Wow.exe` exists
- Check game is fully installed

### Addon not loading
- Check addon is in `Interface/AddOns/ProgressiveSystems/`
- Check `ProgressiveSystems.toc` exists
- Check game version matches addon (30305 for WOTLK)

## 📋 Quick Reference

### Server URLs
- Game ZIP: `http://localhost/WOTLKHD.zip`
- Patch Version: `http://localhost/patches/version.txt`
- Patch Download: `http://localhost/patches/latest/patch-Z.MPQ`

### File Locations
- Game ZIP: `C:\xampp\htdocs\WOTLKHD.zip`
- Patches: `C:\xampp\htdocs\patches\`
- Launcher Config: `launcher_config.json`
- Server Config: `modules/mod-progressive-systems/conf/mod-progressive-systems.conf`

### Commands
```powershell
# Setup web server
.\tools\setup_web_server.ps1

# Build launcher
cd tools/launcher/build
cmake ..
cmake --build . --config Release

# Deploy Qt DLLs
windeployqt WoWLauncher.exe
```

## 🎉 Success Criteria

Everything works when:
- ✅ Launcher connects to server
- ✅ Launcher downloads game (if needed)
- ✅ Launcher downloads patches automatically
- ✅ Launcher launches game
- ✅ Game loads with custom items
- ✅ Addons work correctly
- ✅ Zero manual work for players!

