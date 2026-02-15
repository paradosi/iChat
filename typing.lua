local _, ns = ...

---------------------------------------------------------------------------
-- Typing Indicator — local-only visual sugar
--
-- YOUR typing: Shows "typing..." in the header subtitle when you type
-- THEIR typing: Brief animated "..." bubble when an incoming whisper arrives
---------------------------------------------------------------------------

local TYPING_TIMEOUT = 2.0       -- seconds before "typing" clears after you stop
local INCOMING_ANIM_DURATION = 1.5  -- how long the "..." shows before the real message

-- Dot animation frames
local DOT_FRAMES = { ".", "..", "..." }
local DOT_INTERVAL = 0.4

---------------------------------------------------------------------------
-- Outgoing typing indicator (you're typing)
---------------------------------------------------------------------------
local typingTimer = nil
local dotTicker = nil
local dotIndex = 1

local function StopTypingIndicator()
    if typingTimer then
        typingTimer:Cancel()
        typingTimer = nil
    end
    if dotTicker then
        dotTicker:Cancel()
        dotTicker = nil
    end
    -- Restore header note to contact note
    if ns.headerNote and ns.activeConversation then
        local note = ns.db.contactNotes and ns.db.contactNotes[ns.activeConversation] or ""
        ns.headerNote:SetText(note)
        ns.headerNote:SetTextColor(0.45, 0.45, 0.45)
    end
end

local function StartDotAnimation()
    if dotTicker then dotTicker:Cancel() end
    dotIndex = 1
    dotTicker = C_Timer.NewTicker(DOT_INTERVAL, function()
        if ns.headerNote then
            dotIndex = (dotIndex % #DOT_FRAMES) + 1
            ns.headerNote:SetText("typing" .. DOT_FRAMES[dotIndex])
            ns.headerNote:SetTextColor(0.5, 0.7, 1.0)
        end
    end)
    -- Show immediately
    if ns.headerNote then
        ns.headerNote:SetText("typing.")
        ns.headerNote:SetTextColor(0.5, 0.7, 1.0)
    end
end

function ns.OnTypingStarted()
    if not ns.activeConversation then return end
    if not ns.db.settings.showTypingIndicator then return end

    StartDotAnimation()

    -- Reset/start the timeout timer
    if typingTimer then typingTimer:Cancel() end
    typingTimer = C_Timer.NewTimer(TYPING_TIMEOUT, function()
        StopTypingIndicator()
    end)
end

function ns.OnTypingStopped()
    StopTypingIndicator()
end

---------------------------------------------------------------------------
-- Incoming typing animation (brief "..." bubble before message appears)
---------------------------------------------------------------------------
-- This is handled visually: when a whisper arrives, we briefly show a
-- typing bubble before displaying the actual message. Since we can't
-- predict incoming messages, we skip this for now and just add a subtle
-- "received" animation (message slides in). The typing indicator is
-- primarily for the outgoing side.
--
-- Future: Could use hidden addon messages (C_ChatInfo.SendAddonMessage)
-- with registered prefixes for iChat-to-iChat typing, but that requires
-- both parties to have the addon.
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- Hook: Call ns.OnTypingStarted() from the input box OnTextChanged
---------------------------------------------------------------------------
function ns.HookTypingIndicator()
    if not ns.inputBox then return end

    ns.inputBox:HookScript("OnTextChanged", function(self, userInput)
        if not userInput then return end
        local text = self:GetText()
        if text and text ~= "" then
            ns.OnTypingStarted()
        else
            ns.OnTypingStopped()
        end
    end)

    -- Clear typing when sending
    ns.inputBox:HookScript("OnEnterPressed", function()
        ns.OnTypingStopped()
    end)
end
