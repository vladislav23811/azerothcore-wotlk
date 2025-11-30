-- ProgressiveSystems.lua
-- Main addon logic for all Progressive Systems

ProgressiveSystems = {}
local PS = ProgressiveSystems

-- Saved Variables
ProgressiveSystemsDB = ProgressiveSystemsDB or {}
ProgressiveSystemsPerCharDB = ProgressiveSystemsPerCharDB or {}

-- Addon Version
PS.VERSION = "2.0"

function PS:OnInitialize()
    self:Print("Initializing ProgressiveSystems Addon v" .. self.VERSION .. "...")
    
    -- Initialize saved variables
    if not ProgressiveSystemsDB.globalData then
        ProgressiveSystemsDB.globalData = {
            lastUpdate = time(),
            settings = {
                showNotifications = true,
                autoOpenOnLevel = true,
                showExperienceBar = true,
            }
        }
    end
    
    if not ProgressiveSystemsPerCharDB.charData then
        ProgressiveSystemsPerCharDB.charData = {
            progressionData = {},
            paragonData = {},
            customStats = {},
            lastUpdate = time()
        }
    end
    
    -- Register events
    self:RegisterEvent("PLAYER_LOGIN")
    self:RegisterEvent("PLAYER_LEVEL_UP")
    self:RegisterEvent("PLAYER_XP_UPDATE")
    self:RegisterEvent("CHAT_MSG_ADDON")
    self:RegisterEvent("UNIT_LEVEL")
    self:RegisterEvent("PLAYER_TARGET_CHANGED")
    
    -- Register slash commands
    SLASH_PROGRESSIVESYSTEMS1 = "/ps"
    SLASH_PROGRESSIVESYSTEMS2 = "/progressive"
    SlashCmdList["PROGRESSIVESYSTEMS"] = function(msg, editbox)
        PS:HandleSlashCommand(msg)
    end
    
    self:Print("ProgressiveSystems Addon Initialized.")
    self:Print("Type |cff00ff00/ps|r or |cff00ff00/progressive|r for commands")
end

function PS:OnEvent(event, ...)
    if event == "PLAYER_LOGIN" then
        self:OnPlayerLogin()
    elseif event == "PLAYER_LEVEL_UP" then
        self:OnLevelUp(...)
    elseif event == "PLAYER_XP_UPDATE" then
        self:OnXPUpdate()
    elseif event == "CHAT_MSG_ADDON" then
        self:HandleAddonMessage(...)
    elseif event == "UNIT_LEVEL" then
        local unit = ...
        if unit == "player" then
            self:CheckParagonEligibility()
        end
    end
end

function PS:OnPlayerLogin()
    self:RequestAllData()
    self:CheckParagonEligibility()
    
    -- Show welcome message if first time
    if not ProgressiveSystemsDB.globalData.welcomeShown then
        self:Print("Welcome to Progressive Systems! Type |cff00ff00/ps|r for commands")
        ProgressiveSystemsDB.globalData.welcomeShown = true
    end
end

function PS:OnLevelUp(level)
    if level >= 80 then
        self:Print("|cff00ff00You are now eligible for Paragon levels!|r")
        self:CheckParagonEligibility()
        if ProgressiveSystemsDB.globalData.settings.autoOpenOnLevel then
            C_Timer.After(2, function()
                PS.UI:ToggleMainWindow()
            end)
        end
    end
end

function PS:OnXPUpdate()
    local level = UnitLevel("player")
    if level >= 80 then
        -- Request paragon data update
        self:RequestParagonData()
    end
end

function PS:CheckParagonEligibility()
    local level = UnitLevel("player")
    if level >= 80 then
        self:RequestParagonData()
    end
end

function PS:RequestAllData()
    -- Request all data from server
    self:RequestProgressionData()
    self:RequestParagonData()
    self:RequestCustomStatsData()
    self:RequestInstanceData()
end

function PS:RequestProgressionData()
    -- Request progression data from server
    C_ChatInfo.SendAddonMessage("PS_DATA_REQUEST", "PROGRESSION", "WHISPER", UnitName("player"))
end

function PS:RequestParagonData()
    -- Request paragon data from server
    C_ChatInfo.SendAddonMessage("PS_DATA_REQUEST", "PARAGON", "WHISPER", UnitName("player"))
end

function PS:RequestCustomStatsData()
    -- Request custom stats data from server
    C_ChatInfo.SendAddonMessage("PS_DATA_REQUEST", "CUSTOM_STATS", "WHISPER", UnitName("player"))
end

