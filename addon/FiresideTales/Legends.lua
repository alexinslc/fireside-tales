-- Legends: real Warcraft stories, told in parts. Each part is one sitting at the fire,
-- under a minute, and the teller bar offers the next part when one ends. Keep names,
-- places, and events true to the game, and retell them rather than quoting quest text.
local _, ns = ...

-- The Stalvan Mistmantle quests in Duskwood. Sources:
-- https://warcraft.wiki.gg/wiki/Stalvan_Mistmantle
-- https://warcraft.wiki.gg/wiki/The_Legend_of_Stalvan_quest_chain
-- https://www.engadget.com/2008-09-19-know-your-lore-stalvan-mistmantle.html
ns.AddLegend("Duskwood", "The Legend of Stalvan", {
	summary = "A gentle schoolteacher from Moonbrook, a noble family's daughter, and the pages he left behind.",
	parts = {
		{
			title = "Part 1: A Name in the Dark",
			mood = "spooky",
			lines = {
				{ kind = "say", text = "There's an old seer in Darkshire, Madame Eva. Years back, she woke from a dream with one name on her lips. Stalvan. Death was coming for her granddaughter, and it had a name." },
				{ kind = "say", text = "The town clerk sat up all night with his records, and found it. Stalvan Mistmantle. A schoolteacher, once, out in Moonbrook. Well liked. A gentle sort, everyone said." },
				{ kind = "emote", text = "turns an invisible page, slowly, and runs a finger down it." },
				{ kind = "say", text = "In the ruins of that schoolhouse there was an old footlocker, and in it a letter he never sent. To his old headmaster, proud as a boy, telling him how well he was doing." },
				{ kind = "say", text = "When the footlocker was opened, something pale rose out of it and wailed. A girl, or what was left of one. Nobody knew yet who she was." },
				{ kind = "say", text = "That's where it starts. It gets worse from here." },
			},
		},
		{
			title = "Part 2: The Tutor",
			mood = "dark",
			lines = {
				{ kind = "say", text = "The trail led to the Lion's Pride Inn in Goldshire. Stalvan wrote from there, asking to tutor a noble family's children. The courier fled that inn one stormy night in his nightclothes." },
				{ kind = "say", text = "The letter was for Lord Flintridge of Stormwind. Stalvan got the post anyway. Two children. A boy named Giles, and his older sister, Tilloa." },
				{ kind = "emote", text = "holds up two fingers, then slowly lowers one of them." },
				{ kind = "say", text = "By the time anyone came looking, the Flintridge house stood empty. A caretaker was selling off the last of their things to pay the taxes. The whole family was gone." },
				{ kind = "say", text = "Among their papers was a torn journal page in Stalvan's hand. All about Tilloa. How she was growing up. How bright she was. Careful writing, the way you write something you've thought about for a long time." },
				{ kind = "say", text = "That was the first page. It wasn't the last." },
			},
		},
		{
			title = "Part 3: The Flower",
			mood = "dark",
			lines = {
				{ kind = "say", text = "The family kept a summer house near Eastvale in Elwynn, and Stalvan went with them. Years later, another page turned up in its attic." },
				{ kind = "say", text = "Tilloa had given her tutor a flower that summer. A small kindness, the kind you give a teacher you like. He wrote about it as if she'd made him a promise." },
				{ kind = "emote", text = "cups an invisible flower in both hands, very carefully, as if it might fall apart." },
				{ kind = "say", text = "The last pages turned up muddy and torn at the Scarlet Raven Tavern in Duskwood. Tilloa had come home with a young man she meant to marry. She introduced her tutor to him as a kind old man." },
				{ kind = "say", text = "He wrote that she had mocked and betrayed him. She'd done neither. She had just never thought of him the way he thought of her." },
				{ kind = "emote", text = "closes their hands, slowly, around nothing." },
				{ kind = "say", text = "The page after that one is stained with blood." },
			},
		},
		{
			title = "Part 4: Manor Mistmantle",
			mood = "spooky",
			lines = {
				{ kind = "say", text = "The handwriting matched. There was no doubt left. Stalvan Mistmantle had killed Tilloa, the young man she loved, her brother, and her mother and father." },
				{ kind = "say", text = "Then he went home, to his family's manor north of Darkshire. It's a ruin now. Ghouls stand about in the yard, and a pale little flower grows all around it, that some in Darkshire call Tilloa's tears." },
				{ kind = "emote", text = "glances out past the firelight, toward the dark between the trees." },
				{ kind = "say", text = "Whoever went in found him waiting. Not a man anymore. Dead, and still standing, and still angry. When they carried his ring back to Madame Eva, she only nodded. She had already seen it." },
				{ kind = "say", text = "Her granddaughter lived. But they say that pale girl still rises whenever someone opens something of his. I don't think she's angry. I think she's waiting for someone to tell her it wasn't her fault." },
			},
		},
	},
})

