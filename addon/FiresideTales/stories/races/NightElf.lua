-- Stories only Night Elf characters tell (race token NightElf).
local _, ns = ...

ns.AddStories("race", "NightElf", {
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
	{
		title = "The Tailor's Grandson",
		mood = "funny",
		lines = {
			{ kind = "say", text = "I left a cloak with a tailor to be mended once, in a human town, and told him I'd be back for it shortly." },
			{ kind = "say", text = "I was, I thought. A small errand came up in the south. When I returned, the shop had a new sign, and a young man was minding the counter." },
			{ kind = "emote", text = "tilts their head, wearing a look of gentle confusion." },
			{ kind = "say", text = "He looked at me, went pale, and shouted into the back room. \"It's true! Grandmother, the customer came back!\" Forty-one years, it had been." },
			{ kind = "say", text = "He had the cloak, beautifully mended, and a bill with interest. His grandmother had also lost a large bet with the whole street that I was dead." },
		},
	},
	{
		title = "The Bridge Committee",
		mood = "funny",
		lines = {
			{ kind = "say", text = "There was a footbridge in Ashenvale that needed mending. So our elders gathered to discuss the matter, with all the care it deserved." },
			{ kind = "say", text = "There were questions of wood. Questions of tradition. A very moving speech on the nature of crossing. This went on for about seventy years." },
			{ kind = "emote", text = "folds their hands and nods with immense, unhurried gravity." },
			{ kind = "say", text = "Then a young trader who was passing through dragged a log over the stream one afternoon and walked across, whistling." },
			{ kind = "say", text = "It was an outrage. A committee has been formed to consider the log. I'm told they hope to have their first findings soon." },
		},
	},
	{
		title = "Six Years Old",
		mood = "heartfelt",
		lines = {
			{ kind = "say", text = "I met a human child once, six years old, who wanted to know if my ears hurt. We became friends. I can't really say why." },
			{ kind = "say", text = "I danced at her wedding. I held her first grandchild. She kept getting smaller, and I kept looking exactly the same, and she teased me for it." },
			{ kind = "emote", text = "reaches out and gently smooths a strand of invisible hair." },
			{ kind = "say", text = "Near the end, her eyes had failed. She took my hand and asked me to be honest, because I'd always been honest. What did she look like now?" },
			{ kind = "say", text = "I told her the truth. I said, you look six." },
			{ kind = "emote", text = "watches a log settle in the fire and does not speak again." },
		},
	},
	{
		title = "A Seed in My Pocket",
		mood = "heartfelt",
		lines = {
			{ kind = "emote", text = "opens one hand to reveal a small, dark seed, worn smooth with handling." },
			{ kind = "say", text = "This fell from the branch above the place where I was born. I picked it up the morning I left Ashenvale, meaning to plant it somewhere." },
			{ kind = "say", text = "I've walked past a thousand good hillsides since. Fine soil, clean water, a kind slant of sun. Every time, I've stopped and thought about it." },
			{ kind = "say", text = "But a tree is a promise that you'll come back. It's a large thing to say to a hillside." },
			{ kind = "emote", text = "weighs the seed over the flames for a moment, then closes their fingers around it and puts it away." },
		},
	},
	{
		title = "The Last Post",
		mood = "dark",
		lines = {
			{ kind = "say", text = "Out in the oldest part of Ashenvale there is a watch post in the crown of a great tree, and there is a sentry in it, still on duty." },
			{ kind = "say", text = "Whatever that post was built to watch for has been gone a long, long time. Her company is gone too. She was told to hold until relieved." },
			{ kind = "emote", text = "sits up very straight, eyes fixed on something far past the firelight." },
			{ kind = "say", text = "We take turns carrying food out to her. She takes it, and thanks us, and she asks if there's any word of her relief." },
			{ kind = "say", text = "We tell her soon. Four hundred years, we have been telling her soon. My people have far too long to learn how cruel a small word can be." },
		},
	},
	{
		title = "Quiet Feet",
		mood = "spooky",
		lines = {
			{ kind = "say", text = "My people walk softly. A child of Ashenvale can cross dry leaves without a whisper. So you learn something early on about footsteps." },
			{ kind = "say", text = "If you can hear them, they aren't ours." },
			{ kind = "say", text = "I heard some once, on the root road, far past any lamp. Behind me, slow and heavy. I stopped walking, and they went on for one step longer." },
			{ kind = "emote", text = "breaks off and turns one long ear toward the dark, utterly still." },
			{ kind = "say", text = "I ran the rest of the way, and I run very well. At the gate, the guard took one look at me and went quiet. There was a wet handprint on the back of my cloak." },
		},
	},
	{
		title = "Running the High Limbs",
		mood = "action",
		lines = {
			{ kind = "say", text = "Some fools go up into the high limbs to run them by moonlight. I was young, only a few hundred years old. Of course I went." },
			{ kind = "say", text = "A branch as wide as a road. Then a branch as wide as a table. Then one as wide as my hand, with a long drop on both sides, and behind me a low, soft cough." },
			{ kind = "emote", text = "hunches low, one hand out for balance, and glances back with wide eyes." },
			{ kind = "say", text = "A nightsaber, as large as any I've seen. I jumped. I caught a vine, swung, lost it, caught another, hit a limb with my ribs, and hauled myself up, gasping." },
			{ kind = "say", text = "She landed right beside me without a sound, licked my face from chin to brow, and strolled off. She'd only wanted to play. I sat there until dawn, shaking." },
		},
	},
	{
		title = "The Long Apology",
		mood = "wise",
		lines = {
			{ kind = "say", text = "A dear friend and I quarreled once, over something small. I said a thing that I shouldn't have. I decided to give it a decade, so she might cool." },
			{ kind = "say", text = "A decade became a century. I rehearsed my apology beneath every moon there was. I grew very fine at it, and I carried it for three hundred years." },
			{ kind = "emote", text = "gazes down at their open hands as if weighing something." },
			{ kind = "say", text = "When at last I stood at her door and spoke it, she looked at me kindly, and with great puzzlement. She had no memory of it at all." },
			{ kind = "say", text = "She asked me to stay for supper. We could have had three hundred years of those." },
			{ kind = "emote", text = "tosses a dry twig into the flames and watches how quickly it is gone." },
		},
	},
	{
		title = "Holding Still",
		mood = "action",
		lines = {
			{ kind = "say", text = "My people can vanish into the shadows if we keep perfectly still. Children learn it as a game. Nobody tells you how hard it is with a satyr standing on your hand." },
			{ kind = "say", text = "I'd followed a raiding party in Ashenvale to get back a satchel of seeds they'd stolen. Then the whole party stopped right on top of me to argue." },
			{ kind = "emote", text = "goes completely still, one hand flat at their side, eyes fixed on nothing." },
			{ kind = "say", text = "One of them leaned his whole weight on my fingers. I counted my breaths. I counted his. He had more patience than I'd have liked." },
			{ kind = "say", text = "When they finally moved on, they left the satchel on the ground beside me. It was heavy, and they were tired of carrying it." },
			{ kind = "say", text = "Those seeds are tall trees now. I still can't make a fist on a cold morning without thinking of them." },
		},
	},
})
