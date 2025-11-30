-- ProgressiveSystemsUI.lua
-- Complete UI for all Progressive Systems

local PS_UI = {}
ProgressiveSystems.UI = PS_UI

-- Frame references
local mainFrame
local paragonFrame
local statsFrame
local settingsFrame

-- ============================================================
-- MAIN WINDOW
-- ============================================================
function PS_UI:CreateMainWindow()
    mainFrame = CreateFrame("Frame", "ProgressiveSystemsMainWindow", UIParent, "BasicFrameTemplate")
    mainFrame:SetSize(500, 650)
    mainFrame:SetPoint("CENTER")
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
    mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing)
    
    mainFrame.TitleText:SetText("Progressive Systems")
    
    -- Close button
    mainFrame.CloseButton:SetScript("OnClick", function() mainFrame:Hide() end)
    
    -- Content area
    local content = CreateFrame("Frame", nil, mainFrame)
    content:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 16, -32)
    content:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -16, 50)
    
    -- Tab buttons
    local tabProgression = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    tabProgression:SetSize(120, 30)
    tabProgression:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -10)
    tabProgression:SetText("Progression")
    tabProgression:SetScript("OnClick", function() self:ShowTab("progression") end)
    
    local tabParagon = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    tabParagon:SetSize(120, 30)
    tabParagon:SetPoint("LEFT", tabProgression, "RIGHT", 5, 0)
    tabParagon:SetText("Paragon")
    tabParagon:SetScript("OnClick", function() self:ShowTab("paragon") end)
    
    local tabStats = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    tabStats:SetSize(120, 30)
    tabStats:SetPoint("LEFT", tabParagon, "RIGHT", 5, 0)
    tabStats:SetText("Custom Stats")
    tabStats:SetScript("OnClick", function() self:ShowTab("stats") end)
    
    local tabInstances = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    tabInstances:SetSize(120, 30)
    tabInstances:SetPoint("LEFT", tabStats, "RIGHT", 5, 0)
    tabInstances:SetText("Instances")
    tabInstances:SetScript("OnClick", function() self:ShowTab("instances") end)
    
    -- Content area for tabs
    local tabContent = CreateFrame("Frame", nil, content)
    tabContent:SetPoint("TOPLEFT", tabProgression, "BOTTOMLEFT", 0, -10)
    tabContent:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 10)
    
    mainFrame.tabContent = tabContent
    mainFrame.currentTab = "progression"
    
    -- Progression tab content
    local progContent = CreateFrame("Frame", nil, tabContent)
    progContent:SetAllPoints(tabContent)
    progContent:Hide()
    
    -- Power level display
    local powerText = progContent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    powerText:SetPoint("TOP", progContent, "TOP", 0, -10)
    powerText:SetText("Power Level: 0")
    progContent.powerText = powerText
    
    -- Tier display
    local tierText = progContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    tierText:SetPoint("TOP", powerText, "BOTTOM", 0, -10)
    tierText:SetText("Current Tier: 1")
    progContent.tierText = tierText
    
    -- Points display
    local pointsText = progContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    pointsText:SetPoint("TOP", tierText, "BOTTOM", 0, -10)
    pointsText:SetText("Progression Points: 0")
    progContent.pointsText = pointsText
    
    -- Kills display
    local killsText = progContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    killsText:SetPoint("TOP", pointsText, "BOTTOM", 0, -10)
    killsText:SetText("Total Kills: 0")
    progContent.killsText = killsText
    
    -- Prestige display
    local prestigeText = progContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    prestigeText:SetPoint("TOP", killsText, "BOTTOM", 0, -10)
    prestigeText:SetText("Prestige Level: 0")
    progContent.prestigeText = prestigeText
    
    -- Instance Reset button in progression tab
    local instanceResetBtn = CreateFrame("Button", nil, progContent, "UIPanelButtonTemplate")
    instanceResetBtn:SetSize(180, 30)
    instanceResetBtn:SetPoint("TOP", prestigeText, "BOTTOM", 0, -15)
    instanceResetBtn:SetText("Instance Reset")
    instanceResetBtn:SetScript("OnClick", function()
        if ProgressiveSystems.InstanceReset then
            ProgressiveSystems.InstanceReset:ToggleMainWindow()
        else
            ProgressiveSystems:Print("Instance Reset UI not loaded. Use /ps reset")
        end
    end)
    progContent.instanceResetBtn = instanceResetBtn
    
    mainFrame.progContent = progContent
    
    -- Paragon tab content
    local paragonContent = CreateFrame("Frame", nil, tabContent)
    paragonContent:SetAllPoints(tabContent)
    paragonContent:Hide()
    
    -- Paragon level
    local pgLevelText = paragonContent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    pgLevelText:SetPoint("TOP", paragonContent, "TOP", 0, -10)
    pgLevelText:SetText("Paragon Level: 0")
    paragonContent.levelText = pgLevelText
    
    -- Paragon tier
    local pgTierText = paragonContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    pgTierText:SetPoint("TOP", pgLevelText, "BOTTOM", 0, -10)
    pgTierText:SetText("Paragon Tier: 0")
    paragonContent.tierText = pgTierText
    
    -- Available points
    local pgPointsText = paragonContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    pgPointsText:SetPoint("TOP", pgTierText, "BOTTOM", 0, -10)
    pgPointsText:SetText("Available Points: 0")
    paragonContent.pointsText = pgPointsText
    
    -- Experience bar
    local expBar = CreateFrame("StatusBar", nil, paragonContent)
    expBar:SetSize(450, 20)
    expBar:SetPoint("TOP", pgPointsText, "BOTTOM", 0, -15)
    expBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    expBar:SetStatusBarColor(0, 1, 0, 1)
    expBar:SetMinMaxValues(0, 100)
    expBar:SetValue(0)
    
    local expBarBg = expBar:CreateTexture(nil, "BACKGROUND")
    expBarBg:SetAllPoints(expBar)
    expBarBg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    expBarBg:SetVertexColor(0.3, 0.3, 0.3, 1)
    
    local expText = expBar:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    expText:SetPoint("CENTER", expBar)
    expText:SetText("0 / 0 (0%)")
    expBar.text = expText
    
    paragonContent.expBar = expBar
    
    -- Open Paragon Master button
    local openBtn = CreateFrame("Button", nil, paragonContent, "UIPanelButtonTemplate")
    openBtn:SetSize(200, 30)
    openBtn:SetPoint("TOP", expBar, "BOTTOM", 0, -20)
    openBtn:SetText("Open Paragon Master")
    openBtn:SetScript("OnClick", function()
        ProgressiveSystems:Print("Talk to Paragon Master NPC (Entry: 190020) to allocate points!")
    end)
    
    mainFrame.paragonContent = paragonContent
    
    -- Stats tab content
    local statsContent = CreateFrame("Frame", nil, tabContent)
    statsContent:SetAllPoints(tabContent)
    statsContent:Hide()
    
    -- Scroll frame for stats
    local scrollFrame = CreateFrame("ScrollFrame", nil, statsContent, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", statsContent, "TOPLEFT", 0, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", statsContent, "BOTTOMRIGHT", -30, 10)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(400, 1000)
    scrollFrame:SetScrollChild(scrollChild)
    
    statsContent.scrollFrame = scrollFrame
    statsContent.scrollChild = scrollChild
    
    mainFrame.statsContent = statsContent
    
    -- Instances tab content
    local instancesContent = CreateFrame("Frame", nil, tabContent)
    instancesContent:SetAllPoints(tabContent)
    instancesContent:Hide()
    
    -- Title
    local instancesTitle = instancesContent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    instancesTitle:SetPoint("TOP", instancesContent, "TOP", 0, -10)
    instancesTitle:SetText("Instance Reset System")
    instancesContent.title = instancesTitle
    
    -- Info text
    local instancesInfo = instancesContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    instancesInfo:SetPoint("TOP", instancesTitle, "BOTTOM", 0, -10)
    instancesInfo:SetWidth(450)
    instancesInfo:SetJustifyH("CENTER")
    instancesInfo:SetText("Reset your instances and view completion statistics")
    instancesContent.info = instancesInfo
    
    -- Open Instance Reset button
    local openResetBtn = CreateFrame("Button", nil, instancesContent, "UIPanelButtonTemplate")
    openResetBtn:SetSize(200, 35)
    openResetBtn:SetPoint("TOP", instancesInfo, "BOTTOM", 0, -20)
    openResetBtn:SetText("Open Instance Reset")
    openResetBtn:SetScript("OnClick", function()
        if ProgressiveSystems.InstanceReset then
            ProgressiveSystems.InstanceReset:ToggleMainWindow()
        else
            ProgressiveSystems:Print("Instance Reset UI not loaded. Use /ps reset")
        end
    end)
    instancesContent.openBtn = openResetBtn
    
    -- Quick reset buttons
    local resetAllDungeonsBtn = CreateFrame("Button", nil, instancesContent, "UIPanelButtonTemplate")
    resetAllDungeonsBtn:SetSize(180, 30)
    resetAllDungeonsBtn:SetPoint("TOP", openResetBtn, "BOTTOM", 0, -15)
    resetAllDungeonsBtn:SetText("Reset All Dungeons")
    resetAllDungeonsBtn:SetScript("OnClick", function()
        ProgressiveSystems:RequestInstanceReset("all_dungeons")
    end)
    instancesContent.resetDungeonsBtn = resetAllDungeonsBtn
    
    local resetAllRaidsBtn = CreateFrame("Button", nil, instancesContent, "UIPanelButtonTemplate")
    resetAllRaidsBtn:SetSize(180, 30)
    resetAllRaidsBtn:SetPoint("TOP", resetAllDungeonsBtn, "BOTTOM", 5, -5)
    resetAllRaidsBtn:SetText("Reset All Raids")
    resetAllRaidsBtn:SetScript("OnClick", function()
        ProgressiveSystems:RequestInstanceReset("all_raids")
    end)
    instancesContent.resetRaidsBtn = resetAllRaidsBtn
    
    -- Completion stats display area
    local statsTitle = instancesContent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    statsTitle:SetPoint("TOP", resetAllRaidsBtn, "BOTTOM", 0, -20)
    statsTitle:SetText("Completion Statistics:")
    instancesContent.statsTitle = statsTitle
    
    -- Scroll frame for instance list
    local instancesScrollFrame = CreateFrame("ScrollFrame", nil, instancesContent, "UIPanelScrollFrameTemplate")
    instancesScrollFrame:SetPoint("TOPLEFT", statsTitle, "BOTTOMLEFT", -10, -10)
    instancesScrollFrame:SetPoint("BOTTOMRIGHT", instancesContent, "BOTTOMRIGHT", -30, 10)
    
    local instancesScrollChild = CreateFrame("Frame", nil, instancesScrollFrame)
    instancesScrollChild:SetSize(420, 100)
    instancesScrollFrame:SetScrollChild(instancesScrollChild)
    
    instancesContent.scrollFrame = instancesScrollFrame
    instancesContent.scrollChild = instancesScrollChild
    
    mainFrame.instancesContent = instancesContent
    
    -- Refresh button
    local refreshBtn = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
    refreshBtn:SetSize(100, 25)
    refreshBtn:SetPoint("BOTTOM", mainFrame, "BOTTOM", 0, 16)
    refreshBtn:SetText("Refresh")
    refreshBtn:SetScript("OnClick", function()
        ProgressiveSystems:RequestAllData()
    end)
    
    mainFrame:Hide()
