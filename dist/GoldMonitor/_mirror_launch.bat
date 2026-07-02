@echo off
setlocal EnableExtensions
set "SRC=%~dp0"
set "SRC=%SRC:~0,-1%"
set "EXE=%SRC%\gold_monitor.exe"
set "DST=%LOCALAPPDATA%\GoldMonitor\runtime"
set "LOG_FILE=%~dp0first_run_helper.log"

for /f "delims=" %%A in ('powershell -NoProfile -Command "$p='%~dp0'; if ($p.ToCharArray() | Where-Object { [int]$_ -gt 127 }) { '1' } else { '0' }"') do set "NONASCII=%%A"
if not defined NONASCII set "NONASCII=0"

if "%NONASCII%"=="0" goto launch_local

echo [GoldMonitor] Non-ASCII path detected, mirroring to %DST%
echo [GoldMonitor] Mirror path: %DST% >> "%LOG_FILE%"
if not exist "%DST%" mkdir "%DST%"
robocopy "%SRC%" "%DST%" /E /IS /IT /NJH /NJS /NFL /NDL /NC /NS /NP >nul
if errorlevel 8 goto mirror_failed
if not exist "%DST%\gold_monitor.exe" goto mirror_failed
start "" "%DST%\gold_monitor.exe" --mirrored-runtime
exit /b 0

:mirror_failed
echo [GoldMonitor] ERROR: mirror failed.
echo [GoldMonitor] ERROR: mirror failed. >> "%LOG_FILE%"
exit /b 1

:launch_local
start "" "%EXE%"
exit /b 0
