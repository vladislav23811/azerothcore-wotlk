@echo off
REM Schedule this to run periodically (e.g., every hour) to check for new errors
REM You can add this to Windows Task Scheduler

echo Checking for new unfixable errors...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0auto_check_errors.ps1"

REM If errors were found, the script will generate a request file
REM You can then share that file with the AI assistant

pause

