-- Headless test for Fireside Tales' Voices.lua: stubs the game, loads it the way the client does,
-- adds voices the way the packs do, and sends it chat lines. It proves the logic, not that the
-- game plays sounds like the stubs, so still try it in the game.
--
--   luajit tools/voice/test-voices.lua [addon folder]
local scriptDir = (arg and arg[0] or ""):match("^(.*)[/\\]") or "."
local ADDONS = (arg and arg[1]) or (scriptDir .. "/../../addon")

local passed, failed = 0, 0
local function check(name, cond, detail)
	if cond then
		passed = passed + 1
	else
		failed = failed + 1
		io.write("FAIL " .. name .. (detail and (": " .. tostring(detail)) or "") .. "\n")
	end
end

-- The game -------------------------------------------------------------------
local now = 1000
function GetTime() return now end
function UnitName() return "Thorgrim" end
function UnitGUID() return "Player-1-00000001" end
-- Race and sex by GUID, as GetPlayerInfoByGUID gives them (2 male, 3 female).
local playerInfo = {
	["Player-1-00000001"] = { "Dwarf", 2 },
	["Player-1-00000077"] = { "Dwarf", 2 },
	["Player-1-00000078"] = { "Dwarf", 3 },
}
function GetPlayerInfoByGUID(guid)
	local info = playerInfo[guid]
	if info then return "Warrior", "WARRIOR", info[1], info[1], info[2] end
