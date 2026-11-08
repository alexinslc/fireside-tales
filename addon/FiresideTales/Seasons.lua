-- Which festival is on today, and whether it's night, so the fire can pick a
-- story that fits the evening.
local _, ns = ...

ns.Season = {}

local function weekdayOfFirst(today)
	-- weekday is 1 for Sunday, as the game and os.date both count it.
	return (today.weekday - 1 - (today.monthDay - 1)) % 7 + 1
end

local function between(today, fromMonth, fromDay, toMonth, toDay)
	local now = today.month * 100 + today.monthDay
	local from, to = fromMonth * 100 + fromDay, toMonth * 100 + toDay
	if from <= to then return now >= from and now <= to end
	return now >= from or now <= to -- Runs over the new year.
end

-- In calendar order. keyword matches the game calendar's name for it. dates
-- is used when the calendar can't be read; festivals whose dates move from
-- year to year only come from the calendar.
ns.Season.Festivals = {
	{
		name = "Darkmoon Faire", keyword = "darkmoon",
		offer = "The Darkmoon Faire is in town. Tell a tale?",
		-- Opens the Monday after the first Friday of the month, for a week.
		dates = function(today)
			local firstFriday = 1 + (6 - weekdayOfFirst(today)) % 7
			local opens = firstFriday + 3
			return today.monthDay >= opens and today.monthDay <= opens + 6
		end,
	},
	{ name = "Lunar Festival", keyword = "lunar", offer = "The elders are honored tonight. Tell a tale?" },
	{ name = "Love is in the Air", keyword = "love is in the air", offer = "Love is in the air. Tell a tale?" },
	{ name = "Noblegarden", keyword = "noblegarden", offer = "Noblegarden is here. Tell a tale?" },
	{ name = "Children's Week", keyword = "children", offer = "It's Children's Week. Tell a tale?" },
	{
		name = "Midsummer Fire Festival", keyword = "midsummer",
		offer = "The midsummer fires are lit. Tell a tale?",
		dates = function(today) return between(today, 6, 21, 7, 5) end,
	},
	{ name = "Harvest Festival", keyword = "harvest", offer = "The harvest is in. Tell a tale?" },
	{
		name = "Hallow's End", keyword = "hallow",
		offer = "It's Hallow's End. Tell a tale?",
		dates = function(today) return between(today, 10, 18, 11, 1) end,
	},
	{
		name = "Winter Veil", keyword = "winter veil",
		offer = "It's Winter Veil. Tell a tale?",
		dates = function(today) return between(today, 12, 15, 1, 2) end,
	},
}

local function today()
	if C_DateAndTime and C_DateAndTime.GetCurrentCalendarTime then
		local now = C_DateAndTime.GetCurrentCalendarTime()
		if now and now.monthDay then return now end
	end
	local now = date("*t")
	return { year = now.year, month = now.month, monthDay = now.day, weekday = now.wday }
end

-- The calendar only answers once the game has loaded it.
local calendarReady = false

-- Names of the holidays the calendar shows today, or nil if it can't say.
local function calendarHolidays(now)
	if not (calendarReady and C_Calendar and C_Calendar.GetMonthInfo and C_Calendar.GetNumDayEvents) then return nil end
	local ok, info = pcall(C_Calendar.GetMonthInfo, 0)
	if not ok or type(info) ~= "table" or not info.month then return nil end
	-- The calendar counts months from whichever one it's showing.
	local offset = (now.year - info.year) * 12 + (now.month - info.month)
	local names, monthHasAny = {}, false
	for day = 1, 31 do
		local okCount, count = pcall(C_Calendar.GetNumDayEvents, offset, day)
		for index = 1, (okCount and count or 0) do
			local okEvent, event = pcall(C_Calendar.GetDayEvent, offset, day, index)
			if okEvent and type(event) == "table" and event.calendarType == "HOLIDAY" and event.title then
				monthHasAny = true
				if day == now.monthDay then names[#names + 1] = event.title:lower() end
			end
		end
	end
	-- A month with no holidays at all most likely means the calendar has none.
	if not monthHasAny then return nil end
	return names
end

-- The festivals on today, in calendar order. Worked out once a day, and again
-- whenever the calendar changes.
local cachedDay, cachedActive
function ns.Season.Active()
	local now = today()
	local day = ("%d-%d-%d"):format(now.year or 0, now.month, now.monthDay)
	if day == cachedDay then return cachedActive end
	local holidays = calendarHolidays(now)
	local active = {}
	for _, festival in ipairs(ns.Season.Festivals) do
		local on
		if holidays then
			for _, title in ipairs(holidays) do
				if title:find(festival.keyword, 1, true) then on = true end
			end
		else
			on = festival.dates and festival.dates(now)
		end
		if on then active[#active + 1] = festival end
	end
	cachedDay, cachedActive = day, active
	return active
end

-- Night in the game world, when it's dark out.
function ns.Season.IsNight()
	if not GetGameTime then return false end
	local hour = GetGameTime()
	return hour >= 21 or hour < 6
end

local watcher = CreateFrame("Frame")
watcher:RegisterEvent("PLAYER_LOGIN")
watcher:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_LOGIN" then
		if C_Calendar and C_Calendar.OpenCalendar then
			self:RegisterEvent("CALENDAR_UPDATE_EVENT_LIST")
			pcall(C_Calendar.OpenCalendar)
		end
	else
		calendarReady = true
		cachedDay = nil
	end
end)
