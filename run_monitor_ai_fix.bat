@echo off
echo ========================================
echo AI_FIX_REQUEST Monitor & Auto-Fixer
echo ========================================
echo.
echo This script monitors for new AI_FIX_REQUEST files
echo and automatically fixes common errors.
echo.
echo Usage: run_monitor_ai_fix.bat [check_interval] [workspace_root]
echo   check_interval: Check interval in seconds (default: 10)
echo   workspace_root: Workspace root path (default: auto-detect)
echo.
echo Examples:
echo   run_monitor_ai_fix.bat
echo   run_monitor_ai_fix.bat 30
echo   run_monitor_ai_fix.bat 15 "C:\servers\azerothcore-wotlk"
echo.
echo Press Ctrl+C to stop the monitor.
echo.

if "%1"=="" (
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0monitor_ai_fix_loop.ps1"
) else (
    if "%2"=="" (
        powershell.exe -ExecutionPolicy Bypass -File "%~dp0monitor_ai_fix_loop.ps1" -CheckInterval %1
    ) else (
        powershell.exe -ExecutionPolicy Bypass -File "%~dp0monitor_ai_fix_loop.ps1" -CheckInterval %1 -WorkspaceRoot "%2"
    )
)
pause

