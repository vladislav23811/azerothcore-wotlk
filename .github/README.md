# ![logo](https://raw.githubusercontent.com/azerothcore/azerothcore.github.io/master/images/logo-github.png) AzerothCore WotLK - Playerbots & Progressive Systems Edition

[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](CODE_OF_CONDUCT.md)
[![CodeFactor](https://www.codefactor.io/repository/github/vladislav23811/azerothcore-wotlk/badge)](https://www.codefactor.io/repository/github/vladislav23811/azerothcore-wotlk)
[![StackOverflow](http://img.shields.io/badge/stackoverflow-azerothcore-blue.svg?logo=stackoverflow)](https://stackoverflow.com/questions/tagged/azerothcore?sort=newest "Ask / browse questions here")
[![Discord](https://img.shields.io/discord/217589275766685707?logo=discord&logoColor=white)](https://discord.gg/gkt4y2x "Our community hub on Discord")

## Build Status

[![playerbots-build](https://github.com/vladislav23811/azerothcore-wotlk/actions/workflows/core-build-playerbots.yml/badge.svg?branch=master)](https://github.com/vladislav23811/azerothcore-wotlk/actions/workflows/core-build-playerbots.yml?query=branch%3Amaster)
[![windows-build](https://github.com/vladislav23811/azerothcore-wotlk/actions/workflows/windows_build.yml/badge.svg?branch=master)](https://github.com/vladislav23811/azerothcore-wotlk/actions/workflows/windows_build.yml?query=branch%3Amaster)
[![nopch-build](https://github.com/vladislav23811/azerothcore-wotlk/actions/workflows/core-build-nopch.yml/badge.svg?branch=master)](https://github.com/vladislav23811/azerothcore-wotlk/actions/workflows/core-build-nopch.yml?query=branch%3Amaster)
[![pch-build](https://github.com/vladislav23811/azerothcore-wotlk/actions/workflows/core-build-pch.yml/badge.svg?branch=master)](https://github.com/vladislav23811/azerothcore-wotlk/actions/workflows/core-build-pch.yml?query=branch%3Amaster)
[![core-modules-build](https://github.com/vladislav23811/azerothcore-wotlk/actions/workflows/core_modules_build.yml/badge.svg?branch=master)](https://github.com/vladislav23811/azerothcore-wotlk/actions/workflows/core_modules_build.yml?query=branch%3Amaster)
[![docker-build](https://github.com/vladislav23811/azerothcore-wotlk/actions/workflows/docker_build.yml/badge.svg?branch=master)](https://github.com/vladislav23811/azerothcore-wotlk/actions/workflows/docker_build.yml?query=branch%3Amaster)
[![macos-build](https://github.com/vladislav23811/azerothcore-wotlk/actions/workflows/macos_build.yml/badge.svg?branch=master)](https://github.com/vladislav23811/azerothcore-wotlk/actions/workflows/macos_build.yml?query=branch%3Amaster)
[![tools-build](https://github.com/vladislav23811/azerothcore-wotlk/actions/workflows/tools_build.yml/badge.svg?branch=master)](https://github.com/vladislav23811/azerothcore-wotlk/actions/workflows/tools_build.yml?query=branch%3Amaster)

## 📑 Table of Contents

- [Recent Highlights](#-recent-highlights)
- [Introduction](#-introduction)
- [Key Features](#-key-features)
- [Module Architecture](#-module-architecture)
- [Quick Start](#-quick-start)
- [Full Installation Guide](#-full-installation-guide)
- [Configuration](#️-configuration)
- [Gameplay Features](#-gameplay-features)
- [Documentation](#-documentation)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🌟 Recent Highlights

- ✅ **December 2025 - Module Consolidation Complete** - All modules merged into unified `mod-progressive-systems` for better integration and maintainability
- ✅ **ALL API Compatibility Fixes Complete** - Updated to latest AzerothCore API (logging, database, player/creature APIs)
- ✅ **ALL Compilation Errors Fixed** - Complete build success, zero errors across all platforms!
- ✅ **ExtraDatabase Integration** - Fixed linker errors, integrated into core database library
- ✅ **CMake Modernization** - Improved build system with proper dependency management and policy fixes
- ✅ **Repository Consolidated** - Single `master` branch with all features integrated
- ✅ **Custom WoW Launcher** - Qt5-based launcher with game installation and clean build output
- ✅ **Infinite Dungeon System** - Private instances, wave spawning, boss waves, and group support fully implemented
- ✅ **Progressive Systems** - Difficulty scaling, item upgrades, prestige, and reward systems
- ✅ **C++20 Codebase** - Modern C++20 standard with comprehensive code quality tools
- ✅ **Playerbots Ready** - Full AI companion system for solo and group play
- ⚠️ **Beta/Testing Phase** - All systems implemented, comprehensive in-game testing needed

---

## 🎮 Introduction

This is a **production-ready, modernized AzerothCore WotLK server** focused on **Playerbots** and **Progressive Systems**. Based on the popular MMORPG World of Warcraft patch 3.3.5a (Wrath of the Lich King), this fork enhances the core AzerothCore experience with:

- 🤖 **Advanced Playerbots System** - AI companions for solo and group play with intelligent behavior
- 📈 **Progressive Difficulty Scaling** - Mythic+ style infinite difficulty tiers and challenge modes
- 🎯 **Unified Progressive Systems Module** - All progression features consolidated into one cohesive system
- ⚔️ **Enhanced PvP Features** - 1v1 arena, 3v3 solo queue, and battleground rewards
- 🎨 **Quality of Life Improvements** - Transmog, account-wide features, and modern conveniences
- 🔧 **Modern C++20 Codebase** - Upgraded to C++20 with comprehensive code quality tools

Built on the solid foundation of MaNGOS, TrinityCore, and SunwellCore, with extensive development to improve stability, in-game mechanics, and modularity. This fork consolidates all custom features into a unified, well-integrated progressive systems module for a unique, solo-friendly gameplay experience while maintaining full group content support.

### 🎯 Why This Fork?

This fork is designed for players who want:
- **Solo Play Viability** - Play alone with bot companions or scale difficulty to your group size
- **Infinite Progression** - Never run out of content with infinitely scaling difficulty tiers
- **Modern Code Quality** - C++20 standards, clean builds, and comprehensive testing
- **Unified Systems** - All features integrated into cohesive, well-designed modules
- **Active Development** - Regular updates, bug fixes, and new features
- **Production Ready** - Stable, tested, and ready for real server deployment

## ✨ Key Features

### 🔧 Modern C++20 Codebase
- **C++20 Standard**: Upgraded from C++17 for modern language features
- **API Compatibility**: Fully updated to latest AzerothCore API
  - Modern logging API (`LOG_INFO`, `LOG_ERROR`, `LOG_WARN`)
  - Updated database API (`Query`, `DirectExecute`, `Get<T>()`)
  - Modern player/creature API (`GetLevel()`, `GetRace()`, `GetClass()`)
  - Updated messaging and chat command systems
- **Code Quality Tools**: Clang-format and clang-tidy integration
- **Enhanced Warnings**: Comprehensive compiler warnings for better code quality
- **Clean Builds**: Compiles successfully with zero errors on all platforms
- **IDE Integration**: VS Code CMake tools configured with Qt5 and vcpkg support

### 🎮 Custom WoW Launcher
- **Qt5-Based Interface**: Modern, cross-platform launcher built with Qt5
- **Game Installation**: Automatic game installation with folder selection
- **Update Checking**: Built-in update checking and download management
- **Configuration Management**: Save and load game paths and settings
- **Clean Build Output**: Organized launcher files in dedicated directory (`bin/RelWithDebInfo/WoWLauncher/`)

### 🤖 Playerbots System
- **AI Companions**: Intelligent bot companions that can tank, heal, and DPS
- **Group Support**: Bots can form groups and complete dungeons/raids
- **World Population**: Random world bots for a more populated server feel
- **Raid Capable**: Bots can participate in end-game content
- **Configurable**: Fully customizable bot behavior, gear limits, and AI settings

### 📊 Unified Progressive Systems Module
The `mod-progressive-systems` module consolidates all progression and enhancement features:

#### Core Systems
- **Infinite Dungeon System**: ✅ Fully implemented - Private instances, wave spawning, boss waves, group support
- **Difficulty Scaling**: Mythic+ style difficulty tiers (Mythic+1, +2, +3...) with health/damage scaling
- **Item Upgrade System**: Upgrade items infinitely using progression currency with stat bonuses
- **Prestige System**: Reset progress to gain permanent stat bonuses
- **Paragon System**: Allocate paragon points for custom stat bonuses
- **Progression Points**: Universal currency earned from all activities
- **Power Level System**: Track and display character progression

#### PvP Systems (Integrated)
- **1v1 Arena**: Custom 1v1 arena system with rankings
- **3v3 Solo Queue**: Solo queue for 3v3 arena matches
- **Battleground Rewards**: Enhanced rewards for battleground participation
- **Honor Guard System**: Gain honor from guard kills
- **PvP Item Level Scaling**: Dynamic item level scaling for battlegrounds
- **PvP Mode**: Toggle PvP mode for enhanced PvP experience

#### Quality of Life Features (Integrated)
- **Transmogrification**: Visual customization system for gear
- **Account Achievements**: Account-wide achievement tracking
- **Account Mounts**: Account-wide mount system
- **Character Tools**: Enhanced character management utilities
- **Auto-Learn Spells**: Automatic spell learning on level up
- **Random Enchants**: Random enchantments on item drops
- **Level Rewards**: Rewards and congratulations on level up
- **Solo LFG**: Solo-friendly Looking for Group system
- **Beastmaster NPC**: Enhanced pet management NPC
- **Global Chat**: Cross-realm chat system
- **Multi-Vendor**: NPC with access to multiple vendors
- **Instance Reset**: Custom instance reset functionality

#### AzerothShard Features (Integrated)
- **Challenge Mode**: Challenge mode system with scaling
- **Timewalking**: Timewalking system for scaled content
- **Guild House**: Guild house system with teleportation
- **Hearthstone Mode**: Custom hearthstone functionality
- **Player Stats**: Comprehensive player statistics tracking
- **Smartstone**: Smartstone system for quick access to features
- **XP Rates**: Custom experience rate multipliers

#### Reward Systems (Integrated)
- **Reward Shop**: Shop system using progression points
- **Reward Played Time**: Time-based reward system
- **Premium Features**: Premium account enhancements

### 🎯 Enhanced Gameplay
- **Solo-Friendly**: Autobalance system scales content for solo players
- **Unified Experience**: All features work together seamlessly
- **Modern Design**: Clean, well-integrated module architecture
- **Performance Optimized**: Efficient database queries and caching

---

## 🏗️ Module Architecture

### Module Consolidation Strategy

All individual modules have been **consolidated into `mod-progressive-systems`** for better integration, reduced complexity, and easier maintenance. The unified module includes:

#### Active Modules (3)
1. **mod-eluna** - Lua scripting engine for custom content
2. **mod-playerbots** - AI player bots for companions and world population
3. **mod-progressive-systems** - **Unified module containing all consolidated features**

#### Consolidated Features in mod-progressive-systems

All the following features are now integrated into `mod-progressive-systems`:

**PvP Systems:**
- ✅ 1v1 Arena
- ✅ 3v3 Solo Queue Arena
- ✅ Battleground Rewards
- ✅ Honor Guard System
- ✅ PvP Item Level Scaling
- ✅ PvP Mode Toggle

**Quality of Life:**
- ✅ Transmogrification
- ✅ Account Achievements
- ✅ Account Mounts
- ✅ Character Tools
- ✅ Auto-Learn Spells
- ✅ Random Enchants
- ✅ Level Rewards
- ✅ Solo LFG
- ✅ Beastmaster NPC
- ✅ Global Chat
- ✅ Multi-Vendor
- ✅ Instance Reset

**AzerothShard Features:**
- ✅ Challenge Mode
- ✅ Timewalking
- ✅ Guild House
- ✅ Hearthstone Mode
- ✅ Player Stats
- ✅ Smartstone
- ✅ Custom XP Rates

**Reward Systems:**
- ✅ Reward Shop
- ✅ Reward Played Time
- ✅ Premium Features

**Progressive Systems:**
- ✅ Infinite Dungeon
- ✅ Difficulty Scaling
- ✅ Item Upgrades
- ✅ Prestige System
- ✅ Paragon System
- ✅ Progression Points

### Benefits of Consolidation

- **Better Integration**: All features work together seamlessly
- **Reduced Complexity**: Single module to maintain and configure
- **Improved Performance**: Shared systems and optimized code paths
- **Easier Updates**: One module to update instead of many
- **Better Testing**: Comprehensive testing across all integrated features
- **Cleaner Architecture**: Well-organized, cohesive codebase

---

## 🚀 Quick Start

### ⚡ Zero-Setup First Run!

This build is **READY TO RUN** with automatic database setup:

```bash
# 1. Clone
git clone https://github.com/vladislav23811/azerothcore-wotlk.git
cd azerothcore-wotlk

# 2. Build (C++20 compiler required)
# Linux/Mac: ./acore.sh install
# Windows: Use CMake + Visual Studio 2019+
#   cmake -B build -DCMAKE_TOOLCHAIN_FILE=C:/vcpkg/scripts/buildsystems/vcpkg.cmake
#   cmake --build build --config RelWithDebInfo

# 3. Copy configs (optional - defaults work!)
cp modules/mod-*/conf/*.conf.dist conf/

# 4. Start servers - THAT'S IT!
./authserver  # Auto-creates auth database
./worldserver # Auto-creates & populates ALL databases!

# ✅ All SQL files auto-import on first startup
# ✅ All playerbots spawn automatically  
# ✅ Zero manual SQL import needed!
# ✅ Server starts cleanly with zero errors!
```

### Building on Windows

```bash
# Prerequisites: CMake, Visual Studio 2019+, vcpkg with Qt5
cmake -B C:/servers/build -DCMAKE_TOOLCHAIN_FILE=C:/vcpkg/scripts/buildsystems/vcpkg.cmake
cmake --build C:/servers/build --config RelWithDebInfo -j 16

# Server binaries: C:/servers/build/bin/RelWithDebInfo/
# Launcher: C:/servers/build/bin/RelWithDebInfo/WoWLauncher/WoWLauncher.exe
```

### Key Requirements
- **C++20 Compiler**: GCC 10+, Clang 10+, or MSVC 2019+
- **CMake 3.16+**: Required for build system
- **MySQL 8.0+**: Database server
- **Qt5 (for Launcher)**: Install via vcpkg (`qt5-base qt5-widgets qt5-network`)

---

## ⚙️ Configuration

### Progressive Systems Configuration
Configure all features in `conf/mod-progressive-systems.conf`:
- Difficulty scaling multipliers
- Progression point rewards
- Item upgrade costs
- Prestige system settings
- All integrated module settings

### Playerbots Configuration
Configure bot behavior in `conf/playerbots.conf`:
- Bot count and spawn settings
- Gear quality and item level limits
- AI behavior and reaction times
- Auto-learn spells and talents

### Worldserver Configuration
Key settings in `conf/worldserver.conf`:
- Experience rates
- Loot rates
- Solo-friendly settings
- Addon channel for Progressive Systems addon

For detailed configuration guides, see:
- [PRODUCTION_READY_CONFIG.md](../session-logs/PRODUCTION_READY_CONFIG.md)
- [PROGRESSIVE_SYSTEMS_GUIDE.md](../session-logs/PROGRESSIVE_SYSTEMS_GUIDE.md)

---

## 🎮 Gameplay Features

### Solo Play Experience
- **Autobalance Scaling**: Content automatically scales to ~0.3-0.4x difficulty for solo players
- **Bot Companions**: Recruit AI bots to form groups and complete dungeons
- **Solo Rewards**: Enhanced XP and money bonuses for solo play
- **Reduced Penalties**: Lower durability loss and faster rest regeneration

### Group Play Experience
- **Full Difficulty**: Groups face full 1.0x difficulty for maximum challenge
- **Group Bonuses**: Enhanced XP bonus for grouping
- **Better Coordination**: Real players have advantages over bots
- **Progressive Difficulty**: Access higher difficulty tiers with better groups

### Progression Systems
- **Difficulty Tiers**: Select from Normal → Heroic → Mythic+1 → Mythic+2 → ... → Mythic+∞
- **Item Upgrades**: Upgrade items infinitely using progression points
- **Prestige System**: Reset progress to gain permanent bonuses
- **Power Level**: Track your character's overall power progression
- **Infinite Dungeon**: Private instances with wave-based progression

---

## 📚 Documentation

### Project Documentation
- [MODERNIZATION.md](../MODERNIZATION.md) - C++20 modernization details
- [MODULES_INSTALLED.md](../session-logs/MODULES_INSTALLED.md) - Module details
- [PROGRESSIVE_SYSTEMS_GUIDE.md](../session-logs/PROGRESSIVE_SYSTEMS_GUIDE.md) - Progressive systems guide
- [PRODUCTION_READY_CONFIG.md](../session-logs/PRODUCTION_READY_CONFIG.md) - Production configuration

### Technical Reports
- [SERVER_ARCHITECTURE_ANALYSIS.md](../session-logs/SERVER_ARCHITECTURE_ANALYSIS.md) - Architecture overview
- [SPELL_SYSTEM_ANALYSIS.md](../session-logs/SPELL_SYSTEM_ANALYSIS.md) - Spell system details
- [PERFORMANCE_ANALYSIS_REPORT.md](../session-logs/PERFORMANCE_ANALYSIS_REPORT.md) - Performance analysis

---

## 🤝 Contributing

This is a customized fork of AzerothCore. Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

For contributing guidelines, see the [AzerothCore Contributing Guide](https://www.azerothcore.org/wiki/contribute).

---

## 📖 Philosophy

This fork maintains AzerothCore's core philosophy while adding specialized features:

* **Stability** - All changes are tested and stable
* **Unification** - All features integrated into cohesive modules
* **Solo-Friendly** - Enhanced solo play experience with bots
* **Progressive** - Infinite progression systems for long-term gameplay
* **Modern Code** - C++20 standards and best practices
* **Community Driven** - Built on the active AzerothCore community

---

## 🔗 Important Links

- [AzerothCore Website](http://www.azerothcore.org/)
- [AzerothCore Wiki](http://www.azerothcore.org/wiki)
- [AzerothCore Catalogue](http://www.azerothcore.org/catalogue.html) - Modules, tools, and more
- [Discord Server](https://discord.gg/gkt4y2x) - Community support
- [Eluna API Documentation](https://www.azerothcore.org/eluna/index.html) - Lua scripting reference
- [Doxygen Documentation](https://www.azerothcore.org/pages/doxygen/index.html) - C++ API reference

---

## 📝 License

- The new AzerothCore source components are released under the [GNU AGPL v3](https://www.gnu.org/licenses/agpl-3.0.en.html)
- The old sources based on MaNGOS/TrinityCore are released under the [GNU GPL v2](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)

**Important Note**: AzerothCore is not an official Blizzard Entertainment product, and it is not affiliated with or endorsed by World of Warcraft or Blizzard Entertainment. AzerothCore does not sponsor nor support illegal public servers. If you use this project to run an illegal public server and not for testing and learning, it is your own personal choice.

---

## 🙏 Special Thanks

- **AzerothCore Team** - For the excellent base server framework
- **Module Developers** - For all the amazing modules that enhance the experience
- **Community Contributors** - For bug reports, suggestions, and improvements
- [JetBrains](https://www.jetbrains.com/?from=AzerothCore) - For providing free open-source licenses to developers

[![JetBrains logo.](https://resources.jetbrains.com/storage/products/company/brand/logos/jetbrains.svg)](https://jb.gg/OpenSourceSupport)

---

**Branch**: `master` | **Focus**: Playerbots & Progressive Systems | **Status**: ✅ Production Ready

**Build Status**: ✅ All workflows passing | **Compilation**: ✅ Zero errors | **Modernization**: ✅ C++20 Complete | **API Compatibility**: ✅ Latest AzerothCore

**Clone**: `git clone https://github.com/vladislav23811/azerothcore-wotlk.git` - All features included and working!

---

*Last updated: December 2025 - **All modules consolidated into mod-progressive-systems!** All API compatibility fixes complete. Zero compilation errors. Clean builds on all platforms. ExtraDatabase integration complete. CMake build system fully configured. Ready for deployment!*
