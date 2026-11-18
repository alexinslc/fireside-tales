-- Stories for Harvest Festival. The list's name matches the festival in
-- Seasons.lua, and its stories rise to the top while it's on.
local _, ns = ...

ns.AddStories("festival", "Harvest Festival", {
	{
		title = "The Empty Chairs",
		mood = "heartfelt",
		lines = {
			{ kind = "say", text = "At the Harvest Festival they set out a great feast, and they always leave a few chairs empty." },
			{ kind = "say", text = "For the fallen, they say. The heroes who never came home from the war." },
			{ kind = "emote", text = "pats the empty ground beside them." },
			{ kind = "say", text = "I used to think that was sad. Then an old soldier told me otherwise." },
			{ kind = "say", text = "He said an empty chair isn't a missing person. It's a promise there's still room for them." },
			{ kind = "emote", text = "shifts over a little, leaving space by the fire as if for someone else." },
		},
	},
	{
		title = "Two Graves, One Harvest",
		mood = "wise",
		lines = {
			{ kind = "say", text = "The Harvest Festival honors two heroes. The Alliance remembers a paladin, and the Horde an orc." },
			{ kind = "say", text = "I've stood where each of them lies. One on a quiet hill, one in a canyon that still smells of smoke." },
			{ kind = "emote", text = "lays one hand flat on the ground, then the other beside it." },
			{ kind = "say", text = "The flowers left at both are the same. Wildflowers, picked on the road by tired travelers." },
			{ kind = "say", text = "Whatever side you're on, I think the dead would rather we shared the harvest than argued over it." },
			{ kind = "emote", text = "breaks an imaginary loaf in half and holds one piece out across the fire." },
		},
	},
})
