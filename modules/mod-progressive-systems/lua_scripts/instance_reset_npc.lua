-- ============================================================
-- Instance Reset NPC
-- Allows players to reset instances and view completion stats
-- ============================================================

dofile("progressive_systems_core.lua")
dofile("config.lua")

local Config = require("config")
local NPC_ENTRY = Config.NPC.INSTANCE_RESET or 190010 -- New NPC entry

-- Get map name helper
local function GetMapName(mapId, locale)
    local mapNames = {
        [533] = "Naxxramas",
        [631] = "Icecrown Citadel",
        [603] = "Ulduar",
        [649] = "Trial of the Crusader",
        [724] = "The Ruby Sanctum",
        [615] = "The Obsidian Sanctum",
        [616] = "The Eye of Eternity",
        [624] = "Vault of Archavon",
        [574] = "Utgarde Keep",
        [575] = "Utgarde Pinnacle",
        [576] = "The Nexus",
        [578] = "The Oculus",
        [595] = "The Culling of Stratholme",
        [599] = "Halls of Stone",
        [600] = "Drak'Tharon Keep",
        [601] = "Azjol-Nerub",
        [602] = "Halls of Lightning",
        [604] = "Gundrak",
        [608] = "Violet Hold",
        [615] = "The Obsidian Sanctum",
        [616] = "The Eye of Eternity",
        [617] = "Ahn'kahet: The Old Kingdom",
        [618] = "The Forge of Souls",
        [619] = "Halls of Reflection",
        [632] = "The Forge of Souls",
        [658] = "Pit of Saron",
        [668] = "Halls of Reflection",
    }
    return mapNames[mapId] or ("Map " .. mapId)
end

local function ShowInstanceResetMenu(player, creature)
    player:GossipClearMenu()
    
    -- Get reset info from C++ (we'll need to add Lua bindings or use a workaround)
    -- For now, we'll show a menu with options
    
    player:GossipMenuAddItem(0, 
        "|TInterface\\Icons\\Achievement_Dungeon_UlduarRaid_Misc_01:30|t |cFF00FFFFInstance Reset System|r\n\n" ..
        "|cFF00FF00Reset your instances and track completions!|r\n" ..
        "|cFFAAAAFFYou can reset instances unlimited times.|r",
        0, 0, false, "")
    
    player:GossipMenuAddItem(3, "|TInterface\\Icons\\INV_Misc_Key_02:20|t Reset All Dungeons", 0, 101)
    player:GossipMenuAddItem(3, "|TInterface\\Icons\\INV_Misc_Key_03:20|t Reset All Raids", 0, 102)
    player:GossipMenuAddItem(3, "|TInterface\\Icons\\Achievement_Dungeon_GloryoftheHero:20|t View Completion Stats", 0, 103)
    player:GossipMenuAddItem(3, "|TInterface\\Icons\\INV_Misc_QuestionMark:20|t Reset Specific Instance", 0, 104)
    player:GossipMenuAddItem(3, "|TInterface\\Icons\\Ability_Repair:20|t Back", 0, 99)
    
    player:GossipSendMenu(1, creature)
end

local function ShowCompletionStats(player, creature)
    player:GossipClearMenu()
    
    player:GossipMenuAddItem(0, 
        "|TInterface\\Icons\\Achievement_Dungeon_GloryoftheHero:30|t |cFF00FFFFCompletion Statistics|r\n\n" ..
        "|cFFAAAAFFYour instance completion history|r",
        0, 0, false, "")
    
    -- Get completion data (would need C++ integration)
    -- For now, show placeholder
    player:GossipMenuAddItem(0, "|cFFAAAAFFCompletion data will be shown here|r", 0, 0, false, "")
    
    player:GossipMenuAddItem(3, "|TInterface\\Icons\\Ability_Repair:20|t Back", 0, 99)
    player:GossipSendMenu(1, creature)
end

local function ShowInstanceList(player, creature)
    player:GossipClearMenu()
    
    player:GossipMenuAddItem(0, 
        "|TInterface\\Icons\\INV_Misc_Key_02:30|t |cFF00FFFFSelect Instance to Reset|r\n\n" ..
        "|cFFAAAAFFChoose an instance to reset:|r",
        0, 0, false, "")
    
    -- Common instances
    local instances = {
        {mapId = 533, name = "Naxxramas"},
        {mapId = 631, name = "Icecrown Citadel"},
        {mapId = 603, name = "Ulduar"},
        {mapId = 649, name = "Trial of the Crusader"},
        {mapId = 574, name = "Utgarde Keep"},
        {mapId = 575, name = "Utgarde Pinnacle"},
        {mapId = 576, name = "The Nexus"},
        {mapId = 578, name = "The Oculus"},
    }
    
    for i, inst in ipairs(instances) do
        player:GossipMenuAddItem(3, 
            string.format("|TInterface\\Icons\\INV_Misc_Key_02:20|t %s", inst.name),
            0, 200 + inst.mapId)
    end
    
    player:GossipMenuAddItem(3, "|TInterface\\Icons\\Ability_Repair:20|t Back", 0, 99)
    player:GossipSendMenu(1, creature)
end

local function OnGossipSelect(event, player, creature, sender, intid, code)
    player:GossipClearMenu()
    
    if intid == 99 then
        -- Back to main menu
        dofile("main_menu_npc.lua")
        OnGossipHello(event, player, creature)
    elseif intid == 101 then
        -- Reset all dungeons
        if sInstanceResetSystem:ResetAllInstances(player, false) then
            player:SendBroadcastMessage("|cFF00FF00All dungeons reset successfully!|r")
        else
            player:SendBroadcastMessage("|cFFFF0000Failed to reset dungeons.|r")
        end
        ShowInstanceResetMenu(player, creature)
    elseif intid == 102 then
        -- Reset all raids
        if sInstanceResetSystem:ResetAllInstances(player, true) then
            player:SendBroadcastMessage("|cFF00FF00All raids reset successfully!|r")
        else
            player:SendBroadcastMessage("|cFFFF0000Failed to reset raids.|r")
        end
        ShowInstanceResetMenu(player, creature)
    elseif intid == 103 then
        -- Show completion stats
        ShowCompletionStats(player, creature)
    elseif intid == 104 then
        -- Show instance list
        ShowInstanceList(player, creature)
    elseif intid >= 200 and intid < 300 then
        -- Reset specific instance
        local mapId = intid - 200
        if sInstanceResetSystem:ResetInstance(player, mapId, false) then
            player:SendBroadcastMessage(string.format("|cFF00FF00Instance %s reset successfully!|r", GetMapName(mapId)))
        else
            player:SendBroadcastMessage("|cFFFF0000Failed to reset instance.|r")
        end
        ShowInstanceResetMenu(player, creature)
    else
        ShowInstanceResetMenu(player, creature)
    end
    
    player:GossipSendMenu(1, creature)
end

function OnGossipHello(event, player, creature)
    ShowInstanceResetMenu(player, creature)
end

RegisterCreatureGossipEvent(NPC_ENTRY, 1, OnGossipHello)
RegisterCreatureGossipEvent(NPC_ENTRY, 2, OnGossipSelect)

print("[Progressive Systems] Instance Reset NPC loaded successfully!")