end

function PS_UI:ShowTab(tabName)
    if not mainFrame then
        self:CreateMainWindow()
    end
    
    -- Hide all tabs
    mainFrame.progContent:Hide()
    mainFrame.paragonContent:Hide()
    mainFrame.statsContent:Hide()
    if mainFrame.instancesContent then
        mainFrame.instancesContent:Hide()
    end
    
    -- Show selected tab
    if tabName == "progression" then
        mainFrame.progContent:Show()
        mainFrame.currentTab = "progression"
    elseif tabName == "paragon" then
        mainFrame.paragonContent:Show()
        mainFrame.currentTab = "paragon"
    elseif tabName == "stats" then
        mainFrame.statsContent:Show()
        mainFrame.currentTab = "stats"
    elseif tabName == "instances" then
        if mainFrame.instancesContent then
            mainFrame.instancesContent:Show()
            mainFrame.currentTab = "instances"
            self:UpdateInstancesTab()
        end
    end
    
    self:UpdateAllWindows()
end

function PS_UI:UpdateMainWindow()
    if not mainFrame then
        return
    end
    
    local data = ProgressiveSystemsPerCharDB.charData
    
    -- Update progression tab
    if data and data.progressionData then
        local prog = data.progressionData
        mainFrame.progContent.powerText:SetText(string.format("Power Level: %d", prog.power_level or 0))
        mainFrame.progContent.tierText:SetText(string.format("Current Tier: %d", prog.current_tier or 1))
        mainFrame.progContent.pointsText:SetText(string.format("Progression Points: %d", prog.progression_points or 0))
        mainFrame.progContent.killsText:SetText(string.format("Total Kills: %d", prog.total_kills or 0))
        mainFrame.progContent.prestigeText:SetText(string.format("Prestige Level: %d", prog.prestige_level or 0))
    end
    
    -- Update paragon tab
    if data and data.paragonData then
        local pg = data.paragonData
        mainFrame.paragonContent.levelText:SetText(string.format("Paragon Level: %d", pg.level or 0))
        mainFrame.paragonContent.tierText:SetText(string.format("Paragon Tier: %d", pg.tier or 0))
        mainFrame.paragonContent.pointsText:SetText(string.format("Available Points: %d", pg.points or 0))
        
        if pg.expNeeded and pg.expNeeded > 0 then
            local percent = ((pg.experience or 0) / pg.expNeeded) * 100
            mainFrame.paragonContent.expBar:SetMinMaxValues(0, pg.expNeeded)
            mainFrame.paragonContent.expBar:SetValue(pg.experience or 0)
            mainFrame.paragonContent.expBar.text:SetText(string.format("%d / %d (%.1f%%)",
                pg.experience or 0, pg.expNeeded, percent))
        end
    end
    
    -- Update stats tab
    self:UpdateStatsTab()
    
    -- Update instances tab
    self:UpdateInstancesTab()
