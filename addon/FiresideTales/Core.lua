-- Fireside Tales: stories to tell at the campfire, one line at a time.
-- Nothing is ever sent without a key press or click.
local ADDON, ns = ...

local CHAT_TYPE = { say = "SAY", emote = "EMOTE" }

local getMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
ns.Version = getMetadata and getMetadata(ADDON, "Version") or nil

local db, char, charKey

local function say(msg)
	print("|cffd4af37Fireside Tales:|r " .. msg)
end

-- Some APIs can return secret values, which error on string operations.
local function plain(value)
	if value ~= nil and issecretvalue and issecretvalue(value) then
		return nil
	end
	return value
end

local function currentZone()
	local zone = plain(GetZoneText())
	if zone == "" then return nil end
	return zone
end

-------------------------------------------------------------------------------
-- Shared with the story menu
-------------------------------------------------------------------------------

function ns.GetDB()
	return db
end

function ns.PlayerName()
	return charKey
end

function ns.CharData()
	return char
end

ns.Plain = plain
ns.ChatType = CHAT_TYPE
ns.CurrentZone = currentZone

-- Sends a line unless the game is blocking addon chat. Returns whether it was sent.
function ns.SendLine(text, chatType)
	if C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown() then
		say("the game is blocking addon chat right now. Try again in a moment.")
		return false
	end
	C_ChatInfo.SendChatMessage(text, chatType)
	return true
end

-- Saves a frame's position in db[key] whenever it's dragged.
function ns.MakeDraggable(target, key)
	target:SetClampedToScreen(true)
	target:SetMovable(true)
	target:EnableMouse(true)
	target:RegisterForDrag("LeftButton")
	target:SetScript("OnDragStart", target.StartMoving)
	target:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local point, _, relativePoint, x, y = self:GetPoint()
		db[key] = { point = point, relativePoint = relativePoint, x = x, y = y }
	end)
end

function ns.PlaceFrame(target, key, ...)
	local position = db[key]
	if position then
		target:SetPoint(position.point, UIParent, position.relativePoint, position.x, position.y)
	else
		target:SetPoint(...)
	end
end

-- For small frames: dark, with a border in the bronze of the game's own windows.
function ns.ApplyBackdrop(target)
	target:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	target:SetBackdropColor(0.06, 0.05, 0.04, 0.96)
	target:SetBackdropBorderColor(0.72, 0.55, 0.32)
end

-- Plays one of the game's interface sounds. A client without that sound stays silent.
function ns.PlayUISound(name)
	local id = SOUNDKIT and SOUNDKIT[name]
	if id then
		PlaySound(id)
	end
end

-- Call this after a window's first Hide, so building it doesn't play the closing sound.
function ns.AddWindowSounds(frame)
	frame:HookScript("OnShow", function() ns.PlayUISound("IG_SPELLBOOK_OPEN") end)
	frame:HookScript("OnHide", function() ns.PlayUISound("IG_SPELLBOOK_CLOSE") end)
end

-- A full window in the game's own style: its border, title bar, round portrait, and
-- close button. If the client doesn't have that template, a plain frame stands in.
function ns.NewWindow(name, title, icon, width, height)
	local ok, frame = pcall(CreateFrame, "Frame", name, UIParent, "PortraitFrameTemplate")
	if ok and frame and frame.SetTitle then
		frame:SetTitle(title)
		if frame.SetPortraitToAsset then frame:SetPortraitToAsset(icon) end
	else
		frame = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
		ns.ApplyBackdrop(frame)
		local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		text:SetPoint("TOP", 0, -8)
		text:SetText(title)
		local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
		close:SetPoint("TOPRIGHT", -2, -2)
	end
	frame:SetSize(width, height)
	return frame
end

-- A recessed panel from the game, on its dark marble, to hold a list or a page.
function ns.NewInset(parent)
	local ok, inset = pcall(CreateFrame, "Frame", nil, parent, "InsetFrameTemplate")
	if not ok or not inset then
		inset = CreateFrame("Frame", nil, parent, "BackdropTemplate")
		ns.ApplyBackdrop(inset)
		return inset
	end
	if type(inset.Bg) == "table" and inset.Bg.SetTexture then
		inset.Bg:SetTexture("Interface\\FrameGeneral\\UI-Background-Marble", "REPEAT", "REPEAT")
		inset.Bg:SetHorizTile(true)
		inset.Bg:SetVertTile(true)
		inset.Bg:SetVertexColor(1, 1, 1, 1)
	end
	return inset
end

