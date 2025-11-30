-- ============================================================
-- Progressive Items NPC
-- Vendor for tiered shirts and tabards based on progression
-- ============================================================

dofile("progressive_systems_core.lua")
dofile("config.lua")

local Config = require("config")
local NPC_ENTRY = 190006  -- Progressive Items NPC

-- Tiered items (shirt and tabard per tier)
-- Format: { tier, shirtItemId, tabardItemId, name }
local TIERED_ITEMS = {
    { tier = 1, shirt = 4330, tabard = 5976, name = "Tier 1" },      -- Red Linen Shirt, Guild Tabard
    { tier = 2, shirt = 4332, tabard = 19031, name = "Tier 2" },    -- Bright Yellow Shirt, Frostwolf Battle Tabard
    { tier = 3, shirt = 4334, tabard = 19032, name = "Tier 3" },    -- Brown Linen Shirt, Stormpike Battle Tabard
    { tier = 5, shirt = 4335, tabard = 23999, name = "Tier 5" },    -- Rich Purple Silk Shirt, Honor Hold Tabard
    { tier = 10, shirt = 4336, tabard = 24004, name = "Tier 10" },  -- Black Swashbuckler's Shirt, Thrallmar Tabard
    -- Add more tiers as needed
}

-- ============================================================
-- GOSSIP MENU
-- ============================================================
local function OnGossipHello(event, player, creature)
    player:GossipClearMenu()
    
    local data = ProgressiveCore.GetProgressionData(player)
    local currentTier = data.current_tier or 1
    
    player:GossipMenuAddItem(0, string.format(
        "|TInterface\\Icons\\INV_Helmet_15:30|t |cFF00FFFFProgressive Items|r\n\n" ..
        "|cFF00FF00Current Tier:|r %d\n" ..
        "|cFF00FF00Available Items:|r Up to Tier %d\n\n" ..
        "|cFFAAAAFFPurchase tiered shirts and tabards|r\n" ..
        "|cFFAAAAFFto show off your progression!|r",
        currentTier, currentTier
    ), 0, 0, false, "")
    
    -- Show available tiers
    for _, tierData in ipairs(TIERED_ITEMS) do
        if tierData.tier <= currentTier then
            local color = tierData.tier == currentTier and "00FF00" or "AAAAFF"
            player:GossipMenuAddItem(3, string.format(
                "|cFF%s%s Items|r (Shirt + Tabard)",
                color, tierData.name
            ), 0, 100 + tierData.tier)
        end
    end
    
    player:GossipSendMenu(1, creature)
end

-- ============================================================
-- VENDOR SELECTION
-- ============================================================
local function OnGossipSelect(event, player, creature, sender, intid, code)
    if intid >= 100 then
        local selectedTier = intid - 100
        
        -- Find tier data
        local tierData = nil
        for _, data in ipairs(TIERED_ITEMS) do
            if data.tier == selectedTier then
                tierData = data
                break
            end
        end
        
        if not tierData then
            player:SendBroadcastMessage("|cFFFF0000Invalid tier!|r")
            player:GossipComplete()
            return
        end
        
        -- Check if player has required tier
        local data = ProgressiveCore.GetProgressionData(player)
        if (data.current_tier or 1) < selectedTier then
            player:SendBroadcastMessage(string.format(
                "|cFFFF0000You need Tier %d to purchase these items!|r\n" ..
                "|cFFAAAAFFYour current tier: %d|r",
                selectedTier, data.current_tier or 1))
            player:GossipComplete()
            return
        end
        
        -- Give items
        local shirt = player:AddItem(tierData.shirt, 1)
        local tabard = player:AddItem(tierData.tabard, 1)
        
        if shirt and tabard then
            player:SendBroadcastMessage(string.format(
                "|cFF00FF00Purchased %s items!|r\n" ..
                "|cFFAAAAFFShirt and Tabard added to inventory|r",
                tierData.name))
            player:PlayDirectSound(6448)
        else
            player:SendBroadcastMessage("|cFFFF0000Inventory full!|r")
        end
        
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

print("[Progressive Systems] Progressive Items NPC loaded!")

