# Auto-check for unfixable errors and prepare AI request
# Run this periodically or schedule it to check for new errors

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Automated Error Checker" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan

$logFile = "unfixable_errors.log"
$lastCheckFile = "last_error_check.txt"

# Check if error log exists and has new content
if (-not (Test-Path $logFile)) {
    Write-Host "No errors logged yet. The improvement loop is handling everything!`n" -ForegroundColor Green
    exit 0
}

$logContent = Get-Content $logFile -Raw
if ([string]::IsNullOrWhiteSpace($logContent)) {
    Write-Host "Error log is empty. All good!`n" -ForegroundColor Green
    exit 0
}

# Check if we've seen these errors before
$lastCheckHash = $null
if (Test-Path $lastCheckFile) {
    $lastCheckHash = Get-Content $lastCheckFile -Raw
}

$currentHash = (Get-FileHash $logFile -Algorithm MD5).Hash

if ($lastCheckHash -eq $currentHash) {
    Write-Host "No new errors since last check.`n" -ForegroundColor Yellow
    exit 0
}

# New errors detected!
Write-Host "⚠️  NEW UNFIXABLE ERRORS DETECTED!`n" -ForegroundColor Red

# Generate AI request automatically
Write-Host "Generating AI fix request...`n" -ForegroundColor Yellow

$errors = Get-Content $logFile -Raw
$errorCount = ($errors -split "========================================").Count - 1

# Extract error patterns
$errorPatterns = @()
$errorTypes = @()

if ($errors -match "Error Type: (.+?)\r?\n") {
    $errorTypes = [regex]::Matches($errors, "Error Type: (.+?)\r?\n") | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
}

if ($errors -match "Cannot open include file: '(.+?)'") {
    $errorPatterns = [regex]::Matches($errors, "Cannot open include file: '(.+?)'") | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
}

# Generate formatted request
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
$($errorTypes | ForEach-Object { "  - $_" })

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

Copy the content below and paste it in a message to the AI assistant.
"@

Set-Content -Path $requestFile -Value $request

# Save current hash
Set-Content -Path $lastCheckFile -Value $currentHash

Write-Host "========================================" -ForegroundColor Green
Write-Host "AI Request Generated!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

Write-Host "File: $requestFile" -ForegroundColor Cyan
Write-Host "Errors found: $errorCount`n" -ForegroundColor Yellow

Write-Host "TO GET AI TO FIX THESE ERRORS:" -ForegroundColor Cyan
Write-Host "1. Open: $requestFile" -ForegroundColor White
Write-Host "2. Copy its contents" -ForegroundColor White
Write-Host "3. Paste it in a message to the AI assistant" -ForegroundColor White
Write-Host "4. Or simply say: 'Fix the errors in unfixable_errors.log'`n" -ForegroundColor White

Write-Host "The AI will add automatic fix logic to the script!`n" -ForegroundColor Green

# Display a preview
Write-Host "Preview of errors:" -ForegroundColor Yellow
$errorTypes | Select-Object -First 5 | ForEach-Object {
    Write-Host "  - $_" -ForegroundColor Gray
}
if ($errorTypes.Count -gt 5) {
    Write-Host "  ... and $($errorTypes.Count - 5) more" -ForegroundColor Gray
}
Write-Host ""

