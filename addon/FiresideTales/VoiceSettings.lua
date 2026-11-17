-- The Voices tab of the story menu: which voice packs are installed, where to get the others,
-- and the player's choices for how stories are read aloud.
local _, ns = ...

ns.VoiceSettings = {}

local panel
local packRows = {}
local checks = {}
local summary, readerMenu, sampleStatus

-------------------------------------------------------------------------------
-- Getting a pack: addons can't open a web page, so the address is ready to copy
-------------------------------------------------------------------------------

local linkWindow

local function buildLinkWindow()
	linkWindow = ns.NewWindow("FiresideTalesVoiceLinkFrame", "Get a Voice Pack",
		"Interface\\AddOns\\FiresideTales\\Textures\\Icon", 400, 180)
	linkWindow:SetFrameStrata("DIALOG")
	ns.MakeDraggable(linkWindow, "voiceLinkPosition")
	ns.PlaceFrame(linkWindow, "voiceLinkPosition", "CENTER", UIParent, "CENTER", 0, 60)
	table.insert(UISpecialFrames, "FiresideTalesVoiceLinkFrame") -- Escape closes it.

	local intro = linkWindow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	intro:SetPoint("TOPLEFT", 66, -36)
	intro:SetPoint("TOPRIGHT", -14, -36)
	intro:SetJustifyH("LEFT")
	linkWindow.intro = intro

	local box = CreateFrame("EditBox", nil, linkWindow, "InputBoxTemplate")
	box:SetSize(320, 24)
	box:SetPoint("TOP", 0, -112)
	box:SetAutoFocus(false)
	box:SetFontObject("ChatFontNormal")
	box:SetJustifyH("CENTER")
	box:SetScript("OnTextChanged", function(self, userInput)
		if userInput then
			self:SetText(linkWindow.url or "")
			self:HighlightText()
		end
	end)
	box:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
	box:SetScript("OnEscapePressed", function(self) self:ClearFocus(); linkWindow:Hide() end)
	box:SetScript("OnMouseUp", function(self) self:HighlightText() end)
	linkWindow.box = box

	local hint = linkWindow:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	hint:SetPoint("TOP", box, "BOTTOM", 0, -8)
	hint:SetText("Selected. Press Cmd+C on a Mac or Ctrl+C on Windows to copy it.")

	linkWindow:Hide()
	ns.AddWindowSounds(linkWindow)
	linkWindow:HookScript("OnShow", function()
		box:SetFocus()
		box:HighlightText()
	end)
end

local function showLink(pack)
	if not linkWindow then buildLinkWindow() end
	linkWindow.url = pack.url
	linkWindow.intro:SetText(("%s is a separate download (%s). Get it from CurseForge or the CurseForge app, "
		.. "then reload the game."):format(pack.title, pack.size))
	linkWindow.box:SetText(pack.url)
	linkWindow:Show()
	linkWindow.box:SetFocus()
	linkWindow.box:HighlightText()
end

-------------------------------------------------------------------------------
-- The panel
-------------------------------------------------------------------------------

local function listTitles(list)
	local titles = {}
	for i, voice in ipairs(list) do titles[i] = voice.title end
	return table.concat(titles, ", ")
end

