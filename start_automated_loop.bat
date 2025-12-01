@echo off
REM Fully automated improvement loop - runs unattended
REM No manual intervention required - perfect for overnight runs

echo ========================================
echo AzerothCore Automated Improvement Loop
echo ========================================
echo.
echo This will run UNATTENDED for up to 8 hours.
echo Perfect for running overnight or while away.
echo.
echo The loop will:
echo   - Build every 30 seconds
echo   - Fix errors automatically
echo   - Modernize code continuously
echo   - Add new features every 3 successful builds
echo   - Run for up to 8 hours
echo.
echo Progress will be logged to the PowerShell window.
echo.
echo Starting in 5 seconds...
timeout /t 5 /nobreak >nul

REM Start PowerShell with the improvement loop
REM -NoExit keeps window open to see results
REM -WindowStyle Normal so you can monitor if needed
powershell.exe -ExecutionPolicy Bypass -NoExit -File "%~dp0improve_loop_enhanced.ps1"

REM If script exits, pause so you can see what happened
pause

