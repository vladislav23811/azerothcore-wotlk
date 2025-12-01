# Progress Monitor for Improvement Loop
# Run this in a separate terminal to monitor progress

$logFile = "improvement_progress.log"
$buildDir = "var/build"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Improvement Loop Progress Monitor" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

function Show-Progress {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Checking progress..." -ForegroundColor Yellow
    
    # Check for new feature files
    $featureDirs = Get-ChildItem -Path "modules/mod-azerothshard/src/Features" -Directory -ErrorAction SilentlyContinue
    if ($featureDirs) {
        Write-Host "`nFeatures Added:" -ForegroundColor Green
        foreach ($dir in $featureDirs) {
            Write-Host "  - $($dir.Name)" -ForegroundColor Green
        }
    }
    
    # Check build status
    if (Test-Path "$buildDir\modules\modules.lib") {
        $libTime = (Get-Item "$buildDir\modules\modules.lib").LastWriteTime
        Write-Host "`nLast successful build: $libTime" -ForegroundColor Cyan
    }
    
    # Count modernized files (files with nullptr)
    $modernizedFiles = Get-ChildItem -Path "modules" -Include *.cpp,*.h -Recurse -ErrorAction SilentlyContinue |
        Select-String -Pattern "nullptr" -List |
        Select-Object -ExpandProperty Path -Unique
    
    if ($modernizedFiles) {
        Write-Host "`nModernized files (using nullptr): $($modernizedFiles.Count)" -ForegroundColor Yellow
    }
    
    # Check for errors in build log
    if (Test-Path "$buildDir\build.log") {
        $errors = Get-Content "$buildDir\build.log" -ErrorAction SilentlyContinue |
            Select-String -Pattern "error C\d+:" |
            Measure-Object
        
        if ($errors.Count -gt 0) {
            Write-Host "`nBuild errors found: $($errors.Count)" -ForegroundColor Red
        }
    }
}

# Monitor loop
while ($true) {
    Clear-Host
    Show-Progress
    Write-Host "`nPress Ctrl+C to stop monitoring" -ForegroundColor Gray
    Start-Sleep -Seconds 30
}

