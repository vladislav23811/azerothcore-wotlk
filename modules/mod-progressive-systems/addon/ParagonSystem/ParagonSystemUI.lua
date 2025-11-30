-- ParagonSystemUI.lua
-- UI elements for Paragon System

local PS_UI = {}
ParagonSystem.UI = PS_UI

local mainFrame
local statsFrame

function PS_UI:CreateMainWindow()
    mainFrame = CreateFrame("Frame", "ParagonSystemMainWindow", UIParent, "BasicFrameTemplate")
    mainFrame:SetSize(500, 600)
    mainFrame:SetPoint("CENTER")
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
    mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing)
    
    mainFrame.TitleText:SetText("Paragon System")
    
    -- Close button
    mainFrame.CloseButton:SetScript("OnClick", function() mainFrame:Hide() end)
    
    -- Content area
    local content = CreateFrame("Frame", nil, mainFrame)
    content:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 16, -32)
    content:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -16, 50)
    
    -- Paragon level display
    local levelText = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    levelText:SetPoint("TOP", content, "TOP", 0, -10)
    levelText:SetText("Paragon Level: 0")
    mainFrame.levelText = levelText
    
    -- Experience bar
    local expBar = CreateFrame("StatusBar", nil, content)
    expBar:SetSize(450, 20)
    expBar:SetPoint("TOP", levelText, "BOTTOM", 0, -10)
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
    mainFrame.expBar = expBar
    mainFrame.expText = expText
    
    -- Available points
    local pointsText = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    pointsText:SetPoint("TOP", expBar, "BOTTOM", 0, -15)
    pointsText:SetText("Available Points: 0")
    mainFrame.pointsText = pointsText
    
    -- Tier display
    local tierText = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    tierText:SetPoint("TOP", pointsText, "BOTTOM", 0, -10)
    tierText:SetText("Paragon Tier: 0")
    mainFrame.tierText = tierText
    
    -- Buttons
    local allocateBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    allocateBtn:SetSize(150, 30)
    allocateBtn:SetPoint("TOP", tierText, "BOTTOM", 0, -20)
    allocateBtn:SetText("Allocate Points")
    allocateBtn:SetScript("OnClick", function()
        ParagonSystem:Print("Talk to Paragon Master NPC to allocate points!")
    end)
    
    local statsBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    statsBtn:SetSize(150, 30)
    statsBtn:SetPoint("TOP", allocateBtn, "BOTTOM", 10, -10)
    statsBtn:SetText("View Stats")
    statsBtn:SetScript("OnClick", function()
        self:ShowStatsWindow()
    end)
    
    mainFrame:Hide()
end

function PS_UI:UpdateMainWindow(data)
    if not mainFrame then
        self:CreateMainWindow()
    end
    
    if data then
        mainFrame.levelText:SetText(string.format("Paragon Level: %d", data.level or 0))
        mainFrame.pointsText:SetText(string.format("Available Points: %d", data.points or 0))
        mainFrame.tierText:SetText(string.format("Paragon Tier: %d", data.tier or 0))
        
        if data.expNeeded and data.expNeeded > 0 then
            local percent = (data.experience or 0) / data.expNeeded * 100
            mainFrame.expBar:SetMinMaxValues(0, data.expNeeded)
            mainFrame.expBar:SetValue(data.experience or 0)
            mainFrame.expText:SetText(string.format("%d / %d (%.1f%%)", 
                data.experience or 0, data.expNeeded, percent))
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
        ParagonSystem:RequestParagonData()
    end
end

function PS_UI:ShowStatsWindow()
    -- Create stats window (simplified)
    if not statsFrame then
        statsFrame = CreateFrame("Frame", "ParagonSystemStatsWindow", UIParent, "BasicFrameTemplate")
        statsFrame:SetSize(400, 500)
        statsFrame:SetPoint("CENTER")
        statsFrame:SetMovable(true)
        statsFrame:EnableMouse(true)
        statsFrame:RegisterForDrag("LeftButton")
        statsFrame:SetScript("OnDragStart", statsFrame.StartMoving)
        statsFrame:SetScript("OnDragStop", statsFrame.StopMovingOrSizing)
        
        statsFrame.TitleText:SetText("Paragon Stats")
        statsFrame.CloseButton:SetScript("OnClick", function() statsFrame:Hide() end)
        
        local scrollFrame = CreateFrame("ScrollFrame", nil, statsFrame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", statsFrame, "TOPLEFT", 16, -32)
        scrollFrame:SetPoint("BOTTOMRIGHT", statsFrame, "BOTTOMRIGHT", -16, 50)
        
        local content = CreateFrame("Frame", nil, scrollFrame)
        content:SetSize(350, 1000)
        scrollFrame:SetScrollChild(content)
        
        statsFrame.scrollFrame = scrollFrame
        statsFrame.content = content
    end
    
    -- Update stats display
    local data = ParagonSystemPerCharDB.charData
    if data and data.stats then
        -- Display stats here
    end
    
    statsFrame:Show()
end

-- Create main window on load
hooksecurefunc("UIParent_OnLoad", function()
    PS_UI:CreateMainWindow()
end)

