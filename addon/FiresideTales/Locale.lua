-- Languages. The interface follows the game client's language. The stories follow the
-- player's chosen story language, which starts as the client's, so a German on an English
-- client can still tell them in German. Everything translated comes from the files in
-- locales/, which tools/i18n/build.mjs writes from translations/. A story is only shown
-- translated when all of it is; otherwise it stays in English.
--
-- Translated lines are still voiced: every language's lines are known, so a German line
-- heard by a French player plays the voice of the English line it was made from.
local _, ns = ...

ns.Locale = {}
local LC = ns.Locale

-- In menu order. The two Spanish clients each have their own translation.
LC.LANGUAGES = {
	{ code = "enUS", name = "English" },
	{ code = "deDE", name = "Deutsch" },
	{ code = "frFR", name = "Français" },
	{ code = "esES", name = "Español (España)" },
	{ code = "esMX", name = "Español (México)" },
	{ code = "ruRU", name = "Русский" },
	{ code = "koKR", name = "한국어" },
}
local SAME_AS = { enGB = "enUS" }

local strings = {} -- Interface text, by language, then the English text.
local translations = {} -- Story text, by language, then the English text.
local glossaries = {} -- Official names, by language: zones, festivals, zoneTerms.
local storyLanguage

local function supported(code)
	for _, language in ipairs(LC.LANGUAGES) do
		if language.code == code then return true end
	end
	return false
end

function LC.Name(code)
	for _, language in ipairs(LC.LANGUAGES) do
		if language.code == code then return language.name end
	end
	return code
end

-- The client's language, as one of ours, or English.
function LC.Client()
	local code = GetLocale and GetLocale() or "enUS"
	code = SAME_AS[code] or code
	return supported(code) and code or "enUS"
end

-- The language stories are told in. Set once the saved settings load.
function LC.Stories()
	return storyLanguage or LC.Client()
end

-------------------------------------------------------------------------------
-- Adding languages (from the files in locales/)
-------------------------------------------------------------------------------

function ns.AddStrings(code, map)
	strings[code] = map
end

function ns.AddTranslations(code, map)
	local into = translations[code] or {}
	translations[code] = into
	for english, text in pairs(map) do into[english] = text end
end

function ns.AddGlossary(code, glossary)
	glossaries[code] = glossary
end

-- L[text] is that English text in the client's language, or the English if it has none.
ns.L = setmetatable({}, {
	__index = function(_, key)
		local map = strings[LC.Client()]
		return map and map[key] or key
	end,
})

-- Story text (a heading, a title) in the story language, or as it is.
function LC.T(english)
	local map = translations[LC.Stories()]
	local text = map and map[english]
	return type(text) == "string" and text or english
end

-------------------------------------------------------------------------------
-- Text
-------------------------------------------------------------------------------

-- Lowercase, for searching and riddle answers. string.lower only knows A to Z, so the
-- capitals of the other languages here are lowered by hand: Latin-1 (Ä, É, Ñ) and Cyrillic.
local UPPER_TO_LOWER = {}
for code = 0xC0, 0xDE do
	if code ~= 0xD7 then UPPER_TO_LOWER[code] = code + 32 end
end
for code = 0x410, 0x42F do UPPER_TO_LOWER[code] = code + 32 end
UPPER_TO_LOWER[0x401] = 0x451 -- Ё

local function utf8char(code)
	if code < 0x80 then return string.char(code) end
	if code < 0x800 then return string.char(0xC0 + math.floor(code / 64), 0x80 + code % 64) end
	return string.char(0xE0 + math.floor(code / 4096), 0x80 + math.floor(code / 64) % 64, 0x80 + code % 64)
end

local LOWER_BYTES = {}
for upper, lower in pairs(UPPER_TO_LOWER) do LOWER_BYTES[utf8char(upper)] = utf8char(lower) end

function LC.Lower(text)
	return (text:lower():gsub("[\192-\223][\128-\191]", LOWER_BYTES))
end

-------------------------------------------------------------------------------
-- Places and festivals
-------------------------------------------------------------------------------

-- The client names zones in its own language; the stories are filed under the English name.
local zoneKeys
function LC.ZoneKey(shown)
	if not shown then return nil end
	if not zoneKeys then
		zoneKeys = {}
		for _, glossary in pairs(glossaries) do
			for english, name in pairs(glossary.zones or {}) do zoneKeys[name] = english end
		end
	end
	return zoneKeys[shown] or shown
end

-- A zone's name in the story language.
function LC.ZoneName(english)
	local glossary = glossaries[LC.Stories()]
	return glossary and glossary.zones and glossary.zones[english] or english
end

