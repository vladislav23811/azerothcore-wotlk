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

#### Option 1: Server Only

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

#### Option 2: Server + Launcher Together

```powershell
# Navigate to project root
cd C:\servery\WOTLK-BOTS\azerothcore-wotlk

# Create build directory
mkdir build
cd build

# Configure with launcher enabled (requires Qt)
cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_LAUNCHER=ON

# Build (both server and launcher)
cmake --build . --config RelWithDebInfo

# Outputs:
# - build/bin/RelWithDebInfo/worldserver.exe
# - build/bin/RelWithDebInfo/WoWLauncher.exe
```

**Note**: If Qt is not found, the launcher build will be skipped automatically (server will still build).

## 🎨 Building the Launcher (Qt Application)

### Prerequisites
- CMake 3.15+
- Qt 5.15+ or Qt 6.x
- C++17 compiler
- Python 3 (for MPQ generation tool)

### Build Steps

#### Option 1: Standalone Build (Recommended for launcher-only)

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

#### Option 2: Integrated Build (with server)

See "Option 2" in the Server build section above. Use `-DBUILD_LAUNCHER=ON` when configuring.

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

Use the provided `build_all.ps1` script:

```powershell
# Run from project root
.\build_all.ps1
```

The script will:
1. Ask if you want to build launcher with server
2. Configure and build server (and launcher if enabled)
3. Optionally build launcher separately if Qt wasn't available during integrated build

**Manual commands** (if you prefer):

```powershell
# Build Server + Launcher together
cd build
cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_LAUNCHER=ON
cmake --build . --config RelWithDebInfo

# Or build launcher separately
cd tools\launcher\build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release
```

## 📦 Build Output Locations

### Server
- **Executables**: `build/bin/RelWithDebInfo/`
  - `worldserver.exe`
  - `authserver.exe`
- **Modules**: `build/bin/RelWithDebInfo/modules/`
  - `mod-progressive-systems.dll`

### Launcher
- **When built with server** (`-DBUILD_LAUNCHER=ON`):
  - **Executable**: `build/bin/RelWithDebInfo/WoWLauncher.exe`
  - **Qt DLLs**: Same folder (or use `windeployqt`)
- **When built standalone**:
  - **Executable**: `tools/launcher/build/Release/WoWLauncher.exe`
  - **Qt DLLs**: Same folder (or use `windeployqt`)

## ⚠️ Important Notes

1. **Integrated Build**: You can now build both together using `-DBUILD_LAUNCHER=ON`
2. **Standalone Build**: Launcher can still be built separately (recommended if Qt path is complex)
3. **Different Dependencies**: 
   - Server needs AzerothCore dependencies
   - Launcher needs Qt libraries (optional, won't fail server build if missing)
4. **Different Build Times**: 
   - Server: ~10-30 minutes (full rebuild)
   - Launcher: ~1-2 minutes (small project)
5. **Qt Detection**: If Qt is not found during integrated build, launcher is skipped automatically

## ✅ After Building

1. **Copy server files** to `release/` folder
2. **Copy launcher** to distribution folder
3. **Test both** independently
4. **Deploy** to players

## 🎯 Summary

- **Server**: Build in `build/` directory (main project)
- **Launcher**: 
  - **Integrated**: Build with server using `-DBUILD_LAUNCHER=ON` → `build/bin/RelWithDebInfo/WoWLauncher.exe`
  - **Standalone**: Build in `tools/launcher/build/` → `tools/launcher/build/Release/WoWLauncher.exe`
- **Both needed**: Server for game, Launcher for players
- **Flexibility**: Choose integrated or standalone based on your Qt setup

