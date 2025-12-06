# ============================================================
# Create filelist.txt for WoW game folder
# Generates a list of all files in the WoW folder for launcher
# ============================================================

param(
    [string]$WoWPath = "C:\xampp\htdocs\WoW",
    [string]$OutputFile = "C:\xampp\htdocs\WoW\filelist.txt"
)

Write-Host "=== Creating WoW File List ===" -ForegroundColor Cyan
Write-Host "Source: $WoWPath" -ForegroundColor White
Write-Host "Output: $OutputFile" -ForegroundColor White

if (-not (Test-Path $WoWPath)) {
    Write-Host "ERROR: WoW folder not found: $WoWPath" -ForegroundColor Red
    Write-Host "Please extract your WoW client to this location." -ForegroundColor Yellow
    exit 1
}

Write-Host "`nScanning files..." -ForegroundColor Yellow

$files = Get-ChildItem -Path $WoWPath -Recurse -File | ForEach-Object {
    # Get relative path from WoW folder
    $relativePath = $_.FullName.Substring($WoWPath.Length + 1)
    # Convert to forward slashes for URLs
    $relativePath = $relativePath -replace '\\', '/'
    $relativePath
}

Write-Host "Found $($files.Count) files" -ForegroundColor Green

# Write to file
$files | Out-File -FilePath $OutputFile -Encoding UTF8

Write-Host "`nFile list created: $OutputFile" -ForegroundColor Green
Write-Host "Total files: $($files.Count)" -ForegroundColor White

# Show first few files as preview
Write-Host "`nPreview (first 10 files):" -ForegroundColor Cyan
$files | Select-Object -First 10 | ForEach-Object {
    Write-Host "  $_" -ForegroundColor Gray
}

Write-Host "`n=== Done ===" -ForegroundColor Green
Write-Host "Launcher can now download files from: http://localhost/WoW/" -ForegroundColor White

