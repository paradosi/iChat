local _, ns = ...

---------------------------------------------------------------------------
-- Online/Offline Notifications
-- Shows a toast when a friend you've chatted with comes online or goes offline
---------------------------------------------------------------------------

local TOAST_DURATION = 4.0
local TOAST_FADE_TIME = 0.5
local previousOnline = {}  -- snapshot of online state from last poll
local initialized = false

---------------------------------------------------------------------------
-- Toast Frame (reusable)
---------------------------------------------------------------------------
local toastQueue = {}
local toastShowing = false

local function CreateToastFrame()
    if ns.toastFrame then return end

    local toast = CreateFrame("Frame", "iChatToastFrame", UIParent, "BackdropTemplate")
    toast:SetSize(220, 44)
    toast:SetPoint("TOP", UIParent, "TOP", 0, -80)
    toast:SetFrameStrata("TOOLTIP")
    toast:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    toast:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
    toast:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

    local icon = toast:CreateTexture(nil, "ARTWORK")
    icon:SetSize(10, 10)
    icon:SetPoint("LEFT", 12, 0)
    toast.statusIcon = icon

    local name = toast:CreateFontString(nil, "OVERLAY")
    name:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    name:SetPoint("LEFT", icon, "RIGHT", 8, 4)
    name:SetTextColor(1, 1, 1)
    toast.nameText = name

    local status = toast:CreateFontString(nil, "OVERLAY")
    status:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    status:SetPoint("LEFT", icon, "RIGHT", 8, -8)
    status:SetTextColor(0.5, 0.5, 0.5)
    toast.statusText = status

    -- Click to open conversation
    toast:EnableMouse(true)
    toast:SetScript("OnMouseUp", function(self)
        if self._playerName and ns.mainWindow then
            if not ns.mainWindow:IsShown() then
                ns.mainWindow:Show()
            end
            ns.SelectConversation(self._playerName)
        end
        self:Hide()
    end)

    toast:Hide()
    ns.toastFrame = toast
end

local function ShowToast(playerName, isOnline)
    CreateToastFrame()

    local toast = ns.toastFrame
    toast._playerName = playerName

    -- Class color for name
    local displayName = playerName
    if ns.db.settings.classColoredNames then
        local lower = playerName:lower()
        local classToken = ns.classCache and ns.classCache[lower]
        if classToken and RAID_CLASS_COLORS[classToken] then
            local c = RAID_CLASS_COLORS[classToken]
            displayName = ("|cff%02x%02x%02x%s|r"):format(c.r * 255, c.g * 255, c.b * 255, playerName)
        end
    end

    toast.nameText:SetText(displayName)

    if isOnline then
        toast.statusIcon:SetColorTexture(0.2, 0.9, 0.3, 1)
        toast.statusText:SetText("is now online")
    else
        toast.statusIcon:SetColorTexture(0.5, 0.5, 0.5, 1)
        toast.statusText:SetText("went offline")
    end

    toast:SetAlpha(1)
    toast:Show()

    -- Auto-hide after duration
    C_Timer.After(TOAST_DURATION, function()
        if toast:IsShown() then
            -- Simple fade
            local elapsed = 0
            local ticker = C_Timer.NewTicker(0.03, function(self)
                elapsed = elapsed + 0.03
                local alpha = 1 - (elapsed / TOAST_FADE_TIME)
                if alpha <= 0 then
                    toast:Hide()
                    toast:SetAlpha(1)
                    self:Cancel()
                    -- Show next queued toast
                    if #toastQueue > 0 then
                        local next = table.remove(toastQueue, 1)
                        ShowToast(next.name, next.online)
                    else
                        toastShowing = false
                    end
                else
                    toast:SetAlpha(alpha)
                end
            end)
        end
    end)
end

function ns.QueueToast(playerName, isOnline)
    if toastShowing then
        table.insert(toastQueue, { name = playerName, online = isOnline })
    else
        toastShowing = true
        ShowToast(playerName, isOnline)
    end
end

---------------------------------------------------------------------------
-- Friend Status Change Detection
---------------------------------------------------------------------------
function ns.CheckFriendStatusChanges()
    if not ns.db.settings.showOnlineNotifications then return end

    local currentOnline = {}
    local numFriends = C_FriendList.GetNumFriends()

    for i = 1, numFriends do
        local info = C_FriendList.GetFriendInfoByIndex(i)
        if info and info.name then
            local lower = info.name:lower()
            currentOnline[lower] = info.connected or false

            -- Only notify for people we have conversations with
            if initialized and ns.db.conversations[info.name] then
                local wasOnline = previousOnline[lower]
                local isOnline = info.connected or false

                if wasOnline ~= nil and wasOnline ~= isOnline then
                    ns.QueueToast(info.name, isOnline)
                end
            end
        end
    end

    previousOnline = currentOnline
    initialized = true
end
