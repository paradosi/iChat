local _, ns = ...

-- Friend cache
ns.friendCache = {}
ns.classCache = {}
ns.onlineCache = {}
ns.autoRepliedTo = {}

-- Build reverse lookup: localized class name -> token (e.g. "Warrior" -> "WARRIOR")
local classNameToToken = {}
for i = 1, GetNumClasses() do
    local name, token = GetClassInfo(i)
    if name and token then
        classNameToToken[name] = token
    end
end

function ns:FRIENDLIST_UPDATE()
    wipe(ns.friendCache)
    wipe(ns.classCache)
    wipe(ns.onlineCache)
    local numFriends = C_FriendList.GetNumFriends()
    for i = 1, numFriends do
        local info = C_FriendList.GetFriendInfoByIndex(i)
        if info and info.name then
            local lower = info.name:lower()
            ns.friendCache[lower] = true
            if info.className then
                -- Convert localized class name to token for RAID_CLASS_COLORS
                local token = classNameToToken[info.className] or info.className:upper()
                ns.classCache[lower] = token
            end
            ns.onlineCache[lower] = info.connected or false
        end
    end
    if ns.UpdateHeaderButtons then
        ns.UpdateHeaderButtons()
    end
    if ns.RefreshConversationList then
        ns.RefreshConversationList()
    end
end

function ns.IsFriend(name)
    if not name then return false end
    return ns.friendCache[name:lower()] or false
end

function ns.IsIgnored(name)
    if not name then return false end
    local lower = name:lower()
    for i = 1, C_FriendList.GetNumIgnores() do
        local ignored = C_FriendList.GetIgnoreName(i)
        if ignored and ignored:lower() == lower then
            return true
        end
    end
    return false
end

-- Refresh header buttons when ignore list changes
function ns:IGNORELIST_UPDATE()
    if ns.UpdateHeaderButtons then
        ns.UpdateHeaderButtons()
    end
end

-- Message storage
function ns.StoreMessage(playerName, text, direction, isFriend)
    local convos = ns.db.conversations

    if not convos[playerName] then
        convos[playerName] = {
            messages = {},
            unread = 0,
            lastActivity = 0,
        }
    end

    local convo = convos[playerName]
    local entry = {
        text = text,
        sender = direction, -- "me" or "them"
        time = time(),
        isFriend = isFriend,
    }

    table.insert(convo.messages, entry)

    -- Trim to maxHistory
    while #convo.messages > ns.db.settings.maxHistory do
        table.remove(convo.messages, 1)
    end

    convo.lastActivity = time()

    return entry
end

-- Incoming whisper
function ns:CHAT_MSG_WHISPER(text, sender, ...)
    sender = Ambiguate(sender, "none")
    local isFriend = ns.IsFriend(sender)
    local entry = ns.StoreMessage(sender, text, "them", isFriend)

    -- Update unread if not viewing this conversation
    if ns.activeConversation ~= sender then
        local convo = ns.db.conversations[sender]
        convo.unread = (convo.unread or 0) + 1
        -- Track unread separator position (first unread message)
        if not convo.unreadSepIndex then
            convo.unreadSepIndex = #convo.messages
        end
    end

    -- Check if this contact is muted
    local isMuted = ns.db.mutedContacts and ns.db.mutedContacts[sender]

    -- Flash taskbar icon on incoming whisper (skip if muted)
    if not isMuted and FlashClientIcon then
        FlashClientIcon()
    end

    -- Flash the floating button (skip if muted)
    if not isMuted and ns.FlashButton then
        ns.FlashButton()
    end

    -- Play notification sound (skip if muted)
    if not isMuted and ns.PlayNotifySound then
        ns.PlayNotifySound()
    end

    -- Update UI
    if ns.UpdateButtonBadge then
        ns.UpdateButtonBadge()
    end
    if ns.RefreshConversationList then
        ns.RefreshConversationList()
    end
    if ns.activeConversation == sender and ns.AddBubble then
        ns.AddBubble(entry, sender)
        ns.ScrollToBottom()
    end

    -- Auto-open window on incoming whisper
    if ns.mainWindow and not ns.mainWindow:IsShown() and ns.db.settings.openOnWhisper then
        ns.mainWindow:Show()
        ns.SelectConversation(sender)
    elseif ns.mainWindow and ns.mainWindow:IsShown() and ns.FlashWindow then
        -- Flash to full opacity briefly on new whisper
        ns.FlashWindow()
    end

    -- Auto-reply (once per contact per session)
    if ns.db.settings.autoReplyEnabled and not ns.autoRepliedTo[sender] then
        local msg = ns.db.settings.autoReplyMessage
        if msg and msg ~= "" then
            ns.autoRepliedTo[sender] = true
            C_Timer.After(0.5, function()
                ns.SendWhisper(sender, msg)
            end)
        end
    end
