local _, ns = ...

---------------------------------------------------------------------------
-- UI — Main window, panels, conversation list, compose, context menus,
--       keyboard shortcuts, auto-fade, and copy/note editor popups
--
-- Builds the entire iChat interface:
--   - Title bar with compose, settings, minimize, close buttons
--   - Left panel: searchable, scrollable conversation list with badges
--   - Right panel: chat area (bubbles rendered by bubbles.lua), input bar,
--     emoji button, send button, quick reply bar
--   - Auto-fade system: window fades to 25% opacity when idle
--   - Context menus: pin, mute, note, copy, delete (Retail MenuUtil or
--     Classic EasyMenu depending on client version)
---------------------------------------------------------------------------

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
local PILL_TEXTURE = "Interface\\AddOns\\iChat\\media\\textures\\pill"

-- Portrait logic lives in portraits.lua (ns.CreatePortraitFrame / ns.UpdatePortrait)

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

    -- Set up keyboard shortcuts
    ns.SetupKeyboardShortcuts()
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
    title:SetText("iChat v" .. (ns.version or "?"))

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

    -- Search bar
    local searchBar = CreateFrame("Frame", nil, panel)
    searchBar:SetHeight(24)
    searchBar:SetPoint("TOPLEFT", 4, -4)
    searchBar:SetPoint("TOPRIGHT", -4, -4)

    local searchBg = searchBar:CreateTexture(nil, "BACKGROUND")
    searchBg:SetAllPoints()
    searchBg:SetColorTexture(0.1, 0.1, 0.1, 1)

    local searchBox = CreateFrame("EditBox", "iChatSearchBox", searchBar)
    searchBox:SetPoint("LEFT", 6, 0)
    searchBox:SetPoint("RIGHT", -20, 0)
    searchBox:SetHeight(20)
    searchBox:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    searchBox:SetTextColor(0.8, 0.8, 0.8)
    searchBox:SetAutoFocus(false)
    searchBox:SetMaxLetters(50)

    -- Placeholder text
    local placeholder = searchBox:CreateFontString(nil, "OVERLAY")
    placeholder:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    placeholder:SetTextColor(0.35, 0.35, 0.35)
    placeholder:SetPoint("LEFT", 0, 0)
    placeholder:SetText("Search...")

    searchBox:SetScript("OnTextChanged", function(self)
        local text = self:GetText()
        if text and text ~= "" then
            placeholder:Hide()
        else
            placeholder:Show()
        end
        ns.searchFilter = (text and text ~= "") and text:lower() or nil
        ns.RefreshConversationList()
    end)
    searchBox:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
    end)

    -- Clear button
    local clearBtn = CreateFrame("Button", nil, searchBar)
    clearBtn:SetSize(16, 16)
    clearBtn:SetPoint("RIGHT", -2, 0)
    local clearText = clearBtn:CreateFontString(nil, "OVERLAY")
    clearText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    clearText:SetPoint("CENTER")
    clearText:SetText("x")
    clearText:SetTextColor(0.4, 0.4, 0.4)
    clearBtn:SetScript("OnClick", function()
        searchBox:SetText("")
        searchBox:ClearFocus()
    end)

    ns.searchBox = searchBox
    ns.searchFilter = nil

    -- Scroll frame (below search bar)
    local scroll = CreateFrame("ScrollFrame", "iChatConvoScroll", panel)
    scroll:SetPoint("TOPLEFT", searchBar, "BOTTOMLEFT", -4, -2)
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
    entry:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    local bg = entry:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0)
    entry.bg = bg

    -- Online status dot
    local statusDot = entry:CreateTexture(nil, "OVERLAY")
    statusDot:SetSize(8, 8)
    statusDot:SetPoint("TOPLEFT", 4, -10)
    statusDot:SetTexture(PILL_TEXTURE)
    statusDot:SetVertexColor(0.4, 0.4, 0.4) -- default: gray/offline
    statusDot:Hide()
    entry.statusDot = statusDot

    -- Player name (shifted right if status dot is shown)
    local name = entry:CreateFontString(nil, "OVERLAY")
    name:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    name:SetTextColor(unpack(C.TEXT_WHITE))
    name:SetPoint("TOPLEFT", 14, -8)
    name:SetPoint("RIGHT", -30, 0)
    name:SetJustifyH("LEFT")
    name:SetWordWrap(false)
    entry.nameText = name

    -- Pin icon (small text indicator)
    local pinIcon = entry:CreateFontString(nil, "OVERLAY")
    pinIcon:SetFont("Fonts\\FRIZQT__.TTF", 8, "")
    pinIcon:SetTextColor(0.5, 0.5, 0.5)
    pinIcon:SetPoint("LEFT", name, "RIGHT", 2, 0)
    pinIcon:SetText("")
    pinIcon:Hide()
    entry.pinIcon = pinIcon

    -- Muted icon
    local mutedIcon = entry:CreateFontString(nil, "OVERLAY")
    mutedIcon:SetFont("Fonts\\FRIZQT__.TTF", 8, "")
    mutedIcon:SetTextColor(0.5, 0.5, 0.5)
    mutedIcon:SetPoint("BOTTOMLEFT", 14, 10)
    mutedIcon:SetText("")
    mutedIcon:Hide()
    entry.mutedIcon = mutedIcon

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

    -- Click (left = select, right = context menu)
    entry:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            ns.ShowContextMenu(self.playerName)
        else
            ns.SelectConversation(self.playerName, true)
        end
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
    headerName:SetPoint("LEFT", 10, 2)
    headerName:SetText("")
    ns.headerName = headerName

    -- Contact note (below name in header)
    local headerNote = header:CreateFontString(nil, "OVERLAY")
    headerNote:SetFont("Fonts\\FRIZQT__.TTF", 8, "")
    headerNote:SetTextColor(0.45, 0.45, 0.45)
    headerNote:SetPoint("TOPLEFT", headerName, "BOTTOMLEFT", 0, -1)
    headerNote:SetPoint("RIGHT", -120, 0)
    headerNote:SetJustifyH("LEFT")
    headerNote:SetWordWrap(false)
    headerNote:SetText("")
    ns.headerNote = headerNote

    -- Player portrait (3D model) — logic in portraits.lua
    ns.CreatePortraitFrame(header)

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

    -- Invite button (left of Add Friend)
    local inviteBtn = CreateFrame("Button", nil, header)
    inviteBtn:SetSize(48, 22)
    local inviteText = inviteBtn:CreateFontString(nil, "OVERLAY")
    inviteText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    inviteText:SetPoint("CENTER")
    inviteText:SetText("Invite")
    inviteText:SetTextColor(0.2, 0.78, 0.35)
    inviteBtn:SetScript("OnEnter", function() inviteText:SetTextColor(0.5, 1, 0.6) end)
    inviteBtn:SetScript("OnLeave", function() inviteText:SetTextColor(0.2, 0.78, 0.35) end)
    inviteBtn:SetScript("OnClick", function()
        if not ns.activeConversation then return end
        InviteUnit(ns.activeConversation)
    end)
    inviteBtn:Hide()
    ns.inviteBtn = inviteBtn
    ns.inviteText = inviteText

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

    -- Position inviteBtn now that friendBtn exists
    inviteBtn:SetPoint("RIGHT", friendBtn, "LEFT", -4, 0)

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
    -- Build list with search filter
    local sorted = {}
    local filter = ns.searchFilter
    for name, convo in pairs(ns.db.conversations) do
        local include = true
        if filter then
            -- Match name or message content
            include = name:lower():find(filter, 1, true) ~= nil
            if not include and convo.messages then
                for _, msg in ipairs(convo.messages) do
                    if msg.text and msg.text:lower():find(filter, 1, true) then
                        include = true
                        break
                    end
                end
            end
        end
        if include then
            table.insert(sorted, { name = name, convo = convo })
        end
    end

    -- Sort: pinned first, then by lastActivity descending
    local pinned = ns.db.pinnedConversations or {}
    table.sort(sorted, function(a, b)
        local aPinned = pinned[a.name] and true or false
        local bPinned = pinned[b.name] and true or false
        if aPinned ~= bPinned then return aPinned end
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

        -- Class-colored names
        if ns.db.settings.classColoredNames and ns.classCache then
            local classToken = ns.classCache[data.name:lower()]
            if classToken and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken] then
                local cc = RAID_CLASS_COLORS[classToken]
                entry.nameText:SetTextColor(cc.r, cc.g, cc.b)
            else
                entry.nameText:SetTextColor(unpack(C.TEXT_WHITE))
            end
        else
            entry.nameText:SetTextColor(unpack(C.TEXT_WHITE))
        end

        -- Online status dot
        if ns.db.settings.showOnlineStatus and entry.statusDot then
            local online = ns.onlineCache and ns.onlineCache[data.name:lower()]
            if ns.IsFriend(data.name) then
                entry.statusDot:Show()
                if online then
                    entry.statusDot:SetVertexColor(0.2, 0.8, 0.2) -- green
                else
                    entry.statusDot:SetVertexColor(0.4, 0.4, 0.4) -- gray
                end
            else
                entry.statusDot:Hide()
            end
        elseif entry.statusDot then
            entry.statusDot:Hide()
        end

        -- Pin icon
        if pinned[data.name] and entry.pinIcon then
            entry.pinIcon:SetText("|TInterface\\AddOns\\iChat\\media\\textures\\pill:8|t")
            entry.pinIcon:Show()
        elseif entry.pinIcon then
            entry.pinIcon:Hide()
        end

        -- Muted icon
        if ns.db.mutedContacts and ns.db.mutedContacts[data.name] and entry.mutedIcon then
            entry.mutedIcon:SetText("(muted)")
            entry.mutedIcon:Show()
        elseif entry.mutedIcon then
            entry.mutedIcon:Hide()
        end

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

    -- Store sorted list for keyboard navigation
    ns._sortedConvos = sorted
