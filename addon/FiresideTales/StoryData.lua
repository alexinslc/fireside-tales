-- Lets later story files add to the lists. Loaded after the first story files.
local _, ns = ...

ns.ZoneStories = {}

-- Some story files stay local and aren't in the repository, so a fresh copy may
-- not have these yet.
ns.Stories = ns.Stories or {}
ns.CharacterStories = ns.CharacterStories or {}
ns.RaceStories = ns.RaceStories or {}
ns.ClassStories = ns.ClassStories or {}
ns.TargetStories = {}

local function append(target, stories)
	for _, story in ipairs(stories) do
		target[#target + 1] = story
	end
end

-- kind is "character", "race", "class", "zone", or "shared". key is the
-- character's first name, the race or class token, or the zone's name as the
-- game shows it ("shared" has no key).
function ns.AddStories(kind, key, stories)
	if kind == "shared" then
		append(ns.Stories, stories)
		return
	end
	local lists = {
		character = ns.CharacterStories,
		race = ns.RaceStories,
		class = ns.ClassStories,
		zone = ns.ZoneStories,
	}
	local list = lists[kind]
	list[key] = list[key] or {}
	append(list[key], stories)
end

-- A story counts as being about a zone if its text mentions the zone's full name
-- or one of these words. Lowercase only. Add places within a zone here too.
ns.ZoneTerms = {
	["Elwynn Forest"] = { "elwynn", "goldshire", "northshire", "crystal lake", "echo ridge" },
	["Stormwind City"] = { "stormwind" },
	["Westfall"] = { "sentinel hill", "moonbrook" },
	["Redridge Mountains"] = { "redridge", "lakeshire" },
	["Duskwood"] = { "darkshire", "raven hill" },
	["Stranglethorn Vale"] = { "stranglethorn", "booty bay" },
	["Dun Morogh"] = { "kharanos", "coldridge" },
	["Loch Modan"] = { "thelsamar" },
	["Teldrassil"] = { "shadowglen", "dolanaar" },
	["Tirisfal Glades"] = { "tirisfal", "deathknell" },
	["Mulgore"] = { "bloodhoof", "red cloud" },
	["Durotar"] = { "razor hill", "valley of trials" },
	["Hillsbrad Foothills"] = { "hillsbrad", "southshore", "tarren mill" },
	["Silverpine Forest"] = { "silverpine", "pyrewood" },
	["Burning Steppes"] = { "blackrock" },
	["Eastern Plaguelands"] = { "stratholme" },
	["Western Plaguelands"] = { "andorhal" },
	["Un'Goro Crater"] = { "un'goro" },
	["Tanaris"] = { "gadgetzan" },
	["Zephras Isle"] = { "zephras" },
}
