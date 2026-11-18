-- Voices: when someone nearby tells a Fireside Tales story, or you do, each line they say is
-- read aloud. A teller is read in the voice of their race and sex where that voice pack is
-- installed, and by the narrator otherwise. It only listens to chat, and never sends anything.
--
-- The sounds are separate addons, the voice packs, which add each voice with FiresideTales_AddVoice.
-- ns.VoiceLines (VoiceLines.lua, written by tools/voice/build.mjs) holds the lines they have.
local _, ns = ...

ns.Voices = {}
local V = ns.Voices

-- Chat can repeat a line (two chat frames, a reload); the same teller's line plays once in this time.
local REPEAT_SECONDS = 30
-- A teller who speaks faster than the voice shouldn't leave listeners far behind: past this
-- many waiting lines, the oldest is dropped.
local QUEUE_LIMIT = 2
local GAP_SECONDS = 0.4
-- Master, as Spoken uses: the game plays its own voices on Dialog and can cut a sound off there
-- partway through.
local CHANNEL = "Master"

local KIND_BY_EVENT = { CHAT_MSG_SAY = "say", CHAT_MSG_EMOTE = "emote" }

-- The voice packs there are, for the Voices tab, whether or not they're installed: one per race
-- (each with its men and women), the narrator, and the community stories, in groups.
local function pack(name, title, size)
	return { addon = "FiresideTalesVoices_" .. name, title = title, size = size,
		url = "curseforge.com/wow/addons/fireside-tales-voices-" .. title:lower():gsub(" ", "-") }
end
V.PACKS = {
	{ title = "Alliance", about = "Human, Dwarf, Night Elf, and Gnome tellers, men and women.", packs = {
		pack("Human", "Human", "about 245 MB"), pack("Dwarf", "Dwarf", "about 265 MB"),
		pack("NightElf", "Night Elf", "about 275 MB"), pack("Gnome", "Gnome", "about 270 MB") } },
	{ title = "Horde", about = "Orc, Undead, Tauren, and Troll tellers, men and women.", packs = {
		pack("Orc", "Orc", "about 255 MB"), pack("Undead", "Undead", "about 295 MB"),
		pack("Tauren", "Tauren", "about 295 MB"), pack("Troll", "Troll", "about 295 MB") } },
	{ title = "Skyborne", about = "Skyborne tellers of either faction, men and women.", packs = {
		pack("Skyborne", "Skyborne", "about 250 MB") } },
	{ title = "Narrator", about = "Reads every teller whose race voice isn't installed.", packs = {
		pack("Narrator", "Narrator", "about 130 MB") } },
	{ title = "Community Stories", about = "This week's community stories from firesidetales.dev, in every voice.",
		packs = { pack("Community", "Community", "new each week, up to about 350 MB") } },
}

local voices = {} -- By key, from the packs.
local queue, playing = {}, nil
local heard = {}

local function say(msg)
	print("|cffd4af37Fireside Tales:|r " .. msg)
end

local plain = function(value)
	if value ~= nil and issecretvalue and issecretvalue(value) then return nil end
	return value
end

-- The text as the lines table holds it.
local function tidy(text)
	return (text:gsub("%s+", " "):gsub("^ ", ""):gsub(" $", ""))
end

local function shortName(name)
	if Ambiguate then return Ambiguate(name, "short") end
	return (name:gsub("%-.*$", ""))
end

local function isPlayer(name, guid)
	if guid and UnitGUID and guid == plain(UnitGUID("player")) then return true end
	return name ~= nil and shortName(name) == plain(UnitName("player"))
end

-- The player's choices, kept with the rest of Fireside Tales' saved settings.
local function settings()
	local db = ns.GetDB()
	if not db then return { on = true, own = true, races = true } end
	local s = db.voices
	if type(s) ~= "table" then
		s = {}
		db.voices = s
	end
	if s.on == nil then s.on = true end
	if s.own == nil then s.own = true end -- So a teller hears their own story too.
	if s.races == nil then s.races = true end
	return s
end
V.Settings = settings

-------------------------------------------------------------------------------
-- The voices installed
-------------------------------------------------------------------------------

local packsAdded = {} -- By addon name: each pack that added a voice.

