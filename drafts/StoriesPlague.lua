-- DRAFT, not shipped. Stories for the zombie plague that WoW Forever's game files
-- hint at. Once Blizzard announces the event, move this into the addon folder,
-- add it to FiresideTales.toc, add a "Zombie Plague" festival to Seasons.lua
-- with how to recognize it, and adjust the stories to what the event really is.
local _, ns = ...

ns.AddStories("festival", "Zombie Plague", {
	{
		title = "The Cough in the Next Room",
		mood = "spooky",
		lines = {
			{ kind = "say", text = "I stayed at an inn last week. Someone in the next room was coughing all night." },
			{ kind = "say", text = "Dry, rattling coughs. Then, around midnight, the coughing stopped." },
			{ kind = "emote", text = "goes very still and tilts their head, listening." },
			{ kind = "say", text = "And the scratching started. Slow. Patient. Right on the other side of my wall." },
			{ kind = "say", text = "I didn't sleep. In the morning the innkeeper said that room had been empty for days." },
			{ kind = "emote", text = "glances over one shoulder at the dark." },
		},
	},
	{
		title = "Don't Let Them Bite",
		mood = "action",
		lines = {
			{ kind = "say", text = "First rule of the plague: don't get bitten. Second rule: if your friend gets bitten, keep an eye on your friend." },
			{ kind = "emote", text = "narrows their eyes at the nearest person around the fire." },
			{ kind = "say", text = "I was holding a bridge with three others when the dead came shambling up the road." },
			{ kind = "say", text = "We held it till dawn. Then one of us started talking about how hungry he was." },
			{ kind = "say", text = "Turned out he'd just skipped breakfast. But I've never seen four people back away so fast." },
			{ kind = "emote", text = "laughs nervously and rubs the back of their neck." },
		},
	},
	{
		title = "The Grain Wagons",
		mood = "dark",
		lines = {
			{ kind = "say", text = "My grandmother remembered the first plague, up north. It came in the grain." },
			{ kind = "say", text = "Wagons of it, sent to every village, stamped and sealed and looking perfectly ordinary." },
			{ kind = "emote", text = "lets an invisible handful of grain run slowly through their fingers." },
			{ kind = "say", text = "She said you couldn't tell good bread from bad until it was far too late." },
			{ kind = "say", text = "So these days, when the dead start walking again, I bake my own." },
			{ kind = "emote", text = "brushes their palms clean, one against the other." },
		},
	},
	{
		title = "The Ones Who Fought Back",
		mood = "heartfelt",
		lines = {
			{ kind = "say", text = "Everyone tells the plague stories about the dead. I'd rather tell you about the living." },
			{ kind = "say", text = "A farmer I met, no soldier, held her barn door shut with a pitchfork for two nights straight." },
			{ kind = "emote", text = "plants both fists on their knees, holding firm." },
			{ kind = "say", text = "When help came, she'd saved eleven neighbors and one very annoyed goat." },
			{ kind = "say", text = "Heroes aren't only the ones in armor. Sometimes they just refuse to open the door." },
			{ kind = "emote", text = "nods slowly at the fire." },
		},
	},
})
