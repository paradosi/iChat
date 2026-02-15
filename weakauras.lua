local _, ns = ...

---------------------------------------------------------------------------
-- WeakAuras Integration
-- Exposes iChat events via a custom event frame that WeakAuras can listen to
--
-- WeakAuras trigger setup:
--   Type: Custom > Event
--   Event: ICHAT_WHISPER_RECEIVED, ICHAT_WHISPER_SENT,
--          ICHAT_FRIEND_ONLINE, ICHAT_FRIEND_OFFLINE,
--          ICHAT_UNREAD_CHANGED
--
-- Example custom trigger:
--   function(event, sender, message)
--       if event == "ICHAT_WHISPER_RECEIVED" then return true end
--   end
---------------------------------------------------------------------------

local eventFrame = CreateFrame("Frame", "iChatEvents", UIParent)

-- Fire a custom event that WeakAuras can pick up
function ns.FireEvent(eventName, ...)
    if WeakAuras then
        WeakAuras.ScanEvents(eventName, ...)
    end
end

-- Convenience wrappers (called from messages.lua and notifications.lua)
function ns.FireWhisperReceived(sender, text)
    ns.FireEvent("ICHAT_WHISPER_RECEIVED", sender, text)
end

function ns.FireWhisperSent(target, text)
    ns.FireEvent("ICHAT_WHISPER_SENT", target, text)
end

function ns.FireFriendOnline(name)
    ns.FireEvent("ICHAT_FRIEND_ONLINE", name)
end

function ns.FireFriendOffline(name)
    ns.FireEvent("ICHAT_FRIEND_OFFLINE", name)
end

function ns.FireUnreadChanged(total)
    ns.FireEvent("ICHAT_UNREAD_CHANGED", total)
end
