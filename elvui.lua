local _, ns = ...

---------------------------------------------------------------------------
-- ElvUI Skin Integration
-- Auto-detect ElvUI and apply matching backdrop/font/colors
---------------------------------------------------------------------------

function ns.ApplyElvUISkin()
    -- Check if ElvUI is loaded
    local E = _G.ElvUI and _G.ElvUI[1]
    if not E then return false end

    local S = E:GetModule("Skins", true)
    local db = E.db

    if not db then return false end

    -- Extract ElvUI's color scheme
    local bgR, bgG, bgB = unpack(db.general.backdropcolor or { 0.1, 0.1, 0.1 })
    local borderR, borderG, borderB = unpack(db.general.bordercolor or { 0.3, 0.3, 0.3 })
    local valueR, valueG, valueB = unpack(db.general.valuecolor or { 0.0, 0.48, 1.0 })

    -- Store ElvUI colors for use throughout the addon
    ns.elvuiColors = {
        bg = { bgR, bgG, bgB },
        border = { borderR, borderG, borderB },
        accent = { valueR, valueG, valueB },
    }

    -- Apply to main window if it exists
    if ns.mainWindow then
        ns.mainWindow:SetBackdropColor(bgR, bgG, bgB, ns.db.settings.bgAlpha or 0.95)
        ns.mainWindow:SetBackdropBorderColor(borderR, borderG, borderB, 1)
    end

    -- Override accent color
    ns.C = ns.C or {}
    ns.C.BLUE = { valueR, valueG, valueB, 1 }

    -- Use ElvUI's font if available
    local elvFont = E.media and E.media.normFont
    if elvFont and ns.db.settings.font == "Fonts\\FRIZQT__.TTF" then
        -- Only override if user hasn't explicitly chosen a font
        ns.db.settings._elvuiFont = elvFont
    end

    DEFAULT_CHAT_FRAME:AddMessage("|cff007AFFiChat:|r ElvUI theme detected and applied.")
    return true
end

-- Get the effective font (ElvUI override or user setting)
function ns.GetEffectiveFont()
    if ns.db.settings._elvuiFont and not ns.db.settings._fontOverridden then
        return ns.db.settings._elvuiFont
    end
    return ns.db.settings.font
end
