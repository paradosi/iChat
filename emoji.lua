local _, ns = ...

---------------------------------------------------------------------------
-- Built-in Emoji — shortcode to texture replacement
-- Type :shortcode: in messages and they render as inline icons
---------------------------------------------------------------------------

local EMOJI_PATH = "Interface\\AddOns\\iChat\\media\\emoji\\"

-- All available emoji shortcodes
local EMOJI_LIST = {
    -- Smileys
    "grin", "smile", "laughing", "sweat_smile", "rofl", "joy",
    "wink", "blush", "innocent", "heart_eyes", "star_struck", "kiss",
    "yum", "sunglasses", "thinking", "shush", "neutral", "roll_eyes",
    "smirk", "unamused", "pensive", "cry", "sob", "angry", "rage",
    "scream", "skull", "sleeping", "sick", "vomit", "clown", "nerd",
    "pleading", "party",
    -- Gestures
    "thumbsup", "thumbsdown", "wave", "pray", "muscle", "clap",
    "ok_hand", "point_up", "middle_finger", "raised_fist",
    -- Hearts & Symbols
    "heart", "broken_heart", "fire", "star", "100", "check", "x",
    "warning", "question", "exclamation", "zzz", "sparkles", "boom",
    "poop", "eyes",
    -- Objects & Activities
    "swords", "shield", "moneybag", "tada", "game", "trophy",
    "crown", "gem", "beer", "skull_bones", "ghost", "dragon", "wolf",
    -- Misc
    "arrow_up", "arrow_down", "rocket", "hourglass",
}

-- Build lookup set for fast matching
local EMOJI_SET = {}
for _, name in ipairs(EMOJI_LIST) do
    EMOJI_SET[name] = true
end

-- Replace :shortcode: patterns with inline textures
function ns.ReplaceEmoji(text, iconSize)
    if not text then return text end
    iconSize = iconSize or 14

    return text:gsub(":([%w_]+):", function(code)
        if EMOJI_SET[code] then
            return "|T" .. EMOJI_PATH .. code .. ".png:" .. iconSize .. "|t"
        end
        return ":" .. code .. ":"
    end)
end

-- Get sorted list of all emoji names (for display)
function ns.GetEmojiList()
    return EMOJI_LIST
end

---------------------------------------------------------------------------
-- Emoji Picker Panel
---------------------------------------------------------------------------
local PICKER_COLS = 8
local PICKER_CELL = 36
local PICKER_PAD = 8

function ns.CreateEmojiPicker(parent)
    local rows = math.ceil(#EMOJI_LIST / PICKER_COLS)
    local width = PICKER_COLS * PICKER_CELL + PICKER_PAD * 2
    local height = rows * PICKER_CELL + PICKER_PAD * 2

    -- Click-off backdrop (transparent screen-wide button to close on outside click)
    local clickOff = CreateFrame("Button", nil, UIParent)
    clickOff:SetAllPoints(UIParent)
    clickOff:SetFrameStrata("TOOLTIP")
    clickOff:SetFrameLevel(0)
    clickOff:RegisterForClicks("AnyUp")
    clickOff:SetScript("OnClick", function()
        ns.emojiPicker:Hide()
    end)
    clickOff:Hide()
    ns.emojiClickOff = clickOff

    local picker = CreateFrame("Frame", "iChatEmojiPicker", parent, "BackdropTemplate")
    picker:SetFrameStrata("TOOLTIP")
    picker:SetFrameLevel(10)
    picker:SetSize(width, height)
    picker:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    picker:SetBackdropColor(0.08, 0.08, 0.08, 0.97)
    picker:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)

    for i, name in ipairs(EMOJI_LIST) do
        local row = math.floor((i - 1) / PICKER_COLS)
        local col = (i - 1) % PICKER_COLS

        local btn = CreateFrame("Button", nil, picker)
        btn:SetSize(PICKER_CELL, PICKER_CELL)
        btn:SetPoint("TOPLEFT", PICKER_PAD + col * PICKER_CELL, -(PICKER_PAD + row * PICKER_CELL))

        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetSize(PICKER_CELL - 4, PICKER_CELL - 4)
        icon:SetPoint("CENTER")
        icon:SetTexture(EMOJI_PATH .. name .. ".png")

        local hl = btn:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(1, 1, 1, 0.12)

        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(":" .. name .. ":")
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        btn:SetScript("OnClick", function()
            if ns.inputBox then
                ns.inputBox:Insert(":" .. name .. ":")
                ns.inputBox:SetFocus()
            end
            picker:Hide()
        end)
    end

    picker:SetScript("OnShow", function() clickOff:Show() end)
    picker:SetScript("OnHide", function() clickOff:Hide() end)

    picker:Hide()
    ns.emojiPicker = picker
    return picker
end

function ns.ToggleEmojiPicker()
    if not ns.emojiPicker then return end
    if ns.emojiPicker:IsShown() then
        ns.emojiPicker:Hide()
    else
        ns.emojiPicker:Show()
    end
end

-- Print all available emoji to chat
function ns.PrintEmojiList()
    DEFAULT_CHAT_FRAME:AddMessage("|cff007AFFiChat|r emoji — type :name: to use:")
    local line = ""
    for i, name in ipairs(EMOJI_LIST) do
        local icon = "|T" .. EMOJI_PATH .. name .. ".png:14|t"
        local entry = icon .. " :" .. name .. ":"
        if line == "" then
            line = "  " .. entry
        else
            line = line .. "   " .. entry
        end
        if i % 4 == 0 then
            DEFAULT_CHAT_FRAME:AddMessage(line)
            line = ""
        end
    end
    if line ~= "" then
        DEFAULT_CHAT_FRAME:AddMessage(line)
    end
end
