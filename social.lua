local _, ns = ...

---------------------------------------------------------------------------
-- Guild / Party / Raid Awareness
-- Provides role icons and info next to conversation names
---------------------------------------------------------------------------

-- Cache guild roster
ns.guildCache = {}

function ns.RefreshGuildRoster()
    wipe(ns.guildCache)
    if not IsInGuild() then return end

    local numTotal = GetNumGuildMembers()
    for i = 1, numTotal do
        local name, rankName, rankIndex, level, className, _, _, _, isOnline = GetGuildRosterInfo(i)
        if name then
            local shortName = Ambiguate(name, "none")
            ns.guildCache[shortName:lower()] = {
                rank = rankName,
                rankIndex = rankIndex,
                level = level,
                className = className,
                online = isOnline,
            }
        end
    end
end

-- Check relationships for a player
function ns.GetPlayerRelationship(name)
    if not name then return nil end
    local lower = name:lower()
    local tags = {}

    -- Guild
    if ns.guildCache[lower] then
        local info = ns.guildCache[lower]
        table.insert(tags, { icon = "|TInterface\\GossipFrame\\TabardGossipIcon:12|t", text = info.rank, type = "guild" })
    end

    -- Party/Raid
    if UnitInParty(name) then
        local role = UnitGroupRolesAssigned(name)
        local roleIcon = ""
        if role == "TANK" then
            roleIcon = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:12:12:0:0:64:64:0:19:22:41|t "
        elseif role == "HEALER" then
            roleIcon = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:12:12:0:0:64:64:20:39:1:20|t "
        elseif role == "DAMAGER" then
            roleIcon = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:12:12:0:0:64:64:20:39:22:41|t "
        end
        table.insert(tags, { icon = roleIcon, text = "Party", type = "party" })
    elseif UnitInRaid(name) then
        table.insert(tags, { icon = "|TInterface\\GroupFrame\\UI-Group-LeaderIcon:12|t", text = "Raid", type = "raid" })
    end

    -- Friend (already tracked by messages.lua, but add tag)
    if ns.IsFriend(name) then
        table.insert(tags, { icon = "", text = "Friend", type = "friend" })
    end

    return tags
end

-- Format relationship tags as a colored string for display
function ns.FormatRelationshipTags(name)
    local tags = ns.GetPlayerRelationship(name)
    if not tags or #tags == 0 then return "" end

    local parts = {}
    for _, tag in ipairs(tags) do
        local color = "|cff888888"
        if tag.type == "guild" then color = "|cff40c040" end
        if tag.type == "party" then color = "|cff5599ff" end
        if tag.type == "raid" then color = "|cffff9900" end
        table.insert(parts, color .. (tag.icon or "") .. tag.text .. "|r")
    end
    return table.concat(parts, " ")
end

---------------------------------------------------------------------------
-- Hook into guild roster updates
---------------------------------------------------------------------------
function ns:GUILD_ROSTER_UPDATE()
    ns.RefreshGuildRoster()
end