-- A pack adds each of its voices: { key, title, addon, folder, ext, order, lengths = { [id] = seconds } }.
-- A race voice also has race (the game's English race name, like "Dwarf") and sex (2 male, 3 female).
-- A voice in several packs (Skyborne is in both faction packs, and every voice is in the community
-- pack) is one voice, with each line's sound in the pack that has it.
function FiresideTales_AddVoice(voice)
	if type(voice) ~= "table" or type(voice.key) ~= "string" or type(voice.addon) ~= "string"
		or type(voice.lengths) ~= "table" then
		return
	end
	packsAdded[voice.addon] = true
	local from = { addon = voice.addon, folder = voice.folder or voice.key, ext = voice.ext or "mp3" }
	local known = voices[voice.key]
	if not known then
		known = {
			key = voice.key, title = voice.title or voice.key, order = tonumber(voice.order) or 99,
			race = voice.race, sex = voice.sex, lengths = {}, from = {},
		}
		voices[voice.key] = known
	end
	for id, length in pairs(voice.lengths) do
		known.lengths[id] = length
		known.from[id] = from
	end
end

-- A pack's own lines, like the community pack's: { say = { [text] = { id } }, emote = { ... } },
-- listened for along with Fireside Tales' own.
local addedLines = { say = {}, emote = {} }
local targetLines
function FiresideTales_AddLines(lines)
	if type(lines) ~= "table" then return end
	for kind, list in pairs(lines) do
		if addedLines[kind] and type(list) == "table" then
			for text, entry in pairs(list) do addedLines[kind][text] = entry end
		end
	end
	targetLines = nil -- Made again with these.
end

local function sorted(filter)
	local list = {}
	for _, voice in pairs(voices) do
		if filter(voice) then list[#list + 1] = voice end
	end
	table.sort(list, function(a, b)
		if a.order ~= b.order then return a.order < b.order end
		return a.key < b.key
	end)
	return list
end

local function narrators() return sorted(function(v) return not v.race end) end
local function raceVoices() return sorted(function(v) return v.race ~= nil end) end
V.Narrators, V.RaceVoices = narrators, raceVoices

-- The narrator that reads: the one picked, or the first installed.
local function narrator()
	local picked = voices[settings().narrator]
	return (picked and not picked.race and picked) or narrators()[1]
end
V.Narrator = narrator

function V.SetNarrator(key)
	if voices[key] and not voices[key].race then settings().narrator = key end
end

-- The voice for a teller's race and sex, if it's installed and race voices are on.
local function tellerVoice(guid)
	if not (guid and settings().races and GetPlayerInfoByGUID) then return nil end
	local _, _, _, race, sex = GetPlayerInfoByGUID(guid)
	race, sex = plain(race), plain(sex)
	if not (race and sex) then return nil end
	for _, voice in pairs(voices) do
		if voice.race == race and voice.sex == sex then return voice end
	end
end

-- Whether a pack's addon is loaded, which is when its voices are here.
function V.HasPack(addon)
	if packsAdded[addon] then return true end
	local isLoaded = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
	return isLoaded ~= nil and isLoaded(addon) == true
end

function V.Any()
	return next(voices) ~= nil
end

-------------------------------------------------------------------------------
-- Finding a line
-------------------------------------------------------------------------------

-- Lines with {target} arrive with the target's name in its place, so they're found by pattern.
local function findLine(kind, text)
	local own = ns.VoiceLines and ns.VoiceLines[kind] or {}
	local added = addedLines[kind] or {}
	local entry = own[text] or added[text]
	if entry then return entry end
	if kind ~= "say" then return nil end
	if not targetLines then
		targetLines = {}
		for _, lines in ipairs({ own, added }) do
			for template, found in pairs(lines) do
				if template:find("{target}", 1, true) then
					local pattern = template:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0"):gsub("{target}", ".+")
					targetLines[#targetLines + 1] = { "^" .. pattern .. "$", found }
				end
			end
		end
	end
	for _, line in ipairs(targetLines) do
		if text:find(line[1]) then return line[2] end
	end
end
V.FindLine = findLine

-------------------------------------------------------------------------------
-- Playing
-------------------------------------------------------------------------------

-- /tales voices debug: says in chat what plays, when it ends, and what stops it.
local function debug(msg)
	if settings().debug then
		print(("|cff9d9d9dFireside Tales voices %.1f:|r %s"):format(GetTime(), msg))
	end
end
V.Debug = debug

local function playNext()
	playing = nil
	local clip = table.remove(queue, 1)
	if not clip then return end
	local willPlay, handle = PlaySoundFile(clip.path, CHANNEL)
	debug(("play %s (%.1fs) on %s: %s, handle %s"):format(clip.path:match("Sounds\\(.*)$") or clip.path,
		clip.length, CHANNEL, tostring(willPlay), tostring(handle)))
	-- A line whose sound isn't there (an older pack) stays silent, and the story reads on.
	if not willPlay then return playNext() end
	local current = { handle = handle, clip = clip }
	playing = current
	-- With debugging on, says when the game itself stops the sound, and how far in.
	if settings().debug and C_Sound and C_Sound.IsPlaying and handle then
		local started = GetTime()
		local function watch()
			if playing ~= current then return end
			local ok, on = pcall(C_Sound.IsPlaying, handle)
			if ok and not on then
				debug(("the game stopped %s after %.1fs of %.1fs"):format(
					clip.path:match("([^\\]+)%.%a+$") or "?", GetTime() - started, clip.length))
				return
			end
			C_Timer.After(0.1, watch)
		end
		C_Timer.After(0.1, watch)
	end
	C_Timer.After(clip.length + GAP_SECONDS, function()
		debug(("ended %s, %d waiting"):format(clip.path:match("([^\\]+)%.%a+$") or "?", #queue))
		if playing == current then playNext() end
	end)
end

local function enqueue(clip)
	queue[#queue + 1] = clip
	while #queue > QUEUE_LIMIT do
		table.remove(queue, 1)
		debug("dropped the oldest waiting line")
	end
	if playing then debug(("queued, %d waiting"):format(#queue)) end
	if not playing then playNext() end
end

function V.Stop()
	debug("stop, from " .. ((debugstack and debugstack(2, 2, 0)) or "?"):gsub("\n", " / "))
	for i = #queue, 1, -1 do queue[i] = nil end
	if playing and playing.handle and StopSound then StopSound(playing.handle, 500) end
	playing = nil
end

function V.IsPlaying()
	return playing ~= nil
end

-- Plays a line's sound, or returns why it didn't. `asked` is a player's own test, which plays
-- even with voices off, and cuts in ahead of whatever is playing.
local function play(kind, text, teller, guid, asked)
	if not PlaySoundFile then return nil, "this client can't play sounds" end
	if not (asked or settings().on) then return nil, "voices are off" end
	local entry = findLine(kind, text)
	if not entry then return nil, "not a voiced line" end
	local id = entry[1]
	-- The teller's own voice if it has the line, or else the narrator.
	local voice = tellerVoice(guid)
	if not (voice and voice.lengths[id]) then voice = narrator() end
	if not voice then return nil, "no voice for this teller is installed" end
	local length = voice.lengths[id]
	if not length then return nil, "this voice doesn't have that line yet" end
	local key = id .. ":" .. teller
	local now = GetTime()
	if not asked and heard[key] and now - heard[key] < REPEAT_SECONDS then return nil, "heard just now" end
	heard[key] = now
	if asked then V.Stop() end
	local clip = {
		path = ("Interface\\AddOns\\%s\\Sounds\\%s\\%s.%s"):format(voice.from[id].addon, voice.from[id].folder, id,
			voice.from[id].ext),
		length = length,
		voice = voice,
	}
	enqueue(clip)
	return clip
end
V.Play = play

-- A line the player's own voice (or else the narrator) has, without a name in it.
function V.PlaySample()
	local guid = plain(UnitGUID and UnitGUID("player"))
	local voice = tellerVoice(guid) or narrator()
	if not voice then return nil, "no voice pack is installed" end
	local candidates = {}
	for line, entry in pairs(ns.VoiceLines and ns.VoiceLines.say or {}) do
		if not line:find("{target}", 1, true) and voice.lengths[entry[1]] then
			candidates[#candidates + 1] = line
		end
	end
	if #candidates == 0 then return nil, "that voice has no lines yet" end
	table.sort(candidates)
	local text = candidates[math.random(#candidates)]
	local clip, why = play("say", text, "sample", guid, true)
	return clip and text, why
end

local function onChat(event, text, sender, ...)
	local kind = KIND_BY_EVENT[event]
	text, sender = plain(text), plain(sender)
	if not (kind and text and sender) then return end
	local guid = plain((select(10, ...)))
	if isPlayer(sender, guid) and not settings().own then return end
	local clip, why = play(kind, tidy(text), shortName(sender), guid)
	if not clip and why ~= "not a voiced line" then debug(("%s's line not played: %s"):format(shortName(sender), why)) end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("CHAT_MSG_SAY")
frame:RegisterEvent("CHAT_MSG_EMOTE")
frame:SetScript("OnEvent", function(_, event, ...)
	if ns.GetDB() then onChat(event, ...) end
end)

-- For /tales voices.
function V.Status()
	local s = settings()
	local n = narrator()
	local races = raceVoices()
	if not V.Any() then
		say("no voice packs are installed. Open the Voices tab of the story menu to get one.")
		return
	end
	say(("voices are %s. Narrator: %s. Race voices: %d%s. Your own stories: %s."):format(
		s.on and "on" or "off", n and n.title or "none installed", #races,
		s.races and "" or " (off)", s.own and "on" or "off"))
end
