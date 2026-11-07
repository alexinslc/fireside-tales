-- A book icon on the minimap: click to open the story menu, drag to move it.
local _, ns = ...

local DEFAULT_ANGLE = 225
local EDGE_OFFSET = 5

local button

local function place(angle)
	local radians = math.rad(angle)
	local x = math.cos(radians) * (Minimap:GetWidth() / 2 + EDGE_OFFSET)
	local y = math.sin(radians) * (Minimap:GetHeight() / 2 + EDGE_OFFSET)
	button:ClearAllPoints()
	button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function followCursor()
	local centerX, centerY = Minimap:GetCenter()
	local cursorX, cursorY = GetCursorPosition()
	local scale = Minimap:GetEffectiveScale()
	local angle = math.deg(math.atan2(cursorY / scale - centerY, cursorX / scale - centerX)) % 360
	ns.GetDB().minimapAngle = angle
	place(angle)
end

local function applyVisibility()
	button:SetShown(not ns.GetDB().minimapHidden)
end

function ns.BuildMinimapButton()
	button = CreateFrame("Button", "FiresideTalesMinimapButton", Minimap)
	button:SetFrameStrata("MEDIUM")
	button:SetFrameLevel(8)
	button:SetSize(31, 31)
	button:RegisterForDrag("LeftButton")
	button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

	-- The same gold ring as every other minimap button, with the round icon inside it.
	local border = button:CreateTexture(nil, "OVERLAY")
	border:SetSize(53, 53)
	border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	border:SetPoint("TOPLEFT")

	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetSize(20, 20)
	icon:SetTexture("Interface\\AddOns\\FiresideTales\\Textures\\MinimapIcon")
	icon:SetPoint("TOPLEFT", 6, -6)

	button:SetScript("OnClick", ns.Story.Toggle)
	button:SetScript("OnDragStart", function(self)
		GameTooltip:Hide()
		self:SetScript("OnUpdate", followCursor)
	end)
	button:SetScript("OnDragStop", function(self)
		self:SetScript("OnUpdate", nil)
	end)
	button:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:AddLine("Fireside Tales")
		GameTooltip:AddLine("Click to open your stories. Drag to move this button.", 1, 1, 1, true)
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	place(ns.GetDB().minimapAngle or DEFAULT_ANGLE)
	applyVisibility()
end

function ns.ToggleMinimapButton()
	local db = ns.GetDB()
	db.minimapHidden = not db.minimapHidden
	applyVisibility()
end
