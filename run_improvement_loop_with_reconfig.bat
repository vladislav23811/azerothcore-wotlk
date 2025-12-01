@echo off
echo ========================================
echo AzerothCore Improvement Loop Setup
echo ========================================
echo.
echo This will:
echo   1. Set up Visual Studio environment
echo   2. Reconfigure CMake (if needed)
echo   3. Start the improvement loop
echo.
echo NOTE: For best results, use Developer Command Prompt for VS 2026
echo.
echo Press Ctrl+C to cancel.
echo.
pause

echo.
echo Setting up Visual Studio environment...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0setup_vs_env.ps1"
if errorlevel 1 (
    echo Failed to set up VS environment!
    pause
    exit /b 1
)

echo.
echo Reconfiguring CMake...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0reconfigure_cmake.ps1"
if errorlevel 1 (
    echo CMake reconfiguration failed!
    pause
    exit /b 1
)

echo.
echo Starting improvement loop...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0improve_loop_enhanced.ps1"
pause