end
function Ambiguate(name) return (name:gsub("%-.*$", "")) end
local secrets = {}
function issecretvalue(v) return secrets[v] == true end
local printed = {}
function print(msg) printed[#printed + 1] = msg end

-- Sounds: what was played, and which files exist.
local played, stopped = {}, {}
local missing = {}
local nextHandle = 0
function PlaySoundFile(path, channel)
	if missing[path] then return false end
	nextHandle = nextHandle + 1
	played[#played + 1] = { path = path, channel = channel, handle = nextHandle }
	return true, nextHandle
end
function StopSound(handle) stopped[#stopped + 1] = handle end
local timers = {}
C_Timer = { After = function(seconds, fn) timers[#timers + 1] = { at = now + seconds, fn = fn } end }
local function advance(seconds)
	now = now + seconds
	local due = {}
	for i = #timers, 1, -1 do
		if timers[i].at <= now then due[#due + 1] = table.remove(timers, i) end
	end
	for _, t in ipairs(due) do t.fn() end
end
-- Runs the clock until nothing is waiting.
local function drain() for _ = 1, 50 do advance(10) end end

local frames = {}
function CreateFrame()
	local f = { events = {} }
	function f:RegisterEvent(e) self.events[e] = true end
	function f:SetScript(_, fn) self.handler = fn end
	frames[#frames + 1] = f
	return f
end
local function fire(event, ...)
	for _, f in ipairs(frames) do
		if f.events[event] and f.handler then f.handler(f, event, ...) end
	end
end
-- CHAT_MSG_SAY's arguments, with the GUID 12th.
local function chat(event, text, sender, guid)
	fire(event, text, sender, "Common", "", "", "", 0, 0, "", 7, 1, guid or "Player-1-00000099")
end

-- Load Voices.lua ------------------------------------------------------------
local db = {}
local ns = { GetDB = function() return db end }
-- The test's own lines, so it doesn't depend on which takes exist. The real VoiceLines.lua is
-- loaded separately below, only to check that it parses.
ns.VoiceLines = {
	say = {
		["So I try to keep a light on."] = { "aaaaaaaaaaaa" },
		["Who was he lighting it for?"] = { "bbbbbbbbbbbb" },
		["Forgive me, {target}. You look 50% like a (100%) mule-seller?"] = { "dddddddddddd", "Forgive me, friend. You look 50% like a (100%) mule-seller?" },
		["A line only one narrator has."] = { "eeeeeeeeeeee" },
	},
	emote = {
		["pokes at the fire."] = { "cccccccccccc", "The teller pokes at the fire." },
	},
}
local chunk = assert(loadfile(ADDONS .. "/FiresideTales/Voices.lua"))
chunk("FiresideTales", ns)
local V = ns.Voices

local function last() return played[#played] end
local function count() return #played end

check("no voices to start", not V.Any() and V.Narrator() == nil)
check("settings start on", V.Settings().on and V.Settings().own and V.Settings().races)
check("settings are saved with Fireside Tales'", db.voices and db.voices.on == true)
chat("CHAT_MSG_SAY", "So I try to keep a light on.", "Brannoc")
check("with no voices, nothing plays", count() == 0)

-- The packs load after Fireside Tales, since they depend on it.
FiresideTales_AddVoice({ key = "narrator-male", title = "Male narrator", addon = "FiresideTalesVoices_Narrator",
	folder = "narrator-male", order = 1,
	lengths = { aaaaaaaaaaaa = 3.5, bbbbbbbbbbbb = 2.25, cccccccccccc = 1.5, dddddddddddd = 4.0 } })
check("a narrator is used once added", V.Narrator() and V.Narrator().key == "narrator-male")
check("its pack counts as installed", V.HasPack("FiresideTalesVoices_Narrator"))
check("a pack that isn't here doesn't", not V.HasPack("FiresideTalesVoices_Orc"))

chat("CHAT_MSG_SAY", "So I try to keep a light on.", "Brannoc-Forever")
check("a known say line plays", count() == 1)
check("path names the pack, voice and file", last() and last().path == "Interface\\AddOns\\FiresideTalesVoices_Narrator\\Sounds\\narrator-male\\aaaaaaaaaaaa.mp3", last() and last().path)
check("it plays on the Master channel", last() and last().channel == "Master")

chat("CHAT_MSG_SAY", "So I try to keep a light on.", "Brannoc-Forever")
check("the same teller's line isn't repeated at once", count() == 1)
drain()
now = now + 31
chat("CHAT_MSG_SAY", "So I try to keep a light on.", "Brannoc-Forever")
check("it plays again after the repeat window", count() == 2)

-- Lines wait their turn.
chat("CHAT_MSG_SAY", "So I try to keep a light on.", "Elsa")
check("another teller's line waits while one plays", count() == 2)
advance(3.5)
check("not before the first ends and the gap passes", count() == 2)
advance(0.5)
check("then it plays", count() == 3)
drain()

do
	local before = count()
	chat("CHAT_MSG_SAY", "So I try to keep a light on.", "A1")
	chat("CHAT_MSG_SAY", "So I try to keep a light on.", "A2")
	chat("CHAT_MSG_SAY", "So I try to keep a light on.", "A3")
	chat("CHAT_MSG_SAY", "So I try to keep a light on.", "A4")
	drain()
	check("past two waiting lines, the oldest is dropped", count() == before + 3, count() - before)
end

chat("CHAT_MSG_SAY", "  Who was   he lighting it for? ", "Brannoc")
check("extra spaces still match", count() > 0 and last().path:find("bbbbbbbbbbbb", 1, true))
drain()

do
	local before = count()
	chat("CHAT_MSG_SAY", "Hello there, anyone selling bread?", "Brannoc")
	check("ordinary chat is ignored", count() == before)
	chat("CHAT_MSG_SAY", "pokes at the fire.", "Brannoc")
	check("an emote's text in /say doesn't match", count() == before)
	chat("CHAT_MSG_EMOTE", "pokes at the fire.", "Brannoc")
	check("a known emote plays", count() == before + 1)
	drain()
end

do
	local secret = "Who was he lighting it for?"
	secrets[secret] = true
	now = now + 31
	local before = count()
	local ok = pcall(chat, "CHAT_MSG_SAY", secret, "Brannoc")
	check("a secret line doesn't error", ok)
	check("a secret line isn't played", count() == before)
	secrets[secret] = nil
end

-- A sound that isn't there is skipped, and the next line still plays.
do
	local path = "Interface\\AddOns\\FiresideTalesVoices_Narrator\\Sounds\\narrator-male\\bbbbbbbbbbbb.mp3"
	missing[path] = true
	now = now + 31
	local before = count()
	chat("CHAT_MSG_SAY", "Who was he lighting it for?", "Missing1")
	chat("CHAT_MSG_SAY", "So I try to keep a light on.", "Missing2")
	check("a missing sound doesn't stop the next", count() == before + 1 and last().path:find("aaaaaaaaaaaa", 1, true))
	missing[path] = nil
	drain()
end

-- Your own lines.
do
	now = now + 31
	local before = count()
	chat("CHAT_MSG_SAY", "Who was he lighting it for?", "Thorgrim", "Player-1-00000001")
	check("your own line plays while own is on", count() == before + 1)
	drain()
	V.Settings().own = false
	now = now + 31
	chat("CHAT_MSG_SAY", "Who was he lighting it for?", "Thorgrim", "Player-1-00000001")
	check("your own line is skipped while own is off", count() == before + 1)
	V.Settings().own = true
end

-- Off means quiet, except a sample the player asks for.
do
	V.Settings().on = false
	now = now + 31
	local before = count()
	chat("CHAT_MSG_SAY", "So I try to keep a light on.", "Quiet")
	check("with voices off, nothing plays", count() == before)
	local text = V.PlaySample()
	check("a sample still plays", text and count() == before + 1, text)
	V.Settings().on = true
	drain()
end

-- Stop.
do
	now = now + 31
	chat("CHAT_MSG_SAY", "So I try to keep a light on.", "S1")
	chat("CHAT_MSG_SAY", "Who was he lighting it for?", "S2")
	local before = count()
	V.Stop()
	check("stop stops the sound playing", stopped[#stopped] == last().handle)
	drain()
	check("and drops the lines waiting", count() == before)
	check("nothing is playing after", not V.IsPlaying())
end

-- A {target} line arrives with a name in it.
do
	now = now + 31
	local before = count()
	chat("CHAT_MSG_SAY", "Forgive me, Thrall. You look 50% like a (100%) mule-seller?", "T1", "Player-1-00000002")
	check("a target line with a name plays", count() == before + 1 and last().path:find("dddddddddddd", 1, true))
	drain()
	chat("CHAT_MSG_SAY", "Forgive me, Old Man Tobb's Ghost. You look 50% like a (100%) mule-seller?", "T2", "Player-1-00000003")
	check("a name with spaces and an apostrophe matches", count() == before + 2)
	drain()
	chat("CHAT_MSG_SAY", "Forgive me, . You look 50% like a (100%) mule-seller?", "T3")
	check("an empty name doesn't match", count() == before + 2)
	chat("CHAT_MSG_SAY", "Forgive me, Thrall. You look 50% like a (100%) mule-seller? Ha.", "T4")
	check("extra words after a target line don't match", count() == before + 2)
	chat("CHAT_MSG_SAY", "Forgive me, Thrall. You look 50X like a (100%) mule-seller?", "T5")
	check("pattern characters in a line are taken literally", count() == before + 2)
end

-- Picking a narrator.
do
	now = now + 31
	local before = count()
	chat("CHAT_MSG_SAY", "A line only one narrator has.", "N1")
	check("a line the narrator lacks stays silent", count() == before)
	FiresideTales_AddVoice({ key = "narrator-female", title = "Female narrator", addon = "FiresideTalesVoices_Narrator",
		folder = "narrator-female", order = 2, lengths = { aaaaaaaaaaaa = 3.0, eeeeeeeeeeee = 2.0 } })
	check("the first in order is used until one is picked", V.Narrator().key == "narrator-male")
	check("both narrators are listed in order", #V.Narrators() == 2 and V.Narrators()[2].title == "Female narrator")
	V.SetNarrator("narrator-goblin")
	check("an unknown narrator can't be picked", V.Narrator().key == "narrator-male")
	V.SetNarrator("narrator-female")
	check("she can be picked", V.Narrator().key == "narrator-female" and db.voices.narrator == "narrator-female")
	chat("CHAT_MSG_SAY", "So I try to keep a light on.", "N2")
	check("her sound plays", last().path:find("Sounds\\narrator-female\\aaaaaaaaaaaa.mp3", 1, true), last().path)
	drain()
	V.SetNarrator("narrator-male")
end

-- A teller is read in their race's voice where one is installed.
do
	for _, addon in ipairs({ "FiresideTalesVoices_Skyborne", "FiresideTalesVoices_Community" }) do
		-- A voice can be in two packs (every voice is in the community pack too).
		FiresideTales_AddVoice({ key = "skyborne-male", title = "Skyborne man", addon = addon, folder = "skyborne-male",
			order = 17, race = "Skyborne", sex = 2, lengths = { aaaaaaaaaaaa = 2.0 } })
	end
	FiresideTales_AddVoice({ key = "dwarf-male", title = "Dwarf man", addon = "FiresideTalesVoices_Dwarf",
		folder = "dwarf-male", ext = "ogg", order = 10, race = "Dwarf", sex = 2, lengths = { aaaaaaaaaaaa = 5.0 } })
	check("a voice in two packs is kept once", #V.RaceVoices() == 2)
	check("a race voice isn't listed as a narrator", #V.Narrators() == 2)
	now = now + 31
	chat("CHAT_MSG_SAY", "So I try to keep a light on.", "Durin", "Player-1-00000077")
	check("a dwarf man's line is in the dwarf voice", last().path == "Interface\\AddOns\\FiresideTalesVoices_Dwarf\\Sounds\\dwarf-male\\aaaaaaaaaaaa.ogg", last().path)
	drain()
	chat("CHAT_MSG_SAY", "So I try to keep a light on.", "Hilda", "Player-1-00000078")
	check("a dwarf woman's line is the narrator's", last().path:find("narrator-male", 1, true), last().path)
	drain()
	chat("CHAT_MSG_SAY", "Who was he lighting it for?", "Durin", "Player-1-00000077")
	check("a line the race voice lacks is the narrator's", last().path:find("narrator-male\\bbbbbbbbbbbb", 1, true), last().path)
	drain()
	now = now + 31
	chat("CHAT_MSG_SAY", "So I try to keep a light on.", "Thorgrim", "Player-1-00000001")
	check("your own line is in your race's voice", last().path:find("dwarf-male", 1, true), last().path)
	drain()
	V.Settings().races = false
	now = now + 31
	chat("CHAT_MSG_SAY", "So I try to keep a light on.", "Durin", "Player-1-00000077")
	check("with race voices off, the narrator reads", last().path:find("narrator-male", 1, true), last().path)
	drain()
	V.Settings().races = true
	local text = V.PlaySample()
	check("a sample is in your own race's voice", text and last().path:find("dwarf-male", 1, true), last().path)
	drain()
end

-- The community pack adds its own lines, and its sounds to the voices already here.
do
	check("a community line isn't known before its pack loads", V.FindLine("say", "A tale from the site.") == nil)
	FiresideTales_AddLines({
		say = { ["A tale from the site."] = { "c0c0c0c0c0c0" }, ["Hello there, {target}."] = { "c1c1c1c1c1c1" } },
		emote = {},
	})
	check("its lines are found", V.FindLine("say", "A tale from the site.") and V.FindLine("say", "A tale from the site.")[1] == "c0c0c0c0c0c0")
	check("its {target} lines are found by pattern", V.FindLine("say", "Hello there, Brannoc.") and V.FindLine("say", "Hello there, Brannoc.")[1] == "c1c1c1c1c1c1")
	check("the built-in lines are still found", V.FindLine("say", "So I try to keep a light on.") ~= nil)
	FiresideTales_AddVoice({ key = "dwarf-male", title = "Dwarf man", addon = "FiresideTalesVoices_Community",
		folder = "dwarf-male", ext = "ogg", order = 10, race = "Dwarf", sex = 2, lengths = { c0c0c0c0c0c0 = 4.0 } })
	check("the community pack counts as installed", V.HasPack("FiresideTalesVoices_Community"))
	check("its voice joins the one already here", #V.RaceVoices() == 2 and V.RaceVoices()[1].lengths.aaaaaaaaaaaa == 5.0)
	now = now + 31
	chat("CHAT_MSG_SAY", "A tale from the site.", "Durin", "Player-1-00000077")
	check("a community line plays from the community pack", last().path == "Interface\\AddOns\\FiresideTalesVoices_Community\\Sounds\\dwarf-male\\c0c0c0c0c0c0.ogg", last().path)
	drain()
	chat("CHAT_MSG_SAY", "So I try to keep a light on.", "Durin", "Player-1-00000077")
	check("a built-in line still plays from its own pack", last().path:find("FiresideTalesVoices_Dwarf\\Sounds\\dwarf-male\\aaaaaaaaaaaa.ogg", 1, true), last().path)
	drain()
	FiresideTales_AddVoice({ key = "orc-female", title = "Orc woman", addon = "FiresideTalesVoices_Community",
		folder = "orc-female", ext = "ogg", order = 13, race = "Orc", sex = 3, lengths = { c0c0c0c0c0c0 = 4.0 } })
	playerInfo["Player-1-00000090"] = { "Orc", 3 }
	chat("CHAT_MSG_SAY", "So I try to keep a light on.", "Garra", "Player-1-00000090")
	check("a voice only the community pack has reads the rest by the narrator", last().path:find("narrator-male", 1, true), last().path)
	drain()
	chat("CHAT_MSG_SAY", "A tale from the site.", "Garra", "Player-1-00000090")
	check("and its own community lines in that voice", last().path:find("Community\\Sounds\\orc-female\\c0c0c0c0c0c0", 1, true), last().path)
	drain()
end

-- Without PlaySoundFile, nothing errors.
do
	local saved = PlaySoundFile
	PlaySoundFile = nil
	now = now + 31
	local fine = pcall(chat, "CHAT_MSG_SAY", "So I try to keep a light on.", "NoSound")
	check("a client that can't play sounds doesn't error", fine)
	PlaySoundFile = saved
end

-- The real generated tables parse and have the right shape.
do
	local real = {}
	local linesChunk, err = loadfile(ADDONS .. "/FiresideTales/VoiceLines.lua")
	check("VoiceLines.lua loads", linesChunk, err)
	local ids = {}
	if linesChunk then
		linesChunk("FiresideTales", real)
		local good = real.VoiceLines and real.VoiceLines.say and true
		for _, list in pairs(real.VoiceLines or {}) do
			for text, entry in pairs(list) do
				if type(text) ~= "string" or type(entry[1]) ~= "string" or not entry[1]:match("^%x+$") then good = false end
				ids[entry[1]] = true
			end
		end
		check("every VoiceLines.lua entry has a file name", good)
	end
	-- Each pack built next to the addon.
	local packNames = { "Human", "Dwarf", "NightElf", "Gnome", "Orc", "Undead", "Tauren", "Troll", "Skyborne", "Narrator", "Community" }
	for _, name in ipairs(packNames) do
		local addon = "FiresideTalesVoices_" .. name
		local packChunk = loadfile(ADDONS .. "/" .. addon .. "/Pack.lua")
		if packChunk then
			local added = {}
			local saved, savedLines = FiresideTales_AddVoice, FiresideTales_AddLines
			FiresideTales_AddVoice = function(v) added[#added + 1] = v end
			-- The community pack's lines count as known lines for its own sounds.
			local ownLines = 0
			FiresideTales_AddLines = function(lines)
				for _, list in pairs(lines) do
					for _, entry in pairs(list) do
						ids[entry[1]] = true
						ownLines = ownLines + 1
					end
				end
			end
			packChunk(addon)
			FiresideTales_AddVoice, FiresideTales_AddLines = saved, savedLines
			if addon == "FiresideTalesVoices_Community" then
				check("the community pack adds its own lines", ownLines > 0, ownLines)
			else
				check(addon .. " adds no lines of its own", ownLines == 0, ownLines)
			end
			check(addon .. " adds its voices", #added > 0, #added)
			local good = true
			for _, v in ipairs(added) do
				if v.addon ~= addon or type(v.key) ~= "string" or v.folder ~= v.key then good = false end
				for id, length in pairs(v.lengths or {}) do
					if not ids[id] or type(length) ~= "number" or length <= 0 then good = false end
				end
			end
			check(addon .. " has a length for each sound, each a line in VoiceLines.lua", good)
		end
	end
end

io.write(("RESULT: %d passed, %d failed\n"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