-- The Tirion Fordring quests in the Plaguelands: Redemption, Of Forgotten Memories,
-- Of Lost Honor, Of Love and Family (1 and 2), Find Myranda, Scarlet Subterfuge, In Dreams. Sources:
-- https://warcraft.wiki.gg/wiki/In_Dreams
-- https://warcraft.wiki.gg/wiki/Redemption_(Classic)
-- https://warcraft.wiki.gg/wiki/Of_Forgotten_Memories
-- https://warcraft.wiki.gg/wiki/Of_Lost_Honor
-- https://warcraft.wiki.gg/wiki/Of_Love_and_Family_(1)
-- https://warcraft.wiki.gg/wiki/Of_Love_and_Family_(2)
-- https://warcraft.wiki.gg/wiki/Find_Myranda
-- https://warcraft.wiki.gg/wiki/Scarlet_Subterfuge
-- https://warcraft.wiki.gg/wiki/Tirion_Fordring
-- https://www.wowhead.com/classic/quest=5944/in-dreams
ns.AddLegend("Western Plaguelands", "Tirion Fordring: In Dreams", {
	summary = "An exiled paladin, the son who was told he was dead, and the gifts that called him home.",
	parts = {
		{
			title = "Part 1: The Hermit by the River",
			mood = "wise",
			lines = {
				{ kind = "say", text = "In the Eastern Plaguelands, on the bank of the Thondroril River, there's a little hut. An old man lives there, fishing, keeping to himself. Most folk took him for a hermit gone a bit soft in the head." },
				{ kind = "say", text = "He wasn't. He was Tirion Fordring, once Lord of Mardenholde and a paladin of the Silver Hand. Stripped of it all at a trial in Stratholme and sent into exile, for defending an orc who saved his life." },
				{ kind = "emote", text = "taps two fingers against their chest, where a badge might have hung." },
				{ kind = "say", text = "He had a son. Taelan. Just a boy when his father was cast out. Tirion stayed close all those years, watching him grow up from a distance." },
				{ kind = "say", text = "And that boy grew up to be Highlord of the Scarlet Crusade, holding Hearthglen. The old man said Taelan was still a good man. He only needed to remember. So Tirion set out to remind him." },
			},
		},
		{
			title = "Part 2: The Little Hammer",
			mood = "heartfelt",
			lines = {
				{ kind = "say", text = "On Taelan's seventh birthday, Tirion gave him a tiny war hammer. A perfect copy of his own. The way I heard it, the boy carried it everywhere." },
				{ kind = "emote", text = "holds up a hand with the thumb and finger a few inches apart, and smiles." },
				{ kind = "say", text = "After the exile, Taelan's mother told him his father was dead. So the boy did what boys do. He buried the hammer at his father's grave, down by the Undercroft. An empty grave, for a man still living." },
				{ kind = "say", text = "Someone dug it up for Tirion. Then went north to Northdale, where Taelan had once thrown down a banner. The Symbol of Lost Honor, the day he turned his back on the Silver Hand." },
				{ kind = "emote", text = "rubs a thumb across their palm, as if wiping dirt off something small." },
				{ kind = "say", text = "A hammer, and a banner. There was one thing more the old man wanted. And it was the hardest to find." },
			},
		},
		{
			title = "Part 3: The Painting",
			mood = "spooky",
			lines = {
				{ kind = "say", text = "Long ago, the Fordrings sat for a painter on the shore at Caer Darrow. Tirion, his wife Karandra, and little Taelan. His fondest memory, he said. He wanted to know if that painting still existed." },
				{ kind = "say", text = "Caer Darrow is a dead place now. But the artist, Renfray, was still there. A ghost, still waiting by his easel." },
				{ kind = "emote", text = "frames a small square in the air with their fingers, and peers through it." },
				{ kind = "say", text = "He'd hidden it after the trial, so no one would see it. Behind another painting, one of the twin moons, deep in the Scarlet Bastion of Stratholme. Someone had to fight their way in to bring it out." },
				{ kind = "say", text = "When Tirion saw it again, they say the old paladin nearly fell where he stood, and wept like his heart was breaking open." },
				{ kind = "say", text = "Now he had all three. All he needed was a way into Hearthglen." },
			},
		},
		{
			title = "Part 4: Scarlet Subterfuge",
			mood = "heartfelt",
			lines = {
				{ kind = "say", text = "Out by Uther's Tomb lives an old woman named Myranda the Hag. She knows illusions. Show her the right things, and she'll make you look like one of the Scarlet Crusade, for a little while." },
				{ kind = "say", text = "So Tirion's gift went into Hearthglen in Scarlet colors, through the gates and up into Mardenholde Keep. Right to the Highlord himself." },
				{ kind = "emote", text = "lifts the lid of an invisible box, very slowly." },
				{ kind = "say", text = "Taelan opened it. The hammer. The banner. The painting of a beach and a father he'd been told was dead. He said it couldn't be true, and knew it was." },
				{ kind = "emote", text = "presses a hand flat over their heart and lets out a long breath." },
				{ kind = "say", text = "He told them he'd lived on dreams of his father for years. He was done dreaming. Take me to him, he said. And the guards of Hearthglen heard every word." },
			},
		},
		{
			title = "Part 5: In Dreams",
			mood = "dark",
			lines = {
				{ kind = "say", text = "Taelan cut his way out of his own keep, through the very soldiers he'd commanded. Out of Hearthglen, down the road, toward the edge of the forest where his father waited." },
				{ kind = "say", text = "At the scout tower, Grand Inquisitor Isillien stepped out with his Crimson Elites. The Grand Crusader had ordered the Fordrings dead. Isillien struck Taelan down with holy fire, there on the road." },
				{ kind = "emote", text = "goes very still, and looks down at their empty hands." },
				{ kind = "say", text = "Tirion came too late to save him, but not too late to answer for him. The old man fell on Isillien like a storm, and the Inquisitor could not stand against him." },
				{ kind = "say", text = "He held his son, and swore over him that this would not go unanswered. The Silver Hand would rise again. And from that day Tirion Fordring was its Highlord." },
				{ kind = "emote", text = "looks into the fire for a long moment, then nods once." },
			},
		},
	},
})

