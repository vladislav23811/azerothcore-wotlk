-- ParagonSystemData.lua
-- Data storage and management

local PS_Data = {}
ParagonSystem.Data = PS_Data

PS_Data.paragonData = {}
PS_Data.statsData = {}

function PS_Data:UpdateParagonData(data)
    self.paragonData = data
    ParagonSystemPerCharDB.charData = data
    ParagonSystem.UI:UpdateMainWindow(data)
end

function PS_Data:UpdateStatsData(stats)
    self.statsData = stats
    ParagonSystemPerCharDB.charData.stats = stats
end

function PS_Data:GetParagonLevel()
    return self.paragonData.level or 0
end

function PS_Data:GetAvailablePoints()
    return self.paragonData.points or 0
end

function PS_Data:GetParagonTier()
    return self.paragonData.tier or 0
end

