-- InstanceResetUI.lua
-- Client-side UI for instance reset information

local IRS_UI = {}
ProgressiveSystems.InstanceReset = IRS_UI

local frame
local instanceListFrame

-- Map names (client-side)
local MAP_NAMES = {
    [533] = "Naxxramas",
    [631] = "Icecrown Citadel",
    [603] = "Ulduar",
    [649] = "Trial of the Crusader",
    [724] = "The Ruby Sanctum",
    [574] = "Utgarde Keep",
    [575] = "Utgarde Pinnacle",
    [576] = "The Nexus",
    [578] = "The Oculus",
}

function IRS_UI:CreateMainWindow()
    frame = CreateFrame("Frame", "InstanceResetMainWindow", UIParent, "BasicFrameTemplate")
    frame:SetSize(500, 600)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    
    frame.TitleText:SetText("Instance Reset System")
    
    -- Close button
    frame.CloseButton:SetScript("OnClick", function() frame:Hide() end)
    
    -- Scroll frame for instance list
    local scrollFrame = CreateFrame("ScrollFrame", "InstanceResetScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -32)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -32, 50)
    
    local scrollChild = CreateFrame("Frame", "InstanceResetScrollChild", scrollFrame)
    scrollChild:SetWidth(scrollFrame:GetWidth() - 20)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)
    
    frame.scrollFrame = scrollFrame
    frame.scrollChild = scrollChild
    
    -- Reset All button
    local resetAllButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    resetAllButton:SetSize(120, 25)
    resetAllButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 16, 16)
    resetAllButton:SetText("Reset All")
    resetAllButton:SetScript("OnClick", function()
        ProgressiveSystems:RequestInstanceReset("all")
    end)
    frame.resetAllButton = resetAllButton
    
    -- Refresh button
    local refreshButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    refreshButton:SetSize(100, 25)
    refreshButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, 16)
    refreshButton:SetText("Refresh")
    refreshButton:SetScript("OnClick", function()
        ProgressiveSystems:RequestInstanceData()
    end)
    frame.refreshButton = refreshButton
    
    frame:Hide()
end

function IRS_UI:UpdateInstanceList(instances)
    if not frame then
        self:CreateMainWindow()
    end
    
    local scrollChild = frame.scrollChild
    local yOffset = -10
    
    -- Clear existing buttons
    for i = 1, scrollChild:GetNumChildren() do
        local child = select(i, scrollChild:GetChildren())
        if child then
            child:Hide()
        end
    end
    
    -- Create instance entries
    for i, instance in ipairs(instances) do
        local entryFrame = CreateFrame("Frame", "InstanceEntry" .. i, scrollChild)
        entryFrame:SetSize(scrollChild:GetWidth() - 20, 60)
        entryFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
        
        -- Background
        local bg = entryFrame:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.1, 0.1, 0.1, 0.5)
        
        -- Instance name
        local nameText = entryFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        nameText:SetPoint("TOPLEFT", entryFrame, "TOPLEFT", 10, -5)
        nameText:SetText(MAP_NAMES[instance.mapId] or ("Map " .. instance.mapId))
        
        -- Completion count
        local countText = entryFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        countText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -5)
        countText:SetText("Completions: " .. (instance.completionCount or 0))
        
        -- Reset button
        local resetButton = CreateFrame("Button", nil, entryFrame, "UIPanelButtonTemplate")
        resetButton:SetSize(80, 25)
        resetButton:SetPoint("TOPRIGHT", entryFrame, "TOPRIGHT", -10, -15)
        resetButton:SetText("Reset")
        resetButton:SetScript("OnClick", function()
            ProgressiveSystems:RequestInstanceReset(instance.mapId)
        end)
        
        yOffset = yOffset - 65
    end
    
    -- Update scroll child height
    scrollChild:SetHeight(math.max(1, math.abs(yOffset) + 10))
end

function IRS_UI:ToggleMainWindow()
    if not frame then
        self:CreateMainWindow()
    end
    
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
        ProgressiveSystems:RequestInstanceData()
    end
end

-- Add to main ProgressiveSystems
function ProgressiveSystems:RequestInstanceData()
    -- Request instance data from server via addon message
    -- This would need server-side support
    self:Print("Requesting instance data from server...")
end

function ProgressiveSystems:RequestInstanceReset(mapId)
    -- Request instance reset from server via addon message
    -- This would need server-side support
    if mapId == "all" then
        self:Print("Requesting reset of all instances...")
    else
        self:Print("Requesting reset of instance " .. mapId .. "...")
    end
end

-- Hook into main addon
hooksecurefunc(ProgressiveSystems, "OnInitialize", function()
    ProgressiveSystems:Print("Instance Reset UI loaded. Use /ps reset to open.")
end)