-- The Tower of Althalaxx quests (parts 1 to 9) in Darkshore and Ashenvale. Sources:
-- https://warcraft.wiki.gg/wiki/The_Tower_of_Althalaxx_quest_chain
-- https://warcraft.wiki.gg/wiki/The_Tower_of_Althalaxx_(2)
-- https://warcraft.wiki.gg/wiki/The_Tower_of_Althalaxx_(3)
-- https://warcraft.wiki.gg/wiki/The_Tower_of_Althalaxx_(4)
-- https://warcraft.wiki.gg/wiki/The_Tower_of_Althalaxx_(5)
-- https://warcraft.wiki.gg/wiki/The_Tower_of_Althalaxx_(6)
-- https://warcraft.wiki.gg/wiki/The_Tower_of_Althalaxx_(7)
-- https://warcraft.wiki.gg/wiki/The_Tower_of_Althalaxx_(8)
-- https://warcraft.wiki.gg/wiki/The_Tower_of_Althalaxx_(9)
-- https://warcraft.wiki.gg/wiki/Athrikus_Narassin
-- https://warcraft.wiki.gg/wiki/Balthule_Shadowstrike
ns.AddLegend("Darkshore", "The Tower of Althalaxx", {
	summary = "A night elf scout, a paladin far from home, and the Highborne souls a cult kept locked in glowing stones.",
	parts = {
		{
			title = "Part 1: The Watcher in the Trees",
			mood = "spooky",
			lines = {
				{ kind = "say", text = "North of Auberdine there's an old Highborne tower, Althalaxx. The way I heard it, Sentinel Elissa Starbreeze had a scout watching it. Balthule Shadowstrike. One day he simply stopped reporting in." },
				{ kind = "say", text = "Whoever she sent found him alive, tucked in the trees west of the tower. He hadn't dared leave. Warlocks had moved in, and he was afraid he'd miss whatever they did next." },
				{ kind = "emote", text = "peers between their fingers, as if through leaves, at something far off." },
				{ kind = "say", text = "The fanatics camped outside carried scraps of parchment. Gather enough of them and a name came out of the ink. The Cult of the Dark Strand. Balthule had never heard of it." },
				{ kind = "say", text = "He said only one person needed to know, and fast. His master, a paladin, a long way south." },
			},
		},
		{
			title = "Part 2: The Ghost in the Stone",
			mood = "heartfelt",
			lines = {
				{ kind = "say", text = "The paladin was Delgren the Purifier, a human who had come to help the Sentinels hunt demons and the dead. He kept his post at Maestra's Post, in Ashenvale." },
				{ kind = "say", text = "He read the letter and frowned. He'd been fighting those cultists at Ordil'Aran, and he thought one of them carried a soul gem that held the secret of their power." },
				{ kind = "emote", text = "holds up a tiny invisible stone and squints at it." },
				{ kind = "say", text = "When it was finally brought to him, Delgren broke it open. Out came a ghost. A Highborne named Sargath, from Ameth'Aran, ten thousand years gone." },
				{ kind = "say", text = "As the world broke, their governor Athrikus Narassin promised a spell to shield them. Instead he trapped their souls in gems and fed on them. Hundreds, Sargath said." },
				{ kind = "say", text = "Before he faded, he named one more. Athrikus had a lieutenant, and the lieutenant kept a book." },
			},
		},
		{
			title = "Part 3: The Warlock's Book",
			mood = "action",
			lines = {
				{ kind = "say", text = "The lieutenant was Ilkrud Magthrull, an orc warlock holed up at Fire Scar Shrine in southern Ashenvale. A burnt, ugly place, crawling with demons." },
				{ kind = "emote", text = "flinches back, as if from a sudden burst of shadow." },
				{ kind = "say", text = "He had a succubus at his side and called up voidwalkers when he could. They say it was a hard fight. But his tome came back to Maestra's Post." },
				{ kind = "say", text = "Delgren could read orcish, of all things. Know your enemy, he liked to say. The scribbles told him two soul gems were left, held by satyrs at Night Run and Satyrnaar." },
				{ kind = "say", text = "Two more gems found, two more Highborne spirits let go. With them gone, Athrikus had lost most of his strength. Delgren said it was time to finish this." },
			},
		},
		{
			title = "Part 4: The Top of the Tower",
			mood = "action",
			lines = {
				{ kind = "say", text = "Back at the tower, Balthule was rattled. A blinding flash had burst from the high room, then screaming, then lightning striking the ground every so often." },
				{ kind = "emote", text = "glances up, as if at a high window, and flinches." },
				{ kind = "say", text = "Athrikus was up there, ringed by his strongest warlocks. Balthule wanted to wait for Delgren. But Delgren had trusted his messenger to go in alone, so in they went." },
				{ kind = "say", text = "They came down with proof that Athrikus Narassin was dead, and the Cult of the Dark Strand scattered to the winds. The demons would be back one day, Balthule said. But not soon." },
				{ kind = "emote", text = "smiles and lays a hand flat over their heart." },
				{ kind = "say", text = "Delgren said he'd never once doubted them. Then he gave his blessing, and told them there were plenty more wrongs in this world waiting to be put right." },
			},
		},
	},
})

