# ============================================================
# Automatic Qt Installation Script
# Installs Qt via vcpkg or provides download links
# ============================================================

$ErrorActionPreference = "Continue"

Write-Host "`n=== Qt Installation Helper ===" -ForegroundColor Cyan
Write-Host ""

# Check if Qt is already installed
Write-Host "Checking for existing Qt installation..." -ForegroundColor Yellow

$qtFound = $false
$qtVersion = $null
$qtPath = $null

# Check common Qt installation paths
$qtPaths = @(
    "$env:ProgramFiles\Qt",
    "$env:ProgramFiles(x86)\Qt",
    "$env:LOCALAPPDATA\Qt",
    "C:\Qt",
    "C:\vcpkg\installed\x64-windows"
)

foreach ($path in $qtPaths) {
    if (Test-Path $path) {
        # Check for Qt6
        $qt6Path = Join-Path $path "6.*"
        $qt6Dirs = Get-ChildItem -Path $path -Directory -Filter "6.*" -ErrorAction SilentlyContinue
        if ($qt6Dirs) {
            $qtFound = $true
            $qtVersion = "6"
            $qtPath = $qt6Dirs[0].FullName
            Write-Host "✅ Found Qt6 at: $qtPath" -ForegroundColor Green
            break
        }
        
        # Check for Qt5
        $qt5Dirs = Get-ChildItem -Path $path -Directory -Filter "5.*" -ErrorAction SilentlyContinue
        if ($qt5Dirs) {
            $qtFound = $true
            $qtVersion = "5"
            $qtPath = $qt5Dirs[0].FullName
            Write-Host "✅ Found Qt5 at: $qtPath" -ForegroundColor Green
            break
        }
    }
}

if ($qtFound) {
    Write-Host "`n✅ Qt is already installed!" -ForegroundColor Green
    Write-Host "   Version: Qt$qtVersion" -ForegroundColor White
    Write-Host "   Path: $qtPath" -ForegroundColor White
    Write-Host "`n💡 If CMake still can't find Qt, set Qt5_DIR or Qt6_DIR:" -ForegroundColor Yellow
    Write-Host "   cmake .. -DQt6_DIR=`"$qtPath\lib\cmake\Qt6`"" -ForegroundColor Gray
    exit 0
}

Write-Host "❌ Qt not found. Installing..." -ForegroundColor Yellow
Write-Host ""

# Check for vcpkg
$vcpkgPath = $null
$vcpkgPaths = @(
    "$env:VCPKG_ROOT",
    "C:\vcpkg",
    "$env:USERPROFILE\vcpkg",
    "$env:ProgramFiles\vcpkg"
)

foreach ($path in $vcpkgPaths) {
    if ($path -and (Test-Path (Join-Path $path "vcpkg.exe"))) {
        $vcpkgPath = Join-Path $path "vcpkg.exe"
        Write-Host "✅ Found vcpkg at: $vcpkgPath" -ForegroundColor Green
        break
    }
}

if ($vcpkgPath) {
    Write-Host "`n=== Installing Qt via vcpkg ===" -ForegroundColor Cyan
    Write-Host "This will install Qt5 (recommended for compatibility)" -ForegroundColor Yellow
    Write-Host ""
    
    $response = Read-Host "Install Qt5 via vcpkg? (Y/n)"
    if ($response -ne "n" -and $response -ne "N") {
        Write-Host "Installing Qt5 (this may take 10-30 minutes)..." -ForegroundColor Yellow
        Write-Host "Please wait..." -ForegroundColor Gray
        
        $installCmd = "& `"$vcpkgPath`" install qt5-base qt5-widgets qt5-network --triplet x64-windows"
        Invoke-Expression $installCmd
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`n✅ Qt5 installed successfully!" -ForegroundColor Green
            Write-Host "`n💡 Configure CMake with vcpkg toolchain:" -ForegroundColor Yellow
            Write-Host "   cmake .. -DCMAKE_TOOLCHAIN_FILE=`"$($vcpkgPath.Replace('vcpkg.exe', 'scripts\buildsystems\vcpkg.cmake'))`"" -ForegroundColor Gray
            exit 0
        } else {
            Write-Host "`n❌ vcpkg installation failed" -ForegroundColor Red
        }
    }
} else {
    Write-Host "⚠️ vcpkg not found" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "=== Installation Options ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Option 1: Install vcpkg (Recommended)" -ForegroundColor Yellow
    Write-Host "   git clone https://github.com/Microsoft/vcpkg.git C:\vcpkg" -ForegroundColor Gray
    Write-Host "   cd C:\vcpkg" -ForegroundColor Gray
    Write-Host "   .\bootstrap-vcpkg.bat" -ForegroundColor Gray
    Write-Host "   .\vcpkg integrate install" -ForegroundColor Gray
    Write-Host "   .\vcpkg install qt5-base qt5-widgets qt5-network --triplet x64-windows" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Option 2: Download Qt Installer" -ForegroundColor Yellow
    Write-Host "   Qt6: https://www.qt.io/download-qt-installer" -ForegroundColor Gray
    Write-Host "   Qt5: https://www.qt.io/offline-installers" -ForegroundColor Gray
    Write-Host "   Install to: C:\Qt" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Option 3: Use Chocolatey (if installed)" -ForegroundColor Yellow
    Write-Host "   choco install qt5-default" -ForegroundColor Gray
    Write-Host ""
    
    $response = Read-Host "Open Qt download page in browser? (Y/n)"
    if ($response -ne "n" -and $response -ne "N") {
        Start-Process "https://www.qt.io/download-qt-installer"
    }
}

Write-Host "`n=== Manual Configuration ===" -ForegroundColor Cyan
Write-Host "After installing Qt, configure CMake with Qt path:" -ForegroundColor Yellow
Write-Host "   cmake .. -DQt6_DIR=`"C:\Qt\6.x.x\msvc2019_64\lib\cmake\Qt6`"" -ForegroundColor Gray
Write-Host "   OR" -ForegroundColor Gray
Write-Host "   cmake .. -DQt5_DIR=`"C:\Qt\5.x.x\msvc2019_64\lib\cmake\Qt5`"" -ForegroundColor Gray

