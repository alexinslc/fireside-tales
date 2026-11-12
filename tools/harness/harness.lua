-- Headless smoke test for Fireside Tales: stubs the WoW API, loads the addon the
-- way the client does (TOC order, missing files skipped), and drives its flows.
-- It proves the addon's Lua logic, NOT that the stubbed APIs exist in the client.
--
-- Run it with LuaJIT or any Lua 5.1:
--   luajit tools/harness/harness.lua [addon folder] [pasted reply file]
-- The addon folder defaults to addon/FiresideTales next to this tools folder.
local scriptDir = (arg and arg[0] or ""):match("^(.*)[/\\]") or "."
local ADDON_DIR = ADDON_DIR or (arg and arg[1]) or (scriptDir .. "/../../addon/FiresideTales")
PASTE_FILE = PASTE_FILE or (arg and arg[2])
local realG = _G
local stdPrint = print

local passed, failed = 0, 0
local failures = {}
local function check(name, cond, detail)
	if cond then
		passed = passed + 1
	else
		failed = failed + 1
		failures[#failures + 1] = name .. (detail and (" -- " .. tostring(detail)) or "")
		stdPrint("  FAIL " .. name .. (detail and (" -- " .. tostring(detail)) or ""))
	end
end

-- World state the stubs read from.
local W
local allFrames
local eventFrames
local timers
local sent
local chatOut
local unknownGlobals = {}
local SECRET = "<<secret>>"

local function resetWorld()
	W = {
		now = 1000, zone = "Elwynn Forest", name = "Testhero", race = { "Human", "Human" },
		class = { "Warrior", "WARRIOR" }, target = nil, dead = false, level = 12, lockdown = false,
		-- A plain Saturday with no festival on, at noon.
		day = { year = 2026, month = 11, monthDay = 7, weekday = 7 }, hour = 12,
	}
	allFrames, eventFrames, timers, sent, chatOut = {}, {}, {}, {}, {}
end

local function effectiveShown(f)
	while f do
		if f._hidden then return false end
		f = f._parent
	end
	return true
end

local frameMethods = {}
frameMethods.__index = function(self, key)
	local method = rawget(frameMethods, key)
	if method then return method end
	-- Unmodelled API methods (always capitalized) are no-ops; data fields are nil.
	if type(key) == "string" and key:find("^%u") then
		return function() end
	end
	return nil
end

function frameMethods:SetScript(what, fn) self._scripts[what] = fn end
function frameMethods:GetScript(what) return self._scripts[what] end
function frameMethods:HookScript(what, fn)
	local old = self._scripts[what]
	self._scripts[what] = function(...)
		if old then old(...) end
		fn(...)
	end
end
function frameMethods:Show()
	if self._hidden then
		self._hidden = false
		if self._scripts.OnShow then self._scripts.OnShow(self) end
	end
end
function frameMethods:Hide()
	if not self._hidden then
		self._hidden = true
		if self._scripts.OnHide then self._scripts.OnHide(self) end
	end
end
function frameMethods:IsShown() return not self._hidden end
function frameMethods:SetShown(on) if on then self:Show() else self:Hide() end end
function frameMethods:SetText(text)
	if type(text) == "number" then text = tostring(text) end -- The client accepts numbers.
	self._text = text
	if self._type == "EditBox" and self._scripts.OnTextChanged then self._scripts.OnTextChanged(self) end
	if self._type == "Button" and not self._font then self._font = frameMethods.CreateFontString(self) end
end
function frameMethods:GetText() return self._text or "" end
function frameMethods:GetFontString() return self._font end
function frameMethods:SetEnabled(on) self._disabled = not on end
function frameMethods:Enable() self._disabled = false end
function frameMethods:Disable() self._disabled = true end
function frameMethods:IsEnabled() return not self._disabled end
function frameMethods:RegisterEvent(event)
	self._events[event] = true
	eventFrames[self] = true
end
function frameMethods:UnregisterAllEvents() self._events = {} end
function frameMethods:SetHeight(h) self._h = h end
function frameMethods:SetWidth(w) self._w = w end
function frameMethods:SetSize(w, h) self._w, self._h = w, h end
function frameMethods:GetHeight() return self._h or 100 end
function frameMethods:GetWidth() return self._w or 100 end
function frameMethods:GetStringHeight() return 14 end
function frameMethods:GetCenter() return 500, 400 end
function frameMethods:GetBottom() return 300 end
function frameMethods:GetPoint() return "CENTER", realG.UIParent, "CENTER", 0, 0 end
function frameMethods:GetFrameLevel() return 1 end
function frameMethods:GetEffectiveScale() return 1 end
function frameMethods:GetVerticalScroll() return self._scroll or 0 end
function frameMethods:SetVerticalScroll(v) self._scroll = v end
function frameMethods:GetVerticalScrollRange() return 100 end
function frameMethods:CreateFontString()
	return realG.CreateFrame("FontString", nil, self)
end
function frameMethods:CreateTexture()
	return realG.CreateFrame("Texture", nil, self)
end

local function installApi()
	realG.CreateFrame = function(kind, name, parent)
		local frame = setmetatable({
			_type = kind, _parent = parent, _scripts = {}, _events = {}, _name = name,
		}, frameMethods)
		allFrames[#allFrames + 1] = frame
		if name then rawset(realG, name, frame) end
		return frame
	end
	realG.UIParent = realG.CreateFrame("Frame", "UIParent")
	realG.Minimap = realG.CreateFrame("Frame", "Minimap", realG.UIParent)
	realG.GameTooltip = realG.CreateFrame("Frame", "GameTooltip", realG.UIParent)
	realG.UISpecialFrames = {}
	realG.SlashCmdList = {}
	realG.SOUNDKIT = { TELL_MESSAGE = 3081, IG_SPELLBOOK_OPEN = 829, IG_SPELLBOOK_CLOSE = 830, IG_ABILITY_PAGE_TURN = 836,
		IG_MAINMENU_OPTION = 852, IG_MAINMENU_OPTION_CHECKBOX_ON = 856, IG_MAINMENU_OPTION_CHECKBOX_OFF = 857 }
	realG.GetTime = function() return W.now end
	-- Friday, January 15, 2027, 08:00 UTC, so the community week began Tuesday the 12th.
	realG.time = function(t) if t then return os.time(t) end return 1800000000 end
	realG.GetServerTime = function() return W.serverTime or 1800000000 end
	realG.date = os.date
	realG.C_GameRules = { IsHardcoreActive = function() return W.hardcore or false end }
	realG.wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
	realG.unpack = unpack
	realG.PlaySound = function(id)
		W.sounds = (W.sounds or 0) + 1
		W.soundLog = W.soundLog or {}
		for name, value in pairs(realG.SOUNDKIT) do
			if value == id then W.soundLog[#W.soundLog + 1] = name end
		end
	end
	realG.Ambiguate = function(sender) return (sender:gsub("%-.*$", "")) end
	realG.GetCursorPosition = function() return 500, 500 end
	realG.GetZoneText = function() return W.zone end
	realG.UnitName = function(unit)
		if unit == "player" then return W.name end
		if unit == "target" then return W.target end
	end
	realG.UnitRace = function() return W.race[1], W.race[2] end
	realG.UnitClass = function() return W.class[1], W.class[2] end
	realG.UnitLevel = function() return W.level end
	realG.UnitExists = function(unit) return unit == "player" or (unit == "target" and W.target ~= nil) end
	realG.UnitIsUnit = function(a, b) return a == b or (W.target == W.name) end
	realG.UnitIsDeadOrGhost = function() return W.dead end
	realG.issecretvalue = function(v) return v == SECRET end
	realG.GetUnitSpeed = function() return W.moving and 7 or 0 end
	realG.UnitAffectingCombat = function() return W.combat or false end
	realG.C_UnitAuras = {
		GetPlayerAuraBySpellID = function(id)
			if W.fire and id == 7353 then return { name = "Cozy Fire", spellId = 7353 } end
		end,
	}
	realG.AuraUtil = {
		FindAuraByName = function(name, unit)
			if W.fireByName and name == W.fireByName and unit == "player" then return name end
		end,
	}
	realG.GetGameTime = function() return W.hour, 0 end
	realG.C_DateAndTime = { GetCurrentCalendarTime = function() return W.day end }
	if W.calendar then
		realG.C_Calendar = {
			OpenCalendar = function() W.calendarOpened = true end,
			GetMonthInfo = function() return { month = W.day.month, year = W.day.year } end,
			GetNumDayEvents = function(offset, day) return offset == 0 and #(W.calendar[day] or {}) or 0 end,
			GetDayEvent = function(offset, day, index)
				return { title = W.calendar[day][index], calendarType = "HOLIDAY" }
			end,
		}
	else
		realG.C_Calendar = nil
	end
	realG.C_Timer = { After = function(seconds, fn) timers[#timers + 1] = { at = W.now + seconds, fn = fn } end }
	realG.C_ChatInfo = {
		InChatMessagingLockdown = function() return W.lockdown end,
		SendChatMessage = function(text, chatType)
			assert(type(text) == "string" and #text <= 255, "chat message over 255 bytes")
			sent[#sent + 1] = { text = text, chatType = chatType }
		end,
	}
	realG.C_AddOns = {
		GetAddOnMetadata = function(addon, field)
			for raw in io.lines(ADDON_DIR .. "/FiresideTales.toc") do
				local value = raw:match("^## " .. field .. ":%s*(.-)%s*$")
				if addon == "FiresideTales" and value then return value end
			end
		end,
	}
	realG.print = function(msg) chatOut[#chatOut + 1] = tostring(msg) end
end

local function advance(seconds)
	W.now = W.now + seconds
	local due = {}
	for i = #timers, 1, -1 do
		if timers[i].at <= W.now then
			due[#due + 1] = table.remove(timers, i)
		end
	end
	for _, t in ipairs(due) do t.fn() end
end

local function fire(event, ...)
	for frame in pairs(eventFrames) do
		if frame._events[event] and frame._scripts.OnEvent then
			frame._scripts.OnEvent(frame, event, ...)
		end
	end
end

local function slash(text) realG.SlashCmdList.FIRESIDETALES(text) end

local function plainText(s)
	s = (s or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|T.-|t ?", "")
	return s
end

-- Finds a visible button by its text; a disabled one can't be clicked.
local function findButton(label, parent)
	for _, f in ipairs(allFrames) do
		if f._type == "Button" and effectiveShown(f) and plainText(f._text) == label
			and (not parent or f._parent == parent) then
			return f
		end
	end
end

local function click(f, what)
	assert(f, "no button to click: " .. tostring(what))
	if f._disabled then return false end
	f._scripts.OnClick(f, "LeftButton", false)
	return true
end

local function clickLabel(label, parent)
	return click(findButton(label, parent), label)
end

local function visibleRows()
	local rows = {}
	for _, f in ipairs(allFrames) do
		if rawget(f, "story") and effectiveShown(f) then rows[#rows + 1] = f end
	end
	return rows
end

local function rowFor(title)
	for _, f in ipairs(visibleRows()) do
		if f.story.title == title then return f end
	end
end

-- "- Name" finds an open section. Headers now show their state with an icon.
local function headerStartingWith(prefix)
	local name = prefix:gsub("^%- ", "")
	for _, f in ipairs(allFrames) do
		if f._type == "Button" and rawget(f, "open") == true and effectiveShown(f)
			and plainText(f._text):find(name, 1, true) == 1 then
			return f
		end
	end
end

local function storyWindow() return rawget(realG, "FiresideTalesStoryFrame") end
local function tellerBar() return rawget(realG, "FiresideTalesTellerBar") end

local function boot(db)
	resetWorldKeep = nil
	allFrames, eventFrames, timers = {}, {}, {}
	rawset(realG, "FiresideTalesStoryFrame", nil)
	rawset(realG, "FiresideTalesTellerBar", nil)
	rawset(realG, "FiresideTalesImportFrame", nil)
	rawset(realG, "FiresideTalesFrame", nil)
	rawset(realG, "FiresideTalesMinimapButton", nil)
	installApi()
	realG.FiresideTalesDB = db

	local ns, loaded, skipped = {}, {}, {}
	for raw in io.lines(ADDON_DIR .. "/FiresideTales.toc") do
		local file = raw:gsub("%s+$", "")
		if file:find("%.lua$") then
			local handle = io.open(ADDON_DIR .. "/" .. file)
			if handle then
				local source = handle:read("*a")
				handle:close()
				local chunk, err = loadstring(source, "@" .. file)
				if not chunk then error("SYNTAX " .. err) end
				chunk("FiresideTales", ns)
				loaded[#loaded + 1] = file
			else
				skipped[#skipped + 1] = file
			end
		end
	end
	fire("ADDON_LOADED", "FiresideTales")
	fire("PLAYER_LOGIN")
	fire("PLAYER_ENTERING_WORLD", true, false)
	return ns, loaded, skipped
end

-- Strict globals: report anything the addon reads that we don't provide.
setmetatable(realG, {
	__index = function(_, key)
		unknownGlobals[key] = true
		return nil
	end,
})

local function scenario(name, fn)
	stdPrint("== " .. name)
	local ok, err = xpcall(fn, debug.traceback)
	check(name .. " (no Lua error)", ok, err)
end

resetWorld()
local ns, loaded, skipped

scenario("fresh install loads with local story files absent", function()
	ns, loaded, skipped = boot(nil)
	stdPrint(("   loaded %d files, skipped %d: %s"):format(#loaded, #skipped, table.concat(skipped, ", ")))
	check("only the 3 character files are skipped", #skipped == 3, table.concat(skipped, ", "))
	check("minimap button built", rawget(realG, "FiresideTalesMinimapButton") ~= nil)
	slash("status")
	stdPrint("   " .. plainText(chatOut[#chatOut]))
	check("/tales status prints", chatOut[#chatOut]:find("Testhero the Human Warrior", 1, true))
	check("/tales status shows the version", ns.Version and chatOut[#chatOut]:find("version " .. ns.Version, 1, true), ns.Version)
	slash("stories")
	local shown
	for _, f in ipairs(allFrames) do
		if f._text == "v" .. tostring(ns.Version) then shown = f end
	end
	check("story menu shows the version", shown ~= nil)
	storyWindow():Hide()
end)

scenario("starter story data obeys the addon's rules", function()
	local moods = { funny = 1, heartfelt = 1, dark = 1, action = 1, spooky = 1, wise = 1 }
	local function validate(list, where, wantTheme, wantTarget)
		local titles = {}
		for _, story in ipairs(list) do
			local id = where .. "/" .. tostring(story.title)
			check(id .. " has a known mood", moods[story.mood], story.mood)
			check(id .. " has 3-8 lines", #story.lines >= 3 and #story.lines <= 8, #story.lines)
			if wantTheme then check(id .. " has a theme", story.theme) end
			check(id .. " has no story-level kind (would show Delete)", story.kind == nil)
			local key = tostring(story.theme) .. "/" .. tostring(story.title)
			check(id .. " is unique", not titles[key])
			titles[key] = true
			local says, emotes, targets = 0, 0, 0
			for n, line in ipairs(story.lines) do
				check(id .. " line kind", ns.ChatType[line.kind], line.kind)
				if line.kind == "say" then says = says + 1 else emotes = emotes + 1 end
				if line.text:find("{target}", 1, true) then targets = targets + 1 end
				local filled = line.text:gsub("{target}", ("x"):rep(24))
				check(id .. ":" .. n .. " fits a chat message", #filled <= 250, #filled)
				check(id .. ":" .. n .. " has no unsafe characters",
					not line.text:gsub("{target}", ""):find("[|{}\128-\255]"), line.text)
				if line.kind == "emote" then
					check(id .. ":" .. n .. " emote starts lowercase", not line.text:find("^%u"), line.text)
				end
			end
			check(id .. " has a say and an emote", says > 0 and emotes > 0)
			if wantTarget then
				check(id .. " uses {target}", targets > 0)
			else
				check(id .. " doesn't use {target}", targets == 0)
			end
		end
	end
	validate(ns.Stories, "shared", true, false)
	validate(ns.TargetStories, "target", false, true)
	stdPrint(("   %d shared, %d targeted"):format(#ns.Stories, #ns.TargetStories))
end)

scenario("all published stories obey the rules", function()
	local moods = { funny = 1, heartfelt = 1, dark = 1, action = 1, spooky = 1, wise = 1 }
	local total, longest, longestTitle = 0, 0, ""
	local seen, perList = {}, {}
	local function validate(list, where, wantTarget)
		perList[where] = (perList[where] or 0) + #list
		for _, story in ipairs(list) do
			total = total + 1
			local id = where .. "/" .. tostring(story.title)
			check(id .. " unique title", not seen[story.title], seen[story.title])
			seen[story.title] = id
			check(id .. " mood", moods[story.mood], story.mood)
			check(id .. " 3-8 lines", #story.lines >= 3 and #story.lines <= 8, #story.lines)
			check(id .. " no story-level kind", story.kind == nil)
			local says, emotes, targets, seconds = 0, 0, 0, 0
			for n, line in ipairs(story.lines) do
				check(id .. ":" .. n .. " kind", ns.ChatType[line.kind], line.kind)
				if line.kind == "say" then says = says + 1 else emotes = emotes + 1 end
				if line.text:find("{target}", 1, true) then targets = targets + 1 end
				local filled = line.text:gsub("{target}", ("x"):rep(24))
				check(id .. ":" .. n .. " fits chat", #filled <= 250, #filled)
				check(id .. ":" .. n .. " safe text", not line.text:gsub("{target}", ""):find("[|{}\128-\255]"), line.text)
				if line.kind == "emote" then
					check(id .. ":" .. n .. " lowercase emote", not line.text:find("^%u"), line.text)
				end
				seconds = seconds + math.max(4, math.min(14, 3 + #filled / 20))
			end
			check(id .. " say and emote", says > 0 and emotes > 0)
			check(id .. " target use", (targets > 0) == wantTarget, targets)
			check(id .. " under about 60s", seconds <= 60.5, seconds)
			if seconds > longest then longest, longestTitle = seconds, id end
		end
	end
	validate(ns.Stories, "shared", false)
	validate(ns.TargetStories, "target", true)
	for _, group in ipairs({ { "race", ns.RaceStories }, { "class", ns.ClassStories }, { "zone", ns.ZoneStories }, { "festival", ns.FestivalStories } }) do
		for key, list in pairs(group[2]) do
			validate(list, group[1], false)
			check(group[1] .. "/" .. key .. " has stories", #list > 0)
		end
	end
	for _, legend in ipairs(ns.Legends) do
		validate(legend.parts, "legend", false)
		check("legend " .. legend.title .. " has a zone and a summary", legend.zone and legend.summary)
		check("legend " .. legend.title .. " has at least one part", #legend.parts >= 1, #legend.parts)
	end
	stdPrint(("   total %d: shared %d, target %d, race %d, class %d, zone %d, festival %d, legend parts %d; longest %.0fs (%s)"):format(
		total, perList.shared, perList.target, perList.race, perList.class, perList.zone, perList.festival, perList.legend or 0,
		longest, longestTitle))
	check("637 published stories", total == 637, total)
	check("15 legends", #ns.Legends == 15, #ns.Legends)
	for _, festival in ipairs(ns.Season.Festivals) do
		check("festival " .. festival.name .. " has stories", ns.FestivalStories[festival.name] and #ns.FestivalStories[festival.name] >= 2)
	end
	check("no character stories published", next(ns.CharacterStories) == nil)

	-- Every race and class token the game reports has a list, and the menu builds for each.
	for _, who in ipairs({
		{ "Human", "Human" }, { "Dwarf", "Dwarf" }, { "Night Elf", "NightElf" }, { "Gnome", "Gnome" }, { "Orc", "Orc" },
		{ "Undead", "Scourge" }, { "Tauren", "Tauren" }, { "Troll", "Troll" }, { "Skyborne", "Skyborne" },
	}) do
		check("race list for " .. who[2], ns.RaceStories[who[2]] and #ns.RaceStories[who[2]] >= 9, who[2])
	end
	for _, token in ipairs({ "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }) do
		check("class list for " .. token, ns.ClassStories[token] and #ns.ClassStories[token] >= 9, token)
	end
	local zones = 0
	for zone, list in pairs(ns.ZoneStories) do
		zones = zones + 1
		check("zone " .. zone .. " has 3 or more", #list >= 3, #list)
	end
	check("50 zones", zones == 50, zones)
end)

scenario("menu opens, sections expand, a story is told start to finish", function()
	slash("stories")
	check("menu shown", storyWindow():IsShown())
	check("Tell disabled with nothing chosen", findButton("Tell", storyWindow())._disabled)

	local theme = ns.Stories[1].theme
	local story = ns.Stories[1]
	-- It may have been moved to Here in Elwynn Forest, so search for it directly.
	local search
	for _, f in ipairs(allFrames) do if f._type == "EditBox" then search = search or f end end
	search:SetText(story.title:lower())
	local row = rowFor(story.title)
	check("search finds a story by title", row, story.title)
	click(row, "story row")
	search:SetText("")

	local before = #sent
	for i = 1, #story.lines do
		realG.FiresideTales_Speak()
		check("line " .. i .. " sent", #sent == before + i)
		check("line " .. i .. " text matches", sent[#sent].text == story.lines[i].text)
		check("line " .. i .. " chat type matches", sent[#sent].chatType == ns.ChatType[story.lines[i].kind])
	end
	check("menu collapsed to the teller bar", not storyWindow():IsShown() and tellerBar():IsShown())
	check("told recorded", ns.CharData().told[story.key])
	realG.FiresideTales_Speak()
	check("no extra line after the end", #sent == before + #story.lines)
	click(findButton("Menu", tellerBar()), "Menu")
	check("Menu reopens the list", storyWindow():IsShown() and not tellerBar():IsShown())
	storyWindow():Hide()
	check("closing after the end doesn't bring the bar back", not tellerBar():IsShown())
end)

scenario("partway close returns to the teller bar, restart resets", function()
	local story = ns.Stories[2]
	slash("stories")
	local search
	for _, f in ipairs(allFrames) do if f._type == "EditBox" then search = search or f end end
	search:SetText(story.title:lower())
	click(rowFor(story.title), "row")
	search:SetText("")
	realG.FiresideTales_Speak()
	check("bar shown after first line", tellerBar():IsShown())
	click(findButton("Menu", tellerBar()), "Menu")
	storyWindow():Hide()
	check("Escape partway returns to the bar", tellerBar():IsShown())
	click(findButton("Menu", tellerBar()), "Menu")
	local n = #sent
	clickLabel("Restart", storyWindow())
	realG.FiresideTales_Speak()
	check("restart speaks line 1 again", sent[n + 1].text == story.lines[1].text)
	click(findButton("Menu", tellerBar()), "Menu")
	storyWindow():Hide()
	-- Close the bar so later scenarios start clean.
	tellerBar():Hide()
end)

scenario("targeted story needs a target and keeps the name", function()
	local story = ns.TargetStories[1]
	W.target = nil
	slash("stories")
	local search
	for _, f in ipairs(allFrames) do if f._type == "EditBox" then search = search or f end end
	search:SetText(story.title:lower())
	click(rowFor(story.title), "target row")
	search:SetText("")
	local speak = findButton("Tell", storyWindow())
	check("Speak disabled without a target", speak._disabled)
	local n = #sent
	realG.FiresideTales_Speak()
	check("key press sends nothing without a target", #sent == n)
	W.target = W.name
	fire("PLAYER_TARGET_CHANGED")
	check("targeting yourself doesn't count", findButton("Tell", storyWindow())._disabled)
	W.target = "Bjorn"
	fire("PLAYER_TARGET_CHANGED")
	check("Tell enabled once targeted", not findButton("Tell", storyWindow())._disabled)
	realG.FiresideTales_Speak()
	check("name filled in", sent[#sent].text:find("Bjorn", 1, true) and not sent[#sent].text:find("{target}", 1, true), sent[#sent].text)
	W.target = "Someoneelse"
	fire("PLAYER_TARGET_CHANGED")
	realG.FiresideTales_Speak()
	check("name stays after retargeting", not sent[#sent].text:find("Someoneelse", 1, true), sent[#sent].text)
	W.target = nil
	fire("PLAYER_TARGET_CHANGED")
	realG.FiresideTales_Speak()
	check("still speaks with no target once begun", #sent == n + 3)
	tellerBar():Hide()
end)

scenario("favorites, Tonight, filters", function()
	local a, b = ns.Stories[3], ns.Stories[4]
	slash("stories")
	local search
	for _, f in ipairs(allFrames) do if f._type == "EditBox" then search = search or f end end
	for _, story in ipairs({ a, b }) do
		search:SetText(story.title:lower())
		click(rowFor(story.title), "row")
		clickLabel("Add to Tonight", storyWindow())
	end
	search:SetText("")
	check("Tonight has two", #ns.CharData().tonight == 2)
	clickLabel("Favorite", storyWindow())
	check("favorited", ns.CharData().favorites[b.key])
	check("Favorited label shows", findButton("Favorited", storyWindow()))

	-- Tonight's first story, then Next story loads the second silently.
	click(rowFor(a.title), "tonight row")
	local n = #sent
	for _ = 1, #a.lines do realG.FiresideTales_Speak() end
	check("told every line", #sent == n + #a.lines)
	local nextButton = findButton("Next story", tellerBar())
	check("bar offers Next story", nextButton)
	local m = #sent
	click(nextButton, "Next story")
	check("Next story says nothing", #sent == m)
	realG.FiresideTales_Speak()
	check("next story's first line", sent[#sent].text == b.lines[1].text)
	click(findButton("Menu", tellerBar()), "Menu")

	-- Filters.
	clickLabel("Mood: All", storyWindow())
	clickLabel("Funny")
	for _, row in ipairs(visibleRows()) do
		check("mood filter only shows funny", row.story.mood == "funny", row.story.title)
	end
	check("Clear appears", findButton("Clear", storyWindow()))
	clickLabel("Clear", storyWindow())
	check("Clear resets the filter", findButton("Mood: All", storyWindow()))
	clickLabel("Show: All", storyWindow())
	clickLabel("Favorites")
	check("only the favorite shows", #visibleRows() == 1 and visibleRows()[1].story == b, #visibleRows())
	clickLabel("Clear", storyWindow())
	clickLabel("Show: All", storyWindow())
	clickLabel("Not told yet")
	for _, row in ipairs(visibleRows()) do
		check("Not told yet hides told stories", not ns.CharData().told[row.story.key], row.story.title)
	end
	clickLabel("Clear", storyWindow())
	clickLabel("From: All", storyWindow())
	clickLabel("Target")
	for _, row in ipairs(visibleRows()) do
		check("From: Target only shows targeted", row.story.needsTarget, row.story.title)
	end
	check("From: Target has rows", #visibleRows() > 0)
	clickLabel("Clear", storyWindow())
	clickLabel("Show: All", storyWindow())
	clickLabel("Clear Tonight's list")
	check("Tonight cleared", #ns.CharData().tonight == 0)
	storyWindow():Hide()
	tellerBar():Hide()
end)

scenario("zone section follows you", function()
	W.zone = "Westfall"
	fire("ZONE_CHANGED_NEW_AREA")
	slash("stories")
	local header = headerStartingWith("- Here in Westfall")
	-- Only exists if a starter story mentions Westfall; report rather than assume.
	stdPrint("   starter stories in 'Here in Westfall': " .. (header and plainText(header._text) or "none"))
	W.zone = ""
	fire("ZONE_CHANGED_NEW_AREA")
	storyWindow():Hide()
	slash("stories")
	check("empty zone text doesn't break the list", storyWindow():IsShown())
	storyWindow():Hide()
	W.zone = "Elwynn Forest"
end)

local function importWindow() return rawget(realG, "FiresideTalesImportFrame") end
-- Boxes are built in order: about, prompt, paste.
local function importBoxes()
	local boxes = {}
	for _, f in ipairs(allFrames) do
		if f._type == "EditBox" and f._parent and f._parent._parent and f._parent._parent._parent == importWindow() then
			boxes[#boxes + 1] = f
		end
	end
	return boxes
end
local function importBox() return importBoxes()[3] end
local function pasteResult()
	-- The result label is the font string that starts with "Added".
	for _, f in ipairs(allFrames) do
		if f._type == "FontString" and (f._text or ""):find("^Added ") then return f._text end
	end
end

local GOOD = table.concat({
	"EVERYONE: Road Stories",
	"TITLE: The Honest Toll",
	"MOOD: wise",
	"EMOTE: rolls an invisible coin across their knuckles.",
	"SAY: I met an old woman who kept a toll on a bridge no one had built.",
	"SAY: I paid her a copper anyway.",
	"EMOTE: closes their hand on the coin.",
}, "\n")

local function paste(text)
	local box = importBox()
	box._text = text -- Multi-line box; no OnTextChanged is set.
	clickLabel("Add", importWindow())
	return pasteResult()
end

scenario("Add Stories parses pasted text", function()
	slash("add")
	check("Add Stories window opens", importWindow():IsShown())
	local base = ns.Import.Count()

	local r = paste(GOOD)
	stdPrint("   clean paste: " .. tostring(r))
	check("clean paste adds one", ns.Import.Count() == base + 1, r)

	r = paste(GOOD)
	check("same title replaces", ns.Import.Count() == base + 1 and r:find("replaced 1", 1, true), r)

	r = paste("```\n" .. GOOD:gsub("Honest Toll", "Fenced Toll") .. "\n```")
	check("code fences are tolerated", r:find("Added 1", 1, true), r)

	r = paste((GOOD:gsub("Honest Toll", "Crlf Toll"):gsub("\n", "\r\n")))
	check("Windows line endings are tolerated", r:find("Added 1", 1, true), r)

	r = paste((GOOD:gsub("Honest Toll", "Capital Toll"):gsub("EMOTE: rolls", "EMOTE: Rolls")))
	check("capital emote is accepted", r:find("Added 1", 1, true), r)

	r = paste("TITLE: Orphan\nMOOD: wise\nSAY: a\nSAY: b\nEMOTE: c")
	check("story with no section is skipped", r:find("skipped 1", 1, true), r)

	r = paste("EVERYONE: X\nTITLE: Bad Mood\nMOOD: angry\nSAY: a\nSAY: b\nEMOTE: c")
	check("bad mood is skipped", r:find("skipped 1", 1, true), r)

	r = paste("EVERYONE: X\nTITLE: Two Lines\nMOOD: wise\nSAY: a\nEMOTE: c")
	check("too few lines is skipped", r:find("skipped 1", 1, true), r)

	r = paste("EVERYONE: X\nTITLE: Long\nMOOD: wise\nSAY: " .. ("a"):rep(251) .. "\nSAY: b\nEMOTE: c")
	check("too long is skipped", r:find("skipped 1", 1, true), r)

	r = paste("EVERYONE: X\nTITLE: Sneaky\nMOOD: wise\nSAY: hello {target}\nSAY: b\nEMOTE: c")
	check("{target} outside TARGET is skipped", r:find("skipped 1", 1, true), r)

	r = paste("TARGET:\nTITLE: No Name\nMOOD: wise\nSAY: hello\nSAY: b\nEMOTE: c")
	check("TARGET without {target} is skipped", r:find("skipped 1", 1, true), r)

	r = paste("TARGET:\nTITLE: To You\nMOOD: wise\nSAY: hello {target}\nSAY: b\nEMOTE: looks at {target}")
	check("valid TARGET is added", r:find("Added 1", 1, true), r)

	r = paste("RACE: Undead\nTITLE: Dead Tale\nMOOD: dark\nSAY: a\nSAY: b\nEMOTE: c")
	check("race alias is added", r:find("Added 1", 1, true), r)
	r = paste("RACE: Martian\nTITLE: Mars\nMOOD: dark\nSAY: a\nSAY: b\nEMOTE: c")
	check("unknown race is reported", r:find("unknown race", 1, true), r)
	r = paste("CLASS: warrior\nTITLE: My Class\nMOOD: dark\nSAY: a\nSAY: b\nEMOTE: c")
	check("class is added", r:find("Added 1", 1, true), r)
	r = paste("ZONE: Westfall\nTITLE: Zoned\nMOOD: dark\nSAY: a\nSAY: b\nEMOTE: c")
	check("zone is added", r:find("Added 1", 1, true), r)
	r = paste("CHARACTER: Testhero\nTITLE: Mine\nMOOD: dark\nSAY: a\nSAY: b\nEMOTE: c")
	check("character is added", r:find("Added 1", 1, true), r)

	-- What a person is likely to really paste: the whole AI reply.
	r = paste("Sure! Here are your stories:\n\n```\n" .. GOOD:gsub("Honest Toll", "Chatty Toll") .. "\n```\n\nLet me know if you want more!")
	stdPrint("   whole AI reply with chatter after the code block: " .. tostring(r))
	check("chatter after the code block doesn't lose the last story", r:find("Added 1", 1, true), r)

	r = paste("EVERYONE: X\n" .. "TITLE: Rule One\nMOOD: wise\nSAY: a\nSAY: b\nEMOTE: c\n\n---\n\nTITLE: Rule Two\nMOOD: wise\nSAY: a\nSAY: b\nEMOTE: c")
	stdPrint("   stories separated by a --- rule: " .. tostring(r))
	check("a --- divider between stories doesn't lose a story", r:find("Added 2", 1, true), r)

	r = paste("EVERYONE: X\nTITLE: **Bold Title**\nMOOD: wise\nSAY: a\nSAY: b\nEMOTE: c")
	stdPrint("   markdown in a title: " .. tostring(r))

	importWindow():Hide()
end)

scenario("pasted stories appear, can be told and deleted", function()
	slash("stories")
	local search
	for _, f in ipairs(allFrames) do if f._type == "EditBox" and f._parent == storyWindow() then search = f end end
	search:SetText("honest toll")
	local row = rowFor("The Honest Toll")
	check("pasted story is listed", row)
	click(row, "row")
	search:SetText("")
	check("Delete offered on a pasted story", findButton("Delete", storyWindow()))
	search:SetText("your exact face")
	click(rowFor("Your Exact Face"), "built-in row")
	search:SetText("")
	check("Delete NOT offered on a built-in", not findButton("Delete", storyWindow()))
	-- Pasted class/race/zone/character sections.
	local sources = {}
	clickLabel("From: All", storyWindow())
	for _, label in ipairs({ "Here", "Testhero", "Warrior", "Target", "Everyone", "Places" }) do
		sources[label] = findButton(label) ~= nil
		check("From offers " .. label, sources[label])
	end
	clickLabel("All")
	search:SetText("honest toll")
	click(rowFor("The Honest Toll"), "row")
	search:SetText("")
	local count = ns.Import.Count()
	clickLabel("Delete", storyWindow())
	check("first click only asks", ns.Import.Count() == count and findButton("Sure?", storyWindow()))
	clickLabel("Sure?", storyWindow())
	check("second click deletes", ns.Import.Count() == count - 1)
	storyWindow():Hide()
end)

scenario("game events don't pop anything up", function()
	check("no prompt frame exists", rawget(realG, "FiresideTalesFrame") == nil)
	check("no prompt lines loaded", ns.PromptLines == nil)
	local shownBefore = 0
	for _, f in ipairs(allFrames) do if f:IsShown() then shownBefore = shownBefore + 1 end end
	local n = #sent
	W.zone = "Duskwood"
	fire("ZONE_CHANGED_NEW_AREA")
	fire("QUEST_TURNED_IN", 42)
	fire("PLAYER_LEVEL_UP", 13)
	W.dead = true
	fire("PLAYER_DEAD")
	W.dead = false
	fire("PLAYER_UNGHOST")
	advance(5)
	local shownAfter = 0
	for _, f in ipairs(allFrames) do if f:IsShown() then shownAfter = shownAfter + 1 end end
	check("events show no new frames", shownAfter == shownBefore, shownAfter - shownBefore)
	realG.FiresideTales_Speak()
	check("Speak with no story open sends nothing", #sent == n)
	check("Skip binding is gone", rawget(realG, "FiresideTales_Skip") == nil)

	W.lockdown = true
	check("lockdown blocks sending", ns.SendLine("hello", "SAY") == false and #sent == n)
	check("lockdown tells you", chatOut[#chatOut]:find("blocking", 1, true))
	W.lockdown = false
	check("sends again after lockdown", ns.SendLine("hello", "SAY") == true and #sent == n + 1)
	W.zone = "Elwynn Forest"
end)

scenario("teller bar nearby-chat feed", function()
	local story = ns.Stories[5]
	slash("stories")
	local search
	for _, f in ipairs(allFrames) do if f._type == "EditBox" and f._parent == storyWindow() then search = f end end
	search:SetText(story.title:lower())
	click(rowFor(story.title), "row")
	search:SetText("")
	realG.FiresideTales_Speak()

	local function feedText()
		local out = {}
		for _, f in ipairs(allFrames) do
			if f._type == "FontString" and f._parent == tellerBar() and (f._text or ""):find(": ", 1, true) then
				out[#out + 1] = plainText(f._text)
			end
		end
		return table.concat(out, " / ")
	end

	local sounds = W.sounds or 0
	fire("CHAT_MSG_SAY", "Well told, friend", "Bjorn-Realm")
	check("nearby say shows", feedText():find("Bjorn: Well told", 1, true), feedText())
	check("no sound for ordinary chat", (W.sounds or 0) == sounds)
	fire("CHAT_MSG_SAY", "Hail, testhero!", "Bjorn-Realm")
	check("your name makes a sound", (W.sounds or 0) == sounds + 1)
	fire("CHAT_MSG_SAY", "my own line", "Testhero-Realm")
	check("your own chat is ignored", not feedText():find("my own line", 1, true))
	fire("CHAT_MSG_SAY", SECRET, "Bjorn-Realm")
	fire("CHAT_MSG_SAY", "x", SECRET)
	check("secret chat is ignored", not feedText():find(SECRET, 1, true))
	fire("CHAT_MSG_SAY", ("long "):rep(40), "Bjorn")
	check("long lines are shortened", feedText():find("...", 1, true))
	fire("CHAT_MSG_SAY", "look |cffff0000|Hitem:1|h[Sword]|h|r here", "Bjorn")
	check("links are flattened", feedText():find("look [Sword] here", 1, true), feedText())
	fire("CHAT_MSG_TEXT_EMOTE", "Bjorn waves at you.", "Bjorn")
	check("emote aimed at you makes a sound", (W.sounds or 0) >= sounds + 2)
	advance(46)
	check("feed clears after 45s", feedText() == "", feedText())
	tellerBar():Hide()
	fire("CHAT_MSG_SAY", "after close", "Bjorn")
	check("bar stops listening when closed", not feedText():find("after close", 1, true))
end)

scenario("/reload keeps saved data; slash leftovers", function()
	local db = realG.FiresideTalesDB
	local favorites = 0
	for _ in pairs(db.chars.Testhero.favorites) do favorites = favorites + 1 end
	local pasted = #db.imported
	W.zone = "Elwynn Forest"
	ns, loaded, skipped = boot(db)
	check("favorites survive", favorites > 0)
	check("pasted stories survive", ns.Import.Count() == pasted)
	check("told survives", next(ns.CharData().told) ~= nil)
	slash("stories")
	check("menu rebuilds with saved data", storyWindow():IsShown())
	local search
	for _, f in ipairs(allFrames) do if f._type == "EditBox" and f._parent == storyWindow() then search = f end end
	search:SetText("to you")
	local row = rowFor("To You")
	check("pasted targeted story still needs a target", row and row.story.needsTarget)
	storyWindow():Hide()
	slash("minimap")
	check("/tales minimap hides the icon", not rawget(realG, "FiresideTalesMinimapButton"):IsShown())
	slash("minimap")
	check("old prompt settings cleared", db.settings == nil and db.position == nil)
	slash("off")
	check("/tales off is no longer a command", chatOut[#chatOut]:find("/tales stories | add | fire | minimap | status", 1, true))
	slash("")
	check("bare /tales opens the menu", storyWindow():IsShown())
	slash("")
	check("bare /tales closes it again", not storyWindow():IsShown())
	slash("help")
	check("/tales help lists commands", chatOut[#chatOut]:find("/tales stories", 1, true))
end)

scenario("other races and classes, unknown tokens", function()
	for _, who in ipairs({
		{ { "Skyborne", "Skyborne" }, { "Druid", "DRUID" } },
		{ { "Forsaken", "Scourge" }, { "Warlock", "WARLOCK" } },
		{ { "Tauren", "Tauren" }, { "Shaman", "SHAMAN" } },
	}) do
		W.race, W.class, W.name = who[1], who[2], "Other"
		ns = boot(nil)
		slash("stories")
		check(who[1][1] .. " menu opens", storyWindow():IsShown())
		check(who[1][1] .. " has starter stories", ns.Story.Count() > 0)
		storyWindow():Hide()
	end
end)

scenario("Write Your Tales round trip", function()
	W.race, W.class, W.name, W.zone = { "Human", "Human" }, { "Warrior", "WARRIOR" }, "Bram", "Duskwood"
	ns = boot(nil)
	slash("stories")
	click(findButton("Write Your Tales", storyWindow()), "Write Your Tales button")
	check("window opens from the menu button", importWindow():IsShown())
	local boxes = importBoxes()
	check("three boxes", #boxes == 3, #boxes)
	local about, prompt = boxes[1], boxes[2]

	local text = prompt:GetText()
	check("prompt works with no description", text:find("Invent something fitting", 1, true))
	check("prompt has the name", text:find("First name: Bram", 1, true))
	check("prompt has race and class", text:find("Race and class: Human Warrior", 1, true))
	check("prompt has the zone", text:find("Where they are now: Duskwood", 1, true))
	check("prompt's format uses the character", text:find("CHARACTER: Bram", 1, true))
	check("prompt has no vertical bar", not text:find("|", 1, true))

	about:SetText("A retired soldier\nwho lost his brother at Stratholme. || 100% sure")
	text = prompt:GetText()
	check("description reaches the prompt on one line", text:find("A retired soldier who lost his brother at Stratholme.", 1, true), text:sub(1, 400))
	check("description can't add a vertical bar", not text:find("|", 1, true))
	check("description survives a percent sign", text:find("100% sure", 1, true))
	check("description is saved", ns.CharData().about:find("retired soldier", 1, true))

	local selected = false
	prompt.HighlightText = function() selected = true end
	prompt.SetFocus = function() end
	click(findButton("Select Prompt", importWindow()), "Select Prompt")
	check("Select Prompt highlights the text", selected)
	local before = prompt:GetText()
	prompt._text = "typed over"
	prompt._scripts.OnTextChanged(prompt, true)
	check("typing can't change the prompt", prompt:GetText() == before)

	-- The prompt's own example must be something the parser accepts as a shape.
	local reply = table.concat({
		"Here are five stories for Bram!", "", "```", "CHARACTER: Bram",
		"TITLE: Brother's Boots", "MOOD: heartfelt",
		"EMOTE: Pulls at the laces of one boot.", "SAY: These were my brother's.", "SAY: They still don't fit.",
		"", "---", "",
		"**TITLE:** The Last Muster", "**MOOD:** dark",
		"SAY: We mustered at dawn.", "EMOTE: taps two fingers on one knee.", "SAY: Eleven answered.",
		"```", "", "Let me know if you want more!",
	}, "\n")
	local result = paste(reply)
	stdPrint("   real-shaped AI reply: " .. tostring(result))
	check("whole AI reply adds both stories", result:find("Added 2, replaced 0, skipped 0", 1, true), result)
	check("bold labels are understood", ns.GetDB().imported[2].title == "The Last Muster", ns.GetDB().imported[2].title)
	check("no parser leftovers saved", ns.GetDB().imported[1].stray == nil and ns.GetDB().imported[2].unreadable == nil)

	-- Chatter with no code block at all, and a line that went missing mid-story.
	result = paste("CHARACTER: Bram\nTITLE: Plain\nMOOD: wise\nSAY: a\nSAY: b\nEMOTE: c\n\nHope you like it!")
	check("trailing chatter without a code block is ignored", result:find("Added 1", 1, true), result)
	result = paste("CHARACTER: Bram\nTITLE: Wrapped\nMOOD: wise\nSAY: a\nthis line wrapped\nSAY: b\nEMOTE: c")
	check("text lost mid-story still skips it with a reason", result:find("skipped 1", 1, true) and result:find("this line wrapped", 1, true), result)

	-- The menu shows them as this character's own.
	importWindow():Hide()
	if storyWindow():IsShown() then storyWindow():Hide() end
	slash("stories")
	check("own section is labeled and open", headerStartingWith("- Bram's Tales"), "no header")
	check("own stories are listed", rowFor("The Last Muster"))
	local story = rowFor("The Last Muster").story
	check("saved key doesn't use the label", story.key == "mine/Bram/The Last Muster", story.key)
	click(rowFor("The Last Muster"), "own story")
	local n = #sent
	realG.FiresideTales_Speak()
	check("own story can be told", #sent == n + 1 and sent[#sent].text == "We mustered at dawn.")
	tellerBar():Hide()
	storyWindow():Hide()

	-- Telling mine from built-in, and a story that mentions the zone you're in.
	slash("add")
	paste("CHARACTER: Bram\nTITLE: Darkshire Night\nMOOD: spooky\nSAY: We camped outside Darkshire.\nSAY: Nobody slept.\nEMOTE: stares at the fire.")
	paste("EVERYONE: My Own Theme\nTITLE: Shared By Me\nMOOD: wise\nSAY: a\nSAY: b\nEMOTE: c")
	importWindow():Hide()
	slash("stories")
	local function countLabel()
		for _, f in ipairs(allFrames) do
			if f._type == "FontString" and (f._text or ""):find(" stories$") then return f._text end
		end
	end
	local function rowsNamed(title)
		local n = 0
		for _, f in ipairs(visibleRows()) do if f.story.title == title then n = n + 1 end end
		return n
	end
	check("own story in this zone is listed in Here and in own section", rowsNamed("Darkshire Night") == 2, rowsNamed("Darkshire Night"))
	check("Here section exists", headerStartingWith("- Here in Duskwood"))
	local shown, total = countLabel():match("^(%d+) of (%d+) stories$")
	check("a story listed twice counts once", shown == total, countLabel())
	check("added story is tinted as yours", rowFor("The Last Muster")._text:find("b9e6c9", 1, true))
	check("rows show telling time, not line count", rowFor("The Last Muster").count:GetText():find("^%d+s$"), rowFor("The Last Muster").count:GetText())
	click(rowFor("The Last Muster"), "own story")
	local readerHasTag = false
	for _, f in ipairs(allFrames) do
		if f._type == "FontString" and (f._text or ""):find("added by you", 1, true) then readerHasTag = true end
	end
	check("reader says added by you", readerHasTag)
	clickLabel("Show: All", storyWindow())
	clickLabel("Added by me")
	check("Show button shows the filter", findButton("Show: Added by me", storyWindow()))
	local listed = visibleRows()
	check("Added by me lists stories", #listed > 0)
	local sawShared = false
	for _, row in ipairs(listed) do
		check("Added by me only lists added stories", row.story.kind ~= nil, row.story.title)
		if row.story.title == "Shared By Me" then sawShared = true end
	end
	check("Added by me includes everyone-stories I pasted", sawShared)
	check("filter count is right", countLabel():find("^5 of", 1) ~= nil, countLabel())
	clickLabel("Clear", storyWindow())
	local search
	for _, f in ipairs(allFrames) do if f._type == "EditBox" and f._parent == storyWindow() then search = f end end
	search:SetText("your exact face")
	click(rowFor("Your Exact Face"), "built-in row")
	check("built-in story isn't tinted as yours", not rowFor("Your Exact Face")._text:find("b9e6c9", 1, true))
	check("a reused row drops the marker and star", not rowFor("Your Exact Face").star:IsShown())
	readerHasTag = false
	for _, f in ipairs(allFrames) do
		if f._type == "FontString" and (f._text or ""):find("added by you", 1, true) then readerHasTag = true end
	end
	check("reader doesn't claim a built-in story", not readerHasTag)
	search:SetText("")
	storyWindow():Hide()

	-- Reload keeps the description, and another character doesn't see the stories.
	local db = realG.FiresideTalesDB
	ns = boot(db)
	check("description survives a reload", (ns.CharData().about or ""):find("retired soldier", 1, true))
	slash("add")
	check("reopened box shows the description", importBoxes()[1]:GetText():find("retired soldier", 1, true))
	importWindow():Hide()
	W.name = "Someone"
	ns = boot(db)
	slash("stories")
	check("another character doesn't get them", not headerStartingWith("- Bram's Tales") and not rowFor("The Last Muster"))
	check("another character's description is blank", ns.CharData().about == nil)
	storyWindow():Hide()
end)

if PASTE_FILE then
	scenario("user test paste", function()
		W.race, W.class, W.name, W.zone = { "Human", "Human" }, { "Warrior", "WARRIOR" }, "Bram", "Elwynn Forest"
		ns = boot(nil)
		slash("add")
		local handle = io.open(PASTE_FILE)
		local text = handle:read("*a")
		handle:close()
		stdPrint("   first paste: " .. tostring(paste(text)))
		for _, story in ipairs(realG.FiresideTalesDB.imported) do
			stdPrint(("   saved [%s/%s] %s; first emote: %s"):format(story.kind, tostring(story.listKey or story.theme), story.title, story.lines[1].text))
		end
		importBox()._text = text
		stdPrint("   second paste: " .. tostring(paste(text)))
		importWindow():Hide()
		slash("status")
		stdPrint("   " .. plainText(chatOut[#chatOut]))
	end)
end

scenario("interface sounds", function()
	local function heard()
		local log = table.concat(W.soundLog or {}, ",")
		W.soundLog = {}
		return log
	end
	heard()
	local story = ns.Stories[2]
	slash("stories")
	check("first open plays only the open sound", heard() == "IG_SPELLBOOK_OPEN", "")
	local search
	for _, f in ipairs(allFrames) do if f._type == "EditBox" then search = search or f end end
	search:SetText(story.title:lower())
	heard()
	click(rowFor(story.title), "row")
	check("picking a story turns the page", heard() == "IG_ABILITY_PAGE_TURN", "")
	clickLabel("Favorite", storyWindow())
	check("favoriting ticks on", heard() == "IG_MAINMENU_OPTION_CHECKBOX_ON", "")
	clickLabel("Favorited", storyWindow())
	check("unfavoriting ticks off", heard() == "IG_MAINMENU_OPTION_CHECKBOX_OFF", "")
	clickLabel("Add to Tonight", storyWindow())
	check("adding to tonight ticks on", heard() == "IG_MAINMENU_OPTION_CHECKBOX_ON", "")
	clickLabel("Clear", storyWindow())
	check("clearing filters clicks", heard() == "IG_MAINMENU_OPTION", "")
	clickLabel("Mood: All", storyWindow())
	check("opening a filter clicks", heard() == "IG_MAINMENU_OPTION", "")
	clickLabel("Funny")
	check("choosing a filter clicks", heard() == "IG_MAINMENU_OPTION", "")
	clickLabel("Clear", storyWindow())
	heard()
	local header = headerStartingWith("- ")
	if header then
		click(header, "header")
		check("collapsing a section ticks off", heard() == "IG_MAINMENU_OPTION_CHECKBOX_OFF", "")
	end
	storyWindow():Hide()
	check("closing plays only the close sound", heard() == "IG_SPELLBOOK_CLOSE", "")
	slash("add")
	check("Write Your Tales' first open plays only the open sound", heard() == "IG_SPELLBOOK_OPEN", "")
	slash("add")
	check("Write Your Tales closes with the close sound", heard() == "IG_SPELLBOOK_CLOSE", "")
	realG.SOUNDKIT.IG_ABILITY_PAGE_TURN = nil
	local ok = pcall(ns.PlayUISound, "IG_ABILITY_PAGE_TURN")
	check("a sound this client lacks stays silent", ok and heard() == "", "")
	realG.SOUNDKIT.IG_ABILITY_PAGE_TURN = 836
end)

-- Every title in the addon, to recognize which story is chosen.
local function allStories()
	local out = {}
	local function addList(stories) for _, s in ipairs(stories or {}) do out[#out + 1] = s end end
	addList(ns.Stories)
	addList(ns.TargetStories)
	for _, group in ipairs({ ns.RaceStories, ns.ClassStories, ns.ZoneStories, ns.FestivalStories, ns.CharacterStories or {} }) do
		for _, stories in pairs(group) do addList(stories) end
	end
	for _, legend in ipairs(ns.Legends or {}) do addList(legend.parts) end
	for _, week in ipairs(ns.CommunityWeeks or {}) do addList(week.stories) end
	for _, s in ipairs(realG.FiresideTalesDB.imported) do out[#out + 1] = s end
	return out
end

local function underFrame(f, root)
	while f do
		if f == root then return true end
		f = f._parent
	end
	return false
end

-- The title the reader shows, or nil.
local function readerTitle()
	local titles = {}
	for _, s in ipairs(allStories()) do titles[s.title] = s end
	for _, f in ipairs(allFrames) do
		if f._type == "FontString" and underFrame(f, storyWindow()) and titles[f._text or ""] then
			return f._text, titles[f._text]
		end
	end
end

local function barTexts()
	local out = {}
	for _, f in ipairs(allFrames) do
		if f._type == "FontString" and tellerBar() and underFrame(f, tellerBar()) then
			out[#out + 1] = plainText(f._text)
		end
	end
	return table.concat(out, " / ")
end

local function isAboutElwynn(story)
	for _, s in ipairs(ns.ZoneStories["Elwynn Forest"] or {}) do
		if s == story then return true end
	end
	local text = story.title:lower()
	for _, line in ipairs(story.lines) do text = text .. " " .. line.text:lower() end
	if text:find("elwynn", 1, true) then return true end
	for _, term in ipairs(ns.ZoneTerms["Elwynn Forest"] or {}) do
		if text:find(term, 1, true) then return true end
	end
	return false
end

scenario("Tell a Tale picks a fitting story and moves on", function()
	W.zone = "Elwynn Forest"
	ns, loaded, skipped = boot({})
	slash("stories")
	check("the menu has a Tell a Tale button", findButton("Tell a Tale", storyWindow()))
	check("the empty reader mentions it", (function()
		for _, f in ipairs(allFrames) do
			if f._type == "FontString" and (f._text or ""):find("Tell a Tale", 1, true) then return true end
		end
	end)())
	local count
	for _, f in ipairs(allFrames) do
		if f._type == "FontString" and plainText(f._text):find("^%d+ of %d+ stories$") then count = f end
	end
	check("story count still shown", count ~= nil)

	clickLabel("Tell a Tale", storyWindow())
	local title, story = readerTitle()
	check("a story is chosen", title ~= nil)
	check("the first pick is about where you are", story and isAboutElwynn(story), title)
	check("Tell is ready", not findButton("Tell", storyWindow())._disabled)
	local meta = false
	for _, f in ipairs(allFrames) do
		if f._type == "FontString" and plainText(f._text):find("about %d+ seconds") then meta = true end
	end
	check("the reader shows how long it takes", meta)

	local seen, repeats, targeted = { [title] = true }, 0, 0
	local targetTitles = {}
	for _, s in ipairs(ns.TargetStories) do targetTitles[s.title] = true end
	for _ = 1, 60 do
		clickLabel("Tell a Tale", storyWindow())
		local t = readerTitle()
		if seen[t] then repeats = repeats + 1 end
		if targetTitles[t] then targeted = targeted + 1 end
		seen[t] = true
	end
	check("sixty more picks never repeat", repeats == 0, repeats)
	check("never a story that needs a target", targeted == 0, targeted)

	local _, chosen = readerTitle()
	local n = #sent
	realG.FiresideTales_Speak()
	check("Speak tells the chosen story", sent[n + 1] and sent[n + 1].text == chosen.lines[1].text)
	click(findButton("Menu", tellerBar()), "Menu")
	clickLabel("Tell a Tale", storyWindow())
	local _, fresh = readerTitle()
	check("Tell a Tale works partway through a story", fresh ~= chosen)
	storyWindow():Hide()
	check("a chosen but unbegun story doesn't bring the bar back", not tellerBar():IsShown())

	-- Once everything is told, it still picks something.
	for _, s in ipairs(allStories()) do if s.key then ns.CharData().told[s.key] = 1 end end
	slash("stories")
	clickLabel("Tell a Tale", storyWindow())
	check("still picks when all are told", readerTitle() ~= nil)
	storyWindow():Hide()
end)

scenario("side tabs: rumors and legends have their own, legends go part by part", function()
	W.zone = "Duskwood"
	ns, loaded, skipped = boot({})
	slash("stories")
	local tabs = {}
	for _, f in ipairs(allFrames) do
		if rawget(f, "selected") and rawget(f, "key") then tabs[f.key] = f end
	end
	check("four side tabs", tabs.mine and tabs.stories and tabs.legends and tabs.rumors)
	local search
	for _, f in ipairs(allFrames) do if f._type == "EditBox" then search = search or f end end

	search:SetText("thirteen bells")
	check("rumors aren't on the Stories tab", rowFor("Thirteen Bells") == nil)
	click(tabs.rumors, "Rumors tab")
	check("the Rumors tab has them", rowFor("Thirteen Bells") ~= nil)
	check("From is hidden off the Stories tab", findButton("From: All", storyWindow()) == nil)
	search:SetText("darkshire")
	check("a rumor about this zone comes first", headerStartingWith("- Here in Duskwood") ~= nil)
	search:SetText("")

	click(tabs.legends, "Legends tab")
	local first = rowFor("Part 1: A Name in the Dark")
	check("the Legends tab lists the parts in order", first and rowFor("Part 4: Manor Mistmantle"))
	click(first, "Part 1")
	local lines, n = #first.story.lines, #sent
	for _ = 1, lines do realG.FiresideTales_Speak() end
	check("Part 1 is told", #sent == n + lines)
	check("the bar offers the next part", findButton("Next part") ~= nil)
	realG.FiresideTales_Speak()
	local title = readerTitle()
	check("Next part loads Part 2 without speaking", #sent == n + lines and title == "Part 2: The Tutor", title)
	realG.FiresideTales_Speak()
	check("Part 2 begins", sent[#sent].text == ns.Legends[1].parts[2].lines[1].text)

	click(findButton("Menu", tellerBar()), "Menu")
	local legendPicks = 0
	for _ = 1, 40 do
		clickLabel("Tell a Tale", storyWindow())
		local _, story = readerTitle()
		if story and story.legend then legendPicks = legendPicks + 1 end
	end
	check("Tell a Tale never hands you a legend part", legendPicks == 0, legendPicks)

	click(tabs.stories, "Stories tab")
	search:SetText("stalvan")
	check("legends aren't on the Stories tab", rowFor("Part 1: A Name in the Dark") == nil)
	search:SetText("")
	check("From is back on the Stories tab", findButton("From: All", storyWindow()) ~= nil)

	click(tabs.mine, "Your Tales tab")
	local note = false
	for _, f in ipairs(allFrames) do
		if f._type == "FontString" and effectiveShown(f) and (f._text or ""):find("No tales of your own yet", 1, true) then note = true end
	end
	check("Your Tales says how to add some", note)
	storyWindow():Hide()
end)

scenario("openers and closers frame a story, once each", function()
	W.zone = "Elwynn Forest"
	ns, loaded, skipped = boot({})
	local count = 0
	for _, groups in ipairs({ ns.Openers, ns.Closers }) do
		for key, lines in pairs(groups) do
			for n, line in ipairs(lines) do
				count = count + 1
				local id = key .. ":" .. n
				check(id .. " kind", ns.ChatType[line.kind], line.kind)
				check(id .. " fits chat", #line.text <= 250, #line.text)
				check(id .. " safe text", not line.text:find("[|{}\128-\255\"]"), line.text)
				if line.kind == "emote" then check(id .. " lowercase emote", not line.text:find("^%u"), line.text) end
			end
		end
	end
	check("openers for any time and night", #ns.Openers.any >= 8 and #ns.Openers.night >= 3)
	for _, mood in ipairs({ "funny", "heartfelt", "dark", "action", "spooky", "wise" }) do
		check("closers for " .. mood, ns.Closers[mood] and #ns.Closers[mood] >= 2)
	end
	stdPrint(("   %d opener and closer lines"):format(count))

	local story = ns.Stories[1]
	local closerTexts = {}
	for _, key in ipairs({ "any", story.mood, "night" }) do
		for _, line in ipairs(ns.Closers[key] or {}) do closerTexts[line.text] = true end
	end
	local openerTexts = {}
	for _, key in ipairs({ "any", "night" }) do
		for _, line in ipairs(ns.Openers[key]) do openerTexts[line.text] = true end
	end
	slash("stories")
	local search
	for _, f in ipairs(allFrames) do if f._type == "EditBox" then search = search or f end end
	search:SetText(story.title:lower())
	click(rowFor(story.title), "story row")
	search:SetText("")
	local n0 = #sent
	check("the menu has no Opener of its own", findButton("Opener", storyWindow()) == nil)
	clickLabel("Tell", storyWindow())
	check("Tell opens the story on the teller bar without saying anything", tellerBar():IsShown() and not storyWindow():IsShown() and #sent == n0)
	check("Opener offered before the first line", findButton("Opener", tellerBar()) ~= nil)
	local n = #sent
	clickLabel("Opener", tellerBar())
	check("Opener says one line from the openers", #sent == n + 1 and openerTexts[sent[#sent].text], sent[#sent] and sent[#sent].text)
	check("the story hasn't started", findButton("Opener") == nil and #sent == n + 1)
	check("and the teller bar stays", tellerBar():IsShown() and not storyWindow():IsShown())
	for _ = 1, #story.lines do realG.FiresideTales_Speak() end
	check("the story is told after the opener", #sent == n + 1 + #story.lines)
	check("Closer offered at the end", findButton("Closer", tellerBar()) ~= nil)
	click(findButton("Closer", tellerBar()), "Closer")
	check("Closer says a fitting line", #sent == n + 2 + #story.lines and closerTexts[sent[#sent].text], sent[#sent].text)
	check("only one closer per story", findButton("Closer") == nil)

	-- Between a legend's parts, the next part is offered instead of a closer.
	ns.Story.Toggle()
	local tabs = {}
	for _, f in ipairs(allFrames) do
		if rawget(f, "selected") and rawget(f, "key") then tabs[f.key] = f end
	end
	click(tabs.legends, "Legends tab")
	local first = rowFor(ns.Legends[1].parts[1].title)
	click(first, "Part 1")
	for _ = 1, #first.story.lines do realG.FiresideTales_Speak() end
	check("no closer between parts", findButton("Closer") == nil and findButton("Next part") ~= nil)
	storyWindow():Hide()
	tellerBar():Hide()
end)

scenario("campfire offers a tale once, gently", function()
	W.zone = "Elwynn Forest"
	W.fire, W.moving, W.combat = false, false, false
	ns, loaded, skipped = boot({})
	local function wait(seconds) for _ = 1, seconds do advance(1) end end
	local function light() W.fire = true fire("UNIT_AURA", "player") end
	-- Leaving only counts once the buff has stayed gone a few seconds.
	local function douse() W.fire = false fire("UNIT_AURA", "player") wait(4) end
	local function offered() return tellerBar() ~= nil and tellerBar():IsShown() end

	local sentBefore = #sent
	fire("UNIT_AURA", "target")
	light()
	wait(2)
	check("no offer the moment the fire appears", not offered())
	wait(3)
	check("offers after standing still a few seconds", offered())
	check("no line sent by offering", #sent == sentBefore)
	check("the bar says why it's here", barTexts():find("By the fire. Tell a tale?", 1, true), barTexts())
	check("the bar says how long the story is", barTexts():find("about %d+ sec"), barTexts())
	local another = findButton("Another", tellerBar())
	check("Another is offered", another ~= nil)
	local before = barTexts()
	click(another, "Another")
	check("Another picks a different story", barTexts() ~= before)
	wait(29)
	check("Another restarts the wait", offered())
	wait(2)
	check("an offer nobody takes goes away", not offered())

	fire("UNIT_AURA", "player")
	wait(10)
	check("the same fire doesn't ask twice", not offered())
	douse()
	light()
	wait(10)
	check("a new fire soon after stays quiet", not offered())
	-- About a minute has passed since the offer; this brings it near 5.
	advance(220)
	douse()
	light()
	wait(6)
	check("still quiet under 5 minutes", not offered())

	advance(30)
	douse()
	light()
	W.moving = true
	wait(10)
	check("no offer while you're moving", not offered())
	W.moving = false
	wait(5)
	check("offers once you stop", offered())
	douse()
	check("walking away takes the offer with it", not offered())

	advance(601)
	light()
	wait(5)
	check("offered at the next fire", offered())
	local n = #sent
	realG.FiresideTales_Speak()
	check("Speak tells the offered story", #sent == n + 1)
	check("the hint goes once telling starts", not barTexts():find("By the fire", 1, true))
	check("Another goes once telling starts", findButton("Another", tellerBar()) == nil)
	wait(40)
	check("a story you're telling doesn't time out", offered())
	douse()
	check("leaving the fire mid-story keeps the bar", offered())
	tellerBar():Hide()

	advance(601)
	light()
	wait(5)
	check("no offer with a story half told", not offered())
	douse()

	-- Finish that story so the next checks start clean.
	slash("stories")
	clickLabel("Restart", storyWindow())
	storyWindow():Hide()

	advance(601)
	W.combat = true
	light()
	wait(8)
	check("no offer in combat", not offered())
	W.combat = false
	wait(2)
	check("offers once combat ends", offered())
	douse()

	advance(601)
	slash("stories")
	light()
	wait(6)
	check("no offer with the menu open", storyWindow():IsShown() and not offered())
	storyWindow():Hide()
	wait(6)
	check("closing the menu doesn't bring it after all", not offered())
	douse()

	advance(601)
	slash("fire")
	check("/tales fire turns offers off", realG.FiresideTalesDB.fireOffers == false and chatOut[#chatOut]:find("no more", 1, true))
	light()
	wait(6)
	check("no offer while off", not offered())
	douse()
	slash("fire")
	check("/tales fire turns them back on", realG.FiresideTalesDB.fireOffers == true)
	light()
	wait(5)
	check("offers again once on", offered())
	slash("fire")
	check("turning off clears a showing offer", not offered())
	slash("fire")
	douse()

	W.fire = false
	W.fireByName = "Cozy Fire"
	advance(601)
	fire("UNIT_AURA", "player")
	wait(5)
	check("finds the fire by name too", offered())
	W.fireByName = false
	fire("UNIT_AURA", "player")
	wait(4)
	check("and notices it go", not offered())

	-- Forever's campsite buff, which renews each minute and can blink off.
	W.fireByName = "Welcoming Campfire"
	advance(601)
	fire("UNIT_AURA", "player")
	wait(5)
	check("offers at a Forever campsite", offered())
	W.fireByName = false
	fire("UNIT_AURA", "player")
	advance(1)
	check("a blink as the buff renews keeps the offer", offered())
	W.fireByName = "Welcoming Campfire"
	fire("UNIT_AURA", "player")
	wait(5)
	check("and it's still the same fire", offered())
	W.fireByName = false
	fire("UNIT_AURA", "player")
	check("leaving doesn't end it at once", offered())
	wait(4)
	check("but does once the buff stays gone", not offered())
	fire("UNIT_AURA", SECRET)
	check("a secret unit is ignored", true)
end)

local function on(y, m, d)
	local t = os.date("*t", os.time({ year = y, month = m, day = d, hour = 12 }))
	return { year = y, month = m, monthDay = d, weekday = t.wday }
end

local function activeNames()
	local names = {}
	for _, f in ipairs(ns.Season.Active()) do names[#names + 1] = f.name end
	return table.concat(names, ",")
end

local function festivalOf(story)
	for name, list in pairs(ns.FestivalStories) do
		for _, s in ipairs(list) do if s == story then return name end end
	end
end

scenario("festivals by date, by calendar, and the hour", function()
	W.zone, W.hour, W.calendar = "Elwynn Forest", 12, nil
	W.day = on(2026, 11, 7)
	ns, loaded, skipped = boot({})
	check("no festival on November 7", activeNames() == "", activeNames())

	-- The Darkmoon Faire dates the Forever client's calendar lists.
	for _, case in ipairs({
		{ on(2026, 11, 9), true }, { on(2026, 11, 15), true }, { on(2026, 11, 8), false }, { on(2026, 11, 16), false },
		{ on(2026, 12, 7), true }, { on(2026, 12, 6), false }, { on(2027, 1, 4), true }, { on(2027, 1, 3), false },
		{ on(2027, 2, 8), true }, { on(2027, 2, 7), false },
	}) do
		W.day = case[1]
		local d = ("%d-%02d-%02d"):format(W.day.year, W.day.month, W.day.monthDay)
		check("Darkmoon Faire on " .. d .. " is " .. tostring(case[2]), (activeNames():find("Darkmoon", 1, true) ~= nil) == case[2], activeNames())
	end
	for _, case in ipairs({
		{ on(2026, 12, 20), "Winter Veil" }, { on(2027, 1, 2), "Winter Veil" }, { on(2027, 1, 3), "" },
		{ on(2026, 10, 31), "Hallow's End" }, { on(2026, 6, 25), "Midsummer Fire Festival" },
	}) do
		W.day = case[1]
		check(case[2] .. " on " .. W.day.month .. "/" .. W.day.monthDay, activeNames() == case[2], activeNames())
	end

	-- While the faire is on, its stories lead the list and Tell a Tale.
	W.day = on(2026, 11, 10)
	slash("stories")
	check("a section for the faire is open at the top", headerStartingWith("- On now: Darkmoon Faire") ~= nil)
	check("its stories are listed", rowFor("The Lucky Frog") ~= nil)
	clickLabel("Tell a Tale", storyWindow())
	local _, story = readerTitle()
	check("Tell a Tale picks a faire story first", festivalOf(story) == "Darkmoon Faire", story and story.title)
	storyWindow():Hide()

	W.fire = true
	fire("UNIT_AURA", "player")
	for _ = 1, 5 do advance(1) end
	check("the fire mentions the faire", barTexts():find("The Darkmoon Faire is in town. Tell a tale?", 1, true), barTexts())
	tellerBar():Hide()
	W.fire = false
	fire("UNIT_AURA", "player")

	-- Out of season, festival stories stay in their own section and aren't picked.
	W.day = on(2026, 11, 20)
	ns.Story.StoriesChanged()
	slash("stories")
	check("no festival section on top out of season", headerStartingWith("- On now:") == nil)
	local picked = 0
	for _ = 1, 40 do
		clickLabel("Tell a Tale", storyWindow())
		local _, s = readerTitle()
		if festivalOf(s) then picked = picked + 1 end
	end
	check("no festival story picked out of season", picked == 0, picked)

	-- At night, the grim ones come first among stories of where you are.
	-- Elwynn has none of its own, so this is in Duskwood.
	W.hour, W.zone = 23, "Duskwood"
	ns.Story.StoriesChanged()
	clickLabel("Tell a Tale", storyWindow())
	local _, night = readerTitle()
	check("a night pick is spooky or dark", night and (night.mood == "spooky" or night.mood == "dark"), night and night.mood)
	W.hour, W.zone = 10, "Elwynn Forest"
	ns.Story.StoriesChanged()
	local grimByDay = 0
	for _ = 1, 10 do
		clickLabel("Tell a Tale", storyWindow())
		local _, s = readerTitle()
		if s.mood == "spooky" or s.mood == "dark" then grimByDay = grimByDay + 1 end
	end
	check("daytime picks are gentler", grimByDay == 0, grimByDay)
	storyWindow():Hide()

	W.hour = 23
	advance(601)
	W.fire = true
	fire("UNIT_AURA", "player")
	for _ = 1, 5 do advance(1) end
	check("the fire says it's night", barTexts():find("A dark night by the fire", 1, true), barTexts())
	tellerBar():Hide()
	W.fire, W.hour = false, 12
	fire("UNIT_AURA", "player")

	-- With a calendar that lists holidays, it goes by the calendar.
	W.day = on(2026, 11, 10)
	W.calendar = { [10] = { "Lunar Festival" }, [20] = { "Darkmoon Faire" } }
	ns, loaded, skipped = boot({})
	check("the calendar is opened at login", W.calendarOpened)
	check("before it loads, dates are used", activeNames() == "Darkmoon Faire", activeNames())
	fire("CALENDAR_UPDATE_EVENT_LIST")
	check("once loaded, the calendar wins", activeNames() == "Lunar Festival", activeNames())
	W.calendar = { [3] = { "Something Else" } }
	ns, loaded, skipped = boot({})
	fire("CALENDAR_UPDATE_EVENT_LIST")
	check("a calendar with other holidays shows none of ours", activeNames() == "", activeNames())
	W.calendar = {}
	ns, loaded, skipped = boot({})
	fire("CALENDAR_UPDATE_EVENT_LIST")
	check("an empty calendar falls back to dates", activeNames() == "Darkmoon Faire", activeNames())
	W.calendar, W.day = nil, on(2026, 11, 7)
end)

scenario("Write Your Tales reads a Total RP 3 profile", function()
	W.race, W.class, W.name, W.zone = { "Human", "Human" }, { "Warlock", "WARLOCK" }, "Bram", "Elwynn Forest"
	ns, loaded, skipped = boot({})
	local function prompt() return importBoxes()[2]._text or "" end
	local function label()
		for _, f in ipairs(allFrames) do
			if f._type == "FontString" and underFrame(f, importWindow()) and (f._text or ""):find("^1%. ") then return f._text end
		end
	end

	slash("add")
	check("without Total RP 3 the prompt is as before", prompt():find("About them: Not much yet", 1, true) and not prompt():find("roleplay profile", 1, true))
	check("without it the label asks who they are", (label() or ""):find("Who is Bram?", 1, true), label())
	slash("add")

	-- A made-up character's profile, shaped the way Total RP 3 saves it.
	local profile = {
		profileName = "Bram Ashvale",
		player = {
			characteristics = {
				FN = "Bram", LN = "Ashvale", FT = "Ferryman's son, keeper of fireside tales", RA = "Human", CL = "Warlock",
				AG = "31", EC = "Dark brown", HE = "Short and broad", WE = "Sturdy, with a ferryman's arms",
				BP = "Lakeshire", RE = "Darkshire, Duskwood", MI = {}, PS = {},
			},
			character = { CU = "Sitting by the fire, mending a net nobody needs.", CO = "Always happy to RP." },
			about = {
				TE = 1,
				T1 = { TX = "{h2}The Ferryman's Son{/h2}\nBram grew up poling a flat ferry across Lake Everstill, and could tell the weather from the color of the water.\n\nOne foggy night a passenger paid him in a coin that was warm to the touch, and he has kept it in his boot ever since.\n\n{h2}At the Fire{/h2}\nHe says he studies old river charms. He talks to the fire when he thinks no one is listening, and sometimes it answers in sparks.\n\nHe is patient, stubborn, and still sends his sister a letter every month telling her he works at a mill. She has never once believed him, and writes back anyway, mostly about the weather and her goats.\n\nHe trades in stories the way his father traded in crossings: one at a time, paid fairly, and never rushed. Sit with him and he will ferry you across one." },
				T2 = {}, T3 = { PH = {}, PS = {}, HI = {} },
			},
		},
	}
	realG.TRP3_API = { profile = { getPlayerCurrentProfile = function() return profile end } }
	local line = ns.Import.RoleplayProfile()
	stdPrint("   profile line: " .. tostring(line))
	check("reads the profile", line ~= nil)
	for _, want in ipairs({ "Name: Bram Ashvale", "Title: Ferryman's son", "Age: 31", "Eyes: Dark brown", "Born in: Lakeshire",
		"Lives in: Darkshire, Duskwood.", "Right now: Sitting by the fire", "Their story: The Ferryman's Son. Bram grew up",
		"the water. One foggy night", "since. At the Fire. He says" }) do
		check("profile includes " .. want, line and line:find(want, 1, true), want)
	end
	check("formatting tags are gone", line and not line:find("[{}]"))
	check("no line breaks or bars", line and not line:find("[\n|]"))
	check("the out-of-character note stays out", line and not line:find("happy to RP", 1, true))
	check("the backstory is trimmed", line and #line < 1100 and line:find("%.%.%.$"), line and #line)

	slash("add")
	check("the prompt carries the profile", prompt():find("From their roleplay profile: Name: Bram Ashvale", 1, true))
	check("and doesn't call them a blank slate", not prompt():find("Not much yet", 1, true))
	check("the label says it's included", (label() or ""):find("Total RP 3 profile is in the prompt", 1, true), label())
	importBoxes()[1]:SetText("Speaks softly, and hums when nervous.")
	check("your own words still go in too", prompt():find("About them: Speaks softly", 1, true) and prompt():find("roleplay profile", 1, true))
	importBoxes()[1]:SetText("")
	slash("add")

	-- The three-part About layout, and a profile with nothing filled in.
	profile.player.about = { TE = 3, T3 = { PH = { TX = "Ink on his fingers." }, PS = { TX = "Gentle." }, HI = { TX = "Born under an oak." } } }
	line = ns.Import.RoleplayProfile()
	check("three-part About is read", line and line:find("Their story: Ink on his fingers. Gentle. Born under an oak", 1, true), line)
	profile.player.about = { TE = 2, T2 = { { TX = "First frame." }, { TX = "Second frame." } } }
	line = ns.Import.RoleplayProfile()
	check("framed About is read", line and line:find("First frame. Second frame", 1, true), line)
	realG.TRP3_API = { profile = { getPlayerCurrentProfile = function() return { player = { characteristics = { FN = "Bram" } } } end } }
	check("a profile with only a name is skipped", ns.Import.RoleplayProfile() == nil)
	realG.TRP3_API = { profile = { getPlayerCurrentProfile = function() error("not ready") end } }
	check("a Total RP 3 error is ignored", ns.Import.RoleplayProfile() == nil)
	slash("add")
	check("and Write Your Tales still opens", importWindow():IsShown())
	slash("add")
	realG.TRP3_API = nil
end)

scenario("community tab: this week's shared stories, credited", function()
	W.name = "Testhero"
	ns, loaded, skipped = boot({})
	check("Community.lua loads", (function() for _, file in ipairs(loaded) do if file == "Community.lua" then return true end end end)())
	check("the week starts on Tuesday", ns.CommunityWeekStart() == "2027-01-12", ns.CommunityWeekStart())
	check("a Tuesday is its own week", ns.CommunityWeekStart(1800000000 - 3 * 86400) == "2027-01-12")
	check("a Monday is the week before", ns.CommunityWeekStart(1800000000 - 4 * 86400) == "2027-01-05")
	local function story(title, author, ruleset, kind)
		return { kind = kind or "story", title = title, mood = "funny", author = author, ruleset = ruleset, lines = {
			{ kind = "say", text = "A gnome in Ironforge sells jars of silence." },
			{ kind = "emote", text = "cups an invisible jar in both hands." },
			{ kind = "say", text = "Nobody has opened one. Everyone agrees they are very quiet." },
		} }
	end
	wipe(ns.CommunityWeeks) -- Only these test weeks, whatever Community.lua has.
	ns.AddCommunityWeek("2027-01-19", { story("Next Week's Tale", "Mira", "") })
	ns.AddCommunityWeek("2027-01-12", { story("Jars of Silence", "Testhero Ashvale", "Normal"), story("The Quiet Rumor", "", "", "rumor") })
	ns.AddCommunityWeek("2027-01-05", { story("Last Week's Tale", "Thorg", "PvP") })
	ns.Story.StoriesChanged()

	slash("stories")
	local tabs = {}
	for _, f in ipairs(allFrames) do
		if rawget(f, "selected") and rawget(f, "key") then tabs[f.key] = f end
	end
	check("five side tabs", tabs.community ~= nil)
	check("community stories aren't on the Stories tab", rowFor("Jars of Silence") == nil)
	click(tabs.community, "Community tab")
	check("this week's are open", headerStartingWith("- This Week at the Fire") ~= nil and rowFor("Jars of Silence") ~= nil)
	check("a rumor is listed too", rowFor("The Quiet Rumor") ~= nil)
	check("last week's are closed but there", rowFor("Last Week's Tale") == nil and findButton("Week of January 5") ~= nil)
	check("next week's stay hidden", rowFor("Next Week's Tale") == nil)
	local row = rowFor("Jars of Silence")
	check("a community story isn't marked as yours", row.story.kind == nil and row.story.communityKind == "story")
	click(row, "Jars of Silence")
	local credited
	for _, f in ipairs(allFrames) do
		if f._type == "FontString" and underFrame(f, storyWindow()) and plainText(f._text or ""):find("by Testhero Ashvale, Normal", 1, true) then credited = true end
	end
	check("the reader credits the author", credited)
	check("anonymous credit", ns.CommunityCredit(rowFor("The Quiet Rumor").story) == "shared anonymously")
	local n = #sent
	for _ = 1, 3 do realG.FiresideTales_Speak() end
	check("it's told like any story", #sent == n + 3 and sent[n + 2].text == "cups an invisible jar in both hands.", sent[#sent] and sent[#sent].text)

	-- The note for a featured author: once a week, in the chat window only.
	ns.CharData().featuredNoted = nil
	local before, sentBefore = #chatOut, #sent
	ns.NoteFeaturedStory()
	check("the author is told their story is featured", #chatOut == before + 1 and chatOut[#chatOut]:find('Your story "Jars of Silence" is featured', 1, true), chatOut[#chatOut])
	check("nothing is said aloud", #sent == sentBefore)
	ns.NoteFeaturedStory()
	check("only once a week", #chatOut == before + 1)
	ns.CharData().featuredNoted = nil
	W.hardcore = true
	ns.NoteFeaturedStory()
	check("a Normal story isn't claimed by a Hardcore character", #chatOut == before + 1)
	W.hardcore = nil

	-- Stories reach Tell a Tale only in their week.
	local picks = {}
	click(findButton("Menu", tellerBar()), "Menu")
	for _ = 1, 300 do
		clickLabel("Tell a Tale", storyWindow())
		local _, picked = readerTitle()
		if picked then picks[picked.title] = true end
	end
	check("Tell a Tale never picks last week's", not picks["Last Week's Tale"] and not picks["Next Week's Tale"])
end)

scenario("community tab: empty until the site has stories", function()
	ns, loaded, skipped = boot({})
	wipe(ns.CommunityWeeks)
	ns.Story.StoriesChanged()
	slash("stories")
	for _, f in ipairs(allFrames) do
		if rawget(f, "selected") and rawget(f, "key") == "community" then click(f, "Community tab") end
	end
	local empty
	for _, f in ipairs(allFrames) do
		if f._type == "FontString" and effectiveShown(f) and plainText(f._text or ""):find("No community stories yet", 1, true) then empty = true end
	end
	check("an empty Community tab points to Contribute a Story", empty)

	-- The bottom bar's second button changes with the tab.
	check("the Community tab offers Contribute a Story", findButton("Contribute a Story", storyWindow()) ~= nil)
	check("and not Write Your Tales", findButton("Write Your Tales", storyWindow()) == nil)
	local hint
	for _, f in ipairs(allFrames) do
		if f._type == "FontString" and effectiveShown(f) and plainText(f._text or ""):find("shared by players", 1, true) then hint = true end
	end
	check("the reader says these were shared by players", hint)
	local n = #sent
	click(findButton("Contribute a Story", storyWindow()), "Contribute a Story")
	local contribute = rawget(realG, "FiresideTalesContributeFrame")
	check("Contribute a Story opens its window", contribute and contribute:IsShown())
	local url
	for _, f in ipairs(allFrames) do
		if f._type == "EditBox" and underFrame(f, contribute) then url = f end
	end
	check("it has the address to copy", url and url:GetText() == "firesidetales.dev/submit", url and url:GetText())
	url:SetText("oops")
	if url._scripts.OnTextChanged then url._scripts.OnTextChanged(url, true) end
	check("the address can't be changed", url:GetText() == "firesidetales.dev/submit", url:GetText())
	check("nothing is said aloud", #sent == n)
	click(findButton("Contribute a Story", storyWindow()), "Contribute a Story")
	check("pressing it again closes the window", not contribute:IsShown())
	for _, f in ipairs(allFrames) do
		if rawget(f, "selected") and rawget(f, "key") == "stories" then click(f, "Stories tab") end
	end
	check("other tabs have Write Your Tales back", findButton("Write Your Tales", storyWindow()) ~= nil and findButton("Contribute a Story", storyWindow()) == nil)
end)

scenario("riddles: every riddle is fit to ask", function()
	ns, loaded, skipped = boot({})
	check("Riddles.lua loads", (function() for _, file in ipairs(loaded) do if file == "Riddles.lua" then return true end end end)())
	check("RiddleGame.lua loads", ns.Riddle ~= nil)
	check("22 riddles", #ns.Riddles == 22, #ns.Riddles)
	local function safe(text)
		return #text < 250 and not text:find("[|{}]") and not text:find("[^\32-\126]")
	end
	local titles = {}
	for _, r in ipairs(ns.Riddles) do
		local says, emotes = 0, 0
		for _, line in ipairs(r.lines) do
			if line.kind == "say" then says = says + 1 else emotes = emotes + 1 end
			check(r.title .. ": line is safe for chat", safe(line.text), line.text)
			if line.kind == "emote" then check(r.title .. ": emote starts lowercase", line.text:find("^%l") ~= nil, line.text) end
			check(r.title .. ": its own lines don't give the answer", not ns.Riddle.Matches(r, line.text), line.text)
		end
		check(r.title .. ": 3 to 8 lines", #r.lines >= 3 and #r.lines <= 8, #r.lines)
		check(r.title .. ": a spoken line and an emote", says >= 1 and emotes >= 1)
		check(r.title .. ": has a mood", r.mood ~= nil)
		check(r.title .. ": has a hint", type(r.hint) == "string" and safe(r.hint), r.hint)
		check(r.title .. ": the hint doesn't give the answer", not ns.Riddle.Matches(r, r.hint), r.hint)
		check(r.title .. ": its answer counts as right", ns.Riddle.Matches(r, r.answer), r.answer)
		check(r.title .. ": accepted answers are plain lowercase", (function()
			for _, a in ipairs(r.answers) do if not a:find("^[a-z0-9 ]+$") then return false end end
			return #r.answers > 0
		end)())
		-- The lines Speak builds, with the longest name the game allows.
		check(r.title .. ": the announce line fits", safe(("Abcdefghijkl has it! It's %s."):format(r.answer)))
		check(r.title .. ": the reveal line fits", safe(("Nobody? It's %s."):format(r.answer)))
		check(r.title .. ": title is unique", not titles[r.title], r.title)
		titles[r.title] = true
	end
	-- No riddle's answer would also win another riddle by accident.
	for _, a in ipairs(ns.Riddles) do
		for _, b in ipairs(ns.Riddles) do
			if a ~= b then check(a.title .. " and " .. b.title .. " don't share answers", not ns.Riddle.Matches(b, a.answer), a.answer) end
		end
	end
end)

scenario("riddles: matching answers", function()
	ns, loaded, skipped = boot({})
	local function riddle(title) for _, r in ipairs(ns.Riddles) do if r.title == title then return r end end end
	local stone, candle, knife, lotus = riddle("Never Once Sold"), riddle("On a Kobold's Head"), riddle("After the Hunt"), riddle("Where the Land Burned")
	check("a plain answer", ns.Riddle.Matches(stone, "hearthstone"))
	check("inside a question", ns.Riddle.Matches(stone, "is it a hearthstone?"))
	check("shouted", ns.Riddle.Matches(stone, "HEARTHSTONE!!!"))
	check("plural", ns.Riddle.Matches(stone, "hearthstones"))
	check("two words", ns.Riddle.Matches(stone, "a hearth stone maybe"))
	check("a near miss doesn't count", not ns.Riddle.Matches(stone, "heartstone"))
	check("half the answer doesn't count", not ns.Riddle.Matches(stone, "my hearth is cold"))
	check("inside another word doesn't count", not ns.Riddle.Matches(candle, "candlesticks!"))
	check("a two-word answer", ns.Riddle.Matches(knife, "a skinning knife?"))
	check("one word of it doesn't count", not ns.Riddle.Matches(knife, "a knife") and not ns.Riddle.Matches(knife, "skinning"))
	check("punctuation between words", ns.Riddle.Matches(lotus, "the... black-lotus"))
	check("an empty message", not ns.Riddle.Matches(stone, ""))
end)

scenario("riddles: asking one, and someone gets it", function()
	W.name = "Testhero"
	ns, loaded, skipped = boot({})
	slash("stories")
	local tabs = {}
	for _, f in ipairs(allFrames) do
		if rawget(f, "selected") and rawget(f, "key") then tabs[f.key] = f end
	end
	check("a Riddles tab", tabs.riddles ~= nil)
	local search
	for _, f in ipairs(allFrames) do if f._type == "EditBox" then search = search or f end end
	search:SetText("hearthstone")
	search:SetText("")
	check("riddles aren't on the Stories tab", rowFor("Never Once Sold") == nil)
	click(tabs.riddles, "Riddles tab")
	local row = rowFor("Never Once Sold")
	check("the Riddles tab lists them", row ~= nil and rowFor("Never Enough") ~= nil)
	click(row, "Never Once Sold")
	local readerHas = function(text)
		for _, f in ipairs(allFrames) do
			if f._type == "FontString" and underFrame(f, storyWindow()) and plainText(f._text or ""):find(text, 1, true) then return true end
		end
	end
	check("the teller sees the hint", readerHas("Hint: You chose where I take you"))
	check("the teller sees the answer", readerHas("Answer (only you can see this): a hearthstone"))
	check("not listening before it's asked", not ns.Riddle.IsListening())
	fire("CHAT_MSG_SAY", "hearthstone", "Mira-Stormrage")
	check("an answer before the riddle doesn't count", ns.Riddle.For(row.story) == nil)

	local n = #sent
	realG.FiresideTales_Speak() -- Tell: hands it to the teller bar.
	if #sent == n then realG.FiresideTales_Speak() end
	check("asking starts with the first line", #sent == n + 1 and sent[#sent].text == row.story.lines[1].text, sent[#sent] and sent[#sent].text)
	check("now listening", ns.Riddle.IsListening())
	for _ = 2, #row.story.lines do realG.FiresideTales_Speak() end
	check("every line is asked", #sent == n + #row.story.lines)

	fire("CHAT_MSG_SAY", "a rock?", "Mira-Stormrage")
	check("a wrong guess doesn't win", ns.Riddle.For(row.story).winner == nil)
	fire("CHAT_MSG_SAY", "it's a hearthstone, obviously", "Testhero")
	check("the teller can't win their own riddle", ns.Riddle.For(row.story).winner == nil)
	fire("CHAT_MSG_SAY", "<<secret>>", "Mira-Stormrage")
	fire("CHAT_MSG_SAY", "hearthstone", "<<secret>>")
	check("secret chat is ignored", ns.Riddle.For(row.story).winner == nil)
	check("Speak offers the hint while waiting", findButton("Hint", tellerBar()) ~= nil, barTexts())

	local sounds = W.sounds or 0
	fire("CHAT_MSG_PARTY", "HEARTHSTONE!", "Mira-Stormrage")
	check("the right answer wins, without the realm", ns.Riddle.For(row.story).winner == "Mira")
	check("a sound says so", (W.sounds or 0) > sounds)
	check("the bar names the winner", barTexts():find("Mira has it!", 1, true), barTexts())
	check("Speak offers to announce", findButton("Announce", tellerBar()) ~= nil)
	fire("CHAT_MSG_SAY", "hearthstone", "Bjorn")
	check("a later answer doesn't take it", ns.Riddle.For(row.story).winner == "Mira")
	check("nothing is said by itself", #sent == n + #row.story.lines)

	realG.FiresideTales_Speak()
	check("Announce says who got it, in /say", sent[#sent].text == "Mira has it! It's a hearthstone." and sent[#sent].chatType == "SAY", sent[#sent].text)
	local count = #sent
	realG.FiresideTales_Speak()
	check("then it's over", #sent == count)
	check("the bar says the end", barTexts():find("The end", 1, true), barTexts())
end)

scenario("riddles: nobody gets it", function()
	W.name = "Testhero"
	ns, loaded, skipped = boot({})
	slash("stories")
	for _, f in ipairs(allFrames) do
		if rawget(f, "selected") and rawget(f, "key") == "riddles" then click(f, "Riddles tab") end
	end
	local row = rowFor("Never Enough")
	click(row, "Never Enough")
	local n = #sent
	realG.FiresideTales_Speak()
	if #sent == n then realG.FiresideTales_Speak() end
	for _ = 2, #row.story.lines do realG.FiresideTales_Speak() end
	local asked = #sent

	W.lockdown = true
	realG.FiresideTales_Speak()
	check("a blocked hint isn't counted as given", #sent == asked and findButton("Hint", tellerBar()) ~= nil)
	W.lockdown = false
	realG.FiresideTales_Speak()
	check("Speak gives the hint", sent[#sent].text == row.story.hint, sent[#sent].text)
	check("then offers to reveal", findButton("Reveal", tellerBar()) ~= nil, barTexts())
	check("still listening after the hint", ns.Riddle.IsListening())
	realG.FiresideTales_Speak()
	check("Reveal says the answer", sent[#sent].text == "Nobody? It's your bags.", sent[#sent].text)
	fire("CHAT_MSG_SAY", "bags!", "Mira")
	check("an answer after the reveal doesn't win", ns.Riddle.For(row.story).winner == nil)
	local count = #sent
	realG.FiresideTales_Speak()
	check("then it's over", #sent == count)

	-- Ask it again: it starts fresh, and an answer after the hint still wins.
	click(findButton("Menu", tellerBar()), "Menu")
	click(rowFor("Never Enough"), "Never Enough")
	clickLabel("Restart", storyWindow())
	realG.FiresideTales_Speak()
	if #sent == count then realG.FiresideTales_Speak() end
	for _ = 2, #row.story.lines do realG.FiresideTales_Speak() end
	check("asked again, it listens again", ns.Riddle.IsListening() and ns.Riddle.For(row.story).winner == nil)
	realG.FiresideTales_Speak()
	fire("CHAT_MSG_SAY", "my bags?", "Bjorn")
	check("an answer after the hint wins", ns.Riddle.For(row.story).winner == "Bjorn")
	realG.FiresideTales_Speak()
	check("and is announced", sent[#sent].text == "Bjorn has it! It's your bags.", sent[#sent].text)
end)

scenario("riddles: time runs out, and moving on stops it", function()
	W.name = "Testhero"
	ns, loaded, skipped = boot({})
	slash("stories")
	for _, f in ipairs(allFrames) do
		if rawget(f, "selected") and rawget(f, "key") == "riddles" then click(f, "Riddles tab") end
	end
	local row = rowFor("Lighter Than Air")
	click(row, "Lighter Than Air")
	local n = #sent
	realG.FiresideTales_Speak()
	if #sent == n then realG.FiresideTales_Speak() end
	for _ = 2, #row.story.lines do realG.FiresideTales_Speak() end
	advance(301)
	fire("CHAT_MSG_SAY", "a feather", "Mira")
	check("after five minutes, answers stop counting", ns.Riddle.For(row.story).winner == nil and not ns.Riddle.IsListening())
	check("the bar says nobody's answered", barTexts():find("No answer yet", 1, true), barTexts())
	realG.FiresideTales_Speak()
	check("the hint still works", sent[#sent].text == row.story.hint)

	click(findButton("Menu", tellerBar()), "Menu")
	click(rowFor("On a Kobold's Head"), "On a Kobold's Head")
	check("choosing another riddle ends this one", ns.Riddle.For(row.story) == nil)
	fire("CHAT_MSG_SAY", "a feather", "Mira")
	check("and its answer no longer counts", ns.Riddle.For(row.story) == nil)

	-- Tell a Tale never hands you a riddle.
	local picks = 0
	for _ = 1, 60 do
		clickLabel("Tell a Tale", storyWindow())
		local _, picked = readerTitle()
		if picked and picked.riddle then picks = picks + 1 end
	end
	check("Tell a Tale never picks a riddle", picks == 0, picks)
end)

setmetatable(realG, nil)
stdPrint("")
stdPrint(("RESULT: %d passed, %d failed"):format(passed, failed))
for _, f in ipairs(failures) do stdPrint("  - " .. f) end
local names = {}
for name in pairs(unknownGlobals) do names[#names + 1] = name end
table.sort(names)
stdPrint("Globals read but not stubbed: " .. (#names > 0 and table.concat(names, ", ") or "none"))
