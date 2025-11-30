-- ============================================================
-- Paragon System Lua Script
-- Enhanced NPC interactions for Paragon system
-- ============================================================

dofile("progressive_systems_core.lua")
dofile("config.lua")

local Config = require("config")
local NPC_ENTRY = 190020 -- Paragon Master NPC

-- Helper function to get paragon info
local function GetParagonInfo(player)
    local guid = player:GetGUIDLow()
    local result = CharDBQuery(string.format(
        "SELECT paragon_level, paragon_experience, paragon_points_available, paragon_tier " ..
        "FROM character_paragon WHERE guid = %d", guid))
    
    if result then
        return {
            level = result:GetUInt32(0),
            experience = result:GetUInt64(1),
            points = result:GetUInt32(2),
            tier = result:GetUInt8(3)
        }
    end
    
    return { level = 0, experience = 0, points = 0, tier = 0 }
end

-- Calculate experience needed for next level
local function GetExpForNextLevel(level)
    return math.floor(1000 * math.pow(1.1, level))
end

local function OnGossipHello(event, player, creature)
    player:GossipClearMenu()
    
    local info = GetParagonInfo(player)
    local expNeeded = GetExpForNextLevel(info.level)
    local expPercent = math.floor((info.experience / expNeeded) * 100)
    
    player:GossipMenuAddItem(0, string.format(
        "|TInterface\\Icons\\Achievement_Level_80:30|t |cFF00FFFFParagon System|r\n\n" ..
        "|cFF00FF00Paragon Level:|r %d\n" ..
        "|cFF00FF00Paragon Tier:|r %d\n" ..
        "|cFF00FF00Available Points:|r %d\n" ..
        "|cFFAAAAFFExperience:|r %d / %d (%d%%)\n",
        info.level, info.tier, info.points, info.experience, expNeeded, expPercent
    ), 0, 0, false, "")
    
    player:GossipMenuAddItem(3, "|TInterface\\Icons\\INV_Enchant_Disenchant:20|t Allocate Points", 0, 1)
    player:GossipMenuAddItem(3, "|TInterface\\Icons\\INV_Misc_QuestionMark:20|t View My Stats", 0, 2)
    player:GossipMenuAddItem(3, "|TInterface\\Icons\\Achievement_Leader_Horde:20|t Leaderboard", 0, 3)
    player:GossipMenuAddItem(3, "|TInterface\\Icons\\INV_Misc_QuestionMark:20|t Reset Stats (Cost: 1000 Points)", 0, 4)
    
    player:GossipSendMenu(1, creature)
end

local function ShowAllocateMenu(player, creature, statType)
    player:GossipClearMenu()
    
    local typeNames = {"Core", "Offense", "Defense", "Utility"}
    local typeIcons = {
        "INV_Misc_QuestionMark",
        "INV_Sword_04",
        "INV_Shield_05",
        "INV_Misc_Bag_08"
    }
    
    player:GossipMenuAddItem(0, string.format(
        "|TInterface\\Icons\\%s:30|t |cFF00FFFFAllocate Paragon Points|r\n\n" ..
        "|cFF00FF00Category:|r %s\n",
        typeIcons[statType + 1], typeNames[statType + 1]
    ), 0, 0, false, "")
    
    -- Get stats for this category
    local result = WorldDBQuery(string.format(
        "SELECT stat_id, stat_name, max_points, points_per_level " ..
        "FROM paragon_stat_definitions " ..
        "WHERE stat_type = %d AND active = 1 ORDER BY sort_order", statType))
    
    if result then
        repeat
            local statId = result:GetUInt8(0)
            local statName = result:GetString(1)
            local maxPoints = result:GetUInt32(2)
            local pointsPerLevel = result:GetFloat(3)
            
            -- Get current allocation
            local guid = player:GetGUIDLow()
            local allocResult = CharDBQuery(string.format(
                "SELECT points_allocated FROM character_paragon_stats " ..
                "WHERE guid = %d AND stat_type = %d AND stat_id = %d",
                guid, statType, statId))
            
            local currentPoints = 0
            if allocResult then
                currentPoints = allocResult:GetUInt32(0)
            end
            
            local statValue = math.floor(currentPoints * pointsPerLevel)
            local color = "FFFFFF"
            if currentPoints >= maxPoints then
                color = "FF0000"
            elseif currentPoints > 0 then
                color = "00FF00"
            end
            
            player:GossipMenuAddItem(3, string.format(
                "|TInterface\\Icons\\INV_Enchant_Disenchant:20|t |c%s%s|r\n" ..
                "  Points: %d/%d | Value: +%.1f",
                color, statName, currentPoints, maxPoints, statValue
            ), 0, 100 + (statType * 100) + statId)
        until not result:NextRow()
    end
    
    -- Category selection
    for i = 0, 3 do
        if i ~= statType then
            player:GossipMenuAddItem(3, string.format(
                "|TInterface\\Icons\\%s:20|t %s Stats",
                typeIcons[i + 1], typeNames[i + 1]
            ), 0, 10 + i)
        end
    end
    
    player:GossipMenuAddItem(3, "|TInterface\\Icons\\Ability_Repair:20|t Back", 0, 99)
    player:GossipSendMenu(1, creature)
