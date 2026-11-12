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
local favoriteButton, tonightButton, deleteButton, clearFiltersButton, fromButton, moodButton
local writeButton, contributeButton -- The bottom bar's second button, which changes with the tab.
local tabButtons = {}
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
local offered = {} -- Story keys Tell a Tale has picked this session, so Another moves on.
local offering = false -- The teller bar is offering a story because you sat by a fire.
local offerGeneration = 0
local OFFER_SECONDS = 30 -- An offer nobody takes quietly goes away.
local FIRE_HINT = "By the fire. Tell a tale?"
local NIGHT_HINT = "A dark night by the fire. Tell a tale?"
local buildWindow -- Defined last, once everything it uses exists.
local RUMORS_THEME = "Rumors and Whispers" -- These shared stories get a tab of their own.

-- The tabs down the window's right edge. Stories holds everything except legends,
-- rumors, and community stories, which have their own tabs. Your Tales shows only
-- your character's own.
local currentTab = "stories"
local TAB_SOURCES = {
	mine = { mine = true }, legends = { legend = true }, rumors = { rumors = true }, community = { community = true },
	riddles = { riddle = true },
}
local function inTab(source)
	local only = TAB_SOURCES[currentTab]
	if only then return only[source] or false end
	return source ~= "legend" and source ~= "rumors" and source ~= "community" and source ~= "riddle"
end

-- What the teller bar says when the fire offers a story.
local function fireHint()
	local festival = ns.Season.Active()[1]
	if festival then return festival.offer end
	return ns.Season.IsNight() and NIGHT_HINT or FIRE_HINT
