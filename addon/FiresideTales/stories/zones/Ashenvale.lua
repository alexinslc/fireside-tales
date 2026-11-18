-- Stories told in Ashenvale.
local _, ns = ...

ns.AddStories("zone", "Ashenvale", {
	{
		title = "The Price of a Plank",
		mood = "dark",
		lines = {
			{ kind = "say", text = "There's a stretch of road in Ashenvale with lumber carts on one side and graves on the other. It's a pretty road, otherwise. Everything there is." },
			{ kind = "say", text = "Some of those graves have axes for markers. Some have arrows. Nobody's in much of a mood to tell you which is which." },
			{ kind = "emote", text = "takes a split log from the firewood, knocks twice on it, and listens to the sound." },
			{ kind = "say", text = "I counted, for something to do. I got to ninety before the trees closed in again." },
			{ kind = "say", text = "A while later, in a city a long way from there, I bought a shelf. I asked what the wood was. Fine Ashenvale timber, he said, and very cheap." },
			{ kind = "emote", text = "looks at the log in their hand, and sets it down beside the fire instead of on it." },
		},
	},
	{
		title = "The Third Arrow",
		mood = "action",
		lines = {
			{ kind = "say", text = "I crossed the woods of Ashenvale at night, which was my first mistake. An arrow hit the ground an inch from my left boot. No sound. It was just there." },
			{ kind = "emote", text = "holds one hand halfway raised, eyes moving slowly left and right." },
			{ kind = "say", text = "I took one step and the second arrow hit by my right heel. So I put my hands up and spoke to the trees. I said I was lost, and I meant it." },
			{ kind = "say", text = "Nothing, for the longest time. Only leaves. I never saw a shape. I never heard a breath." },
			{ kind = "say", text = "Then a third arrow landed ten paces away, flat along the ground, pointing east. I walked that way until morning, and I found the road." },
		},
	},
	{
		title = "The Light at Mystral Lake",
		mood = "heartfelt",
		lines = {
			{ kind = "say", text = "The autumn after I lost someone, I ended up at Mystral Lake without meaning to. I had no business there. I'd just stopped choosing roads." },
			{ kind = "say", text = "They say the wisps in Ashenvale linger near people who are grieving. I don't know. A little light came out over the water and settled by my knee." },
			{ kind = "emote", text = "cups their hands gently, as though holding something small and warm." },
			{ kind = "say", text = "I told it the whole thing, start to finish, things I'd not told the living. It didn't do anything. It only stayed." },
			{ kind = "say", text = "It was gone by sunrise, and I got up and found a road. I'd like to go back someday and tell it how things turned out." },
		},
	},
	{
		title = "Thanking the Trees",
		mood = "funny",
		lines = {
			{ kind = "say", text = "I dropped my kettle off a ridge in Ashenvale, and a root reached out and caught it by the handle. I thanked that tree. Very sincerely. At length." },
			{ kind = "say", text = "After that I thanked every tree I passed, just in case. It's a big forest. It slowed me down a good deal." },
			{ kind = "emote", text = "bows their head politely to the nearest log in the fire." },
			{ kind = "say", text = "A sentinel finally asked what I was doing. I told her. She looked at the tree, then at me, and said that root had been there three hundred years." },
			{ kind = "say", text = "Then she thanked it too. You can't be too careful." },
		},
	},
})
