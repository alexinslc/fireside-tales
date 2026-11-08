-- The small bar shown while telling a story: the next line, a cue to let people
-- read the last one, and what's being said nearby. It stays out of the way of
-- the fire, and only listens to chat while it's showing.
local _, ns = ...

local WIDTH = 470
local LINE_TOP = 28 -- Room above the story line.
local BOTTOM_ROOM = 48 -- Room below it for the cue and buttons.
local FEED_LINES = 3
local FEED_LINE_HEIGHT = 13
local FEED_ROOM = 10 -- The divider and the gaps around it.
local FEED_SECONDS = 45
local FEED_MAX_CHARS = 85
local CUE_MIN_SECONDS = 4
local CUE_MAX_SECONDS = 14
local READ_CHARS_PER_SECOND = 20
local COLOR_THEME = "|cffd4af37"
local COLOR_FEED = "|cffa0a0a0"
local COLOR_ALERT = "|cffffd100"

local bar, titleLabel, progressLabel, lineLabel, divider, cueBar, cueLabel, speakButton, anotherButton, framingButton
local feedLabels = {}
local feed = {}
local view
local cueStart, cueLength

ns.Teller = {}

-- How long to give people to read a line, which also says how long a story takes.
function ns.Teller.ReadSeconds(text)
	return math.max(CUE_MIN_SECONDS, math.min(CUE_MAX_SECONDS, 3 + #text / READ_CHARS_PER_SECOND))
end

-------------------------------------------------------------------------------
-- Showing the story
-------------------------------------------------------------------------------

-- The bar is only as tall as what it's showing right now.
local function fitHeight()
	local height = LINE_TOP + lineLabel:GetStringHeight() + BOTTOM_ROOM
	if #feed > 0 then
		height = height + FEED_ROOM + #feed * FEED_LINE_HEIGHT
	end
	divider:SetShown(#feed > 0)
	bar:SetHeight(height)
end

local function applyView()
	if not bar or not view then return end
	titleLabel:SetText(COLOR_THEME .. view.title .. "|r")
	progressLabel:SetText(view.status)
	lineLabel:SetText(view.text)
	speakButton:SetText(view.speakLabel)
	speakButton:SetEnabled(view.canSpeak)
	anotherButton:SetShown(view.canPick and true or false)
	-- The opener or closer sits just left of the other buttons.
	framingButton:SetShown(view.framingLabel ~= nil)
	if view.framingLabel then
		framingButton:SetText(view.framingLabel)
		framingButton:ClearAllPoints()
		framingButton:SetPoint("RIGHT", view.canPick and anotherButton or speakButton, "LEFT", -4, 0)
	end
	if view.hint then cueLabel:SetText(view.hint) end
	fitHeight()
end

-- view is { title, text, status, speakLabel, canSpeak, canPick, hint, framingLabel }.
-- canPick offers a different story, hint fills the cue's spot before the first line,
-- and framingLabel names the opener or closer button, when there is one.
function ns.Teller.Update(newView)
	view = newView
	applyView()
end

-------------------------------------------------------------------------------
-- The cue to let people read. It's only a suggestion: Speak always works.
-------------------------------------------------------------------------------

local function stopCue()
	if not bar then return end
	bar:SetScript("OnUpdate", nil)
	cueBar:Hide()
	cueLabel:SetText("")
end
ns.Teller.StopCue = stopCue

local function updateCue()
	local remaining = cueLength - (GetTime() - cueStart)
	if remaining <= 0 then
		stopCue()
		cueLabel:SetText("Go ahead when you're ready.")
	else
		cueBar:SetValue(remaining / cueLength)
	end
end

function ns.Teller.StartCue(text)
	if not bar then return end
	cueStart = GetTime()
	cueLength = ns.Teller.ReadSeconds(text)
	cueBar:SetValue(1)
	cueBar:Show()
	cueLabel:SetText("Let them read...")
	bar:SetScript("OnUpdate", updateCue)
end

-------------------------------------------------------------------------------
-- What's being said nearby
-------------------------------------------------------------------------------

local function renderFeed()
	for index, label in ipairs(feedLabels) do
		label:SetText(feed[index] or "")
	end
	fitHeight()
end

-- Removes links and color codes, then shortens without splitting a character.
local function tidy(text)
	text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h", ""):gsub("|h", "")
	if #text > FEED_MAX_CHARS then
		text = text:sub(1, FEED_MAX_CHARS):gsub("[\128-\255]+$", "") .. "..."
	end
	return text
end

local chatFormats = {
	CHAT_MSG_SAY = function(name, text) return name .. ": " .. text end,
	CHAT_MSG_EMOTE = function(name, text) return name .. " " .. text end,
	CHAT_MSG_TEXT_EMOTE = function(_, text) return text end, -- Already has the name.
}

local function isAboutMe(event, text)
	local lowered = text:lower()
	if lowered:find(ns.PlayerName():lower(), 1, true) then return true end
	-- A plain emote aimed at you says "you" rather than your name.
	return event == "CHAT_MSG_TEXT_EMOTE" and lowered:find("%f[%a]you%f[%A]") ~= nil
end

local listener = CreateFrame("Frame")
listener:SetScript("OnEvent", function(_, event, rawText, rawSender)
	-- The game can hide chat from addons, in which case there's nothing to show.
	local text, sender = ns.Plain(rawText), ns.Plain(rawSender)
	if not text or not sender then return end
	local name = Ambiguate(sender, "short")
	if name == ns.PlayerName() then return end

	local line = tidy(chatFormats[event](name, text))
	if isAboutMe(event, text) then
		line = COLOR_ALERT .. line .. "|r"
		PlaySound(SOUNDKIT.TELL_MESSAGE)
	else
		line = COLOR_FEED .. line .. "|r"
	end
	table.insert(feed, line)
	if #feed > FEED_LINES then
		table.remove(feed, 1)
	end
	renderFeed()

	-- Old chat clears itself, so the bar shrinks again when the fire goes quiet.
	C_Timer.After(FEED_SECONDS, function()
		for index, shown in ipairs(feed) do
			if shown == line then
				table.remove(feed, index)
				renderFeed()
				return
			end
		end
	end)
end)

local function startListening()
	wipe(feed)
	renderFeed()
	for event in pairs(chatFormats) do
		listener:RegisterEvent(event)
	end
end

local function stopListening()
	listener:UnregisterAllEvents()
end

-------------------------------------------------------------------------------
-- Building the bar
-------------------------------------------------------------------------------

local function makeButton(label, x, onClick)
	local button = CreateFrame("Button", nil, bar, "UIPanelButtonTemplate")
	button:SetSize(90, 22)
	button:SetPoint("BOTTOMRIGHT", x, 10)
	button:SetText(label)
	button:SetScript("OnClick", onClick)
	return button
end

-- Anchors the bar by its bottom edge, so its buttons stay put as its height changes.
local function anchorByBottom()
	local x, y = bar:GetCenter(), bar:GetBottom()
	bar:ClearAllPoints()
	bar:SetPoint("BOTTOM", UIParent, "BOTTOMLEFT", x, y)
	ns.GetDB().tellerPosition = { point = "BOTTOM", relativePoint = "BOTTOMLEFT", x = x, y = y }
end

local function build()
	bar = CreateFrame("Frame", "FiresideTalesTellerBar", UIParent, "BackdropTemplate")
	bar:SetSize(WIDTH, 120)
	ns.ApplyBackdrop(bar)
	ns.MakeDraggable(bar, "tellerPosition")
	ns.PlaceFrame(bar, "tellerPosition", "BOTTOM", UIParent, "BOTTOM", 0, 220)
	anchorByBottom()
	bar:HookScript("OnDragStop", anchorByBottom)
	bar:Hide()
	bar:SetScript("OnShow", startListening)
	bar:SetScript("OnHide", function()
		stopListening()
		stopCue()
		ns.Story.TellerClosed()
	end)

	titleLabel = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	titleLabel:SetPoint("TOPLEFT", 12, -10)
	titleLabel:SetWidth(WIDTH - 130)
	titleLabel:SetJustifyH("LEFT")
	titleLabel:SetWordWrap(false)

	progressLabel = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	progressLabel:SetPoint("TOPRIGHT", -32, -11)

	local close = CreateFrame("Button", nil, bar, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -2, -2)

	lineLabel = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	lineLabel:SetPoint("TOPLEFT", 12, -LINE_TOP)
	lineLabel:SetWidth(WIDTH - 24)
	lineLabel:SetJustifyH("LEFT")
	lineLabel:SetWordWrap(true)

	divider = bar:CreateTexture(nil, "ARTWORK")
	divider:SetColorTexture(0.83, 0.69, 0.22, 0.25)
	divider:SetPoint("TOPLEFT", lineLabel, "BOTTOMLEFT", 0, -5)
	divider:SetSize(WIDTH - 24, 1)

	for index = 1, FEED_LINES do
		local label = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		label:SetPoint("TOPLEFT", divider, "BOTTOMLEFT", 0, -4 - (index - 1) * FEED_LINE_HEIGHT)
		label:SetWidth(WIDTH - 24)
		label:SetJustifyH("LEFT")
		label:SetWordWrap(false)
		feedLabels[index] = label
	end

	cueBar = CreateFrame("StatusBar", nil, bar)
	cueBar:SetPoint("BOTTOMLEFT", 12, 36)
	cueBar:SetSize(WIDTH - 24, 3)
	cueBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	cueBar:SetStatusBarColor(0.83, 0.69, 0.22)
	cueBar:SetMinMaxValues(0, 1)
	cueBar:Hide()

	cueLabel = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	cueLabel:SetPoint("BOTTOMLEFT", 12, 16)

	speakButton = makeButton("Speak", -76, ns.Story.SpeakNext)
	anotherButton = ns.MakeFlatButton(bar, "Another", 64)
	anotherButton:SetPoint("RIGHT", speakButton, "LEFT", -4, 0)
	anotherButton:SetScript("OnClick", ns.Story.TellATale)
	anotherButton:Hide()
	framingButton = ns.MakeFlatButton(bar, "Opener", 60)
	framingButton:SetScript("OnClick", ns.Story.SayFraming)
	framingButton:HookScript("OnEnter", ns.Story.ShowFramingTooltip)
	framingButton:HookScript("OnLeave", function() GameTooltip:Hide() end)
	framingButton:Hide()
	local menu = ns.MakeFlatButton(bar, "Menu", 60)
	menu:SetPoint("BOTTOMRIGHT", -12, 10)
	menu:SetScript("OnClick", ns.Story.Toggle)
	applyView()
end

function ns.Teller.Show()
	if not bar then build() end
	bar:Show()
end

function ns.Teller.Hide()
	if bar then bar:Hide() end
end

function ns.Teller.IsShown()
	return bar ~= nil and bar:IsShown()
end
