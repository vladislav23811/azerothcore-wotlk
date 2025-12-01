# Quick Start Guide - Improvement Loop

## Fix PowerShell Execution Policy Issue

You have two options:

### Option 1: Run with Bypass (Recommended - No Admin Required)
```powershell
powershell.exe -ExecutionPolicy Bypass -File .\improve_loop_enhanced.ps1
```

Or simply double-click: `run_improvement_loop.bat`

### Option 2: Change Execution Policy (Requires Admin)
Run PowerShell as Administrator, then:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Then run:
```powershell
.\improve_loop_enhanced.ps1
```

## What the Loop Does

1. **Builds** the project every 30 seconds
2. **Modernizes** code (NULL → nullptr, modern C++ patterns)
3. **Adds** new WoW 3.3.5a backport features every 3 successful builds
4. **Improves** existing features automatically
5. **Runs** for up to 8 hours (or until you stop it)

## Monitor Progress

In a separate PowerShell window:
```powershell
powershell.exe -ExecutionPolicy Bypass -File .\monitor_progress.ps1
```

## Stop the Loop

Press `Ctrl+C` in the terminal running the loop.

## Features That Will Be Added

The loop will automatically add these WoW features:
- Transmog System
- Void Storage
- Account-wide Mounts/Pets
- Guild Perks
- Rated Battlegrounds
- And 15+ more features!

## Troubleshooting

If you get permission errors:
- Right-click PowerShell → Run as Administrator
- Or use the bypass method (Option 1)

