-- ============================================================
-- Reward Shop NPC
-- Allows players to purchase items with progression points
-- ============================================================

dofile("progressive_systems_core.lua")
dofile("config.lua")

local Config = require("config")
local NPC_ENTRY = Config.NPC.REWARD_SHOP

-- ============================================================
-- GOSSIP MENU
-- ============================================================
local function OnGossipHello(event, player, creature)
    player:GossipClearMenu()
    
    local points = ProgressiveCore.GetProgressionPoints(player)
    
    player:GossipMenuAddItem(0, string.format(
        "|TInterface\\Icons\\INV_Misc_Coin_01:30|t |cFF00FFFFReward Shop|r\n\n" ..
        "|cFF00FF00Progression Points:|r %d\n\n" ..
        "|cFFAAAAFFBrowse items available for purchase.|r",
        points
    ), 0, 0, false, "")
    
    -- Add shop categories
    player:GossipMenuAddItem(3, "|TInterface\\Icons\\INV_Potion_97:20|t Potions & Elixirs", 0, 1)
    player:GossipMenuAddItem(3, "|TInterface\\Icons\\INV_Drink_05:20|t Flasks", 0, 2)
    player:GossipMenuAddItem(3, "|TInterface\\Icons\\INV_Misc_Bag_10:20|t Consumables", 0, 3)
    player:GossipMenuAddItem(3, "|TInterface\\Icons\\INV_Box_01:20|t Special Items", 0, 4)
    
    player:GossipSendMenu(1, creature)
end

-- ============================================================
-- SHOP CATEGORIES
-- ============================================================
local function ShowCategory(player, creature, categoryId)
    player:GossipClearMenu()
    
    local points = ProgressiveCore.GetProgressionPoints(player)
    local items = {}
    
    -- Filter items by category
    -- Simple categorization based on item IDs and names
    for _, itemData in ipairs(Config.RewardShop) do
        local itemId, cost, name = itemData.itemId, itemData.cost, itemData.name
        
        -- Simple categorization based on item name patterns
        local nameLower = string.lower(name or "")
        
        if categoryId == 1 then  -- Potions & Elixirs
            if string.find(nameLower, "potion") or string.find(nameLower, "elixir") then
                table.insert(items, itemData)
            end
        elseif categoryId == 2 then  -- Flasks
            if string.find(nameLower, "flask") then
                table.insert(items, itemData)
            end
        elseif categoryId == 3 then  -- Consumables
            if string.find(nameLower, "potion") or string.find(nameLower, "elixir") or 
               string.find(nameLower, "flask") or string.find(nameLower, "food") or
               string.find(nameLower, "drink") then
                table.insert(items, itemData)
            end
        elseif categoryId == 4 then  -- Special (custom items)
            if itemId >= 99990 then  -- Custom item range
                table.insert(items, itemData)
            end
        end
    end
    
    -- Show items
    player:GossipMenuAddItem(0, string.format(
        "|cFF00FFFFCategory|r\n" ..
        "|cFF00FF00Your Points:|r %d\n",
        points
    ), 0, 0, false, "")
    
    for _, itemData in ipairs(items) do
        local itemId, cost, name = itemData.itemId, itemData.cost, itemData.name
        local canAfford = points >= cost
        local color = canAfford and "00FF00" or "FF0000"
        
        player:GossipMenuAddItem(0, string.format(
            "|cFF%s%s|r |cFFAAAAFF(%d pts)|r",
            color, name, cost
        ), 0, 1000 + itemId)  -- 1000+ for item purchases
    end
    
    player:GossipMenuAddItem(3, "|TInterface\\Icons\\Ability_Repair:20|t Back", 0, 99)
    player:GossipSendMenu(1, creature)
end

-- ============================================================
-- PURCHASE HANDLER
-- ============================================================
local function OnGossipSelect(event, player, creature, sender, intid, code)
    if intid >= 1 and intid <= 4 then
        -- Show category
        ShowCategory(player, creature, intid)
    elseif intid >= 1000 then
        -- Purchase item
        local itemId = intid - 1000
        
        -- Find item in config
        local itemData = nil
        for _, data in ipairs(Config.RewardShop) do
            if data.itemId == itemId then
                itemData = data
                break
            end
        end
        
        if not itemData then
            player:SendBroadcastMessage("|cFFFF0000Item not found!|r")
            player:GossipComplete()
            return
        end
        
        local cost = itemData.cost
        local points = ProgressiveCore.GetProgressionPoints(player)
        
        if points < cost then
            player:SendBroadcastMessage(string.format(
                "|cFFFF0000Not enough progression points!|r\n" ..
                "|cFFAAAAFFRequired: %d|r |cFFAAAAFFYou have: %d|r",
                cost, points))
            player:GossipComplete()
            return
        end
        
        -- Deduct points using ProgressiveCore function
        local finalPoints = ProgressiveCore.GetProgressionPoints(player)
        if finalPoints >= cost then
            CharDBExecute(string.format(
                "UPDATE character_progression_unified SET progression_points = progression_points - %d WHERE guid = %d",
                cost, player:GetGUIDLow()))
            CharDBExecute(string.format(
                "UPDATE characters SET reward_points = GREATEST(COALESCE(reward_points, 0) - %d, 0) WHERE guid = %d",
                cost, player:GetGUIDLow()))
        else
            player:SendBroadcastMessage("|cFFFF0000Not enough points!|r")
            player:GossipComplete()
            return
        end
        
        -- Give item
        player:AddItem(itemId, 1)
        player:SendBroadcastMessage(string.format(
            "|cFF00FF00Purchased: %s|r\n" ..
            "|cFFAAAAFFCost: %d progression points|r",
            itemData.name, cost))
        player:PlayDirectSound(6448)
        
        OnGossipHello(event, player, creature)
    elseif intid == 99 then
        OnGossipHello(event, player, creature)
    else
        player:GossipComplete()
    end
end

-- ============================================================
-- REGISTER EVENTS
-- ============================================================
RegisterCreatureGossipEvent(NPC_ENTRY, 1, OnGossipHello)
RegisterCreatureGossipEvent(NPC_ENTRY, 2, OnGossipSelect)

print("[Progressive Systems] Reward Shop NPC loaded!")

