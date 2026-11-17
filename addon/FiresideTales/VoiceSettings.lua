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
local LINK_ROWS = 4 -- The most packs in a group.
local LINK_TOP, LINK_ROW = -96, 46

-- A box with an address in it, selected for copying, that typing can't change.
local function makeAddressBox(parent)
	local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
	box:SetSize(290, 24)
	box:SetAutoFocus(false)
	box:SetFontObject("ChatFontNormal")
	box:SetScript("OnTextChanged", function(self, userInput)
		if userInput then
			self:SetText(self.url or "")
			self:HighlightText()
		end
	end)
	box:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
	box:SetScript("OnEscapePressed", function(self) self:ClearFocus(); linkWindow:Hide() end)
	box:SetScript("OnMouseUp", function(self) self:HighlightText() end)
	return box
end

local function buildLinkWindow()
	linkWindow = ns.NewWindow("FiresideTalesVoiceLinkFrame", "Get Voice Packs",
		"Interface\\AddOns\\FiresideTales\\Textures\\Icon", 460, 180)
	linkWindow:SetFrameStrata("DIALOG")
	ns.MakeDraggable(linkWindow, "voiceLinkPosition")
	ns.PlaceFrame(linkWindow, "voiceLinkPosition", "CENTER", UIParent, "CENTER", 0, 60)
	table.insert(UISpecialFrames, "FiresideTalesVoiceLinkFrame") -- Escape closes it.

	local intro = linkWindow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	intro:SetPoint("TOPLEFT", 66, -36)
	intro:SetPoint("TOPRIGHT", -14, -36)
	intro:SetJustifyH("LEFT")
	linkWindow.intro = intro

	-- One row per pack in the group: its name and size, and its address or "Installed".
	linkWindow.rows = {}
	for i = 1, LINK_ROWS do
		local row = {}
		row.name = linkWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		row.name:SetPoint("TOPLEFT", 20, LINK_TOP - (i - 1) * LINK_ROW)
		row.size = linkWindow:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
		row.size:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -3)
		row.box = makeAddressBox(linkWindow)
		row.box:SetPoint("TOPRIGHT", -18, LINK_TOP - (i - 1) * LINK_ROW + 2)
		row.installed = linkWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		row.installed:SetPoint("RIGHT", row.box, "RIGHT", 0, 0)
		row.installed:SetText("|cff80d080Installed|r")
		linkWindow.rows[i] = row
	end

	local hint = linkWindow:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	hint:SetPoint("BOTTOM", 0, 14)
	hint:SetText("Click an address to select it, then press Cmd+C on a Mac or Ctrl+C on Windows to copy it.")
	linkWindow.hint = hint

	linkWindow:Hide()
	ns.AddWindowSounds(linkWindow)
end

-- Shows a group's packs, each with its address to copy, and selects the first one not installed.
local function showLinks(group)
	if not linkWindow then buildLinkWindow() end
	local V = ns.Voices
	linkWindow.intro:SetText(#group.packs > 1
		and "Get these from CurseForge or the CurseForge app, then reload the game. CurseForge limits each "
			.. "download to about 500 MB, so each race is a pack of its own."
		or "Get it from CurseForge or the CurseForge app, then reload the game.")
	local first
	for i, row in ipairs(linkWindow.rows) do
		local pack = group.packs[i]
		local shown = pack ~= nil
		row.name:SetShown(shown)
		row.size:SetShown(shown)
		row.box:SetShown(false)
		row.installed:SetShown(false)
		if pack then
			row.name:SetText(pack.title)
			row.size:SetText(pack.size)
			local installed = V.HasPack(pack.addon)
			row.installed:SetShown(installed)
			row.box:SetShown(not installed)
			row.box.url = pack.url
			row.box:SetText(pack.url)
			if not installed and not first then first = row.box end
		end
	end
	linkWindow:SetHeight(-LINK_TOP + #group.packs * LINK_ROW + 30)
	linkWindow:Show()
	if first then
		first:SetFocus()
		first:HighlightText()
	end
end

-------------------------------------------------------------------------------
-- The panel
-------------------------------------------------------------------------------

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
		local have, count = 0, #row.group.packs
		for _, pack in ipairs(row.group.packs) do
			if V.HasPack(pack.addon) then have = have + 1 end
		end
		row.status:SetText(have == count and "|cff80d080Installed|r"
			or have > 0 and ("|cffd4af37%d of %d installed|r"):format(have, count) or "")
		row.get:SetShown(have < count)
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

-- One row per group: its name and who it's for, how much is installed, and Get for the rest.
local PACK_TOP, PACK_ROW = -92, 36
local function makePackRow(parent, group, index)
	local row = CreateFrame("Frame", nil, parent)
	row:SetSize(560, 32)
	row:SetPoint("TOPLEFT", 20, PACK_TOP - (index - 1) * PACK_ROW)
	row.group = group

	local name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	name:SetPoint("TOPLEFT", 0, -2)
	name:SetText(group.title)

	local about = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	about:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -3)
	about:SetWidth(400)
	about:SetJustifyH("LEFT")
	about:SetWordWrap(false)
	about:SetText(group.about)

	row.get = ns.MakeFlatButton(row, "Get", 60)
	row.get:SetPoint("RIGHT", 0, 0)
	row.get:SetScript("OnClick", function() showLinks(group) end)

	row.status = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	row.status:SetPoint("RIGHT", row.get, "LEFT", -10, 0)

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
	intro:SetText("Stories told nearby are read aloud in the voice of the teller's race. "
		.. "Each race's voices are a separate download, so get only the ones you want.")

	summary = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	summary:SetPoint("TOPLEFT", intro, "BOTTOMLEFT", 0, -10)
	summary:SetWidth(560)
	summary:SetJustifyH("LEFT")

	for index, group in ipairs(V.PACKS) do
		makePackRow(panel, group, index)
	end

	local optionsTop = PACK_TOP - #V.PACKS * PACK_ROW - 8
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
