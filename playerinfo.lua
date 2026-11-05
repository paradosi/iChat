local _, ns = ...

---------------------------------------------------------------------------
-- Player Info Cache — Class/race caching from friends, guild, and units
--
-- Scans friend list and guild roster to cache class/race info for players.
-- This allows class-colored names and race icons to work even when the
-- player is not currently visible as a unit (target, party, raid, focus).
--
-- Public API:
--   ns.GetPlayerInfo(name)     → returns { class, race, classFile, raceFile } or nil
--   ns.GetFriends()            → the friend list as plain tables, read once
--   ns.ScanFriendList([friends]) → cache class info for online friends
--   ns.ScanGuildRoster()       → scan guild and cache their info
--   ns.CachePlayerInfo(name, info) → cache an info table for a player
---------------------------------------------------------------------------

-- Get player info from cache, friend list, guild roster, or visible unit
-- Returns { class, race, classFile, raceFile } or nil
function ns.GetPlayerInfo(name)
	if not name then return nil end
	
	-- Guard: ns.db might not be initialized yet
	if not ns.db or not ns.db.playerInfoCache then return nil end
	
	-- Check if this is a BNet conversation
	if ns.IsBNetConversation and ns.IsBNetConversation(name) then
		local bnetIDAccount = ns.GetBNetIDFromName and ns.GetBNetIDFromName(name)
		if bnetIDAccount and ns.GetBNetPlayerInfo then
			return ns.GetBNetPlayerInfo(bnetIDAccount)
		end
		return nil
	end
	
	-- Strip realm suffix for lookup
	local bare = name:match("^([^%-]+)") or name
	
	-- Check cache first
	if ns.db.playerInfoCache[bare] then
		return ns.db.playerInfoCache[bare]
	end
	
	-- Note: Friend/Guild scanning is now proactive (pushed into cache), 
	-- so we don't need to re-scan on every GetPlayerInfo call.
	-- Just check visible units as a fallback.
	
	-- Try visible unit (target, focus, party, raid)
	local unit = ns.FindUnitByName(bare)
	if unit then
		local class, classFile = UnitClass(unit)
		local raceName, raceFile = UnitRace(unit)
		if classFile then
			local playerInfo = {
				class = class,
				classFile = classFile,
				race = raceName,
				raceFile = raceFile,
				level = UnitLevel(unit),
			}
			ns.CachePlayerInfo(bare, playerInfo)
			return playerInfo
		end
	end
	
	return nil
end

-- Cache player info to database
function ns.CachePlayerInfo(name, info)
	if not name or not info then return end
	if not ns.db then return end -- Guard
	
	local bare = name:match("^([^%-]+)") or name
	
	if not ns.db.playerInfoCache then
		ns.db.playerInfoCache = {}
	end
	
	ns.db.playerInfoCache[bare] = info
end

-- Localized class name -> class token ("Krieger"/"Kriegerin" -> "WARRIOR").
-- The friend list gives localized names; RAID_CLASS_COLORS wants tokens.
local classTokenByName
function ns.ClassTokenFromName(className)
	if not className then return nil end
	if not classTokenByName then
		classTokenByName = {}
		for i = 1, (GetNumClasses and GetNumClasses() or 0) do
			local name, token = GetClassInfo(i)
			if name and token then classTokenByName[name] = token end
		end
		for _, names in ipairs({ LOCALIZED_CLASS_NAMES_MALE or {}, LOCALIZED_CLASS_NAMES_FEMALE or {} }) do
			for token, name in pairs(names) do
				classTokenByName[name] = classTokenByName[name] or token
			end
		end
	end
	return classTokenByName[className]
end

-- The friend list, read once into plain tables:
-- { name, level, className, area, connected }
function ns.GetFriends()
	local friends = {}
	if C_FriendList and C_FriendList.GetNumFriends then
		for i = 1, C_FriendList.GetNumFriends() do
			local info = C_FriendList.GetFriendInfoByIndex(i)
			if info and info.name then friends[#friends + 1] = info end
		end
	elseif GetNumFriends then
		for i = 1, GetNumFriends() do
			local name, level, className, area, connected = GetFriendInfo(i)
			if name then
				friends[#friends + 1] = { name = name, level = level, className = className, area = area, connected = connected }
			end
		end
	end
	return friends
end

-- Cache class/level/zone for online friends. Pass the list from
-- ns.GetFriends() when you already have it.
function ns.ScanFriendList(friends)
	for _, info in ipairs(friends or ns.GetFriends()) do
		if info.connected then
			local classFile = ns.ClassTokenFromName(info.className)
			if classFile then
				ns.CachePlayerInfo(info.name, {
					class = info.className,
					classFile = classFile,
					race = nil, -- Friend list API doesn't provide race
					raceFile = nil,
					level = info.level,
					area = info.area,
				})
			end
		end
	end
end

-- Scan guild roster and cache all info
function ns.ScanGuildRoster()
	if not IsInGuild() then return end
	
	local numTotal = GetNumGuildMembers()
	for i = 1, numTotal do
		local name, _, _, _, _, _, _, online, _, _, classFile = GetGuildRosterInfo(i)
		if name and classFile then -- Cache even if offline, why not
			local class = LOCALIZED_CLASS_NAMES_MALE[classFile]
			if class then
				local playerInfo = {
					class = class,
					classFile = classFile,
					race = nil,
					raceFile = nil,
				}
				-- name from GuildRoster is "Name-Realm", CachePlayerInfo handles stripping
				ns.CachePlayerInfo(name, playerInfo)
			end
		end
	end
end

-- Helper: Find unit by name (from portraits.lua logic)
-- Scans visible unit IDs (player, target, focus, party, raid)
function ns.FindUnitByName(name)
	if not name then return nil end
	local bare = name:match("^([^%-]+)") or name

	local function matches(unit)
		local n = UnitName(unit)
		-- Retail: names of units outside the group can be secret on restricted maps
		if not ns.CanRead(n) then return false end
		return n == bare or n == name
	end

	if UnitExists("player") and matches("player") then return "player" end
	if UnitExists("target") and matches("target") then return "target" end
	if UnitExists("focus")  and matches("focus")  then return "focus"  end
	for i = 1, 4 do
		local u = "party" .. i
		if UnitExists(u) and matches(u) then return u end
	end
	for i = 1, 40 do
		local u = "raid" .. i
		if UnitExists(u) and matches(u) then return u end
	end
	return nil
end
