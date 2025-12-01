@echo off
echo ========================================
echo AzerothCore Enhanced Improvement Loop
echo ========================================
echo.
echo NOTE: For best results, run this from a
echo "Developer Command Prompt for VS 2026"
echo.
echo Usage: run_improvement_loop.bat [options]
echo   Options:
echo     -MonitorAIFixRequests  Enable AI_FIX_REQUEST monitoring
echo.
echo Setting up Visual Studio environment...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0setup_vs_env.ps1"
echo.
echo Starting improvement loop...
if "%1"=="-MonitorAIFixRequests" (
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0improve_loop_enhanced.ps1" -MonitorAIFixRequests
) else (
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0improve_loop_enhanced.ps1"
)
pause

