local _, ns = ...

local C = ns.C

-- LibSharedMedia integration (optional)
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

local SOUND_PATH = "Interface\\AddOns\\iChat\\media\\sounds\\"

local BUILTIN_SOUNDS = {
    { name = "Glass", key = "glass", path = SOUND_PATH .. "glass.ogg" },
    { name = "Tritone", key = "tritone", path = SOUND_PATH .. "tritone.ogg" },
    { name = "Chime", key = "chime", path = SOUND_PATH .. "chime.ogg" },
}

local BUILTIN_SOUND_PATHS = {
    glass = SOUND_PATH .. "glass.ogg",
    tritone = SOUND_PATH .. "tritone.ogg",
    chime = SOUND_PATH .. "chime.ogg",
}

local DEFAULT_FONTS = {
    { name = "Fritz Quadrata", path = "Fonts\\FRIZQT__.TTF" },
    { name = "Arial Narrow", path = "Fonts\\ARIALN.TTF" },
    { name = "Morpheus", path = "Fonts\\MORPHEUS.TTF" },
    { name = "Skurri", path = "Fonts\\SKURRI.TTF" },
    { name = "2002", path = "Fonts\\2002.TTF" },
    { name = "2002 Bold", path = "Fonts\\2002B.TTF" },
}

local function GetFontList()
    if LSM then
        local fonts = {}
        for _, name in ipairs(LSM:List("font")) do
            table.insert(fonts, { name = name, path = LSM:Fetch("font", name) })
        end
        if #fonts > 0 then return fonts end
    end
    return DEFAULT_FONTS
end

local function GetSoundList()
    local sounds = {}
    for _, s in ipairs(BUILTIN_SOUNDS) do
        table.insert(sounds, s)
    end
    if LSM then
        for _, name in ipairs(LSM:List("sound")) do
            local path = LSM:Fetch("sound", name)
            table.insert(sounds, { name = name, key = path, path = path })
        end
    end
    table.insert(sounds, { name = "None", key = "none", path = nil })
    return sounds
end

---------------------------------------------------------------------------
-- Helper: Flat Slider
---------------------------------------------------------------------------
local function CreateSettingsSlider(parent, label, min, max, step, getValue, onChange, suffix)
    suffix = suffix or ""
    local container = CreateFrame("Frame", nil, parent)
    container:SetHeight(38)

    local labelText = container:CreateFontString(nil, "OVERLAY")
    labelText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    labelText:SetTextColor(0.65, 0.65, 0.65)
    labelText:SetPoint("TOPLEFT")
    labelText:SetText(label)

    local valueText = container:CreateFontString(nil, "OVERLAY")
    valueText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    valueText:SetTextColor(1, 1, 1)
    valueText:SetPoint("TOPRIGHT")

    local slider = CreateFrame("Slider", nil, container)
    slider:SetPoint("TOPLEFT", 0, -16)
    slider:SetPoint("RIGHT", 0, 0)
    slider:SetHeight(14)
    slider:SetMinMaxValues(min, max)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:SetOrientation("HORIZONTAL")
    slider:EnableMouse(true)

    -- Track
    local track = slider:CreateTexture(nil, "BACKGROUND")
    track:SetHeight(2)
    track:SetPoint("LEFT", 4, 0)
    track:SetPoint("RIGHT", -4, 0)
    track:SetColorTexture(0.25, 0.25, 0.25, 1)

    -- Thumb (blue circle from pill texture)
    slider:SetThumbTexture("Interface\\AddOns\\iChat\\media\\textures\\pill")
    local thumb = slider:GetThumbTexture()
    thumb:SetSize(14, 14)
    thumb:SetVertexColor(0.0, 0.48, 1.0, 1)

    local val = getValue()
    slider:SetValue(val)
    valueText:SetText(tostring(val) .. suffix)

    slider:SetScript("OnValueChanged", function(self, v)
        v = math.floor(v / step + 0.5) * step
        valueText:SetText(tostring(v) .. suffix)
        onChange(v)
    end)

    container.slider = slider
    container.valueText = valueText
    container.Refresh = function()
        local v = getValue()
        slider:SetValue(v)
        valueText:SetText(tostring(v) .. suffix)
    end
    return container
end

---------------------------------------------------------------------------
-- Helper: Flat Checkbox
---------------------------------------------------------------------------
local function CreateSettingsCheckbox(parent, label, getValue, onChange)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetHeight(22)

    local box = btn:CreateTexture(nil, "ARTWORK")
    box:SetSize(14, 14)
    box:SetPoint("LEFT")
    box:SetColorTexture(0.2, 0.2, 0.2, 1)

    local check = btn:CreateTexture(nil, "OVERLAY")
    check:SetSize(10, 10)
    check:SetPoint("CENTER", box)
    check:SetColorTexture(0.0, 0.48, 1.0, 1)

    local text = btn:CreateFontString(nil, "OVERLAY")
    text:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    text:SetTextColor(0.8, 0.8, 0.8)
    text:SetPoint("LEFT", box, "RIGHT", 6, 0)
    text:SetText(label)

    local checked = getValue()
    if checked then check:Show() else check:Hide() end

    btn:SetScript("OnClick", function()
        checked = not checked
        if checked then check:Show() else check:Hide() end
        onChange(checked)
    end)

    btn.Refresh = function()
        checked = getValue()
        if checked then check:Show() else check:Hide() end
    end
    return btn
end

