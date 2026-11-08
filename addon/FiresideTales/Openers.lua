-- Openers and closers: one line to gather people before a story, and one to send it
-- off. The teller bar offers them, and nothing is said until you press the button.
-- Openers come from any, plus night after dark. Closers come from any, the mood of
-- the story just told, and night after dark.
local _, ns = ...

ns.Openers = {
	any = {
		{ kind = "say", text = "Gather round, everyone. I've got one for you." },
		{ kind = "say", text = "Pull up a log. This one's worth hearing." },
		{ kind = "say", text = "Anyone want a story? I've got a good one." },
		{ kind = "say", text = "Settle in, friends. Here's one I picked up on the road." },
		{ kind = "say", text = "All right, quiet down a moment. I've got a tale for you." },
		{ kind = "say", text = "Want to hear something strange? Come a little closer." },
		{ kind = "say", text = "Before anyone turns in, let me tell you one." },
		{ kind = "say", text = "Here's one I heard in a tavern years ago, and I've never forgotten it." },
		{ kind = "emote", text = "pokes the fire until it crackles, then looks around the circle." },
		{ kind = "emote", text = "clears their throat and waits for the circle to go quiet." },
		{ kind = "emote", text = "taps the side of their cup to get everyone's attention." },
		{ kind = "emote", text = "leans toward the firelight, as if about to share a secret." },
	},
	night = {
		{ kind = "say", text = "Dark enough now. This is the hour for a proper story." },
		{ kind = "say", text = "Keep your backs to the fire tonight. You'll want to, after this one." },
		{ kind = "say", text = "Since nobody's sleeping yet, here's one to keep you up." },
		{ kind = "emote", text = "glances out at the dark beyond the firelight, then back at the circle." },
	},
}

ns.Closers = {
	any = {
		{ kind = "say", text = "And that's the tale, more or less as it was told to me." },
		{ kind = "say", text = "That's all of it. Make of it what you will." },
		{ kind = "say", text = "That's how I heard it, anyway. Someone else might tell it different." },
		{ kind = "say", text = "So there you have it. Who's got the next one?" },
		{ kind = "emote", text = "sits back from the fire and lets the story settle." },
		{ kind = "emote", text = "nods once, as if that's the end of the matter." },
	},
	funny = {
		{ kind = "say", text = "And every word of it true. Mostly." },
		{ kind = "say", text = "I'll be here all night, friends. Unfortunately for you." },
		{ kind = "emote", text = "grins and takes a long, satisfied drink." },
	},
	heartfelt = {
		{ kind = "say", text = "I think about that one more often than I'd like to admit." },
		{ kind = "say", text = "Hold on to your people, friends. That's all I've got." },
		{ kind = "emote", text = "is quiet for a moment, watching the coals." },
	},
	dark = {
		{ kind = "say", text = "Not every story ends well. That one didn't." },
		{ kind = "say", text = "Sorry. Some tales need telling, even the hard ones." },
		{ kind = "emote", text = "stares into the fire a while before looking up again." },
	},
	spooky = {
		{ kind = "say", text = "Sleep well, everyone. Keep the fire high." },
		{ kind = "say", text = "If you hear anything tonight, it's probably just the wind. Probably." },
		{ kind = "emote", text = "glances over one shoulder, then laughs a little too loudly." },
	},
	action = {
		{ kind = "say", text = "And that's why I always sit facing the door." },
		{ kind = "say", text = "I'm still not sure how we got out of that one." },
		{ kind = "emote", text = "flexes one hand, as if still feeling the fight in it." },
	},
	wise = {
		{ kind = "say", text = "Take it or leave it. It's served me well enough." },
		{ kind = "say", text = "I didn't understand that one until years later." },
		{ kind = "emote", text = "lets the silence sit a moment before saying anything else." },
	},
	night = {
		{ kind = "say", text = "Well, that's my last one tonight. Goodnight, all." },
		{ kind = "say", text = "The fire's getting low. Rest well, friends." },
		{ kind = "emote", text = "stretches and settles back, ready for sleep." },
	},
}
