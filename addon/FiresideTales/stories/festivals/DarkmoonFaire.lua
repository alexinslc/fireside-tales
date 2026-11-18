-- Stories for Darkmoon Faire. The list's name matches the festival in
-- Seasons.lua, and its stories rise to the top while it's on.
local _, ns = ...

ns.AddStories("festival", "Darkmoon Faire", {
	{
		title = "The Fortune Teller",
		mood = "wise",
		lines = {
			{ kind = "emote", text = "holds one open palm out toward the fire, as if to have it read." },
			{ kind = "say", text = "At the Darkmoon Faire, a fortune teller asked me five questions and wouldn't say why." },
			{ kind = "say", text = "Would I steal bread for a starving friend? Would I tell a king a hard truth? That sort of thing." },
			{ kind = "say", text = "At the end she smiled and said my answers had already told my fortune. I just hadn't heard it yet." },
			{ kind = "emote", text = "closes the hand slowly and rests it on one knee." },
			{ kind = "say", text = "I still think about the one about the king. I'm still not sure I answered it honestly." },
		},
	},
	{
		title = "The Lucky Frog",
		mood = "funny",
		lines = {
			{ kind = "say", text = "Never buy a frog from a boy at the Darkmoon Faire. I say this as someone who did." },
			{ kind = "say", text = "He swore it was lucky. It could tell fortunes, he said, if you asked it nicely." },
			{ kind = "emote", text = "cups both hands together as if holding something small and damp." },
			{ kind = "say", text = "I asked it nicely for three days. It told me nothing. Then it ate my best fishing lure." },
			{ kind = "say", text = "Next month I went back to complain, and the boy sold me a second frog to keep the first one company." },
			{ kind = "emote", text = "sighs and shakes their head at the fire." },
		},
	},
	{
		title = "The Tonk Duel",
		mood = "action",
		lines = {
			{ kind = "say", text = "At the faire there's a game where you steer a little clockwork tank with a box of levers." },
			{ kind = "emote", text = "grips an imaginary set of levers and jerks them left and right." },
			{ kind = "say", text = "I was one dent from losing. The other fellow's tonk was chasing mine round and round a barrel." },
			{ kind = "say", text = "So I stopped. Just stopped. His tonk shot straight past, hit the barrel, and fell over." },
			{ kind = "emote", text = "lets go of the levers and raises both hands, grinning." },
			{ kind = "say", text = "The carnie gave me a prize ticket and asked me never to come back. Best win I ever had." },
		},
	},
	{
		title = "How the Faire Arrives",
		mood = "spooky",
		lines = {
			{ kind = "say", text = "Have you ever seen the Darkmoon Faire arrive? Nobody has. I tried once." },
			{ kind = "say", text = "I sat up all night on a hill above the field. Empty grass. Not a wagon in sight." },
			{ kind = "emote", text = "stares hard into the dark beyond the fire, without blinking." },
			{ kind = "say", text = "Near dawn I blinked. Just once. And there it was. Tents, flags, music already playing." },
			{ kind = "say", text = "A man in a tall hat waved to me from the gate, like he'd known I was watching all along." },
			{ kind = "emote", text = "tips an imaginary hat toward the darkness." },
		},
	},
	{
		title = "One Prize Ticket",
		mood = "heartfelt",
		lines = {
			{ kind = "say", text = "My first time at the faire, I spent every copper I had and won exactly one prize ticket." },
			{ kind = "emote", text = "holds up a thumb and finger, pinching something thin and small." },
			{ kind = "say", text = "One ticket buys nothing. I stood by the prize table anyway, just looking." },
			{ kind = "say", text = "A little girl beside me had one ticket too. Together, the carnie said, we could buy one paper flower." },
			{ kind = "say", text = "So we did, and then we argued for an hour over who got to keep it." },
			{ kind = "emote", text = "smiles at the fire." },
			{ kind = "say", text = "She won. I still think that was fair." },
		},
	},
	{
		title = "The Eighth Card",
		mood = "heartfelt",
		lines = {
			{ kind = "say", text = "Ever tried to finish a Darkmoon deck? Eight cards. I had seven within a year." },
			{ kind = "emote", text = "fans out an invisible hand of cards and counts them twice." },
			{ kind = "say", text = "The eighth never turned up. I traded for it, begged for it, nearly bought a fake from a goblin." },
			{ kind = "say", text = "Then an old friend passed, and their pack came to me. At the bottom, wrapped in a letter, was the eighth card." },
			{ kind = "say", text = "The letter just said: you were always one short. Now you're not." },
			{ kind = "emote", text = "gathers the invisible cards together and holds them against their chest." },
		},
	},
	{
		title = "The Shell Game",
		mood = "funny",
		lines = {
			{ kind = "say", text = "A carnie at the Darkmoon Faire bet me a silver I couldn't find the pea under his three cups." },
			{ kind = "emote", text = "slides three invisible cups around on the ground, fast." },
			{ kind = "say", text = "I watched like a hawk. Pointed at the middle one. He lifted it. Empty." },
			{ kind = "say", text = "The left one, empty. The right one, empty too." },
			{ kind = "say", text = "Where's the pea, I asked. He grinned and said, what pea? That's a different game. Two silver." },
			{ kind = "emote", text = "throws up their hands and laughs at the fire." },
		},
	},
	{
		title = "When the Faire Leaves",
		mood = "heartfelt",
		lines = {
			{ kind = "say", text = "The saddest morning of the month is the one after the Darkmoon Faire leaves." },
			{ kind = "say", text = "You walk out to the field, and it's just grass again, flattened in big circles where the tents stood." },
			{ kind = "emote", text = "smooths a patch of ground flat with the palm of one hand." },
			{ kind = "say", text = "One year I found a paper flower left behind in the grass. Bent, a bit muddy." },
			{ kind = "say", text = "I kept it. It's in my pack still. A promise, I suppose, that the faire always comes back." },
			{ kind = "emote", text = "pats their pack gently." },
		},
	},
})
