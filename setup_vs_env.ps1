# Setup Visual Studio Environment Variables
# This script initializes the Visual Studio environment for building

# Auto-detect Visual Studio installation
$vsVersions = @(
    "C:\Program Files\Microsoft Visual Studio\18\Community",  # VS 2022 (version 18)
    "C:\Program Files\Microsoft Visual Studio\2026\Community",
    "C:\Program Files\Microsoft Visual Studio\2022\Community",
    "C:\Program Files\Microsoft Visual Studio\2019\Community"
)

$vsPath = $null
$vsBasePath = $null

foreach ($vsBase in $vsVersions) {
    $testPath = Join-Path $vsBase "VC\Auxiliary\Build\vcvarsall.bat"
    if (Test-Path $testPath) {
        $vsPath = $testPath
        $vsBasePath = $vsBase
        Write-Host "Found Visual Studio at: $vsBase" -ForegroundColor Green
        break
    }
}

if ($vsPath -and (Test-Path $vsPath)) {
    Write-Host "Setting up Visual Studio environment..." -ForegroundColor Green
    
    # Call vcvarsall.bat and capture environment variables
    $tempFile = [System.IO.Path]::GetTempFileName()
    cmd /c "`"$vsPath`" x64 > `"$tempFile`" 2>&1 && set > `"$tempFile`""
    
    # Read the environment variables
    $envVars = Get-Content $tempFile | Where-Object { $_ -match "^[A-Z_]+=" }
    
    foreach ($line in $envVars) {
        if ($line -match "^([^=]+)=(.*)$") {
            $name = $matches[1]
            $value = $matches[2]
            [System.Environment]::SetEnvironmentVariable($name, $value, "Process")
        }
    }
    
    Remove-Item $tempFile -ErrorAction SilentlyContinue
    
    # Manually set critical paths if vcvarsall didn't work
    # Use detected VS base path or try to find it
    if (-not $vsBasePath) {
        foreach ($vsBase in $vsVersions) {
            if (Test-Path $vsBase) {
                $vsBasePath = $vsBase
                break
            }
        }
    }
    
    # Try to find the latest MSVC version
    $msvcBasePath = Join-Path $vsBasePath "VC\Tools\MSVC"
    $msvcPath = $null
    if (Test-Path $msvcBasePath) {
        $msvcVersions = Get-ChildItem $msvcBasePath -Directory | Sort-Object Name -Descending
        if ($msvcVersions) {
            $msvcPath = $msvcVersions[0].FullName
            Write-Host "  Found MSVC version: $($msvcVersions[0].Name)" -ForegroundColor Green
        }
    }
    if (Test-Path $msvcPath) {
        $includePath = Join-Path $msvcPath "include"
        $libPath = Join-Path $msvcPath "lib\x64"
        $binPath = Join-Path $msvcPath "bin\Hostx64\x64"
        
        if (Test-Path $includePath) {
            if (-not $env:INCLUDE) {
                $env:INCLUDE = $includePath
            } else {
                $env:INCLUDE = "$includePath;$env:INCLUDE"
            }
            Write-Host "  Added to INCLUDE: $includePath" -ForegroundColor Green
        }
        
        if (Test-Path $libPath) {
            if (-not $env:LIB) {
                $env:LIB = $libPath
            } else {
                $env:LIB = "$libPath;$env:LIB"
            }
            Write-Host "  Added to LIB: $libPath" -ForegroundColor Green
        }
        
        if (Test-Path $binPath) {
            if (-not $env:PATH) {
                $env:PATH = $binPath
            } else {
                $env:PATH = "$binPath;$env:PATH"
            }
            Write-Host "  Added to PATH: $binPath" -ForegroundColor Green
        }
    }
    
    # Also add Windows SDK paths (CRITICAL for C runtime headers)
    $windowsSdkPath = "C:\Program Files (x86)\Windows Kits\10\Include"
    if (Test-Path $windowsSdkPath) {
        $latestSdk = Get-ChildItem $windowsSdkPath -Directory | Sort-Object Name -Descending | Select-Object -First 1
        if ($latestSdk) {
            $sdkInclude = $latestSdk.FullName
            $sdkUcrt = Join-Path $latestSdk.FullName "ucrt"
            $sdkUm = Join-Path $latestSdk.FullName "um"
            $sdkWinrt = Join-Path $latestSdk.FullName "winrt"
            $sdkShared = Join-Path $latestSdk.FullName "shared"  # lowercase "shared" in Include\version\shared\
            
            # Add Shared path first (contains winapifamily.h, etc.)
            if (Test-Path $sdkShared) {
                $env:INCLUDE = "$sdkShared;$env:INCLUDE"
                Write-Host "  Added Shared (winapifamily.h, etc.): $sdkShared" -ForegroundColor Green
            }
            
            # Add UCRT (contains crtdbg.h, stddef.h, math.h, etc.)
            if (Test-Path $sdkUcrt) {
                $env:INCLUDE = "$sdkUcrt;$env:INCLUDE"
                Write-Host "  Added UCRT (C runtime): $sdkUcrt" -ForegroundColor Green
            }
            
            # Add other SDK paths
            $env:INCLUDE = "$sdkInclude;$sdkUm;$sdkWinrt;$env:INCLUDE"
            Write-Host "  Added Windows SDK: $sdkInclude" -ForegroundColor Green
            Write-Host "  Added UM: $sdkUm" -ForegroundColor Green
        }
    }
    
    # Also check for Windows SDK in Program Files (64-bit)
    $windowsSdkPath64 = "C:\Program Files\Windows Kits\10\Include"
    if (Test-Path $windowsSdkPath64) {
        $latestSdk64 = Get-ChildItem $windowsSdkPath64 -Directory | Sort-Object Name -Descending | Select-Object -First 1
        if ($latestSdk64) {
            $sdkShared64 = Join-Path $latestSdk64.FullName "shared"  # lowercase "shared"
            $sdkUcrt64 = Join-Path $latestSdk64.FullName "ucrt"
            
            # Add Shared path if not already added
            if (Test-Path $sdkShared64 -and $env:INCLUDE -notlike "*$sdkShared64*") {
                $env:INCLUDE = "$sdkShared64;$env:INCLUDE"
                Write-Host "  Added Shared (64-bit): $sdkShared64" -ForegroundColor Green
            }
            
            # Add UCRT if not already added
            if (Test-Path $sdkUcrt64 -and $env:INCLUDE -notlike "*$sdkUcrt64*") {
                $env:INCLUDE = "$sdkUcrt64;$env:INCLUDE"
                Write-Host "  Added UCRT (64-bit): $sdkUcrt64" -ForegroundColor Green
            }
        }
    }
    
    # Add VC Tools atexe path (for C runtime headers)
    # Use the same detected MSVC path
    $vcToolsPath = $msvcPath
    if (Test-Path $vcToolsPath) {
        $vcAtexe = Join-Path $vcToolsPath "atlmfc\include"
        if (Test-Path $vcAtexe) {
            $env:INCLUDE = "$vcAtexe;$env:INCLUDE"
            Write-Host "  Added VC atlmfc to INCLUDE: $vcAtexe" -ForegroundColor Green
        }
    }
    
    Write-Host "Environment setup complete!" -ForegroundColor Green
    Write-Host "INCLUDE: $env:INCLUDE" -ForegroundColor Cyan
    return $true
} else {
    # Try to set up manually even if vcvarsall.bat not found
    Write-Host "vcvarsall.bat not found, setting up manually..." -ForegroundColor Yellow
    
    # Find VS installation
    if (-not $vsBasePath) {
        foreach ($vsBase in $vsVersions) {
            if (Test-Path $vsBase) {
                $vsBasePath = $vsBase
                Write-Host "Found Visual Studio at: $vsBase" -ForegroundColor Green
                break
            }
        }
    }
    
    if ($vsBasePath) {
        # Set up paths manually
        $msvcBasePath = Join-Path $vsBasePath "VC\Tools\MSVC"
        if (Test-Path $msvcBasePath) {
            $msvcVersions = Get-ChildItem $msvcBasePath -Directory | Sort-Object Name -Descending
            if ($msvcVersions) {
                $msvcPath = $msvcVersions[0].FullName
                $includePath = Join-Path $msvcPath "include"
                $libPath = Join-Path $msvcPath "lib\x64"
                $binPath = Join-Path $msvcPath "bin\Hostx64\x64"
                
                if (Test-Path $includePath) {
                    $env:INCLUDE = "$includePath;$env:INCLUDE"
                    Write-Host "  Added to INCLUDE: $includePath" -ForegroundColor Green
                }
                if (Test-Path $libPath) {
                    $env:LIB = "$libPath;$env:LIB"
                    Write-Host "  Added to LIB: $libPath" -ForegroundColor Green
                }
                if (Test-Path $binPath) {
                    $env:PATH = "$binPath;$env:PATH"
                    Write-Host "  Added to PATH: $binPath" -ForegroundColor Green
                }
            }
        }
        
        # Add Windows SDK paths (CRITICAL for C runtime headers)
        $windowsSdkPath = "C:\Program Files (x86)\Windows Kits\10\Include"
        if (Test-Path $windowsSdkPath) {
            $latestSdk = Get-ChildItem $windowsSdkPath -Directory | Sort-Object Name -Descending | Select-Object -First 1
            if ($latestSdk) {
                $sdkUcrt = Join-Path $latestSdk.FullName "ucrt"
                $sdkUm = Join-Path $latestSdk.FullName "um"
                $sdkWinrt = Join-Path $latestSdk.FullName "winrt"
                $sdkShared = Join-Path $latestSdk.FullName "shared"  # lowercase "shared"
                
                # Add Shared path first (contains winapifamily.h, etc.)
                if (Test-Path $sdkShared) {
                    $env:INCLUDE = "$sdkShared;$env:INCLUDE"
                    Write-Host "  Added Shared (winapifamily.h): $sdkShared" -ForegroundColor Green
                }
                
                # Add UCRT (contains crtdbg.h, stddef.h, math.h, etc.)
                if (Test-Path $sdkUcrt) {
                    $env:INCLUDE = "$sdkUcrt;$env:INCLUDE"
                    Write-Host "  Added UCRT (C runtime): $sdkUcrt" -ForegroundColor Green
                }
                
                # Add other SDK paths
                $env:INCLUDE = "$sdkUm;$sdkWinrt;$env:INCLUDE"
                Write-Host "  Added Windows SDK paths" -ForegroundColor Green
            }
        }
        
        Write-Host "Manual environment setup complete!" -ForegroundColor Green
        Write-Host "INCLUDE: $env:INCLUDE" -ForegroundColor Cyan
        return $true
    } else {
        Write-Host "Visual Studio not found in standard locations" -ForegroundColor Red
        return $false
    }
}

