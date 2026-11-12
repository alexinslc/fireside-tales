-- A riddle at the fire: once the teller starts asking, the addon reads nearby chat for
-- the answer. It never says anything by itself. When someone gets it, the teller bar
-- says so, and the teller presses Speak to announce them. If nobody does, Speak gives
-- the hint, and then the answer.
local _, ns = ...

ns.Riddle = {}

local LISTEN_SECONDS = 300 -- Answers stop counting after five minutes.
local CHANNELS = {
	CHAT_MSG_SAY = true, CHAT_MSG_YELL = true, CHAT_MSG_EMOTE = true,
	CHAT_MSG_PARTY = true, CHAT_MSG_PARTY_LEADER = true,
	CHAT_MSG_RAID = true, CHAT_MSG_RAID_LEADER = true,
}

-- The riddle being asked: riddle, startedAt, hinted, winner, finished.
local game

-- Lowercase words only, with single spaces and a space at each end, so an answer can
-- be found as whole words: " hearth stone " in " is it a hearth stone ".
local function words(text)
	return " " .. text:lower():gsub("[^%w]+", " "):gsub("^ +", ""):gsub(" +$", "") .. " "
end

-- Whether a message names one of the riddle's answers.
function ns.Riddle.Matches(riddle, text)
	local said = words(text)
	for _, answer in ipairs(riddle.answers) do
		if said:find(words(answer), 1, true) then return true end
	end
	return false
end

-- A name without its realm, as chat shows it: "Mira-Stormrage" is Mira.
local function shortName(name)
	return (name:match("^([^%-]+)")) or name
end

function ns.Riddle.Start(riddle)
	local started = { riddle = riddle, startedAt = GetTime(), hinted = false }
	game = started
	-- When time runs out, the teller bar stops saying it's listening.
	C_Timer.After(LISTEN_SECONDS + 1, function()
		if game == started and ns.Story.RiddleChanged then ns.Story.RiddleChanged() end
	end)
end

function ns.Riddle.Stop()
	game = nil
end

-- The riddle in play, if it's this one.
function ns.Riddle.For(riddle)
	return game and game.riddle == riddle and game or nil
end

local function listening()
	return game and not game.winner and not game.finished and GetTime() - game.startedAt <= LISTEN_SECONDS
end

function ns.Riddle.IsListening()
	return listening() and true or false
end

-- Someone said something nearby. Returns their name if it answered the riddle.
function ns.Riddle.Hear(text, sender)
	text, sender = ns.Plain(text), ns.Plain(sender)
	if not listening() or not text or not sender or sender == "" then return nil end
	local name = shortName(sender)
	if name == ns.PlayerName() then return nil end -- The teller can't win their own riddle.
	if not ns.Riddle.Matches(game.riddle, text) then return nil end
	game.winner = name
	return name
end

-- What Speak says next once the riddle is asked, and what it's for:
-- "winner", "hint", or "reveal". Nothing once the riddle is over.
function ns.Riddle.Next()
	if not game or game.finished then return nil end
	local riddle = game.riddle
	if game.winner then
		return ("%s has it! It's %s."):format(game.winner, riddle.answer), "winner"
	end
	if not game.hinted and riddle.hint then
		return riddle.hint, "hint"
	end
	return ("Nobody? It's %s."):format(riddle.answer), "reveal"
end

-- Called once the line from Next has been said.
function ns.Riddle.Said(what)
	if not game then return end
	if what == "hint" then
		game.hinted = true
	else
		game.finished = true
	end
end

local frame = CreateFrame("Frame")
for event in pairs(CHANNELS) do
	frame:RegisterEvent(event)
end
frame:SetScript("OnEvent", function(_, _, text, sender)
	if game and ns.Riddle.Hear(text, sender) then
		ns.PlayUISound("TELL_MESSAGE")
		if ns.Story.RiddleChanged then ns.Story.RiddleChanged() end
	end
end)
