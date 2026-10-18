@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0patch.ps1" -Mode Install %*
if errorlevel 1 echo Installation failed. If access is denied, run this file as administrator.
pause
