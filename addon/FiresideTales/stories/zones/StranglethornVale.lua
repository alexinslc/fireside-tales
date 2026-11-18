-- Stories told in Stranglethorn Vale.
local _, ns = ...

ns.AddStories("zone", "Stranglethorn Vale", {
	{
		title = "The Booty Bay Invoice",
		mood = "funny",
		lines = {
			{ kind = "say", text = "I stepped off a boat in Booty Bay and a goblin handed me a bill. Docking fee. I said I don't own a boat. He said, you were on one." },
			{ kind = "say", text = "Then there was a fee for the plank, and a fee for asking about the fee. So I stepped back to argue and fell into the harbor." },
			{ kind = "emote", text = "pats their pockets, then turns one inside out." },
			{ kind = "say", text = "You've heard about the sharks there. A crew fished me out before I'd finished screaming, and I was very grateful, for about a minute." },
			{ kind = "say", text = "Rescue fee. Salvage fee, since they'd technically recovered me. And a storage charge for the time I spent thanking them on the dock." },
		},
	},
	{
		title = "Into the Arena",
		mood = "action",
		lines = {
			{ kind = "say", text = "Raptors don't chase you in a straight line. Two ran me down the coast path in Stranglethorn while a third cut through the ferns ahead of me." },
			{ kind = "say", text = "I saw old stone walls, an open gate, and went through it at a full sprint without asking what it was for." },
			{ kind = "emote", text = "throws both arms up as if in front of a roaring crowd." },
			{ kind = "say", text = "It was the Gurubashi Arena, in the middle of a brawl. Everybody stopped. Then the raptors came through the gate behind me, and the crowd went mad." },
			{ kind = "say", text = "I don't remember all of it. I remember climbing a fellow's shoulders. Someone made a fortune betting on me that day, and I'd still like to know who." },
		},
	},
	{
		title = "Four Days",
		mood = "dark",
		lines = {
			{ kind = "emote", text = "brushes their own sleeve, then looks at their fingertips a moment too long." },
			{ kind = "say", text = "We found a camp in the deep jungle of Stranglethorn. Tents, cook pot, bedrolls, and every bit of it grown through with green." },
			{ kind = "say", text = "Vines through the canvas. Vines through the boots. A tree root thick as my wrist, right through the middle of a bedroll." },
			{ kind = "say", text = "We figured it had been there ten years, maybe twenty. Then we found the journal, and read the last page, and checked the date." },
			{ kind = "say", text = "Four days. We didn't camp that night. We walked until we hit the road, and nobody sat down, not even to fix a boot." },
		},
	},
	{
		title = "Sold in Booty Bay",
		mood = "funny",
		lines = {
			{ kind = "say", text = "I told a crowd in Booty Bay about the time I escaped a raptor. A goblin offered me a silver for the story. I took it before he could change his mind." },
			{ kind = "say", text = "A week later I heard my story told in the same tavern, by him, with a bigger raptor. And he was charging admission." },
			{ kind = "emote", text = "spreads their hands wider and wider apart, as if measuring a raptor that keeps growing." },
			{ kind = "say", text = "I stood up and said that was my story. He said it was his now, he had a receipt, and would I like to buy it back at the current price." },
			{ kind = "say", text = "Ten silver. I paid it, too. His version's much better than mine." },
		},
	},
})
