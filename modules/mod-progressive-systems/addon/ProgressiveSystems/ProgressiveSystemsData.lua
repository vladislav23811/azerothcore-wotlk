-- ProgressiveSystemsData.lua
-- Data storage and management

local PS_Data = {}
ProgressiveSystems.Data = PS_Data

-- Data storage
PS_Data.progressionData = {}
PS_Data.paragonData = {}
PS_Data.customStats = {}

function PS_Data:UpdateProgressionData(data)
    self.progressionData = data
    ProgressiveSystemsPerCharDB.charData.progressionData = data
    ProgressiveSystems.UI:UpdateAllWindows()
end

function PS_Data:UpdateParagonData(data)
    self.paragonData = data
    ProgressiveSystemsPerCharDB.charData.paragonData = data
    ProgressiveSystems.UI:UpdateAllWindows()
    
    -- Show notification if level up
    if ProgressiveSystemsDB.globalData.settings.showNotifications then
        if data.level and data.level > (self.paragonData.lastLevel or 0) then
            ProgressiveSystems:Print(string.format(
                "|cff00ff00Paragon Level Up!|r You reached Paragon Level %d!", data.level))
        end
    end
end

function PS_Data:UpdateCustomStatsData(data)
    self.customStats = data
    ProgressiveSystemsPerCharDB.charData.customStats = data
    ProgressiveSystems.UI:UpdateAllWindows()
end

function PS_Data:UpdatePoints(points)
    if not self.progressionData then
        self.progressionData = {}
    end
    self.progressionData.progression_points = points
    ProgressiveSystemsPerCharDB.charData.progressionData = self.progressionData
    ProgressiveSystems.UI:UpdateAllWindows()
end

function PS_Data:UpdateKills(kills)
    if not self.progressionData then
        self.progressionData = {}
    end
    self.progressionData.total_kills = kills
    ProgressiveSystemsPerCharDB.charData.progressionData = self.progressionData
    ProgressiveSystems.UI:UpdateAllWindows()
end

-- Getters
function PS_Data:GetProgressionPoints()
    return self.progressionData.progression_points or 0
end

function PS_Data:GetParagonLevel()
    return self.paragonData.level or 0
end

function PS_Data:GetAvailableParagonPoints()
    return self.paragonData.points or 0
end

function PS_Data:GetPowerLevel()
    return self.progressionData.power_level or 0
end

function PS_Data:GetCurrentTier()
    return self.progressionData.current_tier or 1
end

function PS_Data:GetPrestigeLevel()
    return self.progressionData.prestige_level or 0
end

function PS_Data:GetCustomStat(statName)
    return self.customStats[statName] or 0
end
