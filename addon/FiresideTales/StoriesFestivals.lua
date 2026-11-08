-- Stories for festivals and the Darkmoon Faire. Each list's name matches a
-- festival in Seasons.lua, and its stories rise to the top while it's on.
local _, ns = ...

ns.AddStories("festival", "Darkmoon Faire", {
	{
		title = "The Fortune Teller",
		mood = "wise",
		lines = {
			{ kind = "emote", text = "holds one open palm out toward the fire, as if to have it read." },
			{ kind = "say", text = "At the Darkmoon Faire, a fortune teller asked me five questions and wouldn't say why." },
			{ kind = "say", text = "Would I steal bread for a starving friend? Would I tell a king a hard truth? That sort of thing." },
			{ kind = "say", text = "At the end she smiled and said my answers had already told my fortune. I just hadn't heard it yet." },
			{ kind = "emote", text = "closes the hand slowly and rests it on one knee." },
			{ kind = "say", text = "I still think about the one about the king. I'm still not sure I answered it honestly." },
		},
	},
	{
		title = "The Lucky Frog",
		mood = "funny",
		lines = {
			{ kind = "say", text = "Never buy a frog from a boy at the Darkmoon Faire. I say this as someone who did." },
			{ kind = "say", text = "He swore it was lucky. It could tell fortunes, he said, if you asked it nicely." },
			{ kind = "emote", text = "cups both hands together as if holding something small and damp." },
			{ kind = "say", text = "I asked it nicely for three days. It told me nothing. Then it ate my best fishing lure." },
			{ kind = "say", text = "Next month I went back to complain, and the boy sold me a second frog to keep the first one company." },
			{ kind = "emote", text = "sighs and shakes their head at the fire." },
		},
	},
	{
		title = "The Tonk Duel",
		mood = "action",
		lines = {
			{ kind = "say", text = "At the faire there's a game where you steer a little clockwork tank with a box of levers." },
			{ kind = "emote", text = "grips an imaginary set of levers and jerks them left and right." },
			{ kind = "say", text = "I was one dent from losing. The other fellow's tonk was chasing mine round and round a barrel." },
			{ kind = "say", text = "So I stopped. Just stopped. His tonk shot straight past, hit the barrel, and fell over." },
			{ kind = "emote", text = "lets go of the levers and raises both hands, grinning." },
			{ kind = "say", text = "The carnie gave me a prize ticket and asked me never to come back. Best win I ever had." },
		},
	},
	{
		title = "How the Faire Arrives",
		mood = "spooky",
		lines = {
			{ kind = "say", text = "Have you ever seen the Darkmoon Faire arrive? Nobody has. I tried once." },
			{ kind = "say", text = "I sat up all night on a hill above the field. Empty grass. Not a wagon in sight." },
			{ kind = "emote", text = "stares hard into the dark beyond the fire, without blinking." },
			{ kind = "say", text = "Near dawn I blinked. Just once. And there it was. Tents, flags, music already playing." },
			{ kind = "say", text = "A man in a tall hat waved to me from the gate, like he'd known I was watching all along." },
			{ kind = "emote", text = "tips an imaginary hat toward the darkness." },
		},
	},
	{
		title = "One Prize Ticket",
		mood = "heartfelt",
		lines = {
			{ kind = "say", text = "My first time at the faire, I spent every copper I had and won exactly one prize ticket." },
			{ kind = "emote", text = "holds up a thumb and finger, pinching something thin and small." },
			{ kind = "say", text = "One ticket buys nothing. I stood by the prize table anyway, just looking." },
			{ kind = "say", text = "A little girl beside me had one ticket too. Together, the carnie said, we could buy one paper flower." },
			{ kind = "say", text = "So we did, and then we argued for an hour over who got to keep it." },
			{ kind = "emote", text = "smiles at the fire." },
			{ kind = "say", text = "She won. I still think that was fair." },
		},
	},
	{
		title = "The Eighth Card",
		mood = "heartfelt",
		lines = {
			{ kind = "say", text = "Ever tried to finish a Darkmoon deck? Eight cards. I had seven within a year." },
			{ kind = "emote", text = "fans out an invisible hand of cards and counts them twice." },
			{ kind = "say", text = "The eighth never turned up. I traded for it, begged for it, nearly bought a fake from a goblin." },
			{ kind = "say", text = "Then an old friend passed, and their pack came to me. At the bottom, wrapped in a letter, was the eighth card." },
			{ kind = "say", text = "The letter just said: you were always one short. Now you're not." },
			{ kind = "emote", text = "gathers the invisible cards together and holds them against their chest." },
		},
	},
	{
		title = "The Shell Game",
		mood = "funny",
		lines = {
			{ kind = "say", text = "A carnie at the Darkmoon Faire bet me a silver I couldn't find the pea under his three cups." },
			{ kind = "emote", text = "slides three invisible cups around on the ground, fast." },
			{ kind = "say", text = "I watched like a hawk. Pointed at the middle one. He lifted it. Empty." },
			{ kind = "say", text = "The left one, empty. The right one, empty too." },
			{ kind = "say", text = "Where's the pea, I asked. He grinned and said, what pea? That's a different game. Two silver." },
			{ kind = "emote", text = "throws up their hands and laughs at the fire." },
		},
	},
	{
		title = "When the Faire Leaves",
		mood = "heartfelt",
		lines = {
			{ kind = "say", text = "The saddest morning of the month is the one after the Darkmoon Faire leaves." },
			{ kind = "say", text = "You walk out to the field, and it's just grass again, flattened in big circles where the tents stood." },
			{ kind = "emote", text = "smooths a patch of ground flat with the palm of one hand." },
			{ kind = "say", text = "One year I found a paper flower left behind in the grass. Bent, a bit muddy." },
			{ kind = "say", text = "I kept it. It's in my pack still. A promise, I suppose, that the faire always comes back." },
			{ kind = "emote", text = "pats their pack gently." },
		},
	},
})

