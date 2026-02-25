local _, ns = ...

---------------------------------------------------------------------------
-- Portraits — Race icon in the conversation header
--
-- Uses friend list, guild roster, and unit scanning to find player info.
-- Displays their race icon in the header frame and colors their name by class.
--
-- Public API:
--   ns.CreatePortraitFrame(parent)   → call once from CreateRightPanel
--   ns.UpdatePortrait()              → call on conversation switch / toggle
---------------------------------------------------------------------------

-- Race icon texture coordinates (from Interface\Glues\CharacterCreate\UI-CharacterCreate-Races)
-- Format: { left, right, top, bottom }
local RACE_ICON_TCOORDS = {
	-- Alliance
	["Human"]    = { 0, 0.25, 0, 0.25 },
	["Dwarf"]    = { 0.25, 0.5, 0, 0.25 },
	["NightElf"] = { 0.5, 0.75, 0, 0.25 },
	["Gnome"]    = { 0.75, 1.0, 0, 0.25 },
	
	-- Horde
	["Orc"]      = { 0, 0.25, 0.25, 0.5 },
	["Scourge"]  = { 0.25, 0.5, 0.25, 0.5 }, -- Undead
	["Tauren"]   = { 0.5, 0.75, 0.25, 0.5 },
	["Troll"]    = { 0.75, 1.0, 0.25, 0.5 },
	
	-- TBC
	["Draenei"]  = { 0, 0.25, 0.5, 0.75 },
	["BloodElf"] = { 0.25, 0.5, 0.5, 0.75 },
	
	-- Newer (if present)
	["Worgen"]   = { 0.5, 0.75, 0.5, 0.75 },
	["Goblin"]   = { 0.75, 1.0, 0.5, 0.75 },
	["Pandaren"] = { 0, 0.25, 0.75, 1.0 },
}

-- Width of the race icon (square)
local ICON_SIZE = 28

-- Create the race icon frame and attach it to `parent` (the header frame).
-- Stores the frame as ns.headerPortrait. Call once during UI construction.
function ns.CreatePortraitFrame(parent)
	local icon = CreateFrame("Frame", nil, parent)
	icon:SetSize(ICON_SIZE, ICON_SIZE)
	icon:SetPoint("LEFT", 6, 0)
	icon:Hide()

	local tex = icon:CreateTexture(nil, "ARTWORK")
	tex:SetAllPoints(icon)
	tex:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Races")
	icon.texture = tex

	ns.headerPortrait = icon
end

-- Refresh the race icon and name color for the current conversation.
-- Shows the race icon when player info is available; repositions headerName
-- to sit right of the icon (or back to the left edge when hidden).
-- Also applies class color to the player name.
function ns.UpdatePortrait()
	if not ns.headerPortrait or not ns.headerName then return end

	local enabled = ns.db and ns.db.settings and ns.db.settings.showPortrait
	local playerInfo = enabled and ns.activeConversation and ns.GetPlayerInfo(ns.activeConversation)

	if playerInfo and playerInfo.raceFile then
		local coords = RACE_ICON_TCOORDS[playerInfo.raceFile]
		
		if coords then
			ns.headerPortrait.texture:SetTexCoord(unpack(coords))
			ns.headerPortrait:Show()
			ns.headerName:ClearAllPoints()
			ns.headerName:SetPoint("LEFT", ns.headerPortrait, "RIGHT", 8, 2)
			
			-- Apply class color to name
			if playerInfo.classFile then
				local classColor = RAID_CLASS_COLORS[playerInfo.classFile]
				if classColor then
					ns.headerName:SetTextColor(classColor.r, classColor.g, classColor.b)
				else
					ns.headerName:SetTextColor(1, 1, 1)
				end
			else
				ns.headerName:SetTextColor(1, 1, 1)
			end
		else
			-- Unknown race, hide icon and use white text (or class color if available)
			ns.headerPortrait:Hide()
			ns.headerName:ClearAllPoints()
			ns.headerName:SetPoint("LEFT", 10, 2)
			
			if playerInfo.classFile then
				local classColor = RAID_CLASS_COLORS[playerInfo.classFile]
				if classColor then
					ns.headerName:SetTextColor(classColor.r, classColor.g, classColor.b)
				else
					ns.headerName:SetTextColor(1, 1, 1)
				end
			else
				ns.headerName:SetTextColor(1, 1, 1)
			end
		end
	else
		-- Player info not found, hide icon and use white text
		ns.headerPortrait:Hide()
		ns.headerName:ClearAllPoints()
		ns.headerName:SetPoint("LEFT", 10, 2)
		ns.headerName:SetTextColor(1, 1, 1)
	end
end