end

---------------------------------------------------------------------------
-- Update Header Buttons (friend / block state)
---------------------------------------------------------------------------
function ns.UpdateHeaderButtons()
    local name = ns.activeConversation
    if not name then
        if ns.inviteBtn then ns.inviteBtn:Hide() end
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

    -- Invite button: always show when a conversation is open
    if ns.inviteBtn then ns.inviteBtn:Show() end
end

---------------------------------------------------------------------------
-- Select Conversation
---------------------------------------------------------------------------
function ns.SelectConversation(playerName, focusInput)
    ns.activeConversation = playerName
    ns.headerName:SetText(playerName)

    -- Show contact note + relationship tags in header
    if ns.headerNote then
        local note = ns.db.contactNotes and ns.db.contactNotes[playerName] or ""
        local tags = ns.FormatRelationshipTags and ns.FormatRelationshipTags(playerName) or ""
        if note ~= "" and tags ~= "" then
            ns.headerNote:SetText(note .. "  " .. tags)
        elseif tags ~= "" then
            ns.headerNote:SetText(tags)
        else
            ns.headerNote:SetText(note)
        end
    end

    -- Hide empty state
    if ns.emptyText then ns.emptyText:Hide() end

    -- Clear unread and unread separator
    local convo = ns.db.conversations[playerName]
    if convo then
        convo.unread = 0
        convo.unreadSepIndex = nil
    end

    -- Update floating button badge and stop flashing
    if ns.UpdateButtonBadge then
        ns.UpdateButtonBadge()
    end
    if ns.StopFlashButton then
        ns.StopFlashButton()
    end

    -- Cancel fade — user is interacting
    ns.CancelFade()

    -- Update header buttons (friend/block state)
    ns.UpdateHeaderButtons()

    -- Refresh portrait (show 3D model if unit is in range/party)
    ns.UpdatePortrait()

    -- Rebuild
    ns.RebuildBubbles(playerName)
    ns.ScrollToBottom()
    ns.RefreshConversationList()

    -- Focus input only when explicitly requested (e.g. user clicked a conversation)
    if focusInput and not InCombatLockdown() then
        ns.inputBox:SetFocus()
    end
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
                ns.SelectConversation(name, true)
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

