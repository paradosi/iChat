local _, ns = ...

---------------------------------------------------------------------------
-- Messages — Whisper handling, message storage, delivery tracking, and
--            chat filter suppression
--
-- Handles all incoming/outgoing whisper events (CHAT_MSG_WHISPER,
-- CHAT_MSG_WHISPER_INFORM, CHAT_MSG_SYSTEM for failures, AFK/DND).
-- Maintains friend/class/online caches from FRIENDLIST_UPDATE.
-- Tracks pending outbound whispers for delivery status (Sent/Failed).
-- Provides chat filters to optionally suppress whispers from default UI.
---------------------------------------------------------------------------

-- Retail moved these behind namespaces; the old globals survive only as
-- Blizzard_Deprecated shims. Every client has the new ones.
local SendChatMessage = (C_ChatInfo and C_ChatInfo.SendChatMessage) or SendChatMessage
local SendBNetWhisper = (C_BattleNet and C_BattleNet.SendWhisper) or BNSendWhisper
local AddMessageEventFilter = (ChatFrameUtil and ChatFrameUtil.AddMessageEventFilter) or ChatFrame_AddMessageEventFilter
local RemoveMessageEventFilter = (ChatFrameUtil and ChatFrameUtil.RemoveMessageEventFilter) or ChatFrame_RemoveMessageEventFilter
ns.SendBNetWhisperRaw = SendBNetWhisper

-- "No player named '%s' is currently playing." in the client's own language,
-- turned into a Lua pattern that captures the name
local NOT_FOUND_PATTERN
do
    local fmt = ERR_CHAT_PLAYER_NOT_FOUND_S or "No player named '%s' is currently playing."
    local escaped = fmt:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
    NOT_FOUND_PATTERN = "^" .. escaped:gsub("%%%%s", "(.-)") .. "$"
end

-- Friend cache
ns.friendCache = {}
ns.classCache = {}
ns.onlineCache = {}
ns.autoRepliedTo = {}

function ns:FRIENDLIST_UPDATE()
    -- One read of the friend list, shared by every consumer below
    local friends = ns.GetFriends()

    -- Check for online/offline changes before wiping cache
    if ns.CheckFriendStatusChanges then
        ns.CheckFriendStatusChanges(friends)
    end

    wipe(ns.friendCache)
    wipe(ns.classCache)
    wipe(ns.onlineCache)

    for _, info in ipairs(friends) do
        local lower = info.name:lower()
        ns.friendCache[lower] = true
        if info.className then
            ns.classCache[lower] = ns.ClassTokenFromName(info.className) or info.className:upper()
        end
        ns.onlineCache[lower] = info.connected or false
    end

    -- Scan for detailed player info (class/race cache)
    ns.ScanFriendList(friends)

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
    
    local numIgnores = 0
    local GetName
    if C_FriendList and C_FriendList.GetNumIgnores then
        numIgnores = C_FriendList.GetNumIgnores()
        GetName = C_FriendList.GetIgnoreName
    else
        numIgnores = GetNumIgnores()
        GetName = GetIgnoreName
    end
    
    for i = 1, numIgnores do
        local ignored = GetName(i)
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

    -- Trim to maxHistory, keeping the unread separator on the same message
    while #convo.messages > ns.db.settings.maxHistory do
        table.remove(convo.messages, 1)
        if convo.unreadSepIndex then
            convo.unreadSepIndex = convo.unreadSepIndex > 1 and convo.unreadSepIndex - 1 or nil
        end
    end

    convo.lastActivity = time()

    return entry
end

-- Incoming whisper
function ns:CHAT_MSG_WHISPER(text, sender, ...)
    if not ns.CanRead(text, sender) then return ns.NoteUnreadableWhisper() end
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

    -- Fire WeakAuras event
    if ns.FireWhisperReceived then
        ns.FireWhisperReceived(sender, text)
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
    if not ns.CanRead(text, sender) then return end
    sender = Ambiguate(sender, "none")
    local isFriend = ns.IsFriend(sender)
    local entry = ns.StoreMessage(sender, text, "me", isFriend)
    entry.status = "delivered"

    -- Clear pending tracker
    ns.pendingWhispers[sender:lower()] = nil

    -- Fire WeakAuras event
    if ns.FireWhisperSent then
        ns.FireWhisperSent(sender, text)
    end

    if ns.RefreshConversationList then
        ns.RefreshConversationList()
    end
    if ns.activeConversation == sender and ns.AddBubble then
        ns.AddBubble(entry, sender)
        ns.ScrollToBottom()
    end
end