---------------------------------------------------------------------------
-- Helper: Action Button
---------------------------------------------------------------------------
local function CreateActionButton(parent, label, color, onClick)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetHeight(28)

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.12, 0.12, 0.12, 1)

    local text = btn:CreateFontString(nil, "OVERLAY")
    text:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    text:SetPoint("CENTER")
    text:SetText(label)
    text:SetTextColor(unpack(color))
    btn.label = text

    btn:SetScript("OnClick", onClick)
    btn:SetScript("OnEnter", function() bg:SetColorTexture(0.18, 0.18, 0.18, 1) end)
    btn:SetScript("OnLeave", function() bg:SetColorTexture(0.12, 0.12, 0.12, 1) end)

    return btn
end

---------------------------------------------------------------------------
-- Helper: Dropdown Selector
---------------------------------------------------------------------------
local function CreateSettingsDropdown(parent, label, getItems, getValue, onChange, opts)
    opts = opts or {}
    local container = CreateFrame("Frame", nil, parent)
    container:SetHeight(46)

    local labelFS = container:CreateFontString(nil, "OVERLAY")
    labelFS:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    labelFS:SetTextColor(0.65, 0.65, 0.65)
    labelFS:SetPoint("TOPLEFT")
    labelFS:SetText(label)

    -- Current selection button
    local btn = CreateFrame("Button", nil, container)
    btn:SetHeight(24)
    btn:SetPoint("TOPLEFT", 0, -16)
    btn:SetPoint("RIGHT")

    local btnBg = btn:CreateTexture(nil, "BACKGROUND")
    btnBg:SetAllPoints()
    btnBg:SetColorTexture(0.12, 0.12, 0.12, 1)

    local btnText = btn:CreateFontString(nil, "OVERLAY")
    btnText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    btnText:SetTextColor(1, 1, 1)
    btnText:SetPoint("LEFT", 8, 0)
    btnText:SetPoint("RIGHT", -20, 0)
    btnText:SetJustifyH("LEFT")
    btnText:SetWordWrap(false)

    local arrow = btn:CreateFontString(nil, "OVERLAY")
    arrow:SetFont("Fonts\\FRIZQT__.TTF", 8, "")
    arrow:SetTextColor(0.5, 0.5, 0.5)
    arrow:SetPoint("RIGHT", -6, 0)
    arrow:SetText("v")

    -- Dropdown popup
    local MAX_VIS = 200
    local ENTRY_H = 22

    local dropFrame = CreateFrame("Frame", nil, ns.mainWindow or UIParent, "BackdropTemplate")
    dropFrame:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -2)
    dropFrame:SetPoint("RIGHT", btn, "RIGHT")
    dropFrame:SetFrameStrata("TOOLTIP")
    dropFrame:SetFrameLevel(20)
    dropFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    dropFrame:SetBackdropColor(0.08, 0.08, 0.08, 0.98)
    dropFrame:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
    dropFrame:Hide()

    local dropScroll = CreateFrame("ScrollFrame", nil, dropFrame)
    dropScroll:SetPoint("TOPLEFT", 2, -2)
    dropScroll:SetPoint("BOTTOMRIGHT", -2, 2)
    dropScroll:EnableMouseWheel(true)

    local dropChild = CreateFrame("Frame", nil, dropScroll)
    dropChild:SetWidth(1)
    dropChild:SetHeight(1)
    dropScroll:SetScrollChild(dropChild)

    dropScroll:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll()
        local maxS = math.max(0, dropChild:GetHeight() - self:GetHeight())
        self:SetVerticalScroll(math.max(0, math.min(maxS, cur - delta * ENTRY_H * 3)))
    end)

    -- Click-off to close
    local clickOff = CreateFrame("Button", nil, UIParent)
    clickOff:SetAllPoints(UIParent)
    clickOff:SetFrameStrata("TOOLTIP")
    clickOff:SetFrameLevel(0)
    clickOff:RegisterForClicks("AnyUp")
    clickOff:SetScript("OnClick", function() dropFrame:Hide() end)
    clickOff:Hide()

    dropFrame:SetScript("OnShow", function()
        clickOff:Show()
        if ns.CancelFade then ns.CancelFade() end
    end)
    dropFrame:SetScript("OnHide", function() clickOff:Hide() end)

    -- Track for cleanup when settings closes
    if not ns._settingsDropdowns then ns._settingsDropdowns = {} end
    table.insert(ns._settingsDropdowns, dropFrame)

    local entryPool = {}

    local function Populate()
        for _, ef in ipairs(entryPool) do ef:Hide() end

        local items = getItems()
        local curVal = getValue()

        dropChild:SetWidth(dropScroll:GetWidth())

        local yOff = 0
        for i, item in ipairs(items) do
            local ef = entryPool[i]
            if not ef then
                ef = CreateFrame("Button", nil, dropChild)
                ef:SetHeight(ENTRY_H)

                local ebg = ef:CreateTexture(nil, "BACKGROUND")
                ebg:SetAllPoints()
                ebg:SetColorTexture(0, 0, 0, 0)
                ef.bg = ebg

                local etxt = ef:CreateFontString(nil, "OVERLAY")
                etxt:SetPoint("LEFT", 8, 0)
                etxt:SetPoint("RIGHT", -8, 0)
                etxt:SetJustifyH("LEFT")
                etxt:SetWordWrap(false)
                ef.text = etxt

                entryPool[i] = ef
            end

            ef:ClearAllPoints()
            ef:SetPoint("TOPLEFT", 0, -yOff)
            ef:SetPoint("RIGHT", dropChild, "RIGHT")

            if opts.previewFont and item.path then
                pcall(function() ef.text:SetFont(item.path, 10, "") end)
            else
                ef.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
            end
            ef.text:SetText(item.name)

            if item.value == curVal then
                ef.bg:SetColorTexture(0.0, 0.48, 1.0, 0.2)
                ef.text:SetTextColor(1, 1, 1)
            else
                ef.bg:SetColorTexture(0, 0, 0, 0)
                ef.text:SetTextColor(0.7, 0.7, 0.7)
            end

            ef:SetScript("OnClick", function()
                onChange(item.value, item)
                dropFrame:Hide()
                btnText:SetText(item.name)
                if opts.previewFont and item.path then
                    pcall(function() btnText:SetFont(item.path, 10, "") end)
                end
            end)
            ef:SetScript("OnEnter", function()
                if item.value ~= curVal then
                    ef.bg:SetColorTexture(0.14, 0.14, 0.14, 1)
                end
            end)
            ef:SetScript("OnLeave", function()
                if item.value ~= curVal then
                    ef.bg:SetColorTexture(0, 0, 0, 0)
                end
            end)

            ef:Show()
            yOff = yOff + ENTRY_H
        end

        for j = #items + 1, #entryPool do
            entryPool[j]:Hide()
        end

        dropChild:SetHeight(math.max(yOff, 1))
        dropFrame:SetHeight(math.min(yOff + 4, MAX_VIS))
        dropScroll:SetVerticalScroll(0)
    end

    btn:SetScript("OnClick", function()
        if dropFrame:IsShown() then
            dropFrame:Hide()
        else
            Populate()
            dropFrame:Show()
        end
    end)
    btn:SetScript("OnEnter", function() btnBg:SetColorTexture(0.16, 0.16, 0.16, 1) end)
    btn:SetScript("OnLeave", function() btnBg:SetColorTexture(0.12, 0.12, 0.12, 1) end)

    container.Refresh = function()
        local curVal = getValue()
        local items = getItems()
        for _, item in ipairs(items) do
            if item.value == curVal then
                btnText:SetText(item.name)
                if opts.previewFont and item.path then
                    pcall(function() btnText:SetFont(item.path, 10, "") end)
                end
                return
            end
        end
        btnText:SetText("Unknown")
    end

    container.Refresh()
    return container