---------------------------------------------------------------------------
-- Right-Click Context Menu
---------------------------------------------------------------------------
function ns.ShowContextMenu(playerName)
    if not playerName then return end

    local isPinned = ns.db.pinnedConversations and ns.db.pinnedConversations[playerName]
    local isMuted = ns.db.mutedContacts and ns.db.mutedContacts[playerName]
    local hasNote = ns.db.contactNotes and ns.db.contactNotes[playerName]

    -- Shared action functions
    local function pinFunc()
        if not ns.db.pinnedConversations then ns.db.pinnedConversations = {} end
        if isPinned then
            ns.db.pinnedConversations[playerName] = nil
        else
            ns.db.pinnedConversations[playerName] = true
        end
        ns.RefreshConversationList()
    end

    local function muteFunc()
        if not ns.db.mutedContacts then ns.db.mutedContacts = {} end
        if isMuted then
            ns.db.mutedContacts[playerName] = nil
        else
            ns.db.mutedContacts[playerName] = true
        end
        ns.RefreshConversationList()
    end

    local function noteFunc()
        ns.ShowNoteEditor(playerName)
    end

    local function inviteFunc()
        InviteUnit(playerName)
    end

    local function copyFunc()
        ns.ShowCopyPopup(playerName, "Copy Name")
    end

    local function deleteFunc()
        if ns.activeConversation == playerName then
            ns.activeConversation = nil
            ns.headerName:SetText("")
            if ns.headerNote then ns.headerNote:SetText("") end
            if ns.emptyText then ns.emptyText:Show() end
            for _, bubble in ipairs(ns.activeBubbles) do bubble:Hide() end
            wipe(ns.activeBubbles)
            if ns.activeSeparators then
                for _, sep in ipairs(ns.activeSeparators) do sep:Hide() end
                wipe(ns.activeSeparators)
            end
            ns.UpdateHeaderButtons()
        end
        ns.db.conversations[playerName] = nil
        if ns.db.pinnedConversations then ns.db.pinnedConversations[playerName] = nil end
        if ns.db.contactNotes then ns.db.contactNotes[playerName] = nil end
        if ns.db.mutedContacts then ns.db.mutedContacts[playerName] = nil end
        ns.RefreshConversationList()
    end

    local pinText = isPinned and "Unpin" or "Pin to Top"
    local muteText = isMuted and "Unmute" or "Mute Notifications"
    local noteText = hasNote and "Edit Note" or "Add Note"

    if MenuUtil and MenuUtil.CreateContextMenu then
        -- Retail 11.0+: new context menu API (EasyMenu was removed)
        MenuUtil.CreateContextMenu(UIParent, function(owner, rootDescription)
            rootDescription:CreateButton(pinText, pinFunc)
            rootDescription:CreateButton(muteText, muteFunc)
            rootDescription:CreateButton(noteText, noteFunc)
            rootDescription:CreateButton("Copy Name", copyFunc)
            rootDescription:CreateButton("Invite to Group", inviteFunc)
            rootDescription:CreateButton("|cffcc4444Delete Conversation|r", deleteFunc)
        end)
    else
        -- Classic / TBC / Wrath: use legacy EasyMenu + UIDropDownMenuTemplate
        if not ns.contextMenuFrame then
            ns.contextMenuFrame = CreateFrame("Frame", "iChatContextMenu", UIParent, "UIDropDownMenuTemplate")
        end

        local menuList = {
            { text = pinText, notCheckable = true, func = pinFunc },
            { text = muteText, notCheckable = true, func = muteFunc },
            { text = noteText, notCheckable = true, func = noteFunc },
            { text = "Copy Name", notCheckable = true, func = copyFunc },
            { text = "Invite to Group", notCheckable = true, func = inviteFunc },
            { text = "Delete Conversation", notCheckable = true, colorCode = "|cffcc4444", func = deleteFunc },
        }

        EasyMenu(menuList, ns.contextMenuFrame, "cursor", 0, 0, "MENU")
    end
