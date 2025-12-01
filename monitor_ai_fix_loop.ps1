# Monitor AI_FIX_REQUEST files and automatically fix errors
# Runs in a continuous loop, checking for new AI_FIX_REQUEST files
# Enhanced version with improved looping, error handling, and configuration

param(
    [int]$CheckInterval = 10,  # Check interval in seconds
    [string]$WorkspaceRoot = "",  # Workspace root path (auto-detected if not specified)
    [switch]$Verbose,  # Verbose output mode
    [string]$LogFile = "",  # Optional log file path
    [switch]$Quiet  # Quiet mode (minimal output)
)

$ErrorActionPreference = "Continue"

# Determine workspace root
if ([string]::IsNullOrEmpty($WorkspaceRoot)) {
    # Try to detect workspace root from script location or current directory
    if ($PSScriptRoot) {
        $WorkspaceRoot = $PSScriptRoot
    } else {
        $WorkspaceRoot = Get-Location
    }
    
    # If we're in a subdirectory, try to find the root (look for common markers)
    $currentPath = $WorkspaceRoot
    $maxDepth = 5
    $depth = 0
    while ($depth -lt $maxDepth) {
        $markers = @("CMakeLists.txt", "src", "modules", ".git")
        $foundMarker = $false
        foreach ($marker in $markers) {
            if (Test-Path (Join-Path $currentPath $marker)) {
                $foundMarker = $true
                break
            }
        }
        if ($foundMarker) {
            $WorkspaceRoot = $currentPath
            break
        }
        $parentPath = Split-Path $currentPath -Parent
        if ($parentPath -eq $currentPath) {
            break
        }
        $currentPath = $parentPath
        $depth++
    }
}

$WorkspaceRoot = (Resolve-Path $WorkspaceRoot -ErrorAction SilentlyContinue).Path
if (-not $WorkspaceRoot) {
    $WorkspaceRoot = Get-Location
}

if (-not $Quiet) {
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "AI_FIX_REQUEST File Monitor & Auto-Fixer" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Workspace Root: $WorkspaceRoot" -ForegroundColor Cyan
    Write-Host "Check Interval: $CheckInterval seconds" -ForegroundColor Cyan
    Write-Host "Monitoring for new AI_FIX_REQUEST files..." -ForegroundColor Cyan
    Write-Host "Press Ctrl+C to stop`n" -ForegroundColor Gray
}

# Initialize tracking
$script:processedFiles = @{}
$script:iteration = 0
$script:totalProcessed = 0
$script:totalFixed = 0
$script:logWriter = $null

