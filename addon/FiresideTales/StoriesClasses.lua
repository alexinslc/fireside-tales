-- Stories chosen automatically by class, keyed by the class token from UnitClass.
local _, ns = ...

ns.ClassStories = {
	WARRIOR = {
		{
			title = "The Sergeant's Lesson",
			mood = "wise",
			lines = {
				{ kind = "say", text = "My old sergeant had one lesson. Day one, she knocked me down. Then she asked me what I'd learned." },
				{ kind = "say", text = "I said, keep your guard up. She knocked me down again. Day two, the same thing. For a month." },
				{ kind = "emote", text = "rolls one shoulder, as if the bruise still aches." },
				{ kind = "say", text = "Finally I just got up without saying anything. She nodded and said, there it is. That's the whole trade." },
			},
		},
		{
			title = "Notches",
			mood = "dark",
			lines = {
				{ kind = "emote", text = "runs a thumb along the nicks in their blade." },
				{ kind = "say", text = "Young soldiers like to cut a notch for every fight they've won. I did too, for a while." },
				{ kind = "say", text = "Then I met an old veteran whose blade was smooth as glass. I asked if he'd seen no action. He laughed." },
				{ kind = "say", text = "He said, I sharpen them out every night. I won't carry those fellows around with me. Some nights I wish I'd learned that sooner." },
				{ kind = "emote", text = "turns the blade so the firelight slides along its edge, and looks at it for a while." },
			},
		},
	},
	PALADIN = {
		{
			title = "The Weight of the Light",
			mood = "dark",
			lines = {
				{ kind = "say", text = "Folk think the Light makes everything simple. You know what's wrong, and you strike it down. Very tidy." },
				{ kind = "emote", text = "lowers their head and rests both hands on their weapon." },
				{ kind = "say", text = "It's the opposite, friend. The Light shows you everything. Including all the things you'd prefer not to see." },
				{ kind = "say", text = "Armor's the lighter burden. I'd wear twice as much, if I could only stop seeing clearly." },
			},
		},
		{
			title = "Sworn at Dawn",
			mood = "wise",
			lines = {
				{ kind = "say", text = "We keep vigil the night before we take the oath. Alone, kneeling, on cold stone until sunrise." },
				{ kind = "say", text = "I expected visions. Golden light and a voice from above. Mostly, my knees hurt and I needed to relieve myself." },
				{ kind = "emote", text = "smiles to themselves." },
				{ kind = "say", text = "But I stayed. Dawn came up, and nothing had happened, and I took the oath anyway. I've come to think that was the point." },
			},
		},
	},
	HUNTER = {
		{
			title = "My Better Half",
			mood = "funny",
			lines = {
				{ kind = "emote", text = "scratches an imaginary companion behind the ears." },
				{ kind = "say", text = "People ask me how I tamed this beast. I didn't. We came to an arrangement." },
				{ kind = "say", text = "I bring the arrows and the plan. It brings the teeth, and judges the plan, and generally improves on it." },
				{ kind = "say", text = "Every morning, it gets fed first. I've seen what happens otherwise, and so have my boots." },
			},
		},
		{
			title = "Tracks Don't Lie",
			mood = "funny",
			lines = {
				{ kind = "say", text = "A person can lie to you all day, but their tracks can't. Show me where you've walked, and I'll tell you who you are." },
				{ kind = "say", text = "I once followed a so-called fearless knight for two days. He'd told the whole inn about the monster he'd slain." },
				{ kind = "emote", text = "leans down and studies the ground, then glances up, smirking." },
				{ kind = "say", text = "The tracks went up to the cave, stopped, and then ran the other way. I never told a soul. Well. I'm telling you." },
			},
		},
	},
	ROGUE = {
		{
			title = "Honest Work",
			mood = "funny",
			lines = {
				{ kind = "say", text = "I tried honest work once. A whole week as a clerk. Very respectable." },
				{ kind = "emote", text = "absently flips a coin across their knuckles." },
				{ kind = "say", text = "By the end of the week, I'd found out how much my employer was stealing. It was astonishing. I had no idea you could do it with paperwork." },
				{ kind = "say", text = "So I took that money back, on behalf of the public. And some of the paper. Nice paper. Purely an educational experience." },
			},
		},
		{
			title = "The Shadow's Rule",
			mood = "funny",
			lines = {
				{ kind = "say", text = "First rule of my trade: nobody ever remembers the plain one. Learn to be dull. It's the finest cloak there is." },
				{ kind = "say", text = "I spent a whole year as a servant at a nobleman's house. He spoke to me daily, and never once learned my name." },
				{ kind = "emote", text = "smiles thinly and looks away, shifting so the firelight doesn't quite reach their face." },
				{ kind = "say", text = "When the guards asked him to describe the thief, he said it must have been a professional. Tall. Scarred. Very menacing." },
			},
		},
	},
	PRIEST = {
		{
			title = "A Sermon for the Hungry",
			mood = "heartfelt",
			lines = {
				{ kind = "say", text = "My first sermon was three hours long. I'd worked on it for months. There was hardly anyone left at the end." },
				{ kind = "say", text = "A woman at the back told me it was very nice, but her children hadn't eaten since yesterday." },
				{ kind = "emote", text = "bows their head with a small, rueful smile." },
				{ kind = "say", text = "My sermons are shorter now. And I bring soup. Attendance is excellent." },
			},
		},
		{
			title = "Both Hands",
			mood = "dark",
			lines = {
				{ kind = "emote", text = "holds out both hands and regards them quietly." },
				{ kind = "say", text = "This hand has closed wounds. And this one has opened them, when it was needed. People prefer to hear about the first." },
				{ kind = "say", text = "We're taught that mending and ending come from one source. It's a hard thing to learn, and harder to forget." },
				{ kind = "say", text = "I pray before I do either. I'd be worried about any priest who only prayed before one." },
			},
		},
	},
	SHAMAN = {
		{
			title = "When the Elements Argue",
			mood = "funny",
			lines = {
				{ kind = "say", text = "Fire and water don't get along. Everybody knows that. But nobody tells you that you have to sit between them." },
				{ kind = "emote", text = "raises both palms, as if calming two arguing friends." },
				{ kind = "say", text = "I spent one whole night trying to keep a campfire going in the rain. By morning, I'd apologized to both of them." },
				{ kind = "emote", text = "gives the fire a small, apologetic nod, just in case." },
				{ kind = "say", text = "That's the true work. You're not their master. You're the one who has to keep the peace at a very loud family dinner." },
			},
		},
		{
			title = "The Quiet Spirit",
			mood = "dark",
			lines = {
				{ kind = "say", text = "My teacher took me to a dead valley once. No birds, no wind, and no water. I'd never felt so alone." },
				{ kind = "say", text = "I called and called on the spirits, and nothing came. I asked her why it was so empty." },
				{ kind = "emote", text = "lets the silence sit so long that a log settling in the fire sounds loud." },
				{ kind = "say", text = "She said, it isn't empty. It's grieving. Sit down. So we sat. For three days. On the fourth, it rained a little." },
			},
		},
	},
	MAGE = {
		{
			title = "The Cost of Knowing",
			mood = "wise",
			lines = {
				{ kind = "say", text = "My tutor kept a jar with one small flame in it, which he had lit as a boy. It had burned for sixty years." },
				{ kind = "say", text = "He asked me what it was feeding on. I gave him six clever answers. He shook his head at every one." },
				{ kind = "emote", text = "stares into the fire, as if it might have an answer of its own." },
				{ kind = "say", text = "On his deathbed, it went out. So now you know, he said. Every spell costs something. Do learn what, before you cast it." },
			},
		},
		{
			title = "Conjured Lunch",
			mood = "funny",
			lines = {
				{ kind = "say", text = "Yes, I can conjure food. No, it isn't good. Everyone's always so impressed until they've eaten it." },
				{ kind = "emote", text = "conjures a loaf, knocks on it, and winces at the sound." },
				{ kind = "say", text = "We spend ten years studying the fundamental forces of the cosmos, and can make bread that tastes like a wet Tuesday." },
				{ kind = "say", text = "Still, nobody's ever complained after three days in the wilderness. Hunger is an excellent sauce. I don't conjure sauce." },
			},
		},
	},
	WARLOCK = {
		{
			title = "A Reasonable Contract",
			mood = "funny",
			lines = {
				{ kind = "say", text = "Folk hear warlock and think I've sold my soul. Please. I've read the contract. I've read it many times." },
				{ kind = "emote", text = "flicks an imaginary speck of ash from their sleeve." },
				{ kind = "say", text = "There's a clause on page forty. It's beautifully written. The other side was very confident that no one reads page forty." },
				{ kind = "say", text = "I'm not saying I've won. I'm saying that one of us is going to be very surprised, and I sleep quite soundly." },
			},
		},
		{
			title = "What Whispers Back",
			mood = "dark",
			lines = {
				{ kind = "say", text = "The first time something answered me from the other side, it knew my mother's name." },
				{ kind = "say", text = "That's how they get you. It's never power that they offer, not at the start. It's that something finally listened." },
				{ kind = "emote", text = "tilts their head slightly, as though hearing something faint." },
				{ kind = "say", text = "I keep it talking. It keeps me company. Each of us believes we're the one holding the leash." },
				{ kind = "emote", text = "holds still, then glances toward their own shadow and quickly back to the fire." },
			},
		},
	},
	DRUID = {
		{
			title = "Many Skins",
			mood = "wise",
			lines = {
				{ kind = "say", text = "People ask which shape is the real me. The bear, the cat, or this one, sitting here talking to you." },
				{ kind = "emote", text = "rolls their neck and stretches, in a distinctly animal way." },
				{ kind = "say", text = "I ask them if they're the same at home, at market, and at their mother's. They always go quiet." },
				{ kind = "say", text = "Everybody's got a few skins. I just happen to get more use out of the claws." },
			},
		},
		{
			title = "The Balance",
			mood = "wise",
			lines = {
				{ kind = "say", text = "An eager young one asked me why I let the wolves take that deer. I could have stopped them, and it was so gentle." },
				{ kind = "say", text = "So I took them to see a valley where someone had once killed all the wolves. Too many deer. Nothing but bare earth and bones." },
				{ kind = "emote", text = "looks out over the heads of the circle, as if at a far-off valley." },
				{ kind = "say", text = "Kindness isn't the same as balance. It took me a long time to learn that, and I still don't like it." },
			},
		},
	},
}
