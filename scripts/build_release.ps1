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
    "data\flutter_assets\assets\app_icon.ico"
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

if (-not (Test-Path $ReleaseDir)) {
    Write-Error "Release dir not found: $ReleaseDir"
}

Write-Host "==> Copy to $DistDir" -ForegroundColor Cyan
if (Test-Path $DistDir) {
    Remove-Item -Recurse -Force $DistDir
}
New-Item -ItemType Directory -Path $DistDir -Force | Out-Null
Copy-Item -Path (Join-Path $ReleaseDir "*") -Destination $DistDir -Recurse -Force

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

$zipPath = Join-Path $ProjectRoot "dist\GoldMonitor.zip"
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
Write-Host ""
