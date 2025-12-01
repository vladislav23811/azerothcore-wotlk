# Reconfigure CMake with proper Visual Studio environment

Write-Host "Reconfiguring CMake with Visual Studio environment..." -ForegroundColor Cyan

# Setup VS environment
$setupScript = Join-Path $PSScriptRoot "setup_vs_env.ps1"
if (Test-Path $setupScript) {
    . $setupScript
}

# Remove old build directory
if (Test-Path "var/build") {
    Write-Host "Removing old build directory..." -ForegroundColor Yellow
    Remove-Item "var/build" -Recurse -Force -ErrorAction SilentlyContinue
}

# Create build directory
New-Item -ItemType Directory -Path "var/build" -Force | Out-Null

# Run CMake configuration
Write-Host "Running CMake configuration..." -ForegroundColor Green
# Try VS 2026 generator (CMake may use different format, so try multiple)
$generators = @("Visual Studio 19 2022", "Visual Studio 17 2022", "Visual Studio 16 2019")
$configured = $false

foreach ($gen in $generators) {
    Write-Host "Trying generator: $gen" -ForegroundColor Gray
    cmake -B var/build -S . -G $gen -A x64 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Successfully configured with: $gen" -ForegroundColor Green
        $configured = $true
        break
    }
}

if (-not $configured) {
    # Try without specifying generator - let CMake auto-detect
    Write-Host "Trying auto-detection..." -ForegroundColor Yellow
    cmake -B var/build -S . -A x64
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "CMake configuration successful!" -ForegroundColor Green
} else {
    Write-Host "CMake configuration failed!" -ForegroundColor Red
    exit 1
}