end

---------------------------------------------------------------------------
-- Settings Panel
---------------------------------------------------------------------------
function ns.CreateSettingsPanel()
    local panel = CreateFrame("Frame", nil, ns.mainWindow)
    panel:SetPoint("TOPLEFT", ns.rightPanel, "TOPLEFT")
    panel:SetPoint("BOTTOMRIGHT", ns.rightPanel, "BOTTOMRIGHT")
    panel:SetFrameLevel(ns.rightPanel:GetFrameLevel() + 5)
    panel:Hide()

    local bg = panel:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.05, 0.05, 0.05, 1)

    -- Header
    local header = CreateFrame("Frame", nil, panel)
    header:SetHeight(36)
    header:SetPoint("TOPLEFT")
    header:SetPoint("TOPRIGHT")

    local headerBorder = header:CreateTexture(nil, "OVERLAY")
    headerBorder:SetHeight(1)
    headerBorder:SetPoint("BOTTOMLEFT")
    headerBorder:SetPoint("BOTTOMRIGHT")
    headerBorder:SetColorTexture(0.15, 0.15, 0.15, 1)

    local backBtn = CreateFrame("Button", nil, header)
    backBtn:SetSize(40, 36)
    backBtn:SetPoint("LEFT")
    local backText = backBtn:CreateFontString(nil, "OVERLAY")
    backText:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    backText:SetPoint("CENTER")
    backText:SetText("<")
    backText:SetTextColor(0.0, 0.48, 1.0, 1)
    backBtn:SetScript("OnClick", function() ns.ToggleSettings() end)
    backBtn:SetScript("OnEnter", function() backText:SetTextColor(1, 1, 1) end)
    backBtn:SetScript("OnLeave", function() backText:SetTextColor(0.0, 0.48, 1.0, 1) end)

    local title = header:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    title:SetTextColor(1, 1, 1)
    title:SetPoint("CENTER")
    title:SetText("Settings")

    -- Scroll area
    local scroll = CreateFrame("ScrollFrame", nil, panel)
    scroll:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 12, -8)
    scroll:SetPoint("BOTTOMRIGHT", -12, 8)
    scroll:EnableMouseWheel(true)

    local child = CreateFrame("Frame", nil, scroll)
    child:SetWidth(1)
    child:SetHeight(600)
    scroll:SetScrollChild(child)

    scroll:SetScript("OnSizeChanged", function(self, w)
        child:SetWidth(w)
    end)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local maxScroll = math.max(0, child:GetHeight() - self:GetHeight())
        local newVal = math.max(0, math.min(maxScroll, current - (delta * 30)))
        self:SetVerticalScroll(newVal)
    end)

    local yPos = 0

    -----------------------------------------------------------------------
    -- Font Selection (dropdown)
    -----------------------------------------------------------------------
    local fontDropdown = CreateSettingsDropdown(child, "Font",
        function()
            local items = {}
            for _, f in ipairs(GetFontList()) do
                table.insert(items, { name = f.name, value = f.path, path = f.path })
            end
            return items
        end,
        function() return ns.db.settings.font end,
        function(v) ns.db.settings.font = v; ns.ApplyFont() end,
        { previewFont = true }
    )
    fontDropdown:SetPoint("TOPLEFT", 0, -yPos)
    fontDropdown:SetPoint("RIGHT", child, "RIGHT")
    yPos = yPos + 52

    -----------------------------------------------------------------------
    -- Font Size Slider
    -----------------------------------------------------------------------
    local fontSizeSlider = CreateSettingsSlider(child, "Font Size", 8, 16, 1,
        function() return ns.db.settings.fontSize end,
        function(v) ns.db.settings.fontSize = v; ns.ApplyFont() end
    )
    fontSizeSlider:SetPoint("TOPLEFT", 0, -yPos)
    fontSizeSlider:SetPoint("RIGHT", child, "RIGHT")
    yPos = yPos + 44

    -----------------------------------------------------------------------
    -- Background Opacity Slider
    -----------------------------------------------------------------------
    local opacitySlider = CreateSettingsSlider(child, "Background Opacity", 30, 100, 5,
        function() return math.floor((ns.db.settings.bgAlpha or 0.95) * 100 + 0.5) end,
        function(v)
            ns.db.settings.bgAlpha = v / 100
            ns.ApplyTransparency()
        end,
        "%"
    )
    opacitySlider:SetPoint("TOPLEFT", 0, -yPos)
    opacitySlider:SetPoint("RIGHT", child, "RIGHT")
    yPos = yPos + 44

    -----------------------------------------------------------------------
    -- History Slider
    -----------------------------------------------------------------------
    local historySlider = CreateSettingsSlider(child, "Message History", 50, 500, 10,
        function() return ns.db.settings.maxHistory end,
        function(v) ns.db.settings.maxHistory = v end
    )
    historySlider:SetPoint("TOPLEFT", 0, -yPos)
    historySlider:SetPoint("RIGHT", child, "RIGHT")
    yPos = yPos + 48

    -----------------------------------------------------------------------
    -- Toggles
    -----------------------------------------------------------------------
    local openWhisperCB = CreateSettingsCheckbox(child, "Open on incoming whisper",
        function() return ns.db.settings.openOnWhisper end,
        function(v) ns.db.settings.openOnWhisper = v end
    )
    openWhisperCB:SetPoint("TOPLEFT", 0, -yPos)
    openWhisperCB:SetPoint("RIGHT", child, "RIGHT")
    yPos = yPos + 28

    local suppressCB = CreateSettingsCheckbox(child, "Suppress default chat whispers",
        function() return ns.db.settings.suppressDefault end,
        function(v)
            ns.db.settings.suppressDefault = v
            if v then ns.RegisterChatFilters() else ns.UnregisterChatFilters() end
        end
    )
    suppressCB:SetPoint("TOPLEFT", 0, -yPos)
    suppressCB:SetPoint("RIGHT", child, "RIGHT")
    yPos = yPos + 36

    -----------------------------------------------------------------------
    -- Notification Sound (dropdown)
    -----------------------------------------------------------------------
    local soundDropdown = CreateSettingsDropdown(child, "Notification Sound",
        function()
            local items = {}
            for _, s in ipairs(GetSoundList()) do
                table.insert(items, { name = s.name, value = s.key })
            end
            return items
        end,
        function() return ns.db.settings.notifySound or "glass" end,
        function(v)
            ns.db.settings.notifySound = v
            if v ~= "none" then
                local path = BUILTIN_SOUND_PATHS[v] or v
                PlaySoundFile(path, "Master")
            end
        end
    )
    soundDropdown:SetPoint("TOPLEFT", 0, -yPos)
    soundDropdown:SetPoint("RIGHT", child, "RIGHT")
    yPos = yPos + 52

    -----------------------------------------------------------------------
    -- Display Section
    -----------------------------------------------------------------------
    local displayDiv = child:CreateTexture(nil, "OVERLAY")
    displayDiv:SetHeight(1)
    displayDiv:SetPoint("TOPLEFT", 0, -yPos)
    displayDiv:SetPoint("RIGHT", child, "RIGHT")
    displayDiv:SetColorTexture(0.15, 0.15, 0.15, 1)
    yPos = yPos + 12

    local displayLabel = child:CreateFontString(nil, "OVERLAY")
    displayLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    displayLabel:SetTextColor(0.65, 0.65, 0.65)
    displayLabel:SetPoint("TOPLEFT", 0, -yPos)
    displayLabel:SetText("Display")
    yPos = yPos + 18

    local dateSepCB = CreateSettingsCheckbox(child, "Show date separators",
        function() return ns.db.settings.showDateSeparators end,
        function(v)
            ns.db.settings.showDateSeparators = v
            if ns.activeConversation then ns.RebuildBubbles(ns.activeConversation) end
        end
    )
    dateSepCB:SetPoint("TOPLEFT", 0, -yPos)
    dateSepCB:SetPoint("RIGHT", child, "RIGHT")
    yPos = yPos + 26

    local hoverTimeCB = CreateSettingsCheckbox(child, "Show timestamps on hover",
        function() return ns.db.settings.showTimestampOnHover end,
        function(v)
            ns.db.settings.showTimestampOnHover = v
            if ns.activeConversation then ns.RebuildBubbles(ns.activeConversation) end
        end
    )
    hoverTimeCB:SetPoint("TOPLEFT", 0, -yPos)
    hoverTimeCB:SetPoint("RIGHT", child, "RIGHT")
    yPos = yPos + 26

    local itemLinksCB = CreateSettingsCheckbox(child, "Enable item links",
        function() return ns.db.settings.enableItemLinks end,
        function(v) ns.db.settings.enableItemLinks = v end
    )
    itemLinksCB:SetPoint("TOPLEFT", 0, -yPos)
    itemLinksCB:SetPoint("RIGHT", child, "RIGHT")
    yPos = yPos + 26

    local classColorCB = CreateSettingsCheckbox(child, "Class-colored names",
        function() return ns.db.settings.classColoredNames end,
        function(v)
            ns.db.settings.classColoredNames = v
            ns.RefreshConversationList()
        end
    )
    classColorCB:SetPoint("TOPLEFT", 0, -yPos)
    classColorCB:SetPoint("RIGHT", child, "RIGHT")
    yPos = yPos + 26

    local onlineStatusCB = CreateSettingsCheckbox(child, "Show online status",
        function() return ns.db.settings.showOnlineStatus end,
        function(v)
            ns.db.settings.showOnlineStatus = v
            ns.RefreshConversationList()
        end
    )
    onlineStatusCB:SetPoint("TOPLEFT", 0, -yPos)
    onlineStatusCB:SetPoint("RIGHT", child, "RIGHT")
    yPos = yPos + 30

    -----------------------------------------------------------------------
    -- Behavior Section
    -----------------------------------------------------------------------
    local behaviorDiv = child:CreateTexture(nil, "OVERLAY")
    behaviorDiv:SetHeight(1)
    behaviorDiv:SetPoint("TOPLEFT", 0, -yPos)
    behaviorDiv:SetPoint("RIGHT", child, "RIGHT")
    behaviorDiv:SetColorTexture(0.15, 0.15, 0.15, 1)
    yPos = yPos + 12

    local behaviorLabel = child:CreateFontString(nil, "OVERLAY")
    behaviorLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    behaviorLabel:SetTextColor(0.65, 0.65, 0.65)
    behaviorLabel:SetPoint("TOPLEFT", 0, -yPos)
    behaviorLabel:SetText("Behavior")
    yPos = yPos + 18

    local kbShortcutsCB = CreateSettingsCheckbox(child, "Enable keyboard shortcuts",
        function() return ns.db.settings.enableKeyboardShortcuts end,
        function(v) ns.db.settings.enableKeyboardShortcuts = v end
    )
    kbShortcutsCB:SetPoint("TOPLEFT", 0, -yPos)
    kbShortcutsCB:SetPoint("RIGHT", child, "RIGHT")
    yPos = yPos + 26

    local minimapBtnCB = CreateSettingsCheckbox(child, "Show minimap button",
        function() return ns.db.settings.showMinimapButton end,
        function(v)
            ns.db.settings.showMinimapButton = v
            if ns.SetMinimapButtonVisible then
                ns.SetMinimapButtonVisible(v)
            end
        end
    )
    minimapBtnCB:SetPoint("TOPLEFT", 0, -yPos)
    minimapBtnCB:SetPoint("RIGHT", child, "RIGHT")
    yPos = yPos + 30

    -----------------------------------------------------------------------
    -- Auto-Reply Section
    -----------------------------------------------------------------------
    local autoReplyDiv = child:CreateTexture(nil, "OVERLAY")
    autoReplyDiv:SetHeight(1)
    autoReplyDiv:SetPoint("TOPLEFT", 0, -yPos)
    autoReplyDiv:SetPoint("RIGHT", child, "RIGHT")
    autoReplyDiv:SetColorTexture(0.15, 0.15, 0.15, 1)
    yPos = yPos + 12

    local autoReplyLabel = child:CreateFontString(nil, "OVERLAY")
    autoReplyLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    autoReplyLabel:SetTextColor(0.65, 0.65, 0.65)
    autoReplyLabel:SetPoint("TOPLEFT", 0, -yPos)
    autoReplyLabel:SetText("Auto-Reply")
    yPos = yPos + 18

    local autoReplyCB = CreateSettingsCheckbox(child, "Enable auto-reply",
        function() return ns.db.settings.autoReplyEnabled end,
        function(v)
            ns.db.settings.autoReplyEnabled = v
            if v then
                ns.autoRepliedTo = {}
            end
        end
    )
    autoReplyCB:SetPoint("TOPLEFT", 0, -yPos)
    autoReplyCB:SetPoint("RIGHT", child, "RIGHT")
    yPos = yPos + 26

    -- Auto-reply message EditBox
    local arMsgLabel = child:CreateFontString(nil, "OVERLAY")
    arMsgLabel:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    arMsgLabel:SetTextColor(0.5, 0.5, 0.5)
    arMsgLabel:SetPoint("TOPLEFT", 0, -yPos)
    arMsgLabel:SetText("Message:")
    yPos = yPos + 14

    local arMsgRow = CreateFrame("Frame", nil, child)
    arMsgRow:SetHeight(24)
    arMsgRow:SetPoint("TOPLEFT", 0, -yPos)
    arMsgRow:SetPoint("RIGHT", child, "RIGHT")

    local arMsgBox = CreateFrame("EditBox", nil, arMsgRow)
    arMsgBox:SetPoint("LEFT", 0, 0)
    arMsgBox:SetPoint("RIGHT")
    arMsgBox:SetHeight(20)
    arMsgBox:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    arMsgBox:SetTextColor(0.9, 0.9, 0.9)
    arMsgBox:SetAutoFocus(false)
    arMsgBox:SetMaxLetters(200)

    local arMsgBg = arMsgBox:CreateTexture(nil, "BACKGROUND")
    arMsgBg:SetAllPoints()
    arMsgBg:SetColorTexture(0.1, 0.1, 0.1, 1)

    arMsgBox:SetText(ns.db.settings.autoReplyMessage or "")
    arMsgBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    arMsgBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    arMsgBox:SetScript("OnEditFocusLost", function(self)
        ns.db.settings.autoReplyMessage = self:GetText()
    end)
    yPos = yPos + 30

    -----------------------------------------------------------------------
    -- Quick Replies Section
    -----------------------------------------------------------------------
    local qrDiv = child:CreateTexture(nil, "OVERLAY")
    qrDiv:SetHeight(1)
    qrDiv:SetPoint("TOPLEFT", 0, -yPos)
    qrDiv:SetPoint("RIGHT", child, "RIGHT")
    qrDiv:SetColorTexture(0.15, 0.15, 0.15, 1)
    yPos = yPos + 12

    local qrLabel = child:CreateFontString(nil, "OVERLAY")
    qrLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    qrLabel:SetTextColor(0.65, 0.65, 0.65)
    qrLabel:SetPoint("TOPLEFT", 0, -yPos)
    qrLabel:SetText("Quick Replies")
    yPos = yPos + 18

    local qrBoxes = {}
    for i = 1, 5 do
        local row = CreateFrame("Frame", nil, child)
        row:SetHeight(24)
        row:SetPoint("TOPLEFT", 0, -yPos)
        row:SetPoint("RIGHT", child, "RIGHT")

        local num = row:CreateFontString(nil, "OVERLAY")
        num:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        num:SetTextColor(0.5, 0.5, 0.5)
        num:SetPoint("LEFT", 0, 0)
        num:SetText(i .. ".")

        local box = CreateFrame("EditBox", nil, row)
        box:SetPoint("LEFT", num, "RIGHT", 4, 0)
        box:SetPoint("RIGHT")
        box:SetHeight(20)
        box:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        box:SetTextColor(0.9, 0.9, 0.9)
        box:SetAutoFocus(false)
        box:SetMaxLetters(100)

        local boxBg = box:CreateTexture(nil, "BACKGROUND")
        boxBg:SetAllPoints()
        boxBg:SetColorTexture(0.1, 0.1, 0.1, 1)

        box:SetText(ns.db.settings.quickReplies and ns.db.settings.quickReplies[i] or "")

        box:SetScript("OnEnterPressed", function(self)
            self:ClearFocus()
        end)
        box:SetScript("OnEscapePressed", function(self)
            self:ClearFocus()
        end)
        box:SetScript("OnEditFocusLost", function(self)
            if not ns.db.settings.quickReplies then
                ns.db.settings.quickReplies = {}
            end
            ns.db.settings.quickReplies[i] = self:GetText()
            ns.RefreshQuickReplies()
        end)

        qrBoxes[i] = box
        yPos = yPos + 26
    end

    yPos = yPos + 8

    -----------------------------------------------------------------------
    -- Divider
    -----------------------------------------------------------------------
    local div = child:CreateTexture(nil, "OVERLAY")
    div:SetHeight(1)
    div:SetPoint("TOPLEFT", 0, -yPos)
    div:SetPoint("RIGHT", child, "RIGHT")
    div:SetColorTexture(0.15, 0.15, 0.15, 1)
    yPos = yPos + 12

    -----------------------------------------------------------------------
    -- Action Buttons
    -----------------------------------------------------------------------
    local exportBtn = CreateActionButton(child, "Export Conversation", {0.0, 0.48, 1.0, 1}, function()
        ns.ExportConversation()
    end)
    exportBtn:SetPoint("TOPLEFT", 0, -yPos)
    exportBtn:SetPoint("RIGHT", child, "RIGHT")
    yPos = yPos + 34

    local clearBtn = CreateActionButton(child, "Clear Current History", {0.8, 0.25, 0.2, 1}, function()
        if not ns.activeConversation then return end
        local convo = ns.db.conversations[ns.activeConversation]
        if not convo then return end
        wipe(convo.messages)
        convo.unread = 0
        ns.RebuildBubbles(ns.activeConversation)
        ns.RefreshConversationList()
        DEFAULT_CHAT_FRAME:AddMessage("|cff007AFFiChat:|r Cleared history for " .. ns.activeConversation)
    end)
    clearBtn:SetPoint("TOPLEFT", 0, -yPos)
    clearBtn:SetPoint("RIGHT", child, "RIGHT")
    yPos = yPos + 34

    -- Clear All with two-click confirmation
    local clearAllConfirm = false
    local clearAllBtn = CreateActionButton(child, "Clear All History", {0.8, 0.25, 0.2, 1}, function()
        if not clearAllConfirm then
            clearAllConfirm = true
            clearAllBtn.label:SetText("Are you sure? Click again")
            C_Timer.After(3, function()
                clearAllConfirm = false
                if clearAllBtn.label then
                    clearAllBtn.label:SetText("Clear All History")
                end
            end)
            return
        end
        clearAllConfirm = false
        wipe(ns.db.conversations)
        ns.activeConversation = nil
        ns.headerName:SetText("")
        if ns.emptyText then ns.emptyText:Show() end
        for _, bubble in ipairs(ns.activeBubbles) do bubble:Hide() end
        wipe(ns.activeBubbles)
        ns.RefreshConversationList()
        ns.UpdateHeaderButtons()
        clearAllBtn.label:SetText("Clear All History")
        DEFAULT_CHAT_FRAME:AddMessage("|cff007AFFiChat:|r All history cleared.")
    end)
    clearAllBtn:SetPoint("TOPLEFT", 0, -yPos)
    clearAllBtn:SetPoint("RIGHT", child, "RIGHT")
    yPos = yPos + 34

    child:SetHeight(yPos + 8)

    ns.settingsPanel = panel

    panel:SetScript("OnShow", function()
        fontDropdown.Refresh()
        soundDropdown.Refresh()
        fontSizeSlider.Refresh()
        opacitySlider.Refresh()
        historySlider.Refresh()
        openWhisperCB.Refresh()
        suppressCB.Refresh()
        dateSepCB.Refresh()
        hoverTimeCB.Refresh()
        itemLinksCB.Refresh()
        classColorCB.Refresh()
        onlineStatusCB.Refresh()
        kbShortcutsCB.Refresh()
        minimapBtnCB.Refresh()
        autoReplyCB.Refresh()
        arMsgBox:SetText(ns.db.settings.autoReplyMessage or "")
        clearAllConfirm = false
        clearAllBtn.label:SetText("Clear All History")
        -- Refresh quick reply boxes
        for i, box in ipairs(qrBoxes) do
            box:SetText(ns.db.settings.quickReplies and ns.db.settings.quickReplies[i] or "")
        end
    end)
