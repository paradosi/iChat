local _, ns = ...

local C = ns.C

-- Bubble settings
local BUBBLE_MAX_WIDTH_RATIO = 0.65
local BUBBLE_PADDING_H = 14
local BUBBLE_PADDING_V = 8
local BUBBLE_MARGIN = 4
local TIMESTAMP_HEIGHT = 14
local CORNER_SIZE = 14
local SEPARATOR_HEIGHT = 24

-- Frame pools
local bubblePool = {}
local separatorPool = {}
ns.activeBubbles = {}
ns.activeSeparators = {}

local PILL_TEXTURE = "Interface\\AddOns\\iChat\\media\\textures\\pill"

---------------------------------------------------------------------------
-- Bubble Frame (9-slice: 4 quarter-circle corners + 3 solid fills)
---------------------------------------------------------------------------
local function SetBubbleColor(bubble, r, g, b, a)
    for _, tex in ipairs(bubble.parts) do
        tex:SetVertexColor(r, g, b, a)
    end
end

local function CreateBubbleFrame(parent)
    local bubble = CreateFrame("Frame", nil, parent)
    bubble.parts = {}
    bubble:EnableMouse(true)

    local function AddPart(tex)
        table.insert(bubble.parts, tex)
        return tex
    end

    -- 4 corners (quarter-circles from the pill circle texture)
    local tl = AddPart(bubble:CreateTexture(nil, "BACKGROUND"))
    tl:SetTexture(PILL_TEXTURE)
    tl:SetTexCoord(0, 0.5, 0, 0.5)
    tl:SetSize(CORNER_SIZE, CORNER_SIZE)
    tl:SetPoint("TOPLEFT")

    local tr = AddPart(bubble:CreateTexture(nil, "BACKGROUND"))
    tr:SetTexture(PILL_TEXTURE)
    tr:SetTexCoord(0.5, 1, 0, 0.5)
    tr:SetSize(CORNER_SIZE, CORNER_SIZE)
    tr:SetPoint("TOPRIGHT")

    local bl = AddPart(bubble:CreateTexture(nil, "BACKGROUND"))
    bl:SetTexture(PILL_TEXTURE)
    bl:SetTexCoord(0, 0.5, 0.5, 1)
    bl:SetSize(CORNER_SIZE, CORNER_SIZE)
    bl:SetPoint("BOTTOMLEFT")

    local br = AddPart(bubble:CreateTexture(nil, "BACKGROUND"))
    br:SetTexture(PILL_TEXTURE)
    br:SetTexCoord(0.5, 1, 0.5, 1)
    br:SetSize(CORNER_SIZE, CORNER_SIZE)
    br:SetPoint("BOTTOMRIGHT")

    -- Top edge fill (between top corners)
    local topFill = AddPart(bubble:CreateTexture(nil, "BACKGROUND"))
    topFill:SetTexture(PILL_TEXTURE)
    topFill:SetTexCoord(0.49, 0.51, 0.49, 0.51)
    topFill:SetPoint("TOPLEFT", tl, "TOPRIGHT")
    topFill:SetPoint("BOTTOMRIGHT", tr, "BOTTOMLEFT")

    -- Bottom edge fill (between bottom corners)
    local botFill = AddPart(bubble:CreateTexture(nil, "BACKGROUND"))
    botFill:SetTexture(PILL_TEXTURE)
    botFill:SetTexCoord(0.49, 0.51, 0.49, 0.51)
    botFill:SetPoint("TOPLEFT", bl, "TOPRIGHT")
    botFill:SetPoint("BOTTOMRIGHT", br, "BOTTOMLEFT")

    -- Middle fill (full width, between corner rows)
    local midFill = AddPart(bubble:CreateTexture(nil, "BACKGROUND"))
    midFill:SetTexture(PILL_TEXTURE)
    midFill:SetTexCoord(0.49, 0.51, 0.49, 0.51)
    midFill:SetPoint("TOPLEFT", tl, "BOTTOMLEFT")
    midFill:SetPoint("BOTTOMRIGHT", br, "TOPRIGHT")

    -- Message text
    local msgText = bubble:CreateFontString(nil, "OVERLAY")
    msgText:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    msgText:SetTextColor(1, 1, 1)
    msgText:SetJustifyH("LEFT")
    msgText:SetJustifyV("TOP")
    msgText:SetWordWrap(true)
    bubble.msgText = msgText

    -- Timestamp
    local timeText = bubble:CreateFontString(nil, "OVERLAY")
    timeText:SetFont("Fonts\\FRIZQT__.TTF", 8, "")
    timeText:SetTextColor(0.45, 0.45, 0.45)
    bubble.timeText = timeText

    -- Item link support
    bubble:SetHyperlinksEnabled(true)
    bubble:SetScript("OnHyperlinkEnter", function(self, link)
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
        GameTooltip:SetHyperlink(link)
        GameTooltip:Show()
    end)
    bubble:SetScript("OnHyperlinkLeave", function()
        GameTooltip:Hide()
    end)
    bubble:SetScript("OnHyperlinkClick", function(self, link, text, button)
        ChatFrame_OnHyperlinkShow(ChatFrame1, link, text, button)
    end)

    bubble.SetBubbleColor = SetBubbleColor
    bubble:Hide()
    return bubble