ns.AddStories("festival", "Lunar Festival", {
	{
		title = "The Elder on the Hill",
		mood = "heartfelt",
		lines = {
			{ kind = "say", text = "During the Lunar Festival, the elders come back. You'll find them standing in the oddest places." },
			{ kind = "say", text = "I found one on a lonely hill, looking out over nothing. I bowed and asked what he was watching." },
			{ kind = "emote", text = "bows their head toward the fire." },
			{ kind = "say", text = "He said, the road my grandchildren will walk. Then he pressed a coin into my hand and was gone." },
			{ kind = "say", text = "The coin bore my family's mark. I'd never told him my name." },
			{ kind = "emote", text = "rubs an invisible coin between finger and thumb." },
		},
	},
	{
		title = "The Biggest Firework in Moonglade",
		mood = "funny",
		lines = {
			{ kind = "say", text = "At the Lunar Festival, a goblin sold me what he swore was the biggest firework in Moonglade." },
			{ kind = "say", text = "Light it, step back, and look up, he said. So I lit it, stepped back, and looked up." },
			{ kind = "emote", text = "tilts their head back and stares at the sky." },
			{ kind = "say", text = "It went sideways. Through a tent, across the lake, and straight into a druid's beard." },
			{ kind = "say", text = "The druid didn't say a word. He just turned into a bear and sat down on the goblin's stall." },
			{ kind = "emote", text = "laughs quietly into one hand." },
		},
	},
})

ns.AddStories("festival", "Love is in the Air", {
	{
		title = "The Irresistible Perfume",
		mood = "funny",
		lines = {
			{ kind = "say", text = "Love is in the Air, and a vendor sold me a perfume he promised was irresistible." },
			{ kind = "say", text = "It was. To every stray dog, cat, and boar between the city gates and the coast." },
			{ kind = "emote", text = "sniffs one wrist, winces, and wipes it on their knee." },
			{ kind = "say", text = "I spent the whole festival running from wild animals with flowers in their teeth." },
			{ kind = "say", text = "Then a farmer laughed so hard at me he fell off his fence. We've been friends ever since." },
			{ kind = "emote", text = "smiles into the fire." },
		},
	},
	{
		title = "The Letters I Never Send",
		mood = "heartfelt",
		lines = {
			{ kind = "say", text = "Every year when love is in the air, I write one letter. I never send it." },
			{ kind = "emote", text = "folds an invisible sheet of paper in half, then in half again." },
			{ kind = "say", text = "It's to someone I met on the road years ago. We shared a fire like this one, for one night." },
			{ kind = "say", text = "I never learned their name. They left before dawn, and took the road I didn't." },
			{ kind = "say", text = "So the letters pile up. Maybe one year I'll meet them at another fire and hand over the whole stack." },
			{ kind = "emote", text = "tucks the folded paper into a pocket, close to their heart." },
		},
	},
})

