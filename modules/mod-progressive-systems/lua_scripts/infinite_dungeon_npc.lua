-- ============================================================
-- Infinite Dungeon NPC
-- Endless challenge mode with scaling difficulty
-- ============================================================

dofile("progressive_systems_core.lua")
dofile("config.lua")

local Config = require("config")
local NPC_ENTRY = Config.NPC.INFINITE_DUNGEON

-- ============================================================
-- GOSSIP MENU
-- ============================================================
local function OnGossipHello(event, player, creature)
    player:GossipClearMenu()
    
    local guid = player:GetGUIDLow()
    
    -- Get current floor progress
    local floorQuery = CharDBQuery(string.format(
        "SELECT current_floor, highest_floor, total_floors_cleared, best_time " ..
        "FROM infinite_dungeon_progress WHERE guid = %d", guid))
    
    local currentFloor = 1
    local highestFloor = 1
    local totalCleared = 0
    local bestTime = 0
    
    if floorQuery then
        currentFloor = floorQuery:GetUInt32(0)
        highestFloor = floorQuery:GetUInt32(1)
        totalCleared = floorQuery:GetUInt32(2)
        bestTime = floorQuery:GetUInt32(3)
    else
        -- Initialize
        CharDBExecute(string.format(
            "INSERT INTO infinite_dungeon_progress (guid, current_floor, highest_floor) VALUES (%d, 1, 1)",
            guid))
    end
    
    -- Calculate floor multipliers
    local hpMultiplier = 1.0 + (currentFloor * Config.InfiniteDungeon.HEALTH_MULTIPLIER_PER_FLOOR)
    local dmgMultiplier = 1.0 + (currentFloor * Config.InfiniteDungeon.DAMAGE_MULTIPLIER_PER_FLOOR)
    local pointsReward = math.floor(Config.InfiniteDungeon.POINTS_PER_FLOOR * 
        (1.0 + (currentFloor * Config.InfiniteDungeon.POINTS_MULTIPLIER_PER_FLOOR)))
    
    local timeStr = "N/A"
    if bestTime > 0 then
        local minutes = math.floor(bestTime / 60)
        local seconds = bestTime % 60
        timeStr = string.format("%dm %ds", minutes, seconds)
    end
    
    player:GossipMenuAddItem(0, string.format(
        "|TInterface\\Icons\\Achievement_Dungeon_UlduarRaid_Misc_01:30|t |cFF00FFFFInfinite Dungeon|r\n\n" ..
        "|cFF00FF00Current Floor:|r %d\n" ..
        "|cFF00FF00Highest Floor:|r %d\n" ..
        "|cFF00FF00Total Cleared:|r %d\n" ..
        "|cFF00FF00Best Time:|r %s\n\n" ..
        "|cFFAAAAFFFloor %d Stats:|r\n" ..
        "|cFFAAAAFFHP Multiplier: ×%.1f|r\n" ..
        "|cFFAAAAFFDMG Multiplier: ×%.1f|r\n" ..
        "|cFFAAAAFFPoints Reward: %d|r",
        currentFloor, highestFloor, totalCleared, timeStr,
        currentFloor, hpMultiplier, dmgMultiplier, pointsReward
    ), 0, 0, false, "")
    
    -- Main options
    player:GossipMenuAddItem(3, "|TInterface\\Icons\\INV_Misc_Key_14:20|t Start Floor " .. currentFloor, 0, 1)
    player:GossipMenuAddItem(3, "|TInterface\\Icons\\Achievement_Boss_LichKing:20|t Reset to Floor 1", 0, 2)
    player:GossipMenuAddItem(3, "|TInterface\\Icons\\Achievement_Arena_2v2_7:20|t Leaderboard", 0, 3)
    player:GossipMenuAddItem(3, "|TInterface\\Icons\\INV_Misc_Coin_01:20|t Floor Rewards Info", 0, 4)
    
    player:GossipSendMenu(1, creature)
end

