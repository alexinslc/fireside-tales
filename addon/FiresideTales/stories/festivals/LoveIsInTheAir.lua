-- Stories for Love is in the Air. The list's name matches the festival in
-- Seasons.lua, and its stories rise to the top while it's on.
local _, ns = ...

ns.AddStories("festival", "Love is in the Air", {
	{
		title = "The Irresistible Perfume",
		mood = "funny",
		lines = {
			{ kind = "say", text = "Love is in the Air, and a vendor sold me a perfume he promised was irresistible." },
			{ kind = "say", text = "It was. To every stray dog, cat, and boar between the city gates and the coast." },
			{ kind = "emote", text = "sniffs one wrist, winces, and wipes it on their knee." },
			{ kind = "say", text = "I spent the whole festival running from wild animals with flowers in their teeth." },
			{ kind = "say", text = "Then a farmer laughed so hard at me he fell off his fence. We've been friends ever since." },
			{ kind = "emote", text = "smiles into the fire." },
		},
	},
	{
		title = "The Letters I Never Send",
		mood = "heartfelt",
		lines = {
			{ kind = "say", text = "Every year when love is in the air, I write one letter. I never send it." },
			{ kind = "emote", text = "folds an invisible sheet of paper in half, then in half again." },
			{ kind = "say", text = "It's to someone I met on the road years ago. We shared a fire like this one, for one night." },
			{ kind = "say", text = "I never learned their name. They left before dawn, and took the road I didn't." },
			{ kind = "say", text = "So the letters pile up. Maybe one year I'll meet them at another fire and hand over the whole stack." },
			{ kind = "emote", text = "tucks the folded paper into a pocket, close to their heart." },
		},
	},
})
