@echo off
setlocal EnableExtensions
cd /d "%~dp0"
title GoldMonitor Launcher

set "LOG_FILE=%~dp0first_run_helper.log"
echo ==== %date% %time% ==== > "%LOG_FILE%"
echo [GoldMonitor] Launcher started. >> "%LOG_FILE%"

if not exist "%~dp0gold_monitor.exe" (
  echo [GoldMonitor] ERROR: gold_monitor.exe not found.
  echo [GoldMonitor] ERROR: exe missing. >> "%LOG_FILE%"
  pause
  exit /b 1
)

call "%~dp0_mirror_launch.bat"
if errorlevel 1 (
  echo [GoldMonitor] ERROR: launch failed. See first_run_helper.log
  pause
  exit /b 1
)

echo [GoldMonitor] App started. Check tray if no window.
timeout /t 3 /nobreak >nul
exit /b 0
