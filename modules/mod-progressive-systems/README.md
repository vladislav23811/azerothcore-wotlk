# Progressive Systems Module

**Infinite Progression System for AzerothCore WOTLK**

A comprehensive, modular progression system that allows players to continuously grow stronger through difficulty scaling, item upgrades, prestige, and more - all server-side only!

## Features

- **Infinite Difficulty Scaling** - Mythic+ style scaling for all instances
- **Item Upgrade System** - Upgrade any item infinitely using progression points
- **Prestige System** - Reset for permanent bonuses
- **Progression Points** - Earn points from kills, scaled by tier and difficulty
- **Infinite Dungeon** - Endless challenge mode
- **Reward Shop** - Purchase items with progression points
- **Power Level System** - Track overall character power
- **Seasonal Resets** - Optional seasonal progression

## Installation

1. **Copy the module** to your `modules/` directory
2. **Run SQL files** in order:
   - `data/sql/characters/base/character_progression_unified.sql`
   - `data/sql/characters/base/progressive_systems.sql`
   - `data/sql/world/base/difficulty_scaling.sql`
3. **Copy config file**:
   ```bash
   cp mod-progressive-systems.conf.dist worldserver.conf.dist
   # Edit worldserver.conf and configure settings
   ```
4. **Rebuild AzerothCore**:
   ```bash
   mkdir build && cd build
   cmake .. -DCMAKE_INSTALL_PREFIX=~/azeroth-server
   make -j$(nproc)
   make install
   ```
5. **Copy Lua scripts** to your Eluna scripts directory
6. **Restart server**

## Configuration

### Server Config (`worldserver.conf`)

All settings are in the `[ProgressiveSystems]` section. See `mod-progressive-systems.conf.dist` for all options.

### Lua Config (`lua_scripts/config.lua`)

Easy-to-modify Lua configuration file with:
- NPC entries
- Currency items
- Point values
- Tier multipliers
- Difficulty settings
- Upgrade costs
- Prestige bonuses
- Reward shop items

**This is the easiest way to customize the system!**

## NPCs

Spawn these NPCs in your world (default entries):

- **190000** - Main Menu NPC (Progressive Systems hub)
- **190001** - Item Upgrade NPC
- **190002** - Prestige NPC
- **190003** - Difficulty Selector NPC
- **190004** - Reward Shop NPC
- **190005** - Infinite Dungeon NPC

## Database Tables

### Character Tables
- `character_progression_unified` - Main progression tracking
- `character_progression` - Additional progression data
- `character_prestige` - Prestige system data
- `character_stat_enhancements` - Permanent stat upgrades
- `item_upgrades` - Item upgrade levels
- `infinite_dungeon_progress` - Infinite dungeon progress
- `seasonal_progress` - Seasonal tracking

### World Tables
- `custom_difficulty_scaling` - Difficulty scaling configuration per map

## How It Works

### Progression Points
- Earned from killing creatures (scaled by type and difficulty)
- Multiplied by your current tier (5x, 15x, 30x, etc.)
- Can be spent on item upgrades, stat enhancements, and shop items

### Difficulty Scaling
- Set difficulty tier per character
- Creatures in instances scale HP/Damage based on tier
- Higher difficulty = more points and better loot

### Item Upgrades
- Upgrade any item infinitely
- Each level adds 5% stats
- Cost increases exponentially (15% per level)

### Prestige
- Reset progression for permanent bonuses
- 1% stats and 0.5% loot quality per prestige level
- Infinite prestige levels

### Tier System
- Your progression tier affects point multipliers
- Higher tier = more points per kill
- Tiers scale infinitely (5x, 15x, 30x, 50x, 75x, 105x...)

## Customization

### Easy Changes (Lua Config)
Edit `lua_scripts/config.lua`:
- Point values
- Tier multipliers
- Difficulty settings
- NPC entries
- Reward shop items

### Advanced Changes (C++)
- Modify `src/ProgressiveSystems.cpp` for core logic
- Modify `src/DifficultyScaling.cpp` for scaling behavior

### Database Changes
- Edit `custom_difficulty_scaling` table for map-specific scaling
- Add custom reward shop items in `config.lua`

## Troubleshooting

### Module not loading
- Check `include.sh` is executable
- Verify CMake found the module
- Check server logs for errors

### NPCs not working
- Verify NPCs are spawned with correct entries
- Check Eluna is enabled
- Verify Lua scripts are in correct directory

### Points not awarding
- Check `ProgressiveSystems.AwardPointsOnKill = 1` in config
- Verify database tables exist
- Check server logs for SQL errors

## Support

For issues or questions:
1. Check server logs
2. Verify all SQL files ran successfully
3. Check configuration files
4. Review this README

## License

Part of AzerothCore project. See AzerothCore license.

