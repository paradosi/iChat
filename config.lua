local _, ns = ...

local defaults = {
    conversations = {},
    pinnedConversations = {},
    contactNotes = {},
    mutedContacts = {},
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
        showTimestampOnHover = true,
        showDateSeparators = true,
        enableItemLinks = true,
        showOnlineStatus = true,
        classColoredNames = true,
        autoReplyEnabled = false,
        autoReplyMessage = "I'm currently away. I'll respond when I return!",
        enableKeyboardShortcuts = true,
        showMinimapButton = true,
        hideInCombat = true,
        buttonSize = 40,
    },
}

-- Deep copy a table (handles nested tables safely)
local function DeepCopy(src)
    if type(src) ~= "table" then return src end
    local copy = {}
    for k, v in pairs(src) do
        copy[k] = DeepCopy(v)
    end
    return copy
end

function ns.InitDB()
    if not ICHAT_DATA then
        ICHAT_DATA = {}
    end

    -- Merge top-level keys
    for k, v in pairs(defaults) do
        if ICHAT_DATA[k] == nil then
            ICHAT_DATA[k] = DeepCopy(v)
        end
    end

    -- Merge missing settings keys
    for k, v in pairs(defaults.settings) do
        if ICHAT_DATA.settings[k] == nil then
            ICHAT_DATA.settings[k] = v
        end
    end

    -- Ensure new top-level tables exist
    if not ICHAT_DATA.pinnedConversations then ICHAT_DATA.pinnedConversations = {} end
    if not ICHAT_DATA.contactNotes then ICHAT_DATA.contactNotes = {} end
    if not ICHAT_DATA.mutedContacts then ICHAT_DATA.mutedContacts = {} end

    -- Check if WIM is loaded — avoid double-suppression
    if C_AddOns.IsAddOnLoaded("WIM") then
        ICHAT_DATA.settings.suppressDefault = false
    end

    ns.db = ICHAT_DATA
end