end

---------------------------------------------------------------------------
-- Toggle Settings
---------------------------------------------------------------------------
function ns.ToggleSettings()
    if not ns.settingsPanel then
        ns.CreateSettingsPanel()
    end

    if ns.settingsPanel:IsShown() then
        -- Close any open dropdowns
        if ns._settingsDropdowns then
            for _, df in ipairs(ns._settingsDropdowns) do df:Hide() end
        end
        ns.settingsPanel:Hide()
    else
        ns.settingsPanel:Show()
        if ns.CancelFade then ns.CancelFade() end
    end
end

---------------------------------------------------------------------------
-- Apply Font Changes
---------------------------------------------------------------------------
function ns.ApplyFont()
    local font = ns.db.settings.font
    local size = ns.db.settings.fontSize

    if ns.inputBox then
        ns.inputBox:SetFont(font, size, "")
    end

    if ns.activeConversation then
        ns.RebuildBubbles(ns.activeConversation)
        ns.ScrollToBottom()
    end
end

---------------------------------------------------------------------------
-- Apply Transparency
---------------------------------------------------------------------------
function ns.ApplyTransparency()
    local alpha = ns.db.settings.bgAlpha or 0.95
    if ns.mainWindow then
        ns.mainWindow:SetBackdropColor(0.05, 0.05, 0.05, alpha)
    end
    if ns.leftPanelBg then
        ns.leftPanelBg:SetColorTexture(0.06, 0.06, 0.06, alpha)
    end
