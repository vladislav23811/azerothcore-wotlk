-- ============================================================
-- Item Upgrade NPC
-- Allows players to upgrade their items using progression points
-- ============================================================

dofile("progressive_systems_core.lua")
dofile("config.lua")

local Config = require("config")
local NPC_ENTRY = Config.NPC.ITEM_UPGRADE

-- ============================================================
-- GOSSIP MENU
-- ============================================================
local function OnGossipHello(event, player, creature)
    player:GossipClearMenu()
    
    local points = ProgressiveCore.GetProgressionPoints(player)
    
    player:GossipMenuAddItem(0, string.format(
        "|TInterface\\Icons\\INV_Enchant_Disenchant:30|t |cFF00FFFFItem Upgrade System|r\n\n" ..
        "|cFF00FF00Progression Points:|r %d\n\n" ..
        "|cFFAAAAFFSelect an item from your inventory to upgrade it.|r\n" ..
        "|cFFAAAAFFEach upgrade increases item stats by %.0f%%.|r\n" ..
        "|cFFAAAAFFCost increases by %.0f%% per level.|r",
        points,
        Config.Upgrade.STAT_BONUS_PER_LEVEL * 100,
        (Config.Upgrade.COST_MULTIPLIER - 1.0) * 100
    ), 0, 0, false, "")
    
    -- Show equipped items
    for i = 0, 18 do  -- EQUIPMENT_SLOT_END
        local item = player:GetItemByPos(255, i)
        if item then
            local itemTemplate = item:GetTemplate()
            local itemGuid = item:GetGUIDLow()
            
            -- Get upgrade level from database
            local upgradeLevel = 0
            local upgradeQuery = CharDBQuery(string.format(
                "SELECT upgrade_level FROM item_upgrades WHERE item_guid = %d", itemGuid))
            if upgradeQuery then
                upgradeLevel = upgradeQuery:GetUInt32(0)
            end
            
            -- Calculate upgrade cost
            local cost = math.floor(Config.Upgrade.BASE_COST * math.pow(Config.Upgrade.COST_MULTIPLIER, upgradeLevel))
            
            local itemName = itemTemplate:GetName()
            local qualityColor = "FFFFFF"
            if itemTemplate:GetQuality() == 0 then qualityColor = "9D9D9D"  -- Poor
            elseif itemTemplate:GetQuality() == 1 then qualityColor = "FFFFFF"  -- Common
            elseif itemTemplate:GetQuality() == 2 then qualityColor = "1EFF00"  -- Uncommon
            elseif itemTemplate:GetQuality() == 3 then qualityColor = "0070DD"  -- Rare
            elseif itemTemplate:GetQuality() == 4 then qualityColor = "A335EE"  -- Epic
            elseif itemTemplate:GetQuality() == 5 then qualityColor = "FF8000"  -- Legendary
            end
            
            local upgradeText = ""
            if upgradeLevel > 0 then
                upgradeText = string.format(" |cFF00FF00[+%d]|r", upgradeLevel)
            end
            
            local costText = ""
            if cost <= points then
                costText = string.format(" |cFF00FF00(%d pts)|r", cost)
            else
                costText = string.format(" |cFFFF0000(%d pts)|r", cost)
            end
            
            player:GossipMenuAddItem(0, string.format(
                "|cFF%s%s|r%s%s",
                qualityColor, itemName, upgradeText, costText
            ), 0, 100 + i)  -- 100-118 for equipment slots
        end
    end
    
    player:GossipMenuAddItem(3, "|TInterface\\Icons\\Ability_Repair:20|t Back", 0, 99)
    player:GossipSendMenu(1, creature)
end

-- ============================================================
-- UPGRADE HANDLER
-- ============================================================
local function OnGossipSelect(event, player, creature, sender, intid, code)
    if intid >= 100 and intid <= 118 then
        local slot = intid - 100
        local item = player:GetItemByPos(255, slot)
        
        if not item then
            player:SendBroadcastMessage("|cFFFF0000Item not found!|r")
            player:GossipComplete()
            return
        end
        
        -- Get upgrade level from database
        local itemGuid = item:GetGUIDLow()
        local upgradeQuery = CharDBQuery(string.format(
            "SELECT upgrade_level FROM item_upgrades WHERE item_guid = %d", itemGuid))
        local upgradeLevel = 0
        if upgradeQuery then
            upgradeLevel = upgradeQuery:GetUInt32(0)
        end
        
        if upgradeLevel >= Config.Upgrade.MAX_LEVEL then
            player:SendBroadcastMessage("|cFFFF0000Item is at maximum upgrade level!|r")
            player:GossipComplete()
            return
        end
        
        -- Calculate cost
        local cost = math.floor(Config.Upgrade.BASE_COST * math.pow(Config.Upgrade.COST_MULTIPLIER, upgradeLevel))
        local points = ProgressiveCore.GetProgressionPoints(player)
        
        if points < cost then
            player:SendBroadcastMessage(string.format(
                "|cFFFF0000Not enough progression points!|r\n" ..
                "|cFFAAAAFFRequired: %d|r |cFFAAAAFFYou have: %d|r",
                cost, points))
            player:GossipComplete()
            return
        end
        
        -- Deduct points
        CharDBExecute(string.format(
            "UPDATE character_progression_unified SET progression_points = progression_points - %d WHERE guid = %d",
            cost, player:GetGUIDLow()))
        CharDBExecute(string.format(
            "UPDATE characters SET reward_points = GREATEST(COALESCE(reward_points, 0) - %d, 0) WHERE guid = %d",
            cost, player:GetGUIDLow()))
        
        -- Upgrade item in database
        local newLevel = upgradeLevel + 1
        local statBonus = newLevel * Config.Upgrade.STAT_BONUS_PER_LEVEL * 100.0
        CharDBExecute(string.format(
            "INSERT INTO item_upgrades (item_guid, upgrade_level, stat_bonus_percent, upgrade_cost_progression_points) " ..
            "VALUES (%d, %d, %.2f, %d) " ..
            "ON DUPLICATE KEY UPDATE upgrade_level = %d, stat_bonus_percent = %.2f, upgrade_cost_progression_points = upgrade_cost_progression_points + %d",
            itemGuid, newLevel, statBonus, cost, newLevel, statBonus, cost))
        
        -- Recalculate item stats (force update)
        player:UpdateStats(STAT_STRENGTH)
        player:UpdateStats(STAT_AGILITY)
        player:UpdateStats(STAT_STAMINA)
        player:UpdateStats(STAT_INTELLECT)
        player:UpdateStats(STAT_SPIRIT)
        
        player:SendBroadcastMessage(string.format(
            "|cFF00FF00Item upgraded to level %d!|r\n" ..
            "|cFFAAAAFFCost: %d progression points|r\n" ..
            "|cFFAAAAFFStat Bonus: +%.1f%%|r",
            newLevel, cost, newLevel * Config.Upgrade.STAT_BONUS_PER_LEVEL * 100))
        player:PlayDirectSound(6448)  -- Level up sound
        
        OnGossipHello(event, player, creature)
    elseif intid == 99 then
        player:GossipComplete()
    else
        OnGossipHello(event, player, creature)
    end
end

-- ============================================================
-- REGISTER EVENTS
-- ============================================================
RegisterCreatureGossipEvent(NPC_ENTRY, 1, OnGossipHello)
RegisterCreatureGossipEvent(NPC_ENTRY, 2, OnGossipSelect)

print("[Progressive Systems] Item Upgrade NPC loaded!")

