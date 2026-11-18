-- Stories for Lunar Festival. The list's name matches the festival in
-- Seasons.lua, and its stories rise to the top while it's on.
local _, ns = ...

ns.AddStories("festival", "Lunar Festival", {
	{
		title = "The Elder on the Hill",
		mood = "heartfelt",
		lines = {
			{ kind = "say", text = "During the Lunar Festival, the elders come back. You'll find them standing in the oddest places." },
			{ kind = "say", text = "I found one on a lonely hill, looking out over nothing. I bowed and asked what he was watching." },
			{ kind = "emote", text = "bows their head toward the fire." },
			{ kind = "say", text = "He said, the road my grandchildren will walk. Then he pressed a coin into my hand and was gone." },
			{ kind = "say", text = "The coin bore my family's mark. I'd never told him my name." },
			{ kind = "emote", text = "rubs an invisible coin between finger and thumb." },
		},
	},
	{
		title = "The Biggest Firework in Moonglade",
		mood = "funny",
		lines = {
			{ kind = "say", text = "At the Lunar Festival, a goblin sold me what he swore was the biggest firework in Moonglade." },
			{ kind = "say", text = "Light it, step back, and look up, he said. So I lit it, stepped back, and looked up." },
			{ kind = "emote", text = "tilts their head back and stares at the sky." },
			{ kind = "say", text = "It went sideways. Through a tent, across the lake, and straight into a druid's beard." },
			{ kind = "say", text = "The druid didn't say a word. He just turned into a bear and sat down on the goblin's stall." },
			{ kind = "emote", text = "laughs quietly into one hand." },
		},
	},
})
