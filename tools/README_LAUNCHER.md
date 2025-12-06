# WoW Custom Launcher - Complete Setup Guide

## 🎯 What It Does

A **full-featured launcher** that:
- ✅ Downloads/updates WoW client from ZIP
- ✅ Checks for missing files
- ✅ Downloads patches automatically
- ✅ Launches game
- ✅ **ZERO WORK for players!**

## 📋 Setup Instructions

### Step 1: Install Python Dependencies

```bash
pip install requests
```

### Step 2: Setup Web Server (XAMPP)

1. **Run setup script:**
   ```powershell
   .\tools\setup_web_server.ps1
   ```

2. **Place game ZIP:**
   - Copy `WOTLKHD.zip` to `C:\xampp\htdocs\WOTLKHD.zip`
   - Or update path in `setup_web_server.ps1`

3. **Start XAMPP Apache:**
   - Open XAMPP Control Panel
   - Start Apache server

### Step 3: Configure Launcher

Edit `launcher_config.json` (created on first run):

```json
{
    "server_url": "http://localhost",
    "game_zip_url": "http://localhost/WOTLKHD.zip",
    "patch_version_url": "http://localhost/patches/version.txt",
    "patch_download_url": "http://localhost/patches/latest/patch-Z.MPQ",
    "wow_path": "C:/WoW",
    "wow_exe": "Wow.exe",
    "auto_update": true,
    "check_missing_files": true
}
```

**For remote server**, change URLs:
```json
{
    "server_url": "http://your-server-ip",
    "game_zip_url": "http://your-server-ip/WOTLKHD.zip",
    ...
}
```

### Step 4: Run Launcher

**Option A: Double-click**
```
wow_launcher.bat
```

**Option B: Command line**
```bash
python tools/wow_launcher.py
```

## 🔧 How It Works

### First Time Setup:
1. Launcher checks if WoW is installed
2. If not, downloads `WOTLKHD.zip` from server
3. Extracts to `C:/WoW` (or configured path)
4. Checks for missing files
5. Downloads latest patch
6. Launches game

### Subsequent Runs:
1. Checks for missing files
2. Checks patch version
3. Downloads new patch if available
4. Launches game

## 📁 File Structure

```
C:\xampp\htdocs\
├── WOTLKHD.zip          # Full game client
└── patches/
    ├── version.txt       # Patch version (auto-generated)
    └── latest/
        └── patch-Z.MPQ   # Latest patch (symlink)

C:\WoW\                   # Game installation
├── Wow.exe
├── Data/
│   └── patch-Z.MPQ      # Installed patch
└── ...
```

## 🎯 Features

### Automatic Updates
- ✅ Checks server for new patch version
- ✅ Downloads automatically if newer
- ✅ Places in `Data/` folder
- ✅ Zero work for players!

### Missing File Detection
- ✅ Checks critical game files
- ✅ Offers to re-download if missing
- ✅ Validates installation

### Game Installation
- ✅ Downloads full client from ZIP
- ✅ Extracts automatically
- ✅ Sets up complete installation

## 🔒 Security Notes

- Launcher downloads from your server
- Update `server_url` to your actual server IP
- Use HTTPS if possible (requires SSL setup)
- Verify file integrity if needed (enable in config)

## 🚀 Advanced Configuration

### Custom Server
Edit `launcher_config.json`:
```json
{
    "server_url": "http://your-server.com",
    "game_zip_url": "http://your-server.com/downloads/WOTLKHD.zip",
    ...
}
```

### Custom Paths
```json
{
    "wow_path": "D:/Games/World of Warcraft",
    "temp_path": "D:/Temp",
    ...
}
```

### Disable Features
```json
{
    "auto_update": false,
    "check_missing_files": false,
    ...
}
```

## 📝 Server-Side Setup

### XAMPP Configuration

1. **Place files:**
   - `WOTLKHD.zip` → `C:\xampp\htdocs\`
   - Patches → `C:\xampp\htdocs\patches\`

2. **Auto-update version.txt:**
   - Server generates patch → updates `version.txt`
   - Or manually update: `echo %timestamp% > C:\xampp\htdocs\patches\version.txt`

3. **Symlink latest patch:**
   - `mklink C:\xampp\htdocs\patches\latest\patch-Z.MPQ C:\xampp\htdocs\patches\patch-Z.MPQ`

### Alternative: Use Worldserver HTTP

If you implement HTTP server in worldserver:
- Serve patches directly from `patches/` folder
- No XAMPP needed
- More integrated solution

## ✅ Result

**Players just:**
1. Run `wow_launcher.bat`
2. Click "Launch WoW"
3. **That's it!** Everything else is automatic!

**You just:**
1. Place `WOTLKHD.zip` in web server
2. Server auto-generates patches
3. **That's it!** Launcher handles the rest!

## 🎉 Zero Work for Everyone!

- ✅ Server: Auto-generates patches
- ✅ Launcher: Auto-downloads everything
- ✅ Players: Just click and play!