end

function PS_UI:UpdateStatsTab()
    if not mainFrame or not mainFrame.statsContent then
        return
    end
    
    local data = ProgressiveSystemsPerCharDB.charData
    local scrollChild = mainFrame.statsContent.scrollChild
    
    -- Clear existing stat displays
    for i = 1, scrollChild:GetNumChildren() do
        local child = select(i, scrollChild:GetChildren())
        if child then
            child:Hide()
        end
    end
    
    if data and data.customStats then
        local yOffset = -10
        local statNames = {
            "Intelligence", "Attack Speed", "Cast Speed", "Movement Speed",
            "Critical Strike", "Haste", "Mastery", "Versatility",
            "Lifesteal", "Multistrike", "Spell Power", "Attack Power",
            "Armor", "Resistance", "Health Regen", "Mana Regen"
        }
        
        for i, statName in ipairs(statNames) do
            local statValue = data.customStats[statName] or 0
            if statValue > 0 then
                local statFrame = CreateFrame("Frame", nil, scrollChild)
                statFrame:SetSize(400, 20)
                statFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
                
                local statText = statFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
                statText:SetPoint("LEFT", statFrame)
                statText:SetText(string.format("%s: |cff00ff00%d|r", statName, statValue))
                
                yOffset = yOffset - 25
            end
        end
    end
