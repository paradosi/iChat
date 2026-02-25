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
--   ns.ScanFriendList()        → scan friends and cache their info
--   ns.ScanGuildRoster()       → scan guild and cache their info
--   ns.CacheUnitInfo(name, unit) → cache info from a visible unit
---------------------------------------------------------------------------

-- Get player info from cache, friend list, guild roster, or visible unit
-- Returns { class, race, classFile, raceFile } or nil
function ns.GetPlayerInfo(name)
	if not name then return nil end
	
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
	if ns.db.playerInfoCache and ns.db.playerInfoCache[bare] then
		return ns.db.playerInfoCache[bare]
	end
	
	-- Try friend list
	local numFriends = C_FriendList.GetNumFriends()
	for i = 1, numFriends do
		local info = C_FriendList.GetFriendInfoByIndex(i)
		if info and info.name == bare then
			local classFile, class = UnitClass(info.name)
			if classFile then
				local _, raceFile = UnitRace(info.name)
				local playerInfo = {
					class = class,
					classFile = classFile,
					race = info.name and select(2, UnitRace(info.name)),
					raceFile = raceFile,
				}
				ns.CachePlayerInfo(bare, playerInfo)
				return playerInfo
			end
		end
	end
	
	-- Try guild roster
	if IsInGuild() then
		local numTotal = GetNumGuildMembers()
		for i = 1, numTotal do
			local gName, _, _, _, _, _, _, _, _, _, classFile = GetGuildRosterInfo(i)
			if gName and gName == bare then
				local class = classFile and LOCALIZED_CLASS_NAMES_MALE[classFile]
				if class then
					-- Guild roster doesn't provide race, but we can try to get it from unit
					local unit = ns.FindUnitByName(bare)
					local _, raceFile = unit and UnitRace(unit) or nil, nil
					local playerInfo = {
						class = class,
						classFile = classFile,
						race = nil, -- guild roster doesn't have race
						raceFile = raceFile,
					}
					ns.CachePlayerInfo(bare, playerInfo)
					return playerInfo
				end
			end
		end
	end
	
	-- Try visible unit (target, focus, party, raid)
	local unit = ns.FindUnitByName(bare)
	if unit then
		local classFile, class = UnitClass(unit)
		local _, raceFile = UnitRace(unit)
		if classFile then
			local playerInfo = {
				class = class,
				classFile = classFile,
				race = select(2, UnitRace(unit)),
				raceFile = raceFile,
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
	local bare = name:match("^([^%-]+)") or name
	
	if not ns.db.playerInfoCache then
		ns.db.playerInfoCache = {}
	end
	
	ns.db.playerInfoCache[bare] = info
end

-- Scan friend list and cache all info
function ns.ScanFriendList()
	local numFriends = C_FriendList.GetNumFriends()
	for i = 1, numFriends do
		local info = C_FriendList.GetFriendInfoByIndex(i)
		if info and info.name then
			-- Try to get class/race if they're online
			if info.connected then
				local playerInfo = ns.GetPlayerInfo(info.name)
				-- GetPlayerInfo will cache it if found
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
		if name and online and classFile then
			local class = LOCALIZED_CLASS_NAMES_MALE[classFile]
			if class then
				local playerInfo = {
					class = class,
					classFile = classFile,
					race = nil,
					raceFile = nil,
				}
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
