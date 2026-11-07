-- The Write My Story window: describe your character, copy a ready-made prompt into
-- any AI, and paste back what it writes. Stories are saved with the addon's data,
-- outside its folder, so updating the addon never removes them.
local _, ns = ...

local MAX_BYTES = 250
local TARGET_ROOM = ("x"):rep(24) -- {target} is measured as a long character name.
local MIN_LINES = 3
local MAX_LINES = 8
local SHOWN_PROBLEMS = 3
local DEFAULT_THEME = "Your Stories"

local MOODS = { funny = true, heartfelt = true, dark = true, action = true, spooky = true, wise = true }
local CLASSES = {
	WARRIOR = true, PALADIN = true, HUNTER = true, ROGUE = true, PRIEST = true,
	SHAMAN = true, MAGE = true, WARLOCK = true, DRUID = true,
}
local RACES = {
	human = "Human", dwarf = "Dwarf", ["night elf"] = "NightElf", gnome = "Gnome",
	orc = "Orc", undead = "Scourge", forsaken = "Scourge", tauren = "Tauren",
	troll = "Troll", skyborne = "Skyborne",
}

local STORIES_PER_PROMPT = 5
local ABOUT_MAX_LETTERS = 500

local window, editBox, resultLabel, aboutBox, promptBox, aboutLabel, copyHint
local currentPrompt = ""

ns.Import = {}

-------------------------------------------------------------------------------
-- The prompt, filled in from the character. It avoids the vertical bar because an
-- edit box would treat it as a code when showing it.
-------------------------------------------------------------------------------

local function buildPrompt()
	local name = ns.PlayerName()
	local about = (ns.CharData().about or ""):gsub("|", ""):gsub("%s+", " ")
	if about == "" then
		about = "Not much yet. Invent something fitting, and keep it simple."
	end
	return table.concat({
		("Write %d short roleplay stories for my World of Warcraft: Forever character. They're for an addon called Fireside Tales. I tell them one line at a time, sitting at a campfire with other players, using /say and /e."):format(STORIES_PER_PROMPT),
		"",
		"First name: " .. name,
		("Race and class: %s %s"):format((UnitRace("player")), (UnitClass("player"))),
		"Where they are now: " .. (ns.CurrentZone() or "on the road"),
		"About them: " .. about,
		"",
		"Output only plain text in a single code block, exactly in this form, and add nothing else:",
		"",
		"```",
		"CHARACTER: " .. name,
		"TITLE: The Ferry at Dusk",
		"MOOD: heartfelt",
		"EMOTE: turns a worn ferry token over in their fingers, watching the fire.",
		"SAY: My father ran a ferry on a brown river. He said every crossing was a promise you made to a stranger.",
		"SAY: The night the bridge fell, he made eleven trips in the dark. He came home soaked and said it had been a slow evening.",
		"EMOTE: sets the token on one knee and leaves it there.",
		"```",
		"",
		"Rules that make it work:",
		"- Write the CHARACTER line once at the top, then start each story with its own TITLE line. Each title must be unique.",
		"- MOOD must be exactly one of: funny, heartfelt, dark, action, spooky, wise.",
		"- A story must take under a minute to tell. Aim for 4 to 6 lines, and never fewer than 3 or more than 8, with at least one SAY and one EMOTE.",
		"- Each line must be under 220 characters and on a single line, because it's sent as one chat message. Don't use the vertical bar or curly braces.",
		"",
		"How to write them:",
		"- Write SAY lines in the first person, as if talking to people at the fire, and keep them easy to say aloud.",
		"- The game puts my name in front of an emote, so start every EMOTE with a lowercase verb.",
		"- Every emote must work while sitting down. Use the hands and upper body, and never stand, walk, kneel, or crouch.",
		"- Don't say what listeners do, feel, or say, since they're other real players.",
		"- Draw on this character's life. Give each story a clear hook, a turn, and an ending worth waiting for, using real specifics rather than vague fantasy phrases.",
		"- Mix the moods, and don't let every story end on the same note.",
		"- Stay true to Warcraft's setting. Name real places when they fit, and write original stories rather than retelling quests or books.",
	}, "\n")
end

local function refreshPrompt()
	currentPrompt = buildPrompt()
	promptBox:SetText(currentPrompt)
	promptBox:SetCursorPosition(0)
	copyHint:SetText("")
end

-------------------------------------------------------------------------------
-- Reading pasted text
-------------------------------------------------------------------------------

-- Each reader returns a section, or nil and what's wrong with it.
local sectionReaders = {
	CHARACTER = function(value)
		if value == "" or value:find("%s") then return nil, "CHARACTER needs one first name." end
		return { kind = "character", listKey = value }
	end,
	RACE = function(value)
		local race = RACES[value:lower()]
		if not race then return nil, "unknown race: " .. value end
		return { kind = "race", listKey = race }
	end,
	CLASS = function(value)
		local class = value:upper()
		if not CLASSES[class] then return nil, "unknown class: " .. value end
		return { kind = "class", listKey = class }
	end,
	ZONE = function(value)
		if value == "" then return nil, "ZONE needs a zone name." end
		return { kind = "zone", listKey = value }
	end,
	EVERYONE = function(value)
		return { kind = "shared", theme = value ~= "" and value or DEFAULT_THEME }
	end,
	TARGET = function()
		return { kind = "target" }
	end,
}