end

---------------------------------------------------------------------------
-- Quick Reply Bar (shown above input in chat view)
---------------------------------------------------------------------------
function ns.CreateQuickReplyBar(parent)
    local bar = CreateFrame("Frame", nil, parent)
    bar:SetHeight(26)
    bar:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 40)
    bar:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 40)

    local barBg = bar:CreateTexture(nil, "BACKGROUND")
    barBg:SetAllPoints()
    barBg:SetColorTexture(0.07, 0.07, 0.07, 1)

    local topBorder = bar:CreateTexture(nil, "OVERLAY")
    topBorder:SetHeight(1)
    topBorder:SetPoint("TOPLEFT")
    topBorder:SetPoint("TOPRIGHT")
    topBorder:SetColorTexture(0.15, 0.15, 0.15, 1)

    ns.quickReplyBar = bar
    ns.quickReplyBtns = {}

    for i = 1, 5 do
        local btn = CreateFrame("Button", nil, bar)
        btn:SetHeight(20)

        local text = btn:CreateFontString(nil, "OVERLAY")
        text:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        text:SetPoint("CENTER")
        text:SetTextColor(0.7, 0.7, 0.7)
        btn.text = text

        local btnBg = btn:CreateTexture(nil, "BACKGROUND")
        btnBg:SetAllPoints()
        btnBg:SetColorTexture(0.13, 0.13, 0.13, 1)
        btn.bg = btnBg

        btn:SetScript("OnClick", function()
            local msg = text:GetText()
            if msg and msg ~= "" and ns.activeConversation then
                ns.SendWhisper(ns.activeConversation, msg)
            end
        end)
        btn:SetScript("OnEnter", function() btnBg:SetColorTexture(0.2, 0.2, 0.2, 1) end)
        btn:SetScript("OnLeave", function() btnBg:SetColorTexture(0.13, 0.13, 0.13, 1) end)

        btn:Hide()
        ns.quickReplyBtns[i] = btn
    end

    ns.RefreshQuickReplies()
