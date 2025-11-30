# 📦 Addon Installation Guide

## ProgressiveSystems Addon

### Installation Steps:

1. **Locate Addon Directory:**
   - Windows: `World of Warcraft/Interface/AddOns/`
   - Mac: `Applications/World of Warcraft/Interface/AddOns/`

2. **Copy Addon:**
   - Copy the entire `ProgressiveSystems` folder from:
     `modules/mod-progressive-systems/addon/ProgressiveSystems/`
   - To: `Interface/AddOns/ProgressiveSystems/`

3. **Verify Installation:**
   - The folder structure should be:
     ```
     Interface/AddOns/ProgressiveSystems/
       ├── ProgressiveSystems.toc
       ├── ProgressiveSystems.lua
       ├── ProgressiveSystemsUI.lua
       ├── ProgressiveSystemsData.lua
       ├── ProgressiveSystemsParagon.lua
       ├── ProgressiveSystemsStats.lua
       └── README.md
     ```

4. **Restart WoW:**
   - Close WoW completely
   - Restart WoW client
   - The addon should load automatically

5. **Verify Loading:**
   - Type `/ps` in chat
   - You should see: `[ProgressiveSystems] Initializing...`
   - If you see the message, the addon is working!

### Features:

- ✅ Main window with tabs (Progression, Paragon, Stats)
- ✅ Real-time paragon experience bar
- ✅ Custom stats display
- ✅ Power level tracking
- ✅ Automatic data updates
- ✅ Settings window

### Commands:

- `/ps` or `/progressive` - Open main window
- `/ps paragon` - Open paragon window
- `/ps stats` - Open stats window
- `/ps power` - Show power level
- `/ps info` - Show system info
- `/ps config` - Open settings

### Troubleshooting:

**Addon not loading?**
- Check that files are in correct location
- Verify `.toc` file exists
- Check WoW version compatibility (Interface: 30305)

**No data showing?**
- Make sure you're level 80+ for paragon
- Talk to NPCs to initialize data
- Use `/ps` to request data from server

**UI not appearing?**
- Type `/ps ui` to force open
- Check if frames are hidden (try `/reload`)

### Support:

If you have issues:
1. Check chat for error messages
2. Type `/ps info` to see current data
3. Try `/reload` to reload UI
4. Restart WoW if needed

**Enjoy your enhanced progressive server!** 🎮

