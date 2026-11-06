-- Fireside Tales: offers in-character lines when things happen as you play.
-- Nothing is ever sent without a key press or click.
local ADDON, ns = ...

local CHAT_MAX_BYTES = 255
local PROMPT_SECONDS = 45
local RECENT_MAX = 8

-- Higher priority replaces a visible prompt and ignores the cooldown (from 2 up).
local PRIORITY = { zone_enter = 1, quest_done = 1, death = 2, level_up = 3 }
local CHAT_TYPE = { say = "SAY", emote = "EMOTE" }

local db, char, charKey
local pending -- { text, chatType, priority }
local promptToken = 0
local lastPromptAt = -math.huge
local awaitingRevival = false
local frame, textLabel, kindLabel

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
-- Choosing a line
-------------------------------------------------------------------------------

-- Returns the finished text, or nil when a placeholder has no value or the
-- result would not fit in one chat message.
local function formatLine(text, context)
	local result = text:gsub("{(%a+)}", function(key)
		local value = context[key]
		if value ~= nil then
			return (tostring(value):gsub("|", ""))
		end
	end)
	if result:find("{%a+}") or #result > CHAT_MAX_BYTES then
		return nil
	end
	return result
end

local function contains(list, value)
	for _, item in ipairs(list) do
		if item == value then return true end
	end
	return false
end

