# ============================================================
# Extract Game to htdocs
# Extracts WOTLKHD.zip to C:\xampp\htdocs\WoW\
# ============================================================

Write-Host "=== Extract Game to Web Server ===" -ForegroundColor Cyan

$xamppPath = "C:\xampp"
$htdocsPath = "$xamppPath\htdocs"
$gameZip = "$htdocsPath\WOTLKHD.zip"
$gameFolder = "$htdocsPath\WoW"

# Check if ZIP exists
if (-not (Test-Path $gameZip)) {
    Write-Host "✗ Game ZIP not found: $gameZip" -ForegroundColor Red
    Write-Host "Please place WOTLKHD.zip in: $htdocsPath" -ForegroundColor Yellow
    exit 1
}

Write-Host "✓ Game ZIP found: $gameZip" -ForegroundColor Green

# Check if already extracted
if (Test-Path "$gameFolder\Wow.exe") {
    Write-Host "`n⚠ Game already extracted at: $gameFolder" -ForegroundColor Yellow
    $overwrite = Read-Host "Overwrite existing extraction? (y/n)"
    if ($overwrite -ne 'y') {
        Write-Host "Skipping extraction." -ForegroundColor Gray
        exit 0
    }
    Write-Host "Removing existing folder..." -ForegroundColor Yellow
    Remove-Item -Path $gameFolder -Recurse -Force -ErrorAction SilentlyContinue
}

# Create WoW folder
Write-Host "`nCreating game folder: $gameFolder" -ForegroundColor Cyan
New-Item -ItemType Directory -Path $gameFolder -Force | Out-Null

# Extract ZIP
Write-Host "Extracting game files..." -ForegroundColor Cyan
Write-Host "This may take several minutes..." -ForegroundColor Yellow

try {
    # Use .NET ZipFile class (available in .NET 4.5+)
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    
    [System.IO.Compression.ZipFile]::ExtractToDirectory($gameZip, $gameFolder)
    
    Write-Host "`n✓ Extraction complete!" -ForegroundColor Green
    Write-Host "Game files extracted to: $gameFolder" -ForegroundColor Green
    
    # Verify extraction
    if (Test-Path "$gameFolder\Wow.exe") {
        Write-Host "✓ Wow.exe found - extraction successful!" -ForegroundColor Green
    } else {
        Write-Host "⚠ Wow.exe not found - extraction may have failed" -ForegroundColor Yellow
    }
    
    # Show folder size
    $folderSize = (Get-ChildItem -Path $gameFolder -Recurse | Measure-Object -Property Length -Sum).Sum / 1GB
    Write-Host "`nExtracted size: $([math]::Round($folderSize, 2)) GB" -ForegroundColor Cyan
    
} catch {
    Write-Host "`n✗ Extraction failed: $_" -ForegroundColor Red
    Write-Host "`nTrying alternative method (PowerShell Expand-Archive)..." -ForegroundColor Yellow
    
    try {
        Expand-Archive -Path $gameZip -DestinationPath $gameFolder -Force
        Write-Host "✓ Extraction complete using Expand-Archive!" -ForegroundColor Green
    } catch {
        Write-Host "✗ Both extraction methods failed: $_" -ForegroundColor Red
        Write-Host "`nPlease extract manually:" -ForegroundColor Yellow
        Write-Host "  1. Right-click WOTLKHD.zip" -ForegroundColor White
        Write-Host "  2. Select 'Extract All...'" -ForegroundColor White
        Write-Host "  3. Extract to: $gameFolder" -ForegroundColor White
        exit 1
    }
}

Write-Host "`n=== Setup Complete ===" -ForegroundColor Green
Write-Host "`nGame is now available at:" -ForegroundColor Cyan
Write-Host "  http://localhost/WoW/" -ForegroundColor White
Write-Host "`nLauncher will download files from this location." -ForegroundColor Cyan
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "  1. Update launcher config: game_zip_url = http://localhost/WoW/" -ForegroundColor White
Write-Host "  2. Test: http://localhost/WoW/Wow.exe (should download)" -ForegroundColor White