-- A quiet button for everything except the one main action.
function ns.MakeFlatButton(parent, label, width)
	-- The game's own quiet button, as its filter buttons use, where the client has it.
	local ok, native = pcall(CreateFrame, "Button", nil, parent, "UIMenuButtonStretchTemplate")
	if ok and native then
		native:SetSize(width, 22)
		native:SetNormalFontObject("GameFontHighlightSmall")
		native:SetDisabledFontObject("GameFontDisableSmall")
		native:SetText(label)
		return native
	end

	local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
	button:SetSize(width, 22)
	button:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Buttons\\WHITE8X8",
		edgeSize = 1,
	})
	button:SetBackdropColor(1, 1, 1, 0.05)
	button:SetBackdropBorderColor(0.72, 0.55, 0.32, 0.5)
	button:SetNormalFontObject("GameFontHighlightSmall")
	button:SetDisabledFontObject("GameFontDisableSmall")
	button:SetText(label)
	button:SetScript("OnEnter", function(self) self:SetBackdropColor(1, 1, 1, 0.14) end)
	button:SetScript("OnLeave", function(self) self:SetBackdropColor(1, 1, 1, 0.05) end)
	return button
end

-- Gold text marks a flat button as being on.
function ns.SetFlatButtonOn(button, on)
	button:SetNormalFontObject(on and "GameFontNormalSmall" or "GameFontHighlightSmall")
end

-------------------------------------------------------------------------------
-- Key bindings
-------------------------------------------------------------------------------

function FiresideTales_Speak()
	if ns.Story.IsOpen() then
		ns.Story.SpeakNext()
	end
end

function FiresideTales_ToggleStories()
	ns.Story.Toggle()
end

-------------------------------------------------------------------------------
-- Game events
-------------------------------------------------------------------------------

local handlers = {}

function handlers.ADDON_LOADED(name)
	if name ~= ADDON then return end
	FiresideTalesDB = FiresideTalesDB or {}
	db = FiresideTalesDB
	-- Settings and position of the old automatic prompts, which are gone.
	db.settings, db.position = nil, nil
	db.chars = db.chars or {}
	db.imported = db.imported or {} -- Stories from the Write My Story window.
end

function handlers.PLAYER_LOGIN()
	charKey = UnitName("player")
	-- Keeps only what's used now, which also clears any older data.
	local saved = db.chars[charKey] or {}
	char = {
		told = saved.told or {}, -- Story key to the time it was last finished.
		favorites = saved.favorites or {},
		tonight = saved.tonight or {}, -- Story keys, in telling order.
		about = saved.about, -- The player's description, for the Write My Story prompt.
	}
	db.chars[charKey] = char
	ns.BuildMinimapButton()
end

function handlers.ZONE_CHANGED_NEW_AREA()
	ns.Story.ZoneChanged()
end

local eventFrame = CreateFrame("Frame")
for event in pairs(handlers) do
	eventFrame:RegisterEvent(event)
end
eventFrame:SetScript("OnEvent", function(_, event, ...)
	-- Everything except the two startup events needs the character record.
	if char or event == "ADDON_LOADED" or event == "PLAYER_LOGIN" then
		handlers[event](...)
	end
end)

-------------------------------------------------------------------------------
-- Slash command and key binding labels
-------------------------------------------------------------------------------

BINDING_HEADER_FIRESIDETALES = "Fireside Tales"
BINDING_NAME_FIRESIDETALES_SPEAK = "Speak the next line"
BINDING_NAME_FIRESIDETALES_STORIES = "Open or close the story menu"

local function showStatus()
	say(("version %s. %s the %s %s: %d stories for you, %d pasted in across all characters."):format(
		ns.Version or "unknown",
		charKey,
		UnitRace("player"),
		UnitClass("player"),
		ns.Story.Count(),
		ns.Import.Count()
	))
end

SLASH_FIRESIDETALES1 = "/tales"
SlashCmdList.FIRESIDETALES = function(input)
	local command = (input or ""):lower():match("^%s*(%S*)")
	if command == "" or command == "stories" then
		ns.Story.Toggle()
	elseif command == "add" then
		ns.Import.Toggle()
	elseif command == "minimap" then
		ns.ToggleMinimapButton()
	elseif command == "fire" then
		if ns.Campfire.Toggle() then
			say("I'll offer a tale when you settle by a campfire.")
		else
			say("no more campfire prompts. /tales fire turns them back on.")
		end
	elseif command == "status" then
		showStatus()
	else
		say("/tales stories | add | fire | minimap | status")
	end
end