-- Incoming BNet whisper
function ns:CHAT_MSG_BN_WHISPER(text, sender, _, _, _, _, _, _, _, _, _, _, bnetIDAccount, ...)
    if not ns.CanRead(text, bnetIDAccount) then return ns.NoteUnreadableWhisper() end
    if not bnetIDAccount then return end
    
    local convoName = "BNet:" .. bnetIDAccount
    
    local isFriend = true -- BNet friends are always friends
    local entry = ns.StoreMessage(convoName, text, "them", isFriend)
    
    -- Update unread if not viewing this conversation
    if ns.activeConversation ~= convoName then
        local convo = ns.db.conversations[convoName]
        convo.unread = (convo.unread or 0) + 1
        if not convo.unreadSepIndex then
            convo.unreadSepIndex = #convo.messages
        end
    end
    
    -- Check if this contact is muted
    local isMuted = ns.db.mutedContacts and ns.db.mutedContacts[convoName]
    
    -- Flash taskbar icon (skip if muted)
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
    if ns.activeConversation == convoName and ns.AddBubble then
        ns.AddBubble(entry, convoName)
        ns.ScrollToBottom()
    end
    
    -- Auto-open window on incoming whisper
    if ns.mainWindow and not ns.mainWindow:IsShown() and ns.db.settings.openOnWhisper then
        ns.mainWindow:Show()
        ns.SelectConversation(convoName)
    elseif ns.mainWindow and ns.mainWindow:IsShown() and ns.FlashWindow then
        ns.FlashWindow()
    end
    
    -- Fire WeakAuras event
    if ns.FireWhisperReceived then
        ns.FireWhisperReceived(convoName, text)
    end
end

-- Outgoing BNet whisper (confirmed delivered by server)
function ns:CHAT_MSG_BN_WHISPER_INFORM(text, sender, _, _, _, _, _, _, _, _, _, _, bnetIDAccount, ...)
    if not ns.CanRead(text, bnetIDAccount) then return end
    if not bnetIDAccount then return end
    
    local convoName = "BNet:" .. bnetIDAccount
    local isFriend = true
    local entry = ns.StoreMessage(convoName, text, "me", isFriend)
    entry.status = "delivered"
    
    -- Fire WeakAuras event
    if ns.FireWhisperSent then
        ns.FireWhisperSent(convoName, text)
    end
    
    if ns.RefreshConversationList then
        ns.RefreshConversationList()
    end
    if ns.activeConversation == convoName and ns.AddBubble then
        ns.AddBubble(entry, convoName)
        ns.ScrollToBottom()
    end
end

-- System message handler — detect whisper failures ("No player named X is currently playing")
function ns:CHAT_MSG_SYSTEM(text)
    if not ns.CanRead(text) or type(text) ~= "string" then return end
    local failedName = text:match(NOT_FOUND_PATTERN)
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
    if not ns.CanRead(text, sender) then return end
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
    if not ns.CanRead(text, sender) then return end
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
    -- Retail 12.0+: chat is locked down for addons in instances, encounters,
    -- Mythic+ and PvP. Battle.net whispers carry the same restrictions as
    -- character whispers (both HasRestrictions in Blizzard's API docs).
    if C_ChatInfo and C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown() then
        DEFAULT_CHAT_FRAME:AddMessage("|cff007AFFiChat:|r Cannot send — chat is locked down.")
        return
    end

    -- Check if this is a BNet conversation
    if ns.IsBNetConversation and ns.IsBNetConversation(target) then
        local bnetIDAccount = ns.GetBNetIDFromName and ns.GetBNetIDFromName(target)
        if bnetIDAccount then
            SendBNetWhisper(bnetIDAccount, text)
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff007AFFiChat:|r Cannot send — BNet friend not found.")
        end
        return
    end

    -- Regular whisper

    -- Track pending message for delivery confirmation
    ns.pendingWhispers[target:lower()] = {
        text = text,
        time = time(),
    }

    SendChatMessage(text, "WHISPER", nil, target)
end

-- Chat filter to suppress whispers from default chat frame
function ns.WhisperFilter(self, event, ...)
    if ns.db.settings.suppressDefault then
        return true
    end
    return false, ...
end

function ns.RegisterChatFilters()
    AddMessageEventFilter("CHAT_MSG_WHISPER", ns.WhisperFilter)
    AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", ns.WhisperFilter)
    AddMessageEventFilter("CHAT_MSG_BN_WHISPER", ns.WhisperFilter)
    AddMessageEventFilter("CHAT_MSG_BN_WHISPER_INFORM", ns.WhisperFilter)
end

function ns.UnregisterChatFilters()
    RemoveMessageEventFilter("CHAT_MSG_WHISPER", ns.WhisperFilter)
    RemoveMessageEventFilter("CHAT_MSG_WHISPER_INFORM", ns.WhisperFilter)
    RemoveMessageEventFilter("CHAT_MSG_BN_WHISPER", ns.WhisperFilter)
    RemoveMessageEventFilter("CHAT_MSG_BN_WHISPER_INFORM", ns.WhisperFilter)
end
