-- ParagonSystem.lua
-- Main addon logic for Paragon System

ParagonSystem = {}
local PS = ParagonSystem

-- Saved Variables
ParagonSystemDB = {}
ParagonSystemPerCharDB = {}

function PS:OnInitialize()
    self:Print("Initializing ParagonSystem Addon...")
    
    -- Initialize saved variables
    if not ParagonSystemDB.globalData then
        ParagonSystemDB.globalData = {}
    end
    if not ParagonSystemPerCharDB.charData then
        ParagonSystemPerCharDB.charData = {}
    end
    
    -- Register events
    self:RegisterEvent("PLAYER_LOGIN")
    self:RegisterEvent("PLAYER_LEVEL_UP")
    self:RegisterEvent("CHAT_MSG_ADDON")
    
    -- Register slash commands
    SLASH_PARAGON1 = "/paragon"
    SLASH_PARAGON2 = "/pg"
    SlashCmdList["PARAGON"] = function(msg, editbox)
        PS:HandleSlashCommand(msg)
    end
    
    self:Print("ParagonSystem Addon Initialized.")
end

function PS:OnEvent(event, ...)
    if event == "PLAYER_LOGIN" then
        self:RequestParagonData()
    elseif event == "PLAYER_LEVEL_UP" then
        self:OnLevelUp(...)
    elseif event == "CHAT_MSG_ADDON" then
        self:HandleAddonMessage(...)
    end
end

function PS:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[ParagonSystem]|r " .. msg)
end

function PS:RequestParagonData()
    -- Request paragon data from server
    C_ChatInfo.SendAddonMessage("PS_DATA_REQUEST", "ALL", "WHISPER", UnitName("player"))
    self:Print("Requested paragon data from server.")
end

function PS:OnLevelUp(level)
    if level >= 80 then
        self:Print("You are now eligible for Paragon levels!")
        self:RequestParagonData()
    end
end

function PS:HandleAddonMessage(prefix, msg, channel, sender)
    if prefix == "PS_DATA_UPDATE" then
        -- Parse paragon data
        local data = self:ParseParagonData(msg)
        if data then
            ParagonSystem.Data:UpdateParagonData(data)
            self:Print("Received paragon data update.")
        end
    end
end

function PS:ParseParagonData(msg)
    -- Parse message format: "level:123|exp:456|points:7|tier:1"
    local data = {}
    for pair in string.gmatch(msg, "([^|]+)") do
        local key, value = pair:match("([^:]+):(.+)")
        if key and value then
            if key == "level" or key == "points" or key == "tier" then
                data[key] = tonumber(value)
            elseif key == "exp" then
                data[key] = tonumber(value)
            end
        end
    end
    return data
end

function PS:HandleSlashCommand(msg)
    local cmd, arg = msg:match("^(%S*)%s*(.*)$")
    cmd = string.lower(cmd or "")
    
    if cmd == "ui" or cmd == "" then
        ParagonSystem.UI:ToggleMainWindow()
    elseif cmd == "info" then
        self:ShowParagonInfo()
    elseif cmd == "stats" then
        ParagonSystem.UI:ShowStatsWindow()
    else
        self:Print("Usage: /paragon [ui|info|stats]")
    end
end

function PS:ShowParagonInfo()
    local data = ParagonSystemPerCharDB.charData
    if data and data.level then
        self:Print(string.format(
            "Paragon Level: %d | Tier: %d | Available Points: %d",
            data.level or 0, data.tier or 0, data.points or 0
        ))
    else
        self:Print("No paragon data available. Talk to Paragon Master NPC.")
    end
end

-- Register the addon
local addonFrame = CreateFrame("Frame", "ParagonSystemAddonFrame")
addonFrame:SetScript("OnEvent", function(self, event, ...) PS:OnEvent(event, ...) end)
addonFrame:RegisterEvent("PLAYER_LOGIN")
addonFrame:RegisterEvent("PLAYER_LEVEL_UP")
addonFrame:RegisterEvent("CHAT_MSG_ADDON")

PS:OnInitialize()