-- The Raene's Cleansing quests in Ashenvale (Alliance, 11 parts), the chain that
-- rebuilds Dartol's Rod of Transformation. Sources:
-- https://warcraft.wiki.gg/wiki/Raene%27s_Cleansing
-- https://warcraft.wiki.gg/wiki/Raene%27s_Cleansing_(6)
-- https://warcraft.wiki.gg/wiki/Raene%27s_Cleansing_(9)
-- https://warcraft.wiki.gg/wiki/Raene%27s_Cleansing_(11)
-- https://warcraft.wiki.gg/wiki/Dartol%27s_Rod_of_Transformation
-- https://www.wowhead.com/classic/quest=991
-- https://www.wowhead.com/classic/quest=1046
ns.AddLegend("Ashenvale", "The Legend of Dartol's Rod", {
	summary = "A lost friend's unfinished work, a wizard's rod rebuilt from three scattered pieces, and the one furbolg in Ashenvale who still knew himself.",
	parts = {
		{
			title = "Part 1: The Friend Who Didn't Come Home",
			mood = "heartfelt",
			lines = {
				{ kind = "say", text = "In Astranaar there's a woman named Raene Wolfrunner. She had an old friend called Teronis, who went out into Ashenvale to help the Sentinels against the furbolgs. He never came back." },
				{ kind = "say", text = "He'd gone hunting for a gem. The gem was meant to power a rod, made long ago by a wizard named Dartol. An evil man, and long dead, but his rod might slow the furbolg raids." },
				{ kind = "emote", text = "turns one hand over slowly, as if holding something small and bright." },
				{ kind = "say", text = "They found Teronis on a little island in Lake Falathim. Murlocs had got to him. His journal was still in his pack, and the murlocs had carried off the gem." },
				{ kind = "say", text = "The gem came back to Astranaar in the end, and so did the journal. Raene read it, and asked if someone would finish what her friend had started." },
			},
		},
		{
			title = "Part 2: Three Pieces of a Rod",
			mood = "spooky",
			lines = {
				{ kind = "say", text = "Teronis's notes pointed to a dryad named Shael'dryn, who keeps a moonwell east of Iris Lake. She took the gem and frowned. The rod was in pieces, she said, and the forest around them had gone wrong." },
				{ kind = "say", text = "The iron shaft was locked in a chest in a glade near the Felwood border. The key was carried by a treant. The treants up there have gone mad, and they don't hand anything over kindly." },
				{ kind = "emote", text = "glances up at the branches overhead, as though one of them might move." },
				{ kind = "say", text = "The last piece had been given to the druids of Dor'Danil to hide, out east toward the Barrens. The druids were dead. Slimes had swallowed the place, and the pommel with it." },
				{ kind = "say", text = "But it came back out, in the end. Gem, shaft, pommel. Shael'dryn fit them together. Only, a rod is not a rod until it remembers what it's for." },
			},
		},
		{
			title = "Part 3: The Hidden Shrine",
			mood = "wise",
			lines = {
				{ kind = "say", text = "Up in the hills above Shael'dryn's glade there's a shrine most folk walk right past. The path spirals up the mountainside, and you'd never see it from below." },
				{ kind = "say", text = "The rebuilt rod was laid in the shrine's basin. They say it began to glow, and hum, and every tree on that hillside seemed to lean in and listen." },
				{ kind = "emote", text = "holds both palms out toward the fire, as if feeling warmth from something unseen." },
				{ kind = "say", text = "When the light faded, the rod was whole again. Raene was proud. Teronis's work had outlived him. But nobody quite knew what the thing actually did." },
				{ kind = "say", text = "Raene guessed. Maybe Dartol meant to walk among the furbolgs unseen. Maybe the rod could make you look like one of them. There was only one way to find out." },
			},
		},
		{
			title = "Part 4: Krolg",
			mood = "heartfelt",
			lines = {
				{ kind = "say", text = "Southeast of Mystral Lake, a torchlit path runs down to a stream. Across it lived Krolg, a furbolg untouched by the madness, who'd fight any stranger. So the rod was raised, and its bearer wore fur." },
				{ kind = "say", text = "Krolg was deeply relieved to meet a kinsman still in his right mind. His tribe had driven him out. At night he could still see their fires." },
				{ kind = "emote", text = "looks off into the dark, as if counting distant campfires." },
				{ kind = "say", text = "He blamed the night elves for much of it. But a people must deal with its own evil, he said, and his was Ran Bloodtooth, whose mind was no longer his own." },
				{ kind = "say", text = "Ran fell at his camp under the southern hills, guards and all. His skull went to Raene in Astranaar, and she set it beside Dartol's Rod in a place of honor. Teronis, she said, would be proud." },
			},
		},
	},
})