end

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

	-- A built-in list plus any stories pasted into the Write Your Tales window.
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
			local source = story.theme == RUMORS_THEME and "rumors" or "shared"
			sections[#sections + 1] = { source = source, header = story.theme, stories = themes[story.theme] }
		end
		table.insert(themes[story.theme], story)
	end

	for _, festival in ipairs(ns.Season.Festivals) do
		add("festival", festival.name, ns.FestivalStories[festival.name])
	end

	-- Each legend is a section of its parts, in order.
	for _, legend in ipairs(ns.Legends) do
		for index, part in ipairs(legend.parts) do
			part.legend, part.part = legend, index
		end
		add("legend", legend.title, legend.parts)
	end

	add("riddle", "Riddles", ns.Riddles, "Riddles at the Fire")

	-- Community stories, newest week first. Only the latest week is open at first.
	local weeks, current = ns.CommunityWeeksSoFar()
	for index, week in ipairs(weeks) do
		local when = date("!%B %d", time({ year = tonumber(week.week:sub(1, 4)), month = tonumber(week.week:sub(6, 7)),
			day = tonumber(week.week:sub(9, 10)), hour = 12 })):gsub(" 0", " ")
		local before = #sections
		add("community", week.week, week.stories, week.week == current and "This Week at the Fire" or ("Week of " .. when))
		if index == 1 and #sections > before then sections[#sections].latest = true end
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

-- The part after this one, when it's a legend that has more.
local function nextPart(story)
	return story.legend and story.legend.parts[story.part + 1] or nil
end

-- What Speak loads once this story ends: a legend's next part, or Tonight's next story.
local function followingStory()
	return nextPart(currentStory) or nextOnTonight()
end

-------------------------------------------------------------------------------
-- Openers and closers: one line before a story, and one after it
-------------------------------------------------------------------------------

local framingSaid = {} -- Which of the two you've said for this story.
local framingNext = {} -- The line each button will say, so its tooltip can show it.
local framingUsed = {} -- Lines said this session, so they don't come round again soon.

local function framingPool(which)
	local groups = (which == "opener" and ns.Openers or ns.Closers) or {}
	local pool = {}
	local function add(key)
		for _, line in ipairs(groups[key] or {}) do pool[#pool + 1] = line end
	end
	add("any")
	if ns.Season.IsNight() then add("night") end
	if which == "closer" and currentStory then add(currentStory.mood) end
	return pool
end

-- Which button to offer now: an opener before the first line, or a closer once a
-- story ends with nothing after it. Each is said at most once per story.
local function framingNow()
	if not currentStory then return nil end
	if nextLine == 1 and not framingSaid.opener then return "opener" end
	if nextLine > #currentStory.lines and not framingSaid.closer and not followingStory() then return "closer" end
	return nil
end

local function framingLine(which)
	if not framingNext[which] then
		local pool, fresh = framingPool(which), {}
		for _, line in ipairs(pool) do
			if not framingUsed[line] then fresh[#fresh + 1] = line end
		end
		if #fresh == 0 then
			for _, line in ipairs(pool) do framingUsed[line] = nil end
			fresh = pool
		end
		framingNext[which] = fresh[1] and fresh[math.random(#fresh)] or nil
	end
	return framingNext[which]
end

local function framingLabel()
	local which = framingNow()
	if not which or not framingLine(which) then return nil end
	return which == "opener" and "Opener" or "Closer"
end

-- The line the button would say, as people will see it, for its tooltip.
function ns.Story.PeekFraming()
	local which = framingNow()
	local line = which and framingLine(which)
	if not line then return nil end
	return line.kind == "emote" and (ns.PlayerName() .. " " .. line.text) or line.text
end

-- Roughly how long a story takes to tell, giving people time to read each line.
local function storySeconds(story)
	local seconds = 0
	for _, line in ipairs(story.lines) do
		seconds = seconds + ns.Teller.ReadSeconds(fillTarget(line.text, "Somebodyname"))
	end
	return math.max(10, math.floor(seconds / 5 + 0.5) * 5)
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
			row.count:SetText(storySeconds(story) .. "s") -- Roughly how long it takes to tell.
		end
	end
end

local function refreshReader()
	if not currentStory then
		readerTitle:SetText("")
		readerMeta:SetText("")
		readerRule:Hide()
		readerText:SetText(COLOR_META .. (currentTab == "community"
			and "These tales were shared by players. Choose one to tell, or press Contribute a Story to send your own.|r"
			or "Choose a story from the list, or press Tell a Tale and let the fire choose.|r"))
		status:SetText("")
		speakButton:SetText("Tell")
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
	local seconds = storySeconds(currentStory)
	local meta = (MOOD_DOTS[mood] or "") .. COLOR_META .. mood:gsub("^%l", string.upper) .. "|r"
		.. COLOR_META .. ("  -  about %d seconds|r"):format(seconds)
	if currentStory.legend then
		-- A legend told in one sitting just says where it happened.
		local parts = #currentStory.legend.parts
		meta = meta .. COLOR_META .. (parts > 1 and ("  -  %s, part %d of %d|r"):format(currentStory.legend.zone, currentStory.part, parts)
			or ("  -  %s|r"):format(currentStory.legend.zone))
	end
	if currentStory.kind then
		meta = meta .. COLOR_META .. "  -  |r" .. COLOR_ADDED .. "added by you|r"
	end
	if currentStory.week then
		meta = meta .. COLOR_META .. "  -  " .. ns.CommunityCredit(currentStory) .. "|r"
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
	if currentStory.riddle then
		parts[#parts + 1] = COLOR_META .. "Hint: " .. currentStory.hint .. "|r"
		parts[#parts + 1] = COLOR_META .. "Answer (only you can see this): " .. currentStory.answer .. "|r"
	end
	readerText:SetText(table.concat(parts, "\n\n"))
	readerContent:SetHeight(readerTitle:GetStringHeight() + readerMeta:GetStringHeight() + readerText:GetStringHeight() + 30)

	local statusText, canSpeak, speakLabel, barText, barStatus
	local following = nextLine > total and followingStory()
	local riddle = nextLine > total and currentStory.riddle and ns.Riddle.For(currentStory)
	local riddleNext, riddleStep = nil, nil
	if riddle then riddleNext, riddleStep = ns.Riddle.Next() end
	if riddleNext then
		canSpeak = true
		if riddleStep == "winner" then
			statusText = riddle.winner .. " has it!"
			barText = COLOR_NEXT .. riddle.winner .. " has it!|r Speak to say so."
			speakLabel = "Announce"
		else
			statusText = ns.Riddle.IsListening() and "Listening for the answer..." or "No answer yet."
			barText = statusText
			speakLabel = riddleStep == "hint" and "Hint" or "Reveal"
		end
	elseif nextLine > total then
		local isPart = following and following == nextPart(currentStory)
		statusText = isPart and "End of this part." or "The end."
		canSpeak = following and true or false
		speakLabel = following and (isPart and "Next part" or "Next story") or "Speak"
		barText = following and ((isPart and "Next part: " or "Next tonight: ") .. following.title) or "The end."
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
	-- Before the first line, the bar says how long the story is instead.
	if nextLine == 1 and canSpeak then
		barStatus = ("about %d sec"):format(seconds)
	end
	status:SetText(statusText)
	-- Before the first line, the menu's button hands the story to the teller bar
	-- without saying anything, so there's time for an opener.
	speakButton:SetText(nextLine == 1 and "Tell" or speakLabel)
	speakButton:SetEnabled(canSpeak)
	local framing = framingLabel()
	ns.Teller.Update({
		framingLabel = framing,
		title = currentStory.title .. (storyTarget and (", to " .. storyTarget) or ""),
		text = barText,
		status = barStatus or statusText,
		speakLabel = speakLabel,
		canSpeak = canSpeak,
		canPick = nextLine == 1,
		hint = nextLine == 1 and offering and fireHint() or nil,
	})

	-- Keep the next line in view in a long story.
	local range = reader:GetVerticalScrollRange()
	reader:SetVerticalScroll(range * (math.min(nextLine, total) - 1) / math.max(total - 1, 1))
end

local function selectStory(story)
	if not (story and ns.Riddle.For(story)) then ns.Riddle.Stop() end
	currentStory = story
	nextLine = 1
	storyTarget = nil
	confirmingDelete = false
	wipe(framingSaid)
	wipe(framingNext)
	ns.Teller.StopCue()
	refreshRowColors()
	refreshReader()
end

-- Speaks the next line and shrinks the menu to the teller bar. At the end of a
-- story, it loads a legend's next part, or the next one on Tonight's list,
-- without saying anything.
function ns.Story.SpeakNext()
	if not currentStory then return end
	local total = #currentStory.lines
	-- After a riddle is asked, Speak announces the winner, or gives the hint, or the answer.
	if nextLine > total and currentStory.riddle and ns.Riddle.For(currentStory) then
		local text, what = ns.Riddle.Next()
		if text then
			if ns.SendLine(text, "SAY") then
				ns.Riddle.Said(what)
				refreshReader()
			end
			return
		end
	end
	if nextLine > total then
		local following = followingStory()
		if following then selectStory(following) end
		return
	end

	local name = currentStory.needsTarget and listenerName() or nil
	if currentStory.needsTarget and not name then return end
	local line = currentStory.lines[nextLine]
	local text = name and fillTarget(line.text, name) or line.text
	if not ns.SendLine(text, ns.ChatType[line.kind]) then return end

	storyTarget = name
	offering = false
	-- A riddle starts listening for answers with its first line.
	if currentStory.riddle and nextLine == 1 then ns.Riddle.Start(currentStory) end
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

-- Moves the chosen story to the teller bar, ready to tell, without saying anything.
function ns.Story.Ready()
	if not currentStory then return end
	ns.PlayUISound("IG_ABILITY_PAGE_TURN")
	refreshReader()
	ns.Teller.Show()
	window:Hide()
end

-- Says the opener or closer the teller bar is showing, with a cue, as Speak does.
function ns.Story.SayFraming()
	local which = framingNow()
	local line = which and framingLine(which)
	if not line or not ns.SendLine(line.text, ns.ChatType[line.kind]) then return end
	framingUsed[line] = true
	framingNext[which] = nil
	framingSaid[which] = true
	offering = false
	refreshReader()
	if window:IsShown() then
		ns.Teller.Show()
		window:Hide()
	end
	ns.Teller.StartCue(line.text)
end

-- The button's tooltip shows exactly what it will say.
function ns.Story.ShowFramingTooltip(owner)
	local text = ns.Story.PeekFraming()
	if not text then return end
	GameTooltip:SetOwner(owner, "ANCHOR_TOP")
	GameTooltip:SetText(framingNow() == "opener" and "Say an opener" or "Say a closer")
	GameTooltip:AddLine(text, 1, 1, 1, true)
	GameTooltip:Show()
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

-- The words that mean a zone: its name and the places in it.
local function zoneTerms(zone)
	local terms = { zone:lower() }
	for _, term in ipairs(ns.ZoneTerms[zone] or {}) do
		terms[#terms + 1] = term
	end
	return terms
end

local function mentionsAny(story, terms)
	local text = textOf(story)
	for _, term in ipairs(terms) do
		if text:find(term, 1, true) then return true end
	end
	return false
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

	local terms = zoneTerms(zone)
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
		-- Stories told to a target, festival stories, legends, and rumors also keep
		-- to their own.
		local own = { places = true, target = true, festival = true, legend = true, rumors = true, community = true, riddle = true }
		if not own[section.source] then
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
		label:SetPoint("RIGHT", -34, 0)
		label:SetJustifyH("LEFT")
		label:SetWordWrap(false)
		row.count = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
		row.count:SetPoint("RIGHT", -6, 0)
		-- A fixed spot, so titles line up whether or not a story is a favorite.
		row.star = row:CreateTexture(nil, "OVERLAY")
		row.star:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")
		row.star:SetSize(12, 12)
		row.star:SetPoint("LEFT", 3, 0)
		-- Hovering a story says what the row's marks mean.
		row:SetScript("OnEnter", function(self)
			local story = self.story
			local char = ns.CharData()
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(story.title)
			local mood = (story.mood or ""):gsub("^%l", string.upper)
			GameTooltip:AddLine(("%s, about %d seconds to tell, %d lines"):format(mood, storySeconds(story), #story.lines), 1, 1, 1)
			if story.kind then GameTooltip:AddLine("Added by you", 0.73, 0.9, 0.79) end
			if story.week then
				GameTooltip:AddLine("Shared at firesidetales.dev, " .. ns.CommunityCredit(story), 0.85, 0.75, 0.5, true)
			end
			if char.favorites[story.key] then GameTooltip:AddLine("A favorite", 1, 0.82, 0) end
			if char.told[story.key] then GameTooltip:AddLine("You " .. toldText(char.told[story.key]):gsub("^told", "told it"), 0.6, 0.6, 0.6) end
			GameTooltip:Show()
		end)
		row:SetScript("OnLeave", function() GameTooltip:Hide() end)
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

-- The stories of each festival on today, each list tagged with its festival.
local function festivalStoriesNow()
	local out = {}
	for _, festival in ipairs(ns.Season.Active()) do
		for _, section in ipairs(getSections()) do
			if section.source == "festival" and section.header == festival.name then
				local stories = { festival = festival }
				for _, story in ipairs(section.stories) do
					stories[#stories + 1] = story
				end
				out[#out + 1] = stories
			end
		end
	end
	return out
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
	local tabTotal = 0
	for _, section in ipairs(getSections()) do
		if inTab(section.source) then tabTotal = tabTotal + #section.stories end
	end

	if currentTab ~= "stories" then
		-- The other tabs are short, so their sections start open. Rumors and legends
		-- about where you're standing come first.
		local zone = ns.CurrentZone()
		if currentTab == "rumors" and zone then
			local terms, stories = zoneTerms(zone), {}
			for _, section in ipairs(getSections()) do
				if section.source == "rumors" then
					for _, story in ipairs(section.stories) do
						if mentionsAny(story, terms) then stories[#stories + 1] = story end
					end
				end
			end
			showSection("Here in " .. zone, stories, nil, true)
			moveUp(stories)
		end
		for pass = 1, 2 do
			for _, section in ipairs(getSections()) do
				local isHere = section.source == "legend" and section.stories[1].legend.zone == zone
				if inTab(section.source) and (pass == 1) == isHere then
					showSection(section.label or section.header, section.stories, skip,
						section.source ~= "community" or section.latest or false)
				end
			end
		end
	else
		if filters.show == "tonight" or not filters.source then
			local stories = tonightStories()
			showSection("Tonight", stories, nil, true)
			moveUp(stories)
		end
		if filters.show ~= "tonight" then
			if not filters.source then
				for _, stories in ipairs(festivalStoriesNow()) do
					showSection("On now: " .. stories.festival.name, stories, skip, true)
					moveUp(stories)
				end
			end
			if not filters.source or filters.source == "here" then
				local zone, stories = getHereStories()
				if zone then
					showSection("Here in " .. zone, stories, skip, true)
					moveUp(stories)
				end
			end
			if filters.source ~= "here" then
				for _, section in ipairs(getSections()) do
					if inTab(section.source) and (not filters.source or section.source == filters.source) then
						local isMine = section.source == "mine"
						showSection(section.label or section.header, section.stories, not isMine and skip or nil, isMine)
					end
				end
			end
		end
	end

	listContent:SetHeight(math.max(-y + 4, 1))
	list:SetVerticalScroll(keepScroll and scroll or 0)
	clearFiltersButton:SetShown(isFiltering() and true or false)
	countLabel:SetText(("%d of %d %s"):format(shown, tabTotal, currentTab == "legends" and "parts" or currentTab == "riddles" and "riddles" or "stories"))
	if currentTab == "mine" and tabTotal == 0 then
		emptyLabel:SetText("No tales of your own yet.\nPress Write Your Tales to add some.")
	elseif currentTab == "community" and tabTotal == 0 then
		emptyLabel:SetText("No community stories yet.\nPress Contribute a Story to send yours.")
	else
		emptyLabel:SetText("No stories match these filters.")
	end
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

-------------------------------------------------------------------------------
-- Tell a Tale: the fire picks a story for you
-------------------------------------------------------------------------------

-- Prefers a story you haven't told, for a festival that's on, then about where
-- you are, then one of your own, your race's, or your class's, then any shared
-- one. Within each, spooky and dark tales come first at night, and the others by
-- day. Stories that need a target are left out, since you may not have anyone
-- targeted, and so are legends, which start at Part 1 from their own tab.
local function pickTale()
	local festival = {}
	for _, stories in ipairs(festivalStoriesNow()) do
		for _, story in ipairs(stories) do
			festival[#festival + 1] = story
		end
	end
	local _, here = getHereStories()
	local tiers = { festival, here, {}, {} }
	for _, section in ipairs(getSections()) do
		local tier = (section.source == "mine" or section.source == "race" or section.source == "class") and tiers[3]
			or (section.source == "shared" or section.source == "rumors" or section.latest) and tiers[4]
		if tier then
			for _, story in ipairs(section.stories) do
				tier[#tier + 1] = story
			end
		end
	end

	local told = ns.CharData().told
	local night = ns.Season.IsNight()
	local function suitsTheHour(story)
		local grim = story.mood == "spooky" or story.mood == "dark"
		return grim == night
	end
	local function choose(fits)
		for _, tier in ipairs(tiers) do
			local pool, suited = {}, {}
			for _, story in ipairs(tier) do
				if story ~= currentStory and not story.needsTarget and fits(story) then
					pool[#pool + 1] = story
					if suitsTheHour(story) then suited[#suited + 1] = story end
				end
			end
			if #suited > 0 then return suited[math.random(#suited)] end
			if #pool > 0 then return pool[math.random(#pool)] end
		end
	end
	local story = choose(function(s) return not told[s.key] and not offered[s.key] end)
		or choose(function(s) return not offered[s.key] end)
	if not story then
		wipe(offered) -- Every story has had its turn, so start over.
		story = choose(function() return true end)
	end
	if story then offered[story.key] = true end
	return story
end

-- An offer by the fire goes away by itself if nobody takes it.
local function armOfferTimeout()
	offerGeneration = offerGeneration + 1
	local generation = offerGeneration
	C_Timer.After(OFFER_SECONDS, function()
		if generation == offerGeneration then ns.Story.EndOffer() end
	end)
end

function ns.Story.TellATale()
	local story = pickTale()
	if not story then return end
	ns.PlayUISound("IG_ABILITY_PAGE_TURN")
	selectStory(story)
	if offering then armOfferTimeout() end
end

-- Offers a story on the teller bar. A story you chose but haven't begun is kept.
-- Returns whether anything was offered.
function ns.Story.Offer()
	if not window then buildWindow() end
	if window:IsShown() or ns.Teller.IsShown() then return false end
	if currentStory and nextLine > 1 and nextLine <= #currentStory.lines then return false end
	if not currentStory or nextLine > 1 then
		local story = pickTale()
		if not story then return false end
		selectStory(story)
	end
	offering = true
	refreshReader()
	ns.Teller.Show()
	armOfferTimeout()
	return true
end

function ns.Story.IsOffering()
	return offering and nextLine == 1 and ns.Teller.IsShown()
end

function ns.Story.EndOffer()
	if ns.Story.IsOffering() then ns.Teller.Hide() end
	offering = false
end

function ns.Story.TellerClosed()
	offering = false
	offerGeneration = offerGeneration + 1
end

-- Rebuilds the menu after stories are pasted in or deleted.
function ns.Story.StoriesChanged()
	sections = nil
	wipe(offered)
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
		local grouped = { shared = "Everyone", places = "Places", target = "Target", festival = "Festivals" }
		local seen = {}
		for _, section in ipairs(getSections()) do
			if not seen[section.source] and inTab(section.source) then
				seen[section.source] = true
				sources[#sources + 1] = { key = section.source, label = grouped[section.source] or section.header }
			end
		end
		return sources
	end
	fromButton = buildSelector("From", "source", getSources, 118)
	fromButton:SetPoint("LEFT", searchBox, "RIGHT", 6, 0)

	local moods = { { key = nil, label = "All" } }
	for _, mood in ipairs(MOODS) do
		moods[#moods + 1] = mood
	end
	moodButton = buildSelector("Mood", "mood", function() return moods end, 112)
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

-- From only makes sense on the Stories tab. Elsewhere, Mood moves over into its place.
local function refreshFilterBar()
	if writeButton then
		writeButton:SetShown(currentTab ~= "community")
		contributeButton:SetShown(currentTab == "community")
	end
	local onStories = currentTab == "stories"
	fromButton:SetShown(onStories)
	moodButton:ClearAllPoints()
	moodButton:SetPoint("LEFT", onStories and fromButton or searchBox, "RIGHT", onStories and 4 or 6, 0)
end

-------------------------------------------------------------------------------
-- The tabs down the window's right edge, like the spellbook's
-------------------------------------------------------------------------------

local TABS = {
	{ key = "mine", tooltip = "Your Tales", detail = "Your character's own stories.", portrait = true },
	{ key = "stories", tooltip = "Stories", detail = "Tales for every race, class, and zone.",
		icons = { "Interface\\Icons\\INV_Misc_Note_01", "Interface\\Icons\\INV_Misc_Book_09" } },
	{ key = "legends", tooltip = "Legends", detail = "Warcraft's own stories, told in parts.",
		icons = { "Interface\\Icons\\INV_Misc_Book_07", "Interface\\Icons\\INV_Misc_Book_11" } },
	{ key = "rumors", tooltip = RUMORS_THEME, detail = "Short things people swear they heard.",
		icons = { "Interface\\Icons\\INV_Drink_05", "Interface\\Icons\\INV_Letter_09" } },
	{ key = "riddles", tooltip = "Riddles", detail = "Ask a riddle, and the first one nearby to say the answer wins.",
		icons = { "Interface\\Icons\\INV_Misc_QuestionMark" } },
	{ key = "community", tooltip = "Community", detail = "Stories players shared at firesidetales.dev, new each week.",
		icons = { "Interface\\Icons\\Achievement_Reputation_01", "Interface\\Icons\\INV_Misc_GroupNeedMore" } },
}

-- The first icon the client has. SetTexture says when a file is missing.
local function setFirstTexture(texture, paths)
	for _, path in ipairs(paths) do
		if texture:SetTexture(path) ~= false then return end
	end
end

local setTab -- Defined below, after the tabs it switches between.

local function refreshTabs()
	for _, tab in ipairs(tabButtons) do
		tab.selected:SetShown(tab.key == currentTab)
		if tab.portrait and SetPortraitTexture then
			SetPortraitTexture(tab.icon, "player")
		end
	end
end

local function hasAtlas(name)
	return C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name) ~= nil
end

-- The square tabs on the right of the character window, where the client has them.
-- Otherwise, the spellbook's smaller tabs.
local function makeTab(info, sideTabs)
	local tab = CreateFrame("Button", nil, window)
	tab.icon = tab:CreateTexture(nil, "ARTWORK")
	tab.selected = tab:CreateTexture(nil, "OVERLAY")
	local hover = tab:CreateTexture(nil, "HIGHLIGHT")
	if sideTabs then
		tab:SetSize(55, 55)
		local frame = tab:CreateTexture(nil, "BACKGROUND")
		frame:SetAtlas("common-sidetab")
		frame:SetSize(55, 60)
		frame:SetPoint("CENTER")
		tab.icon:SetSize(34, 34)
		tab.icon:SetPoint("CENTER", -2, 0)
		for _, art in ipairs({ { tab.selected, "common-sidetab-selected" }, { hover, "common-sidetab-hover" } }) do
			art[1]:SetAtlas(art[2])
			art[1]:SetSize(55, 60)
			art[1]:SetPoint("CENTER")
		end
	else
		tab:SetSize(32, 32)
		local frame = tab:CreateTexture(nil, "BACKGROUND")
		frame:SetTexture("Interface\\SpellBook\\SpellBook-SkillLineTab")
		frame:SetSize(64, 64)
		frame:SetPoint("TOPLEFT", -3, 11)
		tab.icon:SetAllPoints()
		for _, art in ipairs({ { tab.selected, "Interface\\Buttons\\CheckButtonHilight" }, { hover, "Interface\\Buttons\\ButtonHilight-Square" } }) do
			art[1]:SetTexture(art[2])
			art[1]:SetBlendMode("ADD")
			art[1]:SetAllPoints()
		end
	end
	if not info.portrait then
		setFirstTexture(tab.icon, info.icons)
		tab.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Trims the icon's own border.
		-- The character window's icons fill the tab's square, nearly to its rim.
		if sideTabs then tab.icon:SetSize(41, 41) end
	end
	tab.selected:Hide()
	tab:SetScript("OnClick", function() setTab(info.key) end)
	tab:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(info.tooltip)
		GameTooltip:AddLine(info.detail, 1, 1, 1, true)
		GameTooltip:Show()
	end)
	tab:SetScript("OnLeave", function() GameTooltip:Hide() end)
	tab.key, tab.portrait = info.key, info.portrait
	return tab
end

function setTab(key)
	if key ~= currentTab then
		ns.PlayUISound("IG_CHARACTER_INFO_TAB")
		currentTab = key
		filters.source = nil
		hidePopup()
		refreshFilterBar()
		refreshSelectors()
		renderList()
		if not currentStory then refreshReader() end -- The Community tab's hint differs.
	end
	refreshTabs()
end

local function buildTabs()
	local sideTabs = hasAtlas("common-sidetab") and hasAtlas("common-sidetab-selected")
	for index, info in ipairs(TABS) do
		local tab = makeTab(info, sideTabs)
		if index == 1 then
			-- Flush with the window's edge, as the character window's tabs sit.
			tab:SetPoint("TOPLEFT", window, "TOPRIGHT", sideTabs and -3 or 0, sideTabs and -40 or -36)
		else
			tab:SetPoint("TOPLEFT", tabButtons[index - 1], "BOTTOMLEFT", 0, sideTabs and -4 or -17)
		end
		tabButtons[index] = tab
	end
	refreshTabs()
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
	speakButton:SetText("Tell")
	speakButton:SetScript("OnClick", function()
		if currentStory and nextLine == 1 then
			ns.Story.Ready()
		else
			ns.Story.SpeakNext()
		end
	end)

	restartButton = ns.MakeFlatButton(window, "Restart", 56)
	restartButton:SetPoint("RIGHT", speakButton, "LEFT", -4, 0)
	restartButton:SetScript("OnClick", function()
		if currentStory then
			ns.PlayUISound("IG_ABILITY_PAGE_TURN")
			selectStory(currentStory)
		end
	end)

end

function buildWindow()
	window = ns.NewWindow("FiresideTalesStoryFrame", "Fireside Tales", "Interface\\AddOns\\FiresideTales\\Textures\\Icon",
		LIST_WIDTH + READER_WIDTH + 58, 540)
	ns.MakeDraggable(window, "storyPosition")
	ns.PlaceFrame(window, "storyPosition", "CENTER", UIParent, "CENTER", 0, 40)
	table.insert(UISpecialFrames, "FiresideTalesStoryFrame") -- Escape closes it.

	-- The story count and a small version number sit quietly in the title bar,
	-- left of the close button.
	countLabel = window:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	if ns.Version then
		local version = window:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
		version:SetPoint("TOPRIGHT", -30, -6)
		version:SetText("v" .. ns.Version)
		countLabel:SetPoint("RIGHT", version, "LEFT", -10, 0)
	else
		countLabel:SetPoint("TOPRIGHT", -30, -6)
	end

	local tellATale = ns.MakeFlatButton(window, "Tell a Tale", 84)
	tellATale:SetPoint("BOTTOMLEFT", INSET_LEFT, 7)
	tellATale:SetScript("OnClick", ns.Story.TellATale)
	ns.SetFlatButtonOn(tellATale, true) -- Gold, so it's easy to find.

	-- Write Your Tales makes stories for your character alone. On the Community tab,
	-- the same spot offers Contribute a Story, which shares one with every player.
	writeButton = ns.MakeFlatButton(window, "Write Your Tales", 112)
	writeButton:SetPoint("LEFT", tellATale, "RIGHT", 4, 0)
	writeButton:SetScript("OnClick", ns.Import.Toggle)
	contributeButton = ns.MakeFlatButton(window, "Contribute a Story", 124)
	contributeButton:SetPoint("LEFT", tellATale, "RIGHT", 4, 0)
	contributeButton:SetScript("OnClick", ns.Story.ToggleContribute)
	contributeButton:Hide()

	buildList()
	buildReader()
	buildFilters()
	buildTabs()
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

-------------------------------------------------------------------------------
-- Contribute a Story: where to send a story for every player
-------------------------------------------------------------------------------

local CONTRIBUTE_URL = "firesidetales.dev/submit"
local contributeWindow

local function buildContribute()
	contributeWindow = ns.NewWindow("FiresideTalesContributeFrame", "Contribute a Story",
		"Interface\\AddOns\\FiresideTales\\Textures\\Icon", 400, 180)
	contributeWindow:SetFrameStrata("DIALOG")
	ns.MakeDraggable(contributeWindow, "contributePosition")
	ns.PlaceFrame(contributeWindow, "contributePosition", "CENTER", UIParent, "CENTER", 0, 60)
	table.insert(UISpecialFrames, "FiresideTalesContributeFrame") -- Escape closes it.

	local intro = contributeWindow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	intro:SetPoint("TOPLEFT", 66, -36)
	intro:SetPoint("TOPRIGHT", -14, -36)
	intro:SetJustifyH("LEFT")
	intro:SetText("Write a story or rumor for every player, on the Fireside Tales site. Each week, up to 100 are featured "
		.. "in the Community tab, credited to you, or shared anonymously if you like.")

	-- Addons can't open a web page, so the address is ready to copy. It can't be edited.
	local box = CreateFrame("EditBox", nil, contributeWindow, "InputBoxTemplate")
	box:SetSize(250, 24)
	box:SetPoint("TOP", 0, -112)
	box:SetAutoFocus(false)
	box:SetFontObject("ChatFontNormal")
	box:SetJustifyH("CENTER")
	box:SetText(CONTRIBUTE_URL)
	box:SetScript("OnTextChanged", function(self, userInput)
		if userInput then
			self:SetText(CONTRIBUTE_URL)
			self:HighlightText()
		end
	end)
	box:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
	box:SetScript("OnEscapePressed", function(self) self:ClearFocus(); contributeWindow:Hide() end)
	box:SetScript("OnMouseUp", function(self) self:HighlightText() end)
	contributeWindow.box = box

	local hint = contributeWindow:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	hint:SetPoint("TOP", box, "BOTTOM", 0, -8)
	hint:SetText("Selected. Press Cmd+C on a Mac or Ctrl+C on Windows to copy it.")

	contributeWindow:Hide()
	ns.AddWindowSounds(contributeWindow)
	contributeWindow:HookScript("OnShow", function()
		box:SetFocus()
		box:HighlightText()
	end)
end

function ns.Story.ToggleContribute()
	if not contributeWindow then buildContribute() end
	contributeWindow:SetShown(not contributeWindow:IsShown())
end

-- Someone nearby answered the riddle in play.
function ns.Story.RiddleChanged()
	if currentStory and currentStory.riddle then refreshReader() end
end

function ns.Story.Toggle()
	if not window then buildWindow() end
	if window:IsShown() then
		window:Hide()
	else
		ns.Teller.Hide()
		renderList() -- You may have changed zones since it was last open.
		refreshTabs() -- And your portrait may have changed.
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
