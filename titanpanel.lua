local _, ns = ...

---------------------------------------------------------------------------
-- Titan Panel Integration via LibDataBroker-1.1
--
-- Titan Panel (and other LDB display addons: FuBar, ChocolateBar,
-- Bazooka, etc.) auto-discover addons by scanning LibDataBroker data
-- objects. This module registers iChat as an LDB "launcher" so it
-- appears in Titan Panel's right-click plugin menu and can be placed
-- on the info bar.
--
-- Behavior when Titan Panel is installed:
--   - iChat appears as a clickable icon in the Titan Panel bar
--   - Left-click  : toggle the iChat window (same as floating button)
--   - Right-click : open iChat Settings panel
--   - Bar text    : shows unread count (e.g. "3") or blank when none
--   - Tooltip     : unread count + click hints
--
-- Behavior when Titan Panel is NOT installed:
--   - The LDB object is still registered (other display addons may use
--     it), but there is no visible effect without a display addon.
--
-- Prerequisites:
--   LibDataBroker-1.1 and LibStub must be loaded. Both ship with Titan
--   Panel. If they are absent this module returns early without error.
--
-- NOTE: The custom floating button in minimap.lua is fully independent
-- of this integration. Both can coexist; users may hide the floating
-- button via Settings if they prefer the Titan Panel icon exclusively.
---------------------------------------------------------------------------

local LDB = LibStub and LibStub("LibDataBroker-1.1", true)
if not LDB then return end

---------------------------------------------------------------------------
-- LDB Data Object
---------------------------------------------------------------------------
local ldbObj = LDB:NewDataObject("iChat", {
    type  = "launcher",
    label = "iChat",
    icon  = "Interface\\AddOns\\iChat\\media\\textures\\icon",
    text  = "",

    -- Left-click: toggle window; Right-click: open settings
    OnClick = function(_, button)
        if button == "RightButton" then
            -- Ensure the main window is visible before toggling settings
            -- (settings panel anchors to the main window)
            if ns.mainWindow and not ns.mainWindow:IsShown() then
                ns.ToggleWindow()
            end
            ns.ToggleSettings()
        else
            ns.StopFlashButton()
            ns.ToggleWindow()
        end
    end,

    -- Tooltip: name, hints, unread count
    OnTooltipShow = function(tooltip)
        tooltip:AddLine("|cff007AFFiChat|r")
        tooltip:AddLine("Left-click: Toggle window", 0.7, 0.7, 0.7)
        tooltip:AddLine("Right-click: Settings", 0.7, 0.7, 0.7)

        local total = 0
        if ns.db and ns.db.conversations then
            for _, convo in pairs(ns.db.conversations) do
                total = total + (convo.unread or 0)
            end
        end

        if total > 0 then
            local label = total == 1 and "1 unread message" or total .. " unread messages"
            tooltip:AddLine("|cffff9900" .. label .. "|r")
        end
    end,
})

---------------------------------------------------------------------------
-- ns.UpdateLDBText()
-- Refreshes the LDB bar text with the current total unread count.
-- Called from ns.UpdateButtonBadge() in minimap.lua so both the
-- floating button badge and the Titan Panel text stay in sync.
---------------------------------------------------------------------------
function ns.UpdateLDBText()
    if not ldbObj then return end
    local total = 0
    if ns.db and ns.db.conversations then
        for _, convo in pairs(ns.db.conversations) do
            total = total + (convo.unread or 0)
        end
    end
    ldbObj.text = total > 0 and (total > 99 and "99+" or tostring(total)) or ""
end
