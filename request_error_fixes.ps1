# Request Error Fixes from AI
# This script analyzes unfixable errors and prepares a request for the AI

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Error Fix Request Generator" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan

$logFile = "unfixable_errors.log"
if (-not (Test-Path $logFile)) {
    Write-Host "No unfixable errors found!" -ForegroundColor Green
    Write-Host "The improvement loop is handling all errors automatically.`n" -ForegroundColor Yellow
    exit 0
}

Write-Host "Analyzing unfixable errors from: $logFile`n" -ForegroundColor Yellow

# Read and analyze errors
$errors = Get-Content $logFile -Raw
$errorCount = ($errors -split "========================================").Count - 1

Write-Host "Found $errorCount unfixable error(s)`n" -ForegroundColor Cyan

# Extract unique error patterns
$errorPatterns = @()
$errorTypes = @()

if ($errors -match "Error Type: (.+?)\r?\n") {
    $errorTypes = [regex]::Matches($errors, "Error Type: (.+?)\r?\n") | ForEach-Object { $_.Groups[1].Value }
}

if ($errors -match "Cannot open include file: '(.+?)'") {
    $errorPatterns = [regex]::Matches($errors, "Cannot open include file: '(.+?)'") | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
}

# Generate fix request
$requestFile = "AI_FIX_REQUEST_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$request = @"
========================================
AUTOMATED ERROR FIX REQUEST FOR AI
========================================
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Total Unfixable Errors: $errorCount

ERROR SUMMARY:
=============
Unique Error Types Found:
$($errorTypes | Select-Object -Unique | ForEach-Object { "  - $_" })

Missing Headers Detected:
$($errorPatterns | ForEach-Object { "  - $_" })

FULL ERROR LOG:
==============
$errors

REQUEST:
========
Please add automatic fix logic to the improve_loop_enhanced.ps1 script
for the error types listed above. The Fix-CommonErrors function should
be enhanced to handle these cases automatically.

Copy this file content and share it with the AI assistant to get fixes added.
"@

Set-Content -Path $requestFile -Value $request

Write-Host "========================================" -ForegroundColor Green
Write-Host "Fix Request Generated!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

Write-Host "File created: $requestFile" -ForegroundColor Cyan
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "  1. Open the file: $requestFile" -ForegroundColor White
Write-Host "  2. Copy its contents" -ForegroundColor White
Write-Host "  3. Share it with the AI assistant" -ForegroundColor White
Write-Host "  4. The AI will add fix logic to the script`n" -ForegroundColor White

Write-Host "Or simply say to the AI:" -ForegroundColor Cyan
Write-Host "  'Add fix logic for the errors in unfixable_errors.log'`n" -ForegroundColor White