end

local function AcquireBubble(parent)
    local bubble = table.remove(bubblePool)
    if not bubble then
        bubble = CreateBubbleFrame(parent)
    else
        bubble:SetParent(parent)
    end
    return bubble
end

local function ReleaseBubble(bubble)
    bubble:Hide()
    bubble:ClearAllPoints()
    bubble:SetScript("OnEnter", nil)
    bubble:SetScript("OnLeave", nil)
    bubble:SetScript("OnMouseUp", nil)
    bubble._rawText = nil
    table.insert(bubblePool, bubble)
end

---------------------------------------------------------------------------
-- Separator Frame (date separators + unread separator)
---------------------------------------------------------------------------
local function CreateSeparatorFrame(parent)
    local sep = CreateFrame("Frame", nil, parent)
    sep:SetHeight(SEPARATOR_HEIGHT)

    local leftLine = sep:CreateTexture(nil, "ARTWORK")
    leftLine:SetHeight(1)
    leftLine:SetPoint("LEFT", 16, 0)
    leftLine:SetColorTexture(0.25, 0.25, 0.25, 1)
    sep.leftLine = leftLine

    local text = sep:CreateFontString(nil, "OVERLAY")
    text:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    text:SetTextColor(0.45, 0.45, 0.45)
    text:SetPoint("CENTER")
    sep.text = text

    local rightLine = sep:CreateTexture(nil, "ARTWORK")
    rightLine:SetHeight(1)
    rightLine:SetPoint("RIGHT", -16, 0)
    rightLine:SetColorTexture(0.25, 0.25, 0.25, 1)
    sep.rightLine = rightLine

    -- Lines extend from edges to text
    leftLine:SetPoint("RIGHT", text, "LEFT", -8, 0)
    rightLine:SetPoint("LEFT", text, "RIGHT", 8, 0)

    sep:Hide()
    return sep
end

local function AcquireSeparator(parent)
    local sep = table.remove(separatorPool)
    if not sep then
        sep = CreateSeparatorFrame(parent)
    else
        sep:SetParent(parent)
    end
    return sep
end

local function ReleaseSeparator(sep)
    sep:Hide()
    sep:ClearAllPoints()
    table.insert(separatorPool, sep)
end

---------------------------------------------------------------------------
-- Date Formatting for Separators
---------------------------------------------------------------------------
local function GetDateLabel(timestamp)
    local msgDate = date("*t", timestamp)
    local today = date("*t", time())

    if msgDate.year == today.year and msgDate.yday == today.yday then
        return "Today"
    end

    local yesterday = date("*t", time() - 86400)
    if msgDate.year == yesterday.year and msgDate.yday == yesterday.yday then
        return "Yesterday"
    end

    return date("%b %d", timestamp)
end

local function IsSameDay(t1, t2)
    if not t1 or not t2 then return false end
    local d1 = date("*t", t1)
    local d2 = date("*t", t2)
    return d1.year == d2.year and d1.yday == d2.yday
end

---------------------------------------------------------------------------
-- Timestamp Formatting
---------------------------------------------------------------------------
function ns.FormatTimestamp(timestamp)
    if not timestamp then return "" end
    local diff = time() - timestamp

    if diff < 60 then
        return "now"
    elseif diff < 3600 then
        return math.floor(diff / 60) .. "m"
    elseif diff < 86400 then
        return math.floor(diff / 3600) .. "h"
    else
        return date("%m/%d %H:%M", timestamp)
    end
end

