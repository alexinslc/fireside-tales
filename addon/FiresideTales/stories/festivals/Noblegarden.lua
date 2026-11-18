-- Stories for Noblegarden. The list's name matches the festival in
-- Seasons.lua, and its stories rise to the top while it's on.
local _, ns = ...

ns.AddStories("festival", "Noblegarden", {
	{
		title = "The Egg Hunt",
		mood = "funny",
		lines = {
			{ kind = "say", text = "Noblegarden. Painted eggs hidden all over town, and every child in the valley out hunting them." },
			{ kind = "say", text = "I thought I'd join in. I'm a seasoned adventurer. I've tracked beasts across mountains." },
			{ kind = "emote", text = "shades their eyes with one hand and peers around the fire." },
			{ kind = "say", text = "Two hours later a little girl had forty eggs. I had one, and it was a rock somebody painted." },
			{ kind = "say", text = "She felt so sorry for me she gave me a chocolate. I'm not too proud to say I took it." },
			{ kind = "emote", text = "pops something imaginary into their mouth and chews happily." },
		},
	},
	{
		title = "The Egg Nobody Finds",
		mood = "spooky",
		lines = {
			{ kind = "say", text = "Every Noblegarden, there's one egg nobody finds. I found it once, under an old stone bridge." },
			{ kind = "say", text = "It wasn't painted like the others. It was black, with silver lines running through it like veins." },
			{ kind = "emote", text = "holds out cupped hands, very still." },
			{ kind = "say", text = "It was warm. And while I held it, something inside tapped back." },
			{ kind = "say", text = "I put it right back where I found it. Some eggs aren't meant for baskets." },
			{ kind = "emote", text = "slowly lowers their hands and wipes them on their knees." },
		},
	},
})
