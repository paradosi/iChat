local _, ns = ...

-- Color palette
local C = {
    BLUE        = { 0.00, 0.48, 1.00, 1.0 },
    GREEN       = { 0.20, 0.78, 0.35, 1.0 },
    BG_DARK     = { 0.05, 0.05, 0.05, 0.95 },
    BG_PANEL    = { 0.06, 0.06, 0.06, 1.0 },
    BG_INPUT    = { 0.12, 0.12, 0.12, 1.0 },
    TEXT_WHITE  = { 1.0, 1.0, 1.0, 1.0 },
    TEXT_GRAY   = { 0.5, 0.5, 0.5, 1.0 },
    TEXT_TIME   = { 0.4, 0.4, 0.4, 1.0 },
    DIVIDER     = { 0.15, 0.15, 0.15, 1.0 },
    HOVER       = { 0.14, 0.14, 0.14, 1.0 },
    ACTIVE      = { 0.00, 0.48, 1.00, 0.15 },
    BADGE       = { 1.0, 0.22, 0.17, 1.0 },
}
ns.C = C

local LEFT_WIDTH = 140
local ENTRY_HEIGHT = 52

---------------------------------------------------------------------------
-- Main Window
---------------------------------------------------------------------------
function ns.CreateMainWindow()
    local win = CreateFrame("Frame", "iChatMainWindow", UIParent, "BackdropTemplate")
    win:SetSize(450, 550)
    win:SetPoint("CENTER")
    win:SetFrameStrata("DIALOG")
    win:SetMovable(true)
    win:SetResizable(true)
    win:SetResizeBounds(350, 400, 700, 800)
    win:SetClampedToScreen(true)
    win:EnableMouse(true)
    win:Hide()

    win:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    win:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
    win:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

    win:SetScale(ns.db.settings.scale)

    -- Drag to move (combat guard)
    win:RegisterForDrag("LeftButton")
    win:SetScript("OnDragStart", function(self)
        if not InCombatLockdown() then self:StartMoving() end
    end)
    win:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)

    -- Resize handle
    local resizer = CreateFrame("Button", nil, win)
    resizer:SetSize(16, 16)
    resizer:SetPoint("BOTTOMRIGHT")
    resizer:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizer:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizer:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizer:SetScript("OnMouseDown", function()
        if not InCombatLockdown() then win:StartSizing("BOTTOMRIGHT") end
    end)
    resizer:SetScript("OnMouseUp", function()
        win:StopMovingOrSizing()
    end)

    -- ESC to close
    tinsert(UISpecialFrames, "iChatMainWindow")

    ns.mainWindow = win

    ns.CreateTitleBar(win)
    ns.CreateLeftPanel(win)
    ns.CreateDivider(win)
    ns.CreateRightPanel(win)

    -- Apply saved transparency
    ns.ApplyTransparency()

    -- Set up always-on fade behavior
    ns.SetupFadeHooks()
end