ns.AddStories("festival", "Noblegarden", {
	{
		title = "The Egg Hunt",
		mood = "funny",
		lines = {
			{ kind = "say", text = "Noblegarden. Painted eggs hidden all over town, and every child in the valley out hunting them." },
			{ kind = "say", text = "I thought I'd join in. I'm a seasoned adventurer. I've tracked beasts across mountains." },
			{ kind = "emote", text = "shades their eyes with one hand and peers around the fire." },
			{ kind = "say", text = "Two hours later a little girl had forty eggs. I had one, and it was a rock somebody painted." },
			{ kind = "say", text = "She felt so sorry for me she gave me a chocolate. I'm not too proud to say I took it." },
			{ kind = "emote", text = "pops something imaginary into their mouth and chews happily." },
		},
	},
	{
		title = "The Egg Nobody Finds",
		mood = "spooky",
		lines = {
			{ kind = "say", text = "Every Noblegarden, there's one egg nobody finds. I found it once, under an old stone bridge." },
			{ kind = "say", text = "It wasn't painted like the others. It was black, with silver lines running through it like veins." },
			{ kind = "emote", text = "holds out cupped hands, very still." },
			{ kind = "say", text = "It was warm. And while I held it, something inside tapped back." },
			{ kind = "say", text = "I put it right back where I found it. Some eggs aren't meant for baskets." },
			{ kind = "emote", text = "slowly lowers their hands and wipes them on their knees." },
		},
	},
})

ns.AddStories("festival", "Children's Week", {
	{
		title = "The Dragon in the Clouds",
		mood = "heartfelt",
		lines = {
			{ kind = "say", text = "One Children's Week, I took an orphan out of the city. I asked what she wanted to see most." },
			{ kind = "say", text = "A dragon, she said. A real one. I told her that was a terrible idea. She asked again every hour." },
			{ kind = "emote", text = "rubs the back of their neck, sheepish." },
			{ kind = "say", text = "On the last day we sat on a high cliff and watched the sky until sunset. Nothing came." },
			{ kind = "say", text = "Then she pointed at a cloud and said, there, that one's a dragon. And it was, a little." },
			{ kind = "emote", text = "traces a long, winding shape across the sky with one finger." },
		},
	},
	{
		title = "A Week of Questions",
		mood = "funny",
		lines = {
			{ kind = "say", text = "Children's Week, I took an orphan along for a few days. Nobody warned me about the questions." },
			{ kind = "say", text = "Why is grass green. Why do murlocs smell. Why don't you have a house. Why is your sword chipped." },
			{ kind = "emote", text = "counts the questions off on their fingers and runs out of fingers." },
			{ kind = "say", text = "By the third day I'd told him every story I knew, and made up four more." },
			{ kind = "say", text = "When I brought him back, he told the matron I was the wisest person in the whole world." },
			{ kind = "emote", text = "puffs out their chest proudly, then lets it sag." },
			{ kind = "say", text = "I am not. But I'll take it." },
		},
	},
})

