# Fix NPC Setup in Database
# This script fixes NPC names and script assignments

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

Write-Host "=== Fixing NPC Setup in Database ===" -ForegroundColor Cyan
Write-Host "Database: $dbName" -ForegroundColor Yellow
Write-Host ""

$fixSQL = @"
USE w_world;

-- Main Menu NPC (190000)
UPDATE creature_template 
SET ScriptName = 'npc_progressive_main_menu',
    name = 'Progressive Systems',
    subname = 'Main Menu',
    npcflag = 1,
    minlevel = 80,
    maxlevel = 80,
    faction = 35
WHERE entry = 190000;

-- Item Upgrade NPC (190001)
UPDATE creature_template 
SET ScriptName = 'npc_item_upgrade',
    name = 'Item Upgrade Master',
    subname = 'Upgrade Your Items',
    npcflag = 1,
    minlevel = 80,
    maxlevel = 80,
    faction = 35
WHERE entry = 190001;

-- Prestige NPC (190002)
UPDATE creature_template 
SET ScriptName = 'npc_prestige',
    name = 'Prestige Master',
    subname = 'Reset for Power',
    npcflag = 1,
    minlevel = 80,
    maxlevel = 80,
    faction = 35
WHERE entry = 190002;

-- Stat Enhancement NPC (190003)
UPDATE creature_template 
SET ScriptName = 'npc_stat_enhancement',
    name = 'Stat Enhancement',
    subname = 'Enhance Your Stats',
    npcflag = 1,
    minlevel = 80,
    maxlevel = 80,
    faction = 35
WHERE entry = 190003;

-- Infinite Dungeon NPC (190005)
UPDATE creature_template 
SET ScriptName = 'npc_infinite_dungeon',
    name = 'Infinite Dungeon',
    subname = 'Enter the Challenge',
    npcflag = 1,
    minlevel = 80,
    maxlevel = 80,
    faction = 35
WHERE entry = 190005;

-- Progressive Items NPC (190006)
UPDATE creature_template 
SET ScriptName = 'npc_progressive_items',
    name = 'Progressive Items',
    subname = 'Tiered Cosmetics',
    npcflag = 1,
    minlevel = 80,
    maxlevel = 80,
    faction = 35
WHERE entry = 190006;

SELECT 'NPCs fixed successfully!' AS result;
"@

$fixSQL | Out-File -FilePath "temp_npc_fix.sql" -Encoding UTF8

& $mysqlPath -h $dbHost -P $dbPort -u $dbUser -p$dbPassword $dbName -e "source temp_npc_fix.sql" 2>&1

Remove-Item "temp_npc_fix.sql" -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "✓ NPCs fixed!" -ForegroundColor Green
Write-Host "Run check_npcs.ps1 to verify." -ForegroundColor Yellow