-- ============================================================
-- MENU SELECTION
-- ============================================================
local function OnGossipSelect(event, player, creature, sender, intid, code)
    local guid = player:GetGUIDLow()
    
    if intid == 1 then
        -- Start current floor
        local floorQuery = CharDBQuery(string.format(
            "SELECT current_floor FROM infinite_dungeon_progress WHERE guid = %d", guid))
        local floor = (floorQuery and floorQuery:GetUInt32(0)) or 1
        
        player:SendBroadcastMessage(string.format(
            "|cFF00FF00Starting Infinite Dungeon - Floor %d|r\n" ..
            "|cFFAAAAFFGood luck!|r", floor))
        
        -- Set current floor
        sProgressiveSystems:SetCurrentFloor(player, floor)
        
        -- Teleport to dungeon (using ICC as example - can be configured)
        local mapId = 631  -- ICC
        local x, y, z, o = 529.302, -2124.49, 840.857, 3.14159  -- ICC entrance
        
        -- Try to teleport player
        if player:Teleport(mapId, x, y, z, o) then
            player:SendBroadcastMessage("|cFF00FF00Teleported to Infinite Dungeon!|r")
        else
            player:SendBroadcastMessage("|cFFFF0000Failed to teleport. Please try again.|r")
        end
        
        player:GossipComplete()
        
    elseif intid == 2 then
        -- Reset to floor 1
        CharDBExecute(string.format(
            "UPDATE infinite_dungeon_progress SET current_floor = 1 WHERE guid = %d", guid))
        
        player:SendBroadcastMessage("|cFF00FF00Reset to Floor 1!|r")
        player:PlayDirectSound(6448)
        OnGossipHello(event, player, creature)
        
    elseif intid == 3 then
        -- Leaderboard
        local q = CharDBQuery(
            "SELECT c.name, p.highest_floor, p.total_floors_cleared, p.best_time " ..
            "FROM infinite_dungeon_progress p " ..
            "INNER JOIN characters c ON c.guid = p.guid " ..
            "ORDER BY p.highest_floor DESC, p.best_time ASC LIMIT 10")
        
        player:SendBroadcastMessage("|cFF00FF00=== Infinite Dungeon Leaderboard ===|r")
        local rank = 1
        if q then
            repeat
                local name = q:GetString(0) or "Unknown"
                local highest = q:GetUInt32(1)
                local total = q:GetUInt32(2)
                local time = q:GetUInt32(3)
                
                local timeStr = "N/A"
                if time > 0 then
                    local minutes = math.floor(time / 60)
                    local seconds = time % 60
                    timeStr = string.format("%dm %ds", minutes, seconds)
                end
                
                player:SendBroadcastMessage(string.format(
                    "#%d |cFFFFFFFF%s|r - Floor: %d | Cleared: %d | Time: %s",
                    rank, name, highest, total, timeStr))
                rank = rank + 1
            until not q:NextRow()
        end
        player:GossipComplete()
        
    elseif intid == 4 then
        -- Floor rewards info
        local floorQuery = CharDBQuery(string.format(
            "SELECT current_floor FROM infinite_dungeon_progress WHERE guid = %d", guid))
        local floor = (floorQuery and floorQuery:GetUInt32(0)) or 1
        
        local pointsReward = math.floor(Config.InfiniteDungeon.POINTS_PER_FLOOR * 
            (1.0 + (floor * Config.InfiniteDungeon.POINTS_MULTIPLIER_PER_FLOOR)))
        
        player:SendBroadcastMessage(string.format(
            "|cFF00FFFFFloor %d Rewards:|r\n" ..
            "|cFF00FF00Progression Points:|r %d\n" ..
            "|cFF00FF00Bonus per floor:|r +%.0f%%\n\n" ..
            "|cFFAAAAFFHigher floors = Better rewards!|r",
            floor, pointsReward, Config.InfiniteDungeon.POINTS_MULTIPLIER_PER_FLOOR * 100))
        player:GossipComplete()
        
    else
        player:GossipComplete()
    end
end

-- ============================================================
-- REGISTER EVENTS
-- ============================================================
RegisterCreatureGossipEvent(NPC_ENTRY, 1, OnGossipHello)
RegisterCreatureGossipEvent(NPC_ENTRY, 2, OnGossipSelect)

print("[Progressive Systems] Infinite Dungeon NPC loaded!")

