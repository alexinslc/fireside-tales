-- The story menu: filter the list on the left, then speak a story one line at a time.
local _, ns = ...

local LIST_WIDTH = 230
local READER_WIDTH = 350
local ROW_HEIGHT = 18
local COLOR_THEME = "|cffd4af37"
local COLOR_SPOKEN = "|cff808080"
local COLOR_NEXT = "|cffffd100"
local COLOR_SAY_NEXT = "|cffffffff"
local COLOR_SAY_LATER = "|cffcccccc"
local COLOR_EMOTE_NEXT = "|cffff8040" -- The game's own emote color.
local COLOR_EMOTE_LATER = "|cffc87040"
local COLOR_ADDED = "|cffb9e6c9" -- Stories you added.
local COLOR_META = "|cffb0a080"
local NO_TARGET = "[your target]"

-- A small colored square, so a story's mood shows in the list.
local function moodDot(red, green, blue)
	return ("|TInterface\\Buttons\\WHITE8X8:8:8:0:0:8:8:0:8:0:8:%d:%d:%d|t "):format(red, green, blue)
end

local MOOD_DOTS = {
	funny = moodDot(255, 210, 70),
	heartfelt = moodDot(240, 120, 150),
	dark = moodDot(150, 110, 210),
	action = moodDot(225, 80, 60),
	spooky = moodDot(110, 200, 120),
	wise = moodDot(90, 160, 235),
}

local MOODS = {
	{ key = "funny", label = MOOD_DOTS.funny .. "Funny" },
	{ key = "heartfelt", label = MOOD_DOTS.heartfelt .. "Heartfelt" },
	{ key = "dark", label = MOOD_DOTS.dark .. "Dark" },
	{ key = "action", label = MOOD_DOTS.action .. "Action" },
	{ key = "spooky", label = MOOD_DOTS.spooky .. "Spooky" },
	{ key = "wise", label = MOOD_DOTS.wise .. "Wise" },
}

local window, reader, readerContent, readerTitle, readerMeta, readerRule, readerText, status, speakButton, restartButton
local favoriteButton, tonightButton, deleteButton, clearFiltersButton
local confirmingDelete = false
local list, listContent, countLabel, emptyLabel, searchBox
local rows, headers = {}, {}
local sections
local storyByKey = {}
local searchText = {}
local filters = { source = nil, mood = nil, show = nil, words = {} }
local selectors = {}
local sectionOpen = {} -- Section title to whether you've opened or closed it.
local currentStory
local nextLine = 1
local storyTarget -- The name a {target} story is being told to, once it has begun.

ns.Story = {}

function ns.Story.IsOpen()
	return (window ~= nil and window:IsShown()) or ns.Teller.IsShown()
end

-------------------------------------------------------------------------------
-- Which stories this character gets
-------------------------------------------------------------------------------

