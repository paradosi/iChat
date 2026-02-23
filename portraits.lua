local _, ns = ...

---------------------------------------------------------------------------
-- Portraits — 3D PlayerModel portrait in the conversation header
--
-- Scans visible unit IDs (player, target, focus, party, raid) to find
-- a unit matching the active conversation partner. When found, renders
-- their 3D character model in the header frame next to their name.
--
-- Public API:
--   ns.CreatePortraitFrame(parent)   → call once from CreateRightPanel
--   ns.UpdatePortrait()              → call on conversation switch / toggle
---------------------------------------------------------------------------

-- Scan all accessible unit IDs for one whose name matches `name`.
-- Strips -Realm suffix before comparing.
local function FindUnitByName(name)
    if not name then return nil end
    local bare = name:match("^([^%-]+)") or name

    local function matches(unit)
        local n = UnitName(unit)
        return n == bare or n == name
    end

    -- Self first (self-whisper)
    if UnitExists("player") and matches("player") then return "player" end
    -- Target / focus
    if UnitExists("target") and matches("target") then return "target" end
    if UnitExists("focus")  and matches("focus")  then return "focus"  end
    -- Party (up to 4)
    for i = 1, 4 do
        local u = "party" .. i
        if UnitExists(u) and matches(u) then return u end
    end
    -- Raid (up to 40)
    for i = 1, 40 do
        local u = "raid" .. i
        if UnitExists(u) and matches(u) then return u end
    end
    return nil
end

-- Create the PlayerModel frame and attach it to `parent` (the header frame).
-- Stores the frame as ns.headerPortrait. Call once during UI construction.
function ns.CreatePortraitFrame(parent)
    local portrait = CreateFrame("PlayerModel", nil, parent)
    portrait:SetSize(36, 36)
    portrait:SetPoint("LEFT", 0, 0)
    portrait:Hide()
    ns.headerPortrait = portrait
end

-- Refresh the portrait for the current conversation.
-- Shows the 3D model when the unit is reachable; repositions headerName
-- to sit right of the portrait (or back to the left edge when hidden).
function ns.UpdatePortrait()
    if not ns.headerPortrait or not ns.headerName then return end

    local enabled = ns.db and ns.db.settings and ns.db.settings.showPortrait
    local unit    = enabled and ns.activeConversation and FindUnitByName(ns.activeConversation)

    if unit then
        ns.headerPortrait:SetUnit(unit)
        ns.headerPortrait:Show()
        ns.headerName:ClearAllPoints()
        ns.headerName:SetPoint("LEFT", ns.headerPortrait, "RIGHT", 6, 2)
    else
        ns.headerPortrait:Hide()
        ns.headerName:ClearAllPoints()
        ns.headerName:SetPoint("LEFT", 10, 2)
    end
end
