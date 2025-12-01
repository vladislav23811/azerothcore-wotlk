# Quick Start Guide - Fixed Compiler Issues

## Problem
The compiler couldn't find standard C++ headers because the Visual Studio environment variables weren't set up.

## Solution
We've created scripts to automatically set up the environment, but the **best way** is to use Visual Studio's Developer Command Prompt.

## Recommended Method (Best Results)

1. **Open "Developer Command Prompt for VS 2026"**
   - Search for it in Windows Start Menu
   - Or navigate to: `C:\Program Files\Microsoft Visual Studio\2026\Community\Common7\Tools\VsDevCmd.bat`

2. **Navigate to your project directory:**
   ```cmd
   cd C:\servers\azerothcore-wotlk
   ```

3. **Reconfigure CMake (if needed):**
   ```cmd
   powershell.exe -ExecutionPolicy Bypass -File .\reconfigure_cmake.ps1
   ```

4. **Start the improvement loop:**
   ```cmd
   .\run_improvement_loop.bat
   ```
   Or simply:
   ```cmd
   powershell.exe -ExecutionPolicy Bypass -File .\improve_loop_enhanced.ps1
   ```

## Alternative Method (Automatic Setup)

If you can't use Developer Command Prompt, the scripts will try to set up the environment automatically:

1. **Run the full setup:**
   ```cmd
   .\run_improvement_loop_with_reconfig.bat
   ```

   This will:
   - Set up Visual Studio environment variables
   - Reconfigure CMake
   - Start the improvement loop

## What the Improvement Loop Does

- **Builds** the project every 30 seconds
- **Fixes errors** automatically when possible
- **Modernizes code** (NULL → nullptr, etc.)
- **Adds new WoW features** every 3 successful builds
- **Runs for up to 8 hours** continuously

## Monitoring Progress

The loop will output progress to the console. You can also check:
- Build status in real-time
- Number of features added
- Number of files modernized
- Errors fixed

## Troubleshooting

If you still get "Cannot open include file" errors:

1. Make sure you're using **Developer Command Prompt for VS 2026**
2. Verify Visual Studio 2026 is installed with C++ components
3. Try running `vcvarsall.bat x64` manually first:
   ```cmd
   "C:\Program Files\Microsoft Visual Studio\2026\Community\VC\Auxiliary\Build\vcvarsall.bat" x64
   ```

## Files Created

- `setup_vs_env.ps1` - Sets up VS environment variables
- `reconfigure_cmake.ps1` - Reconfigures CMake with proper environment
- `improve_loop_enhanced.ps1` - Main improvement loop script
- `run_improvement_loop.bat` - Simple launcher
- `run_improvement_loop_with_reconfig.bat` - Full setup + loop
- `run_from_dev_prompt.bat` - For use in Developer Command Prompt