local function chooseLine(trigger, context)
	local recent = char.recent[trigger] or {}
	local usable, fresh = {}, {}
	for _, line in ipairs(ns.PromptLines[trigger] or {}) do
		local text = formatLine(line.text, context)
		if text then
			local candidate = { raw = line.text, text = text, chatType = CHAT_TYPE[line.kind] }
			usable[#usable + 1] = candidate
			if not contains(recent, line.text) then
				fresh[#fresh + 1] = candidate
			end
		end
	end
	local pool = #fresh > 0 and fresh or usable
	if #pool == 0 then
		return nil
	end
	local chosen = pool[math.random(#pool)]
	recent[#recent + 1] = chosen.raw
	while #recent > RECENT_MAX do
		table.remove(recent, 1)
	end
	char.recent[trigger] = recent
	return chosen
end

-------------------------------------------------------------------------------
-- Speak prompt
-------------------------------------------------------------------------------

local function hidePrompt()
	pending = nil
	promptToken = promptToken + 1
	if frame then frame:Hide() end
end
ns.HidePrompt = hidePrompt

local function showPrompt(trigger, context, force)
	if not char then return end
	if not force then
		-- Don't interrupt a story you're in the middle of telling.
		if not db.settings.enabled or ns.Story.IsOpen() then return end
		local priority = PRIORITY[trigger] or 1
		if pending and priority < pending.priority then return end
		if GetTime() - lastPromptAt < db.settings.cooldown and priority < 2 then return end
	end

	local line = chooseLine(trigger, context)
	if not line then return end

	pending = { text = line.text, chatType = line.chatType, priority = PRIORITY[trigger] or 1 }
	lastPromptAt = GetTime()
	promptToken = promptToken + 1
	local token = promptToken

	kindLabel:SetText(line.chatType == "EMOTE" and "Emote" or "Say")
	if line.chatType == "EMOTE" then
		textLabel:SetText(charKey .. " " .. line.text)
	else
		textLabel:SetText(line.text)
	end
	frame:SetHeight(textLabel:GetStringHeight() + 72)
	frame:Show()

	C_Timer.After(PROMPT_SECONDS, function()
		if token == promptToken then hidePrompt() end
	end)
end

local function speakPrompt()
	if pending and ns.SendLine(pending.text, pending.chatType) then
		hidePrompt()
	end
end

-- The key binding tells the open story; otherwise it answers the prompt.
function FiresideTales_Speak()
	if ns.Story.IsOpen() then
		ns.Story.SpeakNext()
	else
		speakPrompt()
	end
end

function FiresideTales_Skip()
	hidePrompt()
end

function FiresideTales_ToggleStories()
	ns.Story.Toggle()
end

local function makeButton(label, x, onClick)
	local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	button:SetSize(90, 22)
	button:SetPoint("BOTTOMRIGHT", x, 10)
	button:SetText(label)
	button:SetScript("OnClick", onClick)
	return button
end

local function buildFrame()
	frame = CreateFrame("Frame", "FiresideTalesFrame", UIParent, "BackdropTemplate")
	frame:SetSize(380, 110)
	ns.ApplyBackdrop(frame)
	ns.MakeDraggable(frame, "position")
	ns.PlaceFrame(frame, "position", "BOTTOM", UIParent, "BOTTOM", 0, 220)

	kindLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	kindLabel:SetPoint("TOPLEFT", 12, -10)

	textLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	textLabel:SetPoint("TOPLEFT", 12, -26)
	textLabel:SetWidth(356)
	textLabel:SetJustifyH("LEFT")
	textLabel:SetWordWrap(true)

	makeButton("Speak", -106, speakPrompt)
	makeButton("Skip", -12, hidePrompt)
	frame:Hide()
end

-------------------------------------------------------------------------------
-- Game events
-------------------------------------------------------------------------------

local handlers = {}

function handlers.ADDON_LOADED(name)
	if name ~= ADDON then return end
	FiresideTalesDB = FiresideTalesDB or {}
	db = FiresideTalesDB
	db.settings = db.settings or {}
	if db.settings.enabled == nil then db.settings.enabled = true end
	db.settings.cooldown = db.settings.cooldown or 30
	db.chars = db.chars or {}
	db.imported = db.imported or {} -- Stories from the Write My Story window.
	buildFrame()
end

function handlers.PLAYER_LOGIN()
	charKey = UnitName("player")
	-- Keeps only what's used now, which also clears any older journal data.
	local saved = db.chars[charKey] or {}
	char = {
		recent = saved.recent or {},
		lastZone = saved.lastZone,
		told = saved.told or {}, -- Story key to the time it was last finished.
		favorites = saved.favorites or {},
		tonight = saved.tonight or {}, -- Story keys, in telling order.
		about = saved.about, -- The player's description, for the Write My Story prompt.
	}
	db.chars[charKey] = char
	ns.BuildMinimapButton()
end

function handlers.PLAYER_ENTERING_WORLD(isInitialLogin)
	-- Arriving somewhere after a login or reload is not a story beat.
	if isInitialLogin or not char.lastZone then
		char.lastZone = currentZone() or char.lastZone
	end
end

function handlers.ZONE_CHANGED_NEW_AREA()
	ns.Story.ZoneChanged()
	local zone = currentZone()
	if not zone or zone == char.lastZone then return end
	char.lastZone = zone
	showPrompt("zone_enter", { zone = zone })
end

function handlers.QUEST_TURNED_IN(questID)
	showPrompt("quest_done", {
		quest = plain(C_QuestLog.GetTitleForQuestID(questID)),
		zone = currentZone(),
	})
end

function handlers.PLAYER_LEVEL_UP(level)
	showPrompt("level_up", { level = plain(level), zone = currentZone() })
end

function handlers.PLAYER_DEAD()
	awaitingRevival = true
end

-- Living players can't hear ghosts, so the line waits until you're back on your feet.
local function offerRevivalLine()
	C_Timer.After(1, function()
		if awaitingRevival and not UnitIsDeadOrGhost("player") then
			awaitingRevival = false
			showPrompt("death", { zone = currentZone() })
		end
	end)
end
handlers.PLAYER_ALIVE = offerRevivalLine
handlers.PLAYER_UNGHOST = offerRevivalLine

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
BINDING_NAME_FIRESIDETALES_SKIP = "Skip the offered line"
BINDING_NAME_FIRESIDETALES_STORIES = "Open or close the story menu"

local function showStatus()
	say(("%s the %s %s: prompts %s, cooldown %ds, %d stories for you, %d pasted in across all characters."):format(
		charKey,
		UnitRace("player"),
		UnitClass("player"),
		db.settings.enabled and "on" or "off",
		db.settings.cooldown,
		ns.Story.Count(),
		ns.Import.Count()
	))
end

SLASH_FIRESIDETALES1 = "/tales"
SlashCmdList.FIRESIDETALES = function(input)
	local command, argument = (input or ""):lower():match("^%s*(%S*)%s*(.-)%s*$")
	if command == "stories" then
		ns.Story.Toggle()
	elseif command == "add" then
		ns.Import.Toggle()
	elseif command == "minimap" then
		ns.ToggleMinimapButton()
	elseif command == "on" or command == "off" then
		db.settings.enabled = command == "on"
		showStatus()
	elseif command == "cooldown" and tonumber(argument) then
		db.settings.cooldown = math.max(0, tonumber(argument))
		showStatus()
	elseif command == "test" then
		local trigger = PRIORITY[argument] and argument or "zone_enter"
		showPrompt(trigger, {
			zone = currentZone() or "these lands",
			quest = "A Test of Nerve",
			level = plain(UnitLevel("player")),
		}, true)
	elseif command == "status" then
		showStatus()
	else
		say("/tales stories | add | minimap | on | off | status | cooldown <seconds> | test [zone_enter, quest_done, level_up, death]")
	end
end
