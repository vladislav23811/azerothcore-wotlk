-- ============================================================
-- Main Progression Menu NPC
-- Unified menu for all progressive systems
-- ============================================================

dofile("progressive_systems_core.lua")
dofile("config.lua")

local Config = require("config")
local NPC_ENTRY = 190000

-- ============================================================
-- GOSSIP MENU
-- ============================================================
local function OnGossipHello(event, player, creature)
    player:GossipClearMenu()
    
    local data = ProgressiveCore.GetProgressionData(player)
    local points = ProgressiveCore.GetProgressionPoints(player)
    local diffInfo = ProgressiveCore.Config.DIFFICULTIES[data.difficulty_tier] or ProgressiveCore.Config.DIFFICULTIES[1]
    
    -- Header with stats
    player:GossipMenuAddItem(0, string.format(
        "|TInterface\\Icons\\Achievement_Boss_LichKing:30|t |cFF00FFFFProgressive Systems|r\n\n" ..
        "|cFF00FF00Total Kills:|r %d\n" ..
        "|cFF00FF00Progression Points:|r %d\n" ..
        "|cFF00FF00Current Tier:|r %d (×%.1f)\n" ..
        "|cFF00FF00Difficulty:|r %s\n" ..
        "|cFF00FF00Prestige Level:|r %d",
        data.total_kills, points, data.current_tier,
        ProgressiveCore.Config.TIER_MULTIPLIERS[data.current_tier] or 1.0,
        diffInfo.name, data.prestige_level
    ), 0, 0, false, "")
    
    -- Main options
    player:GossipMenuAddItem(3, "|TInterface\\Icons\\INV_Misc_Coin_01:20|t Reward Shop", 0, 1)
    player:GossipMenuAddItem(3, "|TInterface\\Icons\\INV_Enchant_Disenchant:20|t Item Upgrades", 0, 2)
    player:GossipMenuAddItem(3, "|TInterface\\Icons\\Achievement_Reputation_01:20|t Prestige System", 0, 3)
    player:GossipMenuAddItem(3, "|TInterface\\Icons\\INV_Misc_Key_14:20|t Difficulty Selector", 0, 4)
    player:GossipMenuAddItem(3, "|TInterface\\Icons\\Achievement_Dungeon_UlduarRaid_Misc_01:20|t Infinite Dungeon", 0, 5)
    player:GossipMenuAddItem(3, "|TInterface\\Icons\\INV_Helmet_15:20|t Progressive Items", 0, 6)
    player:GossipMenuAddItem(3, "|TInterface\\Icons\\Achievement_Arena_2v2_7:20|t Leaderboards", 0, 7)
    player:GossipMenuAddItem(3, "|TInterface\\Icons\\INV_Misc_Key_02:20|t Instance Reset", 0, 8)
    
    player:GossipSendMenu(1, creature)
end

-- ============================================================
-- MENU SELECTION
-- ============================================================
local function OnGossipSelect(event, player, creature, sender, intid, code)
    if intid == 1 then
        -- Reward Shop - Open inline menu
        ShowRewardShopMenu(player, creature)
    elseif intid == 2 then
        -- Item Upgrade - Open inline menu
        ShowItemUpgradeMenu(player, creature)
    elseif intid == 3 then
        -- Prestige System
        ShowPrestigeMenu(player, creature)
    elseif intid == 4 then
        -- Difficulty Selector
        ShowDifficultyMenu(player, creature)
    elseif intid == 5 then
        -- Infinite Dungeon - Open inline menu
        ShowInfiniteDungeonMenu(player, creature)
    elseif intid == 6 then
        -- Progressive Items - Open inline menu
        ShowProgressiveItemsMenu(player, creature)
    elseif intid == 7 then
        -- Leaderboards
        ShowLeaderboard(player)
        player:GossipComplete()
    elseif intid == 8 then
        -- Instance Reset - Open instance reset NPC script
        dofile("instance_reset_npc.lua")
        OnGossipHello(event, player, creature)
    else
        player:GossipComplete()
    end
end

