# Gold Monitor - Windows Release (minimal dist, all runtime deps + icon)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $ProjectRoot

$RequiredFiles = @(
    "gold_monitor.exe",
    "flutter_windows.dll",
    "dartjni.dll",
    "screen_retriever_windows_plugin.dll",
    "tray_manager_plugin.dll",
    "window_manager_plugin.dll",
    "data\icudtl.dat",
    "data\app.so",
    "data\flutter_assets\AssetManifest.bin",
    "data\flutter_assets\assets\app_icon.ico",
    "GoldMonitor.bat",
    "install_runtime_and_run.bat",
    "_mirror_launch.bat"
)

$iconExe = Join-Path $ProjectRoot "windows\runner\resources\app_icon.ico"
$iconAsset = Join-Path $ProjectRoot "assets\app_icon.ico"
if (-not (Test-Path $iconExe)) { Write-Error "Missing exe icon: $iconExe" }
if (-not (Test-Path $iconAsset)) { Write-Error "Missing tray icon: $iconAsset" }
Write-Host "==> Icons OK (exe + tray)" -ForegroundColor Green

Write-Host "==> flutter pub get" -ForegroundColor Cyan
flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "==> flutter build windows --release --tree-shake-icons" -ForegroundColor Cyan
flutter build windows --release --tree-shake-icons
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$ReleaseDir = Join-Path $ProjectRoot "build\windows\x64\runner\Release"
$DistDir = Join-Path $ProjectRoot "dist\GoldMonitor"
$DistRoot = Join-Path $ProjectRoot "dist"

if (-not (Test-Path $ReleaseDir)) {
    Write-Error "Release dir not found: $ReleaseDir"
}

Write-Host "==> Copy to $DistDir" -ForegroundColor Cyan
if (Test-Path $DistDir) {
    try {
        Remove-Item -Recurse -Force $DistDir
    } catch {
        $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $DistDir = Join-Path $DistRoot ("GoldMonitor_" + $stamp)
        Write-Warning "Default dist folder is in use, switching output to: $DistDir"
    }
}
New-Item -ItemType Directory -Path $DistDir -Force | Out-Null
Copy-Item -Path (Join-Path $ReleaseDir "*") -Destination $DistDir -Recurse -Force

$launcherBat = Join-Path $DistDir "install_runtime_and_run.bat"
$startBat = Join-Path $DistDir "GoldMonitor.bat"
$mirrorBat = Join-Path $DistDir "_mirror_launch.bat"
$batContent = @'
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
'@

$mirrorContent = @'
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
'@

$startContent = @'
@echo off
cd /d "%~dp0"
call "%~dp0install_runtime_and_run.bat"
'@

Set-Content -Path $launcherBat -Value $batContent -Encoding ASCII
Set-Content -Path $startBat -Value $startContent -Encoding ASCII
Set-Content -Path $mirrorBat -Value $mirrorContent -Encoding ASCII

$readmePath = Join-Path $DistDir "README.txt"
@(
    "Gold Monitor - Windows portable (~15 MB)",
    "",
    "Launch: double-click GoldMonitor.bat or gold_monitor.exe",
    "",
    "Chinese path: auto-mirrors to %LOCALAPPDATA%\GoldMonitor\runtime",
    "",
    "If exe fails on clean Windows, install VC++ 2015-2022 x64:",
    "https://aka.ms/vs/17/release/vc_redist.x64.exe",
    "",
    "Close button hides to tray; right-click tray icon to quit."
) | Set-Content -Path $readmePath -Encoding UTF8

$missing = @()
foreach ($rel in $RequiredFiles) {
    if (-not (Test-Path (Join-Path $DistDir $rel))) {
        $missing += $rel
    }
}
if ($missing.Count -gt 0) {
    Write-Error ("Missing runtime files: " + ($missing -join ", "))
}

$totalBytes = (Get-ChildItem -Recurse $DistDir | Measure-Object -Property Length -Sum).Sum
$totalMb = [math]::Round($totalBytes / 1MB, 2)

$zipName = Split-Path $DistDir -Leaf
$zipPath = Join-Path $DistRoot ($zipName + ".zip")
if (Test-Path $zipPath) { Remove-Item -Force $zipPath }
Compress-Archive -Path $DistDir -DestinationPath $zipPath -CompressionLevel Optimal
$zipMb = [math]::Round((Get-Item $zipPath).Length / 1MB, 2)

Write-Host ""
Write-Host "BUILD OK" -ForegroundColor Green
Write-Host "  EXE:      $(Join-Path $DistDir 'gold_monitor.exe')"
Write-Host "  Folder:   $DistDir"
Write-Host "  Size:     $totalMb MB"
Write-Host "  Zip:      $zipPath ($zipMb MB)"
Write-Host "  Includes: flutter_windows.dll, plugin DLLs, data/, app_icon.ico"
Write-Host "  First run: GoldMonitor.bat (recommended)"
Write-Host "  VC++: not bundled (install separately if needed)"
Write-Host ""