ns.AddStories("festival", "Midsummer Fire Festival", {
	{
		title = "Big Fires and Small Ones",
		mood = "wise",
		lines = {
			{ kind = "say", text = "At Midsummer, every town lights a bonfire taller than a house. This little one's my favorite, though." },
			{ kind = "emote", text = "nudges a log deeper into the coals." },
			{ kind = "say", text = "The keeper of one of those great bonfires told me the big fires are for the world." },
			{ kind = "say", text = "But the small ones, the ones you build yourself on the road, those are for the people sitting by them." },
			{ kind = "say", text = "So happy Midsummer. This one's for us." },
			{ kind = "emote", text = "holds both hands out toward the flames." },
		},
	},
	{
		title = "Stealing the Flame",
		mood = "funny",
		lines = {
			{ kind = "say", text = "At Midsummer, folk try to steal a flame from the other side's bonfire. Don't ask me why. It's tradition." },
			{ kind = "say", text = "I tried it once. Crept in at night with a torch, quiet as a cat." },
			{ kind = "emote", text = "hunches low and moves their hands slowly, as if sneaking." },
			{ kind = "say", text = "I lit the torch, turned around, and found the keeper standing there. Holding a bucket." },
			{ kind = "say", text = "She doused me, the torch, and my pride all in one go. Then she offered me a cup of tea." },
			{ kind = "emote", text = "wrings out the hem of one sleeve, laughing." },
		},
	},
})

ns.AddStories("festival", "Harvest Festival", {
	{
		title = "The Empty Chairs",
		mood = "heartfelt",
		lines = {
			{ kind = "say", text = "At the Harvest Festival they set out a great feast, and they always leave a few chairs empty." },
			{ kind = "say", text = "For the fallen, they say. The heroes who never came home from the war." },
			{ kind = "emote", text = "pats the empty ground beside them." },
			{ kind = "say", text = "I used to think that was sad. Then an old soldier told me otherwise." },
			{ kind = "say", text = "He said an empty chair isn't a missing person. It's a promise there's still room for them." },
			{ kind = "emote", text = "shifts over a little, leaving space by the fire as if for someone else." },
		},
	},
	{
		title = "Two Graves, One Harvest",
		mood = "wise",
		lines = {
			{ kind = "say", text = "The Harvest Festival honors two heroes. The Alliance remembers a paladin, and the Horde an orc." },
			{ kind = "say", text = "I've stood where each of them lies. One on a quiet hill, one in a canyon that still smells of smoke." },
			{ kind = "emote", text = "lays one hand flat on the ground, then the other beside it." },
			{ kind = "say", text = "The flowers left at both are the same. Wildflowers, picked on the road by tired travelers." },
			{ kind = "say", text = "Whatever side you're on, I think the dead would rather we shared the harvest than argued over it." },
			{ kind = "emote", text = "breaks an imaginary loaf in half and holds one piece out across the fire." },
		},
	},
})

ns.AddStories("festival", "Hallow's End", {
	{
		title = "Trick, Not Treat",
		mood = "funny",
		lines = {
			{ kind = "say", text = "On Hallow's End I asked an innkeeper for a treat. She smiled and said, how about a trick instead?" },
			{ kind = "emote", text = "pats their own face and arms, as if checking they're all still there." },
			{ kind = "say", text = "I walked out of that inn a skeleton. Bones and all. My own horse wouldn't come near me." },
			{ kind = "say", text = "So I went back for another try. She made me a pirate. Then a bat. Then a pirate again." },
			{ kind = "say", text = "By midnight I'd been everything in the book, and I still hadn't had a single piece of candy." },
			{ kind = "emote", text = "holds out an empty palm toward the fire, hopefully." },
		},
	},
	{
		title = "Why We Light the Fires",
		mood = "wise",
		lines = {
			{ kind = "say", text = "Do you know what Hallow's End is really for? It started with the Forsaken." },
			{ kind = "say", text = "It marks the night they broke free of the Lich King's voice, and found their thoughts were their own again." },
			{ kind = "emote", text = "taps two fingers slowly against their temple." },
			{ kind = "say", text = "Folk dress up as monsters now and laugh about it. But the first Hallow's End was no joke." },
			{ kind = "say", text = "It was a people learning they could choose again. So I choose candy. And a good fire." },
			{ kind = "emote", text = "leans back and stretches both hands toward the warmth." },
		},
	},
	{
		title = "The Pumpkin on the Wall",
		mood = "spooky",
		lines = {
			{ kind = "say", text = "Every Hallow's End, somebody carves a pumpkin and sets it on the old wall outside town." },
			{ kind = "say", text = "One year I asked around, to thank whoever it was. Nobody knew. Nobody had ever known." },
			{ kind = "emote", text = "draws a slow, grinning face in the air with one finger." },
			{ kind = "say", text = "So I waited up. Midnight came, and the wall was bare. I looked down to rub my eyes." },
			{ kind = "say", text = "When I looked up, there it was. Lit. Grinning. And still warm when I touched it." },
			{ kind = "emote", text = "pulls their hand back from the fire quickly." },
		},
	},
})

