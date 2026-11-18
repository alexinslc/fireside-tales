-- Stories told in Stormwind City.
local _, ns = ...

ns.AddStories("zone", "Stormwind City", {
	{
		title = "The Fishmonger's Stool",
		mood = "funny",
		lines = {
			{ kind = "say", text = "The first time I visited Stormwind, I tried to find the Trade District by following the canals. Do not do this." },
			{ kind = "say", text = "Every bridge looks like the last bridge. I asked one fishmonger for directions, thanked him, walked for an hour, and asked him again." },
			{ kind = "emote", text = "points left, then right, then gives their own hand a puzzled look." },
			{ kind = "say", text = "By the third day he'd set out a stool for me. By the fifth he'd stopped giving directions and started asking about my family." },
			{ kind = "say", text = "I went to his daughter's wedding in the end. Never did find the Trade District." },
		},
	},
	{
		title = "The Mason's Mark",
		mood = "heartfelt",
		lines = {
			{ kind = "emote", text = "runs a hand low through the air, near the knee, as if along an old wall." },
			{ kind = "say", text = "An old mason in Stormwind told me every stone in those white walls has somebody's mark on it, if you know where to look." },
			{ kind = "say", text = "Mostly they're up high, where the master could see them. Proper work, proper pride." },
			{ kind = "say", text = "He showed me his own, then crouched, knees cracking, and showed me a small crooked one by the ground. A child could have reached it." },
			{ kind = "say", text = "He didn't say whose it was. He only brushed the dust off it, the way you'd straighten a collar, and walked on." },
		},
	},
	{
		title = "The Shop Bell",
		mood = "spooky",
		lines = {
			{ kind = "say", text = "Every morning in Stormwind, I passed a shuttered shop in the Trade District, and every morning its doorbell rang inside, as if someone had just come in." },
			{ kind = "say", text = "I thought someone must have bought the place. Weeks went by. The shutters stayed shut, and the bell kept ringing, right at opening time." },
			{ kind = "emote", text = "lifts one finger and gives a tiny invisible bell a single tap." },
			{ kind = "say", text = "I asked the baker next door. She said the old clockmaker who had it never once missed opening, and he wasn't about to start now." },
			{ kind = "say", text = "She leaves a loaf on his step every morning. By noon, it's gone." },
		},
	},
	{
		title = "The Canal Barrel",
		mood = "action",
		lines = {
			{ kind = "say", text = "A boy fell into the canal in Stormwind, by the Trade District, where the water runs deep and fast toward the harbor. He couldn't swim. Neither could I." },
			{ kind = "say", text = "There was a fish seller nearby with an empty barrel. I didn't ask. I tipped it out, fish and all, and rolled it into the water." },
			{ kind = "emote", text = "shoves something round forward with both hands, then grips the air tight." },
			{ kind = "say", text = "The barrel floated down to him, and he grabbed it and held on. We ran along the bank and fished him out at the next bridge with a mop handle." },
			{ kind = "say", text = "The fish seller was furious about the fish. Then the boy's mother turned out to be his best customer. He gave me a free herring." },
		},
	},
	{
		title = "The Cathedral Stone",
		mood = "wise",
		lines = {
			{ kind = "say", text = "I once watched a mason in Stormwind spend a whole day carving one stone for the Cathedral. Leaves, vines, a tiny bird. It was beautiful." },
			{ kind = "say", text = "Then she set it in the wall facing inward, carving and all, where no one would ever see it again." },
			{ kind = "emote", text = "turns one hand over slowly, palm down, and lays it flat." },
			{ kind = "say", text = "I asked what the point was. She said the stone knows. And so does the next mason who takes that wall apart, a hundred years from now." },
			{ kind = "say", text = "I've done a lot of work since that nobody saw. I don't mind it the way I used to. I like to think somebody will find it, eventually." },
		},
	},
})
