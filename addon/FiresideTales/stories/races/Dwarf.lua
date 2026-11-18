-- Stories only Dwarf characters tell (race token Dwarf).
local _, ns = ...

ns.AddStories("race", "Dwarf", {
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
	{
		title = "The Ram Knows the Way",
		mood = "funny",
		lines = {
			{ kind = "say", text = "For ten years my old ram carried me home from the tavern, and I never once had to wake up for it. Finest animal in Dun Morogh." },
			{ kind = "say", text = "Then one night I happened to be sober. Don't ask why. And I noticed he'd turned off the road, three miles the wrong way." },
			{ kind = "emote", text = "sways gently where they sit, wearing a look of perfect trust." },
			{ kind = "say", text = "He walked straight up to an old woman's gate, where a bucket of oats was waiting. She looked up and said, \"You're quiet tonight.\"" },
			{ kind = "say", text = "Ten years, it turns out, I'd been singing at that gate. She wanted to know if I took requests." },
		},
	},
	{
		title = "The Family Ledger",
		mood = "funny",
		lines = {
			{ kind = "say", text = "Every proper family in the mountain keeps a ledger of slights. Ours goes back nine generations. The first entry is one ladle, lent, never returned." },
			{ kind = "say", text = "We've not spoken to the neighbors in two hundred years over that ladle. There have been fistfights. There was a song." },
			{ kind = "say", text = "Then I was clearing out my grandmother's pantry, and at the very back, behind the pickle crocks, I found it. Our mark was on the handle." },
			{ kind = "emote", text = "glances over one shoulder, then mimes sliding something carefully back onto a high shelf." },
			{ kind = "say", text = "Family's a delicate thing. What's holding it together isn't always what ye'd choose." },
		},
	},
	{
		title = "The Storm Bell",
		mood = "heartfelt",
		lines = {
			{ kind = "say", text = "Our village had a storm bell. When the white came down off the peaks, somebody would ring it all night, so anyone caught out could walk toward the sound." },
			{ kind = "say", text = "My father took that duty for thirty winters. I sat up with him once and said, there's nobody out there, Da. Not a soul travels in this." },
			{ kind = "say", text = "He didn't even look at me. \"Ye don't know that,\" he said, and went on ringing." },
			{ kind = "emote", text = "pulls slowly on an invisible rope, then again, keeping time." },
			{ kind = "say", text = "He went in his sleep, one clear night in spring. I went up and rang it anyway. Just in case he needed to find his way somewhere." },
			{ kind = "emote", text = "feeds the fire one more stick, though no one needs it, just in case." },
		},
	},
	{
		title = "Snow in a Jar",
		mood = "heartfelt",
		lines = {
			{ kind = "say", text = "When I left Dun Morogh, my friends packed me a jar of snow as a joke. Something to remember the cold by, they said, when I went soft." },
			{ kind = "emote", text = "takes out a small stoppered jar and tilts it toward the light." },
			{ kind = "say", text = "It was water by supper, of course. I laughed as hard as anyone." },
			{ kind = "say", text = "That was eleven years ago. It has been to every place I've ever been. There's a good bit less of it now. Stoppers are not what they were." },
			{ kind = "emote", text = "tucks the jar away again, gently, and pats the pocket twice." },
		},
	},
	{
		title = "Three Knocks",
		mood = "dark",
		lines = {
			{ kind = "say", text = "When a tunnel comes down, ye put your ear to the rock and ye listen for three knocks. It means someone's alive back there." },
			{ kind = "emote", text = "raps three times on the ground beside them, then waits, head tilted." },
			{ kind = "say", text = "We heard them. Three knocks, every hour, while we dug. On the second day they came slower. On the third day we stopped hearing them." },
			{ kind = "say", text = "We dug for two more days. Nobody suggested otherwise, and nobody said why." },
			{ kind = "say", text = "I can't sit in a room with a person who taps their fingers. I know it's not their fault. I just get up and leave." },
		},
	},
	{
		title = "The Warm Lunch Pail",
		mood = "spooky",
		lines = {
			{ kind = "say", text = "We broke through into an old gallery once, deep down, sealed off since before anyone's records begin. The air tasted of a thousand years." },
			{ kind = "say", text = "Dust past your ankles. Not one footprint. And there, on a ledge, sat a miner's lunch pail." },
			{ kind = "emote", text = "holds a hand out over the coals, palm down, and slowly draws it back." },
			{ kind = "say", text = "I touched it. It was warm." },
			{ kind = "say", text = "We walled that gallery up the same day, and we did it quickly. It's a good, thick wall. The shift that works near it says somebody's been chipping at the other side." },
		},
	},
	{
		title = "Forty Kegs Across the Ice",
		mood = "action",
		lines = {
			{ kind = "say", text = "Three rams, one sled, forty kegs, and a frozen lake that had been perfectly solid all the way up until we reached the middle of it." },
			{ kind = "say", text = "First crack went off like a thunderclap. Then the whole sheet behind us started to go, and it was coming faster than we were." },
			{ kind = "emote", text = "shoves at the air with both hands, wincing with each push." },
			{ kind = "say", text = "I went over the load cutting ropes. Off with the kegs, one after another, to lighten her. Thirty. Twenty. I think I wept at twelve." },
			{ kind = "say", text = "We hit the far shore with black water at the runners and a single keg aboard. All three rams lived, and I gave each of them a mug of it." },
		},
	},
	{
		title = "The Ugliest Knife",
		mood = "wise",
		lines = {
			{ kind = "say", text = "Over the finest forge I ever worked at hung the ugliest knife in the world. Bent, pitted, and cracked halfway through the tang." },
			{ kind = "say", text = "Took me a year to work up the nerve to ask the old master about it. Who made such a thing, and why keep it?" },
			{ kind = "emote", text = "holds up an imaginary blade, squints along it, and grimaces." },
			{ kind = "say", text = "\"I did,\" the master said. \"Aged nine. And it hangs there for the day ye ruin something and sit down to cry about it. Look up, is all.\"" },
			{ kind = "say", text = "I've made one or two bad things since. I don't cry about them. I just find a nail." },
		},
	},
	{
		title = "The Measure of the Mug",
		mood = "funny",
		lines = {
			{ kind = "say", text = "I once complained in Kharanos that my mug held less than the fellow's next to me. Loudly. The keeper handed me a measuring cup." },
			{ kind = "say", text = "I measured both. Same. I measured again. Still the same. By then half the inn had turned round to watch." },
			{ kind = "emote", text = "squints along the rim of an invisible mug, deeply unconvinced." },
			{ kind = "say", text = "The keeper asked if I'd like to apologize. I said I'd found a fault in my eyes, and I'd need another drink to test it." },
			{ kind = "say", text = "She charged me for the measuring cup. Fair enough. I'd used it the most." },
		},
	},
	{
		title = "Sand on the Floor",
		mood = "action",
		lines = {
			{ kind = "say", text = "We were pouring bronze in a big forge in Ironforge when the chain on the crucible snapped, and a whole lip of molten metal came sliding toward the apprentices." },
			{ kind = "say", text = "Water would blow the place apart. Every dwarf knows that before they know their letters. What you want is sand, and the sand was across the room." },
			{ kind = "emote", text = "grips an invisible sack by the neck and swings it round in a wide, low arc." },
			{ kind = "say", text = "I didn't carry it over. I split it with my knife and swung it round by the neck, spraying a line across the floor like sowing seed." },
			{ kind = "say", text = "The bronze ran right up to that line and stopped. Two apprentices were standing on the far side of it, still holding their tongs." },
			{ kind = "say", text = "The master made me sweep up the sand myself. He kept the lump, though. Says it's the best thing that forge ever cast." },
		},
	},
})
