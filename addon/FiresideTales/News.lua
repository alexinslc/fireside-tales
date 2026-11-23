-- What's New: a small window, shown once after each update, with how to share a story
-- and what this version changed (from WhatsNew.lua). /tales news opens it again.
local _, ns = ...
local L = ns.L

ns.News = {}

local SITE_URL = "firesidetales.dev"
local WIDTH = 400
local window, itemsText, versionText
local waitingForCombat = false

local function itemsFor()
	local data = ns.WhatsNew
	-- WhatsNew.lua is written from CHANGELOG.md for each release. If it's for another version,
	-- the site line still shows, without a list that doesn't match.
	if not data or data.version ~= ns.Version or not data.items or #data.items == 0 then return nil end
	local lines = {}
	for _, item in ipairs(data.items) do
		lines[#lines + 1] = "- " .. item
	end
	return table.concat(lines, "\n")
end

local function build()
	window = ns.NewWindow("FiresideTalesNewsFrame", L["What's New"], "Interface\\AddOns\\FiresideTales\\Textures\\Icon", WIDTH, 220)
	window:SetFrameStrata("DIALOG")
	ns.MakeDraggable(window, "newsPosition")
	ns.PlaceFrame(window, "newsPosition", "CENTER", UIParent, "CENTER", 0, 80)
	table.insert(UISpecialFrames, "FiresideTalesNewsFrame") -- Escape closes it.

	local share = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	share:SetPoint("TOPLEFT", 66, -36)
	share:SetPoint("TOPRIGHT", -14, -36)
	share:SetJustifyH("LEFT")
	share:SetText(L["Got a tale of your own? Share it at %s"]:format(SITE_URL))

	-- Addons can't open a web page, so the address is ready to copy. It can't be edited.
	local box = CreateFrame("EditBox", nil, window, "InputBoxTemplate")
	box:SetSize(200, 24)
	box:SetPoint("TOPLEFT", 72, -64)
	box:SetAutoFocus(false)
	box:SetFontObject("ChatFontNormal")
	box:SetText(SITE_URL)
	box:SetScript("OnTextChanged", function(self, userInput)
		if userInput then
			self:SetText(SITE_URL)
			self:HighlightText()
		end
	end)
	box:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
	box:SetScript("OnEscapePressed", function(self) self:ClearFocus(); window:Hide() end)
	box:SetScript("OnMouseUp", function(self) self:HighlightText() end)
	window.box = box

	local hint = window:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	hint:SetPoint("TOPLEFT", box, "BOTTOMLEFT", -6, -4)
	hint:SetText(L["Cmd+C or Ctrl+C to copy"])

	versionText = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	versionText:SetPoint("TOPLEFT", 20, -118)
	versionText:SetPoint("TOPRIGHT", -20, -118)
	versionText:SetJustifyH("LEFT")

	itemsText = window:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	itemsText:SetPoint("TOPLEFT", versionText, "BOTTOMLEFT", 0, -8)
	itemsText:SetPoint("TOPRIGHT", versionText, "BOTTOMRIGHT", 0, -8)
	itemsText:SetJustifyH("LEFT")
	itemsText:SetJustifyV("TOP")
	itemsText:SetSpacing(3)

	window:Hide()
	window:HookScript("OnShow", function()
		box:SetFocus()
		box:HighlightText()
	end)
end

local function fill()
	local items = itemsFor()
	versionText:SetShown(items ~= nil)
	itemsText:SetShown(items ~= nil)
	local height = 126
	if items then
		versionText:SetText(L["New in version %s"]:format(ns.Version))
		itemsText:SetText(items)
		height = 118 + versionText:GetStringHeight() + 8 + itemsText:GetStringHeight() + 22
	end
	window:SetHeight(math.max(126, height))
end

function ns.News.Show()
	if not window then build() end
	fill()
	window:Show()
end

function ns.News.Toggle()
	if window and window:IsShown() then
		window:Hide()
	else
		ns.News.Show()
	end
end

function ns.News.IsShown()
	return window ~= nil and window:IsShown()
end

local function inCombat()
	return InCombatLockdown and InCombatLockdown() or false
end

-- Shows the window once per version: on the first login after an update, or on a fresh
-- install. In combat, it waits until combat ends.
function ns.News.ShowIfNew()
	local db = ns.GetDB()
	if not db or not ns.Version or db.lastSeenVersion == ns.Version then return end
	if inCombat() then
		waitingForCombat = true
		return
	end
	db.lastSeenVersion = ns.Version
	ns.News.Show()
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_LOGIN" then
		-- A moment after logging in, once the screen has settled.
		if C_Timer then C_Timer.After(3, ns.News.ShowIfNew) else ns.News.ShowIfNew() end
	elseif event == "PLAYER_REGEN_ENABLED" and waitingForCombat then
		waitingForCombat = false
		ns.News.ShowIfNew()
	end
end)