-- The Great Masquerade quests in the Burning Steppes: Dragonkin Menace, The True Masters (1-6),
-- Marshal Windsor, Abandoned Hope, A Crumpled Up Note, A Shred of Hope, Jail Break!,
-- Stormwind Rendezvous, The Great Masquerade, The Dragon's Eye, Drakefire Amulet.
-- Horde side touched on: The Champion of the Horde, Blood of the Black Dragon Champion. Sources:
-- https://warcraft.wiki.gg/wiki/Onyxia%27s_Lair_Attunement
-- https://warcraft.wiki.gg/wiki/Dragonkin_Menace
-- https://warcraft.wiki.gg/wiki/The_True_Masters_(3)
-- https://warcraft.wiki.gg/wiki/Marshal_Reginald_Windsor
-- https://warcraft.wiki.gg/wiki/A_Crumpled_Up_Note_(quest)
-- https://warcraft.wiki.gg/wiki/Jail_Break!
-- https://warcraft.wiki.gg/wiki/The_Great_Masquerade
-- https://warcraft.wiki.gg/wiki/The_Dragon%27s_Eye_(quest)
-- https://warcraft.wiki.gg/wiki/Drakefire_Amulet_(quest)
-- https://warcraft.wiki.gg/wiki/The_Champion_of_the_Horde
ns.AddLegend("Burning Steppes", "Onyxia: The Great Masquerade", {
	summary = "A lost marshal, a lady at Bolvar's side who was never a lady, and the amulet that opened a dragon's door.",
	parts = {
		{
			title = "Part 1: Smoke Over the Steppes",
			mood = "action",
			lines = {
				{ kind = "say", text = "The way I heard it, it starts at Morgan's Vigil, at the edge of the Burning Steppes. Black dragonkin were massing under the ridge, and Helendis Riverhorn needed them pushed back." },
				{ kind = "emote", text = "jabs a thumb over one shoulder, toward some ridge in the dark." },
				{ kind = "say", text = "When the brood was beaten back, Helendis sealed a letter. The Blackrock orcs were not their own masters, it said. The black dragonflight was pulling their strings." },
				{ kind = "say", text = "It went to Magistrate Solomon in Lakeshire, then to Highlord Bolvar Fordragon himself. Bolvar wanted proof, so he asked his court's expert on dragons. Lady Katrana Prestor." },
				{ kind = "emote", text = "lifts their chin and looks down their nose, cold as a winter morning." },
				{ kind = "say", text = "She sneered at it all. Bolvar made the messenger a deputy anyway, and Solomon sent them on to Marshal Maxwell. And Maxwell had a missing man on his mind." },
			},
		},
		{
			title = "Part 2: The Prisoner of Blackrock",
			mood = "dark",
			lines = {
				{ kind = "say", text = "Marshal Reginald Windsor once led the Alliance in the Steppes, until he rode into Blackrock Mountain and never rode out. Everyone said he was dead. Everyone but Ragged John." },
				{ kind = "say", text = "John was the only one of Windsor's men who got away. He swore the Dark Iron dwarves had dragged the marshal off to a prison deep in Blackrock Depths." },
				{ kind = "emote", text = "rubs both wrists slowly, as if feeling old chains." },
				{ kind = "say", text = "Windsor was alive in a cell down there. But a crumpled note from Emperor Dagran Thaurissan bragged that General Angerforge and Golem Lord Argelmach were breaking Windsor's secret notes." },
				{ kind = "say", text = "So brave folk went after those two and took the notes back, carved on stone tablets. What was written there, Windsor said, would end a grand deception. Now he just had to get out." },
			},
		},
		{
			title = "Part 3: The Masquerade Ends",
			mood = "dark",
			lines = {
				{ kind = "say", text = "They broke him out together. Windsor got his armor back, opened the cells, and fought his way up out of the Depths. Then he made for Stormwind, and told everyone to bring friends." },
				{ kind = "emote", text = "straightens their back, chin high, one hand flat over the heart." },
				{ kind = "say", text = "He rode in on his horse Mercutio and marched to the keep with a crowd behind him. He told the boy king Anduin to run, then faced Lady Prestor. She laughed and called it treason." },
				{ kind = "say", text = "Then Windsor read from his tablets, in the old tongue of dragons. Her disguise fell away, and there stood Onyxia, daughter of Deathwing. The royal guards turned into dragonspawn." },
				{ kind = "emote", text = "goes quiet and lowers their eyes to the flames." },
				{ kind = "say", text = "She struck Windsor down with one claw, mocked Bolvar as her puppet, and vanished. But she left something behind." },
			},
		},
		{
			title = "Part 4: The Drakefire Amulet",
			mood = "wise",
			lines = {
				{ kind = "say", text = "With his last breath Windsor pointed Bolvar to his medallion. It had kept the Highlord's mind in her grip, and it lay shattered now. A piece of it was a piece of Onyxia herself." },
				{ kind = "say", text = "Only one with dragon blood could remake it. The trail led to a cold peak in Winterspring, and Haleh of the blue flight. She knew the foul thing the moment she felt it." },
				{ kind = "emote", text = "wrinkles their nose and holds an invisible shard at arm's length." },
				{ kind = "say", text = "She needed the blood of General Drakkisath, master of Blackrock Spire. The Horde tells of Rexxar in Desolace, who learned the same secret, and sent his champions after the same blood." },
				{ kind = "say", text = "With that blood the shard became the Drakefire Amulet, and no ward in the Wyrmbog could keep its bearer out. Onyxia waits there still. But Windsor tore off her mask first, in front of all of Stormwind." },
			},
		},
	},
})

-- The legends below are retold in our own words from Warcraft history, as someone at a
-- campfire in WoW: Forever's era would know it: Anduin the boy king, Varian missing,
-- Sylvanas in Undercity, Thrall as Warchief.

-- Sylvanas Windrunner and the fall of Quel'Thalas. Sources:
-- https://warcraft.wiki.gg/wiki/Sylvanas_Windrunner
-- https://warcraft.wiki.gg/wiki/Forsaken
ns.AddLegend("Tirisfal Glades", "The Ranger-General", {
	summary = "Before the Banshee Queen, there was a ranger in the forests of Quel'Thalas who would not give ground.",
	parts = {
		{
			title = "Part 1: One More Gate",
			mood = "action",
			lines = {
				{ kind = "say", text = "Before she was the Banshee Queen, Sylvanas Windrunner was the Ranger-General of Silvermoon, the high elves' city in the north." },
				{ kind = "say", text = "When the Scourge marched on Quel'Thalas, she already knew who led it. Prince Arthas, the paladin who came home wrong." },
				{ kind = "emote", text = "looks into the fire." },
				{ kind = "say", text = "She could have pulled back behind the city walls and waited. She didn't. She met the dead in the forest and made them pay for every step." },
				{ kind = "say", text = "She held each gate until it broke, and then she held the next one. She sent runners to warn Silvermoon. Not one of them got through." },
				{ kind = "say", text = "Short of the city, Arthas finally reached her. Her bow broke on his sword, and she asked him to end it quickly." },
			},
		},
		{
			title = "Part 2: The Forsaken",
			mood = "dark",
			lines = {
				{ kind = "say", text = "He refused. He was angry that she had made him bleed for every mile." },
				{ kind = "say", text = "So he killed her, and then he tore her spirit from her body and bound it to him. She had to follow him into her own home while he finished it." },
				{ kind = "emote", text = "closes one hand slowly into a fist." },
				{ kind = "say", text = "Later, his grip on the dead slipped. Only for a moment. Thousands in Lordaeron woke with their own minds again, and nowhere to go." },
				{ kind = "say", text = "She gathered them and gave them a name: the Forsaken. They are not our friends. I won't pretend they are." },
				{ kind = "say", text = "But when you hear her name, remember the ranger in the forest, holding one more gate." },
				{ kind = "emote", text = "bows their head." },
			},
		},
	},
})

