local _, ns = ...

---------------------------------------------------------------------------
-- LDB (LibDataBroker) Integration
--
-- Registers an LDB launcher data object so that any LDB display addon
-- (Titan Panel, ChocolateBar, Bazooka, FuBar, etc.) can auto-discover iChat.
--
-- Returns early if LibStub or LibDataBroker-1.1 are not loaded, so there
-- is no behavior change when no LDB display addon is present.
--
-- Behavior:
--   - iChat appears in any LDB display's plugin list
--   - Left-click: toggle iChat window
--   - Right-click: open Settings
--   - Bar text: unread count ("3", "99+") or blank
--   - Tooltip: unread count + click hints
--
-- NOTE: The custom floating button in minimap.lua is fully independent
-- of this integration. Both can coexist; users may hide the floating
-- button via Settings if they prefer the LDB icon exclusively.
---------------------------------------------------------------------------

-- Bail out if LibStub is not available
if not LibStub then return end

local LDB = LibStub:GetLibrary("LibDataBroker-1.1", true)
if not LDB then return end

---------------------------------------------------------------------------
-- LDB Object
---------------------------------------------------------------------------

local dataobj = LDB:NewDataObject("iChat", {
	type  = "launcher",
	label = "iChat",
	icon  = "Interface\\AddOns\\iChat\\media\\textures\\icon",
	text  = "",

	OnClick = function(_, button)
		if button == "RightButton" then
			if ns.mainWindow and not ns.mainWindow:IsShown() then
				if ns.ToggleWindow then ns.ToggleWindow() end
			end
			if ns.ToggleSettings then ns.ToggleSettings() end
		else
			if ns.StopFlashButton then ns.StopFlashButton() end
			if ns.ToggleWindow then ns.ToggleWindow() end
		end
	end,

	OnTooltipShow = function(tooltip)
		tooltip:AddLine("|cff007AFFiChat|r")
		local total = 0
		if ns.db and ns.db.conversations then
			for _, convo in pairs(ns.db.conversations) do
				total = total + (convo.unread or 0)
			end
		end
		if total > 0 then
			local label = total == 1 and "1 unread message" or total .. " unread messages"
			tooltip:AddLine(label, 0.2, 1.0, 0.2)
		else
			tooltip:AddLine("No unread messages", 1, 1, 1)
		end
		tooltip:AddLine(" ")
		tooltip:AddLine("Left-click: Toggle window", 1, 1, 1)
		tooltip:AddLine("Right-click: Open Settings", 1, 1, 1)
	end,
})

---------------------------------------------------------------------------
-- Public API — update LDB text when unread count changes
---------------------------------------------------------------------------

-- Called from minimap.lua when unread count changes
function ns.UpdateLDBText()
	if not dataobj then return end
	local total = 0
	if ns.db and ns.db.conversations then
		for _, convo in pairs(ns.db.conversations) do
			total = total + (convo.unread or 0)
		end
	end
	dataobj.text = total > 0 and (total > 99 and "99+" or tostring(total)) or ""
end