---------------------------------------------------------------------------
-- Title Bar
---------------------------------------------------------------------------
function ns.CreateTitleBar(parent)
    local bar = CreateFrame("Frame", nil, parent)
    bar:SetHeight(30)
    bar:SetPoint("TOPLEFT")
    bar:SetPoint("TOPRIGHT")

    -- Bottom border
    local border = bar:CreateTexture(nil, "OVERLAY")
    border:SetHeight(1)
    border:SetPoint("BOTTOMLEFT")
    border:SetPoint("BOTTOMRIGHT")
    border:SetColorTexture(unpack(C.DIVIDER))

    -- Title text
    local title = bar:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    title:SetTextColor(unpack(C.BLUE))
    title:SetPoint("CENTER")
    title:SetText("iChat")

    -- Close button
    local closeBtn = CreateFrame("Button", nil, bar)
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("RIGHT", -6, 0)
    local closeTex = closeBtn:CreateFontString(nil, "OVERLAY")
    closeTex:SetFont("Fonts\\FRIZQT__.TTF", 16, "")
    closeTex:SetPoint("CENTER")
    closeTex:SetText("x")
    closeTex:SetTextColor(0.6, 0.6, 0.6)
    closeBtn:SetScript("OnClick", function() parent:Hide() end)
    closeBtn:SetScript("OnEnter", function() closeTex:SetTextColor(1, 0.3, 0.3) end)
    closeBtn:SetScript("OnLeave", function() closeTex:SetTextColor(0.6, 0.6, 0.6) end)

    -- Minimize button
    local minBtn = CreateFrame("Button", nil, bar)
    minBtn:SetSize(20, 20)
    minBtn:SetPoint("RIGHT", closeBtn, "LEFT", -4, 0)
    local minTex = minBtn:CreateFontString(nil, "OVERLAY")
    minTex:SetFont("Fonts\\FRIZQT__.TTF", 16, "")
    minTex:SetPoint("CENTER", 0, -1)
    minTex:SetText("-")
    minTex:SetTextColor(0.6, 0.6, 0.6)
    minBtn:SetScript("OnClick", function() ns.ToggleMinimize() end)
    minBtn:SetScript("OnEnter", function() minTex:SetTextColor(1, 1, 1) end)
    minBtn:SetScript("OnLeave", function() minTex:SetTextColor(0.6, 0.6, 0.6) end)
    ns.minBtn = minBtn
    ns.minTex = minTex

    -- Settings (gear) button
    local gearBtn = CreateFrame("Button", nil, bar)
    gearBtn:SetSize(20, 20)
    gearBtn:SetPoint("RIGHT", minBtn, "LEFT", -4, 0)
    local gearIcon = gearBtn:CreateTexture(nil, "ARTWORK")
    gearIcon:SetSize(16, 16)
    gearIcon:SetPoint("CENTER")
    gearIcon:SetTexture("Interface\\Buttons\\UI-OptionsButton")
    gearIcon:SetVertexColor(0.6, 0.6, 0.6)
    gearBtn:SetScript("OnClick", function() ns.ToggleSettings() end)
    gearBtn:SetScript("OnEnter", function() gearIcon:SetVertexColor(1, 1, 1) end)
    gearBtn:SetScript("OnLeave", function() gearIcon:SetVertexColor(0.6, 0.6, 0.6) end)

    -- Compose (new chat) button — chat bubble icon
    local composeBtn = CreateFrame("Button", nil, bar)
    composeBtn:SetSize(28, 28)
    composeBtn:SetPoint("LEFT", 4, 0)
    local composeIcon = composeBtn:CreateTexture(nil, "ARTWORK")
    composeIcon:SetSize(26, 26)
    composeIcon:SetPoint("CENTER")
    composeIcon:SetTexture("Interface\\CHATFRAME\\UI-ChatIcon-Chat-Up")
    composeIcon:SetVertexColor(unpack(C.BLUE))
    composeBtn:SetScript("OnClick", function() ns.ToggleCompose() end)
    composeBtn:SetScript("OnEnter", function() composeIcon:SetVertexColor(1, 1, 1) end)
    composeBtn:SetScript("OnLeave", function() composeIcon:SetVertexColor(unpack(C.BLUE)) end)

    ns.titleBar = bar
end

---------------------------------------------------------------------------
-- Left Panel (Conversation List)
---------------------------------------------------------------------------
function ns.CreateLeftPanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetWidth(LEFT_WIDTH)
    panel:SetPoint("TOPLEFT", ns.titleBar, "BOTTOMLEFT", 0, 0)
    panel:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)

    local bg = panel:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(unpack(C.BG_PANEL))
    ns.leftPanelBg = bg

    -- Scroll frame
    local scroll = CreateFrame("ScrollFrame", "iChatConvoScroll", panel)
    scroll:SetPoint("TOPLEFT")
    scroll:SetPoint("BOTTOMRIGHT")
    scroll:EnableMouseWheel(true)

    local child = CreateFrame("Frame", "iChatConvoScrollChild", scroll)
    child:SetWidth(LEFT_WIDTH)
    child:SetHeight(1)
    scroll:SetScrollChild(child)

    scroll:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local maxScroll = math.max(0, child:GetHeight() - self:GetHeight())
        local newVal = math.max(0, math.min(maxScroll, current - (delta * 30)))
        self:SetVerticalScroll(newVal)
    end)

    ns.leftPanel = panel
    ns.convoScrollFrame = scroll
    ns.convoScrollChild = child
    ns.convoEntries = {}
end

