@echo off
REM This batch file should be run from a Developer Command Prompt for VS 2022
REM It will properly set up the environment and run the improvement loop

echo ========================================
echo AzerothCore Enhanced Improvement Loop
echo ========================================
echo.
echo This script should be run from:
echo "Developer Command Prompt for VS 2026"
echo.
echo If you're not in a Developer Command Prompt,
echo the build may fail due to missing environment variables.
echo.
pause

echo.
echo Starting improvement loop...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0improve_loop_enhanced.ps1"
pause