# Initialize log file if specified
if (-not [string]::IsNullOrEmpty($LogFile)) {
    try {
        $logPath = if ([System.IO.Path]::IsPathRooted($LogFile)) {
            $LogFile
        } else {
            Join-Path $WorkspaceRoot $LogFile
        }
        $script:logWriter = [System.IO.StreamWriter]::new($logPath, $true)
        $script:logWriter.AutoFlush = $true
        Write-Log "Monitor started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    }
    catch {
        Write-Warning "Could not open log file: $LogFile. Logging disabled."
    }
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    
    if ($script:logWriter) {
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $logEntry = "[$timestamp] [$Level] $Message"
        $script:logWriter.WriteLine($logEntry)
    }
    
    if (-not $Quiet) {
        switch ($Level) {
            "ERROR" { Write-Host $Message -ForegroundColor Red }
            "WARN" { Write-Host $Message -ForegroundColor Yellow }
            "SUCCESS" { Write-Host $Message -ForegroundColor Green }
            default {
                if ($Verbose) {
                    Write-Host $Message -ForegroundColor Gray
                }
            }
        }
    }
}

function Get-FileKey {
    param([System.IO.FileInfo]$File)
    # Use filename + last write time to track file modifications
    return "$($File.Name)|$($File.LastWriteTime.Ticks)"
}

function Is-FileProcessed {
    param([string]$FileKey)
    
    if ($script:processedFiles.ContainsKey($FileKey)) {
        return $true
    }
    
    # Also check if file was processed before (by name only, in case it was modified)
    $fileName = $FileKey.Split('|')[0]
    foreach ($key in $script:processedFiles.Keys) {
        if ($key.StartsWith("$fileName|")) {
            # File was processed before, but check if it was modified
            $oldTicks = [long]$key.Split('|')[1]
            $newTicks = [long]$FileKey.Split('|')[1]
            if ($newTicks -gt $oldTicks) {
                # File was modified, should reprocess
                return $false
            }
            return $true
        }
    }
    
    return $false
}

function Fix-RedefinitionError {
    param(
        [string]$Symbol,
        [string]$FilePath,
        [string]$WorkspaceRoot
    )
    
    $fixed = $false
    
    try {
        if (-not (Test-Path $FilePath)) {
            Write-Log "File not found: $FilePath" "WARN"
            return $false
        }
        
        $content = Get-Content $FilePath -Raw -ErrorAction Stop
        $originalContent = $content
        
        # Pattern 1: Fix static constexpr redefinitions by moving to header
        if ($content -match "static\s+constexpr\s+\w+\s+$Symbol\s*=") {
            Write-Log "Found static constexpr definition of $Symbol in $FilePath" "INFO"
            
            # Try to find corresponding header file
            $headerPath = $FilePath -replace '\.cpp$', '.h'
            if (-not (Test-Path $headerPath)) {
                $headerPath = $FilePath -replace '\.cpp$', '.hpp'
            }
            
            if (Test-Path $headerPath) {
                $headerContent = Get-Content $headerPath -Raw
                
                # Check if symbol already exists in header in a namespace
                if ($headerContent -notmatch "(?:namespace\s+\w+\s*\{[^}]*)?(?:inline\s+)?constexpr\s+\w+\s+$Symbol\s*=") {
                    # Add to header in a namespace if not already there
                    if ($headerContent -notmatch "namespace\s+AzthArenaConstants") {
                        # Add namespace at appropriate location
                        $insertPoint = $headerContent.IndexOf("#include")
                        if ($insertPoint -ge 0) {
                            $lastInclude = $headerContent.LastIndexOf("#include")
                            $afterIncludes = $headerContent.IndexOf("`n", $lastInclude)
                            if ($afterIncludes -ge 0) {
                                $namespaceDef = @"

// Constants moved from implementation files to avoid redefinition
namespace AzthArenaConstants
{
    inline constexpr uint32 $Symbol = 11; // Value to be determined from source
}

"@
                                $headerContent = $headerContent.Insert($afterIncludes + 1, $namespaceDef)
                                Set-Content -Path $headerPath -Value $headerContent -NoNewline -ErrorAction Stop
                                Write-Log "Added $Symbol to header namespace" "SUCCESS"
                            }
                        }
                    }
                }
                
                # Remove from .cpp file and add using directive
                $pattern = "(?s)//.*?1v1.*?constants.*?static\s+constexpr\s+\w+\s+$Symbol\s*=\s*\d+;"
                if ($content -match $pattern) {
                    $replacement = "// Constants are now defined in header`nusing namespace AzthArenaConstants;"
                    $content = $content -replace $pattern, $replacement
                    $fixed = $true
                }
            }
        }
        
        # Pattern 2: Fix const redefinitions
        if ($content -match "const\s+\w+\s+$Symbol\s*=" -and -not $content -match "static\s+const") {
            Write-Log "Found const definition of $Symbol in $FilePath" "INFO"
            # Convert to static const or move to header
            $pattern = "const\s+(\w+)\s+$Symbol\s*=\s*([^;]+);"
            if ($content -match $pattern) {
                $type = $matches[1]
                $value = $matches[2]
                $replacement = "static const $type $Symbol = $value;"
                $content = $content -replace $pattern, $replacement
                $fixed = $true
            }
        }
        
        if ($fixed -and $content -ne $originalContent) {
            Set-Content -Path $FilePath -Value $content -NoNewline -ErrorAction Stop
            Write-Log "Fixed redefinition error for $Symbol in $FilePath" "SUCCESS"
            return $true
        }
    }
    catch {
        Write-Log "Error fixing redefinition for $Symbol in $FilePath : $_" "ERROR"
        return $false
    }
    
    return $false
}

function Process-AIFixRequest {
    param(
        [string]$FilePath,
        [string]$WorkspaceRoot
    )
    
    Write-Log "`nProcessing: $FilePath" "INFO"
    
    if (-not (Test-Path $FilePath)) {
        Write-Log "File not found: $FilePath" "ERROR"
        return @{ Fixed = $false; ErrorsFound = 0 }
    }
    
    try {
        $content = Get-Content $FilePath -Raw -ErrorAction Stop
    }
    catch {
        Write-Log "Error reading file: $_" "ERROR"
        return @{ Fixed = $false; ErrorsFound = 0 }
    }
    
    $fixed = $false
    $errorsFound = 0
    
    # Enhanced error pattern matching
    $errorPatterns = @(
        "error\s+C(\d+):\s*(.+)",  # Standard MSVC error
        "error:\s*(.+)",  # Generic error
        "fatal\s+error\s+C(\d+):\s*(.+)"  # Fatal error
    )
    
    $errors = @()
    foreach ($pattern in $errorPatterns) {
        $matches = [regex]::Matches($content, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        foreach ($match in $matches) {
            $errorCode = if ($match.Groups.Count -gt 1) { $match.Groups[1].Value } else { "UNKNOWN" }
            $errorMsg = if ($match.Groups.Count -gt 2) { $match.Groups[2].Value } else { $match.Groups[1].Value }
            $errors += @{
                Code = $errorCode
                Message = $errorMsg
                FullMatch = $match.Value
            }
            $errorsFound++
        }
    }
    
    Write-Log "Found $errorsFound error(s) to fix" "INFO"
    
    # Fix BATTLEGROUND_QUEUE_1v1 redefinition errors
    if ($content -match "BATTLEGROUND_QUEUE_1v1.*redefinition") {
        Write-Log "Fixing BATTLEGROUND_QUEUE_1v1 redefinition errors..." "INFO"
        
        $azthHeader = Join-Path $WorkspaceRoot "modules" "mod-azerothshard" "src" "ASPlatform" "AZTH.h"
        $azthCpp = Join-Path $WorkspaceRoot "modules" "mod-azerothshard" "src" "ASPlatform" "AZTH.cpp"
        $azthScCpp = Join-Path $WorkspaceRoot "modules" "mod-azerothshard" "src" "ASPlatform" "AZTH_SC.cpp"
        
        # Check and fix AZTH.cpp
        if (Test-Path $azthCpp) {
            $cppFixed = Fix-RedefinitionError -Symbol "BATTLEGROUND_QUEUE_1v1" -FilePath $azthCpp -WorkspaceRoot $WorkspaceRoot
            if ($cppFixed) { $fixed = $true }
        }
        
        # Check and fix AZTH_SC.cpp
        if (Test-Path $azthScCpp) {
            $scFixed = Fix-RedefinitionError -Symbol "BATTLEGROUND_QUEUE_1v1" -FilePath $azthScCpp -WorkspaceRoot $WorkspaceRoot
            if ($scFixed) { $fixed = $true }
        }
        
        if ($fixed) {
            Write-Log "Fixed BATTLEGROUND_QUEUE_1v1 redefinition errors!" "SUCCESS"
        }
    }
    
    # Process other redefinition errors
    foreach ($error in $errors) {
        $errorCode = $error.Code
        $errorMsg = $error.Message
        
        # C2374: redefinition; multiple initialization
        # C2086: redefinition
        if ($errorCode -eq "2374" -or $errorCode -eq "2086") {
            if ($errorMsg -match "redefinition") {
                Write-Log "Detected redefinition error (C$errorCode): $errorMsg" "INFO"
                
                # Extract symbol name
                if ($errorMsg -match "'([^']+)':\s*redefinition") {
                    $symbol = $matches[1]
                    Write-Log "Symbol: $symbol" "INFO"
                    
                    # Extract file path from error message if available
                    if ($errorMsg -match "\(([^)]+)\):\s*error") {
                        $errorFilePath = $matches[1]
                        if (-not [System.IO.Path]::IsPathRooted($errorFilePath)) {
                            $errorFilePath = Join-Path $WorkspaceRoot $errorFilePath
                        }
                        
                        if (Test-Path $errorFilePath) {
                            $symbolFixed = Fix-RedefinitionError -Symbol $symbol -FilePath $errorFilePath -WorkspaceRoot $WorkspaceRoot
                            if ($symbolFixed) {
                                $fixed = $true
                            }
                        }
                    }
                }
            }
        }
    }
    
    return @{
        Fixed = $fixed
        ErrorsFound = $errorsFound
    }
}

# Main monitoring loop
Write-Log "Starting monitoring loop..." "INFO"

while ($true) {
    $script:iteration++
    
    try {
        # Find all AI_FIX_REQUEST files in workspace root
        $searchPath = Join-Path $WorkspaceRoot "*"
        $requestFiles = Get-ChildItem -Path $searchPath -Filter "AI_FIX_REQUEST_*.txt" -ErrorAction SilentlyContinue | 
            Sort-Object LastWriteTime -Descending
        
        if ($requestFiles) {
            if (-not $Quiet) {
                Write-Host "`n[$(Get-Date -Format 'HH:mm:ss')] Found $($requestFiles.Count) AI_FIX_REQUEST file(s)" -ForegroundColor Cyan
            }
            Write-Log "Found $($requestFiles.Count) AI_FIX_REQUEST file(s)" "INFO"
            
            foreach ($file in $requestFiles) {
                $fileKey = Get-FileKey -File $file
                
                # Check if this is a new or modified file
                if (-not (Is-FileProcessed -FileKey $fileKey)) {
                    if (-not $Quiet) {
                        Write-Host "`n[!] NEW/MODIFIED FILE DETECTED: $($file.Name)" -ForegroundColor Yellow
                        Write-Host "    Created: $($file.CreationTime)" -ForegroundColor Gray
                        Write-Host "    Modified: $($file.LastWriteTime)" -ForegroundColor Gray
                    }
                    Write-Log "New/modified file detected: $($file.Name)" "INFO"
                    
                    # Process the file
                    $result = Process-AIFixRequest -FilePath $file.FullName -WorkspaceRoot $WorkspaceRoot
                    
                    $script:totalProcessed++
                    if ($result.Fixed) {
                        $script:totalFixed++
                        if (-not $Quiet) {
                            Write-Host "`n[OK] Successfully processed: $($file.Name)" -ForegroundColor Green
                            Write-Host "    [->] Rebuild the project to verify fixes" -ForegroundColor Yellow
                        }
                        Write-Log "Successfully fixed errors in $($file.Name)" "SUCCESS"
                    } else {
                        if (-not $Quiet) {
                            Write-Host "`n[!] Processed but no automatic fixes applied: $($file.Name)" -ForegroundColor Yellow
                            Write-Host "    [->] Manual review may be required" -ForegroundColor Gray
                        }
                        Write-Log "Processed $($file.Name) but no fixes applied" "WARN"
                    }
                    
                    # Mark as processed
                    $script:processedFiles[$fileKey] = @{
                        Processed = $true
                        Timestamp = Get-Date
                        Fixed = $result.Fixed
                        ErrorsFound = $result.ErrorsFound
                    }
                }
            }
        } else {
            if ($script:iteration % 6 -eq 0) { # Print status every minute (6 * 10 seconds)
                if (-not $Quiet) {
                    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] No AI_FIX_REQUEST files found. Waiting... (Processed: $script:totalProcessed, Fixed: $script:totalFixed)" -ForegroundColor Gray
                }
                Write-Log "No AI_FIX_REQUEST files found. Waiting..." "INFO"
            }
        }
        
        # Wait before next check
        Start-Sleep -Seconds $CheckInterval
    }
    catch {
        Write-Log "Exception in monitoring loop: $_" "ERROR"
        Write-Log "Stack trace: $($_.ScriptStackTrace)" "ERROR"
        Write-Log "Continuing..." "WARN"
        Start-Sleep -Seconds $CheckInterval
    }
}

# Cleanup (should never reach here, but just in case)
if ($script:logWriter) {
    $script:logWriter.Close()
    $script:logWriter = $null
}
