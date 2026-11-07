-- Stories chosen automatically by race, keyed by the race token from UnitRace.
-- Both Skyborne races share one list, matched by name in StoryMenu.lua.
local _, ns = ...

ns.RaceStories = {
	Human = {
		{
			title = "Elwynn Mornings",
			mood = "heartfelt",
			lines = {
				{ kind = "say", text = "I've seen a lot of country since I left Elwynn, and every bit of it is trying to kill me. Elwynn only ever tried to feed me." },
				{ kind = "emote", text = "breathes in the woodsmoke and, for a moment, seems to catch the smell of fresh bread instead." },
				{ kind = "say", text = "Morning mist on the fields, someone's bread baking in Goldshire, and you'd think nothing bad had ever happened in the world." },
				{ kind = "say", text = "That's the thing about home. It's not that it's safe. It's that it lets you forget, for a little while, that nowhere is." },
			},
		},
		{
			title = "The Soldier's Song",
			mood = "dark",
			lines = {
				{ kind = "say", text = "Every human my age knows somebody who marched off and never came home. My family has three names on a stone." },
				{ kind = "emote", text = "hums a few bars of an old marching song." },
				{ kind = "say", text = "My aunt used to sing that while she did the washing. She never once told me it was about them." },
				{ kind = "say", text = "We're a short-lived people, and stubborn. We bury our dead, and then we go plant something." },
			},
		},
	},
	Dwarf = {
		{
			title = "Cold Hands, Warm Forge",
			mood = "funny",
			lines = {
				{ kind = "say", text = "Down in Dun Morogh, a bairn learns two things before walking. Which way's the forge, and which way's the ale." },
				{ kind = "emote", text = "squints at the coals with a smith's eye, plainly unimpressed, then grins." },
				{ kind = "say", text = "Outsiders think the snow makes us grim. Nonsense. The snow makes us thirsty." },
				{ kind = "say", text = "I've drunk in a lot of taverns since I came down from the mountain. Not one has poured a proper pint. I keep checking, mind." },
			},
		},
		{
			title = "What the Stone Remembers",
			mood = "wise",
			lines = {
				{ kind = "say", text = "My grandfather could lay a hand on a rock wall and tell you who'd cut it, and when, and if they'd been in a foul mood." },
				{ kind = "say", text = "Stone remembers, he'd say. Every blow. It just takes its time telling you." },
				{ kind = "emote", text = "pats the ground beside them as if greeting an old friend, nodding slowly." },
				{ kind = "say", text = "I've got no such gift. But I still touch the walls wherever I go. It seems rude not to say hello." },
			},
		},
	},
	NightElf = {
		{
			title = "A Long Memory",
			mood = "wise",
			lines = {
				{ kind = "say", text = "When your people live as long as mine, you stop saying long ago. You say, when I was younger." },
				{ kind = "emote", text = "looks above the firelight for a long, quiet moment." },
				{ kind = "say", text = "There are trees I've watched grow from seed. I've outlived some of them. That does something to you." },
				{ kind = "say", text = "The young races are always in such a hurry. I used to pity them. Now, I think they might have noticed something we forgot." },
			},
		},
		{
			title = "Under Teldrassil",
			mood = "heartfelt",
			lines = {
				{ kind = "say", text = "You've never truly seen the dark until you've walked Teldrassil's roots with only the moon above you." },
				{ kind = "say", text = "It's not an empty dark. It's full. Owls. Moths. Quiet feet. Everything awake and going about its business." },
				{ kind = "emote", text = "moves one hand as if brushing through hanging leaves." },
				{ kind = "say", text = "I sometimes wake in these bright, loud cities and have to remind myself that the sun is not angry with me." },
			},
		},
	},
	Gnome = {
		{
			title = "Technically an Improvement",
			mood = "funny",
			lines = {
				{ kind = "say", text = "I once built a device to wake me up in the morning. A very simple thing. Forty gears, two springs, and a small charge." },
				{ kind = "emote", text = "flinches from a popping spark and pats their singed eyebrows." },
				{ kind = "say", text = "And it worked! Woke me up. Woke the whole block up. Woke some people two districts over." },
				{ kind = "say", text = "I've made a few adjustments since. It's only destroyed one bed this year, which is a great improvement." },
			},
		},
		{
			title = "The City Below",
			mood = "dark",
			lines = {
				{ kind = "say", text = "We joke a lot, my people. You've noticed. We joke about nearly everything except Gnomeregan." },
				{ kind = "emote", text = "stops fiddling with a small gear and just holds it." },
				{ kind = "say", text = "I had a workshop there. I left a kettle on. It's a silly thing to think about, but I do. All the time." },
				{ kind = "say", text = "One day we'll go back and take it home. And I'll turn off that kettle. And then, I suspect, I'll have a good cry." },
			},
		},
	},
	Orc = {
		{
			title = "Red Dust",
			mood = "heartfelt",
			lines = {
				{ kind = "say", text = "Durotar is a hard land. Red dust, thin water, and everything with teeth. It suits us." },
				{ kind = "emote", text = "scoops up a handful of dirt and lets it sift through their fingers." },
				{ kind = "say", text = "My elders remember greener places. They speak about them softly. I only remember the camps. This dust is the first home that was ever ours." },
				{ kind = "say", text = "We built it from nothing, with our own hands, and no one gave it to us. That is worth more than green." },
			},
		},
		{
			title = "Blood and Honor",
			mood = "wise",
			lines = {
				{ kind = "say", text = "An old warrior asked me once if I knew what honor was. I said, it's never running from a fight." },
				{ kind = "say", text = "He laughed until he coughed. Then he said, pup, I've run from a hundred fights. That's why you get to hear me say this." },
				{ kind = "emote", text = "grunts, a smile tugging at one tusk." },
				{ kind = "say", text = "Honor is knowing what you'd die for, he told me, and refusing to die for anything less. I've kept that with me." },
			},
		},
	},
	Scourge = {
		{
			title = "Things I Don't Miss",
			mood = "funny",
			lines = {
				{ kind = "say", text = "Death's got a few advantages, you know. I no longer get colds. I haven't slept in years. Saves a fortune on inns." },
				{ kind = "emote", text = "adjusts their jaw with a faint click." },
				{ kind = "say", text = "I do miss the taste of a pear, though. I eat them now and then, just to remember the shape of it." },
				{ kind = "say", text = "It doesn't work. But I keep buying pears. The merchants in Tirisfal must think I've got quite the appetite." },
			},
		},
		{
			title = "The Name on the Stone",
			mood = "dark",
			lines = {
				{ kind = "say", text = "I went looking for my own grave once. Out in Tirisfal. I wanted to see what they'd said about me." },
				{ kind = "say", text = "It was well kept. Fresh flowers, even. Someone had been coming for years." },
				{ kind = "emote", text = "sits very still, the firelight moving over a face that does not." },
				{ kind = "say", text = "I waited until I saw who came. Then I left without a word. Some people deserve to keep the version they're mourning." },
			},
		},
	},
	Tauren = {
		{
			title = "The Plains at Dusk",
			mood = "heartfelt",
			lines = {
				{ kind = "say", text = "In Mulgore, we say that the wind is the Earth Mother breathing out. Stand in the tall grass at dusk, and you'll feel it." },
				{ kind = "emote", text = "closes their eyes and sits quietly, as if a great field lay all around them." },
				{ kind = "say", text = "Small folk ask how I can stand so much open space. I ask them how they can stand so many walls." },
				{ kind = "say", text = "No one has ever managed to answer. They just look a little sad, and order another drink." },
			},
		},
		{
			title = "The Hunt and the Thanks",
			mood = "wise",
			lines = {
				{ kind = "say", text = "My grandmother taught me to hunt. She would thank the animal before she drew the bow, and again after." },
				{ kind = "say", text = "I asked her once if the thanks made any difference to the animal. She said, no, child. It makes a difference to you." },
				{ kind = "emote", text = "touches two fingers to the ground, then to their heart." },
				{ kind = "say", text = "I've seen what happens to those who stop thanking. They get very good at killing, and then they're not much good for anything else." },
			},
		},
	},
	Troll = {
		{
			title = "Old Blood",
			mood = "funny",
			lines = {
				{ kind = "say", text = "Mon, my people were building empires when your ancestors were still arguing about fire." },
				{ kind = "emote", text = "nods at the fire and shows their tusks in a wide, lazy grin." },
				{ kind = "say", text = "Don't look like that. Empires fall. We know better than anybody. I'm just saying, we've seen a few things come and go." },
				{ kind = "say", text = "And we still here, eh? Still laughing. Stay around long enough, and that's all the victory you get." },
			},
		},
		{
			title = "The Loa's Bargain",
			mood = "funny",
			lines = {
				{ kind = "say", text = "When I was small, my uncle made an offering to the loa, for good fishing. A fine, fat chicken." },
				{ kind = "say", text = "Next morning, the boat was full. Fish everywhere. He danced for an hour, he was so pleased." },
				{ kind = "emote", text = "chuckles low in their throat." },
				{ kind = "say", text = "Then he looked up, and every chicken in the village was sitting on his roof. Staring. Lesson is this, mon: read the bargain." },
			},
		},
	},
	Skyborne = {
		{
			title = "Zephras Winds",
			mood = "wise",
			lines = {
				{ kind = "say", text = "On Zephras Isle, you learn to read the wind before you learn to read anything else." },
				{ kind = "emote", text = "watches the smoke lean one way, then the other, and nods as if it had spoken." },
				{ kind = "say", text = "Groundfolk think of wind as weather. To us it's a neighbor. Sometimes kindly, sometimes drunk, and always in your business." },
				{ kind = "say", text = "I can't stay anywhere long where the air is still. It feels as though the whole world is holding its breath." },
			},
		},
		{
			title = "Looking Down",
			mood = "funny",
			lines = {
				{ kind = "say", text = "When I first left the isle, I couldn't get used to how everyone here looks straight ahead. All day. Never up." },
				{ kind = "say", text = "I asked a farmer once what the weather would be. He looked at me as if I'd asked him the price of the moon." },
				{ kind = "emote", text = "glances skyward out of habit." },
				{ kind = "say", text = "It rained on him. I'd have told him, had he asked me back. Nobody ever asks me back." },
			},
		},
	},
}
