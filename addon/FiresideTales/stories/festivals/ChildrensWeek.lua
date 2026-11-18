-- Stories for Children's Week. The list's name matches the festival in
-- Seasons.lua, and its stories rise to the top while it's on.
local _, ns = ...

ns.AddStories("festival", "Children's Week", {
	{
		title = "The Dragon in the Clouds",
		mood = "heartfelt",
		lines = {
			{ kind = "say", text = "One Children's Week, I took an orphan out of the city. I asked what she wanted to see most." },
			{ kind = "say", text = "A dragon, she said. A real one. I told her that was a terrible idea. She asked again every hour." },
			{ kind = "emote", text = "rubs the back of their neck, sheepish." },
			{ kind = "say", text = "On the last day we sat on a high cliff and watched the sky until sunset. Nothing came." },
			{ kind = "say", text = "Then she pointed at a cloud and said, there, that one's a dragon. And it was, a little." },
			{ kind = "emote", text = "traces a long, winding shape across the sky with one finger." },
		},
	},
	{
		title = "A Week of Questions",
		mood = "funny",
		lines = {
			{ kind = "say", text = "Children's Week, I took an orphan along for a few days. Nobody warned me about the questions." },
			{ kind = "say", text = "Why is grass green. Why do murlocs smell. Why don't you have a house. Why is your sword chipped." },
			{ kind = "emote", text = "counts the questions off on their fingers and runs out of fingers." },
			{ kind = "say", text = "By the third day I'd told him every story I knew, and made up four more." },
			{ kind = "say", text = "When I brought him back, he told the matron I was the wisest person in the whole world." },
			{ kind = "emote", text = "puffs out their chest proudly, then lets it sag." },
			{ kind = "say", text = "I am not. But I'll take it." },
		},
	},
})