end

function ns.RefreshQuickReplies()
    if not ns.quickReplyBtns then return end

    local replies = ns.db.settings.quickReplies or {}
    local visible = {}

    for i = 1, 5 do
        local msg = replies[i]
        if msg and msg ~= "" then
            table.insert(visible, { index = i, text = msg })
        end
    end

    -- Hide all first
    for i = 1, 5 do
        ns.quickReplyBtns[i]:Hide()
    end

    if #visible == 0 then
        if ns.quickReplyBar then ns.quickReplyBar:Hide() end
        if ns.chatScrollFrame then
            ns.chatScrollFrame:SetPoint("BOTTOMRIGHT", ns.rightPanel, "BOTTOMRIGHT", 0, 40)
        end
        return
    end

    if ns.quickReplyBar then ns.quickReplyBar:Show() end
    if ns.chatScrollFrame then
        ns.chatScrollFrame:SetPoint("BOTTOMRIGHT", ns.rightPanel, "BOTTOMRIGHT", 0, 66)
    end

    -- Layout visible buttons evenly
    local count = #visible
    local padding = 4
    local prevBtn = nil

    for idx, data in ipairs(visible) do
        local btn = ns.quickReplyBtns[data.index]
        btn.text:SetText(data.text)
        btn:ClearAllPoints()

        if idx == 1 then
            btn:SetPoint("LEFT", ns.quickReplyBar, "LEFT", padding, 0)
        else
            btn:SetPoint("LEFT", prevBtn, "RIGHT", padding, 0)
        end

        if idx == count then
            btn:SetPoint("RIGHT", ns.quickReplyBar, "RIGHT", -padding, 0)
        end

        -- Approximate equal widths
        local totalPadding = padding * (count + 1)
        btn:SetWidth((ns.quickReplyBar:GetWidth() - totalPadding) / count)

        btn:Show()
        prevBtn = btn
    end