-- Anduin Wrynn, the missing King Varian, and King Llane. Sources:
-- https://warcraft.wiki.gg/wiki/Anduin_Wrynn
-- https://warcraft.wiki.gg/wiki/Varian_Wrynn
-- https://warcraft.wiki.gg/wiki/Llane_Wrynn
ns.AddLegend("Stormwind City", "Two Boy Kings", {
	summary = "A boy king in Stormwind Keep, a father lost at sea, and the king who was once a boy in the same keep.",
	parts = {
		{
			title = "Part 1: Not Yet, Your Majesty",
			mood = "heartfelt",
			lines = {
				{ kind = "say", text = "There's a boy in Stormwind Keep who wears a crown. He's about ten years old. His name is Anduin, and his father is King Varian Wrynn." },
				{ kind = "say", text = "Or was. Nobody knows which word to use anymore. The king sailed for Theramore to talk peace, and he never arrived." },
				{ kind = "say", text = "So they put the crown on his son, and set a regent beside him to rule until the boy is grown." },
				{ kind = "emote", text = "lowers their voice." },
				{ kind = "say", text = "They say the boy asks every morning if there's any news from the sea. They say the answer is always the same. \"Not yet, Your Majesty.\"" },
			},
		},
		{
			title = "Part 2: The Other Boy King",
			mood = "heartfelt",
			lines = {
				{ kind = "say", text = "When Varian was a boy, his father was King Llane. In the First War, with the orcs at the walls, someone Llane trusted killed him in his own keep." },
				{ kind = "say", text = "They say Varian saw it happen. Stormwind fell that year, and he was carried north with the refugees, to grow up in someone else's kingdom." },
				{ kind = "emote", text = "sighs." },
				{ kind = "say", text = "He came home a man, and the city was built again, stone by stone. Varian at least knew his father was gone. This boy doesn't even get that." },
				{ kind = "say", text = "So if you're ever in Stormwind and you see a small face at a high window in the keep, wave." },
				{ kind = "emote", text = "lifts a hand in a small wave." },
			},
		},
	},
})

-- The Battle of Mount Hyjal. Sources:
-- https://warcraft.wiki.gg/wiki/Battle_of_Mount_Hyjal
-- https://warcraft.wiki.gg/wiki/Archimonde
-- https://warcraft.wiki.gg/wiki/Horn_of_Cenarius
ns.AddLegend("Mount Hyjal", "The Night They Gave Up Forever", {
	summary = "How the night elves traded their immortality to stop Archimonde at the World Tree.",
	parts = {
		{
			title = "Part 1: Three Armies",
			mood = "action",
			lines = {
				{ kind = "say", text = "Ask any night elf old enough, and they'll tell you: they were never supposed to die. For ten thousand years, the World Tree on Mount Hyjal kept them young." },
				{ kind = "say", text = "Then the Burning Legion came back, and its general, Archimonde, climbed the mountain to take the tree for himself." },
				{ kind = "emote", text = "looks up toward the mountains." },
				{ kind = "say", text = "Malfurion Stormrage had a plan, but it needed time, and three armies bought it." },
				{ kind = "say", text = "Humans who had fled across the sea, under Jaina Proudmoore. Orcs, under Thrall. Night elves, under Tyrande Whisperwind." },
				{ kind = "say", text = "Not long before, all three had been killing each other in Ashenvale. On that mountain, each held its ground until there was nothing left to hold." },
			},
		},
		{
			title = "Part 2: The Horn",
			mood = "heartfelt",
			lines = {
				{ kind = "say", text = "Archimonde reached the tree and climbed it to drink its power. And Malfurion blew the Horn of Cenarius." },
				{ kind = "emote", text = "cups both hands together, then opens them slowly." },
				{ kind = "say", text = "The wisps answered. Thousands of them, like stars coming down. They poured into the demon until there was nothing left of him." },
				{ kind = "say", text = "And the kaldorei were mortal. They knew that was the price before they did it. They did it anyway." },
				{ kind = "say", text = "They planted a new tree, Teldrassil, but it doesn't keep them young. Now they grow old. Slowly, but they do." },
				{ kind = "say", text = "So if you see a night elf counting the years, sit with them a while. It's new to them." },
			},
		},
	},
})

