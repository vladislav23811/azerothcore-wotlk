# Continuous Improvement Loop Script
# Builds, fixes errors, and modernizes code in a loop

$ErrorActionPreference = "Continue"
$startTime = Get-Date
$maxDuration = New-TimeSpan -Hours 8
$buildDir = "var/build"
$iteration = 0
$lastErrorCount = 0
$consecutiveSuccessCount = 0

Write-Host "Starting continuous improvement loop..." -ForegroundColor Green
Write-Host "Target duration: 8 hours" -ForegroundColor Green
Write-Host "Start time: $startTime" -ForegroundColor Green
Write-Host ""

function Build-Project {
    param([string]$Target = "all")
    
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Building target: $Target" -ForegroundColor Cyan
    
    $buildOutput = cmake --build $buildDir --config Debug --target $Target 2>&1
    $exitCode = $LASTEXITCODE
    
    # Count errors
    $errorLines = $buildOutput | Select-String -Pattern "error C\d+:" | Measure-Object
    $errorCount = $errorLines.Count
    
    return @{
        ExitCode = $exitCode
        ErrorCount = $errorCount
        Output = $buildOutput
    }
}

function Extract-Errors {
    param([string[]]$BuildOutput)
    
    $errors = @()
    foreach ($line in $BuildOutput) {
        if ($line -match "error C\d+:" -or $line -match "fatal error") {
            $errors += $line
        }
    }
    return $errors
}

function Modernize-Code {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Starting code modernization..." -ForegroundColor Yellow
    
    # Find all C++ files
    $cppFiles = Get-ChildItem -Path . -Include *.cpp,*.h,*.hpp -Recurse -Exclude "var","_deps" | 
        Where-Object { $_.FullName -notmatch "\\var\\" -and $_.FullName -notmatch "\\_deps\\" }
    
    Write-Host "Found $($cppFiles.Count) C++ files to potentially modernize" -ForegroundColor Yellow
    
    # Find all SQL files
    $sqlFiles = Get-ChildItem -Path . -Include *.sql -Recurse -Exclude "var","_deps" |
        Where-Object { $_.FullName -notmatch "\\var\\" -and $_.FullName -notmatch "\\_deps\\" }
    
    Write-Host "Found $($sqlFiles.Count) SQL files to potentially modernize" -ForegroundColor Yellow
    
    # Find all Lua files
    $luaFiles = Get-ChildItem -Path . -Include *.lua -Recurse -Exclude "var","_deps" |
        Where-Object { $_.FullName -notmatch "\\var\\" -and $_.FullName -notmatch "\\_deps\\" }
    
    Write-Host "Found $($luaFiles.Count) Lua files to potentially modernize" -ForegroundColor Yellow
    
    # Note: Actual modernization would be done by AI/automated tools
    # This is a placeholder for the improvement process
    Write-Host "Code modernization placeholder - would run improvements here" -ForegroundColor Yellow
}

# Main loop
while ((Get-Date) -lt ($startTime + $maxDuration)) {
    $iteration++
    $elapsed = (Get-Date) - $startTime
    
    Write-Host "`n========================================" -ForegroundColor Magenta
    Write-Host "Iteration: $iteration | Elapsed: $($elapsed.ToString('hh\:mm\:ss'))" -ForegroundColor Magenta
    Write-Host "========================================`n" -ForegroundColor Magenta
    
    # Build the project
    $buildResult = Build-Project -Target "all"
    
    if ($buildResult.ExitCode -eq 0 -and $buildResult.ErrorCount -eq 0) {
        $consecutiveSuccessCount++
        Write-Host "`n✓ Build successful! (Consecutive: $consecutiveSuccessCount)" -ForegroundColor Green
        
        if ($consecutiveSuccessCount -ge 2) {
            Write-Host "Multiple successful builds - starting modernization..." -ForegroundColor Green
            Modernize-Code
            Start-Sleep -Seconds 5
        }
    }
    else {
        $consecutiveSuccessCount = 0
        Write-Host "`n✗ Build failed with $($buildResult.ErrorCount) errors" -ForegroundColor Red
        
        $errors = Extract-Errors -BuildOutput $buildResult.Output
        if ($errors.Count -gt 0) {
            Write-Host "`nTop errors:" -ForegroundColor Red
            $errors | Select-Object -First 10 | ForEach-Object {
                Write-Host "  $_" -ForegroundColor Red
            }
        }
        
        # Wait a bit before retrying
        Start-Sleep -Seconds 10
    }
    
    # Check if we should continue
    $remaining = ($startTime + $maxDuration) - (Get-Date)
    if ($remaining.TotalSeconds -le 0) {
        Write-Host "`nMaximum duration reached. Stopping." -ForegroundColor Yellow
        break
    }
    
    Write-Host "`nRemaining time: $($remaining.ToString('hh\:mm\:ss'))" -ForegroundColor Cyan
    Write-Host "Waiting 30 seconds before next iteration...`n" -ForegroundColor Cyan
    Start-Sleep -Seconds 30
}

$totalElapsed = (Get-Date) - $startTime
Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "Loop completed!" -ForegroundColor Green
Write-Host "Total iterations: $iteration" -ForegroundColor Green
Write-Host "Total elapsed time: $($totalElapsed.ToString('hh\:mm\:ss'))" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Magenta

