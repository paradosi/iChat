local _, ns = ...

local defaults = {
    conversations = {},
    settings = {
        scale = 1.0,
        suppressDefault = true,
        openOnWhisper = true,
        maxHistory = 100,
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 11,
        bgAlpha = 0.95,
        quickReplies = {},
        notifySound = "glass",
    },
}

function ns.InitDB()
    if not ICHAT_DATA then
        ICHAT_DATA = {}
    end

    -- Merge top-level keys
    for k, v in pairs(defaults) do
        if ICHAT_DATA[k] == nil then
            if type(v) == "table" then
                ICHAT_DATA[k] = {}
                for k2, v2 in pairs(v) do
                    ICHAT_DATA[k][k2] = v2
                end
            else
                ICHAT_DATA[k] = v
            end
        end
    end

    -- Merge missing settings keys
    for k, v in pairs(defaults.settings) do
        if ICHAT_DATA.settings[k] == nil then
            ICHAT_DATA.settings[k] = v
        end
    end

    -- Check if WIM is loaded — avoid double-suppression
    if C_AddOns.IsAddOnLoaded("WIM") then
        ICHAT_DATA.settings.suppressDefault = false
    end

    ns.db = ICHAT_DATA
end
