-- Fireside Tales Voices: when someone nearby tells a Fireside Tales story, each line they say is
-- read aloud through Spoken. It only listens to chat, and it never sends anything.
local ADDON, ns = ...

local SOURCE_KEY = "fireside"
local SOUNDS = "Interface\\AddOns\\" .. ADDON .. "\\Sounds\\"
-- Chat can repeat a line (two chat frames, a reload); the same teller's line plays once in this time.
local REPEAT_SECONDS = 30

local KIND_BY_EVENT = { CHAT_MSG_SAY = "say", CHAT_MSG_EMOTE = "emote" }

local source
local heard = {}

local function say(msg)
	print("|cffd4af37Fireside Tales Voices:|r " .. msg)
end

-- Some APIs can return secret values, which error on string operations.
local function plain(value)
	if value ~= nil and issecretvalue and issecretvalue(value) then
		return nil
	end
	return value
end

-- The text as the pack's table holds it.
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

local function count(list)
	local n = 0
	for _ in pairs(list or {}) do n = n + 1 end
	return n
end

-- Queues the line's sound, or returns why it didn't. `asked` is a player's own test, which
-- plays even where Spoken reads nothing by itself.
local function play(kind, text, teller, asked)
	if not source then return nil, "Spoken isn't ready" end
	local entry = ns.Lines and ns.Lines[kind] and ns.Lines[kind][text]
	if not entry then return nil, "not a voiced line" end
	local id, length, spoken = entry[1], entry[2], entry[3]
	local key = "fireside:" .. id .. ":" .. teller
	local now = GetTime()
	if not asked and heard[key] and now - heard[key] < REPEAT_SECONDS then return nil, "heard just now" end
	heard[key] = now
	return source:Enqueue({
		key = key,
		path = SOUNDS .. ns.Voice .. "\\" .. id .. ".mp3",
		length = length,
		priority = "normal",
		present = {
			header = teller,
			label = "Fireside Tales",
			transcript = spoken or (kind == "emote" and (teller .. " " .. text)) or text,
			portrait = { kind = "none" },
		},
	}, asked)
end
ns.Play = play

local function onChat(event, text, sender, ...)
	local kind = KIND_BY_EVENT[event]
	text, sender = plain(text), plain(sender)
	if not (kind and text and sender) then return end
	local guid = plain((select(10, ...)))
	if isPlayer(sender, guid) and not FiresideTalesVoicesDB.hearOwn then return end
	play(kind, tidy(text), shortName(sender))
end

local function register()
	if not (Spoken and Spoken.IsCompatible and Spoken:IsCompatible(1)) then
		say("this version of Spoken isn't one it knows, so stories won't be read aloud.")
		return
	end
	source = Spoken:RegisterSource(SOURCE_KEY, {
		title = "Fireside Tales",
		addon = ADDON,
		about = "Reads Fireside Tales stories aloud when someone nearby tells one.",
		order = 50,
		-- A teller who speaks faster than the voice shouldn't leave listeners far behind:
		-- past two waiting lines, the oldest is dropped.
		queueLimit = 2,
		interClipGap = 0.4,
		-- A line whose sound isn't installed (an old pack) stays silent and the story reads on.
		testBeforeQueue = true,
		packs = function() return { "Fireside Tales Voices" } end,
		diagnostics = function()
			say(("%d say and %d emote lines in the \"%s\" voice."):format(count(ns.Lines.say), count(ns.Lines.emote), ns.Voice))
		end,
	})
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(_, event, ...)
	if event == "ADDON_LOADED" then
		if ... == ADDON then
			FiresideTalesVoicesDB = FiresideTalesVoicesDB or {}
			-- On by default, so a teller hears their own story too, and can try the pack alone.
			if FiresideTalesVoicesDB.hearOwn == nil then FiresideTalesVoicesDB.hearOwn = true end
		end
	elseif event == "PLAYER_LOGIN" then
		register()
		if source then
			frame:RegisterEvent("CHAT_MSG_SAY")
			frame:RegisterEvent("CHAT_MSG_EMOTE")
		end
	else
		onChat(event, ...)
	end
end)

SLASH_FIRESIDETALESVOICES1 = "/ftvoices"
SlashCmdList.FIRESIDETALESVOICES = function(input)
	local command = (input or ""):lower():match("^%s*(%S*)")
	if command == "own" then
		FiresideTalesVoicesDB.hearOwn = not FiresideTalesVoicesDB.hearOwn
		say(FiresideTalesVoicesDB.hearOwn and "you'll hear your own stories read aloud." or "you won't hear your own stories, only other tellers'.")
	elseif command == "test" then
		local text = next(ns.Lines.say or {})
		if not text then say("this pack has no lines yet.") return end
		local ok, why = play("say", text, plain(UnitName("player")) or "You", true)
		say(ok and ("playing: " .. text) or ("couldn't play a line: " .. tostring(why)))
	else
		say(("%s. %d lines in the \"%s\" voice. Your own stories: %s."):format(
			source and "Reading stories through Spoken" or "Not running: Spoken isn't loaded",
			count(ns.Lines.say) + count(ns.Lines.emote), ns.Voice or "?",
			FiresideTalesVoicesDB.hearOwn and "on" or "off"))
		say("/ftvoices own turns your own stories on or off. /ftvoices test plays a line.")
	end
end
