-- Stories for Hallow's End. The list's name matches the festival in
-- Seasons.lua, and its stories rise to the top while it's on.
local _, ns = ...

ns.AddStories("festival", "Hallow's End", {
	{
		title = "Trick, Not Treat",
		mood = "funny",
		lines = {
			{ kind = "say", text = "On Hallow's End I asked an innkeeper for a treat. She smiled and said, how about a trick instead?" },
			{ kind = "emote", text = "pats their own face and arms, as if checking they're all still there." },
			{ kind = "say", text = "I walked out of that inn a skeleton. Bones and all. My own horse wouldn't come near me." },
			{ kind = "say", text = "So I went back for another try. She made me a pirate. Then a bat. Then a pirate again." },
			{ kind = "say", text = "By midnight I'd been everything in the book, and I still hadn't had a single piece of candy." },
			{ kind = "emote", text = "holds out an empty palm toward the fire, hopefully." },
		},
	},
	{
		title = "Why We Light the Fires",
		mood = "wise",
		lines = {
			{ kind = "say", text = "Do you know what Hallow's End is really for? It started with the Forsaken." },
			{ kind = "say", text = "It marks the night they broke free of the Lich King's voice, and found their thoughts were their own again." },
			{ kind = "emote", text = "taps two fingers slowly against their temple." },
			{ kind = "say", text = "Folk dress up as monsters now and laugh about it. But the first Hallow's End was no joke." },
			{ kind = "say", text = "It was a people learning they could choose again. So I choose candy. And a good fire." },
			{ kind = "emote", text = "leans back and stretches both hands toward the warmth." },
		},
	},
	{
		title = "The Pumpkin on the Wall",
		mood = "spooky",
		lines = {
			{ kind = "say", text = "Every Hallow's End, somebody carves a pumpkin and sets it on the old wall outside town." },
			{ kind = "say", text = "One year I asked around, to thank whoever it was. Nobody knew. Nobody had ever known." },
			{ kind = "emote", text = "draws a slow, grinning face in the air with one finger." },
			{ kind = "say", text = "So I waited up. Midnight came, and the wall was bare. I looked down to rub my eyes." },
			{ kind = "say", text = "When I looked up, there it was. Lit. Grinning. And still warm when I touched it." },
			{ kind = "emote", text = "pulls their hand back from the fire quickly." },
		},
	},
})