end

local function OnGossipSelect(event, player, creature, sender, intid, code)
    player:GossipClearMenu()
    
    if intid == 1 then
        -- Allocate points - show Core stats first
        ShowAllocateMenu(player, creature, 0)
    elseif intid == 2 then
        -- View stats
        local guid = player:GetGUIDLow()
        local result = CharDBQuery(string.format(
            "SELECT ps.stat_type, ps.stat_id, ps.points_allocated, pd.stat_name, pd.points_per_level " ..
            "FROM character_paragon_stats ps " ..
            "JOIN paragon_stat_definitions pd ON ps.stat_id = pd.stat_id " ..
            "WHERE ps.guid = %d ORDER BY ps.stat_type, pd.sort_order", guid))
        
        local statsText = "|TInterface\\Icons\\INV_Misc_QuestionMark:30|t |cFF00FFFFYour Paragon Stats|r\n\n"
        
        if result then
            repeat
                local statType = result:GetUInt8(0)
                local points = result:GetUInt32(2)
                local statName = result:GetString(3)
                local pointsPerLevel = result:GetFloat(4)
                local statValue = math.floor(points * pointsPerLevel)
                
                statsText = statsText .. string.format(
                    "|cFF00FF00%s:|r %d points (+%.1f)\n",
                    statName, points, statValue
                )
            until not result:NextRow()
        else
            statsText = statsText .. "|cFFFF0000No stats allocated yet!|r\n"
        end
        
        player:GossipMenuAddItem(0, statsText, 0, 0, false, "")
        player:GossipMenuAddItem(3, "|TInterface\\Icons\\Ability_Repair:20|t Back", 0, 99)
        player:GossipSendMenu(1, creature)
    elseif intid == 3 then
        -- Leaderboard
        local result = CharDBQuery(
            "SELECT c.name, p.paragon_level, p.paragon_tier " ..
            "FROM character_paragon p " ..
            "JOIN characters c ON p.guid = c.guid " ..
            "ORDER BY p.paragon_level DESC, p.total_paragon_experience DESC " ..
            "LIMIT 10")
        
        local leaderboard = "|TInterface\\Icons\\Achievement_Leader_Horde:30|t |cFF00FFFFParagon Leaderboard|r\n\n"
        leaderboard = leaderboard .. "|cFF00FF00Top 10 Players:|r\n\n"
        
        if result then
            local rank = 1
            repeat
                local name = result:GetString(0)
                local level = result:GetUInt32(1)
                local tier = result:GetUInt8(2)
                
                leaderboard = leaderboard .. string.format(
                    "|cFFFFFF00#%d|r %s - Level %d (Tier %d)\n",
                    rank, name, level, tier
                )
                rank = rank + 1
            until not result:NextRow()
        else
            leaderboard = leaderboard .. "|cFFFF0000No paragon players yet!|r\n"
        end
        
        player:GossipMenuAddItem(0, leaderboard, 0, 0, false, "")
        player:GossipMenuAddItem(3, "|TInterface\\Icons\\Ability_Repair:20|t Back", 0, 99)
        player:GossipSendMenu(1, creature)
    elseif intid == 4 then
        -- Reset stats
        local info = GetParagonInfo(player)
        if info.points >= 1000 then
            -- Reset all stats and refund points
            local guid = player:GetGUIDLow()
            CharDBExecute(string.format(
                "DELETE FROM character_paragon_stats WHERE guid = %d", guid))
            CharDBExecute(string.format(
                "UPDATE character_paragon SET paragon_points_available = %d WHERE guid = %d",
                info.points - 1000, guid))
            
            player:SendBroadcastMessage("|cFF00FF00Stats reset!|r 1000 points deducted.")
            player:PlayDirectSound(6448)
        else
            player:SendBroadcastMessage("|cFFFF0000Not enough points!|r Need 1000 points to reset.")
        end
        OnGossipHello(event, player, creature)
    elseif intid >= 10 and intid < 14 then
        -- Category selection
        ShowAllocateMenu(player, creature, intid - 10)
    elseif intid >= 100 then
        -- Allocate point to stat
        local statType = math.floor((intid - 100) / 100)
        local statId = (intid - 100) % 100
        
        -- Use C++ function to allocate point
        -- This would need to be exposed via Eluna or use direct SQL
        local guid = player:GetGUIDLow()
        local info = GetParagonInfo(player)
        
        if info.points > 0 then
            -- Get current allocation
            local allocResult = CharDBQuery(string.format(
                "SELECT points_allocated FROM character_paragon_stats " ..
                "WHERE guid = %d AND stat_type = %d AND stat_id = %d",
                guid, statType, statId))
            
            local currentPoints = 0
            if allocResult then
                currentPoints = allocResult:GetUInt32(0)
            end
            
            -- Get max points
            local maxResult = WorldDBQuery(string.format(
                "SELECT max_points FROM paragon_stat_definitions WHERE stat_id = %d", statId))
            
            local maxPoints = 50
            if maxResult then
                maxPoints = maxResult:GetUInt32(0)
            end
            
            if currentPoints < maxPoints then
                -- Allocate point
                CharDBExecute(string.format(
                    "INSERT INTO character_paragon_stats (guid, stat_type, stat_id, points_allocated) " ..
                    "VALUES (%d, %d, %d, %d) " ..
                    "ON DUPLICATE KEY UPDATE points_allocated = points_allocated + 1",
                    guid, statType, statId, currentPoints + 1))
                
                CharDBExecute(string.format(
                    "UPDATE character_paragon SET paragon_points_available = paragon_points_available - 1 WHERE guid = %d",
                    guid))
                
                player:SendBroadcastMessage("|cFF00FF00Paragon point allocated!|r")
                player:PlayDirectSound(6448)
                
                -- Reapply stats (would need C++ hook)
                -- sParagonSystem->ApplyAllParagonStats(player)
            else
                player:SendBroadcastMessage("|cFFFF0000This stat is at maximum!|r")
            end
        else
            player:SendBroadcastMessage("|cFFFF0000You have no available paragon points!|r")
        end
        
        ShowAllocateMenu(player, creature, statType)
    elseif intid == 99 then
        OnGossipHello(event, player, creature)
    end
end

RegisterCreatureGossipEvent(NPC_ENTRY, 1, OnGossipHello)
RegisterCreatureGossipEvent(NPC_ENTRY, 2, OnGossipSelect)

print("[Paragon System] Lua NPC script loaded successfully!")