ns.AddStories("festival", "Winter Veil", {
	{
		title = "The Snowball Ambush",
		mood = "funny",
		lines = {
			{ kind = "say", text = "Winter Veil in the city. I was minding my own business with a mug of cocoa when the first snowball hit." },
			{ kind = "emote", text = "flinches and wipes the side of their face." },
			{ kind = "say", text = "I turned around and there were six of them. Dwarves. Grinning. Arms full of snow." },
			{ kind = "say", text = "I set the mug down very carefully. Rolled up my sleeves. And started making snowballs of my own." },
			{ kind = "say", text = "Two hours later we were all in the tavern, soaked to the beard, buying each other drinks." },
			{ kind = "emote", text = "raises an imaginary mug toward the fire." },
		},
	},
	{
		title = "The Brown Paper Gift",
		mood = "heartfelt",
		lines = {
			{ kind = "say", text = "One Winter Veil morning, I found a gift under the great tree with my name on it." },
			{ kind = "say", text = "Small. Wrapped in plain brown paper. No note, and no word of who it was from." },
			{ kind = "emote", text = "turns a small, invisible package over in their hands." },
			{ kind = "say", text = "Inside was a wooden button. The very one that fell off my mother's coat the winter I left home." },
			{ kind = "say", text = "I never found out how. Some say Greatfather Winter just knows. I'd rather not know, honestly." },
			{ kind = "emote", text = "tucks the invisible button into a pocket and pats it." },
		},
	},
	{
		title = "The Greench's Sack",
		mood = "action",
		lines = {
			{ kind = "say", text = "Heard of the Greench? A big green beast up in the Alterac snow that hates Winter Veil." },
			{ kind = "say", text = "Every year it steals gifts, and every year somebody has to climb up there and take them back." },
			{ kind = "emote", text = "hunches their shoulders and bares their teeth, growling softly." },
			{ kind = "say", text = "The year I went, it had a sack of toys bigger than a cart, and it would not let go." },
			{ kind = "say", text = "We fought half the night. In the end the sack tore, and toys rained down the whole mountain." },
			{ kind = "emote", text = "flutters their fingers downward like falling snow." },
			{ kind = "say", text = "Children in the valley were finding toys in the snow until spring." },
		},
	},
	{
		title = "Under the Mistletoe",
		mood = "funny",
		lines = {
			{ kind = "say", text = "Winter Veil, a crowded inn, and some joker had hung mistletoe over the only free seat." },
			{ kind = "say", text = "I sat. Looked up. Saw it. Looked across. The one sitting there was an ogre." },
			{ kind = "emote", text = "slowly raises their eyes upward, then lowers them again." },
			{ kind = "say", text = "The ogre looked up too. Then at me. Then he said, very politely, me not that kind of ogre." },
			{ kind = "say", text = "We split a pie instead. Best company I had all winter." },
			{ kind = "emote", text = "chuckles and pats their stomach." },
		},
	},
	{
		title = "Two Places at Once",
		mood = "funny",
		lines = {
			{ kind = "say", text = "Every Winter Veil, Greatfather Winter visits Ironforge and Orgrimmar. Both of them. At the same time. Everybody knows this and nobody thinks about it." },
			{ kind = "say", text = "A dwarf I know wrote to an orc she knows. Same day, same hour, they both sat on his knee. Same red coat. Same cookie crumb caught in the left side of the beard." },
			{ kind = "emote", text = "picks an invisible crumb from their own chin, and studies it." },
			{ kind = "say", text = "Either he's very fast, or there are two of him. They decided they didn't want to know which. I think that was wise of them." },
		},
	},
	{
		title = "Courtesy of Smokywood Pastures",
		mood = "funny",
		lines = {
			{ kind = "say", text = "You've seen the notices. Greatfather Winter is visiting, courtesy of Smokywood Pastures. I always wondered what that meant. Who pays Greatfather Winter?" },
			{ kind = "say", text = "So I asked one of their goblins, between selling me a fruitcake and a second, larger fruitcake. He got out a ledger as thick as my arm." },
			{ kind = "emote", text = "runs a finger slowly down an invisible page, then stops." },
			{ kind = "say", text = "One line, every year, going back further than the company. Greatfather Winter: one glass of milk, one cookie. Paid in full." },
			{ kind = "say", text = "The goblin said it's the only account they've never managed to raise the price on. He seemed personally hurt by it." },
		},
	},
	{
		title = "The Season to Be Jolly",
		mood = "heartfelt",
		lines = {
			{ kind = "say", text = "A notice goes up every winter: throughout Azeroth, it is the season to be jolly. My old sergeant read it to us like a battle order. Then he went to practice." },
			{ kind = "emote", text = "stretches their mouth into a stiff, uncertain grin, then lets it drop." },
			{ kind = "say", text = "He was terrible at it. Children ran from him. He'd stand at the gate and smile at people as if he were about to arrest them." },
			{ kind = "say", text = "Then on the last day, a little one walked straight up and handed him a lumpy gift wrapped in a sock. It was a rock with a face painted on it. A smiling face." },
			{ kind = "say", text = "He kept it on his belt for the rest of his life. He never did learn how to smile right. He didn't need to, after that." },
		},
	},
	{
		title = "The Lost Reindeer",
		mood = "action",
		lines = {
			{ kind = "say", text = "One Winter Veil, one of Greatfather Winter's reindeer got loose in Dun Morogh, and I was fool enough to grab the rope when it ran past me." },
			{ kind = "say", text = "I don't know if you've ever been dragged across a frozen lake on your belly. It's fast. Much faster than you'd like. The reindeer did not slow down for the ice." },
			{ kind = "emote", text = "grips an invisible rope in both fists, and leans back hard." },
			{ kind = "say", text = "Through a snowdrift. Under a cart. Past a very surprised troll. I held on. I don't know why. By then it was a matter of pride." },
			{ kind = "say", text = "It stopped at the gates of Ironforge, right in front of Greatfather Winter, as if it had meant to go there all along. He thanked me for walking it home." },
		},
	},
	{
		title = "Tracks in the Snowfield",
		mood = "spooky",
		lines = {
			{ kind = "say", text = "Winter Veil Eve, we were camped in the snow outside Ironforge, six tents and one small fire. In the morning, there were tracks." },
			{ kind = "say", text = "Hoofprints. But they started in the middle of the field, in fresh snow, with nothing leading up to them. As if something had come down out of the sky." },
			{ kind = "emote", text = "looks slowly upward, then back down at the ground by their feet." },
			{ kind = "say", text = "They went to every tent, and stopped at each one, and there was a gift by every door. Seven gifts. There were six of us." },
			{ kind = "say", text = "The seventh had the name of a friend we'd lost in the pass that autumn. Nobody would open it. It's still on a shelf in Kharanos, wrapped." },
		},
	},
	{
		title = "The Unopened Gift",
		mood = "dark",
		lines = {
			{ kind = "say", text = "My neighbor keeps one Winter Veil gift on the mantel, every year, unopened. Red paper, gone pink now. It's from her brother." },
			{ kind = "say", text = "He sent it the winter he marched out. It arrived the week after the letter that said he wouldn't be coming home." },
			{ kind = "emote", text = "rests a hand flat on their knee and looks into the coals for a while." },
			{ kind = "say", text = "I asked her once why she doesn't open it. She said as long as it's wrapped, he's still got one more thing to say to her." },
		},
	},
	{
		title = "The Patient Snowman",
		mood = "spooky",
		lines = {
			{ kind = "say", text = "They say the children outside Ironforge built a snowman one Winter Veil, a fine one with coal eyes, out past the gates. The next morning it was a little closer to the road." },
			{ kind = "emote", text = "glances out past the firelight, as if checking something." },
			{ kind = "say", text = "Every morning, a little closer. By the end of the feast it was standing at the gate, facing in. Nobody saw it move. The guards say it's still waiting to be let inside." },
		},
	},
})
