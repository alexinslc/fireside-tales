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
ns.FestivalStories = {}

local function append(target, stories)
	for _, story in ipairs(stories) do
		target[#target + 1] = story
	end
end

-- kind is "character", "race", "class", "zone", "festival", or "shared". key is
-- the character's first name, the race or class token, the zone's name as the
-- game shows it, or a festival's name from Seasons.lua ("shared" has no key).
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
		festival = ns.FestivalStories,
	}
	local list = lists[kind]
	list[key] = list[key] or {}
	append(list[key], stories)
end

-- Legends are real Warcraft stories told in parts, each part one sitting at the
-- fire. zone is where it happens, as the game names it.
ns.Legends = {}

function ns.AddLegend(zone, title, legend)
	legend.zone, legend.title = zone, title
	ns.Legends[#ns.Legends + 1] = legend
end

-- Stories players shared at firesidetales.dev, featured a week at a time. Community.lua
-- is written from the site, so each release carries the weeks ahead. week is the
-- Tuesday (UTC) it starts, as "YYYY-MM-DD".
ns.CommunityWeeks = {}

function ns.AddCommunityWeek(week, stories)
	for _, story in ipairs(stories) do
		-- kind marks pasted stories elsewhere, so a community story's kind goes by another name.
		story.communityKind, story.kind = story.kind, nil
		story.week = week
	end
	ns.CommunityWeeks[#ns.CommunityWeeks + 1] = { week = week, stories = stories }
	table.sort(ns.CommunityWeeks, function(a, b) return a.week < b.week end)
end

-- The Tuesday (UTC) the current week started, as "YYYY-MM-DD".
function ns.CommunityWeekStart(now)
	now = now or (GetServerTime and GetServerTime()) or time()
	local t = date("!*t", now)
	local daysSince = (t.wday - 3) % 7 -- wday 3 is Tuesday.
	local start = now - daysSince * 86400 - (t.hour * 3600 + t.min * 60 + t.sec)
	return date("!%Y-%m-%d", start)
end

-- Weeks that have started, newest first. The first is this week's, or the latest
-- one this copy of the addon has, if it hasn't been updated in a while.
function ns.CommunityWeeksSoFar(now)
	local current = ns.CommunityWeekStart(now)
	local out = {}
	for index = #ns.CommunityWeeks, 1, -1 do
		local week = ns.CommunityWeeks[index]
		if week.week <= current then out[#out + 1] = week end
	end
	return out, current
end

-- "by Mira, Roleplay", or "shared anonymously".
function ns.CommunityCredit(story)
	local author, ruleset = story.author or "", story.ruleset or ""
	if author ~= "" and ruleset ~= "" then return ("by %s, %s"):format(author, ruleset) end
	if author ~= "" then return "by " .. author end
	return "shared anonymously"
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
	["Alterac Mountains"] = { "alterac", "dalaran" },
	["Deadwind Pass"] = { "deadwind", "karazhan" },
	["Moonglade"] = { "nighthaven", "elune'ara" },
	["Mount Hyjal"] = { "hyjal" },
	["The Riverglades"] = { "riverglades" },
}