---------------------------------------------------------------------------
-- Conversation Entry
---------------------------------------------------------------------------
function ns.CreateConvoEntry(index)
    local entry = CreateFrame("Button", nil, ns.convoScrollChild)
    entry:SetHeight(ENTRY_HEIGHT)
    entry:SetPoint("TOPLEFT", ns.convoScrollChild, "TOPLEFT", 0, -(index - 1) * ENTRY_HEIGHT)
    entry:SetPoint("RIGHT", ns.convoScrollChild, "RIGHT")

    local bg = entry:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0)
    entry.bg = bg

    -- Player name
    local name = entry:CreateFontString(nil, "OVERLAY")
    name:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    name:SetTextColor(unpack(C.TEXT_WHITE))
    name:SetPoint("TOPLEFT", 8, -8)
    name:SetPoint("RIGHT", -30, 0)
    name:SetJustifyH("LEFT")
    name:SetWordWrap(false)
    entry.nameText = name

    -- Preview
    local preview = entry:CreateFontString(nil, "OVERLAY")
    preview:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    preview:SetTextColor(unpack(C.TEXT_GRAY))
    preview:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -2)
    preview:SetPoint("RIGHT", -8, 0)
    preview:SetJustifyH("LEFT")
    preview:SetWordWrap(false)
    preview:SetMaxLines(1)
    entry.previewText = preview

    -- Relative time
    local timeText = entry:CreateFontString(nil, "OVERLAY")
    timeText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    timeText:SetTextColor(unpack(C.TEXT_TIME))
    timeText:SetPoint("TOPRIGHT", -8, -8)
    entry.timeText = timeText

    -- Unread badge
    local badge = CreateFrame("Frame", nil, entry)
    badge:SetSize(18, 18)
    badge:SetPoint("BOTTOMRIGHT", -8, 8)
    local badgeBg = badge:CreateTexture(nil, "ARTWORK")
    badgeBg:SetAllPoints()
    badgeBg:SetColorTexture(unpack(C.BADGE))
    local badgeCount = badge:CreateFontString(nil, "OVERLAY")
    badgeCount:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    badgeCount:SetPoint("CENTER")
    badgeCount:SetTextColor(1, 1, 1)
    badge:Hide()
    entry.unreadBadge = badge
    entry.unreadCount = badgeCount

    -- Bottom divider
    local div = entry:CreateTexture(nil, "OVERLAY")
    div:SetHeight(1)
    div:SetPoint("BOTTOMLEFT", 8, 0)
    div:SetPoint("BOTTOMRIGHT", -8, 0)
    div:SetColorTexture(unpack(C.DIVIDER))

    -- Click
    entry:SetScript("OnClick", function(self)
        ns.SelectConversation(self.playerName)
    end)
    entry:SetScript("OnEnter", function(self)
        if ns.activeConversation ~= self.playerName then
            bg:SetColorTexture(unpack(C.HOVER))
        end
    end)
    entry:SetScript("OnLeave", function(self)
        if ns.activeConversation ~= self.playerName then
            bg:SetColorTexture(0, 0, 0, 0)
        end
    end)

    return entry
end

---------------------------------------------------------------------------
-- Divider
---------------------------------------------------------------------------
function ns.CreateDivider(parent)
    local div = parent:CreateTexture(nil, "OVERLAY")
    div:SetWidth(1)
    div:SetPoint("TOPLEFT", ns.titleBar, "BOTTOMLEFT", LEFT_WIDTH, 0)
    div:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", LEFT_WIDTH, 0)
    div:SetColorTexture(unpack(C.DIVIDER))
end

