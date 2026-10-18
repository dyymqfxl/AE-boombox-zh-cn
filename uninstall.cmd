@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0patch.ps1" -Mode Uninstall %*
if errorlevel 1 echo Uninstall failed. If access is denied, run this file as administrator.
pause
