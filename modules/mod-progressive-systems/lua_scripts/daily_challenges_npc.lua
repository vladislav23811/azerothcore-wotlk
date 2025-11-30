-- ============================================================
-- Daily Challenges NPC
-- Shows and tracks daily/weekly challenges
-- ============================================================

dofile("progressive_systems_core.lua")
dofile("config.lua")

local Config = _G.Config or {}
local NPC_ENTRY = 190007  -- Add to config

local function OnGossipHello(event, player, creature)
    player:GossipClearMenu()
    
    -- Get active challenges
    local dailyChallenges = {}
    local weeklyChallenges = {}
    
    local qDaily = CharDBQuery([[
        SELECT challenge_id, challenge_name, challenge_description, target_value, reward_points,
               (SELECT progress FROM character_challenge_progress WHERE guid = ]] .. player:GetGUIDLow() .. [[ AND challenge_id = daily_challenges.challenge_id) as progress
        FROM daily_challenges
        WHERE challenge_type = 0 AND is_active = 1 AND CURDATE() BETWEEN start_date AND end_date
        ORDER BY challenge_id
    ]])
    
    if qDaily then
        repeat
            table.insert(dailyChallenges, {
                id = qDaily:GetUInt32(0),
                name = qDaily:GetString(1),
                desc = qDaily:GetString(2),
                target = qDaily:GetUInt32(3),
                reward = qDaily:GetUInt32(4),
                progress = qDaily:GetUInt32(5) or 0
            })
        until not qDaily:NextRow()
    end
    
    local qWeekly = CharDBQuery([[
        SELECT challenge_id, challenge_name, challenge_description, target_value, reward_points,
               (SELECT progress FROM character_challenge_progress WHERE guid = ]] .. player:GetGUIDLow() .. [[ AND challenge_id = daily_challenges.challenge_id) as progress
        FROM daily_challenges
        WHERE challenge_type = 1 AND is_active = 1 AND CURDATE() BETWEEN start_date AND end_date
        ORDER BY challenge_id
    ]])
    
    if qWeekly then
        repeat
            table.insert(weeklyChallenges, {
                id = qWeekly:GetUInt32(0),
                name = qWeekly:GetString(1),
                desc = qWeekly:GetString(2),
                target = qWeekly:GetUInt32(3),
                reward = qWeekly:GetUInt32(4),
                progress = qWeekly:GetUInt32(5) or 0
            })
        until not qWeekly:NextRow()
    end
    
    -- Header
    player:GossipMenuAddItem(0, string.format(
        "|TInterface\\Icons\\Achievement_Boss_LichKing:30|t |cFF00FFFFDaily & Weekly Challenges|r\n\n" ..
        "|cFF00FF00Daily Challenges:|r %d\n" ..
        "|cFF00FF00Weekly Challenges:|r %d",
        #dailyChallenges, #weeklyChallenges
    ), 0, 0, false, "")
    
    -- Daily Challenges
    if #dailyChallenges > 0 then
        player:GossipMenuAddItem(0, "|cFFFFFF00=== Daily Challenges ===|r", 0, 0, false, "")
        for i, challenge in ipairs(dailyChallenges) do
            local percent = math.floor((challenge.progress / challenge.target) * 100)
            local color = percent >= 100 and "00FF00" or "FFFFFF"
            player:GossipMenuAddItem(0, string.format(
                "|cFF%s%s|r\n|cFFAAAAFFProgress: %d/%d (%d%%)|r |cFF00FF00Reward: %d pts|r",
                color, challenge.name, challenge.progress, challenge.target, percent, challenge.reward
            ), 0, 100 + challenge.id, false, "")
        end
    end
    
    -- Weekly Challenges
    if #weeklyChallenges > 0 then
        player:GossipMenuAddItem(0, "|cFFFFFF00=== Weekly Challenges ===|r", 0, 0, false, "")
        for i, challenge in ipairs(weeklyChallenges) do
            local percent = math.floor((challenge.progress / challenge.target) * 100)
            local color = percent >= 100 and "00FF00" or "FFFFFF"
            player:GossipMenuAddItem(0, string.format(
                "|cFF%s%s|r\n|cFFAAAAFFProgress: %d/%d (%d%%)|r |cFF00FF00Reward: %d pts|r",
                color, challenge.name, challenge.progress, challenge.target, percent, challenge.reward
            ), 0, 200 + challenge.id, false, "")
        end
    end
    
    player:GossipMenuAddItem(3, "|TInterface\\Icons\\Ability_Repair:20|t Back", 0, 99)
    player:GossipSendMenu(1, creature)
end

local function OnGossipSelect(event, player, creature, sender, intid, code)
    if intid >= 100 and intid < 200 then
        -- Daily challenge selected
        local challengeId = intid - 100
        -- Show details or claim reward if completed
        OnGossipHello(event, player, creature)
    elseif intid >= 200 and intid < 300 then
        -- Weekly challenge selected
        local challengeId = intid - 200
        -- Show details or claim reward if completed
        OnGossipHello(event, player, creature)
    elseif intid == 99 then
        -- Back to main menu
        dofile("main_menu_npc.lua")
        OnGossipHello(event, player, creature)
    else
        player:GossipComplete()
    end
end

RegisterCreatureGossipEvent(NPC_ENTRY, 1, OnGossipHello)
RegisterCreatureGossipEvent(NPC_ENTRY, 2, OnGossipSelect)

print("[Progressive Systems] Daily Challenges NPC loaded!")

