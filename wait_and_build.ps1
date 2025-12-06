# ============================================================
# Wait for Qt Installation and Build Everything
# Monitors Qt installation, then configures and builds
# ============================================================

$ErrorActionPreference = "Continue"

Write-Host "`n=== Waiting for Qt Installation ===" -ForegroundColor Cyan
Write-Host ""

$vcpkgPath = "C:\vcpkg\vcpkg.exe"
$maxWait = 3600  # 1 hour max
$checkInterval = 30  # Check every 30 seconds
$elapsed = 0

while ($elapsed -lt $maxWait) {
    Write-Host "[$([math]::Floor($elapsed/60))m $($elapsed%60)s] Checking Qt installation..." -ForegroundColor Gray -NoNewline
    
    try {
        $qtList = & $vcpkgPath list 2>&1 | Select-String "qt5.*x64-windows"
    } catch {
        $qtList = $null
    }
    
    if ($qtList -and $qtList.Count -gt 0) {
        Write-Host "`r[$([math]::Floor($elapsed/60))m $($elapsed%60)s] " -NoNewline
        Write-Host "Qt5 INSTALLED!" -ForegroundColor Green
        Write-Host ""
        break
    }
    
    Write-Host "`r[$([math]::Floor($elapsed/60))m $($elapsed%60)s] Still installing... (waiting $checkInterval seconds)" -NoNewline
    Start-Sleep -Seconds $checkInterval
    $elapsed += $checkInterval
}

if ($elapsed -ge $maxWait) {
    Write-Host "`nTimeout waiting for Qt installation" -ForegroundColor Yellow
    Write-Host "You can build the server without launcher:" -ForegroundColor Cyan
    Write-Host "   cd C:\servery\WOTLK-BOTS\build" -ForegroundColor White
    Write-Host "   cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_LAUNCHER=OFF" -ForegroundColor White
    Write-Host "   cmake --build . --config RelWithDebInfo" -ForegroundColor White
    exit 1
}

Write-Host "`n=== Configuring CMake ===" -ForegroundColor Cyan
Write-Host ""

$buildDir = "C:\servery\WOTLK-BOTS\build"
$sourceDir = "C:\servery\WOTLK-BOTS\azerothcore-wotlk"

if (-not (Test-Path $buildDir)) {
    New-Item -ItemType Directory -Path $buildDir | Out-Null
}

Push-Location $buildDir

Write-Host "Running CMake configuration..." -ForegroundColor Yellow
cmake $sourceDir -DCMAKE_BUILD_TYPE=RelWithDebInfo

if ($LASTEXITCODE -ne 0) {
    Write-Host "`nCMake configuration failed" -ForegroundColor Red
    Pop-Location
    exit 1
}

Write-Host "`nCMake configuration successful!" -ForegroundColor Green
Write-Host ""

Write-Host "=== Building Everything ===" -ForegroundColor Cyan
Write-Host "Building server + launcher..." -ForegroundColor Yellow
Write-Host "This will take several minutes..." -ForegroundColor Gray
Write-Host ""

cmake --build . --config RelWithDebInfo --parallel

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nBUILD COMPLETE!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Output Files:" -ForegroundColor Cyan
    
    $worldserver = "bin\RelWithDebInfo\worldserver.exe"
    $launcher = "bin\RelWithDebInfo\WoWLauncher.exe"
    
    if (Test-Path $worldserver) {
        Write-Host "   [OK] Server: $worldserver" -ForegroundColor Green
    } else {
        Write-Host "   [FAIL] Server: Not found" -ForegroundColor Red
    }
    
    if (Test-Path $launcher) {
        Write-Host "   [OK] Launcher: $launcher" -ForegroundColor Green
    } else {
        Write-Host "   [WARN] Launcher: Not found" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "Everything is ready!" -ForegroundColor Green
} else {
    Write-Host "`nBuild failed" -ForegroundColor Red
}

Pop-Location
