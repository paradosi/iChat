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
	if not ns.db then return end -- Guard
	
	local bare = name:match("^([^%-]+)") or name
	
	if not ns.db.playerInfoCache then
		ns.db.playerInfoCache = {}
	end
	
	ns.db.playerInfoCache[bare] = info
end

-- Scan friend list and cache all info (Single pass)
function ns.ScanFriendList()
	local numFriends = 0
	local GetInfo
	
	if C_FriendList and C_FriendList.GetNumFriends then
		numFriends = C_FriendList.GetNumFriends()
		GetInfo = C_FriendList.GetFriendInfoByIndex
	else
		numFriends = GetNumFriends()
		GetInfo = function(i)
			local name, level, className, area, connected = GetFriendInfo(i)
			if name then
				return { name = name, className = className, connected = connected }
			end
		end
	end

	for i = 1, numFriends do
		local info = GetInfo(i)
		if info and info.name and info.connected then
			-- Friend info provides localized class name; need to map to token
			local className = info.className
			local classFile = nil
			
			if className and LOCALIZED_CLASS_NAMES_MALE then
				-- Try to find class token from localized name
				for token, localizedName in pairs(LOCALIZED_CLASS_NAMES_MALE) do
					if localizedName == className then
						classFile = token
						break
					end
				end
				-- Fallback for female names if needed (usually MALE table covers generic)
				if not classFile and LOCALIZED_CLASS_NAMES_FEMALE then
					for token, localizedName in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do
						if localizedName == className then
							classFile = token
							break
						end
					end
				end
			end
			
			if classFile then
				local playerInfo = {
					class = className,
					classFile = classFile,
					race = nil, -- Friend list API doesn't provide race
					raceFile = nil,
				}
				ns.CachePlayerInfo(info.name, playerInfo)
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
