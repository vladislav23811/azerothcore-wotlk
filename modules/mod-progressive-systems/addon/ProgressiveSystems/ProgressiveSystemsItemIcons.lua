-- ============================================================
-- Progressive Systems - Item Icon Enhancement Addon
-- ============================================================
-- This addon enhances custom currency items with better tooltips
-- and can optionally override item display information
-- ============================================================

local ProgressiveSystemsItemIcons = CreateFrame("Frame")
ProgressiveSystemsItemIcons:RegisterEvent("ADDON_LOADED")
ProgressiveSystemsItemIcons:RegisterEvent("PLAYER_LOGIN")

-- Custom item definitions with enhanced tooltips
local CUSTOM_ITEMS = {
    [99997] = {
        name = "Progression Token",
        icon = "Interface\\Icons\\INV_Misc_Coin_01",  -- Gold coin icon
        description = "Currency used in the Progressive Systems reward shop.",
        quality = 4,  -- Epic (purple)
    },
    [99998] = {
        name = "Celestial Token",
        icon = "Interface\\Icons\\INV_Misc_Coin_02",  -- Silver coin icon
        description = "Rare celestial currency for purchasing premium rewards.",
        quality = 4,  -- Epic (purple)
    },
    [99999] = {
        name = "Bloody Token",
        icon = "Interface\\Icons\\INV_Misc_Coin_03",  -- Bronze coin icon
        description = "Blood-soaked currency earned from the Bloody Palace challenges.",
        quality = 4,  -- Epic (purple)
    },
}

-- Hook into tooltip to enhance custom items
local function OnTooltipSetItem(tooltip)
    local name, link = tooltip:GetItem()
    if not link then return end
    
    local itemId = tonumber(string.match(link, "item:(%d+)"))
    if not itemId or not CUSTOM_ITEMS[itemId] then return end
    
    local itemData = CUSTOM_ITEMS[itemId]
    
    -- Enhance tooltip with custom information
    tooltip:AddLine(" ")
    tooltip:AddLine("|cFF00FFFFProgressive Systems Currency|r", 1, 1, 1)
    if itemData.description then
        tooltip:AddLine(itemData.description, 1, 0.82, 0, true)
    end
end

-- Hook GameTooltip and ItemRefTooltip
GameTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
ItemRefTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)

-- Function to get item icon path (for use in other addons)
function ProgressiveSystemsItemIcons:GetItemIcon(itemId)
    if CUSTOM_ITEMS[itemId] and CUSTOM_ITEMS[itemId].icon then
        return CUSTOM_ITEMS[itemId].icon
    end
    return nil
end

-- Function to get item data
function ProgressiveSystemsItemIcons:GetItemData(itemId)
    return CUSTOM_ITEMS[itemId]
end

-- Export functions globally
ProgressiveSystemsItemIcons_GetItemIcon = function(itemId) 
    return ProgressiveSystemsItemIcons:GetItemIcon(itemId) 
end

ProgressiveSystemsItemIcons_GetItemData = function(itemId) 
    return ProgressiveSystemsItemIcons:GetItemData(itemId) 
end

print("|cFF00FFFFProgressive Systems|r: Item icon enhancement loaded!")

