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
# Build Server (AzerothCore) + Launcher (if enabled)
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
    # Ask user if they want to build launcher too
    $buildLauncher = $false
    $response = Read-Host "Build launcher with server? (y/N)"
    if ($response -eq "y" -or $response -eq "Y") {
        $buildLauncher = $true
        Write-Host "Launcher will be built with server (requires Qt)" -ForegroundColor Cyan
    }
    
    # Configure if needed
    if (-not (Test-Path "CMakeCache.txt")) {
        Write-Host "Configuring CMake..." -ForegroundColor Yellow
        $cmakeArgs = @("-DCMAKE_BUILD_TYPE=RelWithDebInfo")
        if ($buildLauncher) {
            $cmakeArgs += "-DBUILD_LAUNCHER=ON"
        }
        & cmake .. @cmakeArgs
        if ($LASTEXITCODE -ne 0) {
            throw "CMake configuration failed"
        }
    } else {
        # If CMakeCache exists, check if we need to reconfigure for launcher
        if ($buildLauncher) {
            Write-Host "Reconfiguring CMake to enable launcher..." -ForegroundColor Yellow
            & cmake .. -DBUILD_LAUNCHER=ON
            if ($LASTEXITCODE -ne 0) {
                Write-Host "⚠️ Failed to enable launcher. Continuing with server build..." -ForegroundColor Yellow
            }
        }
    }
    
    # Build
    Write-Host "Building server..." -ForegroundColor Yellow
    if ($buildLauncher) {
        Write-Host "  (Launcher will be built too if Qt is available)" -ForegroundColor Gray
    }
    cmake --build . --config RelWithDebInfo
    if ($LASTEXITCODE -ne 0) {
        throw "Server build failed"
    }
    
    Write-Host "✅ Server build complete!" -ForegroundColor Green
    Write-Host "   Output: $serverBuildDir\bin\RelWithDebInfo\worldserver.exe" -ForegroundColor White
    
    # Check if launcher was built
    $launcherPath = Join-Path $serverBuildDir "bin\RelWithDebInfo\WoWLauncher.exe"
    if (Test-Path $launcherPath) {
        Write-Host "✅ Launcher build complete!" -ForegroundColor Green
        Write-Host "   Output: $launcherPath" -ForegroundColor White
    } elseif ($buildLauncher) {
        Write-Host "⚠️ Launcher not built (Qt not found or disabled)" -ForegroundColor Yellow
        Write-Host "   You can build it separately: cd tools\launcher\build && cmake .. && cmake --build ." -ForegroundColor Gray
    }
} catch {
    Write-Host "❌ Server build failed: $_" -ForegroundColor Red
    Pop-Location
    exit 1
} finally {
    Pop-Location
}

Write-Host ""

# ============================================================
# Option to build launcher separately if not built with server
# ============================================================
$launcherPath = Join-Path $serverBuildDir "bin\RelWithDebInfo\WoWLauncher.exe"
if (-not (Test-Path $launcherPath)) {
    Write-Host "=== Build Launcher Separately? ===" -ForegroundColor Cyan
    $response = Read-Host "Build launcher separately? (y/N)"
    if ($response -eq "y" -or $response -eq "Y") {
        $launcherDir = Join-Path $projectRoot "tools\launcher"
        $launcherBuildDir = Join-Path $launcherDir "build"

        if (-not (Test-Path $launcherDir)) {
            Write-Host "❌ Launcher directory not found: $launcherDir" -ForegroundColor Red
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
        } finally {
            Pop-Location
        }
    }
}

Write-Host ""
Write-Host "=== BUILD COMPLETE ===" -ForegroundColor Green
Write-Host ""
Write-Host "📦 Output Files:" -ForegroundColor Cyan
Write-Host "   Server: $serverBuildDir\bin\RelWithDebInfo\worldserver.exe" -ForegroundColor White

# Check for launcher in both possible locations
$launcherInServerBuild = Join-Path $serverBuildDir "bin\RelWithDebInfo\WoWLauncher.exe"
$launcherStandalone = Join-Path $projectRoot "tools\launcher\build\Release\WoWLauncher.exe"

if (Test-Path $launcherInServerBuild) {
    Write-Host "   Launcher: $launcherInServerBuild" -ForegroundColor White
} elseif (Test-Path $launcherStandalone) {
    Write-Host "   Launcher: $launcherStandalone" -ForegroundColor White
} else {
    Write-Host "   Launcher: Not built (Qt not found or disabled)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "💡 Next Steps:" -ForegroundColor Yellow
Write-Host "   1. Copy server files to release/ folder" -ForegroundColor White
Write-Host "   2. Test launcher (may need Qt DLLs)" -ForegroundColor White
Write-Host "   3. Deploy to players" -ForegroundColor White
Write-Host ""
Write-Host "💡 To build launcher separately:" -ForegroundColor Cyan
Write-Host "   cd tools\launcher\build" -ForegroundColor White
Write-Host "   cmake .. -DCMAKE_BUILD_TYPE=Release" -ForegroundColor White
Write-Host "   cmake --build . --config Release" -ForegroundColor White