function ns.VoiceSettings.Refresh()
	if not panel then return end
	local V = ns.Voices
	local s = V.Settings()
	local any = V.Any()

	if any then
		local n = V.Narrator()
		local races = V.RaceVoices()
		summary:SetText(("|cff80d080Reading stories aloud.|r Narrator: %s. Race voices: %s."):format(
			n and n.title or "none installed", #races > 0 and tostring(#races) or "none installed"))
	else
		summary:SetText("|cffff8060No Voice Packs Installed|r")
	end

	for _, row in ipairs(packRows) do
		local installed = V.HasPack(row.pack.addon)
		row.status:SetShown(installed)
		row.get:SetShown(not installed)
	end

	checks.on:SetChecked(s.on)
	checks.own:SetChecked(s.own)
	checks.own:SetEnabled(s.on)
	readerMenu.refresh()
end

local function makeCheck(parent, label, detail, onClick)
	local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
	check:SetSize(24, 24)
	local text = check.Text or check.text
	if not (type(text) == "table" and text.SetText) then
		text = check:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		text:SetPoint("LEFT", check, "RIGHT", 2, 1)
	end
	text:SetFontObject("GameFontHighlight")
	text:SetText(label)
	check.label = text
	local note = parent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	note:SetPoint("TOPLEFT", check, "BOTTOMLEFT", 26, 3)
	note:SetWidth(250)
	note:SetJustifyH("LEFT")
	note:SetText(detail)
	check:SetScript("OnClick", function(self)
		ns.PlayUISound(self:GetChecked() and "IG_MAINMENU_OPTION_CHECKBOX_ON" or "IG_MAINMENU_OPTION_CHECKBOX_OFF")
		onClick(self:GetChecked() and true or false)
		ns.VoiceSettings.Refresh()
	end)
	return check
end

local function makePackRow(parent, pack, index)
	local row = CreateFrame("Frame", nil, parent)
	row:SetSize(560, 44)
	row:SetPoint("TOPLEFT", 20, -96 - (index - 1) * 48)
	row.pack = pack

	local name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	name:SetPoint("TOPLEFT", 0, -4)
	name:SetText(pack.title)

	local about = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	about:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -4)
	about:SetWidth(420)
	about:SetJustifyH("LEFT")
	about:SetText(pack.about .. " |cff9d9d9d" .. pack.size .. "|r")

	row.status = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	row.status:SetPoint("RIGHT", 0, 0)
	row.status:SetText("|cff80d080Installed|r")

	row.get = ns.MakeFlatButton(row, "Get on CurseForge", 120)
	row.get:SetPoint("RIGHT", 0, 0)
	row.get:SetScript("OnClick", function() showLink(pack) end)

	packRows[index] = row
	return row
end

-- The choices for who reads: race voices, then each narrator installed (or just "Narrator").
local function readerChoices()
	local V = ns.Voices
	local list = { { key = "races", text = "Race voices" } }
	local narrators = V.Narrators()
	if #narrators <= 1 then
		list[2] = { key = "narrator", text = "Narrator" }
	else
		for _, n in ipairs(narrators) do list[#list + 1] = { key = "narrator", voice = n.key, text = n.title } end
	end
	return list
end

local function isChosen(choice)
	local V = ns.Voices
	local s = V.Settings()
	if choice.key == "races" then return s.races end
	if s.races then return false end
	return not choice.voice or (V.Narrator() and V.Narrator().key == choice.voice)
end

local function choose(choice)
	local V = ns.Voices
	V.Settings().races = choice.key == "races"
	if choice.voice then V.SetNarrator(choice.voice) end
	ns.PlayUISound("IG_MAINMENU_OPTION")
	ns.VoiceSettings.Refresh()
end

function ns.VoiceSettings.MakeReaderMenu(parent)
	local menu = {}
	local ok, dropdown = pcall(CreateFrame, "DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
	if ok and dropdown and dropdown.SetupMenu then
		dropdown:SetWidth(200)
		dropdown:SetupMenu(function(_, root)
			for _, choice in ipairs(readerChoices()) do
				root:CreateRadio(choice.text, isChosen, choose, choice)
			end
		end)
		menu.frame = dropdown
		menu.refresh = function()
			if dropdown.GenerateMenu then dropdown:GenerateMenu() end
			dropdown:SetEnabled(ns.Voices.Settings().on)
		end
		return menu
	end
	-- No dropdown in this client: a button that steps through the choices.
	local button = ns.MakeFlatButton(parent, "Race voices", 200)
	button:SetScript("OnClick", function()
		local list = readerChoices()
		for i, choice in ipairs(list) do
			if isChosen(choice) then return choose(list[i % #list + 1]) end
		end
		choose(list[1])
	end)
	menu.frame = button
	menu.refresh = function()
		for _, choice in ipairs(readerChoices()) do
			if isChosen(choice) then button:SetText(choice.text) end
		end
		button:SetEnabled(ns.Voices.Settings().on)
	end
	return menu
end

-- Builds the Voices page over the story menu's own pages. The menu shows and hides it with its tab.
function ns.VoiceSettings.Build(window, top, bottom)
	local V = ns.Voices
	panel = ns.NewInset(window)
	panel:SetPoint("TOPLEFT", 8, top)
	panel:SetPoint("BOTTOMRIGHT", -8, bottom)
	panel:SetFrameLevel(window:GetFrameLevel() + 20) -- Over the pages it stands in for.
	panel:EnableMouse(true)

	local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 20, -16)
	title:SetText("Voices")

	local intro = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	intro:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
	intro:SetWidth(560)
	intro:SetJustifyH("LEFT")
	intro:SetText("When someone nearby tells a Fireside Tales story, or you do, each line is read aloud in the "
		.. "voice of the teller's race. Voice packs are separate downloads, so get only the ones you want.")

	summary = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	summary:SetPoint("TOPLEFT", intro, "BOTTOMLEFT", 0, -10)
	summary:SetWidth(560)
	summary:SetJustifyH("LEFT")

	for index, pack in ipairs(V.PACKS) do
		makePackRow(panel, pack, index)
	end

	local optionsTop = -96 - #V.PACKS * 48 - 14
	local rule = panel:CreateTexture(nil, "ARTWORK")
	rule:SetColorTexture(0.72, 0.55, 0.32, 0.35)
	rule:SetPoint("TOPLEFT", 20, optionsTop)
	rule:SetSize(560, 1)

	checks.on = makeCheck(panel, "Read stories aloud", "Turn this off to keep the packs installed but quiet.",
		function(on)
			V.Settings().on = on
			if not on then V.Stop() end
		end)
	checks.on:SetPoint("TOPLEFT", 16, optionsTop - 10)
	checks.own = makeCheck(panel, "Hear your own stories", "Read aloud as you tell them, too.",
		function(on) V.Settings().own = on end)
	checks.own:SetPoint("TOPLEFT", checks.on, "BOTTOMLEFT", 0, -16)

	-- Who reads: race voices, or one narrator for every story. A dropdown where the game has one,
	-- or else a button that steps through the same choices.
	local readerLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	readerLabel:SetPoint("TOPLEFT", 320, optionsTop - 14)
	readerLabel:SetText("Who reads")
	readerMenu = ns.VoiceSettings.MakeReaderMenu(panel)
	readerMenu.frame:SetPoint("TOPLEFT", readerLabel, "BOTTOMLEFT", 0, -6)
	local readerNote = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	readerNote:SetPoint("TOPLEFT", readerMenu.frame, "BOTTOMLEFT", 2, -6)
	readerNote:SetWidth(250)
	readerNote:SetJustifyH("LEFT")
	readerNote:SetText("With race voices, the narrator reads any teller whose race pack isn't installed.")

	local sample = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	sample:SetSize(110, 22)
	sample:SetPoint("BOTTOMLEFT", 20, 14)
	sample:SetText("Play a Sample")
	sample:SetScript("OnClick", function()
		local text, why = V.PlaySample()
		sampleStatus:SetText(text and ('|cffd4af37"' .. text .. '"|r') or ("Couldn't play one: " .. tostring(why) .. "."))
	end)

	local stop = ns.MakeFlatButton(panel, "Stop", 50)
	stop:SetPoint("LEFT", sample, "RIGHT", 4, 0)
	stop:SetScript("OnClick", function()
		V.Stop()
		sampleStatus:SetText("")
	end)

	sampleStatus = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	sampleStatus:SetPoint("LEFT", stop, "RIGHT", 10, 0)
	sampleStatus:SetPoint("RIGHT", panel, "RIGHT", -16, 0)
	sampleStatus:SetJustifyH("LEFT")
	sampleStatus:SetWordWrap(false)

	local volume = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	volume:SetPoint("BOTTOMLEFT", sample, "TOPLEFT", 0, 8)
	volume:SetText("Voices play at the game's Master volume, in Settings, under Audio.")

	panel:Hide()
	panel:SetScript("OnShow", ns.VoiceSettings.Refresh)
	return panel
end
