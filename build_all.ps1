# ============================================================
# Build All - Server + Launcher
# Builds both AzerothCore server and Qt launcher
# ============================================================

$ErrorActionPreference = "Stop"

Write-Host "`n=== BUILDING SERVER + LAUNCHER ===" -ForegroundColor Green
Write-Host ""

# Get project root
$projectRoot = $PSScriptRoot
if (-not $projectRoot) {
    $projectRoot = Get-Location
}

# ============================================================
# Build Server (AzerothCore)
# ============================================================
Write-Host "=== Building AzerothCore Server ===" -ForegroundColor Cyan
Write-Host ""

$serverBuildDir = Join-Path $projectRoot "build"
if (-not (Test-Path $serverBuildDir)) {
    New-Item -ItemType Directory -Path $serverBuildDir | Out-Null
    Write-Host "Created build directory: $serverBuildDir" -ForegroundColor Green
}

Push-Location $serverBuildDir

try {
    # Configure if needed
    if (-not (Test-Path "CMakeCache.txt")) {
        Write-Host "Configuring CMake..." -ForegroundColor Yellow
        cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo
        if ($LASTEXITCODE -ne 0) {
            throw "CMake configuration failed"
        }
    }
    
    # Build
    Write-Host "Building server..." -ForegroundColor Yellow
    cmake --build . --config RelWithDebInfo
    if ($LASTEXITCODE -ne 0) {
        throw "Server build failed"
    }
    
    Write-Host "✅ Server build complete!" -ForegroundColor Green
    Write-Host "   Output: $serverBuildDir\bin\RelWithDebInfo\worldserver.exe" -ForegroundColor White
} catch {
    Write-Host "❌ Server build failed: $_" -ForegroundColor Red
    Pop-Location
    exit 1
} finally {
    Pop-Location
}

Write-Host ""

# ============================================================
# Build Launcher (Qt Application)
# ============================================================
Write-Host "=== Building Qt Launcher ===" -ForegroundColor Cyan
Write-Host ""

$launcherDir = Join-Path $projectRoot "tools\launcher"
$launcherBuildDir = Join-Path $launcherDir "build"

if (-not (Test-Path $launcherDir)) {
    Write-Host "❌ Launcher directory not found: $launcherDir" -ForegroundColor Red
    Write-Host "Skipping launcher build..." -ForegroundColor Yellow
    exit 0
}

if (-not (Test-Path $launcherBuildDir)) {
    New-Item -ItemType Directory -Path $launcherBuildDir | Out-Null
    Write-Host "Created launcher build directory: $launcherBuildDir" -ForegroundColor Green
}

Push-Location $launcherBuildDir

try {
    # Configure if needed
    if (-not (Test-Path "CMakeCache.txt")) {
        Write-Host "Configuring CMake for launcher..." -ForegroundColor Yellow
        Write-Host "Note: Requires Qt 5.15+ or Qt 6.x installed" -ForegroundColor Gray
        
        cmake .. -DCMAKE_BUILD_TYPE=Release
        if ($LASTEXITCODE -ne 0) {
            Write-Host "⚠️ Launcher CMake configuration failed (Qt not found?)" -ForegroundColor Yellow
            Write-Host "   Install Qt or use vcpkg: vcpkg install qt5-base qt5-widgets qt5-network" -ForegroundColor Yellow
            Pop-Location
            exit 0
        }
    }
    
    # Build
    Write-Host "Building launcher..." -ForegroundColor Yellow
    cmake --build . --config Release
    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠️ Launcher build failed" -ForegroundColor Yellow
        Write-Host "   Check Qt installation and CMake configuration" -ForegroundColor Yellow
        Pop-Location
        exit 0
    }
    
    Write-Host "✅ Launcher build complete!" -ForegroundColor Green
    Write-Host "   Output: $launcherBuildDir\Release\WoWLauncher.exe" -ForegroundColor White
} catch {
    Write-Host "⚠️ Launcher build error: $_" -ForegroundColor Yellow
    Write-Host "   Server build succeeded, launcher can be built separately" -ForegroundColor Gray
} finally {
    Pop-Location
}

Write-Host ""
Write-Host "=== BUILD COMPLETE ===" -ForegroundColor Green
Write-Host ""
Write-Host "📦 Output Files:" -ForegroundColor Cyan
Write-Host "   Server: $serverBuildDir\bin\RelWithDebInfo\worldserver.exe" -ForegroundColor White
Write-Host "   Launcher: $launcherBuildDir\Release\WoWLauncher.exe" -ForegroundColor White
Write-Host ""
Write-Host "💡 Next Steps:" -ForegroundColor Yellow
Write-Host "   1. Copy server files to release/ folder" -ForegroundColor White
Write-Host "   2. Test launcher (may need Qt DLLs)" -ForegroundColor White
Write-Host "   3. Deploy to players" -ForegroundColor White

