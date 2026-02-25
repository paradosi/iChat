local _, ns = ...

---------------------------------------------------------------------------
-- Titan Panel Integration (Native + LDB)
--
-- This module provides dual integration:
-- 1. Native Titan Panel plugin (proper layout, positioning)
-- 2. LibDataBroker object (compatibility with other LDB displays)
--
-- Behavior:
--   - iChat appears as a proper Titan Panel plugin with correct positioning
--   - Left-click: toggle iChat window
--   - Right-click: open iChat Settings
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
		version = "1.4.2",
		menuText = "iChat",
		menuContextFunction = GeneratorFunction,
		buttonTextFunction = GetButtonText,
		tooltipTitle = "|cff007AFFiChat|r",
		tooltipTextFunction = GetTooltipText,
		icon = "Interface\\AddOns\\iChat\\media\\textures\\icon",
		iconWidth = 16,
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

---------------------------------------------------------------------------
-- LibDataBroker Integration (for other LDB displays)
---------------------------------------------------------------------------

local LDB = LibStub and LibStub("LibDataBroker-1.1", true)
if LDB then
	local ldbObj = LDB:NewDataObject("iChat", {
		type  = "launcher",
		label = "iChat",
		icon  = "Interface\\AddOns\\iChat\\media\\textures\\icon",
		text  = "",
		
		OnClick = function(_, button)
			OnClick(_G[TITAN_BUTTON] or UIParent, button)
		end,
		
		OnTooltipShow = function(tooltip)
			tooltip:AddLine("|cff007AFFiChat|r")
			tooltip:AddLine("Left-click: Toggle window", 0.7, 0.7, 0.7)
			tooltip:AddLine("Right-click: Settings", 0.7, 0.7, 0.7)
			
			local total = GetUnreadCount()
			if total > 0 then
				local label = total == 1 and "1 unread message" or total .. " unread messages"
				tooltip:AddLine("|cffff9900" .. label .. "|r")
			end
		end,
	})
	
	-- Update LDB text when unread count changes
	function ns.UpdateLDBText(total)
		if not ldbObj then return end
		
		-- If total not provided, compute it
		if not total then
			total = GetUnreadCount()
		end
		
		ldbObj.text = total > 0 and (total > 99 and "99+" or tostring(total)) or ""
	end
	
	-- Initialize LDB text on load
	C_Timer.After(0, function()
		if ns.db then
			ns.UpdateLDBText()
		end
	end)
end
