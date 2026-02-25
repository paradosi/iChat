local _, ns = ...

---------------------------------------------------------------------------
-- Floating Button — freely draggable anywhere on screen
---------------------------------------------------------------------------

local ICON_PATH = "Interface\\AddOns\\iChat\\media\\textures\\"

function ns.CreateMinimapButton()
    if ns.minimapButton then return end

    local size = ns.db.settings.buttonSize or 40
    local faction = UnitFactionGroup("player")
    local iconFile = ICON_PATH .. (faction == "Horde" and "icon_horde" or "icon_alliance")

    local btn = CreateFrame("Button", "iChatFloatingButton", UIParent)
    btn:SetSize(size, size)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(8)
    btn:SetMovable(true)
    btn:SetClampedToScreen(true)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:RegisterForDrag("LeftButton")

    -- Shield icon (blue for Alliance, red for Horde)
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture(iconFile)
    btn.icon = icon

    -- Restore saved position
    local pos = ns.db.settings.buttonPos
    if pos then
        btn:SetPoint(pos.point or "CENTER", UIParent, pos.relPoint or "BOTTOMLEFT", pos.x or 0, pos.y or 0)
    else
        btn:SetPoint("CENTER", UIParent, "CENTER", -300, -200)
    end

    -- Click handlers
    btn:SetScript("OnClick", function(self, button)
        ns.StopFlashButton()
        if button == "RightButton" then
            ns.ToggleSettings()
        else
            ns.ToggleWindow()
        end
    end)

    -- Free drag
    btn:SetScript("OnDragStart", function(self)
        if not InCombatLockdown() then
            self:StartMoving()
        end
    end)
    btn:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        ns.db.settings.buttonPos = {
            point = point,
            relPoint = relPoint,
            x = x,
            y = y,
        }
    end)

    -- Hover effect (brighten icon)
    btn:SetScript("OnEnter", function(self)
        self.icon:SetVertexColor(2.0, 2.0, 2.0)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("|cff007AFFiChat|r")
        GameTooltip:AddLine("Left-click: Toggle window", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("Right-click: Settings", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("Drag: Reposition", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function(self)
        self.icon:SetVertexColor(1.5, 1.5, 1.5)
        GameTooltip:Hide()
    end)

    -- Unread badge (red dot with count)
    local badge = CreateFrame("Frame", nil, btn)
    badge:SetSize(18, 18)
    badge:SetPoint("TOPRIGHT", 4, 4)
    local badgeBg = badge:CreateTexture(nil, "ARTWORK")
    badgeBg:SetAllPoints()
    badgeBg:SetColorTexture(1.0, 0.22, 0.17, 1)
    local badgeCount = badge:CreateFontString(nil, "OVERLAY")
    badgeCount:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    badgeCount:SetPoint("CENTER")
    badgeCount:SetTextColor(1, 1, 1)
    badge:Hide()
    btn.unreadBadge = badge
    btn.unreadCount = badgeCount

    ns.minimapButton = btn

    if not ns.db.settings.showMinimapButton then
        btn:Hide()
    end
end

-- Update the unread badge on the floating button
function ns.UpdateButtonBadge()
    if not ns.minimapButton or not ns.minimapButton.unreadBadge then return end
    local total = 0
    if ns.db and ns.db.conversations then
        for _, convo in pairs(ns.db.conversations) do
            total = total + (convo.unread or 0)
        end
    end
    if total > 0 then
        ns.minimapButton.unreadCount:SetText(total > 99 and "99+" or tostring(total))
        ns.minimapButton.unreadBadge:Show()
    else
        ns.minimapButton.unreadBadge:Hide()
    end

    -- Fire WeakAuras event
    if ns.FireUnreadChanged then
        ns.FireUnreadChanged(total)
    end

    -- Sync LDB text (Titan Panel / ChocolateBar / Bazooka / etc.)
    if ns.UpdateLDBText then
        ns.UpdateLDBText()
    end
end

-- Repeating flash on incoming whisper — pulses until user opens iChat
function ns.FlashButton()
    if not ns.minimapButton then return end
    -- Already flashing, just let it continue
    if ns.buttonFlashTicker then return end
    local btn = ns.minimapButton
    local on = false
    ns.buttonFlashTicker = C_Timer.NewTicker(0.5, function()
        if not btn.icon then
            ns.StopFlashButton()
            return
        end
        on = not on
        if on then
            btn.icon:SetVertexColor(1.0, 0.4, 0.4)
        else
            btn.icon:SetVertexColor(1, 1, 1)
        end
    end)
end

function ns.StopFlashButton()
    if ns.buttonFlashTicker then
        ns.buttonFlashTicker:Cancel()
        ns.buttonFlashTicker = nil
    end
    if ns.minimapButton and ns.minimapButton.icon then
        ns.minimapButton.icon:SetVertexColor(1.5, 1.5, 1.5)
    end
end

function ns.SetMinimapButtonVisible(show)
    if not ns.minimapButton then return end
    if show then
        ns.minimapButton:Show()
    else
        ns.minimapButton:Hide()
    end
end

function ns.ResizeButton(size)
    if not ns.minimapButton then return end
    ns.minimapButton:SetSize(size, size)
    -- Scale badge relative to button size
    local badgeSize = math.max(14, math.floor(size * 0.45))
    local fontSize = math.max(7, math.floor(size * 0.22))
    if ns.minimapButton.unreadBadge then
        ns.minimapButton.unreadBadge:SetSize(badgeSize, badgeSize)
    end
    if ns.minimapButton.unreadCount then
        ns.minimapButton.unreadCount:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE")
    end
end