-- Tirion Fordring and Eitrigg, before "Tirion Fordring: In Dreams". Sources:
-- https://warcraft.wiki.gg/wiki/Tirion_Fordring
-- https://warcraft.wiki.gg/wiki/Eitrigg
ns.AddLegend("Western Plaguelands", "Tirion and the Orc", {
	summary = "Before the hermit by the river, a paladin spared an old orc and lost everything for it.",
	parts = {
		{
			title = "Part 1: The Old Watchtower",
			mood = "action",
			lines = {
				{ kind = "say", text = "Tirion Fordring was once a lord of Lordaeron and a paladin of the Silver Hand. One day, near Hearthglen, he found an old orc hiding in a ruined watchtower." },
				{ kind = "say", text = "His name was Eitrigg. He was tired of war. He had walked away from it. They fought anyway." },
				{ kind = "emote", text = "rubs their hands together by the fire." },
				{ kind = "say", text = "In the fight, part of the old tower came down and knocked Tirion senseless. Eitrigg could have finished him." },
				{ kind = "say", text = "Instead he pulled Tirion out, tied him to his saddle, and sent the horse home. Tirion told his people the orc had been dealt with, and kept the secret." },
			},
		},
		{
			title = "Part 2: The Trial",
			mood = "heartfelt",
			lines = {
				{ kind = "say", text = "But the orc was found, and dragged off to be executed. Tirion drew his sword on his own men to stop it, and lost." },
				{ kind = "say", text = "When orcs stormed into Stratholme, he broke the orc out in the chaos. At his trial, his own wife begged him to lie. He told the truth." },
				{ kind = "emote", text = "presses a palm flat against their chest, then lets it fall." },
				{ kind = "say", text = "Uther himself took the Light from him, and they sent him into exile. He had just enough time to say goodbye to his young son, Taelan." },
				{ kind = "say", text = "The orc Tirion spared stands beside the Warchief in Orgrimmar now. What became of the boy is another story, and a sadder one." },
			},
		},
	},
})

-- Grom Hellscream, Cenarius, and Mannoroth. Sources:
-- https://warcraft.wiki.gg/wiki/Grom_Hellscream
-- https://warcraft.wiki.gg/wiki/Mannoroth
-- https://warcraft.wiki.gg/wiki/Demon_Fall_Canyon
ns.AddLegend("Ashenvale", "The Last Breath of Grom Hellscream", {
	summary = "The orc who drank the demon's blood first, and the canyon where he paid it back.",
	parts = {
		{
			title = "Part 1: The First to Drink",
			mood = "dark",
			lines = {
				{ kind = "say", text = "Long ago, on the orcs' own world, the warlock Gul'dan offered the chieftains the blood of a demon named Mannoroth. Drink, he said, and you will be strong." },
				{ kind = "say", text = "Grom Hellscream of the Warsong clan drank first. The blood made the orcs strong. It also filled them with a rage that wasn't theirs." },
				{ kind = "emote", text = "glances off toward the trees." },
				{ kind = "say", text = "When the orcs came to Kalimdor, the Warsong went into Ashenvale to cut timber, and Cenarius himself came to drive them out." },
				{ kind = "say", text = "Desperate, Grom found a fountain filled with the demon's blood, left waiting for them. With that blood in him, he killed Cenarius, the teacher of Malfurion." },
			},
		},
		{
			title = "Part 2: Demon Fall",
			mood = "action",
			lines = {
				{ kind = "say", text = "His Warchief, Thrall, caught him, and with a human sorceress's help they burned the demon's hold out of him. Then the two of them went looking for Mannoroth." },
				{ kind = "say", text = "They found him in a canyon in Ashenvale. Thrall was struck down, and Grom faced the demon alone." },
				{ kind = "emote", text = "raises both hands as if gripping an axe, then brings them down hard." },
				{ kind = "say", text = "He drove his axe into Mannoroth with everything he had left. The demon died, and the curse in the orcs' blood died with him." },
				{ kind = "say", text = "The blast burned Grom, and he did not get up again. They say he told Thrall he was finally free of it." },
			},
		},
		{
			title = "Part 3: For Him or for Cenarius",
			mood = "wise",
			lines = {
				{ kind = "say", text = "He killed Cenarius. He killed sentinels defending their own forest." },
				{ kind = "say", text = "But every orc alive today is free because Grom Hellscream walked into that canyon." },
				{ kind = "emote", text = "is quiet for a moment." },
				{ kind = "say", text = "The canyon is still there. They call it Demon Fall. I stop when I pass it. I'm never sure if it's for him or for Cenarius." },
				{ kind = "emote", text = "bows their head." },
			},
		},
	},
})

-- Uther and Arthas. Sources:
-- https://warcraft.wiki.gg/wiki/Uther_the_Lightbringer
-- https://warcraft.wiki.gg/wiki/Uther%27s_Tomb
ns.AddLegend("Western Plaguelands", "The Lightbringer", {
	summary = "Uther the Lightbringer, the prince he taught, and the order he would not obey.",
	parts = {
		{
			title = "The Teacher",
			mood = "dark",
			lines = {
				{ kind = "say", text = "Uther the Lightbringer taught a young prince named Arthas everything he knew about the Light." },
				{ kind = "say", text = "At Stratholme, Uther refused the prince's order to put the city to the sword, and Arthas called it treason." },
				{ kind = "say", text = "The next time they met, Arthas carried a new sword, and Uther stood guard over his dead king's ashes." },
				{ kind = "emote", text = "looks down at the coals." },
				{ kind = "say", text = "Uther fell to his own student. His tomb stands in these hills, and paladins still come to it." },
				{ kind = "emote", text = "bows their head." },
			},
		},
	},
})

