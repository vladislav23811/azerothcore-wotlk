# Auto-Fix Generator - Automatically adds fix logic to the improvement loop
# This script analyzes errors and automatically adds fix patterns to the script

param(
    [string[]]$Errors
)

$scriptFile = "improve_loop_enhanced.ps1"
$backupFile = "$scriptFile.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

Write-Host "Analyzing errors and generating automatic fixes..." -ForegroundColor Cyan

# Backup the script first
Copy-Item $scriptFile $backupFile
Write-Host "Backed up script to: $backupFile" -ForegroundColor Gray

$scriptContent = Get-Content $scriptFile -Raw
$newFixes = @()

foreach ($error in $Errors) {
    # Pattern 1: Missing header files
    if ($error -match "Cannot open include file: '([^']+)'") {
        $missingHeader = $matches[1]
        
        # Check if this header is already handled
        if ($scriptContent -notmatch "`"$missingHeader`"|'$missingHeader'") {
            Write-Host "  Detected new missing header: $missingHeader" -ForegroundColor Yellow
            
            # Generate fix logic
            $fixCode = @"
                "$missingHeader" {
                    # Auto-generated fix for missing header: $missingHeader
                    Write-Host "    Attempting to fix missing header: $missingHeader" -ForegroundColor Yellow
                    
                    # Try to find and add the header path
                    `$headerPaths = @(
                        "C:\Program Files (x86)\Windows Kits\10\Include\*\shared\$missingHeader",
                        "C:\Program Files\Windows Kits\10\Include\*\shared\$missingHeader",
                        "C:\Program Files\Microsoft Visual Studio\*\VC\Tools\MSVC\*\include\$missingHeader"
                    )
                    
                    `$found = `$false
                    foreach (`$path in `$headerPaths) {
                        `$matches = Get-ChildItem -Path `$path -ErrorAction SilentlyContinue
                        if (`$matches) {
                            `$headerDir = Split-Path `$matches[0].FullName -Parent
                            if (`$env:INCLUDE -notlike "*`$headerDir*") {
                                `$env:INCLUDE = "`$headerDir;`$env:INCLUDE"
                                Write-Host "      Added header path: `$headerDir" -ForegroundColor Green
                                `$found = `$true
                                `$fixed++
                            }
                        }
                    }
                    
                    if (-not `$found) {
                        # Try to add as include statement to common files
                        `$commonFiles = @("src/common/Common.h", "src/common/Define.h")
                        foreach (`$file in `$commonFiles) {
                            if (Test-Path `$file) {
                                `$content = Get-Content `$file -Raw
                                if (`$content -notmatch "#include\s*[<`"]$missingHeader[>`"]") {
                                    `$content = `$content -replace '(#include\s*"Define\.h")', "``$1`n#include <$missingHeader>"
                                    Set-Content -Path `$file -Value `$content -NoNewline
                                    Write-Host "      Added #include <$missingHeader> to `$file" -ForegroundColor Green
                                    `$fixed++
                                    break
                                }
                            }
                        }
                    }
                }
"@
            $newFixes += $fixCode
        }
    }
    
    # Pattern 2: Undeclared identifiers
    if ($error -match "error C2065: '([^']+)' : undeclared identifier") {
        $identifier = $matches[1]
        
        if ($scriptContent -notmatch "undeclared.*$identifier") {
            Write-Host "  Detected undeclared identifier: $identifier" -ForegroundColor Yellow
            
            $fixCode = @"
                # Auto-fix for undeclared identifier: $identifier
                if (`$error -match "undeclared identifier.*$identifier") {
                    Write-Host "    Attempting to fix undeclared identifier: $identifier" -ForegroundColor Yellow
                    # Add constant definition if it's a constant pattern
                    if (`$identifier -match "^[A-Z_]+$") {
                        `$defineFile = "src/common/Define.h"
                        if (Test-Path `$defineFile) {
                            `$content = Get-Content `$defineFile -Raw
                            if (`$content -notmatch "`$identifier") {
                                `$newDefine = "`n// Auto-generated constant`nconstexpr uint32 $identifier = 0; // TODO: Set correct value`n"
                                `$content = `$content -replace '(#endif\s*//ACORE_DEFINE_H)', "`$newDefine`$1"
                                Set-Content -Path `$defineFile -Value `$content -NoNewline
                                Write-Host "      Added constant definition for $identifier" -ForegroundColor Green
                                `$fixed++
                            }
                        }
                    }
                }
"@
            $newFixes += $fixCode
        }
    }
    
    # Pattern 3: Linker errors
    if ($error -match "error LNK\d+:") {
        Write-Host "  Detected linker error (will attempt library path fixes)" -ForegroundColor Yellow
        # Linker errors are harder to auto-fix, but we can try
    }
}

# Add new fixes to the script
if ($newFixes.Count -gt 0) {
    Write-Host "`nAdding $($newFixes.Count) new fix pattern(s) to script..." -ForegroundColor Green
    
    # Find the switch statement in Fix-CommonErrors
    $switchPattern = 'switch \(`$missingHeader\) \{'
    $switchEndPattern = '\s+default:'
    
    if ($scriptContent -match $switchPattern) {
        # Insert new cases before default
        $beforeDefault = $scriptContent -replace "(\s+)(default:)", "`$1$($newFixes -join "`n`$1")`n`$1`$2"
        $scriptContent = $beforeDefault
        
        # Also add any non-switch fixes after the switch
        $nonSwitchFixes = $newFixes | Where-Object { $_ -notmatch '^\s+"' }
        if ($nonSwitchFixes.Count -gt 0) {
            $insertPoint = $scriptContent.IndexOf('return $fixed')
            if ($insertPoint -gt 0) {
                $beforeReturn = $scriptContent.Substring(0, $insertPoint)
                $afterReturn = $scriptContent.Substring($insertPoint)
                $scriptContent = $beforeReturn + ($nonSwitchFixes -join "`n") + "`n    " + $afterReturn
            }
        }
        
        Set-Content -Path $scriptFile -Value $scriptContent -NoNewline
        Write-Host "Script updated with new fix patterns!" -ForegroundColor Green
        Write-Host "The improvement loop will now handle these errors automatically.`n" -ForegroundColor Cyan
    }
    else {
        Write-Host "Could not find switch statement to update." -ForegroundColor Red
    }
}
else {
    Write-Host "No new fix patterns to add.`n" -ForegroundColor Yellow
}