end

function PS_UI:ToggleMainWindow()
    if not mainFrame then
        self:CreateMainWindow()
    end
    
    if mainFrame:IsShown() then
        mainFrame:Hide()
    else
        mainFrame:Show()
        ProgressiveSystems:RequestAllData()
        self:UpdateAllWindows()
    end
end

function PS_UI:UpdateAllWindows()
    self:UpdateMainWindow()
    self:UpdateParagonWindow()
    self:UpdateStatsWindow()
    self:UpdateInstancesTab()
end

-- ============================================================
-- INSTANCES TAB
-- ============================================================
function PS_UI:UpdateInstancesTab()
    if not mainFrame or not mainFrame.instancesContent then
        return
    end
    
    local scrollChild = mainFrame.instancesContent.scrollChild
    local data = ProgressiveSystemsPerCharDB.charData
    
    -- Clear existing instance displays
    for i = 1, scrollChild:GetNumChildren() do
        local child = select(i, scrollChild:GetChildren())
        if child then
            child:Hide()
        end
    end
    
    -- Get instance data (would come from server)
    -- For now, show placeholder or use cached data
    local instances = data and data.instanceData or {}
    
    if #instances == 0 then
        local noDataText = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        noDataText:SetPoint("TOP", scrollChild, "TOP", 0, -10)
        noDataText:SetText("|cffaaaaaaNo instance data available.\nClick 'Open Instance Reset' for full interface.|r")
        return
    end
    
    -- Display instances
    local yOffset = -10
    for i, instance in ipairs(instances) do
        local entryFrame = CreateFrame("Frame", nil, scrollChild)
        entryFrame:SetSize(400, 50)
        entryFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
        
        -- Background
        local bg = entryFrame:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.1, 0.1, 0.1, 0.5)
        
        -- Instance name
        local nameText = entryFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        nameText:SetPoint("TOPLEFT", entryFrame, "TOPLEFT", 10, -5)
        nameText:SetText(instance.name or ("Map " .. (instance.mapId or 0)))
        
        -- Completion count
        local countText = entryFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        countText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -5)
        countText:SetText(string.format("Completions: |cff00ff00%d|r", instance.completionCount or 0))
        
        yOffset = yOffset - 55
    end
    
    -- Update scroll child height
    scrollChild:SetHeight(math.max(100, math.abs(yOffset) + 10))