end

---------------------------------------------------------------------------
-- Contact Note Editor
---------------------------------------------------------------------------
function ns.ShowNoteEditor(playerName)
    if not ns.noteEditorFrame then
        local f = CreateFrame("Frame", "iChatNoteEditor", UIParent, "BackdropTemplate")
        f:SetSize(260, 100)
        f:SetPoint("CENTER")
        f:SetFrameStrata("FULLSCREEN_DIALOG")
        f:SetMovable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)

        f:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        f:SetBackdropColor(0.06, 0.06, 0.06, 0.98)
        f:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

        local title = f:CreateFontString(nil, "OVERLAY")
        title:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
        title:SetTextColor(1, 1, 1)
        title:SetPoint("TOP", 0, -8)
        f._title = title

        local box = CreateFrame("EditBox", nil, f)
        box:SetPoint("TOPLEFT", 10, -28)
        box:SetPoint("RIGHT", -10, 0)
        box:SetHeight(24)
        box:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        box:SetTextColor(0.9, 0.9, 0.9)
        box:SetAutoFocus(true)
        box:SetMaxLetters(100)

        local boxBg = box:CreateTexture(nil, "BACKGROUND")
        boxBg:SetAllPoints()
        boxBg:SetColorTexture(0.1, 0.1, 0.1, 1)

        box:SetScript("OnEnterPressed", function(self)
            local text = self:GetText():match("^%s*(.-)%s*$")
            if not ns.db.contactNotes then ns.db.contactNotes = {} end
            if text and text ~= "" then
                ns.db.contactNotes[f._playerName] = text
            else
                ns.db.contactNotes[f._playerName] = nil
            end
            -- Update header note if viewing this conversation
            if ns.activeConversation == f._playerName and ns.headerNote then
                ns.headerNote:SetText(text or "")
            end
            f:Hide()
        end)
        box:SetScript("OnEscapePressed", function() f:Hide() end)
        f._editBox = box

        -- Save / Cancel buttons
        local saveBtn = CreateFrame("Button", nil, f)
        saveBtn:SetSize(60, 22)
        saveBtn:SetPoint("BOTTOMLEFT", 10, 8)
        local saveBg = saveBtn:CreateTexture(nil, "BACKGROUND")
        saveBg:SetAllPoints()
        saveBg:SetColorTexture(0.0, 0.48, 1.0, 0.3)
        local saveText = saveBtn:CreateFontString(nil, "OVERLAY")
        saveText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        saveText:SetPoint("CENTER")
        saveText:SetText("Save")
        saveText:SetTextColor(1, 1, 1)
        saveBtn:SetScript("OnClick", function()
            box:GetScript("OnEnterPressed")(box)
        end)

        local cancelBtn = CreateFrame("Button", nil, f)
        cancelBtn:SetSize(60, 22)
        cancelBtn:SetPoint("BOTTOMRIGHT", -10, 8)
        local cancelBg = cancelBtn:CreateTexture(nil, "BACKGROUND")
        cancelBg:SetAllPoints()
        cancelBg:SetColorTexture(0.15, 0.15, 0.15, 1)
        local cancelText = cancelBtn:CreateFontString(nil, "OVERLAY")
        cancelText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        cancelText:SetPoint("CENTER")
        cancelText:SetText("Cancel")
        cancelText:SetTextColor(0.7, 0.7, 0.7)
        cancelBtn:SetScript("OnClick", function() f:Hide() end)

        tinsert(UISpecialFrames, "iChatNoteEditor")
        ns.noteEditorFrame = f
    end

    ns.noteEditorFrame._playerName = playerName
    ns.noteEditorFrame._title:SetText("Note for " .. playerName)
    ns.noteEditorFrame._editBox:SetText(ns.db.contactNotes and ns.db.contactNotes[playerName] or "")
    ns.noteEditorFrame:Show()
    ns.noteEditorFrame._editBox:SetFocus()
    ns.noteEditorFrame._editBox:HighlightText()