-- Lowercase words that mean a zone in the story language: its name and places in it.
function LC.ZoneTerms(english)
	local code = LC.Stories()
	if code == "enUS" then return nil end
	local glossary = glossaries[code]
	local terms = { LC.Lower(LC.ZoneName(english)) }
	for _, term in ipairs(glossary and glossary.zoneTerms and glossary.zoneTerms[english] or {}) do
		terms[#terms + 1] = LC.Lower(term)
	end
	return terms
end

-- A festival's name in the story language.
function LC.FestivalName(english)
	local glossary = glossaries[LC.Stories()]
	return glossary and glossary.festivals and glossary.festivals[english] or english
end

-- Words that find a festival in the calendar, which is in the client's language.
function LC.FestivalKeyword(festival)
	local glossary = glossaries[LC.Client()]
	local name = glossary and glossary.festivals and glossary.festivals[festival.name]
	return name and LC.Lower(name) or festival.keyword
end

-------------------------------------------------------------------------------
-- Telling the stories in the story language
-------------------------------------------------------------------------------

-- A line too long for chat in another language is split into parts, each said with its
-- own press of Speak. source is the English line, for the voices; part > 1 is said silently.
local function translateLines(lines, map)
	local out = {}
	for _, line in ipairs(lines) do
		local text = map[line.text]
		if type(text) == "table" then
			for index, part in ipairs(text) do
				out[#out + 1] = { kind = line.kind, text = part, source = line.text, part = index }
			end
		else
			out[#out + 1] = { kind = line.kind, text = text, source = line.text }
		end
	end
	return out
end

local function answersKey(answers)
	return "answers: " .. table.concat(answers, " | ")
end
LC.AnswersKey = answersKey

-- Whether every piece of a story has a translation.
local function complete(story, map)
	if story.title and not map[story.title] then return false end
	for _, line in ipairs(story.lines or {}) do
		if not map[line.text] then return false end
	end
	if story.riddle then
		if not (map[story.hint] and map[story.answer] and map[answersKey(story.answers)]) then return false end
	end
	return true
end

-- Changes a story in place. Its key keeps using the English title, so what's been told and
-- the favorites stay the same whichever language it's told in.
local function translateStory(story, map)
	if story.sourceTitle or not complete(story, map) then return end
	story.sourceTitle = story.title
	if story.title then story.title = map[story.title] end
	story.lines = translateLines(story.lines or {}, map)
	if story.riddle then
		story.hint, story.answer = map[story.hint], map[story.answer]
		-- English answers count too, since not everyone at the fire plays in one language.
		local answers = {}
		for _, answer in ipairs(map[answersKey(story.answers)]) do answers[#answers + 1] = answer end
		for _, answer in ipairs(story.answers) do answers[#answers + 1] = answer end
		story.answers = answers
	end
end

local function translateAll(list, map)
	for _, story in ipairs(list or {}) do translateStory(story, map) end
end

local function translateKeyed(lists, map)
	for _, list in pairs(lists) do translateAll(list, map) end
end

-- Openers and closers are lines, each one its own little story.
local function translatePools(pools, map)
	for which, pool in pairs(pools or {}) do
		local out = {}
		for _, line in ipairs(pool) do
			local text = map[line.text]
			if type(text) == "string" then
				out[#out + 1] = { kind = line.kind, text = text, source = line.text }
			elseif type(text) ~= "table" then
				out[#out + 1] = line -- Parts make no sense for one line; it stays English.
			end
		end
		pools[which] = out
	end
end

-- Called once the saved settings load, before anything lists a story.
function LC.Apply(db)
	storyLanguage = db and supported(db.storyLanguage) and db.storyLanguage or nil
	local map = translations[LC.Stories()]
	if not map then return end
	translateAll(ns.Stories, map)
	translateAll(ns.TargetStories, map)
	translateKeyed(ns.RaceStories, map)
	translateKeyed(ns.ClassStories, map)
	translateKeyed(ns.ZoneStories, map)
	translateKeyed(ns.FestivalStories, map)
	translateAll(ns.Riddles, map)
	for _, legend in ipairs(ns.Legends or {}) do
		local done = true
		for _, part in ipairs(legend.parts) do done = done and complete(part, map) end
		if done and map[legend.title] then
			translateAll(legend.parts, map)
			legend.label = map[legend.title]
			if legend.summary then legend.summary = map[legend.summary] or legend.summary end
		end
	end
	for _, week in ipairs(ns.CommunityWeeks or {}) do translateAll(week.stories, map) end
	translatePools(ns.Openers, map)
	translatePools(ns.Closers, map)
end

-- The language to tell stories in from the next /reload. nil goes back to the client's.
function LC.SetStories(db, code)
	if code ~= nil and not supported(code) then return false end
	db.storyLanguage = code
	return true
end

-------------------------------------------------------------------------------
-- Voices
-------------------------------------------------------------------------------

-- For a line heard in chat in any language: the English line it was made from, and
-- whether it's a later part of a split line (which has no sound of its own).
-- A {target} line arrives with a name in its place, so those are found by pattern.
local sources, targetSources
local function addSource(text, english, later)
	if text:find("{target}", 1, true) then
		local pattern = text:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0"):gsub("{target}", ".+")
		targetSources[#targetSources + 1] = { "^" .. pattern .. "$", english, later }
	else
		sources[text] = sources[text] or { english, later }
	end
end

function LC.SourceLine(text)
	if not sources then
		sources, targetSources = {}, {}
		for _, map in pairs(translations) do
			for english, translated in pairs(map) do
				if type(translated) == "string" then
					addSource(translated, english, false)
				elseif type(translated) == "table" and english:sub(1, 9) ~= "answers: " then
					for index, part in ipairs(translated) do addSource(part, english, index > 1) end
				end
			end
		end
	end
	local found = sources[text]
	if found then return found[1], found[2] end
	for _, line in ipairs(targetSources) do
		if text:find(line[1]) then return line[2], line[3] end
	end
end

-- For the harness: what's loaded.
function LC.Loaded()
	return strings, translations, glossaries
end
