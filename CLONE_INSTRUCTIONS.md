# How to Clone This Repository

## ✅ Good News: Both Branches Are Identical!

As of **December 3, 2025**, both `master` and `playerbotwithall` branches contain the same code!

You can clone either way and get all the features:

## ✅ Clone Commands (Both Work!)

```bash
# Option 1: Clone master (default)
git clone https://github.com/vladislav23811/azerothcore-wotlk.git

# Option 2: Clone playerbotwithall specifically
git clone --branch playerbotwithall https://github.com/vladislav23811/azerothcore-wotlk.git
```

Both commands will give you:
- ✅ All 23 modules
- ✅ All lua_scripts
- ✅ All configuration files
- ✅ C++20 modernization
- ✅ Latest commits and fixes

## 📁 What You Should See After Cloning

After cloning the `playerbotwithall` branch, you should have:

### Module Configs (26 .conf.dist files)
- `modules/mod-progressive-systems/conf/mod-progressive-systems.conf.dist`
- `modules/mod-playerbots/conf/playerbots.conf.dist`
- `modules/mod-autobalance/conf/AutoBalance.conf.dist`
- `modules/mod-eluna/conf/mod_ale.conf.dist`
- And 22 more module configs...

### Lua Scripts (13 files)
```
modules/mod-progressive-systems/lua_scripts/
├── 00_init.lua
├── config.lua
├── daily_challenge_generator.lua
├── daily_challenges_npc.lua
├── infinite_dungeon_npc.lua
├── infinite_dungeon_waves.lua
├── instance_reset_npc.lua
├── item_upgrade_npc.lua
├── main_menu_npc.lua
├── paragon_npc.lua
├── progressive_items_npc.lua
├── progressive_systems_core.lua
└── reward_shop_npc.lua
```

### SQL Files
```
modules/mod-progressive-systems/data/sql/
├── characters/base/
│   ├── 00_AUTO_SETUP_ALL.sql
│   ├── progressive_systems.sql
│   ├── paragon_system.sql
│   └── [13 more SQL files]
└── world/base/
    ├── 00_AUTO_SETUP_ALL.sql
    ├── difficulty_scaling.sql
    └── [6 more SQL files]
```

## 🔍 Verify Your Clone

After cloning, run these commands to verify:

```bash
# Check you're on the right branch
git branch

# Should show: * playerbotwithall

# Verify lua_scripts exist
ls modules/mod-progressive-systems/lua_scripts/

# Should show 13 .lua files

# Verify config files exist
ls modules/mod-*/conf/*.conf.dist | wc -l

# Should show: 26 (or similar number)
```

## 🔄 Branch Information

**Current Status**: Both branches are synchronized!

- **`master`**: Main branch (identical to playerbotwithall as of Dec 3, 2025)
- **`playerbotwithall`**: Development branch (where new features are added first)

Both branches currently point to commit: **`3dcb00374`**

### Going Forward
- New features will be added to `playerbotwithall` first
- `master` will be periodically updated to match `playerbotwithall`
- For the latest bleeding-edge features, use `playerbotwithall`
- For stable releases, use `master`

## 📊 File Counts in playerbotwithall Branch

- **Total lua_scripts**: 13 files
- **Total .conf.dist files**: 29 files (26 modules + 3 core)
- **Total SQL files**: 20+ files
- **Total modules**: 23 modules

## 🆘 Still Missing Files?

If you cloned the correct branch and files are still missing:

1. **Check your branch:**
   ```bash
   git branch
   git log --oneline -5
   ```
   
   Latest commit should be: `79d91df62 Comprehensive README update...`

2. **Check .gitignore isn't hiding them:**
   ```bash
   git check-ignore modules/mod-progressive-systems/lua_scripts/*
   ```
   
   Should return nothing (files are NOT ignored)

3. **Verify files in repository:**
   ```bash
   git ls-tree -r HEAD --name-only | grep lua_scripts
   git ls-tree -r HEAD --name-only | grep "\.conf\.dist"
   ```

4. **Force refresh:**
   ```bash
   git fetch origin playerbotwithall
   git reset --hard origin/playerbotwithall
   ```

## ✅ Confirmation

After cloning (either master or playerbotwithall), you should see:
- ✅ 23 module folders in `modules/`
- ✅ 13 lua scripts in `modules/mod-progressive-systems/lua_scripts/`
- ✅ 26+ .conf.dist files across all modules
- ✅ SQL files in `modules/mod-progressive-systems/data/sql/`
- ✅ Latest commit: `3dcb00374`

---

**Last Updated**: December 3, 2025
**Branches**: Both `master` and `playerbotwithall` are synchronized
**Latest Commit**: 3dcb00374 (Add CLONE_INSTRUCTIONS.md)
**Status**: ✅ Both branches contain all features!

