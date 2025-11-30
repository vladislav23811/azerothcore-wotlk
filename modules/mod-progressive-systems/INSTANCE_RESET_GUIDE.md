# Instance Reset System Guide

## Overview
The Instance Reset System allows players to reset instances unlimited times and track their completion statistics. Perfect for progressive servers where players want to farm dungeons and raids repeatedly!

## Features

### ✅ Unlimited Instance Resets
- Reset any dungeon or raid instance as many times as you want
- No daily limits or cooldowns (configurable)
- Works for both dungeons and raids

### ✅ Completion Tracking
- Tracks how many times you've completed each instance
- Records best completion time
- Tracks highest difficulty tier completed
- Monitors total kills and deaths per instance

### ✅ Easy Access
- NPC menu for easy reset
- Client addon for viewing stats
- Integrated into main progressive systems menu

## Usage

### Via NPC
1. Talk to the **Instance Reset NPC** (Entry: 190010)
2. Select "Reset All Dungeons" or "Reset All Raids"
3. Or select a specific instance to reset
4. View your completion statistics

### Via Client Addon
1. Type `/ps reset` or `/ps instances`
2. View all your instances and completion counts
3. Click "Reset" button for any instance
4. Or click "Reset All" to reset everything

### Via Main Menu
1. Talk to Main Progressive Systems NPC (Entry: 190000)
2. Select "Instance Reset"
3. Choose your reset option

## Completion Statistics

The system tracks:
- **Completion Count**: How many times you've completed the instance
- **Best Time**: Fastest completion time (in seconds)
- **Highest Difficulty**: Highest difficulty tier you've completed
- **Total Kills**: All kills in this instance
- **Total Deaths**: All deaths in this instance

## Configuration

### Default Settings
- ✅ Unlimited resets (no daily limit)
- ✅ No cooldown between resets
- ✅ No progression point cost
- ✅ Works for both dungeons and raids

### Customizable Options
You can modify in `InstanceResetSystem.cpp`:

```cpp
m_config.unlimitedResets = true;        // Allow unlimited resets
m_config.maxResetsPerDay = 0;          // 0 = unlimited, or set daily limit
m_config.requireProgressionPoints = false; // Require points to reset
m_config.resetCostPoints = 0;          // Cost in progression points
m_config.allowRaidResets = true;       // Allow raid resets
m_config.allowDungeonResets = true;    // Allow dungeon resets
m_config.cooldownSeconds = 0;          // Cooldown between resets (0 = no cooldown)
```

## Database Tables

### `instance_completion_tracking`
Tracks completion statistics per player per instance:
- `guid` - Player GUID
- `map_id` - Instance map ID
- `completion_count` - Number of completions
- `last_completion_time` - Unix timestamp
- `best_time` - Best completion time (seconds)
- `highest_difficulty_tier` - Highest tier completed
- `total_kills` - Total kills
- `total_deaths` - Total deaths

### `instance_reset_usage`
Tracks reset usage for daily limits/cooldowns:
- `usage_id` - Auto-increment ID
- `guid` - Player GUID
- `map_id` - Instance map ID
- `reset_time` - Unix timestamp of reset

## Integration

The system automatically:
- ✅ Tracks instance completions when you finish a dungeon/raid
- ✅ Updates completion statistics
- ✅ Integrates with progressive systems difficulty tiers
- ✅ Works with all instance types

## Example Usage

### Reset All Dungeons
```
1. Talk to Instance Reset NPC
2. Select "Reset All Dungeons"
3. All your dungeon instances are reset!
```

### View Completion Stats
```
1. Type /ps reset
2. See all your instances with completion counts
3. View your best times and difficulty tiers
```

### Reset Specific Instance
```
1. Talk to Instance Reset NPC
2. Select "Reset Specific Instance"
3. Choose the instance (e.g., "Naxxramas")
4. Instance is reset!
```

## Benefits

1. **Unlimited Farming** - Run instances as many times as you want
2. **Progress Tracking** - See your completion history
3. **Easy Access** - Multiple ways to reset instances
4. **Integrated** - Works with all progressive systems
5. **Flexible** - Configurable limits and costs

## Technical Details

### How It Works
1. Player requests instance reset (via NPC or addon)
2. System checks if instance can be reset
3. Unbinds player from instance
4. Deletes instance save data
5. Tracks reset usage
6. Player can now enter instance fresh

### Completion Tracking
- Automatically triggered when instance is completed
- Updates completion count
- Records best time if faster
- Updates highest difficulty tier if higher
- Tracks all kills and deaths

## Troubleshooting

### Instance Won't Reset
- Check if you're bound to the instance
- Verify instance is not currently active (no players inside)
- Check if resets are enabled for that instance type

### Completion Stats Not Updating
- Stats update when instance is completed
- Check server logs for errors
- Verify database tables exist

### Addon Not Showing Instances
- Make sure addon is loaded
- Type `/ps reset` to open window
- Check if you have any bound instances

## Commands

| Command | Description |
|---------|-------------|
| `/ps reset` | Open instance reset window |
| `/ps instances` | Same as reset |

## NPC Entries

- **Instance Reset NPC**: 190010
- **Main Menu NPC**: 190000 (has Instance Reset option)

Enjoy unlimited instance farming! 🎉

