# Progressive Systems Module Deployment Script
# Stops server, copies files, and provides restart instructions

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Progressive Systems Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. Stop server (if running)
Write-Host "`n[1/4] Stopping server..." -ForegroundColor Yellow
$worldserver = Get-Process -Name "worldserver" -ErrorAction SilentlyContinue
$authserver = Get-Process -Name "authserver" -ErrorAction SilentlyContinue

if ($worldserver) {
    Write-Host "  Stopping worldserver..." -ForegroundColor Yellow
    Stop-Process -Name "worldserver" -Force
    Start-Sleep -Seconds 2
}

if ($authserver) {
    Write-Host "  Stopping authserver..." -ForegroundColor Yellow
    Stop-Process -Name "authserver" -Force
    Start-Sleep -Seconds 2
}

if (-not $worldserver -and -not $authserver) {
    Write-Host "  No server processes found (already stopped)" -ForegroundColor Green
}

# 2. Copy executables
Write-Host "`n[2/4] Copying executables..." -ForegroundColor Yellow
$buildPath = "C:\servery\WOTLK-BOTS\build\bin\RelWithDebInfo"
$releasePath = "C:\servery\WOTLK-BOTS\release"

if (-not (Test-Path $releasePath)) {
    New-Item -ItemType Directory -Path $releasePath -Force | Out-Null
}

try {
    Copy-Item -Path "$buildPath\worldserver.exe" -Destination "$releasePath\worldserver.exe" -Force
    Write-Host "  ✓ Copied worldserver.exe" -ForegroundColor Green
    
    Copy-Item -Path "$buildPath\authserver.exe" -Destination "$releasePath\authserver.exe" -Force
    Write-Host "  ✓ Copied authserver.exe" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Error copying files: $_" -ForegroundColor Red
    exit 1
}

# 3. Verify SQL files
Write-Host "`n[3/4] Verifying SQL files..." -ForegroundColor Yellow
$sqlFiles = @(
    "modules\mod-progressive-systems\data\sql\characters\base\00_AUTO_SETUP_ALL.sql",
    "modules\mod-progressive-systems\data\sql\world\base\00_AUTO_SETUP_ALL.sql"
)

foreach ($sqlFile in $sqlFiles) {
    if (Test-Path $sqlFile) {
        Write-Host "  ✓ Found: $sqlFile" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Missing: $sqlFile" -ForegroundColor Red
    }
}

# 4. Summary
Write-Host "`n[4/4] Deployment Summary" -ForegroundColor Yellow
Write-Host "  Build directory: $buildPath" -ForegroundColor Cyan
Write-Host "  Release directory: $releasePath" -ForegroundColor Cyan
Write-Host "`n  ✓ Deployment complete!" -ForegroundColor Green
Write-Host "`n  Next steps:" -ForegroundColor Yellow
Write-Host "    1. Start the server" -ForegroundColor White
Write-Host "    2. Monitor logs for database setup messages" -ForegroundColor White
Write-Host "    3. Check for any errors in worldserver.log" -ForegroundColor White
Write-Host "`n========================================" -ForegroundColor Cyan
