# WoW Launcher - C++ Qt GUI Application

A professional, modern launcher with a beautiful GUI built using Qt.

## Features

- ✅ **Modern GUI** - Dark theme, professional design
- ✅ **Progress Tracking** - Real-time download progress
- ✅ **Status Logging** - Detailed activity log
- ✅ **Auto-Updates** - Checks and downloads patches automatically
- ✅ **Game Launch** - One-click game launch
- ✅ **Settings** - Configurable paths and URLs

## Requirements

### Build Requirements
- CMake 3.15 or higher
- Qt 5.15+ or Qt 6.x
- C++17 compatible compiler (MSVC 2019+, GCC 7+, Clang 8+)

### Runtime Requirements
- Windows 10/11 (or Linux/Mac with Qt)
- Qt runtime libraries (included in build)

## Building

### Windows (Visual Studio)

```bash
# Install Qt (download from qt.io or use vcpkg)
# Set Qt5_DIR or Qt6_DIR environment variable

mkdir build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release
```

### Using vcpkg (Recommended)

```bash
# Install Qt via vcpkg
vcpkg install qt5-base qt5-widgets qt5-network

# Configure CMake
cmake .. -DCMAKE_TOOLCHAIN_FILE=[vcpkg root]/scripts/buildsystems/vcpkg.cmake
```

### Linux

```bash
# Install Qt via package manager
sudo apt-get install qt6-base-dev qt6-widgets-dev qt6-network-dev

# Build
mkdir build && cd build
cmake ..
make
```

## Configuration

The launcher reads from `launcher_config.json` (same format as Python launcher):

```json
{
    "server_url": "http://localhost",
    "game_zip_url": "http://localhost/WOTLKHD.zip",
    "patch_version_url": "http://localhost/patches/version.txt",
    "patch_download_url": "http://localhost/patches/latest/patch-Z.MPQ",
    "wow_path": "C:/WoW",
    "wow_exe": "Wow.exe"
}
```

## Usage

1. **Build the launcher** (see above)
2. **Configure** `launcher_config.json` with your server URL
3. **Run** the launcher executable
4. **Click "Launch WoW"** - that's it!

## UI Features

- **Status Panel** - Shows current operation and progress
- **Activity Log** - Detailed log of all operations
- **Game Info** - Displays game path, patch version, status
- **Update Button** - Manually check for updates
- **Settings Button** - Configure launcher (coming soon)

## Distribution

### Windows
- Copy `WoWLauncher.exe` and Qt DLLs to distribution folder
- Or create installer using Qt Installer Framework

### Include Qt DLLs
The launcher needs these Qt DLLs (for Windows):
- `Qt6Core.dll` (or `Qt5Core.dll`)
- `Qt6Widgets.dll` (or `Qt5Widgets.dll`)
- `Qt6Network.dll` (or `Qt5Network.dll`)
- `Qt6Gui.dll` (or `Qt5Gui.dll`)

Or use `windeployqt` tool:
```bash
windeployqt WoWLauncher.exe
```

## Screenshots

*Dark theme, modern design, professional appearance*

## Future Enhancements

- [ ] Settings dialog (GUI)
- [ ] Game installation from ZIP
- [ ] Missing file detection
- [ ] Multiple server support
- [ ] Auto-update launcher itself
- [ ] News/announcements panel
- [ ] Remember me / auto-login

## License

Same as main project.

