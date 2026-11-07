-- Notices when you settle by a campfire and offers a story on the teller bar.
-- It asks once per fire, only after you've stood still a moment, never in combat
-- or partway through a story, and the offer goes away by itself. The game doesn't
-- tell addons whether you're sitting, so standing still by the fire stands in.
local _, ns = ...

local COZY_FIRE_SPELL = 7353 -- The buff a cooking fire gives everyone near it.
local COZY_FIRE_NAME = "Cozy Fire"
local STILL_SECONDS = 4
local QUIET_SECONDS = 10 * 60 -- However many fires get lit, at most one offer this often.

local hadFire = false
local asked = false -- Whether this fire has had its offer, or didn't need one.
local watching = false
local stillFor = 0
local lastOffer

ns.Campfire = {}

local function hasFire()
	if C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID
		and C_UnitAuras.GetPlayerAuraBySpellID(COZY_FIRE_SPELL) then
		return true
	end
	if AuraUtil and AuraUtil.FindAuraByName then
		return ns.Plain(AuraUtil.FindAuraByName(COZY_FIRE_NAME, "player")) ~= nil
	end
	return false
end

function ns.Campfire.IsOn()
	return ns.GetDB().fireOffers ~= false
end

function ns.Campfire.Toggle()
	ns.GetDB().fireOffers = not ns.Campfire.IsOn()
	if not ns.Campfire.IsOn() then ns.Story.EndOffer() end
	return ns.Campfire.IsOn()
end

-- Checks once a second while you're by a fire, until it has asked.
local function watch()
	if asked or not hasFire() then
		watching = false
		return
	end
	if GetUnitSpeed("player") > 0 then
		stillFor = 0
	else
		stillFor = stillFor + 1
	end

	if stillFor >= STILL_SECONDS and not UnitAffectingCombat("player") and not UnitIsDeadOrGhost("player") then
		asked = true
		local quiet = lastOffer and GetTime() - lastOffer < QUIET_SECONDS
		-- With the menu open or a story going, you're already telling one.
		if ns.Campfire.IsOn() and not quiet and not ns.Story.IsOpen() and ns.Story.Offer() then
			lastOffer = GetTime()
		end
		watching = false
		return
	end
	C_Timer.After(1, watch)
end

local function auraChanged(unit)
	if ns.Plain(unit) ~= "player" then return end
	local fire = hasFire()
	if fire and not hadFire then
		asked, stillFor = false, 0
		if not watching then
			watching = true
			C_Timer.After(1, watch)
		end
	elseif hadFire and not fire then
		ns.Story.EndOffer() -- You walked away, or the fire went out.
	end
	hadFire = fire
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(self, event, unit)
	if event == "PLAYER_LOGIN" then
		-- Core sets up the saved data on login, so start listening after that.
		self:RegisterEvent("UNIT_AURA")
		return
	end
	auraChanged(unit)
end)