---------------------------------------------------------------------------
-- Right Panel (Chat Area)
---------------------------------------------------------------------------
function ns.CreateRightPanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", ns.titleBar, "BOTTOMLEFT", LEFT_WIDTH + 1, 0)
    panel:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)

    -- Header
    local header = CreateFrame("Frame", nil, panel)
    header:SetHeight(36)
    header:SetPoint("TOPLEFT")
    header:SetPoint("TOPRIGHT")

    local headerBorder = header:CreateTexture(nil, "OVERLAY")
    headerBorder:SetHeight(1)
    headerBorder:SetPoint("BOTTOMLEFT")
    headerBorder:SetPoint("BOTTOMRIGHT")
    headerBorder:SetColorTexture(unpack(C.DIVIDER))

    local headerName = header:CreateFontString(nil, "OVERLAY")
    headerName:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    headerName:SetTextColor(unpack(C.TEXT_WHITE))
    headerName:SetPoint("LEFT", 10, 0)
    headerName:SetText("")
    ns.headerName = headerName

    -- Block button (rightmost)
    local blockBtn = CreateFrame("Button", nil, header)
    blockBtn:SetSize(48, 22)
    blockBtn:SetPoint("RIGHT", -6, 0)
    local blockText = blockBtn:CreateFontString(nil, "OVERLAY")
    blockText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    blockText:SetPoint("CENTER")
    blockText:SetText("Block")
    blockText:SetTextColor(0.8, 0.25, 0.2)
    blockBtn:SetScript("OnEnter", function() blockText:SetTextColor(1, 0.4, 0.3) end)
    blockBtn:SetScript("OnLeave", function()
        if ns.activeConversation and ns.IsIgnored(ns.activeConversation) then
            blockText:SetTextColor(0.5, 0.5, 0.5)
        else
            blockText:SetTextColor(0.8, 0.25, 0.2)
        end
    end)
    blockBtn:SetScript("OnClick", function()
        if not ns.activeConversation then return end
        if ns.IsIgnored(ns.activeConversation) then
            C_FriendList.DelIgnore(ns.activeConversation)
        else
            C_FriendList.AddIgnore(ns.activeConversation)
        end
        C_Timer.After(0.1, function() ns.UpdateHeaderButtons() end)
    end)
    blockBtn:Hide()
    ns.blockBtn = blockBtn
    ns.blockText = blockText

    -- Add Friend button (left of block)
    local friendBtn = CreateFrame("Button", nil, header)
    friendBtn:SetSize(64, 22)
    friendBtn:SetPoint("RIGHT", blockBtn, "LEFT", -4, 0)
    local friendText = friendBtn:CreateFontString(nil, "OVERLAY")
    friendText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    friendText:SetPoint("CENTER")
    friendText:SetText("Add Friend")
    friendText:SetTextColor(unpack(C.BLUE))
    friendBtn:SetScript("OnEnter", function() friendText:SetTextColor(1, 1, 1) end)
    friendBtn:SetScript("OnLeave", function() friendText:SetTextColor(unpack(C.BLUE)) end)
    friendBtn:SetScript("OnClick", function()
        if not ns.activeConversation then return end
        C_FriendList.AddFriend(ns.activeConversation)
        C_Timer.After(0.2, function()
            ns:FRIENDLIST_UPDATE()
            ns.UpdateHeaderButtons()
        end)
    end)
    friendBtn:Hide()
    ns.friendBtn = friendBtn
    ns.friendText = friendText

    -- Empty state text (shown when no conversation selected)
    local emptyText = panel:CreateFontString(nil, "OVERLAY")
    emptyText:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    emptyText:SetTextColor(0.35, 0.35, 0.35)
    emptyText:SetPoint("CENTER", panel, "CENTER", 0, 20)
    emptyText:SetText("Select a conversation\nor /w someone to start")
    ns.emptyText = emptyText

    -- Quick reply bar (created in settings.lua, sits above input)
    -- Reserve space: input=40, quickReply=26
    ns.CreateQuickReplyBar(panel)

    -- Chat scroll area
    local qrOffset = (ns.quickReplyBar and ns.quickReplyBar:IsShown()) and 66 or 40
    local chatScroll = CreateFrame("ScrollFrame", "iChatBubbleScroll", panel)
    chatScroll:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, 0)
    chatScroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, qrOffset)
    chatScroll:EnableMouseWheel(true)

    local chatChild = CreateFrame("Frame", "iChatBubbleScrollChild", chatScroll)
    chatChild:SetWidth(1) -- updated in OnSizeChanged
    chatChild:SetHeight(1)
    chatScroll:SetScrollChild(chatChild)

    chatScroll:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local maxScroll = math.max(0, chatChild:GetHeight() - self:GetHeight())
        local newVal = math.max(0, math.min(maxScroll, current - (delta * 40)))
        self:SetVerticalScroll(newVal)
    end)

    chatScroll:SetScript("OnSizeChanged", function(self, w, h)
        chatChild:SetWidth(w)
        if ns.activeConversation then
            ns.RebuildBubbles(ns.activeConversation)
        end
    end)

    ns.chatScrollFrame = chatScroll
    ns.chatScrollChild = chatChild

    -- Input bar
    local inputBar = CreateFrame("Frame", nil, panel)
    inputBar:SetHeight(40)
    inputBar:SetPoint("BOTTOMLEFT")
    inputBar:SetPoint("BOTTOMRIGHT")

    local inputBg = inputBar:CreateTexture(nil, "BACKGROUND")
    inputBg:SetAllPoints()
    inputBg:SetColorTexture(0.08, 0.08, 0.08, 1)

    local inputTopBorder = inputBar:CreateTexture(nil, "OVERLAY")
    inputTopBorder:SetHeight(1)
    inputTopBorder:SetPoint("TOPLEFT")
    inputTopBorder:SetPoint("TOPRIGHT")
    inputTopBorder:SetColorTexture(unpack(C.DIVIDER))

    -- Input EditBox
    local inputBox = CreateFrame("EditBox", "iChatInputBox", inputBar)
    inputBox:SetPoint("LEFT", 10, 0)
    inputBox:SetPoint("RIGHT", -68, 0)
    inputBox:SetHeight(24)
    inputBox:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    inputBox:SetTextColor(1, 1, 1)
    inputBox:SetAutoFocus(false)
    inputBox:SetMaxLetters(255)

    local inputBoxBg = inputBox:CreateTexture(nil, "BACKGROUND")
    inputBoxBg:SetPoint("TOPLEFT", inputBar, "TOPLEFT", 6, -6)
    inputBoxBg:SetPoint("BOTTOMRIGHT", inputBar, "BOTTOMRIGHT", -64, 6)
    inputBoxBg:SetTexture("Interface\\AddOns\\iChat\\media\\textures\\inputbox")
    inputBoxBg:SetVertexColor(0.18, 0.18, 0.18, 1)

    inputBox:SetScript("OnEnterPressed", function(self)
        local text = self:GetText()
        if text ~= "" and ns.activeConversation then
            ns.SendWhisper(ns.activeConversation, text)
            self:SetText("")
        end
    end)
    inputBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    -- Send button
    local sendBtn = CreateFrame("Button", nil, inputBar)
    sendBtn:SetSize(28, 28)
    sendBtn:SetPoint("RIGHT", -6, 0)
    local sendTex = sendBtn:CreateFontString(nil, "OVERLAY")
    sendTex:SetFont("Fonts\\FRIZQT__.TTF", 18, "")
    sendTex:SetPoint("CENTER")
    sendTex:SetText(">")
    sendTex:SetTextColor(unpack(C.BLUE))
    sendBtn:SetScript("OnClick", function()
        local text = inputBox:GetText()
        if text ~= "" and ns.activeConversation then
            ns.SendWhisper(ns.activeConversation, text)
            inputBox:SetText("")
        end
    end)
    sendBtn:SetScript("OnEnter", function() sendTex:SetTextColor(1, 1, 1) end)
    sendBtn:SetScript("OnLeave", function() sendTex:SetTextColor(unpack(C.BLUE)) end)

    -- Emoji picker button (between input and send)
    local emojiBtn = CreateFrame("Button", nil, inputBar)
    emojiBtn:SetSize(24, 24)
    emojiBtn:SetPoint("RIGHT", sendBtn, "LEFT", -2, 0)
    local emojiIcon = emojiBtn:CreateTexture(nil, "ARTWORK")
    emojiIcon:SetSize(20, 20)
    emojiIcon:SetPoint("CENTER")
    emojiIcon:SetTexture("Interface\\AddOns\\iChat\\media\\emoji\\smile.png")
    emojiBtn:SetScript("OnClick", function() ns.ToggleEmojiPicker() end)
    emojiBtn:SetScript("OnEnter", function()
        emojiIcon:SetVertexColor(1, 1, 0.7)
        GameTooltip:SetOwner(emojiBtn, "ANCHOR_TOP")
        GameTooltip:SetText("Emoji")
        GameTooltip:Show()
    end)
    emojiBtn:SetScript("OnLeave", function()
        emojiIcon:SetVertexColor(1, 1, 1)
        GameTooltip:Hide()
    end)

    -- Create emoji picker panel
    if ns.CreateEmojiPicker then
        ns.CreateEmojiPicker(ns.mainWindow)
        ns.emojiPicker:ClearAllPoints()
        ns.emojiPicker:SetPoint("BOTTOMRIGHT", emojiBtn, "TOPRIGHT", 0, 4)
    end

    ns.inputBox = inputBox
    ns.rightPanel = panel

    -- Enable Emoji-Core autocomplete on input box if available
    if Emojis and Emojis.EnableEmojiCompleterForEditBox then
        Emojis.EnableEmojiCompleterForEditBox(inputBox)
    end
