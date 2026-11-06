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
local STAR = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:12|t "
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

local window, reader, readerContent, readerText, status, speakButton, restartButton
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
	local function add(source, header, stories)
		if stories and #stories > 0 then
			sections[#sections + 1] = { source = source, header = header, stories = stories }
		end
	end

	local name = ns.PlayerName()
	local raceName, raceToken = UnitRace("player")
	local className, classToken = UnitClass("player")
	-- Both Skyborne races share one list, and their exact token isn't known.
	local raceKey = (raceName .. raceToken):find("Skyborne") and "Skyborne" or raceToken

	-- A built-in list plus any stories pasted into the Add Stories window.
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

	add("mine", name, withPasted(ns.CharacterStories[name], "character", name))
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
			local color = story == currentStory and COLOR_NEXT or (char.told[story.key] and COLOR_SPOKEN or COLOR_SAY_NEXT)
			row:SetText((char.favorites[story.key] and STAR or "") .. (MOOD_DOTS[story.mood] or "")
				.. color .. story.title .. "|r")
			row.count:SetText(#story.lines)
		end
	end
end

local function refreshReader()
	if not currentStory then
		readerText:SetText("Choose a story from the list.")
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
	local heading = COLOR_THEME .. currentStory.title .. "|r"
	if char.told[currentStory.key] then
		heading = heading .. " " .. COLOR_SPOKEN .. toldText(char.told[currentStory.key]) .. "|r"
	end
	local parts = { heading }
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
	readerContent:SetHeight(readerText:GetStringHeight() + 8)

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
		label:SetPoint("LEFT", 16, 0)
		label:SetPoint("RIGHT", -26, 0)
		label:SetJustifyH("LEFT")
		label:SetWordWrap(false)
		row.count = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
		row.count:SetPoint("RIGHT", -6, 0)
		row:SetScript("OnClick", function(self) selectStory(self.story) end)
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
		label:SetPoint("LEFT", 2, 0)
		label:SetJustifyH("LEFT")
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
	-- Sections stay closed until opened, unless a filter is narrowing the list.
	local function showSection(title, stories, skip, openByDefault)
		local matches = {}
		for _, story in ipairs(stories) do
			if not (skip and skip[story]) and matchesFilters(story) then
				matches[#matches + 1] = story
			end
		end
		if #matches == 0 then return end
		shown = shown + #matches

		local open = sectionOpen[title]
		if open == nil then open = openByDefault or false end
		if isFiltering() then open = true end

		if headerIndex > 0 then y = y - 4 end
		headerIndex = headerIndex + 1
		local header = getHeader(headerIndex)
		header:SetPoint("TOPLEFT", 0, y)
		header:SetText(COLOR_THEME .. (open and "- " or "+ ") .. title .. "|r " .. COLOR_SPOKEN .. #matches .. "|r")
		header:SetScript("OnClick", function()
			if isFiltering() then return end -- Filters keep every match in view.
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
	-- rather than appearing twice. Choosing a specific source shows that source's
	-- stories in their usual places.
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
					showSection(section.header, section.stories, skip, section.source == "mine")
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
	renderList(true)
	refreshReader()
end

local function toggleTonight()
	local tonight = ns.CharData().tonight
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
	searchBox = CreateFrame("EditBox", nil, window, "InputBoxTemplate")
	searchBox:SetAutoFocus(false)
	searchBox:SetSize(170, 20)
	searchBox:SetPoint("TOPLEFT", 20, -35)
	local hint = searchBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	hint:SetPoint("LEFT", 2, 0)
	hint:SetText("Search stories")
	searchBox:SetScript("OnTextChanged", function(self)
		hint:SetShown(self:GetText() == "")
		setSearch(self:GetText())
	end)
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
	fromButton:SetPoint("TOPLEFT", searchBox, "TOPRIGHT", 10, 1)

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

	local divider = window:CreateTexture(nil, "ARTWORK")
	divider:SetColorTexture(1, 1, 1, 0.12)
	divider:SetPoint("TOPLEFT", 14, -60)
	divider:SetPoint("TOPRIGHT", -14, -60)
	divider:SetHeight(1)
end

local function buildList()
	list = CreateFrame("ScrollFrame", nil, window)
	list:SetPoint("TOPLEFT", 14, -66)
	list:SetPoint("BOTTOMLEFT", 14, 14)
	list:SetWidth(LIST_WIDTH)
	enableWheelScroll(list)

	listContent = CreateFrame("Frame", nil, list)
	listContent:SetSize(LIST_WIDTH, 1)
	list:SetScrollChild(listContent)

	emptyLabel = window:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	emptyLabel:SetPoint("TOPLEFT", list, "TOPLEFT", 4, -4)
	emptyLabel:SetText("No stories match these filters.")
end

local function buildReader()
	reader = CreateFrame("ScrollFrame", nil, window)
	reader:SetPoint("TOPLEFT", LIST_WIDTH + 30, -66)
	reader:SetPoint("BOTTOMRIGHT", -14, 60)

	local divider = window:CreateTexture(nil, "ARTWORK")
	divider:SetColorTexture(1, 1, 1, 0.12)
	divider:SetPoint("TOPLEFT", LIST_WIDTH + 21, -66)
	divider:SetPoint("BOTTOMLEFT", LIST_WIDTH + 21, 14)
	divider:SetWidth(1)
	enableWheelScroll(reader)

	readerContent = CreateFrame("Frame", nil, reader)
	readerContent:SetSize(READER_WIDTH, 1)
	reader:SetScrollChild(readerContent)

	readerText = readerContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	readerText:SetPoint("TOPLEFT")
	readerText:SetWidth(READER_WIDTH)
	readerText:SetJustifyH("LEFT")
	readerText:SetWordWrap(true)

	status = window:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	status:SetPoint("BOTTOMLEFT", LIST_WIDTH + 30, 40)

	favoriteButton = ns.MakeFlatButton(window, "Favorite", 60)
	favoriteButton:SetPoint("BOTTOMLEFT", LIST_WIDTH + 30, 12)
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
	speakButton:SetPoint("BOTTOMRIGHT", -12, 12)
	speakButton:SetText("Speak")
	speakButton:SetScript("OnClick", ns.Story.SpeakNext)

	restartButton = ns.MakeFlatButton(window, "Restart", 56)
	restartButton:SetPoint("RIGHT", speakButton, "LEFT", -4, 0)
	restartButton:SetScript("OnClick", function()
		if currentStory then selectStory(currentStory) end
	end)
end

local function buildWindow()
	window = CreateFrame("Frame", "FiresideTalesStoryFrame", UIParent, "BackdropTemplate")
	window:SetSize(LIST_WIDTH + READER_WIDTH + 58, 520)
	ns.ApplyBackdrop(window)
	ns.MakeDraggable(window, "storyPosition")
	ns.PlaceFrame(window, "storyPosition", "CENTER", UIParent, "CENTER", 0, 40)
	table.insert(UISpecialFrames, "FiresideTalesStoryFrame") -- Escape closes it.

	local title = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("TOPLEFT", 14, -14)
	title:SetText("Stories")

	countLabel = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	countLabel:SetPoint("LEFT", title, "RIGHT", 12, 0)

	local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -2, -2)

	local addStories = ns.MakeFlatButton(window, "Add Stories", 76)
	addStories:SetPoint("TOPRIGHT", -34, -8)
	addStories:SetScript("OnClick", ns.Import.Toggle)

	buildList()
	buildReader()
	buildFilters()
	renderList()
	refreshReader()
	window:Hide()
	-- Closing the menu partway through a story goes back to the teller bar.
	window:SetScript("OnHide", function()
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
		ns.HidePrompt()
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
