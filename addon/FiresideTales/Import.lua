-- The Add Stories window: paste stories an AI wrote, and they're saved with the
-- addon's data, outside its folder, so updating the addon never removes them.
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

local window, editBox, resultLabel

ns.Import = {}

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
			story.unreadable = nil
			stories[#stories + 1] = story
		end
		story = nil
	end

	for rawLine in (text .. "\n"):gmatch("(.-)\n") do
		local line = rawLine:match("^%s*(.-)%s*$")
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
			story.lines[#story.lines + 1] = { kind = "say", text = value }
		elseif story and label == "EMOTE" then
			-- The game puts the character's name first, so it continues a sentence.
			story.lines[#story.lines + 1] = { kind = "emote", text = value:sub(1, 1):lower() .. value:sub(2) }
		elseif story and line ~= "" and not line:find("^```") then
			story.unreadable = story.unreadable or line
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

local function build()
	window = CreateFrame("Frame", "FiresideTalesImportFrame", UIParent, "BackdropTemplate")
	window:SetSize(500, 440)
	window:SetFrameStrata("DIALOG")
	ns.ApplyBackdrop(window)
	ns.MakeDraggable(window, "importPosition")
	ns.PlaceFrame(window, "importPosition", "CENTER", UIParent, "CENTER", 0, 40)
	table.insert(UISpecialFrames, "FiresideTalesImportFrame") -- Escape closes it.

	local title = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("TOPLEFT", 14, -14)
	title:SetText("Add Stories")

	local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -2, -2)

	local help = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	help:SetPoint("TOPLEFT", 14, -34)
	help:SetWidth(472)
	help:SetJustifyH("LEFT")
	help:SetText("Paste what your AI wrote using a prompt from the addon's prompts folder, then press Add. A few stories at a time works best.")

	local box = CreateFrame("Frame", nil, window, "BackdropTemplate")
	box:SetPoint("TOPLEFT", 14, -66)
	box:SetPoint("BOTTOMRIGHT", -14, 104)
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

	editBox = CreateFrame("EditBox", nil, scroll)
	editBox:SetMultiLine(true)
	editBox:SetAutoFocus(false)
	editBox:SetMaxLetters(0)
	editBox:SetFontObject("ChatFontNormal")
	editBox:SetWidth(460)
	editBox:SetHeight(300)
	editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	scroll:SetScrollChild(editBox)
	scroll:SetScript("OnMouseDown", function() editBox:SetFocus() end)

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
end

function ns.Import.Toggle()
	if not window then build() end
	window:SetShown(not window:IsShown())
end

function ns.Import.Count()
	return #ns.GetDB().imported
end