-- Returns what's wrong with a story, or nil if it's fine to use.
local function findProblem(story)
	if story.unreadable then return "can't read: " .. story.unreadable:sub(1, 40) end
	if story.title == "" then return "it has no title" end
	if not MOODS[story.mood or ""] then return "MOOD must be funny, heartfelt, dark, action, spooky, or wise" end
	if #story.lines < MIN_LINES or #story.lines > MAX_LINES then
		return ("it has %d lines (needs %d to %d)"):format(#story.lines, MIN_LINES, MAX_LINES)
	end

	local says, emotes, usesTarget = 0, 0, false
	for _, line in ipairs(story.lines) do
		if line.kind == "say" then says = says + 1 else emotes = emotes + 1 end
		local withoutTarget = line.text:gsub("{target}", "")
		if line.text:find("{target}", 1, true) then usesTarget = true end
		if withoutTarget:find("[|{}]") then return "a line uses |, {, or }" end
		if line.text == "" then return "it has an empty line" end
		if #line.text:gsub("{target}", TARGET_ROOM) > MAX_BYTES then return "a line is too long" end
	end
	if says == 0 or emotes == 0 then return "it needs at least one SAY and one EMOTE" end
	if story.kind == "target" and not usesTarget then return "TARGET stories must use {target}" end
	if story.kind ~= "target" and usesTarget then return "only TARGET stories can use {target}" end
	return nil
end

-- Returns the usable stories and a list of problems.
local function parse(text)
	local stories, problems = {}, {}
	local section, story

	local function finishStory()
		if not story then return end
		local problem = findProblem(story)
		if problem then
			problems[#problems + 1] = ('"%s": %s'):format(story.title, problem)
		else
			story.unreadable, story.stray = nil, nil
			stories[#stories + 1] = story
		end
		story = nil
	end

	-- A stray line only costs a story when more of the story comes after it, which
	-- means text went missing. Trailing chatter from the AI is simply ignored.
	local function addLine(kind, value)
		if story.stray then
			story.unreadable = story.unreadable or story.stray
		end
		story.lines[#story.lines + 1] = { kind = kind, text = value }
	end

	for rawLine in (text .. "\n"):gmatch("(.-)\n") do
		local line = rawLine:match("^%s*(.-)%s*$"):gsub("%*%*", "") -- AIs like bold labels.
		local label, value = line:match("^(%u+):%s*(.*)$")
		if label and sectionReaders[label] then
			finishStory()
			local problem
			section, problem = sectionReaders[label](value)
			if problem then problems[#problems + 1] = problem end
		elseif label == "TITLE" then
			finishStory()
			if section then
				story = { kind = section.kind, listKey = section.listKey, theme = section.theme, title = value, lines = {} }
			else
				problems[#problems + 1] = ('"%s": no valid section above it'):format(value)
			end
		elseif story and label == "MOOD" then
			story.mood = value:lower()
		elseif story and label == "SAY" then
			addLine("say", value)
		elseif story and label == "EMOTE" then
			-- The game puts the character's name first, so it continues a sentence.
			addLine("emote", value:sub(1, 1):lower() .. value:sub(2))
		elseif line:find("^```") then
			finishStory() -- Whatever follows a code block is the AI talking, not the story.
		elseif story and line ~= "" and not line:find("^[-*_=]+$") then
			story.stray = story.stray or line
		end
	end
	finishStory()
	return stories, problems
end

-- Adds stories, replacing any in the same list with the same title.
local function save(stories)
	local saved = ns.GetDB().imported
	local added, replaced = 0, 0
	for _, story in ipairs(stories) do
		local position
		for index, existing in ipairs(saved) do
			if existing.kind == story.kind and existing.listKey == story.listKey and existing.title == story.title then
				position = index
				break
			end
		end
		if position then
			saved[position] = story
			replaced = replaced + 1
		else
			saved[#saved + 1] = story
			added = added + 1
		end
	end
	return added, replaced
end

local function addPasted()
	local stories, problems = parse(editBox:GetText())
	local added, replaced = save(stories)
	if added + replaced > 0 then
		ns.Story.StoriesChanged()
		editBox:SetText("")
	end

	local parts = { ("Added %d, replaced %d, skipped %d."):format(added, replaced, #problems) }
	for index = 1, math.min(SHOWN_PROBLEMS, #problems) do
		parts[#parts + 1] = problems[index]
	end
	if #problems > SHOWN_PROBLEMS then
		parts[#parts + 1] = ("...and %d more."):format(#problems - SHOWN_PROBLEMS)
	end
	resultLabel:SetText(table.concat(parts, "\n"))
end

-------------------------------------------------------------------------------
-- The window
-------------------------------------------------------------------------------

-- A scrolling multi-line box. Give it a fixed height, or bottom to stretch it down
-- to that distance from the window's bottom edge.
local function makeTextBox(top, height, bottom)
	local box = CreateFrame("Frame", nil, window, "BackdropTemplate")
	box:SetPoint("TOPLEFT", 12, top)
	if height then
		box:SetPoint("TOPRIGHT", -12, top)
		box:SetHeight(height)
	else
		box:SetPoint("BOTTOMRIGHT", -12, bottom)
	end
	box:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
	box:SetBackdropColor(0, 0, 0, 0.45)

	local scroll = CreateFrame("ScrollFrame", nil, box)
	scroll:SetPoint("TOPLEFT", 6, -6)
	scroll:SetPoint("BOTTOMRIGHT", -6, 6)
	scroll:EnableMouseWheel(true)
	scroll:SetScript("OnMouseWheel", function(self, delta)
		local target = self:GetVerticalScroll() - delta * 40
		self:SetVerticalScroll(math.max(0, math.min(target, self:GetVerticalScrollRange())))
	end)

	local edit = CreateFrame("EditBox", nil, scroll)
	edit:SetMultiLine(true)
	edit:SetAutoFocus(false)
	edit:SetMaxLetters(0)
	edit:SetFontObject("ChatFontNormal")
	edit:SetWidth(460)
	edit:SetHeight(height and height - 12 or 200)
	edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	scroll:SetScrollChild(edit)
	scroll:SetScript("OnMouseDown", function() edit:SetFocus() end)
	return edit, box
end

local function makeStepLabel(top, text, left)
	local label = window:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	label:SetPoint("TOPLEFT", left or 12, top)
	label:SetJustifyH("LEFT")
	label:SetText(text)
	return label
end

local function build()
	window = ns.NewWindow("FiresideTalesImportFrame", "Write My Story", "Interface\\AddOns\\FiresideTales\\Textures\\Icon", 500, 590)
	window:SetFrameStrata("DIALOG")
	ns.MakeDraggable(window, "importPosition")
	ns.PlaceFrame(window, "importPosition", "CENTER", UIParent, "CENTER", 0, 40)
	table.insert(UISpecialFrames, "FiresideTalesImportFrame") -- Escape closes it.

	-- Step 1: who this character is. Saved as you type, and it fills in the prompt.
	-- The label starts clear of the round portrait.
	aboutLabel = makeStepLabel(-44, "", 66)
	aboutBox = makeTextBox(-64, 50)
	aboutBox:SetMaxLetters(ABOUT_MAX_LETTERS)

	-- Step 2: the prompt. It can be selected and copied, but not edited.
	makeStepLabel(-126, "2. Copy this prompt, then paste it into any AI.")
	copyHint = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	copyHint:SetPoint("TOPLEFT", 12, -230)
	local selectPrompt = ns.MakeFlatButton(window, "Select Prompt", 96)
	selectPrompt:SetPoint("TOPRIGHT", -12, -120)

	promptBox = makeTextBox(-146, 76)
	promptBox:SetScript("OnTextChanged", function(self, userInput)
		if userInput then
			self:SetText(currentPrompt)
			self:HighlightText()
		end
	end)
	promptBox:SetScript("OnEditFocusLost", function(self) self:HighlightText(0, 0) end)
	selectPrompt:SetScript("OnClick", function()
		promptBox:SetFocus()
		promptBox:HighlightText()
		copyHint:SetText("Selected. Press Cmd+C on a Mac or Ctrl+C on Windows to copy it.")
	end)

	-- Set up last, because typing here refreshes the prompt box above.
	aboutBox:SetScript("OnTextChanged", function(self)
		local about = self:GetText()
		ns.CharData().about = about ~= "" and about or nil
		refreshPrompt()
	end)

	-- Step 3: what the AI wrote.
	makeStepLabel(-250, "3. Paste what the AI wrote here, then press Add.")
	local box
	editBox, box = makeTextBox(-266, nil, 104)

	resultLabel = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	resultLabel:SetPoint("TOPLEFT", box, "BOTTOMLEFT", 0, -8)
	resultLabel:SetWidth(472)
	resultLabel:SetJustifyH("LEFT")

	local add = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
	add:SetSize(90, 22)
	add:SetPoint("BOTTOMRIGHT", -12, 12)
	add:SetText("Add")
	add:SetScript("OnClick", addPasted)

	window:Hide()
	ns.AddWindowSounds(window)
end

function ns.Import.Toggle()
	if not window then build() end
	if window:IsShown() then
		window:Hide()
		return
	end
	aboutLabel:SetText(("1. Who is %s? A sentence or two: where they're from, how they talk. Optional."):format(ns.PlayerName()))
	aboutBox:SetText(ns.CharData().about or "")
	refreshPrompt() -- You may have traveled since it was last open.
	window:Show()
end

function ns.Import.Count()
	return #ns.GetDB().imported
end