end

-- ============================================================
-- PARAGON WINDOW (Standalone)
-- ============================================================
function PS_UI:CreateParagonWindow()
    paragonFrame = CreateFrame("Frame", "ProgressiveSystemsParagonWindow", UIParent, "BasicFrameTemplate")
    paragonFrame:SetSize(450, 550)
    paragonFrame:SetPoint("CENTER")
    paragonFrame:SetMovable(true)
    paragonFrame:EnableMouse(true)
    paragonFrame:RegisterForDrag("LeftButton")
    paragonFrame:SetScript("OnDragStart", paragonFrame.StartMoving)
    paragonFrame:SetScript("OnDragStop", paragonFrame.StopMovingOrSizing)
    
    paragonFrame.TitleText:SetText("Paragon System")
    paragonFrame.CloseButton:SetScript("OnClick", function() paragonFrame:Hide() end)
    
    -- Content (reuse from main window or create new)
    local content = CreateFrame("Frame", nil, paragonFrame)
    content:SetPoint("TOPLEFT", paragonFrame, "TOPLEFT", 16, -32)
    content:SetPoint("BOTTOMRIGHT", paragonFrame, "BOTTOMRIGHT", -16, 50)
    
    -- Level display
    local levelText = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    levelText:SetPoint("TOP", content, "TOP", 0, -10)
    levelText:SetText("Paragon Level: 0")
    paragonFrame.levelText = levelText
    
    -- Tier display
    local tierText = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    tierText:SetPoint("TOP", levelText, "BOTTOM", 0, -10)
    tierText:SetText("Paragon Tier: 0")
    paragonFrame.tierText = tierText
    
    -- Points display
    local pointsText = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    pointsText:SetPoint("TOP", tierText, "BOTTOM", 0, -10)
    pointsText:SetText("Available Points: 0")
    paragonFrame.pointsText = pointsText
    
    -- Experience bar
    local expBar = CreateFrame("StatusBar", nil, content)
    expBar:SetSize(400, 20)
    expBar:SetPoint("TOP", pointsText, "BOTTOM", 0, -15)
    expBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    expBar:SetStatusBarColor(0, 1, 0, 1)
    expBar:SetMinMaxValues(0, 100)
    expBar:SetValue(0)
    
    local expBarBg = expBar:CreateTexture(nil, "BACKGROUND")
    expBarBg:SetAllPoints(expBar)
    expBarBg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    expBarBg:SetVertexColor(0.3, 0.3, 0.3, 1)
    
    local expText = expBar:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    expText:SetPoint("CENTER", expBar)
    expText:SetText("0 / 0 (0%)")
    expBar.text = expText
    paragonFrame.expBar = expBar
    
    -- Info text
    local infoText = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    infoText:SetPoint("TOP", expBar, "BOTTOM", 0, -20)
    infoText:SetWidth(400)
    infoText:SetJustifyH("CENTER")
    infoText:SetText("Talk to Paragon Master NPC (Entry: 190020)\nto allocate your paragon points!")
    
    paragonFrame:Hide()