-- ============================================================
-- REWARD SHOP MENU (Inline)
-- ============================================================
function ShowRewardShopMenu(player, creature)
    player:GossipClearMenu()
    
    local points = ProgressiveCore.GetProgressionPoints(player)
    
    player:GossipMenuAddItem(0, string.format(
        "|TInterface\\Icons\\INV_Misc_Coin_01:30|t |cFF00FFFFReward Shop|r\n\n" ..
        "|cFF00FF00Progression Points:|r %d\n",
        points
    ), 0, 0, false, "")
    
    -- Show top items from config
    local shopItems = require("config").RewardShop
    for i = 1, math.min(10, #shopItems) do
        local itemData = shopItems[i]
        local canAfford = points >= itemData.cost
        local color = canAfford and "00FF00" or "FF0000"
        
        player:GossipMenuAddItem(0, string.format(
            "|cFF%s%s|r |cFFAAAAFF(%d pts)|r",
            color, itemData.name, itemData.cost
        ), 0, 2000 + itemData.itemId)
    end
    
    player:GossipMenuAddItem(3, "|TInterface\\Icons\\Ability_Repair:20|t Back", 0, 99)
    player:GossipSendMenu(1, creature)
end

-- ============================================================
-- ITEM UPGRADE MENU (Inline)
-- ============================================================
function ShowItemUpgradeMenu(player, creature)
    player:GossipClearMenu()
    
    local points = ProgressiveCore.GetProgressionPoints(player)
    
    player:GossipMenuAddItem(0, string.format(
        "|TInterface\\Icons\\INV_Enchant_Disenchant:30|t |cFF00FFFFItem Upgrade|r\n\n" ..
        "|cFF00FF00Progression Points:|r %d\n" ..
        "|cFFAAAAFFSelect an item to upgrade|r",
        points
    ), 0, 0, false, "")
    
    -- Show equipped items
    for i = 0, 18 do
        local item = player:GetItemByPos(255, i)
        if item then
            local itemTemplate = item:GetTemplate()
            local itemGuid = item:GetGUIDLow()
            
            local upgradeLevel = 0
            local upgradeQuery = CharDBQuery(string.format(
                "SELECT upgrade_level FROM item_upgrades WHERE item_guid = %d", itemGuid))
            if upgradeQuery then
                upgradeLevel = upgradeQuery:GetUInt32(0)
            end
            
            local cost = math.floor(Config.Upgrade.BASE_COST * math.pow(Config.Upgrade.COST_MULTIPLIER, upgradeLevel))
            local upgradeText = upgradeLevel > 0 and string.format(" |cFF00FF00[+%d]|r", upgradeLevel) or ""
            local costText = points >= cost and string.format(" |cFF00FF00(%d)|r", cost) or string.format(" |cFFFF0000(%d)|r", cost)
            
            player:GossipMenuAddItem(0, string.format(
                "%s%s%s",
                itemTemplate:GetName(), upgradeText, costText
            ), 0, 3000 + i)
        end
    end
    
    player:GossipMenuAddItem(3, "|TInterface\\Icons\\Ability_Repair:20|t Back", 0, 99)
    player:GossipSendMenu(1, creature)
end

-- ============================================================
-- PRESTIGE MENU
-- ============================================================
function ShowPrestigeMenu(player, creature)
    player:GossipClearMenu()
    
    local data = ProgressiveCore.GetProgressionData(player)
    local canPrestige = player:GetLevel() >= 80
    
    player:GossipMenuAddItem(0, string.format(
        "|TInterface\\Icons\\Achievement_Reputation_01:30|t |cFF00FFFFPrestige System|r\n\n" ..
        "|cFF00FF00Current Prestige:|r %d\n" ..
        "|cFF00FF00Stat Bonus:|r +%.1f%%\n" ..
        "|cFF00FF00Loot Bonus:|r +%.1f%%\n\n" ..
        "%s",
        data.prestige_level,
        data.prestige_level * ProgressiveCore.Config.PRESTIGE_STAT_BONUS * 100,
        data.prestige_level * ProgressiveCore.Config.PRESTIGE_LOOT_BONUS * 100,
        canPrestige and "|cFF00FF00You can prestige!|r" or "|cFFFF0000Requires level 80|r"
    ), 0, 0, false, "")
    
    if canPrestige and data.prestige_level < 1000 then
        player:GossipMenuAddItem(3, "|TInterface\\Icons\\Achievement_Reputation_01:20|t Prestige Now!", 0, 4000)
    end
    
    player:GossipMenuAddItem(3, "|TInterface\\Icons\\Ability_Repair:20|t Back", 0, 99)
    player:GossipSendMenu(1, creature)
end

-- ============================================================
-- INFINITE DUNGEON MENU (Inline)
-- ============================================================
function ShowInfiniteDungeonMenu(player, creature)
    player:GossipClearMenu()
    
    local guid = player:GetGUIDLow()
    local floorQuery = CharDBQuery(string.format(
        "SELECT current_floor, highest_floor FROM infinite_dungeon_progress WHERE guid = %d", guid))
    
    local currentFloor = (floorQuery and floorQuery:GetUInt32(0)) or 1
    local highestFloor = (floorQuery and floorQuery:GetUInt32(1)) or 1
    
    player:GossipMenuAddItem(0, string.format(
        "|TInterface\\Icons\\Achievement_Dungeon_UlduarRaid_Misc_01:30|t |cFF00FFFFInfinite Dungeon|r\n\n" ..
        "|cFF00FF00Current Floor:|r %d\n" ..
        "|cFF00FF00Highest Floor:|r %d\n",
        currentFloor, highestFloor
    ), 0, 0, false, "")
    
    player:GossipMenuAddItem(3, "|TInterface\\Icons\\INV_Misc_Key_14:20|t Start Floor " .. currentFloor, 0, 5000)
    player:GossipMenuAddItem(3, "|TInterface\\Icons\\Achievement_Boss_LichKing:20|t Reset to Floor 1", 0, 5001)
    player:GossipMenuAddItem(3, "|TInterface\\Icons\\Achievement_Arena_2v2_7:20|t Leaderboard", 0, 5002)
    
    player:GossipMenuAddItem(3, "|TInterface\\Icons\\Ability_Repair:20|t Back", 0, 99)
    player:GossipSendMenu(1, creature)
end

-- ============================================================
-- PROGRESSIVE ITEMS MENU (Inline)
-- ============================================================
function ShowProgressiveItemsMenu(player, creature)
    player:GossipClearMenu()
    
    local data = ProgressiveCore.GetProgressionData(player)
    local currentTier = data.current_tier or 1
    
    player:GossipMenuAddItem(0, string.format(
        "|TInterface\\Icons\\INV_Helmet_15:30|t |cFF00FFFFProgressive Items|r\n\n" ..
        "|cFF00FF00Current Tier:|r %d\n",
        currentTier
    ), 0, 0, false, "")
    
    -- Show available tiers (simplified)
    for tier = 1, math.min(10, currentTier) do
        local color = tier == currentTier and "00FF00" or "AAAAFF"
        player:GossipMenuAddItem(3, string.format(
            "|cFF%sTier %d Items|r",
            color, tier
        ), 0, 6000 + tier)
    end
    
    player:GossipMenuAddItem(3, "|TInterface\\Icons\\Ability_Repair:20|t Back", 0, 99)
    player:GossipSendMenu(1, creature)
end

-- ============================================================
-- HANDLE SUB-MENU ACTIONS
-- ============================================================
local function OnGossipSelectExtended(event, player, creature, sender, intid, code)
    -- Reward shop purchases
    if intid >= 2000 and intid < 3000 then
        local itemId = intid - 2000
        -- Handle purchase (same logic as reward_shop_npc.lua)
        player:SendBroadcastMessage("|cFF00FF00Purchase functionality - use Reward Shop NPC for full features|r")
        OnGossipHello(event, player, creature)
        
    -- Item upgrades
    elseif intid >= 3000 and intid < 4000 then
        local slot = intid - 3000
        -- Handle upgrade (same logic as item_upgrade_npc.lua)
        player:SendBroadcastMessage("|cFF00FF00Upgrade functionality - use Item Upgrade NPC for full features|r")
        OnGossipHello(event, player, creature)
        
    -- Prestige
    elseif intid == 4000 then
        local data = ProgressiveCore.GetProgressionData(player)
        if player:GetLevel() >= 80 and data.prestige_level < 1000 then
            -- Use C++ prestige function
            if sProgressiveSystems:PrestigeCharacter(player) then
                player:SendBroadcastMessage("|cFF00FF00Prestiged! You gained permanent bonuses!|r")
                player:PlayDirectSound(6448)
            else
                player:SendBroadcastMessage("|cFFFF0000Failed to prestige. Check requirements!|r")
            end
        else
            if player:GetLevel() < 80 then
                player:SendBroadcastMessage("|cFFFF0000You must be level 80 to prestige!|r")
            else
                player:SendBroadcastMessage("|cFFFF0000You are at maximum prestige level!|r")
            end
        end
        OnGossipHello(event, player, creature)
        
    -- Infinite dungeon actions
    elseif intid == 5000 then
        player:SendBroadcastMessage("|cFF00FF00Use Infinite Dungeon NPC for full features|r")
        OnGossipHello(event, player, creature)
    elseif intid == 5001 then
        CharDBExecute(string.format(
            "UPDATE infinite_dungeon_progress SET current_floor = 1 WHERE guid = %d",
            player:GetGUIDLow()))
        player:SendBroadcastMessage("|cFF00FF00Reset to Floor 1!|r")
        OnGossipHello(event, player, creature)
    elseif intid == 5002 then
        ShowLeaderboard(player)
        OnGossipHello(event, player, creature)
        
    -- Progressive items
    elseif intid >= 6000 and intid < 7000 then
        player:SendBroadcastMessage("|cFF00FF00Use Progressive Items NPC for full features|r")
        OnGossipHello(event, player, creature)
        
    -- Back button
    elseif intid == 99 then
        OnGossipHello(event, player, creature)
    else
        OnGossipSelect(event, player, creature, sender, intid, code)
    end
end

-- ============================================================
-- DIFFICULTY MENU
-- ============================================================
function ShowDifficultyMenu(player, creature)
    player:GossipClearMenu()
    
    local data = ProgressiveCore.GetProgressionData(player)
    
    player:GossipMenuAddItem(0, "|cFF00FFFFSelect Difficulty|r\n" ..
        "|cFFAAAAFFCurrent: " .. (ProgressiveCore.Config.DIFFICULTIES[data.difficulty_tier] or ProgressiveCore.Config.DIFFICULTIES[1]).name .. "|r", 0, 0)
    
    for diffId, diffInfo in pairs(ProgressiveCore.Config.DIFFICULTIES) do
        local color = diffId <= 1 and "00FF00" or diffId <= 2 and "FFFF00" or diffId <= 3 and "FFA500" or "FF0000"
        local selected = (data.difficulty_tier == diffId) and " |cFF00FF00[SELECTED]|r" or ""
        
        player:GossipMenuAddItem(0, string.format(
            "|cFF%s%s|r (HP: ×%.1f, DMG: ×%.1f, Points: ×%.1f)%s",
            color, diffInfo.name, diffInfo.hp, diffInfo.dmg, diffInfo.points, selected
        ), 0, 100 + diffId)
    end
    
    player:GossipMenuAddItem(3, "|TInterface\\Icons\\Ability_Repair:20|t Back", 0, 99)
    player:GossipSendMenu(1, creature)
end

-- ============================================================
-- LEADERBOARD
-- ============================================================
function ShowLeaderboard(player)
    local q = CharDBQuery(
        "SELECT c.guid, c.name, p.total_kills, p.prestige_level, p.progression_points " ..
        "FROM character_progression_unified p " ..
        "INNER JOIN characters c ON c.guid = p.guid " ..
        "ORDER BY p.total_kills DESC LIMIT 10")
    
    player:SendBroadcastMessage("|cFF00FF00=== Top 10 Players ===|r")
    local rank = 1
    if q then
        repeat
            local guid = q:GetUInt32(0)
            local name = q:GetString(1) or "Unknown"
            local kills = q:GetUInt32(2)
            local prestige = q:GetUInt32(3)
            local points = q:GetUInt64(4)
            
            player:SendBroadcastMessage(string.format(
                "#%d |cFFFFFFFF%s|r - Kills: %d | Prestige: %d | Points: %d",
                rank, name, kills, prestige, points))
            
            rank = rank + 1
        until not q:NextRow()
    end
end

-- ============================================================
-- DIFFICULTY SELECTION HANDLER
-- ============================================================
local function OnDifficultySelect(event, player, creature, sender, intid, code)
    if intid >= 100 and intid < 110 then
        local selectedDiff = intid - 100
        local guid = player:GetGUIDLow()
        
        CharDBExecute(string.format(
            "UPDATE character_progression_unified SET difficulty_tier = %d WHERE guid = %d",
            selectedDiff, guid))
        
        local diffInfo = ProgressiveCore.Config.DIFFICULTIES[selectedDiff]
        player:SendBroadcastMessage(string.format(
            "|cFF00FF00Difficulty set to: %s|r", diffInfo.name))
        player:PlayDirectSound(6448)  -- Level up sound
        
        OnGossipHello(event, player, creature)
    elseif intid == 99 then
        OnGossipHello(event, player, creature)
    else
        OnGossipSelect(event, player, creature, sender, intid, code)
    end
end

-- ============================================================
-- REGISTER EVENTS
-- ============================================================
RegisterCreatureGossipEvent(NPC_ENTRY, 1, OnGossipHello)
RegisterCreatureGossipEvent(NPC_ENTRY, 2, function(event, player, creature, sender, intid, code)
    if intid >= 100 and intid < 200 then
        OnDifficultySelect(event, player, creature, sender, intid, code)
    elseif intid >= 2000 then
        OnGossipSelectExtended(event, player, creature, sender, intid, code)
    else
        OnGossipSelect(event, player, creature, sender, intid, code)
    end
end)

print("[Progressive Systems] Main menu NPC loaded!")