-- Anduin Lothar, the Lion of Azeroth. Sources:
-- https://warcraft.wiki.gg/wiki/Anduin_Lothar
-- https://warcraft.wiki.gg/wiki/Anduin_Wrynn
ns.AddLegend("Stormwind City", "The Name the Boy King Carries", {
	summary = "Anduin Lothar, the Lion of Azeroth, and why Stormwind's boy king bears his name.",
	parts = {
		{
			title = "The Lion of Azeroth",
			mood = "heartfelt",
			lines = {
				{ kind = "say", text = "The boy king of Stormwind is named Anduin. He was named for a man: Anduin Lothar, the Lion of Azeroth, Stormwind's champion in the First War." },
				{ kind = "say", text = "When Stormwind fell, Lothar is the one who got its people out, by ship, north to Lordaeron. He brought the young prince Varian with them." },
				{ kind = "emote", text = "points north with a stick from the fire." },
				{ kind = "say", text = "In the Second War, every army of the Alliance followed him. Near the war's end, at Blackrock Spire, he was cut off from his men and met Doomhammer alone." },
				{ kind = "say", text = "He did not come back. Lothar was the closest thing to a father Varian had left. When Varian had a son, he gave the boy that name." },
				{ kind = "emote", text = "bows their head." },
			},
		},
	},
})

-- Tyrande Whisperwind and Malfurion Stormrage. Sources:
-- https://warcraft.wiki.gg/wiki/Tyrande_Whisperwind
-- https://warcraft.wiki.gg/wiki/Malfurion_Stormrage
ns.AddLegend("Teldrassil", "The Long Wait", {
	summary = "Tyrande Whisperwind, and the ten thousand years she kept watch for Malfurion.",
	parts = {
		{
			title = "Part 1: Ten Thousand Years",
			mood = "heartfelt",
			lines = {
				{ kind = "say", text = "Tyrande Whisperwind leads the night elves now, from Darnassus. Ten thousand years ago, she loved a druid named Malfurion Stormrage." },
				{ kind = "say", text = "After the first war against the Legion, he and his druids lay down to sleep in the Emerald Dream. She stayed awake. Someone had to watch over the kaldorei." },
				{ kind = "emote", text = "looks up at the moon." },
				{ kind = "say", text = "For ten thousand years she kept watch with the Sentinels, and waited." },
				{ kind = "say", text = "When the Legion came back, she was the one who went down into the barrow dens and woke him. They fought side by side at Hyjal, and they won." },
			},
		},
		{
			title = "Part 2: Waiting Again",
			mood = "heartfelt",
			lines = {
				{ kind = "say", text = "Not long after, he went back into the Dream. This time, he hasn't come back, and the druids won't say why." },
				{ kind = "emote", text = "folds their hands in their lap." },
				{ kind = "say", text = "She leads her people, and she doesn't speak of it." },
				{ kind = "say", text = "She waited ten thousand years once. She is waiting again." },
			},
		},
	},
})

-- The Skyborne (shen'dorei), told in a High Order Skyborne voice. Sources: Blizzard's
-- "Meet the New Skyborne" (the pact with Skywall's wind spirits, the spirits vanishing,
-- Windshapers and High Order answering differently), the BlizzCon Found Photos recap
-- (rebels who fled Eldre'Thalas; the spirits lifted the land into Skywall), and the
-- in-game "Rebellion In Eldre'Thalas" crystals (the ships at Eldre'narr).
ns.AddLegend("Zephras Isle", "The Island the Wind Held", {
	summary = "How rebel Highborne fled Eldre'Thalas and found a home the wind agreed to hold.",
	parts = {
		{
			title = "Part 1: The Rebels of Eldre'Thalas",
			mood = "action",
			lines = {
				{ kind = "say", text = "My people were Highborne once, in the city of Eldre'Thalas. You'd call it Dire Maul now." },
				{ kind = "say", text = "After the Sundering, the city lost the magic of the Well, and its rulers would not let go. Our elders say the prince meant to feed that magic with a demon." },
				{ kind = "say", text = "Our ancestors rose up against him. It cost them dearly, and then they ran." },
				{ kind = "emote", text = "looks up at the sky." },
				{ kind = "say", text = "They took ships at Eldre'narr on the coast and sailed west, with the prince's fleet behind them, out past the edge of the maps." },
			},
		},
		{
			title = "Part 2: The Pact",
			mood = "wise",
			lines = {
				{ kind = "say", text = "Out there, they reached a land where the wind spirits lived. The elders say the spirits offered them a home, if they would keep faith with the wind." },
				{ kind = "say", text = "They made that pact. The spirits lifted that land up out of the world and into Skywall, where no ship could follow." },
				{ kind = "emote", text = "spreads both hands, palms up, and lifts them slowly." },
				{ kind = "say", text = "We call it Zephras. Some of our people were given skysight there, so they could see the spirits and speak with them." },
				{ kind = "say", text = "The spirits kept us hidden, from the prince and from everyone else. For thousands of years, we lived on air that had agreed to hold us." },
			},
		},
	},
})

-- Same sources as "The Island the Wind Held".
ns.AddLegend("Zephras Isle", "The Day the Wind Went Quiet", {
	summary = "The morning the wind spirits left Zephras, and why the Skyborne came down to Azeroth.",
	parts = {
		{
			title = "The Empty Wind",
			mood = "heartfelt",
			lines = {
				{ kind = "say", text = "On Zephras, the spirits were always in the wind, and we never once thought about it." },
				{ kind = "say", text = "My mother says she woke one morning some years ago, and the wind was empty. Nobody knows why they left." },
				{ kind = "emote", text = "holds out a hand, as if feeling for a breeze." },
				{ kind = "say", text = "After that the pylons started failing, and we lost word from the other islands." },
				{ kind = "say", text = "The Windshapers came down to Azeroth to find out where the spirits went, and to bring them back." },
				{ kind = "say", text = "Those of us in the High Order came for a different reason. Our forebears were magisters, and we had let most of what they knew slip away." },
				{ kind = "say", text = "So we came to Dalaran to learn it again. We don't know if the spirits are ever coming back." },
			},
		},
	},
})
