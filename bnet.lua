local _, ns = ...

---------------------------------------------------------------------------
-- Battle.net Integration
--
-- Handles BNet whispers, friend list, and sending messages to RealID friends.
-- BNet conversations are stored with "BNet:" prefix to differentiate from
-- regular whispers (e.g., "BNet:12345" where 12345 is bnetIDAccount).
--
-- Public API:
--   ns.GetBNetFriendInfo(bnetIDAccount)  → returns friend info table or nil
--   ns.GetBNetPresenceID(bnetIDAccount)  → returns presenceID for friend
--   ns.IsBNetConversation(name)          → returns true if name starts with "BNet:"
--   ns.GetBNetIDFromName(name)           → extracts bnetIDAccount from "BNet:12345"
--   ns.GetBNetDisplayName(bnetIDAccount) → returns display name for conversation list
---------------------------------------------------------------------------

-- Check if a conversation is a BNet conversation
function ns.IsBNetConversation(name)
	return name and name:sub(1, 5) == "BNet:"
end

-- Extract bnetIDAccount from conversation name
function ns.GetBNetIDFromName(name)
	if not ns.IsBNetConversation(name) then return nil end
	return tonumber(name:sub(6))
end

-- Get BNet friend info by bnetIDAccount
function ns.GetBNetFriendInfo(bnetIDAccount)
	if not bnetIDAccount then return nil end
	
	local numFriends = BNGetNumFriends()
	for i = 1, numFriends do
		local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
		if accountInfo and accountInfo.bnetAccountID == bnetIDAccount then
			return accountInfo
		end
	end
	
	return nil
end

-- Get presenceID for a bnetIDAccount (needed for some APIs)
function ns.GetBNetPresenceID(bnetIDAccount)
	local info = ns.GetBNetFriendInfo(bnetIDAccount)
	return info and info.bnetAccountID
end

-- Get BattleTag/account name for BNet friend (prefers accountName like "Jim Fano")
function ns.GetBNetBattleTag(bnetIDAccount)
	local info = ns.GetBNetFriendInfo(bnetIDAccount)
	if not info then
		return "BNet Friend #" .. (bnetIDAccount or "?")
	end
	-- Prefer accountName ("Jim Fano") over battleTag ("FANO#11843")
	return info.accountName or info.battleTag or ("BNet #" .. bnetIDAccount)
end

-- Get character name for BNet friend (if playing WoW)
function ns.GetBNetCharacterName(bnetIDAccount)
	local info = ns.GetBNetFriendInfo(bnetIDAccount)
	if not info or not info.gameAccountInfo then
		return nil
	end
	
	local gameInfo = info.gameAccountInfo
	if gameInfo.isOnline and gameInfo.clientProgram == BNET_CLIENT_WOW then
		local charName = gameInfo.characterName
		local realmName = gameInfo.realmName
		if charName then
			return charName .. (realmName and ("-" .. realmName) or "")
		end
	end
	
	return nil
end

-- Get display name for BNet friend (BattleTag (CharacterName) format)
function ns.GetBNetDisplayName(bnetIDAccount)
	local battleTag = ns.GetBNetBattleTag(bnetIDAccount)
	local charName = ns.GetBNetCharacterName(bnetIDAccount)
	
	if charName then
		return battleTag .. " (" .. charName .. ")"
	end
	
	return battleTag
end

-- Get BNet friend's class/race info (for WoW characters)
function ns.GetBNetPlayerInfo(bnetIDAccount)
	local info = ns.GetBNetFriendInfo(bnetIDAccount)
	if not info or not info.gameAccountInfo then return nil end
	
	local gameInfo = info.gameAccountInfo
	if not gameInfo.isOnline or gameInfo.clientProgram ~= BNET_CLIENT_WOW then
		return nil
	end
	
	local className = gameInfo.className
	local raceName = gameInfo.raceName
	
	if not className then return nil end
	
	-- Convert localized class name to classFile
	local classFile
	for file, name in pairs(LOCALIZED_CLASS_NAMES_MALE) do
		if name == className then
			classFile = file
			break
		end
	end
	
	return {
		class = className,
		classFile = classFile,
		race = raceName,
		raceFile = nil, -- BNet API doesn't provide race file
	}
end

-- Send a BNet whisper
function ns.SendBNetWhisper(bnetIDAccount, message)
	if not bnetIDAccount or not message or message == "" then return end
	BNSendWhisper(bnetIDAccount, message)
end

-- Get game info string for header display
function ns.GetBNetGameInfo(bnetIDAccount)
	local info = ns.GetBNetFriendInfo(bnetIDAccount)
	if not info or not info.gameAccountInfo or not info.gameAccountInfo.isOnline then
		return "Offline"
	end
	
	local gameInfo = info.gameAccountInfo
	local client = gameInfo.clientProgram or "?"
	
	-- WoW-specific info
	if client == BNET_CLIENT_WOW then
		local charName = gameInfo.characterName or "Unknown"
		local level = gameInfo.characterLevel or "?"
		local className = gameInfo.className or "?"
		return string.format("WoW: %s (L%s %s)", charName, level, className)
	end
	
	-- Other games
	local gameNames = {
		[BNET_CLIENT_D3] = "Diablo 3",
		[BNET_CLIENT_WTCG] = "Hearthstone",
		[BNET_CLIENT_HEROES] = "Heroes of the Storm",
		[BNET_CLIENT_OVERWATCH] = "Overwatch",
		[BNET_CLIENT_SC2] = "StarCraft 2",
		[BNET_CLIENT_SC] = "StarCraft",
		[BNET_CLIENT_DESTINY2] = "Destiny 2",
		[BNET_CLIENT_COD] = "Call of Duty",
		[BNET_CLIENT_COD_MW] = "Modern Warfare",
		[BNET_CLIENT_COD_MW2] = "Modern Warfare 2",
	}
	
	return gameNames[client] or ("Playing " .. (client or "Unknown"))
end