function PS:HandleAddonMessage(prefix, msg, channel, sender)
    if prefix == "PROGRESSIVE_SYSTEMS" or prefix == "PS_DATA_UPDATE" then
        -- Parse message
        local data = self:ParseDataMessage(msg)
        if data then
            if data.type == "PROGRESSION" then
                ProgressiveSystems.Data:UpdateProgressionData(data)
            elseif data.type == "PARAGON" then
                ProgressiveSystems.Data:UpdateParagonData(data)
            elseif data.type == "CUSTOM_STATS" then
                ProgressiveSystems.Data:UpdateCustomStatsData(data)
            elseif data.type == "POINTS_UPDATE" then
                ProgressiveSystems.Data:UpdatePoints(data.points)
            elseif data.type == "KILL_UPDATE" then
                ProgressiveSystems.Data:UpdateKills(data.kills)
            elseif data.type == "INSTANCE_DATA" then
                -- Update instance data
                if not ProgressiveSystemsPerCharDB.charData.instanceData then
                    ProgressiveSystemsPerCharDB.charData.instanceData = {}
                end
                ProgressiveSystemsPerCharDB.charData.instanceData = data.instances or {}
                ProgressiveSystems.UI:UpdateInstancesTab()
            end
            
            -- Update UI
            ProgressiveSystems.UI:UpdateAllWindows()
        end
    end
end

function PS:ParseDataMessage(msg)
    -- Parse message format: "TYPE|key:value|key:value"
    local data = {}
    local parts = {}
    for part in string.gmatch(msg, "([^|]+)") do
        table.insert(parts, part)
    end
    
    if #parts > 0 then
        data.type = parts[1]
        for i = 2, #parts do
            local key, value = parts[i]:match("([^:]+):(.+)")
            if key and value then
                -- Try to convert to number
                local numValue = tonumber(value)
                if numValue then
                    data[key] = numValue
                else
                    data[key] = value
                end
            end
        end
        return data
    end
    return nil
end

function PS:HandleSlashCommand(msg)
    local cmd, arg = msg:match("^(%S*)%s*(.*)$")
    cmd = string.lower(cmd or "")
    
    if cmd == "ui" or cmd == "" then
        ProgressiveSystems.UI:ToggleMainWindow()
    elseif cmd == "paragon" or cmd == "pg" then
        ProgressiveSystems.UI:ToggleParagonWindow()
    elseif cmd == "stats" then
        ProgressiveSystems.UI:ToggleStatsWindow()
    elseif cmd == "power" then
        self:ShowPowerLevel()
    elseif cmd == "info" then
        self:ShowInfo()
    elseif cmd == "config" or cmd == "settings" then
        ProgressiveSystems.UI:ToggleSettingsWindow()
    elseif cmd == "reset" or cmd == "instances" then
        if ProgressiveSystems.InstanceReset then
            ProgressiveSystems.InstanceReset:ToggleMainWindow()
        else
            self:Print("Instance Reset UI not loaded. Use NPC or reload addon.")
        end
    else
        self:Print("Usage: /ps [ui|paragon|stats|power|info|config|reset]")
        self:Print("  ui - Open main window")
        self:Print("  paragon - Open paragon window")
        self:Print("  stats - Open stats window")
        self:Print("  power - Show power level")
        self:Print("  info - Show system info")
        self:Print("  config - Open settings")
        self:Print("  reset - Open instance reset window")
    end
end

function PS:ShowPowerLevel()
    local data = ProgressiveSystemsPerCharDB.charData
    if data and data.progressionData then
        local power = data.progressionData.power_level or 0
        local tier = data.progressionData.current_tier or 1
        local prestige = data.progressionData.prestige_level or 0
        
        self:Print(string.format(
            "|cff00ffff=== Power Level ===|r\n" ..
            "Power Level: |cff00ff00%d|r\n" ..
            "Current Tier: |cffffff00%d|r\n" ..
            "Prestige Level: |cffff0000%d|r",
            power, tier, prestige
        ))
    else
        self:Print("No progression data available. Talk to Progressive Systems NPCs.")
    end
end

function PS:ShowInfo()
    local data = ProgressiveSystemsPerCharDB.charData
    self:Print("|cff00ffff=== Progressive Systems Info ===|r")
    
    if data and data.paragonData then
        local pg = data.paragonData
        self:Print(string.format(
            "Paragon Level: |cff00ff00%d|r (Tier %d) | Points: |cffffff00%d|r",
            pg.level or 0, pg.tier or 0, pg.points or 0
        ))
    end
    
    if data and data.progressionData then
        local prog = data.progressionData
        self:Print(string.format(
            "Progression Points: |cff00ff00%d|r | Kills: |cffffff00%d|r",
            prog.progression_points or 0, prog.total_kills or 0
        ))
    end
    
    self:Print("Type |cff00ff00/ps ui|r to open the main window")
end

function PS:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[ProgressiveSystems]|r " .. msg)
end

-- Register the addon
local addonFrame = CreateFrame("Frame", "ProgressiveSystemsAddonFrame")
addonFrame:SetScript("OnEvent", function(self, event, ...) PS:OnEvent(event, ...) end)
addonFrame:RegisterEvent("PLAYER_LOGIN")
addonFrame:RegisterEvent("PLAYER_LEVEL_UP")
addonFrame:RegisterEvent("PLAYER_XP_UPDATE")
addonFrame:RegisterEvent("CHAT_MSG_ADDON")
addonFrame:RegisterEvent("UNIT_LEVEL")

PS:OnInitialize()