---------------------------------------------------------------------------
-- Layout a Single Bubble
---------------------------------------------------------------------------
local function LayoutBubble(bubble, entry, chatWidth, yOffset)
    local maxTextWidth = chatWidth * BUBBLE_MAX_WIDTH_RATIO - (BUBBLE_PADDING_H * 2)
    if maxTextWidth < 50 then maxTextWidth = 50 end

    -- Apply font from settings
    local font = ns.db.settings.font or "Fonts\\FRIZQT__.TTF"
    local fontSize = ns.db.settings.fontSize or 11
    bubble.msgText:SetFont(font, fontSize, "")
    bubble.timeText:SetFont(font, math.max(fontSize - 3, 7), "")

    -- Process emoji: built-in shortcodes first, then Emoji-Core if available
    local displayText = entry.text
    local emojiSize = fontSize + 5
    if ns.ReplaceEmoji then
        displayText = ns.ReplaceEmoji(displayText, emojiSize)
    end
    if Emojis and Emojis.ReplaceEmojiToIcon then
        displayText = Emojis.ReplaceEmojiToIcon(displayText, emojiSize)
    end

    -- Measure text
    bubble.msgText:SetWidth(maxTextWidth)
    bubble.msgText:SetText(displayText)

    local textWidth = math.min(bubble.msgText:GetStringWidth(), maxTextWidth)
    local textHeight = bubble.msgText:GetStringHeight()

    local bubbleWidth = textWidth + (BUBBLE_PADDING_H * 2)
    local bubbleHeight = textHeight + (BUBBLE_PADDING_V * 2)

    -- Ensure minimum size so corners don't overlap
    bubbleWidth = math.max(bubbleWidth, CORNER_SIZE * 2 + 2)
    bubbleHeight = math.max(bubbleHeight, CORNER_SIZE * 2 + 2)

    bubble:SetSize(bubbleWidth, bubbleHeight)

    -- Position text inside bubble
    bubble.msgText:ClearAllPoints()
    bubble.msgText:SetPoint("TOPLEFT", bubble, "TOPLEFT", BUBBLE_PADDING_H, -BUBBLE_PADDING_V)
    bubble.msgText:SetWidth(maxTextWidth)

    -- Color and alignment
    if entry.sender == "me" then
        bubble:SetBubbleColor(0.00, 0.48, 1.00, 0.9)
        bubble:ClearAllPoints()
        bubble:SetPoint("TOPRIGHT", ns.chatScrollChild, "TOPRIGHT", -8, -yOffset)
        bubble.timeText:ClearAllPoints()
        bubble.timeText:SetPoint("TOPRIGHT", bubble, "BOTTOMRIGHT", 0, -1)
        bubble.timeText:SetJustifyH("RIGHT")
    else
        if entry.isFriend then
            bubble:SetBubbleColor(0.00, 0.40, 0.85, 0.85)
        else
            bubble:SetBubbleColor(0.20, 0.78, 0.35, 0.9)
        end
        bubble:ClearAllPoints()
        bubble:SetPoint("TOPLEFT", ns.chatScrollChild, "TOPLEFT", 8, -yOffset)
        bubble.timeText:ClearAllPoints()
        bubble.timeText:SetPoint("TOPLEFT", bubble, "BOTTOMLEFT", 0, -1)
        bubble.timeText:SetJustifyH("LEFT")
    end

    -- Timestamp
    local relativeTime = ns.FormatTimestamp(entry.time)
    bubble.timeText:SetText(relativeTime)

    -- Store raw text for copy
    bubble._rawText = entry.text

    -- Right-click to copy message
    bubble:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" and self._rawText and ns.ShowCopyPopup then
            ns.ShowCopyPopup(self._rawText, "Copy Message")
        end
    end)

    -- Hover to show exact timestamp
    if ns.db.settings.showTimestampOnHover then
        bubble._entryTime = entry.time
        bubble._relativeTime = relativeTime
        bubble:SetScript("OnEnter", function(self)
            if self._entryTime then
                self.timeText:SetText(date("%I:%M:%S %p", self._entryTime))
                self.timeText:SetTextColor(0.6, 0.6, 0.6)
            end
        end)
        bubble:SetScript("OnLeave", function(self)
            self.timeText:SetText(self._relativeTime or "")
            self.timeText:SetTextColor(0.45, 0.45, 0.45)
        end)
    else
        bubble:SetScript("OnEnter", nil)
        bubble:SetScript("OnLeave", nil)
    end

    bubble:Show()

    return bubbleHeight + TIMESTAMP_HEIGHT + BUBBLE_MARGIN
end

---------------------------------------------------------------------------
-- Layout an Unread Separator
---------------------------------------------------------------------------
local function LayoutUnreadSeparator(parent, chatWidth, yOffset)
    local sep = AcquireSeparator(parent)
    sep:ClearAllPoints()
    sep:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -yOffset)
    sep:SetPoint("RIGHT", parent, "RIGHT")
    sep.text:SetText("New Messages")
    sep.text:SetTextColor(0.0, 0.48, 1.0)
    sep.leftLine:SetColorTexture(0.0, 0.48, 1.0, 0.5)
    sep.rightLine:SetColorTexture(0.0, 0.48, 1.0, 0.5)
    sep:Show()
    return sep
end

