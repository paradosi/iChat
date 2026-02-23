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
-- Exposed as ns.FindUnitByName so other modules (e.g. messages.lua) can use it.
function ns.FindUnitByName(name)
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

-- Local class cache for players seen in range (keyed by lowercase name → token).
-- Supplements ns.classCache (friends list) with any player we've rendered a 3D portrait for.
local portraitClassCache = {}

-- Cache the class token for a unit if not already known.
local function CacheUnitClass(unit, name)
    if not unit or not name then return end
    local key = name:lower()
    if portraitClassCache[key] then return end          -- already cached
    if ns.classCache and ns.classCache[key] then return end -- already in friends cache
    local _, classToken = UnitClass(unit)
    if classToken then
        portraitClassCache[key] = classToken
    end
end

-- Width of the portrait frame (used to offset headerName).
local PORTRAIT_W = 46

-- Class icon texture path — works for all WoW versions.
local function GetClassIconPath(classToken)
    if not classToken then return "Interface\\Icons\\INV_Misc_QuestionMark" end
    return "Interface\\Icons\\classicon_" .. classToken:lower()
end

-- Create the PlayerModel frame + a fallback 2D texture, attached to `parent`.
-- Stores frames as ns.headerPortrait (3D) and ns.headerPortrait2D (texture).
-- Call once during UI construction.
function ns.CreatePortraitFrame(parent)
    -- 3D PlayerModel (shown when unit is in range)
    local portrait = CreateFrame("PlayerModel", nil, parent)
    portrait:SetSize(PORTRAIT_W, 50)
    portrait:SetPoint("LEFT", 0, -7)
    portrait:Hide()
    ns.headerPortrait = portrait

    -- 2D class icon fallback (shown when unit is out of range)
    local icon = parent:CreateTexture(nil, "OVERLAY")
    icon:SetSize(PORTRAIT_W - 6, PORTRAIT_W - 6)   -- slightly smaller, square
    icon:SetPoint("LEFT", 2, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)        -- trim icon border
    icon:Hide()
    ns.headerPortrait2D = icon
end

-- Apply the head-and-shoulders camera to the already-loaded unit model.
-- Must be deferred one frame so the geometry is ready before SetCamera fires.
local function ApplyPortraitCamera(portrait)
    C_Timer.After(0, function()
        if portrait and portrait:IsShown() then
            portrait:SetCamera(1)           -- WoW portrait zoom (head + shoulders)
            portrait:SetPortraitZoom(0.85)  -- tighten to head/shoulders crop (0.0–1.0)
        end
    end)
end

-- Apply class color to headerName, falling back to white if unknown.
local function ApplyNameClassColor(name)
    if not ns.headerName or not name then return end
    local key        = name:lower()
    local classToken = (ns.classCache and ns.classCache[key])
                    or portraitClassCache[key]
    if classToken and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken] then
        local c = RAID_CLASS_COLORS[classToken]
        ns.headerName:SetTextColor(c.r, c.g, c.b)
    else
        ns.headerName:SetTextColor(1, 1, 1)  -- fallback white
    end
end

-- Refresh the portrait for the current conversation.
-- Shows 3D model when unit is reachable; falls back to 2D class icon otherwise.
-- Repositions headerName to sit right of the portrait (or back to left edge when hidden).
function ns.UpdatePortrait()
    if not ns.headerPortrait or not ns.headerName then return end

    local enabled = ns.db and ns.db.settings and ns.db.settings.showPortrait
    local name    = ns.activeConversation
    local unit    = enabled and name and ns.FindUnitByName(name)

    if not enabled or not name then
        -- portraits disabled or no active conversation
        ns.headerPortrait:ClearModel()
        ns.headerPortrait:Hide()
        if ns.headerPortrait2D then ns.headerPortrait2D:Hide() end
        ns.headerName:SetTextColor(1, 1, 1)
        ns.headerName:ClearAllPoints()
        ns.headerName:SetPoint("LEFT", 10, 2)

    elseif unit then
        -- 3D model — cache class first so ApplyNameClassColor has it immediately
        CacheUnitClass(unit, name)
        ApplyNameClassColor(name)
        if ns.headerPortrait2D then ns.headerPortrait2D:Hide() end
        ns.headerPortrait:ClearModel()
        ns.headerPortrait:SetUnit(unit)
        ns.headerPortrait:Show()
        ApplyPortraitCamera(ns.headerPortrait)
        ns.headerName:ClearAllPoints()
        ns.headerName:SetPoint("LEFT", ns.headerPortrait, "RIGHT", 6, 2)

    else
        -- 2D fallback — check friends cache, then local portrait cache
        ns.headerPortrait:ClearModel()
        ns.headerPortrait:Hide()
        ApplyNameClassColor(name)
        if ns.headerPortrait2D then
            local key        = name:lower()
            local classToken = (ns.classCache and ns.classCache[key])
                            or portraitClassCache[key]
            ns.headerPortrait2D:SetTexture(GetClassIconPath(classToken))
            ns.headerPortrait2D:Show()
            ns.headerName:ClearAllPoints()
            ns.headerName:SetPoint("LEFT", ns.headerPortrait2D, "RIGHT", 6, 2)
        else
            ns.headerName:ClearAllPoints()
            ns.headerName:SetPoint("LEFT", 10, 2)
        end
    end
end
