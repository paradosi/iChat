local _, ns = ...

---------------------------------------------------------------------------
-- Portraits — Class icon in the conversation header
--
-- Scans visible unit IDs (player, target, focus, party, raid) to find
-- a unit matching the active conversation partner. When found, displays
-- their class icon in the header frame and colors their name by class.
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

-- Class icon texture coordinates (from Interface\GLUES\CHARACTERCREATE\UI-CHARACTERCREATE-CLASSES)
-- Format: { left, right, top, bottom }
local CLASS_ICON_TCOORDS = {
    ["WARRIOR"]     = { 0,      0.25,   0,      0.25 },
    ["MAGE"]        = { 0.25,   0.49609375, 0,  0.25 },
    ["ROGUE"]       = { 0.49609375, 0.7421875, 0, 0.25 },
    ["DRUID"]       = { 0.7421875, 0.98828125, 0, 0.25 },
    ["HUNTER"]      = { 0,      0.25,   0.25,   0.5 },
    ["SHAMAN"]      = { 0.25,   0.49609375, 0.25, 0.5 },
    ["PRIEST"]      = { 0.49609375, 0.7421875, 0.25, 0.5 },
    ["WARLOCK"]     = { 0.7421875, 0.98828125, 0.25, 0.5 },
    ["PALADIN"]     = { 0,      0.25,   0.5,    0.75 },
    ["DEATHKNIGHT"] = { 0.25,   0.49609375, 0.5, 0.75 },
    ["MONK"]        = { 0.49609375, 0.7421875, 0.5, 0.75 },
    ["DEMONHUNTER"] = { 0.7421875, 0.98828125, 0.5, 0.75 },
    ["EVOKER"]      = { 0.49609375, 0.7421875, 0.75, 1.0 },
}

-- Width of the class icon (square)
local ICON_SIZE = 28

-- Create the class icon frame and attach it to `parent` (the header frame).
-- Stores the frame as ns.headerPortrait. Call once during UI construction.
function ns.CreatePortraitFrame(parent)
    local icon = CreateFrame("Frame", nil, parent)
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetPoint("LEFT", 6, 0)
    icon:Hide()

    local tex = icon:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints(icon)
    tex:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
    icon.texture = tex

    ns.headerPortrait = icon
end

-- Refresh the class icon and name color for the current conversation.
-- Shows the class icon when the unit is reachable; repositions headerName
-- to sit right of the icon (or back to the left edge when hidden).
-- Also applies class color to the player name.
function ns.UpdatePortrait()
    if not ns.headerPortrait or not ns.headerName then return end

    local enabled = ns.db and ns.db.settings and ns.db.settings.showPortrait
    local unit    = enabled and ns.activeConversation and FindUnitByName(ns.activeConversation)

    if unit then
        local _, classFilename = UnitClass(unit)
        local coords = CLASS_ICON_TCOORDS[classFilename]
        
        if coords then
            ns.headerPortrait.texture:SetTexCoord(unpack(coords))
            ns.headerPortrait:Show()
            ns.headerName:ClearAllPoints()
            ns.headerName:SetPoint("LEFT", ns.headerPortrait, "RIGHT", 8, 2)
            
            -- Apply class color to name
            local classColor = RAID_CLASS_COLORS[classFilename]
            if classColor then
                ns.headerName:SetTextColor(classColor.r, classColor.g, classColor.b)
            else
                ns.headerName:SetTextColor(1, 1, 1)
            end
        else
            -- Unknown class, hide icon and use white text
            ns.headerPortrait:Hide()
            ns.headerName:ClearAllPoints()
            ns.headerName:SetPoint("LEFT", 10, 2)
            ns.headerName:SetTextColor(1, 1, 1)
        end
    else
        -- Unit not found, hide icon and use white text
        ns.headerPortrait:Hide()
        ns.headerName:ClearAllPoints()
        ns.headerName:SetPoint("LEFT", 10, 2)
        ns.headerName:SetTextColor(1, 1, 1)
    end
end
