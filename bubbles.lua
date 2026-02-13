local _, ns = ...

local C = ns.C

-- Bubble settings
local BUBBLE_MAX_WIDTH_RATIO = 0.65
local BUBBLE_PADDING_H = 14
local BUBBLE_PADDING_V = 8
local BUBBLE_MARGIN = 4
local TIMESTAMP_HEIGHT = 14
local CORNER_SIZE = 14

-- Frame pool
local bubblePool = {}
ns.activeBubbles = {}

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
    table.insert(bubblePool, bubble)
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
    bubble.timeText:SetText(ns.FormatTimestamp(entry.time))

    bubble:Show()

    return bubbleHeight + TIMESTAMP_HEIGHT + BUBBLE_MARGIN
end

---------------------------------------------------------------------------
-- Rebuild All Bubbles
---------------------------------------------------------------------------
function ns.RebuildBubbles(playerName)
    for _, bubble in ipairs(ns.activeBubbles) do
        ReleaseBubble(bubble)
    end
    wipe(ns.activeBubbles)

    local convo = ns.db.conversations[playerName]
    if not convo or not convo.messages then return end

    local chatWidth = ns.chatScrollChild:GetWidth()
    if chatWidth <= 0 then chatWidth = 300 end

    local yOffset = 8

    for _, entry in ipairs(convo.messages) do
        local bubble = AcquireBubble(ns.chatScrollChild)
        local height = LayoutBubble(bubble, entry, chatWidth, yOffset)
        table.insert(ns.activeBubbles, bubble)
        yOffset = yOffset + height
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

    local yOffset = 8
    for _, b in ipairs(ns.activeBubbles) do
        local bh = b:GetHeight()
        yOffset = yOffset + bh + TIMESTAMP_HEIGHT + BUBBLE_MARGIN
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
