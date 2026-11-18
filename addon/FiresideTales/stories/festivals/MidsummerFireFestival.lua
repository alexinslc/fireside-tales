-- Stories for Midsummer Fire Festival. The list's name matches the festival in
-- Seasons.lua, and its stories rise to the top while it's on.
local _, ns = ...

ns.AddStories("festival", "Midsummer Fire Festival", {
	{
		title = "Big Fires and Small Ones",
		mood = "wise",
		lines = {
			{ kind = "say", text = "At Midsummer, every town lights a bonfire taller than a house. This little one's my favorite, though." },
			{ kind = "emote", text = "nudges a log deeper into the coals." },
			{ kind = "say", text = "The keeper of one of those great bonfires told me the big fires are for the world." },
			{ kind = "say", text = "But the small ones, the ones you build yourself on the road, those are for the people sitting by them." },
			{ kind = "say", text = "So happy Midsummer. This one's for us." },
			{ kind = "emote", text = "holds both hands out toward the flames." },
		},
	},
	{
		title = "Stealing the Flame",
		mood = "funny",
		lines = {
			{ kind = "say", text = "At Midsummer, folk try to steal a flame from the other side's bonfire. Don't ask me why. It's tradition." },
			{ kind = "say", text = "I tried it once. Crept in at night with a torch, quiet as a cat." },
			{ kind = "emote", text = "hunches low and moves their hands slowly, as if sneaking." },
			{ kind = "say", text = "I lit the torch, turned around, and found the keeper standing there. Holding a bucket." },
			{ kind = "say", text = "She doused me, the torch, and my pride all in one go. Then she offered me a cup of tea." },
			{ kind = "emote", text = "wrings out the hem of one sleeve, laughing." },
		},
	},
})
