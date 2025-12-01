@echo off
REM Fully automated improvement loop - runs minimized in background
REM Perfect for unattended operation - no window distractions

echo ========================================
echo AzerothCore Automated Improvement Loop
echo ========================================
echo.
echo Starting in MINIMIZED mode...
echo The loop will run in the background.
echo.
echo To view progress, check the minimized PowerShell window
echo in your taskbar.
echo.
echo Starting in 3 seconds...
timeout /t 3 /nobreak >nul

REM Start PowerShell minimized - runs in background
powershell.exe -ExecutionPolicy Bypass -WindowStyle Minimized -File "%~dp0improve_loop_enhanced.ps1"

REM This won't be reached until loop completes
echo.
echo Loop has completed!
pause

