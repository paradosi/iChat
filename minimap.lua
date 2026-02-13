local _, ns = ...

---------------------------------------------------------------------------
-- Floating Button — freely draggable anywhere on screen
---------------------------------------------------------------------------

local BUTTON_SIZE = 48
local ICON_SIZE = 44
local ICON_TEXTURE = "Interface\\AddOns\\iChat\\media\\textures\\minimap_icon"

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

    -- Icon (fills the button)
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetPoint("CENTER")
    icon:SetTexture(ICON_TEXTURE)
    btn.icon = icon

    -- Highlight glow
    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetSize(ICON_SIZE, ICON_SIZE)
    hl:SetPoint("CENTER")
    hl:SetTexture(ICON_TEXTURE)
    hl:SetVertexColor(1, 1, 1, 0.3)

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
        -- Save position
        local point, _, relPoint, x, y = self:GetPoint()
        ns.db.settings.buttonPos = {
            point = point,
            relPoint = relPoint,
            x = x,
            y = y,
        }
    end)

    -- Tooltip
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("|cff007AFFiChat|r")
        GameTooltip:AddLine("Left-click: Toggle window", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("Right-click: Settings", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("Drag: Reposition", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    ns.minimapButton = btn

    -- Respect visibility setting
    if not ns.db.settings.showMinimapButton then
        btn:Hide()
    end
end

-- Toggle button visibility
function ns.SetMinimapButtonVisible(show)
    if not ns.minimapButton then return end
    if show then
        ns.minimapButton:Show()
    else
        ns.minimapButton:Hide()
    end
end
