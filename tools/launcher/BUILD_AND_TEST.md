# Build and Test Guide

## 🔧 Building the Launcher

### Prerequisites

1. **Install Qt**
   - Download from https://www.qt.io/download
   - Or use vcpkg: `vcpkg install qt5-base qt5-widgets qt5-network`
   - Or use system package manager (Linux)

2. **CMake 3.15+**
   - Usually comes with Visual Studio
   - Or download from https://cmake.org/

3. **C++17 Compiler**
   - Visual Studio 2019+ (Windows)
   - GCC 7+ (Linux)
   - Clang 8+ (Mac)

### Build Steps

#### Windows (Visual Studio)

```powershell
# Navigate to launcher directory
cd tools/launcher

# Create build directory
mkdir build
cd build

# Configure (adjust Qt path if needed)
cmake .. -DCMAKE_BUILD_TYPE=Release

# Build
cmake --build . --config Release

# Executable will be in: build/Release/WoWLauncher.exe
```

#### Using vcpkg (Recommended)

```powershell
# Install Qt via vcpkg
vcpkg install qt5-base qt5-widgets qt5-network

# Configure with vcpkg toolchain
cmake .. -DCMAKE_TOOLCHAIN_FILE=[vcpkg root]/scripts/buildsystems/vcpkg.cmake

# Build
cmake --build . --config Release
```

#### Linux

```bash
# Install Qt
sudo apt-get install qt6-base-dev qt6-widgets-dev qt6-network-dev

# Build
mkdir build && cd build
cmake ..
make
```

## 📦 Distribution

### Windows

1. **Copy executable:**
   ```powershell
   copy build\Release\WoWLauncher.exe C:\WoWLauncher\
   ```

2. **Copy Qt DLLs:**
   ```powershell
   # Use windeployqt (comes with Qt)
   windeployqt.exe WoWLauncher.exe
   ```

3. **Or manually copy:**
   - `Qt6Core.dll` (or `Qt5Core.dll`)
   - `Qt6Widgets.dll` (or `Qt5Widgets.dll`)
   - `Qt6Network.dll` (or `Qt5Network.dll`)
   - `Qt6Gui.dll` (or `Qt5Gui.dll`)

### Create Installer (Optional)

Use Qt Installer Framework or Inno Setup to create installer.

## 🧪 Testing

### 1. Test Launcher Startup

```powershell
# Run launcher
.\build\Release\WoWLauncher.exe
```

**Expected:**
- ✅ Launcher window opens
- ✅ Shows "Ready" status
- ✅ Game path displayed
- ✅ Buttons enabled

### 2. Test Settings

1. Click "Settings" button
2. Change game path
3. Change server URL
4. Click "OK"
5. Verify settings saved

**Expected:**
- ✅ Settings dialog opens
- ✅ Can browse for game path
- ✅ URLs auto-update when server URL changes
- ✅ Settings saved to `launcher_config.json`

### 3. Test Update Check

1. Ensure web server is running
2. Click "Check for Updates"
3. Watch status log

**Expected:**
- ✅ "Checking for updates..." appears
- ✅ Shows local and server versions
- ✅ Downloads patch if newer
- ✅ Progress bar updates

### 4. Test Patch Download

**Setup:**
1. Ensure server generated patch
2. Ensure `C:\xampp\htdocs\patches\latest\patch-Z.MPQ` exists
3. Delete local patch: `WoW\Data\patch-Z.MPQ`

**Test:**
1. Click "Check for Updates"
2. Should detect missing patch
3. Should download automatically

**Expected:**
- ✅ Detects missing patch
- ✅ Downloads from server
- ✅ Shows progress
- ✅ Places in `WoW\Data\patch-Z.MPQ`

### 5. Test Game Launch

**Setup:**
1. Ensure WoW is installed at configured path
2. Ensure `Wow.exe` exists

**Test:**
1. Click "Launch WoW"
2. Watch status

**Expected:**
- ✅ "Launching WoW..." appears
- ✅ WoW process starts
- ✅ "WoW launched successfully!" message

## 🐛 Debugging

### Launcher Won't Start

**Check:**
- Qt DLLs are in same folder as executable
- All dependencies are present
- Check Windows Event Viewer for errors

### Can't Connect to Server

**Check:**
- Apache is running
- URL is correct in settings
- Firewall isn't blocking
- Test URL in browser

### Patch Download Fails

**Check:**
- `patches/latest/patch-Z.MPQ` exists on server
- File permissions allow read
- URL is correct
- Network connection works

### Game Won't Launch

**Check:**
- Game path is correct
- `Wow.exe` exists at path
- Game is properly installed
- Check Windows Event Viewer

## 📝 Test Checklist

- [ ] Launcher builds successfully
- [ ] Launcher starts without errors
- [ ] Settings dialog works
- [ ] Settings are saved correctly
- [ ] Update check connects to server
- [ ] Patch version comparison works
- [ ] Patch download works
- [ ] Patch is placed correctly
- [ ] Game launch works
- [ ] All UI elements work
- [ ] Error messages are clear

## 🎯 Next Steps After Testing

1. **Fix any bugs found**
2. **Create installer** (optional)
3. **Distribute to players**
4. **Monitor for issues**

## ✅ Success Criteria

Launcher is ready when:
- ✅ Builds without errors
- ✅ All features work
- ✅ Connects to server
- ✅ Downloads patches
- ✅ Launches game
- ✅ No crashes or errors

