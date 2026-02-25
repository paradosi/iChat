local addonName, ns = ...

---------------------------------------------------------------------------
-- Core — Entry point, event dispatch, slash commands, and combat hiding
--
-- Sets up the main event frame that routes WoW events to handler functions
-- on the addon namespace (ns). Initializes saved variables, registers
-- whisper events, builds the UI, and defines all /ichat slash commands.
---------------------------------------------------------------------------

-- Version read from TOC at load time (set in ADDON_LOADED)
ns.version = "?"
ns.playerName = nil
ns.activeConversation = nil

-- Event frame
local frame = CreateFrame("Frame", "iChatEventFrame", UIParent)
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(self, event, ...)
    if ns[event] then
        ns[event](ns, ...)
    end
end)

function ns:ADDON_LOADED(loadedName)
    if loadedName ~= addonName then return end
    frame:UnregisterEvent("ADDON_LOADED")

    ns.InitDB()
    ns.version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "?"
    ns.playerName = UnitName("player")

    -- Register whisper events
    frame:RegisterEvent("CHAT_MSG_WHISPER")
    frame:RegisterEvent("CHAT_MSG_WHISPER_INFORM")
    frame:RegisterEvent("CHAT_MSG_BN_WHISPER")
    frame:RegisterEvent("CHAT_MSG_BN_WHISPER_INFORM")
    frame:RegisterEvent("CHAT_MSG_AFK")
    frame:RegisterEvent("CHAT_MSG_DND")
    frame:RegisterEvent("FRIENDLIST_UPDATE")
    frame:RegisterEvent("IGNORELIST_UPDATE")
    frame:RegisterEvent("GUILD_ROSTER_UPDATE")
    frame:RegisterEvent("BN_FRIEND_LIST_SIZE_CHANGED")
    frame:RegisterEvent("BN_FRIEND_INFO_CHANGED")
    frame:RegisterEvent("CHAT_MSG_SYSTEM")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")

    -- Build the UI (hidden by default)
    ns.CreateMainWindow()

    -- Suppress whispers from default chat if enabled
    if ns.db.settings.suppressDefault then
        ns.RegisterChatFilters()
    end

    -- Create minimap button
    if ns.CreateMinimapButton then
        ns.CreateMinimapButton()
    end

    -- Hook typing indicator
    if ns.HookTypingIndicator then
        -- Delayed: input box is created in CreateMainWindow
        C_Timer.After(0.1, function()
            ns.HookTypingIndicator()
        end)
    end

    -- Register guild roster event
    if IsInGuild() then
        C_GuildInfo.GuildRoster()
    end

    -- Apply ElvUI skin if available
    if ns.db.settings.elvuiSkin and ns.ApplyElvUISkin then
        C_Timer.After(1, function()
            ns.ApplyElvUISkin()
        end)
    end

    -- Slash commands
    SLASH_ICHAT1 = "/ichat"
    SlashCmdList["ICHAT"] = function(msg)
        ns.SlashHandler(msg)
    end
end

-- Compatibility wrapper: C_FriendList is unavailable in Classic Era (11508)
local function RequestFriendList()
    if C_FriendList and C_FriendList.ShowFriends then
        C_FriendList.ShowFriends()
    else
        ShowFriends()
    end
end

function ns:PLAYER_LOGIN()
    ns.playerName = UnitName("player")
    RequestFriendList()
    frame:UnregisterEvent("PLAYER_LOGIN")

    -- Poll friend list every 60s to keep online status current
    C_Timer.NewTicker(60, function()
        RequestFriendList()
    end)
    
    -- Initial player info scans
    C_Timer.After(2, function()
        if ns.ScanFriendList then
            ns.ScanFriendList()
        end
        if ns.ScanGuildRoster then
            ns.ScanGuildRoster()
        end
    end)
end

-- Friend list updated - scan for player info
-- MOVED TO messages.lua to avoid conflict

-- Guild roster updated - scan for player info
-- MOVED TO social.lua to avoid conflict

-- BNet Friend list updated
function ns:BN_FRIEND_LIST_SIZE_CHANGED()
	if ns.RefreshConversationList then
		ns.RefreshConversationList()
	end
end

function ns:BN_FRIEND_INFO_CHANGED()
	if ns.RefreshConversationList then
		ns.RefreshConversationList()
	end
end

-- Hide window on combat start, restore on combat end
ns.wasShownBeforeCombat = false