end

-- Outgoing whisper (confirmed delivered by server)
function ns:CHAT_MSG_WHISPER_INFORM(text, sender, ...)
    sender = Ambiguate(sender, "none")
    local isFriend = ns.IsFriend(sender)
    local entry = ns.StoreMessage(sender, text, "me", isFriend)
    entry.status = "delivered"

    -- Clear pending tracker
    ns.pendingWhispers[sender:lower()] = nil

    if ns.RefreshConversationList then
        ns.RefreshConversationList()
    end
    if ns.activeConversation == sender and ns.AddBubble then
        ns.AddBubble(entry, sender)
        ns.ScrollToBottom()
    end
end

-- System message handler — detect whisper failures ("No player named X is currently playing")
function ns:CHAT_MSG_SYSTEM(text)
    local failedName = text:match("No player named '(.-)' is currently playing")
        or text:match("No player named (.+) is currently playing")
    if not failedName then return end

    local lower = failedName:lower()
    local pending = ns.pendingWhispers[lower]
    if not pending then return end

    ns.pendingWhispers[lower] = nil

    -- Find the last outgoing message to this player and mark as failed
    local convo = ns.db.conversations[failedName]
    if convo and convo.messages then
        for i = #convo.messages, 1, -1 do
            local msg = convo.messages[i]
            if msg.sender == "me" and not msg.status then
                msg.status = "failed"
                break
            end
        end
    end

    -- Rebuild if viewing this conversation
    if ns.activeConversation == failedName and ns.RebuildBubbles then
        ns.RebuildBubbles(failedName)
        ns.ScrollToBottom()
    end
end

-- AFK auto-reply
function ns:CHAT_MSG_AFK(text, sender, ...)
    sender = Ambiguate(sender, "none")
    if ns.db.conversations[sender] then
        local entry = ns.StoreMessage(sender, "[AFK] " .. text, "them", ns.IsFriend(sender))
        if ns.activeConversation == sender and ns.AddBubble then
            ns.AddBubble(entry, sender)
            ns.ScrollToBottom()
        end
        if ns.RefreshConversationList then
            ns.RefreshConversationList()
        end
    end
end

-- DND auto-reply
function ns:CHAT_MSG_DND(text, sender, ...)
    sender = Ambiguate(sender, "none")
    if ns.db.conversations[sender] then
        local entry = ns.StoreMessage(sender, "[DND] " .. text, "them", ns.IsFriend(sender))
        if ns.activeConversation == sender and ns.AddBubble then
            ns.AddBubble(entry, sender)
            ns.ScrollToBottom()
        end
        if ns.RefreshConversationList then
            ns.RefreshConversationList()
        end
    end
end

-- Pending outbound messages (for delivery tracking)
ns.pendingWhispers = {}

-- Send a whisper
function ns.SendWhisper(target, text)
    -- Retail 12.0+: check for chat lockdown
    if C_ChatInfo and C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown() then
        DEFAULT_CHAT_FRAME:AddMessage("|cff007AFFiChat:|r Cannot send — chat is locked down.")
        return
    end

    -- Track pending message for delivery confirmation
    ns.pendingWhispers[target:lower()] = {
        text = text,
        time = time(),
    }

    if C_ChatInfo and C_ChatInfo.SendChatMessage then
        C_ChatInfo.SendChatMessage(text, "WHISPER", nil, target)
    else
        SendChatMessage(text, "WHISPER", nil, target)
    end
end

-- Chat filter to suppress whispers from default chat frame
function ns.WhisperFilter(self, event, ...)
    if ns.db.settings.suppressDefault then
        return true
    end
    return false, ...
end

function ns.RegisterChatFilters()
    ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", ns.WhisperFilter)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", ns.WhisperFilter)
end

function ns.UnregisterChatFilters()
    ChatFrame_RemoveMessageEventFilter("CHAT_MSG_WHISPER", ns.WhisperFilter)
    ChatFrame_RemoveMessageEventFilter("CHAT_MSG_WHISPER_INFORM", ns.WhisperFilter)
end
