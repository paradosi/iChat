local _, ns = ...

---------------------------------------------------------------------------
-- Minimap Button — draggable button around the minimap edge
---------------------------------------------------------------------------

local BUTTON_SIZE = 32
local ICON_TEXTURE = "Interface\\AddOns\\iChat\\media\\textures\\minimap_icon"

local function UpdatePosition(btn, angle)
    local rad = math.rad(angle)
    local x = math.cos(rad) * 80
    local y = math.sin(rad) * 80
    btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function ns.CreateMinimapButton()
    if ns.minimapButton then return end

    local btn = CreateFrame("Button", "iChatMinimapButton", Minimap)
    btn:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(8)
    btn:SetMovable(true)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:RegisterForDrag("LeftButton")

    -- Background circle
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    bg:SetPoint("CENTER")
    bg:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    local overlay = btn:CreateTexture(nil, "OVERLAY")
    overlay:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    overlay:SetPoint("CENTER")
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    -- Icon
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", 0, 1)
    icon:SetTexture(ICON_TEXTURE)

    -- Highlight
    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetSize(20, 20)
    hl:SetPoint("CENTER", 0, 1)
    hl:SetTexture(ICON_TEXTURE)
    hl:SetVertexColor(1, 1, 1, 0.3)

    -- Position from saved angle
    local angle = ns.db.settings.minimapButtonAngle or 220
    UpdatePosition(btn, angle)

    -- Click handlers
    btn:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            ns.ToggleSettings()
        else
            ns.ToggleWindow()
        end
    end)

    -- Drag to reposition
    btn:SetScript("OnDragStart", function(self)
        self.isDragging = true
    end)
    btn:SetScript("OnDragStop", function(self)
        self.isDragging = false
    end)
    btn:SetScript("OnUpdate", function(self)
        if not self.isDragging then return end
        local mx, my = Minimap:GetCenter()
        local cx, cy = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        cx, cy = cx / scale, cy / scale
        local newAngle = math.deg(math.atan2(cy - my, cx - mx))
        ns.db.settings.minimapButtonAngle = newAngle
        UpdatePosition(self, newAngle)
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

-- Toggle minimap button visibility
function ns.SetMinimapButtonVisible(show)
    if not ns.minimapButton then return end
    if show then
        ns.minimapButton:Show()
    else
        ns.minimapButton:Hide()
    end
end
