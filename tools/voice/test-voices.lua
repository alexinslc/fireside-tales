-- Headless test for Fireside Tales Voices: stubs Spoken and the game, loads the pack the way the
-- client does, and sends it chat lines. It proves the pack's logic, not that the game or Spoken
-- behave like the stubs, so still try it in the game.
--
--   luajit tools/voice/test-voices.lua [pack folder]
local scriptDir = (arg and arg[0] or ""):match("^(.*)[/\\]") or "."
local PACK_DIR = (arg and arg[1]) or (scriptDir .. "/../../addon/FiresideTalesVoices")

local passed, failed = 0, 0
local function check(name, cond, detail)
	if cond then
		passed = passed + 1
	else
		failed = failed + 1
		print("FAIL " .. name .. (detail and (": " .. tostring(detail)) or ""))
	end
end

-- The game -------------------------------------------------------------------
local now = 1000
function GetTime() return now end
function UnitName() return "Thorgrim" end
function UnitGUID() return "Player-1-00000001" end
function Ambiguate(name) return (name:gsub("%-.*$", "")) end
local secrets = {}
function issecretvalue(v) return secrets[v] == true end
SlashCmdList = {}
local printed = {}
function print(msg) printed[#printed + 1] = msg end

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

-- Spoken ---------------------------------------------------------------------
local queued, registered = {}, nil
Spoken = {
	IsCompatible = function(_, v) return v == 1 end,
	RegisterSource = function(_, key, info)
		registered = { key = key, info = info }
		return { Enqueue = function(_, clip, asked) queued[#queued + 1] = { clip = clip, asked = asked } return clip end }
	end,
}

-- Load the pack --------------------------------------------------------------
local ns = {}
local function load(file)
	local chunk = assert(loadfile(PACK_DIR .. "/" .. file))
	chunk("FiresideTalesVoices", ns)
end
-- The test's own lines, so it doesn't depend on which takes exist. The real Lines.lua is
-- loaded separately below, only to check that it parses.
ns.Voice = "narrator"
ns.Lines = {
	say = {
		["So I try to keep a light on."] = { "aaaaaaaaaaaa", 3.5 },
		["Who was he lighting it for?"] = { "bbbbbbbbbbbb", 2.25 },
	},
	emote = {
		["pokes at the fire."] = { "cccccccccccc", 1.5, "The teller pokes at the fire." },
	},
}
load("Core.lua")
fire("ADDON_LOADED", "FiresideTalesVoices")
fire("PLAYER_LOGIN")

check("registers a source with Spoken", registered and registered.key == "fireside")
check("source caps the backlog", registered and registered.info.queueLimit == 2)
check("hearOwn starts on", FiresideTalesVoicesDB.hearOwn == true)

local function last() return queued[#queued] and queued[#queued].clip end

chat("CHAT_MSG_SAY", "So I try to keep a light on.", "Brannoc-Forever")
check("a known say line is queued", #queued == 1)
check("path names the voice and file", last() and last().path == "Interface\\AddOns\\FiresideTalesVoices\\Sounds\\narrator\\aaaaaaaaaaaa.mp3", last() and last().path)
check("length comes from the table", last() and last().length == 3.5)
check("header is the teller without realm", last() and last().present.header == "Brannoc", last() and last().present.header)
check("not a player's own test", queued[1] and not queued[1].asked)

chat("CHAT_MSG_SAY", "So I try to keep a light on.", "Brannoc-Forever")
check("the same teller's line isn't repeated at once", #queued == 1)
now = now + 31
chat("CHAT_MSG_SAY", "So I try to keep a light on.", "Brannoc-Forever")
check("it plays again after the repeat window", #queued == 2)
chat("CHAT_MSG_SAY", "So I try to keep a light on.", "Elsa")
check("another teller's same line plays", #queued == 3)

chat("CHAT_MSG_SAY", "  Who was   he lighting it for? ", "Brannoc")
check("extra spaces still match", #queued == 4)

chat("CHAT_MSG_SAY", "Hello there, anyone selling bread?", "Brannoc")
check("ordinary chat is ignored", #queued == 4)

chat("CHAT_MSG_SAY", "pokes at the fire.", "Brannoc")
check("an emote's text in /say doesn't match", #queued == 4)
chat("CHAT_MSG_EMOTE", "pokes at the fire.", "Brannoc")
check("a known emote is queued", #queued == 5)
check("an emote's transcript is what the voice says", last() and last().present.transcript == "The teller pokes at the fire.")

local secret = "Who was he lighting it for?"
secrets[secret] = true
now = now + 31
local ok = pcall(chat, "CHAT_MSG_SAY", secret, "Brannoc")
check("a secret line doesn't error", ok)
check("a secret line isn't played", #queued == 5)
secrets[secret] = nil

chat("CHAT_MSG_SAY", "Who was he lighting it for?", "Thorgrim", "Player-1-00000001")
check("your own line plays while hearOwn is on", #queued == 6)
SlashCmdList.FIRESIDETALESVOICES("own")
check("/ftvoices own turns it off", FiresideTalesVoicesDB.hearOwn == false)
now = now + 31
chat("CHAT_MSG_SAY", "Who was he lighting it for?", "Thorgrim", "Player-1-00000001")
check("your own line is skipped while hearOwn is off", #queued == 6)

SlashCmdList.FIRESIDETALESVOICES("test")
check("/ftvoices test queues a line as asked", #queued == 7 and queued[7].asked == true)
SlashCmdList.FIRESIDETALESVOICES("")
check("/ftvoices prints a status", printed[#printed] and printed[#printed]:find("/ftvoices own", 1, true))

-- Without Spoken, nothing errors and nothing listens.
do
	local saved = Spoken
	Spoken = nil
	frames, queued = {}, {}
	load("Core.lua")
	fire("ADDON_LOADED", "FiresideTalesVoices")
	local fine = pcall(fire, "PLAYER_LOGIN")
	check("loads without a compatible Spoken", fine)
	check("doesn't listen to chat without Spoken", not frames[1].events.CHAT_MSG_SAY)
	Spoken = saved
end

-- The real generated table parses and has the right shape.
do
	local real = {}
	local chunk, err = loadfile(PACK_DIR .. "/Lines.lua")
	check("Lines.lua loads", chunk, err)
	if chunk then
		chunk("FiresideTalesVoices", real)
		check("Lines.lua names a voice", type(real.Voice) == "string")
		local good = true
		for kind, list in pairs(real.Lines or {}) do
			for text, entry in pairs(list) do
				if type(text) ~= "string" or type(entry[1]) ~= "string" or not entry[1]:match("^%x+$") or type(entry[2]) ~= "number" then
					good = false
				end
			end
		end
		check("every Lines.lua entry has a file and a length", good and real.Lines and real.Lines.say)
	end
end

io.write(("RESULT: %d passed, %d failed\n"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
