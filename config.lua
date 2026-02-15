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
        sharedAccount = false,
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

-- Deep merge: copy missing keys from src into dst (does not overwrite existing)
local function DeepMerge(dst, src)
    for k, v in pairs(src) do
        if dst[k] == nil then
            dst[k] = DeepCopy(v)
        elseif type(v) == "table" and type(dst[k]) == "table" then
            DeepMerge(dst[k], v)
        end
    end
end

-- Migrate per-character data into account-wide storage
local function MigrateToAccount()
    if not ICHAT_DATA or not ICHAT_ACCOUNT then return end

    -- Merge conversations (don't overwrite existing account convos)
    for name, convo in pairs(ICHAT_DATA.conversations or {}) do
        if not ICHAT_ACCOUNT.conversations[name] then
            ICHAT_ACCOUNT.conversations[name] = DeepCopy(convo)
        else
            -- Append any messages that are newer than the latest in account
            local acctConvo = ICHAT_ACCOUNT.conversations[name]
            local acctLast = acctConvo.lastActivity or 0
            for _, msg in ipairs(convo.messages or {}) do
                if msg.time and msg.time > acctLast then
                    table.insert(acctConvo.messages, DeepCopy(msg))
                end
            end
            if convo.lastActivity and convo.lastActivity > acctLast then
                acctConvo.lastActivity = convo.lastActivity
            end
        end
    end

    -- Merge contact notes and pinned (don't overwrite)
    for name, note in pairs(ICHAT_DATA.contactNotes or {}) do
        if not ICHAT_ACCOUNT.contactNotes[name] then
            ICHAT_ACCOUNT.contactNotes[name] = note
        end
    end
    for name, v in pairs(ICHAT_DATA.pinnedConversations or {}) do
        if not ICHAT_ACCOUNT.pinnedConversations[name] then
            ICHAT_ACCOUNT.pinnedConversations[name] = v
        end
    end
    for name, v in pairs(ICHAT_DATA.mutedContacts or {}) do
        if not ICHAT_ACCOUNT.mutedContacts[name] then
            ICHAT_ACCOUNT.mutedContacts[name] = v
        end
    end
end

local function InitStorage(storage)
    -- Merge top-level keys from defaults
    for k, v in pairs(defaults) do
        if storage[k] == nil then
            storage[k] = DeepCopy(v)
        end
    end

    -- Merge missing settings keys
    for k, v in pairs(defaults.settings) do
        if storage.settings[k] == nil then
            storage.settings[k] = v
        end
    end

    -- Ensure new top-level tables exist
    if not storage.pinnedConversations then storage.pinnedConversations = {} end
    if not storage.contactNotes then storage.contactNotes = {} end
    if not storage.mutedContacts then storage.mutedContacts = {} end
end

function ns.InitDB()
    -- Initialize both storage tables
    if not ICHAT_DATA then ICHAT_DATA = {} end
    if not ICHAT_ACCOUNT then ICHAT_ACCOUNT = {} end

    InitStorage(ICHAT_DATA)
    InitStorage(ICHAT_ACCOUNT)

    -- Determine which storage to use
    -- Check account-wide first (shared setting lives there when enabled)
    local useShared = ICHAT_ACCOUNT.settings and ICHAT_ACCOUNT.settings.sharedAccount

    if useShared then
        ns.db = ICHAT_ACCOUNT
    else
        ns.db = ICHAT_DATA
    end

    -- Check if WIM is loaded — avoid double-suppression
    if C_AddOns.IsAddOnLoaded("WIM") then
        ns.db.settings.suppressDefault = false
    end
end

-- Switch between per-character and account-wide storage
-- Called from settings panel when toggling shared mode
function ns.SetSharedAccount(enabled)
    if enabled then
        -- Migrate current character data into account storage
        MigrateToAccount()
        ICHAT_ACCOUNT.settings.sharedAccount = true
        -- Copy current settings to account (except sharedAccount which we just set)
        for k, v in pairs(ICHAT_DATA.settings) do
            if k ~= "sharedAccount" and ICHAT_ACCOUNT.settings[k] == nil then
                ICHAT_ACCOUNT.settings[k] = DeepCopy(v)
            end
        end
        ns.db = ICHAT_ACCOUNT
        DEFAULT_CHAT_FRAME:AddMessage("|cff007AFFiChat:|r Switched to account-wide storage. Character data merged.")
    else
        ICHAT_ACCOUNT.settings.sharedAccount = false
        ICHAT_DATA.settings.sharedAccount = false
        ns.db = ICHAT_DATA
        DEFAULT_CHAT_FRAME:AddMessage("|cff007AFFiChat:|r Switched to per-character storage.")
    end

    -- Refresh UI with new data source
    if ns.RefreshConversationList then ns.RefreshConversationList() end
    if ns.activeConversation then
        local convo = ns.db.conversations[ns.activeConversation]
        if convo then
            ns.RebuildBubbles(ns.activeConversation)
        else
            ns.activeConversation = nil
        end
    end
    if ns.UpdateButtonBadge then ns.UpdateButtonBadge() end
end

-- Check if currently using shared account storage
function ns.IsSharedAccount()
    return ICHAT_ACCOUNT and ICHAT_ACCOUNT.settings and ICHAT_ACCOUNT.settings.sharedAccount or false
end
