@echo off
REM WoW Custom Launcher - Windows Batch Wrapper
REM Makes it easy to run the launcher

cd /d "%~dp0\.."
python tools\wow_launcher.py
pause