-- This character's menu as { { source, header, stories }, ... }: their own
-- stories, then their race's, their class's, those told to a target, and the
-- shared ones by theme. Each story gets a key that history and favorites use.
local function getSections()
	if sections then return sections end
	sections = {}
	-- The header is part of each story's saved key, so a friendlier name for the
	-- list goes in label instead.
	local function add(source, header, stories, label)
		if stories and #stories > 0 then
			sections[#sections + 1] = { source = source, header = header, stories = stories, label = label }
		end
	end

	local name = ns.PlayerName()
	local raceName, raceToken = UnitRace("player")
	local className, classToken = UnitClass("player")
	-- Both Skyborne races share one list, and their exact token isn't known.
	local raceKey = (raceName .. raceToken):find("Skyborne") and "Skyborne" or raceToken

	-- A built-in list plus any stories pasted into the Write My Story window.
	local imported = ns.GetDB().imported
	local function withPasted(builtIn, kind, listKey)
		local merged = {}
		for _, story in ipairs(builtIn or {}) do
			merged[#merged + 1] = story
		end
		for _, story in ipairs(imported) do
			if story.kind == kind and story.listKey == listKey then
				merged[#merged + 1] = story
			end
		end
		return merged
	end

	add("mine", name, withPasted(ns.CharacterStories[name], "character", name), name .. "'s Tales")
	add("race", raceName, withPasted(ns.RaceStories[raceKey], "race", raceKey))
	add("class", className, withPasted(ns.ClassStories[classToken], "class", classToken))
	local targetStories = withPasted(ns.TargetStories, "target")
	add("target", "Target Someone First", targetStories)
	for _, story in ipairs(targetStories) do
		story.needsTarget = true
	end

	local themes = {}
	for _, story in ipairs(withPasted(ns.Stories, "shared")) do
		if not themes[story.theme] then
			themes[story.theme] = {}
			sections[#sections + 1] = { source = "shared", header = story.theme, stories = themes[story.theme] }
		end
		table.insert(themes[story.theme], story)
	end

	local zoneNames = {}
	for zone in pairs(ns.ZoneStories) do
		zoneNames[zone] = true
	end
	for _, story in ipairs(imported) do
		if story.kind == "zone" then
			zoneNames[story.listKey] = true
		end
	end
	local zones = {}
	for zone in pairs(zoneNames) do
		zones[#zones + 1] = zone
	end
	table.sort(zones)
	for _, zone in ipairs(zones) do
		add("places", zone, withPasted(ns.ZoneStories[zone], "zone", zone))
	end

	for _, section in ipairs(sections) do
		for _, story in ipairs(section.stories) do
			story.key = section.source .. "/" .. section.header .. "/" .. story.title
			storyByKey[story.key] = story
		end
	end
	return sections
end

function ns.Story.Count()
	local count = 0
	for _, section in ipairs(getSections()) do
		count = count + #section.stories
	end
	return count
end

-------------------------------------------------------------------------------
-- Reading a story
-------------------------------------------------------------------------------

-- Who a {target} story goes to: whoever it has begun with, or else your target.
local function listenerName()
	if storyTarget then return storyTarget end
	if not UnitExists("target") or UnitIsUnit("target", "player") then return nil end
	local name = ns.Plain((UnitName("target")))
	return name
end

local function fillTarget(text, name)
	return (text:gsub("{target}", function() return name end))
end

local function displayText(line)
	local text = fillTarget(line.text, listenerName() or NO_TARGET)
	if line.kind == "emote" then
		return ns.PlayerName() .. " " .. text
	end
	return text
end

local function isOnTonight(story)
	for _, key in ipairs(ns.CharData().tonight) do
		if key == story.key then return true end
	end
	return false
end

-- The story after this one on Tonight's list, if it's on the list at all.
local function nextOnTonight()
	local tonight = ns.CharData().tonight
	for index, key in ipairs(tonight) do
		if key == currentStory.key then
			for later = index + 1, #tonight do
				if storyByKey[tonight[later]] then return storyByKey[tonight[later]] end
			end
			return nil
		end
	end
	return nil
end

local function toldText(toldAt)
	local days = math.floor((time() - toldAt) / 86400)
	if days < 1 then return "told today" end
	if days == 1 then return "told yesterday" end
	return ("told %d days ago"):format(days)
end

local function refreshRowColors()
	local char = ns.CharData()
	for _, row in ipairs(rows) do
		if row:IsShown() then
			local story = row.story
			-- The chosen story is gold, and ones you've told are gray.
			local color = story == currentStory and COLOR_NEXT or (char.told[story.key] and COLOR_SPOKEN)
				or (story.kind and COLOR_ADDED or COLOR_SAY_NEXT)
			row:SetText((MOOD_DOTS[story.mood] or "") .. color .. story.title .. "|r")
			row.star:SetShown(char.favorites[story.key] and true or false)
			row.noteIcon:SetShown(story.kind ~= nil)
			row.count:SetText(#story.lines)
		end
	end
end

local function refreshReader()
	if not currentStory then
		readerTitle:SetText("")
		readerMeta:SetText("")
		readerRule:Hide()
		readerText:SetText(COLOR_META .. "Choose a story from the list.|r")
		status:SetText("")
		speakButton:SetText("Speak")
		speakButton:Disable()
		restartButton:Disable()
		favoriteButton:Disable()
		tonightButton:Disable()
		deleteButton:Hide()
		return
	end

	local char = ns.CharData()
	local favorite, onTonight = char.favorites[currentStory.key], isOnTonight(currentStory)
	restartButton:Enable()
	favoriteButton:Enable()
	favoriteButton:SetText(favorite and "Favorited" or "Favorite")
	ns.SetFlatButtonOn(favoriteButton, favorite)
	tonightButton:Enable()
	tonightButton:SetText(onTonight and "On Tonight" or "Add to Tonight")
	ns.SetFlatButtonOn(tonightButton, onTonight)
	-- Only pasted stories have a kind, and only they can be deleted here.
	deleteButton:SetShown(currentStory.kind ~= nil)
	deleteButton:SetText(confirmingDelete and "Sure?" or "Delete")

	local total = #currentStory.lines
	readerTitle:SetText(currentStory.title)
	local mood = currentStory.mood or ""
	local meta = (MOOD_DOTS[mood] or "") .. COLOR_META .. mood:gsub("^%l", string.upper) .. "|r"
	if currentStory.kind then
		meta = meta .. COLOR_META .. "  -  |r" .. COLOR_ADDED .. "added by you|r"
	end
	if char.told[currentStory.key] then
		meta = meta .. COLOR_META .. "  -  " .. toldText(char.told[currentStory.key]) .. "|r"
	end
	readerMeta:SetText(meta)
	readerRule:Show()

	local parts = {}
	for index, line in ipairs(currentStory.lines) do
		local isEmote = line.kind == "emote"
		local text
		if index < nextLine then
			text = COLOR_SPOKEN .. displayText(line) .. "|r"
		elseif index == nextLine then
			text = COLOR_NEXT .. "> |r" .. (isEmote and COLOR_EMOTE_NEXT or COLOR_SAY_NEXT) .. displayText(line) .. "|r"
		else
			text = (isEmote and COLOR_EMOTE_LATER or COLOR_SAY_LATER) .. displayText(line) .. "|r"
		end
		parts[#parts + 1] = text
	end
	readerText:SetText(table.concat(parts, "\n\n"))
	readerContent:SetHeight(readerTitle:GetStringHeight() + readerMeta:GetStringHeight() + readerText:GetStringHeight() + 30)

	local statusText, canSpeak, speakLabel, barText
	local following = nextLine > total and nextOnTonight()
	if nextLine > total then
		statusText = "The end."
		canSpeak = following and true or false
		speakLabel = following and "Next story" or "Speak"
		barText = following and ("Next tonight: " .. following.title) or "The end."
	else
		statusText = ("Line %d of %d"):format(nextLine, total)
		canSpeak = true
		speakLabel = "Speak"
		local line = currentStory.lines[nextLine]
		barText = (line.kind == "emote" and COLOR_EMOTE_NEXT or COLOR_SAY_NEXT) .. displayText(line) .. "|r"
		if currentStory.needsTarget and not listenerName() then
			statusText = "Target someone first."
			canSpeak = false
		end
	end
	status:SetText(statusText)
	speakButton:SetText(speakLabel)
	speakButton:SetEnabled(canSpeak)
	ns.Teller.Update({
		title = currentStory.title .. (storyTarget and (", to " .. storyTarget) or ""),
		text = barText,
		status = statusText,
		speakLabel = speakLabel,
		canSpeak = canSpeak,
	})

	-- Keep the next line in view in a long story.
	local range = reader:GetVerticalScrollRange()
	reader:SetVerticalScroll(range * (math.min(nextLine, total) - 1) / math.max(total - 1, 1))
end

local function selectStory(story)
	currentStory = story
	nextLine = 1
	storyTarget = nil
	confirmingDelete = false
	ns.Teller.StopCue()
	refreshRowColors()
	refreshReader()
end

-- Speaks the next line and shrinks the menu to the teller bar. At the end of a
-- story, it loads the next one on Tonight's list without saying anything.
function ns.Story.SpeakNext()
	if not currentStory then return end
	local total = #currentStory.lines
	if nextLine > total then
		local following = nextOnTonight()
		if following then selectStory(following) end
		return
	end

	local name = currentStory.needsTarget and listenerName() or nil
	if currentStory.needsTarget and not name then return end
	local line = currentStory.lines[nextLine]
	local text = name and fillTarget(line.text, name) or line.text
	if not ns.SendLine(text, ns.ChatType[line.kind]) then return end

	storyTarget = name
	nextLine = nextLine + 1
	if nextLine > total then
		ns.CharData().told[currentStory.key] = time()
		refreshRowColors()
	end
	refreshReader()

	if window:IsShown() then
		ns.Teller.Show()
		window:Hide()
	end
	if nextLine > total then
		ns.Teller.StopCue()
	else
		ns.Teller.StartCue(text)
	end
end

-------------------------------------------------------------------------------
-- Filtering the list
-------------------------------------------------------------------------------

local function textOf(story)
	if not searchText[story] then
		local parts = { story.title, story.theme or "", story.mood or "" }
		for _, line in ipairs(story.lines) do
			parts[#parts + 1] = line.text
		end
		searchText[story] = table.concat(parts, " "):lower()
	end
	return searchText[story]
end

-- Stories about the zone you're standing in: those written for it, then any
-- other story of yours that mentions it. Returns a list and a lookup set.
local hereZone, hereList, hereSet
local function getHereStories()
	local zone = ns.CurrentZone()
	if zone == hereZone and hereList then
		return hereZone, hereList, hereSet
	end
	hereZone, hereList, hereSet = zone, {}, {}
	if not zone then
		return hereZone, hereList, hereSet
	end

	local terms = { zone:lower() }
	for _, term in ipairs(ns.ZoneTerms[zone] or {}) do
		terms[#terms + 1] = term
	end
	local function addStory(story)
		if not hereSet[story] then
			hereSet[story] = true
			hereList[#hereList + 1] = story
		end
	end

	for _, section in ipairs(getSections()) do
		if section.source == "places" and section.header == zone then
			for _, story in ipairs(section.stories) do
				addStory(story)
			end
		end
	end
	for _, section in ipairs(getSections()) do
		-- Tales of other places stay put even if they mention this one in passing.
		-- Stories told to a target also keep to their own section.
		if section.source ~= "places" and section.source ~= "target" then
			for _, story in ipairs(section.stories) do
				local text = textOf(story)
				for _, term in ipairs(terms) do
					if text:find(term, 1, true) then
						addStory(story)
						break
					end
				end
			end
		end
	end
	return hereZone, hereList, hereSet
end

local function matchesFilters(story)
	if filters.mood and story.mood ~= filters.mood then
		return false
	end
	local char = ns.CharData()
	if filters.show == "favorites" and not char.favorites[story.key] then
		return false
	end
	if filters.show == "untold" and char.told[story.key] then
		return false
	end
	if filters.show == "added" and not story.kind then
		return false
	end
	local text = textOf(story)
	for _, word in ipairs(filters.words) do
		if not text:find(word, 1, true) then
			return false
		end
	end
	return true
end

local function getRow(index)
	local row = rows[index]
	if not row then
		row = CreateFrame("Button", nil, listContent)
		row:SetSize(LIST_WIDTH, ROW_HEIGHT)
		row:SetNormalFontObject("GameFontHighlightSmall")
		row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
		row:SetText(" ")
		local label = row:GetFontString()
		label:ClearAllPoints()
		label:SetPoint("LEFT", 18, 0)
		label:SetPoint("RIGHT", -38, 0)
		label:SetJustifyH("LEFT")
		label:SetWordWrap(false)
		row.count = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
		row.count:SetPoint("RIGHT", -6, 0)
		-- These have fixed spots, so titles line up whichever ones a story has.
		row.star = row:CreateTexture(nil, "OVERLAY")
		row.star:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")
		row.star:SetSize(12, 12)
		row.star:SetPoint("LEFT", 3, 0)
		row.noteIcon = row:CreateTexture(nil, "OVERLAY")
		row.noteIcon:SetTexture("Interface\\Icons\\INV_Misc_Note_01")
		row.noteIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		row.noteIcon:SetSize(13, 13)
		row.noteIcon:SetPoint("RIGHT", -22, 0)
		row:SetScript("OnClick", function(self)
			ns.PlayUISound("IG_ABILITY_PAGE_TURN")
			selectStory(self.story)
		end)
		rows[index] = row
	end
	return row
end

local function getHeader(index)
	local header = headers[index]
	if not header then
		header = CreateFrame("Button", nil, listContent)
		header:SetSize(LIST_WIDTH, ROW_HEIGHT)
		header:SetNormalFontObject("GameFontNormalSmall")
		header:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
		header:SetText(" ")
		local label = header:GetFontString()
		label:ClearAllPoints()
		label:SetPoint("LEFT", 18, 0)
		label:SetPoint("RIGHT", -26, 0)
		label:SetJustifyH("LEFT")
		label:SetWordWrap(false)
		header.icon = header:CreateTexture(nil, "ARTWORK")
		header.icon:SetSize(13, 13)
		header.icon:SetPoint("LEFT", 2, 0)
		header.count = header:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
		header.count:SetPoint("RIGHT", -6, 0)
		headers[index] = header
	end
	return header
end

local function isFiltering()
	return filters.source or filters.mood or filters.show or #filters.words > 0
end

local function tonightStories()
	local stories = {}
	for _, key in ipairs(ns.CharData().tonight) do
		if storyByKey[key] then
			stories[#stories + 1] = storyByKey[key]
		end
	end
	return stories
end

local function renderList(keepScroll)
	local scroll = list:GetVerticalScroll()
	for _, row in ipairs(rows) do row:Hide() end
	for _, header in ipairs(headers) do header:Hide() end

	local y, rowIndex, headerIndex, shown = 0, 0, 0, 0
	local counted = {} -- A story can be listed twice, but it's still one story.
	-- Sections stay closed until opened, unless a filter is narrowing the list.
	local function showSection(title, stories, skip, openByDefault)
		local matches = {}
		for _, story in ipairs(stories) do
			if not (skip and skip[story]) and matchesFilters(story) then
				matches[#matches + 1] = story
				if not counted[story] then
					counted[story] = true
					shown = shown + 1
				end
			end
		end
		if #matches == 0 then return end

		local open = sectionOpen[title]
		if open == nil then open = openByDefault or false end
		if isFiltering() then open = true end

		if headerIndex > 0 then y = y - 4 end
		headerIndex = headerIndex + 1
		local header = getHeader(headerIndex)
		header:SetPoint("TOPLEFT", 0, y)
		header:SetText(COLOR_THEME .. title .. "|r")
		header.icon:SetTexture(open and "Interface\\Buttons\\UI-MinusButton-Up" or "Interface\\Buttons\\UI-PlusButton-Up")
		header.count:SetText(#matches)
		header.open = open
		header:SetScript("OnClick", function()
			if isFiltering() then return end -- Filters keep every match in view.
			ns.PlayUISound(open and "IG_MAINMENU_OPTION_CHECKBOX_OFF" or "IG_MAINMENU_OPTION_CHECKBOX_ON")
			sectionOpen[title] = not open
			renderList(true)
		end)
		header:Show()
		y = y - ROW_HEIGHT

		if not open then return end
		for _, story in ipairs(matches) do
			rowIndex = rowIndex + 1
			local row = getRow(rowIndex)
			row.story = story
			row:SetPoint("TOPLEFT", 0, y)
			row:Show()
			y = y - ROW_HEIGHT
		end
	end

	-- Tonight's list comes first, then stories about this zone, each moving up
	-- rather than appearing twice. The exception is your character's own section,
	-- which always lists all of them. Choosing a specific source shows that
	-- source's stories in their usual places.
	local skip = {}
	local function moveUp(stories)
		for _, story in ipairs(stories) do
			skip[story] = true
		end
	end
	if filters.show == "tonight" or not filters.source then
		local stories = tonightStories()
		showSection("Tonight", stories, nil, true)
		moveUp(stories)
	end
	if filters.show ~= "tonight" then
		if not filters.source or filters.source == "here" then
			local zone, stories = getHereStories()
			if zone then
				showSection("Here in " .. zone, stories, skip, true)
				moveUp(stories)
			end
		end
		if filters.source ~= "here" then
			for _, section in ipairs(getSections()) do
				if not filters.source or section.source == filters.source then
					local isMine = section.source == "mine"
					showSection(section.label or section.header, section.stories, not isMine and skip or nil, isMine)
				end
			end
		end
	end

	listContent:SetHeight(math.max(-y + 4, 1))
	list:SetVerticalScroll(keepScroll and scroll or 0)
	clearFiltersButton:SetShown(isFiltering() and true or false)
	countLabel:SetText(("%d of %d stories"):format(shown, ns.Story.Count()))
	emptyLabel:SetShown(headerIndex == 0)
	refreshRowColors()
end

local function refreshSelectors()
	for _, selector in ipairs(selectors) do
		selector.Refresh()
	end
end

local function toggleFavorite()
	local favorites = ns.CharData().favorites
	favorites[currentStory.key] = not favorites[currentStory.key] or nil
	ns.PlayUISound(favorites[currentStory.key] and "IG_MAINMENU_OPTION_CHECKBOX_ON" or "IG_MAINMENU_OPTION_CHECKBOX_OFF")
	renderList(true)
	refreshReader()
end

local function toggleTonight()
	local tonight = ns.CharData().tonight
	ns.PlayUISound(isOnTonight(currentStory) and "IG_MAINMENU_OPTION_CHECKBOX_OFF" or "IG_MAINMENU_OPTION_CHECKBOX_ON")
	if isOnTonight(currentStory) then
		for index = #tonight, 1, -1 do
			if tonight[index] == currentStory.key then
				table.remove(tonight, index)
			end
		end
	else
		tonight[#tonight + 1] = currentStory.key
	end
	renderList(true)
	refreshReader()
end

local function clearTonight()
	wipe(ns.CharData().tonight)
	renderList(true)
	refreshReader()
end

-- Rebuilds the menu after stories are pasted in or deleted.
function ns.Story.StoriesChanged()
	sections = nil
	wipe(storyByKey)
	hereZone, hereList, hereSet = nil, nil, nil
	if not window then return end
	currentStory = nil
	nextLine = 1
	storyTarget = nil
	confirmingDelete = false
	filters.source = nil
	ns.Teller.Hide()
	refreshSelectors()
	renderList()
	refreshReader()
end

-- The first click asks, and the second deletes.
local function deleteCurrent()
	if not confirmingDelete then
		confirmingDelete = true
		refreshReader()
		return
	end
	local imported = ns.GetDB().imported
	for index, story in ipairs(imported) do
		if story == currentStory then
			table.remove(imported, index)
			break
		end
	end
	ns.Story.StoriesChanged()
end

local function setSearch(text)
	filters.words = {}
	for word in text:lower():gmatch("%S+") do
		filters.words[#filters.words + 1] = word
	end
	renderList()
end

local function clearFilters()
	ns.PlayUISound("IG_MAINMENU_OPTION")
	searchBox:SetText("")
	searchBox:ClearFocus()
	filters.words = {}
	filters.source = nil
	filters.mood = nil
	filters.show = nil
	refreshSelectors()
	renderList()
end

-------------------------------------------------------------------------------
-- Building the window
-------------------------------------------------------------------------------

local function enableWheelScroll(scroll)
	scroll:EnableMouseWheel(true)
	scroll:SetScript("OnMouseWheel", function(self, delta)
		local target = self:GetVerticalScroll() - delta * 40
		self:SetVerticalScroll(math.max(0, math.min(target, self:GetVerticalScrollRange())))
	end)
end

-- The popup list a filter opens. Clicking elsewhere in the window closes it.
local popup, popupBlocker
local popupRows = {}

local function hidePopup()
	if popup then
		popup:Hide()
		popupBlocker:Hide()
	end
end

local function getPopupRow(index)
	local row = popupRows[index]
	if not row then
		row = CreateFrame("Button", nil, popup)
		row:SetHeight(ROW_HEIGHT)
		row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
		row:SetNormalFontObject("GameFontHighlightSmall")
		row:SetText(" ")
		local label = row:GetFontString()
		label:ClearAllPoints()
		label:SetPoint("LEFT", 6, 0)
		row:SetPoint("TOPLEFT", 6, -6 - (index - 1) * ROW_HEIGHT)
		row:SetPoint("TOPRIGHT", -6, -6 - (index - 1) * ROW_HEIGHT)
		popupRows[index] = row
	end
	return row
end

-- Each item is { key, label }, or { label, action } for a command.
local function showPopup(owner, items, selected, onPick)
	if not popup then
		popupBlocker = CreateFrame("Button", nil, window)
		popupBlocker:SetAllPoints(window)
		popupBlocker:SetFrameStrata("DIALOG")
		popupBlocker:SetScript("OnClick", hidePopup)
		popup = CreateFrame("Frame", nil, window, "BackdropTemplate")
		ns.ApplyBackdrop(popup)
		popup:SetFrameStrata("DIALOG")
		popup:SetFrameLevel(popupBlocker:GetFrameLevel() + 5)
		popup:EnableMouse(true)
	end
	for _, row in ipairs(popupRows) do row:Hide() end
	for index, item in ipairs(items) do
		local row = getPopupRow(index)
		row:SetNormalFontObject(not item.action and item.key == selected and "GameFontNormalSmall" or "GameFontHighlightSmall")
		row:SetText(item.label)
		row:SetScript("OnClick", function()
			ns.PlayUISound("IG_MAINMENU_OPTION")
			hidePopup()
			if item.action then
				item.action()
			else
				onPick(item.key)
			end
		end)
		row:Show()
	end
	popup:SetSize(math.max(owner:GetWidth(), 130), #items * ROW_HEIGHT + 12)
	popup:ClearAllPoints()
	popup:SetPoint("TOPLEFT", owner, "BOTTOMLEFT", 0, -2)
	popupBlocker:Show()
	popup:Show()
end

-- A button that shows one filter's value and opens its list. getItems returns
-- the choices; the one with no key means "all".
local function buildSelector(caption, filterName, getItems, width)
	local button = ns.MakeFlatButton(window, "", width)
	function button.Refresh()
		local selected = filters[filterName]
		for _, item in ipairs(getItems()) do
			if not item.action and item.key == selected then
				button:SetText(caption .. ": " .. item.label)
			end
		end
		ns.SetFlatButtonOn(button, selected ~= nil)
	end
	button:SetScript("OnClick", function()
		ns.PlayUISound("IG_MAINMENU_OPTION")
		showPopup(button, getItems(), filters[filterName], function(key)
			filters[filterName] = key
			button.Refresh()
			renderList()
		end)
	end)
	button.Refresh()
	selectors[#selectors + 1] = button
	return button
end

local function buildFilters()
	-- The game's search box, with its magnifier and clear button, where the client has it.
	-- It keeps its own text handling, so the search hooks in after that.
	local modern = SearchBoxTemplate_OnTextChanged ~= nil
	searchBox = CreateFrame("EditBox", nil, window, modern and "SearchBoxTemplate" or "InputBoxTemplate")
	searchBox:SetAutoFocus(false)
	searchBox:SetSize(150, 20)
	searchBox:SetPoint("TOPLEFT", 66, -32) -- Clear of the round portrait.
	if modern and type(searchBox.Instructions) == "table" then
		searchBox.Instructions:SetText("Search stories")
		searchBox:HookScript("OnTextChanged", function(self) setSearch(self:GetText()) end)
	else
		local hint = searchBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
		hint:SetPoint("LEFT", 2, 0)
		hint:SetText("Search stories")
		searchBox:SetScript("OnTextChanged", function(self)
			hint:SetShown(self:GetText() == "")
			setSearch(self:GetText())
		end)
	end
	searchBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	searchBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

	-- Only offer sources this character actually has stories in.
	local function getSources()
		local sources = { { key = nil, label = "All" }, { key = "here", label = "Here" } }
		local grouped = { shared = "Everyone", places = "Places", target = "Target" }
		local seen = {}
		for _, section in ipairs(getSections()) do
			if not seen[section.source] then
				seen[section.source] = true
				sources[#sources + 1] = { key = section.source, label = grouped[section.source] or section.header }
			end
		end
		return sources
	end
	local fromButton = buildSelector("From", "source", getSources, 118)
	fromButton:SetPoint("LEFT", searchBox, "RIGHT", 6, 0)

	local moods = { { key = nil, label = "All" } }
	for _, mood in ipairs(MOODS) do
		moods[#moods + 1] = mood
	end
	local moodButton = buildSelector("Mood", "mood", function() return moods end, 112)
	moodButton:SetPoint("LEFT", fromButton, "RIGHT", 4, 0)

	local showChoices = {
		{ key = nil, label = "All" },
		{ key = "favorites", label = "Favorites" },
		{ key = "untold", label = "Not told yet" },
		{ key = "added", label = "Added by me" },
		{ key = "tonight", label = "Tonight" },
	}
	local showButton = buildSelector("Show", "show", function()
		if #ns.CharData().tonight == 0 then return showChoices end
		local items = { unpack(showChoices) }
		items[#items + 1] = { label = "Clear Tonight's list", action = clearTonight }
		return items
	end, 118)
	showButton:SetPoint("LEFT", moodButton, "RIGHT", 4, 0)

	clearFiltersButton = ns.MakeFlatButton(window, "Clear", 46)
	clearFiltersButton:SetPoint("LEFT", showButton, "RIGHT", 4, 0)
	clearFiltersButton:SetScript("OnClick", clearFilters)
end

local INSET_TOP, INSET_BOTTOM = -60, 34
local INSET_LEFT = 8

local function buildList()
	local inset = ns.NewInset(window)
	inset:SetPoint("TOPLEFT", INSET_LEFT, INSET_TOP)
	inset:SetPoint("BOTTOMLEFT", INSET_LEFT, INSET_BOTTOM)
	inset:SetWidth(LIST_WIDTH + 8)

	list = CreateFrame("ScrollFrame", nil, window)
	list:SetPoint("TOPLEFT", inset, "TOPLEFT", 4, -4)
	list:SetPoint("BOTTOMLEFT", inset, "BOTTOMLEFT", 4, 4)
	list:SetWidth(LIST_WIDTH)
	list:SetFrameLevel(inset:GetFrameLevel() + 5) -- Above the panel's own border.
	enableWheelScroll(list)

	listContent = CreateFrame("Frame", nil, list)
	listContent:SetSize(LIST_WIDTH, 1)
	list:SetScrollChild(listContent)

	emptyLabel = list:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	emptyLabel:SetPoint("TOPLEFT", list, "TOPLEFT", 4, -4)
	emptyLabel:SetText("No stories match these filters.")
end

local function makeReaderString(parent, template)
	local text = parent:CreateFontString(nil, "OVERLAY", template)
	text:SetWidth(READER_WIDTH)
	text:SetJustifyH("LEFT")
	text:SetWordWrap(true)
	return text
end

-- A faint glow of firelight rising from the bottom of the page, where the client can
-- draw a gradient. Without one, the page is just the dark panel.
local function addFirelight(inset)
	local glow = inset:CreateTexture(nil, "BORDER")
	glow:SetTexture("Interface\\Buttons\\WHITE8X8")
	glow:SetPoint("BOTTOMLEFT", 3, 3)
	glow:SetPoint("BOTTOMRIGHT", -3, 3)
	glow:SetHeight(230)
	local drawn = CreateColor and pcall(glow.SetGradient, glow, "VERTICAL",
		CreateColor(0.62, 0.27, 0.05, 0.42), CreateColor(0.62, 0.27, 0.05, 0))
	if not drawn then glow:Hide() end
end

local function buildReader()
	local inset = ns.NewInset(window)
	inset:SetPoint("TOPLEFT", INSET_LEFT + LIST_WIDTH + 12, INSET_TOP)
	inset:SetPoint("BOTTOMRIGHT", -8, INSET_BOTTOM)
	addFirelight(inset)

	reader = CreateFrame("ScrollFrame", nil, window)
	reader:SetPoint("TOPLEFT", inset, "TOPLEFT", 12, -12)
	reader:SetPoint("BOTTOMRIGHT", inset, "BOTTOMRIGHT", -10, 26)
	reader:SetFrameLevel(inset:GetFrameLevel() + 5) -- Above the panel's own border.
	enableWheelScroll(reader)

	readerContent = CreateFrame("Frame", nil, reader)
	readerContent:SetSize(READER_WIDTH, 1)
	reader:SetScrollChild(readerContent)

	readerTitle = makeReaderString(readerContent, "GameFontNormalLarge")
	readerTitle:SetPoint("TOPLEFT")

	readerMeta = makeReaderString(readerContent, "GameFontNormalSmall")
	readerMeta:SetPoint("TOPLEFT", readerTitle, "BOTTOMLEFT", 0, -4)

	readerRule = readerContent:CreateTexture(nil, "ARTWORK")
	readerRule:SetColorTexture(0.72, 0.55, 0.32, 0.35)
	readerRule:SetPoint("TOPLEFT", readerMeta, "BOTTOMLEFT", 0, -7)
	readerRule:SetSize(READER_WIDTH, 1)

	readerText = makeReaderString(readerContent, "GameFontHighlight")
	readerText:SetPoint("TOPLEFT", readerRule, "BOTTOMLEFT", 0, -9)

	status = inset:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	status:SetPoint("BOTTOMLEFT", 12, 9)

	-- The buttons sit along the window's foot, as they do in the game's own windows.
	favoriteButton = ns.MakeFlatButton(window, "Favorite", 60)
	favoriteButton:SetPoint("BOTTOMLEFT", inset, "BOTTOMLEFT", 0, -27)
	favoriteButton:SetScript("OnClick", toggleFavorite)

	tonightButton = ns.MakeFlatButton(window, "Add to Tonight", 90)
	tonightButton:SetPoint("LEFT", favoriteButton, "RIGHT", 4, 0)
	tonightButton:SetScript("OnClick", toggleTonight)

	deleteButton = ns.MakeFlatButton(window, "Delete", 44)
	deleteButton:SetPoint("LEFT", tonightButton, "RIGHT", 4, 0)
	deleteButton:SetScript("OnClick", deleteCurrent)
	deleteButton:Hide()

	-- Speak is the one main action, so it's the only raised button here.
	speakButton = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
	speakButton:SetSize(90, 22)
	speakButton:SetPoint("BOTTOMRIGHT", inset, "BOTTOMRIGHT", 0, -27)
	speakButton:SetText("Speak")
	speakButton:SetScript("OnClick", ns.Story.SpeakNext)

	restartButton = ns.MakeFlatButton(window, "Restart", 56)
	restartButton:SetPoint("RIGHT", speakButton, "LEFT", -4, 0)
	restartButton:SetScript("OnClick", function()
		if currentStory then
			ns.PlayUISound("IG_ABILITY_PAGE_TURN")
			selectStory(currentStory)
		end
	end)
end

local function buildWindow()
	window = ns.NewWindow("FiresideTalesStoryFrame", "Fireside Tales", "Interface\\AddOns\\FiresideTales\\Textures\\Icon",
		LIST_WIDTH + READER_WIDTH + 58, 540)
	ns.MakeDraggable(window, "storyPosition")
	ns.PlaceFrame(window, "storyPosition", "CENTER", UIParent, "CENTER", 0, 40)
	table.insert(UISpecialFrames, "FiresideTalesStoryFrame") -- Escape closes it.

	-- A small, quiet version number in the title bar, left of the close button.
	if ns.Version then
		local version = window:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
		version:SetPoint("TOPRIGHT", -30, -6)
		version:SetText("v" .. ns.Version)
	end

	local writeStory = ns.MakeFlatButton(window, "Write My Story", 104)
	writeStory:SetPoint("BOTTOMLEFT", INSET_LEFT, 7)
	writeStory:SetScript("OnClick", ns.Import.Toggle)

	countLabel = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	countLabel:SetPoint("LEFT", writeStory, "RIGHT", 8, 0)

	buildList()
	buildReader()
	buildFilters()
	renderList()
	refreshReader()
	window:Hide()
	ns.AddWindowSounds(window)
	-- Closing the menu partway through a story goes back to the teller bar.
	window:HookScript("OnHide", function()
		hidePopup()
		if currentStory and nextLine > 1 and nextLine <= #currentStory.lines then
			ns.Teller.Show()
		end
	end)
end

function ns.Story.Toggle()
	if not window then buildWindow() end
	if window:IsShown() then
		window:Hide()
	else
		ns.Teller.Hide()
		renderList() -- You may have changed zones since it was last open.
		window:Show()
	end
end

function ns.Story.ZoneChanged()
	if window and window:IsShown() then
		renderList()
	end
end

-- Speak waits for a target on {target} stories, so it reacts when you pick one.
local targetWatcher = CreateFrame("Frame")
targetWatcher:RegisterEvent("PLAYER_TARGET_CHANGED")
targetWatcher:SetScript("OnEvent", function()
	if currentStory and currentStory.needsTarget and not storyTarget and ns.Story.IsOpen() then
		refreshReader()
	end
end)
