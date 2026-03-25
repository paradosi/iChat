local _, ns = ...

---------------------------------------------------------------------------
-- ElvUI DataText Integration
--
-- Registers a custom DataText "iChat" that can be placed on any ElvUI
-- info panel (minimap, chat, custom bars). Shows unread count with
-- ElvUI's value color, tooltip with details, click to toggle.
--
-- Behavior:
--   - Text: "iChat: 3" when unreads, "iChat" when caught up
--   - Left-click: toggle iChat window
--   - Right-click: toggle settings
--   - Tooltip: unread count + click hints
---------------------------------------------------------------------------

-- Guard: only load if ElvUI is available
local E = _G.ElvUI and _G.ElvUI[1]
if not E then return end

local DT = E:GetModule("DataTexts", true)
if not DT then return end

-- Guard: RegisterDataText/RegisterDatatext not available (e.g. TBC Classic ElvUI)
local registerFn = DT.RegisterDataText or DT.RegisterDatatext
if not registerFn then return end

local displayString = ""

local function GetUnreadCount()
    local total = 0
    if ns.db and ns.db.conversations then
        for _, convo in pairs(ns.db.conversations) do
            total = total + (convo.unread or 0)
        end
    end
    return total
end

local function OnEvent(self)
    local total = GetUnreadCount()
    if total > 0 then
        local countText = total > 99 and "99+" or tostring(total)
        self.text:SetFormattedText(displayString, "iChat: ", countText)
    else
        self.text:SetText("iChat")
    end
end

local function OnClick(self, button)
    if button == "RightButton" then
        if ns.mainWindow and not ns.mainWindow:IsShown() then
            ns.ToggleWindow()
        end
        ns.ToggleSettings()
    else
        if ns.StopFlashButton then ns.StopFlashButton() end
        ns.ToggleWindow()
    end
end

local function OnEnter(self)
    DT.tooltip:ClearLines()
    DT.tooltip:AddLine("|cff007AFFiChat|r")
    DT.tooltip:AddLine(" ")

    local total = GetUnreadCount()
    if total > 0 then
        local label = total == 1 and "1 unread message" or total .. " unread messages"
        DT.tooltip:AddLine(label, 0.2, 1.0, 0.2)
    else
        DT.tooltip:AddLine("No unread messages", 0.7, 0.7, 0.7)
    end

    DT.tooltip:AddLine(" ")
    DT.tooltip:AddLine("Left-click: Toggle window", 0.7, 0.7, 0.7)
    DT.tooltip:AddLine("Right-click: Settings", 0.7, 0.7, 0.7)
    DT.tooltip:Show()
end

local function ValueColorUpdate(self, hex)
    displayString = "%s" .. hex .. "%s|r"
    OnEvent(self)
end

registerFn(DT, "iChat", nil, { "CHAT_MSG_WHISPER", "CHAT_MSG_BN_WHISPER" }, OnEvent, nil, OnClick, OnEnter, nil, "iChat Whispers", nil, ValueColorUpdate)

---------------------------------------------------------------------------
-- Public API — called from minimap.lua when unread count changes
---------------------------------------------------------------------------
function ns.UpdateElvUIDataText()
    local reg = DT.RegisteredDataTexts or DT.RegisteredDatatexts
    if not DT or not reg or not reg["iChat"] then return end
    -- Force update all panels that have this DataText active
    local panels = DT.RegisteredPanels
    if not panels then return end
    for _, panel in pairs(panels) do
        for i = 1, panel.numPoints or 0 do
            local dt = panel.dataPanels and panel.dataPanels[i]
            if dt and dt.name == "iChat" then
                OnEvent(dt)
            end
        end
    end
end
