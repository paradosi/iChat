local _, ns = ...

---------------------------------------------------------------------------
-- Portraits — Class-colored names in conversation header
--
-- Uses friend list, guild roster, and unit scanning to find player info.
-- Colors player names by class in the header frame.
--
-- Public API:
--   ns.CreatePortraitFrame(parent)   → call once from CreateRightPanel (no-op)
--   ns.UpdatePortrait()              → call on conversation switch / toggle
---------------------------------------------------------------------------

-- No-op for compatibility (used to create race icon, now unused)
function ns.CreatePortraitFrame(parent)
	-- No icon needed anymore, just keeping this for compatibility
end

-- Apply class color to the name in the conversation header.
function ns.UpdatePortrait()
	if not ns.headerName then return end

	-- Always position name at left (no icon to offset for)
	ns.headerName:ClearAllPoints()
	ns.headerName:SetPoint("LEFT", 10, 2)

	-- Check if class colors are enabled
	local enabled = ns.db and ns.db.settings and ns.db.settings.showPortrait
	local playerInfo = enabled and ns.activeConversation and ns.GetPlayerInfo(ns.activeConversation)

	-- Apply class color if available and enabled
	if playerInfo and playerInfo.classFile then
		local classColor = RAID_CLASS_COLORS[playerInfo.classFile]
		if classColor then
			ns.headerName:SetTextColor(classColor.r, classColor.g, classColor.b)
		else
			ns.headerName:SetTextColor(1, 1, 1)
		end
	else
		-- No player info or disabled, use white text
		ns.headerName:SetTextColor(1, 1, 1)
	end
end
