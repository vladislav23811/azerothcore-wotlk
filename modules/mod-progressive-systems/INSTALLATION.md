# Progressive Systems Module - Installation Guide

## 📁 Lua Scripts Location

### Current Location (Source)
```
modules/mod-progressive-systems/lua_scripts/
```

### Required Location (Runtime)
```
bin/lua_scripts/
```
*(Relative to where worldserver.exe runs)*

## 📋 Installation Steps

### 1. Copy Lua Scripts

**Windows:**
```powershell
# From project root
Copy-Item -Path "modules\mod-progressive-systems\lua_scripts\*" -Destination "bin\lua_scripts\" -Recurse -Force
```

**Linux/Mac:**
```bash
# From project root
cp -r modules/mod-progressive-systems/lua_scripts/* bin/lua_scripts/
```

### 2. Verify Scripts Are Copied

After copying, you should have these files in `bin/lua_scripts/`:
- ✅ `config.lua`
- ✅ `progressive_systems_core.lua`
- ✅ `main_menu_npc.lua`
- ✅ `item_upgrade_npc.lua`
- ✅ `reward_shop_npc.lua`
- ✅ `infinite_dungeon_npc.lua`
- ✅ `progressive_items_npc.lua`

### 3. Configure Eluna (if needed)

Edit `worldserver.conf` and ensure:
```ini
ALE.Enabled = true
ALE.ScriptPath = "lua_scripts"
```

### 4. Restart Server

The scripts will auto-load when the server starts (if Eluna is enabled).

## 🔍 Verify Installation

1. Start the server
2. Check server logs for:
   ```
   [Progressive Systems] Core module loaded successfully!
   [Progressive Systems] Main menu NPC loaded!
   [Progressive Systems] Item Upgrade NPC loaded!
   [Progressive Systems] Reward Shop NPC loaded!
   [Progressive Systems] Infinite Dungeon NPC loaded!
   [Progressive Systems] Progressive Items NPC loaded!
   ```

3. In-game: Spawn NPC 190000 and interact with it

## 📝 Notes

- Scripts are loaded from `bin/lua_scripts/` (relative to worldserver.exe)
- You can change the path in `worldserver.conf` with `ALE.ScriptPath`
- Scripts auto-reload if `ALE.AutoReload = true` (development only)
- Use `.reload ALE` command in-game to reload scripts without restart

## 🛠️ Development Workflow

For development, you can:
1. Keep scripts in `modules/mod-progressive-systems/lua_scripts/`
2. Use a symlink or copy script to sync to `bin/lua_scripts/`
3. Enable `ALE.AutoReload = true` for automatic reloading

**Windows Symlink:**
```powershell
# Run as Administrator
New-Item -ItemType SymbolicLink -Path "bin\lua_scripts\progressive" -Target "$PWD\modules\mod-progressive-systems\lua_scripts"
```

**Linux/Mac Symlink:**
```bash
ln -s ../../modules/mod-progressive-systems/lua_scripts bin/lua_scripts/progressive
```