---------------------------------------------------------------------------
-- Layout a Date Separator
---------------------------------------------------------------------------
local function LayoutDateSeparator(parent, chatWidth, yOffset, timestamp)
    local sep = AcquireSeparator(parent)
    sep:ClearAllPoints()
    sep:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -yOffset)
    sep:SetPoint("RIGHT", parent, "RIGHT")
    sep.text:SetText(GetDateLabel(timestamp))
    sep.text:SetTextColor(0.45, 0.45, 0.45)
    sep.leftLine:SetColorTexture(0.25, 0.25, 0.25, 1)
    sep.rightLine:SetColorTexture(0.25, 0.25, 0.25, 1)
    sep:Show()
    return sep
end

---------------------------------------------------------------------------
-- Rebuild All Bubbles
---------------------------------------------------------------------------
function ns.RebuildBubbles(playerName)
    for _, bubble in ipairs(ns.activeBubbles) do
        ReleaseBubble(bubble)
    end
    wipe(ns.activeBubbles)

    for _, sep in ipairs(ns.activeSeparators) do
        ReleaseSeparator(sep)
    end
    wipe(ns.activeSeparators)

    local convo = ns.db.conversations[playerName]
    if not convo or not convo.messages then return end

    local chatWidth = ns.chatScrollChild:GetWidth()
    if chatWidth <= 0 then chatWidth = 300 end

    local yOffset = 8
    local prevTime = nil
    local showDateSep = ns.db.settings.showDateSeparators
    local unreadSepIndex = convo.unreadSepIndex

    for i, entry in ipairs(convo.messages) do
        -- Date separator
        if showDateSep and entry.time then
            if not prevTime or not IsSameDay(prevTime, entry.time) then
                local sep = LayoutDateSeparator(ns.chatScrollChild, chatWidth, yOffset, entry.time)
                table.insert(ns.activeSeparators, sep)
                yOffset = yOffset + SEPARATOR_HEIGHT
            end
        end

        -- Unread separator (before first unread message)
        if unreadSepIndex and i == unreadSepIndex then
            local sep = LayoutUnreadSeparator(ns.chatScrollChild, chatWidth, yOffset)
            table.insert(ns.activeSeparators, sep)
            yOffset = yOffset + SEPARATOR_HEIGHT
        end

        local bubble = AcquireBubble(ns.chatScrollChild)
        local height = LayoutBubble(bubble, entry, chatWidth, yOffset)
        table.insert(ns.activeBubbles, bubble)
        yOffset = yOffset + height
        prevTime = entry.time
    end

    local scrollHeight = ns.chatScrollFrame:GetHeight()
    ns.chatScrollChild:SetHeight(math.max(yOffset + 8, scrollHeight))
end

---------------------------------------------------------------------------
-- Add Single Bubble (Append)
---------------------------------------------------------------------------
function ns.AddBubble(entry, playerName)
    if ns.activeConversation ~= playerName then return end

    local chatWidth = ns.chatScrollChild:GetWidth()
    if chatWidth <= 0 then chatWidth = 300 end

    -- Calculate current yOffset from existing elements
    local yOffset = 8
    for _, b in ipairs(ns.activeBubbles) do
        local bh = b:GetHeight()
        yOffset = yOffset + bh + TIMESTAMP_HEIGHT + BUBBLE_MARGIN
    end
    for _, s in ipairs(ns.activeSeparators) do
        yOffset = yOffset + SEPARATOR_HEIGHT
    end

    -- Check if we need a date separator
    local showDateSep = ns.db.settings.showDateSeparators
    if showDateSep and entry.time then
        local convo = ns.db.conversations[playerName]
        if convo and convo.messages and #convo.messages > 1 then
            local prevEntry = convo.messages[#convo.messages - 1]
            if prevEntry and not IsSameDay(prevEntry.time, entry.time) then
                local sep = LayoutDateSeparator(ns.chatScrollChild, chatWidth, yOffset, entry.time)
                table.insert(ns.activeSeparators, sep)
                yOffset = yOffset + SEPARATOR_HEIGHT
            end
        end
    end

    local bubble = AcquireBubble(ns.chatScrollChild)
    local height = LayoutBubble(bubble, entry, chatWidth, yOffset)
    table.insert(ns.activeBubbles, bubble)

    local scrollHeight = ns.chatScrollFrame:GetHeight()
    ns.chatScrollChild:SetHeight(math.max(yOffset + height + 8, scrollHeight))
end

---------------------------------------------------------------------------
-- Scroll to Bottom
---------------------------------------------------------------------------
function ns.ScrollToBottom()
    C_Timer.After(0.02, function()
        if not ns.chatScrollFrame then return end
        local maxScroll = math.max(0, ns.chatScrollChild:GetHeight() - ns.chatScrollFrame:GetHeight())
        ns.chatScrollFrame:SetVerticalScroll(maxScroll)
    end)
end
