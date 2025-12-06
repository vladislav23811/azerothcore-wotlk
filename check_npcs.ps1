# Check NPC Setup in Database
# This script checks if NPCs are set up correctly with proper scripts and names

$mysqlPath = "C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe"
if (-not (Test-Path $mysqlPath)) {
    $mysqlPath = "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe"
}
if (-not (Test-Path $mysqlPath)) {
    Write-Host "MySQL not found. Please install MySQL or update the path in this script." -ForegroundColor Red
    exit 1
}

$dbHost = "127.0.0.1"
$dbPort = "3306"
$dbUser = "root"
$dbPassword = "qwer4941"
$dbName = "w_world"

Write-Host "=== Checking NPC Setup in Database ===" -ForegroundColor Cyan
Write-Host "Database: $dbName" -ForegroundColor Yellow
Write-Host ""

$query = @"
SELECT 
    entry,
    name,
    subname,
    ScriptName,
    CASE 
        WHEN entry = 190000 AND ScriptName = 'npc_progressive_main_menu' AND name = 'Progressive Systems' THEN '✓ OK'
        WHEN entry = 190001 AND ScriptName = 'npc_item_upgrade' AND name = 'Item Upgrade Master' THEN '✓ OK'
        WHEN entry = 190002 AND ScriptName = 'npc_prestige' AND name = 'Prestige Master' THEN '✓ OK'
        WHEN entry = 190003 AND ScriptName = 'npc_stat_enhancement' AND name = 'Stat Enhancement' THEN '✓ OK'
        WHEN entry = 190005 AND ScriptName = 'npc_infinite_dungeon' AND name = 'Infinite Dungeon' THEN '✓ OK'
        WHEN entry = 190006 AND ScriptName = 'npc_progressive_items' AND name = 'Progressive Items' THEN '✓ OK'
        WHEN ScriptName IS NULL OR ScriptName = '' THEN '✗ MISSING SCRIPT'
        ELSE '✗ NEEDS FIX'
    END AS status
FROM creature_template
WHERE entry IN (190000, 190001, 190002, 190003, 190005, 190006)
ORDER BY entry;
"@

$query | Out-File -FilePath "temp_npc_check.sql" -Encoding UTF8

& $mysqlPath -h $dbHost -P $dbPort -u $dbUser -p$dbPassword $dbName -e "source temp_npc_check.sql" 2>&1

Remove-Item "temp_npc_check.sql" -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "=== Expected NPC Setup ===" -ForegroundColor Cyan
Write-Host "190000 - Progressive Systems (npc_progressive_main_menu)" -ForegroundColor White
Write-Host "190001 - Item Upgrade Master (npc_item_upgrade)" -ForegroundColor White
Write-Host "190002 - Prestige Master (npc_prestige)" -ForegroundColor White
Write-Host "190003 - Stat Enhancement (npc_stat_enhancement)" -ForegroundColor White
Write-Host "190005 - Infinite Dungeon (npc_infinite_dungeon)" -ForegroundColor White
Write-Host "190006 - Progressive Items (npc_progressive_items)" -ForegroundColor White
Write-Host ""
Write-Host "If any NPCs show 'NEEDS FIX', run: fix_npcs.sql" -ForegroundColor Yellow