end

---------------------------------------------------------------------------
-- Conversation List Management
---------------------------------------------------------------------------
function ns.RefreshConversationList()
    -- Sort by lastActivity descending
    local sorted = {}
    for name, convo in pairs(ns.db.conversations) do
        table.insert(sorted, { name = name, convo = convo })
    end
    table.sort(sorted, function(a, b)
        return (a.convo.lastActivity or 0) > (b.convo.lastActivity or 0)
    end)

    -- Ensure enough entry frames
    while #ns.convoEntries < #sorted do
        local entry = ns.CreateConvoEntry(#ns.convoEntries + 1)
        table.insert(ns.convoEntries, entry)
    end

    -- Update each entry
    for i, data in ipairs(sorted) do
        local entry = ns.convoEntries[i]
        entry.playerName = data.name
        entry.nameText:SetText(data.name)

        -- Last message preview
        local msgs = data.convo.messages
        if msgs and #msgs > 0 then
            local last = msgs[#msgs]
            local prefix = last.sender == "me" and "You: " or ""
            local preview = prefix .. last.text
            if #preview > 22 then preview = preview:sub(1, 22) .. "..." end
            if ns.ReplaceEmoji then
                preview = ns.ReplaceEmoji(preview, 14)
            end
            if Emojis and Emojis.ReplaceEmojiToIcon then
                preview = Emojis.ReplaceEmojiToIcon(preview, 14)
            end
            entry.previewText:SetText(preview)
            entry.timeText:SetText(ns.FormatTimestamp(last.time))
        else
            entry.previewText:SetText("")
            entry.timeText:SetText("")
        end

        -- Unread badge
        if (data.convo.unread or 0) > 0 then
            entry.unreadBadge:Show()
            entry.unreadCount:SetText(tostring(data.convo.unread))
        else
            entry.unreadBadge:Hide()
        end

        -- Highlight active
        if ns.activeConversation == data.name then
            entry.bg:SetColorTexture(unpack(C.ACTIVE))
        else
            entry.bg:SetColorTexture(0, 0, 0, 0)
        end

        -- Reposition
        entry:ClearAllPoints()
        entry:SetPoint("TOPLEFT", ns.convoScrollChild, "TOPLEFT", 0, -(i - 1) * ENTRY_HEIGHT)
        entry:SetPoint("RIGHT", ns.convoScrollChild, "RIGHT")
        entry:Show()
    end

    -- Hide extra entries
    for i = #sorted + 1, #ns.convoEntries do
        ns.convoEntries[i]:Hide()
    end

    -- Update scroll child height
    ns.convoScrollChild:SetHeight(math.max(#sorted * ENTRY_HEIGHT, 1))
end

---------------------------------------------------------------------------
-- Update Header Buttons (friend / block state)
---------------------------------------------------------------------------
function ns.UpdateHeaderButtons()
    local name = ns.activeConversation
    if not name then
        if ns.friendBtn then ns.friendBtn:Hide() end
        if ns.blockBtn then ns.blockBtn:Hide() end
        return
    end

    -- Friend button: show "Add Friend" or "Friend" (muted, non-clickable)
    if ns.IsFriend(name) then
        ns.friendText:SetText("Friend")
        ns.friendText:SetTextColor(0.4, 0.4, 0.4)
        ns.friendBtn:SetScript("OnEnter", nil)
        ns.friendBtn:SetScript("OnLeave", nil)
        ns.friendBtn:SetScript("OnClick", nil)
    else
        ns.friendText:SetText("Add Friend")
        ns.friendText:SetTextColor(unpack(C.BLUE))
        ns.friendBtn:SetScript("OnEnter", function() ns.friendText:SetTextColor(1, 1, 1) end)
        ns.friendBtn:SetScript("OnLeave", function() ns.friendText:SetTextColor(unpack(C.BLUE)) end)
        ns.friendBtn:SetScript("OnClick", function()
            if not ns.activeConversation then return end
            C_FriendList.AddFriend(ns.activeConversation)
            C_Timer.After(0.2, function()
                ns:FRIENDLIST_UPDATE()
                ns.UpdateHeaderButtons()
            end)
        end)
    end
    ns.friendBtn:Show()

    -- Block button: toggle between Block / Unblock
    if ns.IsIgnored(name) then
        ns.blockText:SetText("Unblock")
        ns.blockText:SetTextColor(0.5, 0.5, 0.5)
    else
        ns.blockText:SetText("Block")
        ns.blockText:SetTextColor(0.8, 0.25, 0.2)
    end
    ns.blockBtn:Show()
end

---------------------------------------------------------------------------
-- Select Conversation
---------------------------------------------------------------------------
function ns.SelectConversation(playerName)
    ns.activeConversation = playerName
    ns.headerName:SetText(playerName)

    -- Hide empty state
    if ns.emptyText then ns.emptyText:Hide() end

    -- Clear unread
    local convo = ns.db.conversations[playerName]
    if convo then convo.unread = 0 end

    -- Cancel fade — user is interacting
    ns.CancelFade()

    -- Update header buttons (friend/block state)
    ns.UpdateHeaderButtons()

    -- Rebuild
    ns.RebuildBubbles(playerName)
    ns.ScrollToBottom()
    ns.RefreshConversationList()

    -- Focus input
    ns.inputBox:SetFocus()
end

---------------------------------------------------------------------------
-- Minimize / Restore
---------------------------------------------------------------------------
ns.isMinimized = false
ns.savedHeight = nil

function ns.ToggleMinimize()
    local win = ns.mainWindow
    if not win then return end

    if ns.isMinimized then
        -- Restore
        win:SetHeight(ns.savedHeight or 550)
        win:SetResizable(true)
        if ns.leftPanel then ns.leftPanel:Show() end
        if ns.rightPanel then ns.rightPanel:Show() end
        ns.minTex:SetText("-")
        ns.isMinimized = false
    else
        -- Minimize to title bar only
        ns.savedHeight = win:GetHeight()
        win:SetResizable(false)
        if ns.leftPanel then ns.leftPanel:Hide() end
        if ns.rightPanel then ns.rightPanel:Hide() end
        win:SetHeight(30)
        ns.minTex:SetText("+")
        ns.isMinimized = true
    end
end

---------------------------------------------------------------------------
-- Auto-Fade (fades when mouse leaves, restores on hover/new whisper)
---------------------------------------------------------------------------
local FADE_DELAY = 1.5      -- seconds after mouse leaves before fading
local FADE_ALPHA = 0.25     -- target alpha when faded
local FADE_IN_SPEED = 0.15  -- seconds to fade in
local FADE_OUT_SPEED = 0.4  -- seconds to fade out

ns.isFaded = false
ns.fadeTimer = nil

-- Schedule a fade-out after a short delay
local function ScheduleFadeOut()
    if ns.fadeTimer then
        ns.fadeTimer:Cancel()
    end
    ns.fadeTimer = C_Timer.NewTimer(FADE_DELAY, function()
        ns.fadeTimer = nil
        -- Don't fade while interacting with settings or emoji picker
        if ns.settingsPanel and ns.settingsPanel:IsShown() then return end
        if ns.emojiPicker and ns.emojiPicker:IsShown() then return end
        if ns.mainWindow and ns.mainWindow:IsShown() then
            UIFrameFadeOut(ns.mainWindow, FADE_OUT_SPEED, ns.mainWindow:GetAlpha(), FADE_ALPHA)
            ns.isFaded = true
        end
    end)
end

-- Hook mouse enter/leave on the main window (called once during init)
function ns.SetupFadeHooks()
    if ns.fadeHooked then return end

    ns.mainWindow:HookScript("OnEnter", function()
        -- Cancel pending fade and restore full opacity
        if ns.fadeTimer then
            ns.fadeTimer:Cancel()
            ns.fadeTimer = nil
        end
        if ns.isFaded then
            UIFrameFadeIn(ns.mainWindow, FADE_IN_SPEED, ns.mainWindow:GetAlpha(), 1.0)
            ns.isFaded = false
        end
    end)

    ns.mainWindow:HookScript("OnLeave", function()
        -- Start fade timer when mouse leaves
        if ns.mainWindow:IsShown() then
            ScheduleFadeOut()
        end
    end)

    ns.mainWindow:HookScript("OnShow", function()
        -- Start visible, schedule fade
        ns.mainWindow:SetAlpha(1.0)
        ns.isFaded = false
        ScheduleFadeOut()
    end)

    ns.mainWindow:HookScript("OnHide", function()
        -- Clean up on hide
        if ns.fadeTimer then
            ns.fadeTimer:Cancel()
            ns.fadeTimer = nil
        end
        ns.isFaded = false
        ns.mainWindow:SetAlpha(1.0)
    end)

    ns.fadeHooked = true
end

-- Flash to full opacity briefly (e.g. on new whisper)
function ns.FlashWindow()
    if not ns.mainWindow or not ns.mainWindow:IsShown() then return end
    if ns.fadeTimer then
        ns.fadeTimer:Cancel()
        ns.fadeTimer = nil
    end
    UIFrameFadeIn(ns.mainWindow, FADE_IN_SPEED, ns.mainWindow:GetAlpha(), 1.0)
    ns.isFaded = false
    ScheduleFadeOut()
end

-- Legacy compat — StartFade/CancelFade still work
function ns.StartFade()
    ScheduleFadeOut()
end

function ns.CancelFade()
    if ns.fadeTimer then
        ns.fadeTimer:Cancel()
        ns.fadeTimer = nil
    end
    ns.isFaded = false
    if ns.mainWindow then
        UIFrameFadeRemoveFrame(ns.mainWindow)
        ns.mainWindow:SetAlpha(1.0)
    end
end

---------------------------------------------------------------------------
-- Compose New Chat
---------------------------------------------------------------------------
function ns.ToggleCompose()
    if ns.composeBar and ns.composeBar:IsShown() then
        ns.composeBar:Hide()
        return
    end

    -- Create compose bar on first use
    if not ns.composeBar then
        local bar = CreateFrame("Frame", nil, ns.mainWindow, "BackdropTemplate")
        bar:SetHeight(32)
        bar:SetPoint("TOPLEFT", ns.titleBar, "BOTTOMLEFT", LEFT_WIDTH + 1, 0)
        bar:SetPoint("TOPRIGHT", ns.titleBar, "BOTTOMRIGHT", 0, 0)
        bar:SetFrameLevel(ns.mainWindow:GetFrameLevel() + 10)

        bar:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        bar:SetBackdropColor(0.08, 0.08, 0.08, 1)
        bar:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

        local toLabel = bar:CreateFontString(nil, "OVERLAY")
        toLabel:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
        toLabel:SetTextColor(unpack(C.TEXT_GRAY))
        toLabel:SetPoint("LEFT", 8, 0)
        toLabel:SetText("To:")

        local nameBox = CreateFrame("EditBox", "iChatComposeInput", bar)
        nameBox:SetPoint("LEFT", toLabel, "RIGHT", 6, 0)
        nameBox:SetPoint("RIGHT", -8, 0)
        nameBox:SetHeight(20)
        nameBox:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
        nameBox:SetTextColor(1, 1, 1)
        nameBox:SetAutoFocus(false)
        nameBox:SetMaxLetters(50)

        nameBox:SetScript("OnEnterPressed", function(self)
            local name = self:GetText():match("^%s*(.-)%s*$")
            if name and name ~= "" then
                -- Capitalize first letter
                name = name:sub(1, 1):upper() .. name:sub(2):lower()

                -- Create or select conversation
                if not ns.db.conversations[name] then
                    ns.db.conversations[name] = {
                        messages = {},
                        unread = 0,
                        lastActivity = time(),
                    }
                end
                ns.SelectConversation(name)
                ns.RefreshConversationList()
                self:SetText("")
                bar:Hide()
            end
        end)
        nameBox:SetScript("OnEscapePressed", function(self)
            self:SetText("")
            bar:Hide()
        end)

        ns.composeBar = bar
        ns.composeInput = nameBox
    end

    ns.composeBar:Show()
    ns.composeInput:SetText("")
    ns.composeInput:SetFocus()
end