end

function PS_UI:UpdateParagonWindow()
    if not paragonFrame then
        return
    end
    
    local data = ProgressiveSystemsPerCharDB.charData
    if data and data.paragonData then
        local pg = data.paragonData
        paragonFrame.levelText:SetText(string.format("Paragon Level: %d", pg.level or 0))
        paragonFrame.tierText:SetText(string.format("Paragon Tier: %d", pg.tier or 0))
        paragonFrame.pointsText:SetText(string.format("Available Points: %d", pg.points or 0))
        
        if pg.expNeeded and pg.expNeeded > 0 then
            local percent = ((pg.experience or 0) / pg.expNeeded) * 100
            paragonFrame.expBar:SetMinMaxValues(0, pg.expNeeded)
            paragonFrame.expBar:SetValue(pg.experience or 0)
            paragonFrame.expBar.text:SetText(string.format("%d / %d (%.1f%%)",
                pg.experience or 0, pg.expNeeded, percent))
        end
    end
end

function PS_UI:ToggleParagonWindow()
    if not paragonFrame then
        self:CreateParagonWindow()
    end
    
    if paragonFrame:IsShown() then
        paragonFrame:Hide()
    else
        paragonFrame:Show()
        ProgressiveSystems:RequestParagonData()
        self:UpdateParagonWindow()
    end
end

-- ============================================================
-- STATS WINDOW (Standalone)
-- ============================================================
function PS_UI:CreateStatsWindow()
    statsFrame = CreateFrame("Frame", "ProgressiveSystemsStatsWindow", UIParent, "BasicFrameTemplate")
    statsFrame:SetSize(400, 500)
    statsFrame:SetPoint("CENTER")
    statsFrame:SetMovable(true)
    statsFrame:EnableMouse(true)
    statsFrame:RegisterForDrag("LeftButton")
    statsFrame:SetScript("OnDragStart", statsFrame.StartMoving)
    statsFrame:SetScript("OnDragStop", statsFrame.StopMovingOrSizing)
    
    statsFrame.TitleText:SetText("Custom Stats")
    statsFrame.CloseButton:SetScript("OnClick", function() statsFrame:Hide() end)
    
    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, statsFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", statsFrame, "TOPLEFT", 16, -32)
    scrollFrame:SetPoint("BOTTOMRIGHT", statsFrame, "BOTTOMRIGHT", -16, 50)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(350, 1000)
    scrollFrame:SetScrollChild(scrollChild)
    
    statsFrame.scrollFrame = scrollFrame
    statsFrame.scrollChild = scrollChild
    
    statsFrame:Hide()
end

function PS_UI:UpdateStatsWindow()
    if not statsFrame then
        return
    end
    
    local data = ProgressiveSystemsPerCharDB.charData
    local scrollChild = statsFrame.scrollChild
    
    -- Clear existing
    for i = 1, scrollChild:GetNumChildren() do
        local child = select(i, scrollChild:GetChildren())
        if child then
            child:Hide()
        end
    end
    
    if data and data.customStats then
        local yOffset = -10
        local statNames = {
            "Intelligence", "Attack Speed", "Cast Speed", "Movement Speed",
            "Critical Strike", "Haste", "Mastery", "Versatility",
            "Lifesteal", "Multistrike", "Spell Power", "Attack Power",
            "Armor", "Resistance", "Health Regen", "Mana Regen",
            "Experience", "Gold", "Loot"
        }
        
        for i, statName in ipairs(statNames) do
            local statValue = data.customStats[statName] or 0
            local statFrame = CreateFrame("Frame", nil, scrollChild)
            statFrame:SetSize(350, 20)
            statFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
            
            local statText = statFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
            statText:SetPoint("LEFT", statFrame)
            local color = statValue > 0 and "00ff00" or "ffffff"
            statText:SetText(string.format("|cff%s%s:|r %d", color, statName, statValue))
            
            yOffset = yOffset - 25
        end
    end