end

---------------------------------------------------------------------------
-- Play Notification Sound
---------------------------------------------------------------------------
function ns.PlayNotifySound()
    local key = ns.db.settings.notifySound or "glass"
    if key == "none" then return end
    local path = BUILTIN_SOUND_PATHS[key] or key
    PlaySoundFile(path, "Master")
end

---------------------------------------------------------------------------
-- Export Conversation
---------------------------------------------------------------------------
function ns.ExportConversation()
    if not ns.activeConversation then
        DEFAULT_CHAT_FRAME:AddMessage("|cff007AFFiChat:|r No conversation selected.")
        return
    end

    local convo = ns.db.conversations[ns.activeConversation]
    if not convo or not convo.messages or #convo.messages == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cff007AFFiChat:|r No messages to export.")
        return
    end

    local lines = {}
    for _, msg in ipairs(convo.messages) do
        local sender = msg.sender == "me" and (ns.playerName or "You") or ns.activeConversation
        local timeStr = date("%Y-%m-%d %H:%M:%S", msg.time)
        table.insert(lines, "[" .. timeStr .. "] " .. sender .. ": " .. msg.text)
    end
    local text = table.concat(lines, "\n")

    -- Create export frame if needed
    if not ns.exportFrame then
        local frame = CreateFrame("Frame", "iChatExportFrame", UIParent, "BackdropTemplate")
        frame:SetSize(500, 400)
        frame:SetPoint("CENTER")
        frame:SetFrameStrata("FULLSCREEN_DIALOG")
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

        frame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        frame:SetBackdropColor(0.05, 0.05, 0.05, 0.98)
        frame:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

        local ftitle = frame:CreateFontString(nil, "OVERLAY")
        ftitle:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
        ftitle:SetTextColor(1, 1, 1)
        ftitle:SetPoint("TOP", 0, -10)
        ftitle:SetText("Export Conversation")

        local hint = frame:CreateFontString(nil, "OVERLAY")
        hint:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        hint:SetTextColor(0.5, 0.5, 0.5)
        hint:SetPoint("TOP", ftitle, "BOTTOM", 0, -2)
        hint:SetText("Ctrl+A then Ctrl+C to copy")

        local closeBtn = CreateFrame("Button", nil, frame)
        closeBtn:SetSize(20, 20)
        closeBtn:SetPoint("TOPRIGHT", -6, -6)
        local closeTex = closeBtn:CreateFontString(nil, "OVERLAY")
        closeTex:SetFont("Fonts\\FRIZQT__.TTF", 16, "")
        closeTex:SetPoint("CENTER")
        closeTex:SetText("x")
        closeTex:SetTextColor(0.6, 0.6, 0.6)
        closeBtn:SetScript("OnClick", function() frame:Hide() end)
        closeBtn:SetScript("OnEnter", function() closeTex:SetTextColor(1, 0.3, 0.3) end)
        closeBtn:SetScript("OnLeave", function() closeTex:SetTextColor(0.6, 0.6, 0.6) end)

        local eScroll = CreateFrame("ScrollFrame", "iChatExportScroll", frame, "UIPanelScrollFrameTemplate")
        eScroll:SetPoint("TOPLEFT", 10, -38)
        eScroll:SetPoint("BOTTOMRIGHT", -28, 10)

        local editBox = CreateFrame("EditBox", "iChatExportEditBox", eScroll)
        editBox:SetMultiLine(true)
        editBox:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        editBox:SetTextColor(0.9, 0.9, 0.9)
        editBox:SetWidth(450)
        editBox:SetAutoFocus(false)
        eScroll:SetScrollChild(editBox)

        eScroll:SetScript("OnSizeChanged", function(self, w)
            editBox:SetWidth(w)
        end)

        ns.exportFrame = frame
        ns.exportBox = editBox

        tinsert(UISpecialFrames, "iChatExportFrame")
    end

    ns.exportBox:SetText(text)
    ns.exportFrame:Show()
    ns.exportBox:HighlightText()
    ns.exportBox:SetFocus()
end
