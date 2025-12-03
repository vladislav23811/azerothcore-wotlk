# Extract All TODOs/FIXMEs from Codebase
# Generates a CSV file with all issues for tracking

param(
    [string]$OutputFile = "TODO_TRACKER.csv",
    [switch]$IncludeHeaders = $true
)

Write-Host "Scanning codebase for TODO/FIXME/HACK/BUG comments..." -ForegroundColor Cyan

$pattern = 'TODO|FIXME|XXX|HACK|BUG'
$results = @()
$fileCount = 0

# Search in source directories
$searchPaths = @(
    "src/server/game",
    "src/server/scripts",
    "src/common",
    "src/server/database",
    "modules"
)

foreach ($searchPath in $searchPaths) {
    if (Test-Path $searchPath) {
        Get-ChildItem -Path $searchPath -Include "*.cpp","*.h" -Recurse -File | ForEach-Object {
            $file = $_.FullName
            $relativePath = $file -replace [regex]::Escape((Get-Location).Path + "\"), ""
            $fileCount++
            
            $lineNum = 0
            Get-Content $file -ErrorAction SilentlyContinue | ForEach-Object {
                $lineNum++
                $line = $_
                
                if ($line -match $pattern) {
                    # Determine issue type
                    $type = "UNKNOWN"
                    if ($line -match 'TODO') { $type = "TODO" }
                    elseif ($line -match 'FIXME') { $type = "FIXME" }
                    elseif ($line -match 'HACK') { $type = "HACK" }
                    elseif ($line -match 'BUG') { $type = "BUG" }
                    elseif ($line -match 'XXX') { $type = "XXX" }
                    
                    # Determine system
                    $system = "Other"
                    if ($relativePath -match "Spells") { $system = "Spells" }
                    elseif ($relativePath -match "Player") { $system = "Player" }
                    elseif ($relativePath -match "Creature") { $system = "Creature" }
                    elseif ($relativePath -match "Combat") { $system = "Combat" }
                    elseif ($relativePath -match "Handlers") { $system = "Handlers" }
                    elseif ($relativePath -match "AI") { $system = "AI" }
                    elseif ($relativePath -match "Scripts") { $system = "Scripts" }
                    elseif ($relativePath -match "Database") { $system = "Database" }
                    elseif ($relativePath -match "Network") { $system = "Network" }
                    
                    # Estimate difficulty
                    $difficulty = "MEDIUM"
                    if ($line -match 'null|nullptr|crash|segfault') { $difficulty = "HIGH" }
                    elseif ($line -match 'logging|comment|cleanup|format') { $difficulty = "LOW" }
                    
                    $results += [PSCustomObject]@{
                        ID = "ISSUE-$($results.Count + 1)"
                        Type = $type
                        System = $system
                        Difficulty = $difficulty
                        File = $relativePath
                        Line = $lineNum
                        Content = $line.Trim() -replace '"', "'"
                        Status = "PENDING"
                        AssignedDate = ""
                        CompletedDate = ""
                        Notes = ""
                    }
                }
            }
        }
    }
}

Write-Host "Scanned $fileCount files" -ForegroundColor Green
Write-Host "Found $($results.Count) issues" -ForegroundColor Yellow

# Export to CSV
$results | Export-Csv -Path $OutputFile -NoTypeInformation -Encoding UTF8
Write-Host "Exported to $OutputFile" -ForegroundColor Green

# Print summary
Write-Host ""
Write-Host "SUMMARY BY TYPE:" -ForegroundColor Cyan
$results | Group-Object Type | ForEach-Object {
    Write-Host "  $($_.Name): $($_.Count)" -ForegroundColor White
}

Write-Host ""
Write-Host "SUMMARY BY SYSTEM:" -ForegroundColor Cyan
$results | Group-Object System | Sort-Object Count -Descending | ForEach-Object {
    Write-Host "  $($_.Name): $($_.Count)" -ForegroundColor White
}

Write-Host ""
Write-Host "SUMMARY BY DIFFICULTY:" -ForegroundColor Cyan
$results | Group-Object Difficulty | ForEach-Object {
    Write-Host "  $($_.Name): $($_.Count)" -ForegroundColor White
}

Write-Host ""
Write-Host "TOP 10 FILES WITH MOST ISSUES:" -ForegroundColor Cyan
$results | Group-Object File | Sort-Object Count -Descending | Select-Object -First 10 | ForEach-Object {
    Write-Host "  $($_.Count) - $($_.Name)" -ForegroundColor White
}

Write-Host ""
Write-Host "Use this CSV to track progress!" -ForegroundColor Green
Write-Host "  - Update Status column as you fix issues" -ForegroundColor Gray
Write-Host "  - Add CompletedDate when done" -ForegroundColor Gray
Write-Host "  - Use Notes for any important info" -ForegroundColor Gray
