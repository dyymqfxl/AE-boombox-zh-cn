@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0update.ps1" %*
if errorlevel 1 echo Update failed. If access is denied, run this file as administrator.
pause
