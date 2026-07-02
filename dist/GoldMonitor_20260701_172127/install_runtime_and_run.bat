@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
title GoldMonitor First Run Helper
color 0E

set "LOG_FILE=%~dp0first_run_helper.log"
echo ==== %date% %time% ==== > "%LOG_FILE%"
echo [GoldMonitor] First run helper started.

echo [GoldMonitor] Checking VC++ runtime...
echo [GoldMonitor] Checking VC++ runtime...>>"%LOG_FILE%"
set "missing=0"
if not exist "%SystemRoot%\System32\vcruntime140.dll" set "missing=1"
if not exist "%SystemRoot%\System32\vcruntime140_1.dll" set "missing=1"
if not exist "%SystemRoot%\System32\msvcp140.dll" set "missing=1"

if "%missing%"=="1" (
  echo [GoldMonitor] VC++ runtime not found, downloading installer...
  echo [GoldMonitor] Runtime missing, downloading...>>"%LOG_FILE%"
  set "VC_URL=https://aka.ms/vs/17/release/vc_redist.x64.exe"
  set "VC_EXE=%TEMP%\vc_redist.x64.exe"
  powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Invoke-WebRequest -UseBasicParsing -Uri '%VC_URL%' -OutFile '%VC_EXE%' } catch { exit 1 }"
  if errorlevel 1 (
    echo [GoldMonitor] Download failed. Please install manually:
    echo %VC_URL%
    echo [GoldMonitor] ERROR: download failed.>>"%LOG_FILE%"
    pause
    exit /b 1
  )
  echo [GoldMonitor] Installing VC++ runtime, UAC prompt may appear...
  echo [GoldMonitor] Installing runtime...>>"%LOG_FILE%"
  "%VC_EXE%" /install /passive /norestart
  if errorlevel 1 (
    echo [GoldMonitor] Install may have failed. Try manual install:
    echo %VC_URL%
    echo [GoldMonitor] ERROR: runtime install failed.>>"%LOG_FILE%"
    pause
    exit /b 1
  )
) else (
  echo [GoldMonitor] VC++ runtime already installed.
  echo [GoldMonitor] Runtime already installed.>>"%LOG_FILE%"
)

echo [GoldMonitor] Launching app...
if not exist "%~dp0gold_monitor.exe" (
  echo [GoldMonitor] ERROR: gold_monitor.exe not found in current folder.
  echo [GoldMonitor] ERROR: exe missing.>>"%LOG_FILE%"
  pause
  exit /b 1
)
start "" "%~dp0gold_monitor.exe"
if errorlevel 1 (
  echo [GoldMonitor] ERROR: failed to start app.
  echo [GoldMonitor] ERROR: start command failed.>>"%LOG_FILE%"
  pause
  exit /b 1
)
echo [GoldMonitor] App start command sent.
echo [GoldMonitor] App start command sent.>>"%LOG_FILE%"
echo [GoldMonitor] If no main window appears, check system tray area.
echo [GoldMonitor] Window will close in 8 seconds...
timeout /t 8 /nobreak >nul
exit /b 0
