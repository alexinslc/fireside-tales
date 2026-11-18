-- Stories only Tauren characters tell (race token Tauren).
local _, ns = ...

ns.AddStories("race", "Tauren", {
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
	{
		title = "Low Doors",
		mood = "funny",
		lines = {
			{ kind = "say", text = "I was invited into a very small tavern once, by very small and very friendly people. I ducked. I did not duck enough." },
			{ kind = "emote", text = "tilts their head sideways and tugs gently at nothing, with growing concern." },
			{ kind = "say", text = "Both horns went right into the door frame, and there they stayed. I could neither go in nor go out. They were very kind. They brought me a stool." },
			{ kind = "say", text = "It took two days to find a carpenter. By the second evening, people had begun hanging their coats on me." },
			{ kind = "say", text = "When they finally cut me free, the regulars took up a collection. There's now a small plaque on that door. I think of it as my only monument." },
		},
	},
	{
		title = "The Wisdom of the Kodo",
		mood = "funny",
		lines = {
			{ kind = "say", text = "We were crossing Mulgore with the whole caravan when the lead kodo sat down in the road. When a kodo sits, the world waits." },
			{ kind = "say", text = "Our eldest walked around it three times, and then looked gravely at the sky. \"It senses a storm,\" she said. So we made camp. We waited two days." },
			{ kind = "emote", text = "gazes solemnly into the distance, nodding, then looks down and sighs." },
			{ kind = "say", text = "No storm came. On the third morning, I finally looked under its foot and pulled out a burr, as long as my thumb. The kodo got up and walked on." },
			{ kind = "say", text = "I told no one. And if you ever visit my people, you may hear the tale of the great storm that the kodo saved us from. It's a very good story." },
		},
	},
	{
		title = "The Knot of Grass",
		mood = "heartfelt",
		lines = {
			{ kind = "say", text = "When one of ours sets off into the wide world, someone in the family ties a knot in the tall grass at the edge of camp. It's a small thing." },
			{ kind = "emote", text = "twists an invisible handful of grass together and ties it off with care." },
			{ kind = "say", text = "My mother tied mine. The wind undoes them by autumn, she told me. That's the point of it. You aren't meant to stay tied." },
			{ kind = "say", text = "I was gone twelve years. When I came home at last, I walked out to look at the spot, not expecting anything. And there was a knot in the grass, fresh that spring." },
			{ kind = "say", text = "I never mentioned it, and neither did she." },
		},
	},
	{
		title = "An Empty Bowl",
		mood = "dark",
		lines = {
			{ kind = "say", text = "The year the rains failed in Mulgore, there were more mouths in our camp than there was food. Nobody talked about it. There was nothing to say." },
			{ kind = "say", text = "One evening my grandfather finished half his meal. He set his bowl down in front of me, and he stood, and he walked out into the plain." },
			{ kind = "emote", text = "sets something down with both hands and does not look up." },
			{ kind = "say", text = "I started to call after him. My mother laid a hand on my arm. No one at the fire looked up, and he did not look back." },
			{ kind = "say", text = "He did not come back. And every child in our camp lived to see the rain." },
			{ kind = "emote", text = "looks slowly around the circle, at each face the firelight reaches, and then away." },
		},
	},
	{
		title = "Fire on the Plain",
		mood = "action",
		lines = {
			{ kind = "say", text = "Dry grass and a high wind. We saw the smoke at noon, and by the time we'd got the herd moving, the fire was a wall across the whole of the plain." },
			{ kind = "say", text = "A kodo can't outrun it. Neither can you. I could feel it on my back, and I could hear the calves screaming, and then our eldest stopped dead and pulled out a flint." },
			{ kind = "emote", text = "strikes their hands together sharply, then shields their eyes from a sudden blaze." },
			{ kind = "say", text = "She set the grass alight, right in front of us. I thought she'd gone mad. It raced away downwind and left a black patch, smoking. \"Drive them onto it! Now!\"" },
			{ kind = "say", text = "We pushed the whole herd onto the hot ash and stood in it, coughing. The great fire came, found nothing there to eat, and parted around us. That grass grew back thicker." },
			{ kind = "emote", text = "rubs a pinch of cold ash from the fire's edge between their fingers, and smiles." },
		},
	},
	{
		title = "The Herd That Made No Sound",
		mood = "spooky",
		lines = {
			{ kind = "say", text = "Some evenings in Mulgore, at the very end of the light, a herd will cross the far side of the plain. It's a big one. You'll feel no hoofbeats. The grass will not bend." },
			{ kind = "say", text = "The old ones turn their backs to it, and they tell the children not to count." },
			{ kind = "emote", text = "turns partway from the fire, then stops and glances back over one shoulder into the dark." },
			{ kind = "say", text = "I was young, so naturally I counted. And at the very end of the line walked someone on two legs, slowly, with a kodo harness over one shoulder." },
			{ kind = "say", text = "The knots on that harness were my grandmother's. Nobody else tied them that way. The figure stopped, and raised a hand. Then it waved me over." },
		},
	},
	{
		title = "The Full Bowl",
		mood = "wise",
		lines = {
			{ kind = "say", text = "When you are as large as my people are, you spend your childhood breaking things. Fences. Cups. Small friends, nearly." },
			{ kind = "say", text = "My mother taught me to walk through a village as if I had a bowl on my head, filled right to the brim. She made me do it with a real one, too." },
			{ kind = "emote", text = "sits up with their chin level and shoulders still, as if a brimming bowl rested on their head." },
			{ kind = "say", text = "It's the whole of what I know about strength. Any fool can spill. What takes a lifetime is to carry all that weight through a room and leave everything standing." },
			{ kind = "say", text = "I've carried that bowl through many doors. I've only spilled it twice. I remember both names." },
		},
	},
	{
		title = "The Birds' Row",
		mood = "wise",
		lines = {
			{ kind = "say", text = "Every year my family left one row of corn standing at the edge of the field, unharvested. It was for the birds, my grandfather said." },
			{ kind = "say", text = "When I was fourteen, I knew everything. I called it waste. And so I got up early, in secret, and I brought that row in myself. I was very proud." },
			{ kind = "emote", text = "looks skyward and slowly hunches their shoulders, as if something were circling." },
			{ kind = "say", text = "The next summer, every bird on the plain came to our field. All of it, every row, gone before it had ripened." },
			{ kind = "say", text = "My grandfather never said a word about it. He only planted the row again. You pay your neighbors what you owe them, or else they come and collect." },
		},
	},
	{
		title = "The Little Stool",
		mood = "heartfelt",
		lines = {
			{ kind = "say", text = "A traveler once gave me a stool she'd made on the road. She hadn't measured me first. It came up to about my knee." },
			{ kind = "say", text = "I couldn't sit on it, so I used it to hold my sewing bowl. It was exactly the right height to keep the thread out of my supper." },
			{ kind = "emote", text = "pinches an invisible thread and lifts it carefully clear of something below." },
			{ kind = "say", text = "She came back a year later and started apologizing for it again. Then she saw the worn patch where the bowl had sat every night." },
			{ kind = "say", text = "The next stool she made me, I can actually sit on. I still use the little one more." },
		},
	},
	{
		title = "Shoulder to the Wagon",
		mood = "action",
		lines = {
			{ kind = "say", text = "A trader's wagon got stuck in a ford in the Barrens with the river rising fast. Six of us pushing, and the wheels only sank deeper." },
			{ kind = "say", text = "The trader's daughter was still up on the seat holding the reins, because nobody had told her she could let go." },
			{ kind = "emote", text = "sets one shoulder low and pushes slowly forward, jaw tight." },
			{ kind = "say", text = "So I stopped pushing, got down in the water, and put my shoulders under the back axle. My mother always said I was built like a hill. I was glad she was right." },
			{ kind = "say", text = "The wheels came up out of the mud, and the wagon rolled onto the bank with me still underneath it, plodding along like a slow, wet kodo." },
			{ kind = "say", text = "The girl finally let go of the reins. Then she climbed down and patted me on the head, the way you would a good kodo. I let her." },
		},
	},
})