end

---------------------------------------------------------------------------
-- Copy Text Popup — small EditBox with text pre-selected for Ctrl+C
---------------------------------------------------------------------------
function ns.ShowCopyPopup(text, title)
    if not ns.copyFrame then
        local f = CreateFrame("Frame", "iChatCopyPopup", UIParent, "BackdropTemplate")
        f:SetSize(320, 80)
        f:SetPoint("CENTER")
        f:SetFrameStrata("FULLSCREEN_DIALOG")
        f:SetMovable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)

        f:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        f:SetBackdropColor(0.06, 0.06, 0.06, 0.98)
        f:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

        local ftitle = f:CreateFontString(nil, "OVERLAY")
        ftitle:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        ftitle:SetTextColor(0.6, 0.6, 0.6)
        ftitle:SetPoint("TOP", 0, -8)
        f._title = ftitle

        local hint = f:CreateFontString(nil, "OVERLAY")
        hint:SetFont("Fonts\\FRIZQT__.TTF", 8, "")
        hint:SetTextColor(0.4, 0.4, 0.4)
        hint:SetPoint("BOTTOM", 0, 6)
        hint:SetText("Ctrl+C to copy, Escape to close")

        local box = CreateFrame("EditBox", nil, f)
        box:SetPoint("TOPLEFT", 10, -24)
        box:SetPoint("RIGHT", -10, 0)
        box:SetHeight(24)
        box:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        box:SetTextColor(1, 1, 1)
        box:SetAutoFocus(true)
        box:SetMaxLetters(500)

        local boxBg = box:CreateTexture(nil, "BACKGROUND")
        boxBg:SetAllPoints()
        boxBg:SetColorTexture(0.1, 0.1, 0.1, 1)

        box:SetScript("OnEscapePressed", function() f:Hide() end)
        box:SetScript("OnEnterPressed", function() f:Hide() end)
        -- Prevent editing — reselect on any text change
        box:SetScript("OnTextChanged", function(self, userInput)
            if userInput and self._origText then
                self:SetText(self._origText)
                self:HighlightText()
            end
        end)
        f._editBox = box

        tinsert(UISpecialFrames, "iChatCopyPopup")
        ns.copyFrame = f
    end

    ns.copyFrame._title:SetText(title or "Copy Text")
    ns.copyFrame._editBox._origText = text
    ns.copyFrame._editBox:SetText(text)
    ns.copyFrame:Show()
    ns.copyFrame._editBox:SetFocus()
    ns.copyFrame._editBox:HighlightText()
