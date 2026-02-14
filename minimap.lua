local _, ns = ...

---------------------------------------------------------------------------
-- Floating Button — freely draggable anywhere on screen
---------------------------------------------------------------------------

local BUTTON_SIZE = 40
local ICON_TEXTURE = "Interface\\AddOns\\iChat\\media\\textures\\icon"

function ns.CreateMinimapButton()
    if ns.minimapButton then return end

    local btn = CreateFrame("Button", "iChatFloatingButton", UIParent)
    btn:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(8)
    btn:SetMovable(true)
    btn:SetClampedToScreen(true)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:RegisterForDrag("LeftButton")

    -- Shield icon
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture(ICON_TEXTURE)
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
        self.icon:SetVertexColor(1.3, 1.3, 1.3)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("|cff007AFFiChat|r")
        GameTooltip:AddLine("Left-click: Toggle window", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("Right-click: Settings", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("Drag: Reposition", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function(self)
        self.icon:SetVertexColor(1, 1, 1)
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
end

-- Flash the button on incoming whisper (visual pulse regardless of unread state)
function ns.FlashButton()
    if not ns.minimapButton then return end
    local btn = ns.minimapButton
    btn.icon:SetVertexColor(1.0, 0.4, 0.4) -- red tint flash
    C_Timer.After(0.3, function()
        if not btn.icon then return end
        btn.icon:SetVertexColor(1, 1, 1) -- back to normal
    end)
end

function ns.SetMinimapButtonVisible(show)
    if not ns.minimapButton then return end
    if show then
        ns.minimapButton:Show()
    else
        ns.minimapButton:Hide()
    end
end