function ns:PLAYER_REGEN_DISABLED()
    if not ns.db.settings.hideInCombat then return end
    if ns.mainWindow and ns.mainWindow:IsShown() then
        ns.wasShownBeforeCombat = true
        ns.mainWindow:Hide()
    end
end

function ns:PLAYER_REGEN_ENABLED()
    if not ns.db.settings.hideInCombat then return end
    if ns.wasShownBeforeCombat and ns.mainWindow then
        ns.mainWindow:Show()
        ns.wasShownBeforeCombat = false
    end
end

function ns.SlashHandler(msg)
    msg = (msg or ""):lower():match("^%s*(.-)%s*$") or ""

    if msg == "" then
        ns.ToggleWindow()
    elseif msg == "clear" then
        if ns.activeConversation and ns.db.conversations[ns.activeConversation] then
            wipe(ns.db.conversations[ns.activeConversation].messages)
            ns.db.conversations[ns.activeConversation].unread = 0
            ns.RebuildBubbles(ns.activeConversation)
            ns.RefreshConversationList()
            DEFAULT_CHAT_FRAME:AddMessage("|cff007AFFiChat:|r Cleared conversation with " .. ns.activeConversation)
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff007AFFiChat:|r No active conversation to clear.")
        end
    elseif msg == "emoji" then
        if ns.PrintEmojiList then
            ns.PrintEmojiList()
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff007AFFiChat:|r Emoji module not loaded.")
        end
    elseif msg:match("^scale%s+") then
        local s = tonumber(msg:match("^scale%s+(.+)"))
        if s and s >= 0.5 and s <= 2.0 then
            ns.db.settings.scale = s
            if ns.mainWindow then
                ns.mainWindow:SetScale(s)
            end
            DEFAULT_CHAT_FRAME:AddMessage("|cff007AFFiChat:|r Scale set to " .. s)
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff007AFFiChat:|r Scale must be between 0.5 and 2.0")
        end
    elseif msg == "autoreply" then
        ns.db.settings.autoReplyEnabled = not ns.db.settings.autoReplyEnabled
        if ns.db.settings.autoReplyEnabled then
            wipe(ns.autoRepliedTo or {})
            ns.autoRepliedTo = {}
            DEFAULT_CHAT_FRAME:AddMessage("|cff007AFFiChat:|r Auto-reply |cff00ff00enabled|r: " .. (ns.db.settings.autoReplyMessage or ""))
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff007AFFiChat:|r Auto-reply |cffff4444disabled|r")
        end
    elseif msg == "export" then
        if ns.ExportConversation then
            ns.ExportConversation()
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff007AFFiChat:|r Export not available.")
        end
    elseif msg == "version" or msg == "ver" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff007AFFiChat|r v" .. ns.version .. (ns.IsSharedAccount() and " (account-wide)" or " (per-character)"))
    elseif msg:match("^search%s+") then
        local query = msg:match("^search%s+(.+)")
        if query and ns.searchBox then
            if ns.mainWindow and not ns.mainWindow:IsShown() then
                ns.mainWindow:Show()
            end
            ns.searchBox:SetText(query)
            ns.searchBox:SetFocus()
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff007AFFiChat|r v" .. ns.version .. " — commands:")
        DEFAULT_CHAT_FRAME:AddMessage("  /ichat - Toggle window")
        DEFAULT_CHAT_FRAME:AddMessage("  /ichat clear - Clear current conversation")
        DEFAULT_CHAT_FRAME:AddMessage("  /ichat export - Export current conversation to text")
        DEFAULT_CHAT_FRAME:AddMessage("  /ichat scale <n> - Set scale (0.5-2.0)")
        DEFAULT_CHAT_FRAME:AddMessage("  /ichat emoji - Show available emoji shortcodes")
        DEFAULT_CHAT_FRAME:AddMessage("  /ichat autoreply - Toggle auto-reply")
        DEFAULT_CHAT_FRAME:AddMessage("  /ichat search <text> - Search conversations")
        DEFAULT_CHAT_FRAME:AddMessage("  /ichat version - Show version info")
    end
end

function ns.ToggleWindow()
    if ns.mainWindow then
        if ns.mainWindow:IsShown() then
            ns.mainWindow:Hide()
        else
            ns.mainWindow:Show()
            ns.RefreshConversationList()
        end
    end
end
