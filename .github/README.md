# ![logo](https://raw.githubusercontent.com/azerothcore/azerothcore.github.io/master/images/logo-github.png) AzerothCore WotLK - Playerbots & Progressive Systems Edition

[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](CODE_OF_CONDUCT.md)
[![CodeFactor](https://www.codefactor.io/repository/github/vladislav23811/azerothcore-wotlk/badge)](https://www.codefactor.io/repository/github/vladislav23811/azerothcore-wotlk)
[![StackOverflow](http://img.shields.io/badge/stackoverflow-azerothcore-blue.svg?logo=stackoverflow)](https://stackoverflow.com/questions/tagged/azerothcore?sort=newest "Ask / browse questions here")
[![Discord](https://img.shields.io/discord/217589275766685707?logo=discord&logoColor=white)](https://discord.gg/gkt4y2x "Our community hub on Discord")

## Build Status

[![playerbots-build](https://github.com/vladislav23811/azerothcore-wotlk/actions/workflows/core-build-playerbots.yml/badge.svg?branch=playerbotwithall)](https://github.com/vladislav23811/azerothcore-wotlk/actions/workflows/core-build-playerbots.yml?query=branch%3Aplayerbotwithall)
[![windows-build](https://github.com/vladislav23811/azerothcore-wotlk/actions/workflows/windows_build.yml/badge.svg?branch=playerbotwithall)](https://github.com/vladislav23811/azerothcore-wotlk/actions/workflows/windows_build.yml?query=branch%3Aplayerbotwithall)
[![nopch-build](https://github.com/vladislav23811/azerothcore-wotlk/actions/workflows/core-build-nopch.yml/badge.svg?branch=playerbotwithall)](https://github.com/vladislav23811/azerothcore-wotlk/actions/workflows/core-build-nopch.yml?query=branch%3Aplayerbotwithall)
[![pch-build](https://github.com/vladislav23811/azerothcore-wotlk/actions/workflows/core-build-pch.yml/badge.svg?branch=playerbotwithall)](https://github.com/vladislav23811/azerothcore-wotlk/actions/workflows/core-build-pch.yml?query=branch%3Aplayerbotwithall)
[![core-modules-build](https://github.com/vladislav23811/azerothcore-wotlk/actions/workflows/core_modules_build.yml/badge.svg?branch=playerbotwithall)](https://github.com/vladislav23811/azerothcore-wotlk/actions/workflows/core_modules_build.yml?query=branch%3Aplayerbotwithall)
[![docker-build](https://github.com/vladislav23811/azerothcore-wotlk/actions/workflows/docker_build.yml/badge.svg?branch=playerbotwithall)](https://github.com/vladislav23811/azerothcore-wotlk/actions/workflows/docker_build.yml?query=branch%3Aplayerbotwithall)
[![macos-build](https://github.com/vladislav23811/azerothcore-wotlk/actions/workflows/macos_build.yml/badge.svg?branch=playerbotwithall)](https://github.com/vladislav23811/azerothcore-wotlk/actions/workflows/macos_build.yml?query=branch%3Aplayerbotwithall)
[![tools-build](https://github.com/vladislav23811/azerothcore-wotlk/actions/workflows/tools_build.yml/badge.svg?branch=playerbotwithall)](https://github.com/vladislav23811/azerothcore-wotlk/actions/workflows/tools_build.yml?query=branch%3Aplayerbotwithall)

## 🎮 Introduction

This is a **customized AzerothCore WotLK server** focused on **Playerbots** and **Progressive Systems**. Based on the popular MMORPG World of Warcraft patch 3.3.5a, this fork enhances the core AzerothCore experience with:

- 🤖 **Advanced Playerbots System** - AI companions for solo and group play
- 📈 **Progressive Difficulty Scaling** - Infinite difficulty tiers and challenge modes
- 🎯 **Custom Progression Systems** - Item upgrades, prestige, and reward points
- ⚔️ **Enhanced PvP Features** - 1v1 arena, solo queue, and battleground rewards
- 🎨 **Quality of Life Improvements** - Transmog, account-wide features, and more

The original code is based on MaNGOS, TrinityCore, and SunwellCore, with extensive development to improve stability, in-game mechanics, and modularity. This fork adds specialized modules and configurations for a unique gameplay experience.

## ✨ Key Features

### 🤖 Playerbots System
- **AI Companions**: Intelligent bot companions that can tank, heal, and DPS
- **Group Support**: Bots can form groups and complete dungeons/raids
- **World Population**: Random world bots for a more populated server feel
- **Raid Capable**: Bots can participate in end-game content
- **Configurable**: Fully customizable bot behavior, gear limits, and AI settings

### 📊 Progressive Systems
- **Infinite Difficulty Scaling**: Mythic+ style difficulty tiers (Mythic+1, +2, +3...)
- **Dynamic Item Upgrades**: Upgrade items infinitely using progression currency
- **Prestige System**: Reset and gain permanent bonuses
- **Challenge Modes**: Time-based challenges with leaderboards
- **Progression Points**: Universal currency earned from all activities
- **Power Level System**: Track and display character progression

### 🎯 Enhanced Gameplay
- **Solo-Friendly**: Autobalance system scales content for solo players
- **Account-Wide Features**: Shared achievements, mounts, and more
- **Reward Systems**: Multiple reward point systems for different activities
- **Custom Content**: AzerothShard features including Challenge Mode and Timewalking

## 📦 Installed Modules (22+ Modules)

### Core Systems
- ✅ **mod-eluna** - Lua scripting engine for custom content
- ✅ **mod-autobalance** - Dynamic difficulty scaling based on group size
- ✅ **mod-azerothshard** - Advanced features (Challenge Mode, Mythic+, Timewalking, etc.)
- ✅ **mod-progressive-systems** - Custom progression and difficulty systems

### AI & Automation
- ✅ **mod-playerbots** - AI player bots for companions and world population

### PvP & Arena
- ✅ **mod-1v1-arena** - 1v1 Arena PvP system
- ✅ **mod-arena-3v3-solo-queue** - Solo queue for 3v3 arena
- ✅ **mod-bg-reward** - Battleground rewards system
- ✅ **mod-gain-honor-guard** - Honor from guard kills

### Progression & Rewards
- ✅ **mod-reward-shop** - Reward point shop system
- ✅ **mod-reward-played-time** - Time-based rewards
- ✅ **mod-account-achievements** - Account-wide achievements
- ✅ **mod-congrats-on-level** - Level up rewards

### Quality of Life
- ✅ **mod-transmog** - Visual customization system
- ✅ **mod-premium** - Premium account features
- ✅ **mod-character-tools** - Character management tools
- ✅ **mod-account-mounts** - Account-wide mount system
- ✅ **mod-instance-reset** - Instance reset functionality
- ✅ **mod-learn-spells** - Auto-learn spells system
- ✅ **mod-solo-lfg** - Solo Looking for Group system
- ✅ **mod-npc-beastmaster** - Beastmaster NPC for pet management

### Item Enhancement
- ✅ **mod-random-enchants** - Random enchantments on items

For detailed module information, see [MODULES_INSTALLED.md](../MODULES_INSTALLED.md) and [FINAL_MODULES_SUMMARY.md](../FINAL_MODULES_SUMMARY.md).

## 🚀 Installation

### Prerequisites
- Windows, Linux, or macOS
- CMake 3.16+
- C++17 compatible compiler (GCC 7+, Clang 5+, MSVC 2019+)
- MySQL 5.7+ or MariaDB 10.3+
- OpenSSL 1.0.x or 1.1.x

### Quick Start

1. **Clone the repository:**
   ```bash
   git clone https://github.com/vladislav23811/azerothcore-wotlk.git
   cd azerothcore-wotlk
   ```

2. **Install dependencies and build:**
   ```bash
   # Linux/macOS
   ./acore.sh install
   
   # Windows
   # Use the provided installer or follow the wiki guide
   ```

3. **Configure modules:**
   ```bash
   # Copy module configuration files
   cp modules/mod-*/conf/*.conf.dist conf/
   # Edit configuration files as needed
   ```

4. **Apply database updates:**
   ```bash
   # Follow standard AzerothCore database setup
   # Apply any module-specific SQL files from modules/*/data/sql/
   ```

5. **Start the server:**
   ```bash
   ./acore.sh start
   ```

For detailed installation instructions, see the [AzerothCore Installation Guide](http://www.azerothcore.org/wiki/installation).

## ⚙️ Configuration

### Playerbots Configuration
Configure bot behavior in `conf/playerbots.conf`:
- Bot count and spawn settings
- Gear quality and item level limits
- AI behavior and reaction times
- Auto-learn spells and talents

### Progressive Systems Configuration
Configure progression features in `conf/mod-progressive-systems.conf`:
- Difficulty scaling multipliers
- Progression point rewards
- Item upgrade costs
- Prestige system settings

### Worldserver Configuration
Key settings in `conf/worldserver.conf`:
- Experience rates (2x XP from kills, 1.5x from quests)
- Loot rates (enhanced rare/epic drops)
- Solo-friendly settings (reduced durability loss, faster rest)
- Addon channel enabled for Progressive Systems addon

For detailed configuration guides, see:
- [PRODUCTION_READY_CONFIG.md](../PRODUCTION_READY_CONFIG.md)
- [PROGRESSIVE_SYSTEMS_GUIDE.md](../PROGRESSIVE_SYSTEMS_GUIDE.md)

## 🎮 Gameplay Features

### Solo Play Experience
- **Autobalance Scaling**: Content automatically scales to ~0.3-0.4x difficulty for solo players
- **Bot Companions**: Recruit AI bots to form groups and complete dungeons
- **Solo Rewards**: 1.2x XP and money bonus for solo play
- **Reduced Penalties**: Lower durability loss and faster rest regeneration

### Group Play Experience
- **Full Difficulty**: Groups face full 1.0x difficulty for maximum challenge
- **Group Bonuses**: 1.2x XP bonus for grouping
- **Better Coordination**: Real players have advantages over bots
- **Progressive Difficulty**: Access higher difficulty tiers with better groups

### Progression Systems
- **Difficulty Tiers**: Select from Normal → Heroic → Mythic+1 → Mythic+2 → ... → Mythic+∞
- **Item Upgrades**: Upgrade items infinitely using progression points
- **Prestige System**: Reset progress to gain permanent bonuses
- **Power Level**: Track your character's overall power progression

## 📚 Documentation

- [MODULES_INSTALLED.md](../MODULES_INSTALLED.md) - Complete module list and descriptions
- [PROGRESSIVE_SYSTEMS_GUIDE.md](../PROGRESSIVE_SYSTEMS_GUIDE.md) - Progressive systems implementation guide
- [PRODUCTION_READY_CONFIG.md](../PRODUCTION_READY_CONFIG.md) - Production configuration settings
- [MODULE_CONFIGURATION_GUIDE.md](../modules/MODULE_CONFIGURATION_GUIDE.md) - Module configuration guide

## 🤝 Contributing

This is a customized fork of AzerothCore. Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

For contributing guidelines, see the [AzerothCore Contributing Guide](https://www.azerothcore.org/wiki/contribute).

## 📖 Philosophy

This fork maintains AzerothCore's core philosophy while adding specialized features:

* **Stability** - All changes are tested and stable
* **Customization** - Extensive module system for easy customization
* **Solo-Friendly** - Enhanced solo play experience with bots
* **Progressive** - Infinite progression systems for long-term gameplay
* **Community Driven** - Built on the active AzerothCore community

## 🔗 Important Links

- [AzerothCore Website](http://www.azerothcore.org/)
- [AzerothCore Wiki](http://www.azerothcore.org/wiki)
- [AzerothCore Catalogue](http://www.azerothcore.org/catalogue.html) - Modules, tools, and more
- [Discord Server](https://discord.gg/gkt4y2x) - Community support
- [Eluna API Documentation](https://www.azerothcore.org/eluna/index.html) - Lua scripting reference
- [Doxygen Documentation](https://www.azerothcore.org/pages/doxygen/index.html) - C++ API reference

## 📝 License

- The new AzerothCore source components are released under the [GNU AGPL v3](https://www.gnu.org/licenses/agpl-3.0.en.html)
- The old sources based on MaNGOS/TrinityCore are released under the [GNU GPL v2](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)

**Important Note**: AzerothCore is not an official Blizzard Entertainment product, and it is not affiliated with or endorsed by World of Warcraft or Blizzard Entertainment. AzerothCore does not sponsor nor support illegal public servers. If you use this project to run an illegal public server and not for testing and learning, it is your own personal choice.

## 🙏 Special Thanks

- **AzerothCore Team** - For the excellent base server framework
- **Module Developers** - For all the amazing modules that enhance the experience
- **Community Contributors** - For bug reports, suggestions, and improvements
- [JetBrains](https://www.jetbrains.com/?from=AzerothCore) - For providing free open-source licenses to developers

[![JetBrains logo.](https://resources.jetbrains.com/storage/products/company/brand/logos/jetbrains.svg)](https://jb.gg/OpenSourceSupport)

---

**Branch**: `playerbotwithall` | **Focus**: Playerbots & Progressive Systems | **Status**: Active Development

---
*Last updated: Workflows configured for automatic builds*
