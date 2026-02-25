local _, ns = ...

---------------------------------------------------------------------------
-- Titan Panel Integration (Native)
--
-- This module provides native Titan Panel plugin integration with proper
-- layout, positioning, and right-click menu support.
--
-- NOTE: This is a NATIVE Titan plugin, not LibDataBroker (LDB).
-- TitanPanelComboTemplate is used for direct integration.
--
-- Behavior:
--   - iChat appears as a proper Titan Panel plugin with correct positioning
--   - Left-click: toggle iChat window
--   - Right-click: shows Titan Panel menu with custom iChat options
--   - Bar text: shows unread count (e.g. "3", "99+") or blank
--   - Tooltip: unread count + click hints
--
-- NOTE: The custom floating button in minimap.lua is fully independent
-- of this integration. Both can coexist; users may hide the floating
-- button via Settings if they prefer the Titan Panel icon exclusively.
---------------------------------------------------------------------------

-- Constants
local TITAN_ICHAT_ID = "iChat"
local TITAN_BUTTON = "TitanPanel" .. TITAN_ICHAT_ID .. "Button"

---------------------------------------------------------------------------
-- Helper Functions
---------------------------------------------------------------------------

local function GetUnreadCount()
	local total = 0
	if ns.db and ns.db.conversations then
		for _, convo in pairs(ns.db.conversations) do
			total = total + (convo.unread or 0)
		end
	end
	return total
end

local function GetButtonText()
	local total = GetUnreadCount()
	if total == 0 then
		return "", "" -- empty label and text when no unreads
	end
	
	local label = TitanGetVar(TITAN_ICHAT_ID, "ShowLabelText") and "iChat: " or ""
	local text = total > 99 and "99+" or tostring(total)
	
	-- Apply coloring if enabled
	if TitanGetVar(TITAN_ICHAT_ID, "ShowColoredText") then
		text = TitanUtils_GetGreenText(text)
	else
		text = TitanUtils_GetHighlightText(text)
	end
	
	return label, text
end

local function GetTooltipText()
	local total = GetUnreadCount()
	local lines = {}
	
	if total > 0 then
		local label = total == 1 and "1 unread message" or total .. " unread messages"
		table.insert(lines, TitanUtils_GetGreenText(label))
	else
		table.insert(lines, TitanUtils_GetNormalText("No unread messages"))
	end
	
	table.insert(lines, " ")
	table.insert(lines, TitanUtils_GetNormalText("Left-click: Toggle window"))
	table.insert(lines, TitanUtils_GetNormalText("Right-click: Menu"))
	
	return table.concat(lines, "\n")
end

---------------------------------------------------------------------------
-- Menu Generator (Right-Click Menu)
---------------------------------------------------------------------------

local function GeneratorFunction(owner, rootDescription)
	local root = rootDescription
	
	-- Add custom iChat commands at the top
	root:CreateButton("Toggle iChat Window", function()
		ns.StopFlashButton()
		ns.ToggleWindow()
	end)
	
	root:CreateButton("Settings...", function()
		-- Ensure the main window is visible before toggling settings
		if ns.mainWindow and not ns.mainWindow:IsShown() then
			ns.ToggleWindow()
		end
		ns.ToggleSettings()
	end)
	
	root:CreateDivider()
	
	-- Titan Panel adds standard options automatically after this:
	-- - Show Icon
	-- - Show Label Text
	-- - Show Colored Text
	-- - Display on Right Side
	-- - Hide
end

---------------------------------------------------------------------------
-- Event Handlers
---------------------------------------------------------------------------

local function OnLoad(self)
	self.registry = {
		id = TITAN_ICHAT_ID,
		category = "Interface",
		version = ns.version,
		menuText = "iChat",
		menuContextFunction = GeneratorFunction,
		buttonTextFunction = GetButtonText,
		tooltipTitle = "|cff007AFFiChat|r",
		tooltipTextFunction = GetTooltipText,
		icon = "Interface\\AddOns\\iChat\\media\\textures\\icon",
		iconWidth = 16,
		iconButtonWidth = 24,  -- Add padding around icon (16px icon + 4px each side)
		notes = "iMessage-style whisper client for WoW",
		controlVariables = {
			ShowIcon = true,
			ShowLabelText = true,
			ShowColoredText = true,
			DisplayOnRightSide = true,
		},
		savedVariables = {
			ShowIcon = true,
			ShowLabelText = false,
			ShowColoredText = false,
			DisplayOnRightSide = false,
		}
	}
	
	-- Register for unread updates from iChat
	-- (minimap.lua will call ns.UpdateTitanButton when unreads change)
end

local function OnShow(self)
	-- Initial update
	TitanPanelButton_UpdateButton(TITAN_ICHAT_ID)
end

local function OnClick(self, button)
	-- Left-click: toggle window
	-- Right-click: handled by Titan Panel (shows menu via menuContextFunction)
	if button == "LeftButton" then
		ns.StopFlashButton()
		ns.ToggleWindow()
	end
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

-- Called from minimap.lua when unread count changes
function ns.UpdateTitanButton()
	if _G[TITAN_BUTTON] then
		TitanPanelButton_UpdateButton(TITAN_ICHAT_ID)
	end
end

---------------------------------------------------------------------------
-- Create Frame
---------------------------------------------------------------------------

local function CreateFrames()
	if _G[TITAN_BUTTON] then
		return -- already created
	end
	
	-- Guard: check if Titan Panel is loaded
	if not _G.TitanPanelComboTemplate then
		return
	end
	
	-- Create Titan Panel button using the combo template (icon + text)
	local frame = CreateFrame("Button", TITAN_BUTTON, UIParent, "TitanPanelComboTemplate")
	frame:SetFrameStrata("FULLSCREEN")
	
	-- Initialize the plugin
	OnLoad(frame)
	
	-- Set up event handlers
	frame:SetScript("OnShow", function(self)
		OnShow(self)
		TitanPanelButton_OnShow(self)
	end)
	
	frame:SetScript("OnClick", function(self, button)
		OnClick(self, button)
		TitanPanelButton_OnClick(self, button)
	end)
end

-- Create the frame when this file loads
CreateFrames()
