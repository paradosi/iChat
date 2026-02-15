local _, ns = ...

---------------------------------------------------------------------------
-- ElvUI Skin Integration
-- Auto-detect ElvUI and apply matching backdrop/font/colors
---------------------------------------------------------------------------

function ns.ApplyElvUISkin()
    local ok, err = pcall(ns._ApplyElvUISkinInner)
    if not ok then
        DEFAULT_CHAT_FRAME:AddMessage("|cff007AFFiChat:|r ElvUI skin failed: " .. tostring(err))
        return false
    end
    return true
end

function ns._ApplyElvUISkinInner()
    -- Check if ElvUI is loaded
    local E = _G.ElvUI and _G.ElvUI[1]
    if not E then return false end

    local S = E:GetModule("Skins", true)
    local db = E.db

    if not db or not db.general then return false end

    -- Extract ElvUI's color scheme
    local bc = db.general and db.general.backdropcolor
    local bgR, bgG, bgB = 0.1, 0.1, 0.1
    if bc and type(bc) == "table" and bc.r then
        bgR, bgG, bgB = bc.r, bc.g, bc.b
    elseif bc and type(bc) == "table" and bc[1] then
        bgR, bgG, bgB = bc[1], bc[2] or 0.1, bc[3] or 0.1
    end

    local brc = db.general and db.general.bordercolor
    local borderR, borderG, borderB = 0.3, 0.3, 0.3
    if brc and type(brc) == "table" and brc.r then
        borderR, borderG, borderB = brc.r, brc.g, brc.b
    elseif brc and type(brc) == "table" and brc[1] then
        borderR, borderG, borderB = brc[1], brc[2] or 0.3, brc[3] or 0.3
    end

    local vc = db.general and db.general.valuecolor
    local valueR, valueG, valueB = 0.0, 0.48, 1.0
    if vc and type(vc) == "table" and vc.r then
        valueR, valueG, valueB = vc.r, vc.g, vc.b
    elseif vc and type(vc) == "table" and vc[1] then
        valueR, valueG, valueB = vc[1], vc[2] or 0.48, vc[3] or 1.0
    end

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
