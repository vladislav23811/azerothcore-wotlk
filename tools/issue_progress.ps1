# Issue Progress Tracker
# Shows current progress and next recommended issue

param(
    [string]$TrackerFile = "TODO_TRACKER.csv",
    [switch]$NextIssue,
    [switch]$Stats,
    [string]$MarkComplete = "",
    [string]$System = "",
    [string]$Difficulty = ""
)

if (-not (Test-Path $TrackerFile)) {
    Write-Host "Tracker file not found: $TrackerFile" -ForegroundColor Red
    Write-Host "Run extract_todos.ps1 first to create the tracker" -ForegroundColor Yellow
    exit 1
}

# Load tracker
$issues = Import-Csv $TrackerFile

# Mark issue complete
if ($MarkComplete) {
    $issue = $issues | Where-Object { $_.ID -eq $MarkComplete }
    if ($issue) {
        $issue.Status = "COMPLETED"
        $issue.CompletedDate = Get-Date -Format "yyyy-MM-dd"
        $issues | Export-Csv -Path $TrackerFile -NoTypeInformation
        Write-Host "Marked $MarkComplete as complete!" -ForegroundColor Green
    } else {
        Write-Host "Issue $MarkComplete not found" -ForegroundColor Red
    }
    exit 0
}

# Show statistics
if ($Stats) {
    Write-Host ""
    Write-Host "ISSUE STATISTICS" -ForegroundColor Cyan
    Write-Host "===================" -ForegroundColor Cyan
    
    $total = $issues.Count
    $completed = ($issues | Where-Object { $_.Status -eq "COMPLETED" }).Count
    $pending = ($issues | Where-Object { $_.Status -eq "PENDING" }).Count
    $inProgress = ($issues | Where-Object { $_.Status -eq "IN_PROGRESS" }).Count
    $blocked = ($issues | Where-Object { $_.Status -eq "BLOCKED" }).Count
    
    $completePct = if ($total -gt 0) { [math]::Round($completed/$total*100, 1) } else { 0 }
    
    Write-Host "Total Issues:     $total" -ForegroundColor White
    Write-Host "Completed:        $completed ($completePct %)" -ForegroundColor Green
    Write-Host "In Progress:      $inProgress" -ForegroundColor Yellow
    Write-Host "Pending:          $pending" -ForegroundColor White
    Write-Host "Blocked:          $blocked" -ForegroundColor Red
    
    Write-Host ""
    Write-Host "PROGRESS BY SYSTEM:" -ForegroundColor Cyan
    $issues | Group-Object System | Sort-Object Count -Descending | ForEach-Object {
        $systemTotal = $_.Count
        $systemComplete = ($_.Group | Where-Object { $_.Status -eq "COMPLETED" }).Count
        $pct = if ($systemTotal -gt 0) { [math]::Round($systemComplete/$systemTotal*100, 1) } else { 0 }
        Write-Host "  $($_.Name): $systemComplete/$systemTotal ($pct %)" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "PROGRESS BY DIFFICULTY:" -ForegroundColor Cyan
    $issues | Group-Object Difficulty | ForEach-Object {
        $diffTotal = $_.Count
        $diffComplete = ($_.Group | Where-Object { $_.Status -eq "COMPLETED" }).Count
        $pct = if ($diffTotal -gt 0) { [math]::Round($diffComplete/$diffTotal*100, 1) } else { 0 }
        Write-Host "  $($_.Name): $diffComplete/$diffTotal ($pct %)" -ForegroundColor White
    }
    
    # Recent activity
    $recentlyCompleted = $issues | Where-Object { 
        $_.Status -eq "COMPLETED" -and $_.CompletedDate 
    } | Sort-Object CompletedDate -Descending | Select-Object -First 5
    
    if ($recentlyCompleted) {
        Write-Host ""
        Write-Host "RECENTLY COMPLETED:" -ForegroundColor Cyan
        $recentlyCompleted | ForEach-Object {
            Write-Host "  $($_.ID) - $($_.System) ($($_.CompletedDate))" -ForegroundColor Green
        }
    }
    
    exit 0
}

# Get next issue
if ($NextIssue) {
    Write-Host ""
    Write-Host "FINDING NEXT ISSUE..." -ForegroundColor Cyan
    
    # Filter by system and difficulty if specified
    $filtered = $issues | Where-Object { $_.Status -eq "PENDING" }
    
    if ($System) {
        $filtered = $filtered | Where-Object { $_.System -eq $System }
    }
    
    if ($Difficulty) {
        $filtered = $filtered | Where-Object { $_.Difficulty -eq $Difficulty }
    }
    
    # Priority: LOW difficulty first, then MEDIUM, then HIGH
    $next = $filtered | Where-Object { $_.Difficulty -eq "LOW" } | Select-Object -First 1
    if (-not $next) {
        $next = $filtered | Where-Object { $_.Difficulty -eq "MEDIUM" } | Select-Object -First 1
    }
    if (-not $next) {
        $next = $filtered | Where-Object { $_.Difficulty -eq "HIGH" } | Select-Object -First 1
    }
    
    if ($next) {
        Write-Host ""
        Write-Host "RECOMMENDED NEXT ISSUE:" -ForegroundColor Green
        Write-Host "  ID:         $($next.ID)" -ForegroundColor White
        Write-Host "  Type:       $($next.Type)" -ForegroundColor White
        Write-Host "  System:     $($next.System)" -ForegroundColor Cyan
        Write-Host "  Difficulty: $($next.Difficulty)" -ForegroundColor Yellow
        Write-Host "  File:       $($next.File):$($next.Line)" -ForegroundColor White
        Write-Host "  Content:    $($next.Content)" -ForegroundColor Gray
        
        Write-Host ""
        Write-Host "TO MARK COMPLETE:" -ForegroundColor Yellow
        Write-Host "   .\tools\issue_progress.ps1 -MarkComplete $($next.ID)" -ForegroundColor White
    } else {
        Write-Host "No pending issues found!" -ForegroundColor Green
        if ($System -or $Difficulty) {
            Write-Host "   (Try removing filters)" -ForegroundColor Gray
        }
    }
    
    exit 0
}

# Default: Show overview
Write-Host ""
Write-Host "ISSUE TRACKER OVERVIEW" -ForegroundColor Cyan
Write-Host "==========================" -ForegroundColor Cyan

$total = $issues.Count
$completed = ($issues | Where-Object { $_.Status -eq "COMPLETED" }).Count
$pending = ($issues | Where-Object { $_.Status -eq "PENDING" }).Count
$completePct = if ($total -gt 0) { [math]::Round($completed/$total*100, 1) } else { 0 }

Write-Host "Total:     $total issues" -ForegroundColor White
Write-Host "Completed: $completed ($completePct %)" -ForegroundColor Green
Write-Host "Remaining: $pending" -ForegroundColor Yellow

Write-Host ""
Write-Host "AVAILABLE COMMANDS:" -ForegroundColor Cyan
Write-Host "  -Stats              Show detailed statistics" -ForegroundColor White
Write-Host "  -NextIssue          Get next recommended issue" -ForegroundColor White
Write-Host "  -NextIssue -System Spells -Difficulty LOW" -ForegroundColor White
Write-Host "                      Get next issue filtered by system/difficulty" -ForegroundColor Gray
Write-Host "  -MarkComplete ID    Mark an issue as complete" -ForegroundColor White
