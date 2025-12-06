# Complete Build Guide - Server + Launcher

## 📋 Overview

The **server** (AzerothCore) and **launcher** (Qt application) are **separate projects** and need to be built separately.

## 🔧 Building the Server (AzerothCore)

### Prerequisites
- CMake 3.15+
- Visual Studio 2019+ (Windows) or GCC 7+ (Linux)
- MySQL development libraries
- OpenSSL
- All AzerothCore dependencies

### Build Steps

```powershell
# Navigate to project root
cd C:\servery\WOTLK-BOTS\azerothcore-wotlk

# Create build directory
mkdir build
cd build

# Configure (adjust paths as needed)
cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo

# Build
cmake --build . --config RelWithDebInfo

# Output: build/bin/RelWithDebInfo/worldserver.exe
```

## 🎨 Building the Launcher (Qt Application)

### Prerequisites
- CMake 3.15+
- Qt 5.15+ or Qt 6.x
- C++17 compiler
- Python 3 (for MPQ generation tool)

### Build Steps

```powershell
# Navigate to launcher directory
cd C:\servery\WOTLK-BOTS\azerothcore-wotlk\tools\launcher

# Create build directory
mkdir build
cd build

# Configure (adjust Qt path if needed)
cmake .. -DCMAKE_BUILD_TYPE=Release

# Build
cmake --build . --config Release

# Output: build/Release/WoWLauncher.exe
```

### Using vcpkg (Recommended)

```powershell
# Install Qt via vcpkg
vcpkg install qt5-base qt5-widgets qt5-network

# Configure with vcpkg toolchain
cmake .. -DCMAKE_TOOLCHAIN_FILE=[vcpkg root]/scripts/buildsystems/vcpkg.cmake

# Build
cmake --build . --config Release
```

## 🚀 Quick Build Script

Create `build_all.ps1`:

```powershell
# Build Server
Write-Host "Building AzerothCore server..." -ForegroundColor Cyan
cd C:\servery\WOTLK-BOTS\azerothcore-wotlk
if (-not (Test-Path build)) { mkdir build }
cd build
cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build . --config RelWithDebInfo

# Build Launcher
Write-Host "`nBuilding Qt launcher..." -ForegroundColor Cyan
cd ..\tools\launcher
if (-not (Test-Path build)) { mkdir build }
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release

Write-Host "`n✅ Build complete!" -ForegroundColor Green
Write-Host "Server: C:\servery\WOTLK-BOTS\azerothcore-wotlk\build\bin\RelWithDebInfo\worldserver.exe" -ForegroundColor White
Write-Host "Launcher: C:\servery\WOTLK-BOTS\azerothcore-wotlk\tools\launcher\build\Release\WoWLauncher.exe" -ForegroundColor White
```

## 📦 Build Output Locations

### Server
- **Executables**: `build/bin/RelWithDebInfo/`
  - `worldserver.exe`
  - `authserver.exe`
- **Modules**: `build/bin/RelWithDebInfo/modules/`
  - `mod-progressive-systems.dll`

### Launcher
- **Executable**: `tools/launcher/build/Release/WoWLauncher.exe`
- **Qt DLLs**: Same folder (or use `windeployqt`)

## ⚠️ Important Notes

1. **Separate Builds**: Server and launcher are independent projects
2. **Different Dependencies**: 
   - Server needs AzerothCore dependencies
   - Launcher needs Qt libraries
3. **Different Build Times**: 
   - Server: ~10-30 minutes (full rebuild)
   - Launcher: ~1-2 minutes (small project)

## ✅ After Building

1. **Copy server files** to `release/` folder
2. **Copy launcher** to distribution folder
3. **Test both** independently
4. **Deploy** to players

## 🎯 Summary

- **Server**: Build in `build/` directory (main project)
- **Launcher**: Build in `tools/launcher/build/` directory (separate project)
- **Both needed**: Server for game, Launcher for players

