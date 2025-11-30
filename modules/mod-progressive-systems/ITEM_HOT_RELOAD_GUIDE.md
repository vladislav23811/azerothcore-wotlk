# Item Template Hot Reload Guide

## Problem Solved
**No more server restarts needed!** New items added to `item_template` are now automatically detected and reloaded without server restart.

## How It Works

### 1. Automatic Hot Reload (Default: Enabled)
- System checks for new items every 30 seconds
- Automatically reloads item templates when changes are detected
- Works in the background - no manual intervention needed

### 2. Manual Reload Command
You can also manually reload items using the GM command:
```
.reload item_template
```

Or reload all item-related data:
```
.reload all item
```

## Features

### Automatic Detection
- Detects new items added to `item_template`
- Detects deleted items (removed from database)
- Automatically reloads when changes are found

### Manual Control
- Force reload at any time with `.reload item_template`
- Disable auto-reload if needed (via code/config)

### Safe Reload
- Clears old item templates first (removes deleted items)
- Reloads all items from database
- Updates fast lookup array for performance
- Reloads item locales

## Usage

### Adding New Items
1. Add item to `item_template` table in database
2. Wait up to 30 seconds (or use `.reload item_template`)
3. Item is now available in-game!

### Example SQL
```sql
INSERT INTO item_template (entry, class, subclass, name, displayid, Quality, ...)
VALUES (90000, 2, 7, 'My Custom Sword', 12345, 4, ...);
```

Then either:
- Wait 30 seconds for auto-reload
- Or run: `.reload item_template`

### Important Notes

1. **Item Icons**: 
   - Icons are stored in client-side DBC files
   - New items MUST use existing `DisplayInfoID` values to show icons
   - See `ITEM_ICON_GUIDE.md` for details

2. **Client Cache**:
   - Players may need to relog to see new items
   - Or clear their client cache (WDB folder)

3. **Performance**:
   - Auto-reload checks every 30 seconds
   - Only reloads when changes are detected
   - Minimal performance impact

## Configuration

### Disable Auto-Reload
If you want to disable automatic reloading:

```cpp
sItemTemplateHotReload->SetAutoReloadEnabled(false);
```

### Change Check Interval
Modify in `ItemTemplateHotReload.cpp`:
```cpp
uint32 m_checkIntervalSeconds = 30; // Change to desired interval
```

## Technical Details

### What Gets Reloaded
- `item_template` table → `_itemTemplateStore`
- Fast lookup array → `_itemTemplateStoreFast`
- Item locales → `_itemLocaleStore`

### Reload Process
1. Clear existing item templates
2. Load all items from database
3. Rebuild fast lookup array
4. Reload item locales
5. Update known item entries cache

### Performance
- Database query: Simple SELECT on `item_template.entry`
- Reload time: ~100-500ms depending on item count
- Memory: Clears old data before loading new

## Troubleshooting

### Items Not Appearing
1. Check if item was actually added to database
2. Verify `DisplayInfoID > 0` for icon display
3. Try manual reload: `.reload item_template`
4. Check server logs for errors

### Auto-Reload Not Working
1. Check if auto-reload is enabled
2. Verify system is initialized (check startup logs)
3. Check for errors in server logs
4. Try manual reload to test

### Performance Issues
1. Increase check interval (default: 30 seconds)
2. Disable auto-reload if not needed
3. Use manual reload only when needed

## Integration

The hot reload system is automatically:
- ✅ Initialized on server startup
- ✅ Integrated with progressive systems module
- ✅ Scheduled to check every 30 seconds
- ✅ Ready to use without configuration

## Commands

| Command | Description |
|---------|-------------|
| `.reload item_template` | Reload all item templates manually |
| `.reload all item` | Reload all item-related data (templates, locales, sets, etc.) |

## Benefits

1. **No Server Restart** - Add items instantly
2. **Automatic** - Works in background
3. **Safe** - Clears deleted items properly
4. **Fast** - Reloads in milliseconds
5. **Integrated** - Works with all systems

Enjoy instant item updates! 🎉

