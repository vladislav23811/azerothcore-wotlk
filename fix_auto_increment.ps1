# Fix AUTO_INCREMENT issue in bloody_palace_bosses table
Write-Host "=== Fixing AUTO_INCREMENT for bloody_palace_bosses table ===" -ForegroundColor Cyan

# Try to find MySQL
$mysqlPath = $null
$possiblePaths = @(
    "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe",
    "C:\Program Files\MySQL\MySQL Server 5.7\bin\mysql.exe",
    "C:\Program Files (x86)\MySQL\MySQL Server 8.0\bin\mysql.exe",
    "C:\Program Files (x86)\MySQL\MySQL Server 5.7\bin\mysql.exe",
    "mysql.exe"
)

foreach ($path in $possiblePaths) {
    if (Test-Path $path -ErrorAction SilentlyContinue) {
        $mysqlPath = $path
        Write-Host "Found MySQL at: $mysqlPath" -ForegroundColor Green
        break
    }
}

if (-not $mysqlPath) {
    Write-Host "MySQL not found in common locations." -ForegroundColor Yellow
    Write-Host "Please run this SQL manually in your MySQL client:" -ForegroundColor Yellow
    Write-Host ""
    Get-Content "fix_auto_increment.sql" | Write-Host
    Write-Host ""
    Write-Host "Or provide the path to mysql.exe" -ForegroundColor Yellow
    exit 1
}

# Prompt for MySQL credentials
Write-Host ""
$mysqlUser = Read-Host "Enter MySQL username (default: root)"
if ([string]::IsNullOrWhiteSpace($mysqlUser)) {
    $mysqlUser = "root"
}

$mysqlPass = Read-Host "Enter MySQL password" -AsSecureString
$mysqlPassPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($mysqlPass)
)

Write-Host ""
Write-Host "Running fix..." -ForegroundColor Yellow

# Run the SQL fix
$sqlContent = Get-Content "fix_auto_increment.sql" -Raw
$sqlContent | & $mysqlPath -u $mysqlUser -p"$mysqlPassPlain" 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ AUTO_INCREMENT fixed successfully!" -ForegroundColor Green
    Write-Host "You can now restart your worldserver." -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "❌ Error running MySQL command." -ForegroundColor Red
    Write-Host "Please run the SQL manually:" -ForegroundColor Yellow
    Write-Host ""
    Get-Content "fix_auto_increment.sql" | Write-Host
}

# Clear password from memory
$mysqlPassPlain = $null
[GC]::Collect()

