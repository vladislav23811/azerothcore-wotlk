-- ============================================================
-- Daily Challenge Generator
-- Generates and manages daily/weekly challenges
-- ============================================================

local DailyChallengeGenerator = {}

-- Challenge templates
DailyChallengeGenerator.templates = {
    daily = {
        { type = "kill", name = "Kill 50 Creatures", target = 50, reward = 100 },
        { type = "kill_elite", name = "Kill 10 Elite Creatures", target = 10, reward = 200 },
        { type = "kill_boss", name = "Kill 1 Boss", target = 1, reward = 500 },
        { type = "dungeon", name = "Complete 1 Dungeon", target = 1, reward = 300 },
        { type = "quest", name = "Complete 5 Quests", target = 5, reward = 150 },
        { type = "pvp_kill", name = "Kill 3 Players", target = 3, reward = 400 },
    },
    weekly = {
        { type = "kill", name = "Kill 500 Creatures", target = 500, reward = 1000 },
        { type = "kill_boss", name = "Kill 10 Bosses", target = 10, reward = 5000 },
        { type = "dungeon", name = "Complete 5 Dungeons", target = 5, reward = 2000 },
        { type = "raid", name = "Complete 1 Raid", target = 1, reward = 5000 },
        { type = "quest", name = "Complete 25 Quests", target = 25, reward = 1500 },
        { type = "pvp_kill", name = "Kill 20 Players", target = 20, reward = 3000 },
    }
}