end

function PS_UI:ToggleStatsWindow()
    if not statsFrame then
        self:CreateStatsWindow()
    end
    
    if statsFrame:IsShown() then
        statsFrame:Hide()
    else
        statsFrame:Show()
        ProgressiveSystems:RequestCustomStatsData()
        self:UpdateStatsWindow()
    end
end

-- ============================================================
-- SETTINGS WINDOW
-- ============================================================
function PS_UI:CreateSettingsWindow()
    settingsFrame = CreateFrame("Frame", "ProgressiveSystemsSettingsWindow", UIParent, "BasicFrameTemplate")
    settingsFrame:SetSize(400, 300)
    settingsFrame:SetPoint("CENTER")
    settingsFrame:SetMovable(true)
    settingsFrame:EnableMouse(true)
    settingsFrame:RegisterForDrag("LeftButton")
    settingsFrame:SetScript("OnDragStart", settingsFrame.StartMoving)
    settingsFrame:SetScript("OnDragStop", settingsFrame.StopMovingOrSizing)
    
    settingsFrame.TitleText:SetText("Settings")
    settingsFrame.CloseButton:SetScript("OnClick", function() settingsFrame:Hide() end)
    
    -- Settings checkboxes
    local content = CreateFrame("Frame", nil, settingsFrame)
    content:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 16, -32)
    content:SetPoint("BOTTOMRIGHT", settingsFrame, "BOTTOMRIGHT", -16, 50)
    
    local showNotif = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    showNotif:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -10)
    showNotif.text = showNotif:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    showNotif.text:SetPoint("LEFT", showNotif, "RIGHT", 5, 0)
    showNotif.text:SetText("Show Notifications")
    showNotif:SetChecked(ProgressiveSystemsDB.globalData.settings.showNotifications)
    showNotif:SetScript("OnClick", function(self)
        ProgressiveSystemsDB.globalData.settings.showNotifications = self:GetChecked()
    end)
    
    local autoOpen = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    autoOpen:SetPoint("TOPLEFT", showNotif, "BOTTOMLEFT", 0, -10)
    autoOpen.text = autoOpen:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    autoOpen.text:SetPoint("LEFT", autoOpen, "RIGHT", 5, 0)
    autoOpen.text:SetText("Auto-open on Level Up")
    autoOpen:SetChecked(ProgressiveSystemsDB.globalData.settings.autoOpenOnLevel)
    autoOpen:SetScript("OnClick", function(self)
        ProgressiveSystemsDB.globalData.settings.autoOpenOnLevel = self:GetChecked()
    end)
    
    local showExpBar = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    showExpBar:SetPoint("TOPLEFT", autoOpen, "BOTTOMLEFT", 0, -10)
    showExpBar.text = showExpBar:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    showExpBar.text:SetPoint("LEFT", showExpBar, "RIGHT", 5, 0)
    showExpBar.text:SetText("Show Experience Bar")
    showExpBar:SetChecked(ProgressiveSystemsDB.globalData.settings.showExperienceBar)
    showExpBar:SetScript("OnClick", function(self)
        ProgressiveSystemsDB.globalData.settings.showExperienceBar = self:GetChecked()
    end)
    
    settingsFrame:Hide()
end

function PS_UI:ToggleSettingsWindow()
    if not settingsFrame then
        self:CreateSettingsWindow()
    end
    
    if settingsFrame:IsShown() then
        settingsFrame:Hide()
    else
        settingsFrame:Show()
    end
end

-- Create windows on load
hooksecurefunc("UIParent_OnLoad", function()
    PS_UI:CreateMainWindow()
    PS_UI:CreateParagonWindow()
    PS_UI:CreateStatsWindow()
    PS_UI:CreateSettingsWindow()
end)
