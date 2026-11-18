-- Stories told in Duskwood.
local _, ns = ...

ns.AddStories("zone", "Duskwood", {
	{
		title = "Stay There",
		mood = "spooky",
		lines = {
			{ kind = "say", text = "First thing they tell you in Darkshire: if something in the trees calls your name, you don't answer it. I thought that was just a thing to scare visitors." },
			{ kind = "say", text = "Three nights in, walking back from Raven Hill, I heard my name. It came from off the road, and it was my mother's voice." },
			{ kind = "emote", text = "stops talking and holds very still for a moment." },
			{ kind = "say", text = "She's been in the ground twelve years, which is the only reason I kept my feet on the road. I stood there with my heart going, not answering." },
			{ kind = "say", text = "And then, very softly, from a good deal closer, the same voice said, that's right. Stay there." },
			{ kind = "emote", text = "looks past the firelight at the black trees, and very carefully does not answer them." },
		},
	},
	{
		title = "The One About the Goat",
		mood = "funny",
		lines = {
			{ kind = "say", text = "I told a joke at the Scarlet Raven Tavern in Darkshire. It's a good joke. It's got a goat in it." },
			{ kind = "emote", text = "stares blankly ahead, imitating a whole room of unamused faces." },
			{ kind = "say", text = "Nothing. Not a cough. Somebody in the corner sighed, though I think that was about something else." },
			{ kind = "say", text = "I left the next morning. Three days down the road, I hear boots behind me, and here comes a fellow from the tavern, out of breath." },
			{ kind = "say", text = "He grabs my arm and says, the goat. It was the goat all along! He laughs till he cries, turns around, and walks back into the dark." },
		},
	},
	{
		title = "Walking Them Home",
		mood = "heartfelt",
		lines = {
			{ kind = "say", text = "There's an old gravedigger who works Raven Hill Cemetery, and you'll know what I mean when I say the dead there don't always stay put." },
			{ kind = "say", text = "I saw him one evening, leading something slow and stumbling back through the gate by its sleeve, talking to it quietly." },
			{ kind = "emote", text = "holds out one hand as if guiding someone frail across a road." },
			{ kind = "say", text = "I asked if he wasn't afraid. He said he'd buried most of them himself. They weren't wicked, he said. They'd only forgotten where they live." },
			{ kind = "say", text = "He tucked the earth back down and patted it, then went to see who else was up." },
		},
	},
	{
		title = "The Cheap Candles",
		mood = "funny",
		lines = {
			{ kind = "say", text = "I bought the cheapest candles in Darkshire. The seller warned me they smoked. I said I only needed them to see by." },
			{ kind = "say", text = "They smoked, all right. Black smoke, thick as wool. But I'll tell you something: nothing in Duskwood came near my camp all week." },
			{ kind = "emote", text = "waves a hand in front of their face and coughs politely." },
			{ kind = "say", text = "I went back for more. He'd put the price up. Turns out half the town buys them, and nobody lights them indoors." },
		},
	},
})
