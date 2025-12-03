# Batch Process Issues
# Generate prompts for processing multiple issues

param(
    [string]$TrackerFile = "TODO_TRACKER.csv",
    [int]$Count = 5,
    [string]$System = "",
    [string]$Difficulty = "",
    [string]$Priority = "Priority1"
)

if (-not (Test-Path $TrackerFile)) {
    Write-Host "❌ Tracker file not found: $TrackerFile" -ForegroundColor Red
    Write-Host "💡 Run extract_todos.ps1 first" -ForegroundColor Yellow
    exit 1
}

$issues = Import-Csv $TrackerFile

# Filter
$filtered = $issues | Where-Object { $_.Status -eq "PENDING" }

if ($System) {
    $filtered = $filtered | Where-Object { $_.System -eq $System }
}

if ($Difficulty) {
    $filtered = $filtered | Where-Object { $_.Difficulty -eq $Difficulty }
}

# Get batch
$batch = $filtered | Select-Object -First $Count

if ($batch.Count -eq 0) {
    Write-Host "❌ No issues found matching criteria" -ForegroundColor Red
    exit 1
}

Write-Host "`n🎯 BATCH PROCESSING PLAN" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
Write-Host "Issues to process: $($batch.Count)" -ForegroundColor White
if ($System) { Write-Host "System: $System" -ForegroundColor Cyan }
if ($Difficulty) { Write-Host "Difficulty: $Difficulty" -ForegroundColor Yellow }

Write-Host "`n📋 ISSUES IN THIS BATCH:" -ForegroundColor Cyan
$batch | ForEach-Object {
    Write-Host "  [$($_.ID)] $($_.System) - $($_.Type) ($($_.Difficulty))" -ForegroundColor White
    Write-Host "     File: $($_.File):$($_.Line)" -ForegroundColor Gray
    Write-Host "     $($_.Content.Substring(0, [Math]::Min(80, $_.Content.Length)))" -ForegroundColor DarkGray
    Write-Host ""
}

Write-Host "`n🤖 RECOMMENDED PROMPT:" -ForegroundColor Green
Write-Host "======================" -ForegroundColor Green

$prompt = @"
Process the following $($batch.Count) issues systematically:

"@

$i = 1
foreach ($issue in $batch) {
    $prompt += @"
$i. [$($issue.ID)] $($issue.System) - $($issue.Type)
   File: $($issue.File):$($issue.Line)
   Issue: $($issue.Content)
   Difficulty: $($issue.Difficulty)

"@
    $i++
}

$prompt += @"

For each issue:
1. Read and understand the TODO/FIXME comment
2. Locate the relevant code
3. Implement the fix properly
4. Add error handling if needed
5. Test the fix
6. Remove or update the comment
7. Mark the issue as complete in TODO_TRACKER.csv

After completing all issues, generate a summary report.
"@

Write-Host $prompt -ForegroundColor White

Write-Host "`n💾 COPY-PASTE READY PROMPT SAVED TO: batch_prompt.txt" -ForegroundColor Yellow
$prompt | Out-File "batch_prompt.txt" -Encoding UTF8

Write-Host "`n✨ AFTER COMPLETION, RUN:" -ForegroundColor Cyan
Write-Host "   .\tools\issue_progress.ps1 -Stats" -ForegroundColor White