end

---------------------------------------------------------------------------
-- Keyboard Shortcuts (Tab/Shift+Tab to cycle conversations)
---------------------------------------------------------------------------
function ns.SetupKeyboardShortcuts()
    if not ns.mainWindow then return end

    ns.mainWindow:EnableKeyboard(true)
    ns.mainWindow:SetPropagateKeyboardInput(true)

    ns.mainWindow:HookScript("OnKeyDown", function(self, key)
        if not ns.db.settings.enableKeyboardShortcuts then
            self:SetPropagateKeyboardInput(true)
            return
        end

        if key == "TAB" and not ns.inputBox:HasFocus() then
            self:SetPropagateKeyboardInput(false)
            local sorted = ns._sortedConvos
            if not sorted or #sorted == 0 then return end

            local currentIdx = 0
            for i, data in ipairs(sorted) do
                if data.name == ns.activeConversation then
                    currentIdx = i
                    break
                end
            end

            local nextIdx
            if IsShiftKeyDown() then
                nextIdx = currentIdx > 1 and (currentIdx - 1) or #sorted
            else
                nextIdx = currentIdx < #sorted and (currentIdx + 1) or 1
            end
            ns.SelectConversation(sorted[nextIdx].name, true)
        else
            self:SetPropagateKeyboardInput(true)
        end
    end)
end