-- Generate daily challenges
function DailyChallengeGenerator.GenerateDaily()
    local today = os.date("%Y-%m-%d")
    
    -- Check if challenges already generated today
    local existing = WorldDBQuery(string.format(
        "SELECT COUNT(*) FROM daily_challenges WHERE challenge_type = 0 AND start_date = '%s'",
        today
    ))
    
    if existing and existing:GetUInt32(0) > 0 then
        return  -- Already generated
    end
    
    -- Generate 3 random daily challenges
    local templates = DailyChallengeGenerator.templates.daily
    local selected = {}
    
    for i = 1, 3 do
        local template = templates[math.random(#templates)]
        while DailyChallengeGenerator.IsSelected(selected, template) do
            template = templates[math.random(#templates)]
        end
        table.insert(selected, template)
    end
    
    -- Insert into database
    for _, template in ipairs(selected) do
        WorldDBExecute(string.format(
            "INSERT INTO daily_challenges (challenge_name, challenge_description, challenge_type, target_value, reward_points, start_date, end_date, is_active) " ..
            "VALUES ('%s', '%s', 0, %d, %d, '%s', '%s', 1)",
            template.name,
            template.name,  -- Use name as description
            template.target,
            template.reward,
            today,
            today
        ))
    end
    
    print(string.format("[Daily Challenges] Generated %d daily challenges for %s", #selected, today))
end

-- Generate weekly challenges
function DailyChallengeGenerator.GenerateWeekly()
    local today = os.date("%Y-%m-%d")
    local weekEnd = os.date("%Y-%m-%d", os.time() + (7 * 24 * 60 * 60))
    
    -- Check if challenges already generated this week
    local existing = WorldDBQuery(string.format(
        "SELECT COUNT(*) FROM daily_challenges WHERE challenge_type = 1 AND start_date = '%s'",
        today
    ))
    
    if existing and existing:GetUInt32(0) > 0 then
        return  -- Already generated
    end
    
    -- Generate 3 random weekly challenges
    local templates = DailyChallengeGenerator.templates.weekly
    local selected = {}
    
    for i = 1, 3 do
        local template = templates[math.random(#templates)]
        while DailyChallengeGenerator.IsSelected(selected, template) do
            template = templates[math.random(#templates)]
        end
        table.insert(selected, template)
    end
    
    -- Insert into database
    for _, template in ipairs(selected) do
        WorldDBExecute(string.format(
            "INSERT INTO daily_challenges (challenge_name, challenge_description, challenge_type, target_value, reward_points, start_date, end_date, is_active) " ..
            "VALUES ('%s', '%s', 1, %d, %d, '%s', '%s', 1)",
            template.name,
            template.name,
            template.target,
            template.reward,
            today,
            weekEnd
        ))
    end
    
    print(string.format("[Daily Challenges] Generated %d weekly challenges for week %s - %s", #selected, today, weekEnd))
end

-- Helper: Check if template already selected
function DailyChallengeGenerator.IsSelected(selected, template)
    for _, t in ipairs(selected) do
        if t.type == template.type then
            return true
        end
    end
    return false
end

-- Track challenge progress
function DailyChallengeGenerator.TrackProgress(player, challengeType, amount)
    if not player then
        return
    end
    
    local guid = player:GetGUIDLow()
    local today = os.date("%Y-%m-%d")
    
    -- Get active challenges of this type
    local challenges = WorldDBQuery(string.format(
        "SELECT challenge_id, target_value FROM daily_challenges " ..
        "WHERE challenge_type = %d AND is_active = 1 AND '%s' BETWEEN start_date AND end_date",
        challengeType, today
    ))
    
    if not challenges then
        return
    end
    
    repeat
        local challengeId = challenges:GetUInt32(0)
        local target = challenges:GetUInt32(1)
        
        -- Get or create progress
        local progress = CharDBQuery(string.format(
            "SELECT progress FROM character_challenge_progress " ..
            "WHERE guid = %d AND challenge_id = %d",
            guid, challengeId
        ))
        
        local currentProgress = 0
        if progress then
            currentProgress = progress:GetUInt32(0)
        else
            -- Create progress entry
            CharDBExecute(string.format(
                "INSERT INTO character_challenge_progress (guid, challenge_id, progress) " ..
                "VALUES (%d, %d, 0)",
                guid, challengeId
            ))
        end
        
        -- Update progress
        local newProgress = math.min(currentProgress + amount, target)
        CharDBExecute(string.format(
            "UPDATE character_challenge_progress SET progress = %d " ..
            "WHERE guid = %d AND challenge_id = %d",
            newProgress, guid, challengeId
        ))
        
        -- Check if completed
        if newProgress >= target then
            DailyChallengeGenerator.CompleteChallenge(player, challengeId)
        end
    until not challenges:NextRow()
end

-- Complete challenge and award reward
function DailyChallengeGenerator.CompleteChallenge(player, challengeId)
    if not player then
        return
    end
    
    local guid = player:GetGUIDLow()
    
    -- Check if already claimed
    local claimed = CharDBQuery(string.format(
        "SELECT reward_claimed FROM character_challenge_progress " ..
        "WHERE guid = %d AND challenge_id = %d",
        guid, challengeId
    ))
    
    if claimed and claimed:GetUInt32(0) == 1 then
        return  -- Already claimed
    end
    
    -- Get challenge reward
    local challenge = WorldDBQuery(string.format(
        "SELECT challenge_name, reward_points FROM daily_challenges WHERE challenge_id = %d",
        challengeId
    ))
    
    if not challenge then
        return
    end
    
    local name = challenge:GetString(0)
    local reward = challenge:GetUInt32(1)
    
    -- Award points
    if ProgressiveCore and ProgressiveCore.AddProgressionPoints then
        ProgressiveCore.AddProgressionPoints(player, reward)
    end
    
    -- Mark as claimed
    CharDBExecute(string.format(
        "UPDATE character_challenge_progress SET reward_claimed = 1 " ..
        "WHERE guid = %d AND challenge_id = %d",
        guid, challengeId
    ))
    
    player:SendBroadcastMessage(string.format(
        "|cFF00FF00Challenge Complete!|r\n" ..
        "|cFFAAAAFF%s|r\n" ..
        "|cFF00FF00Reward: %d progression points|r",
        name, reward
    ))
end

-- Hook into kill events
local function OnCreatureKill(event, killer, killed)
    if not killer or not killer:IsPlayer() then
        return
    end
    
    local isElite = killed:IsElite()
    local isBoss = killed:IsWorldBoss() or (killed:GetMaxHealth() > 1000000)  -- Rough boss detection
    
    DailyChallengeGenerator.TrackProgress(killer, 0, 1)  -- Daily kill
    
    if isElite then
        DailyChallengeGenerator.TrackProgress(killer, 0, 1)  -- Daily elite kill
    end
    
    if isBoss then
        DailyChallengeGenerator.TrackProgress(killer, 0, 1)  -- Daily boss kill
    end
end

-- Hook into dungeon complete
local function OnDungeonComplete(event, player, dungeonId)
    if not player then
        return
    end
    
    DailyChallengeGenerator.TrackProgress(player, 0, 1)  -- Daily dungeon
end

-- Hook into quest complete
local function OnQuestComplete(event, player, quest)
    if not player or not quest then
        return
    end
    
    DailyChallengeGenerator.TrackProgress(player, 0, 1)  -- Daily quest
end

-- Register events
RegisterPlayerEvent(7, OnCreatureKill)  -- PLAYER_EVENT_ON_KILL_CREATURE
RegisterPlayerEvent(13, OnQuestComplete)  -- PLAYER_EVENT_ON_QUEST_COMPLETE

-- Generate challenges on server start
CreateLuaEvent(function()
    DailyChallengeGenerator.GenerateDaily()
    DailyChallengeGenerator.GenerateWeekly()
end, 5000, 1)  -- 5 seconds after load

-- Generate daily challenges every day at midnight
CreateLuaEvent(function()
    local hour = tonumber(os.date("%H"))
    if hour == 0 then
        DailyChallengeGenerator.GenerateDaily()
    end
end, 3600000, 0)  -- Check every hour

-- Export
_G.DailyChallengeGenerator = DailyChallengeGenerator

print("[Progressive Systems] Daily Challenge Generator loaded!")

