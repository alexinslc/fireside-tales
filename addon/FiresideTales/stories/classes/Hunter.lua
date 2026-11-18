-- Stories only Hunters tell (class token HUNTER).
local _, ns = ...

ns.AddStories("class", "HUNTER", {
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
	{
		title = "What the Droppings Said",
		mood = "funny",
		lines = {
			{ kind = "say", text = "My teacher could look at what an animal left behind and tell you its age, its health, and what kind of week it was having." },
			{ kind = "emote", text = "leans forward, pokes at something invisible with a stick, and sniffs thoughtfully." },
			{ kind = "say", text = "It took me six years to learn that. It's the most useful thing I know. There is nowhere to mention it at a dinner party." },
			{ kind = "say", text = "I've only been asked back once. That was when I told the host that what was in her pantry wasn't mice, and was about the size of a pony." },
			{ kind = "say", text = "She thanked me very warmly, from the roof." },
		},
	},
	{
		title = "My First Companion",
		mood = "funny",
		lines = {
			{ kind = "say", text = "To hear people tell it, everybody's first beast was some great snarling thing. Mine was a turtle. I chose it because I thought it couldn't get away." },
			{ kind = "say", text = "Three weeks I sat with that turtle. I brought it berries. I spoke to it softly. I told it things about my family." },
			{ kind = "emote", text = "looks down fondly at a spot near their feet." },
			{ kind = "say", text = "And on the day I was sure we understood each other, it turned around and walked off." },
			{ kind = "say", text = "I watched it go for most of an afternoon. I could have caught up at any moment. That's what stung." },
		},
	},
	{
		title = "The Old Hound's Share",
		mood = "heartfelt",
		lines = {
			{ kind = "say", text = "My old hound can't run anymore. His hips went two winters ago, and his nose is about half what it was." },
			{ kind = "say", text = "He still comes out with me every morning. It takes a while. I find him a sunny place under a tree, and he watches the woods like he's in charge." },
			{ kind = "emote", text = "pats their thigh twice, softly, and looks down." },
			{ kind = "say", text = "When I've brought something down, I drag it around in a wide circle and leave it upwind of him. Then I go and stand a little way off." },
			{ kind = "say", text = "He wakes up, and he finds it. And he looks at me like, did you see that? Did you see what I found?" },
			{ kind = "say", text = "I always did. I make a great fuss. I'll keep making it for as long as there's a morning." },
			{ kind = "emote", text = "sets a scrap of jerky down beside them, where an old dog might find it." },
		},
	},
	{
		title = "The Walk You Owe",
		mood = "dark",
		lines = {
			{ kind = "say", text = "The first deer I ever shot, I shot badly. High and back, and it ran. I was pleased at how far it went. I was very young." },
			{ kind = "say", text = "My teacher looked at the leaves and picked up her pack. I said we'd never catch it. She said we weren't going home." },
			{ kind = "emote", text = "lowers their gaze and walks two fingers slowly along one knee, as if following something along the ground." },
			{ kind = "say", text = "Two days, uphill. It had gone a long way in that condition, and we saw every place it had stopped to rest." },
			{ kind = "say", text = "I finished it myself, and it looked at me. She said only, \"That's what a bad shot costs, and you're the cheap end of it.\"" },
		},
	},
	{
		title = "Seven Wolves, Five Arrows",
		mood = "action",
		lines = {
			{ kind = "emote", text = "draws an imaginary arrow, then pauses to count the rest with one finger." },
			{ kind = "say", text = "I don't recommend camping on a rock. But when a pack comes up around you at night, a rock is the best furniture there is." },
			{ kind = "say", text = "Seven pairs of eyes. I had five arrows, one companion, and a fire that was mostly a memory. My sums have never been so clear." },
			{ kind = "emote", text = "glances past the firelight and counts something out there under their breath." },
			{ kind = "say", text = "One, two, three, into the dark at whatever moved. One got my sleeve, and I gave it the fourth at about the length of my arm." },
			{ kind = "say", text = "The fifth I kept, because a person should always have something left to lie about. My companion went off the rock and took the rest." },
			{ kind = "say", text = "It came back at dawn, limping, dropped down beside me, and gave me a long look. As if I'd miscounted on purpose." },
		},
	},
	{
		title = "Over My Own Tracks",
		mood = "spooky",
		lines = {
			{ kind = "say", text = "When you think you're being followed, you walk a big slow loop and cut your own trail. Anyone in my trade will tell you that." },
			{ kind = "say", text = "So I did, one grey morning in the high woods. And there they were, fresh prints laid over mine. Somebody had been walking in my steps." },
			{ kind = "emote", text = "leans down and lays two fingers on the ground, then goes very still." },
			{ kind = "say", text = "Same boots. Same stride. And the same little patch on the left heel, where I'd mended it myself with a scrap of elk hide." },
			{ kind = "emote", text = "traces a little patch shape in the air and goes still." },
			{ kind = "say", text = "They went on ahead toward my camp, at an easy pace. Whoever it was knew where they were going." },
			{ kind = "say", text = "I left a perfectly good kettle at that camp. I have never wanted a kettle less." },
		},
	},
	{
		title = "Till the Birds Forget",
		mood = "wise",
		lines = {
			{ kind = "say", text = "My teacher walked me to a field and told me to sit down until the birds forgot about me. Then she went home." },
			{ kind = "say", text = "The first day they all flew off when I scratched my nose. The fourth day I stopped being bored, and that was worse. The things you think about out there." },
			{ kind = "emote", text = "goes completely still for a long moment, barely breathing." },
			{ kind = "say", text = "On the ninth morning, a wren landed on my bow. It sat there and sang. I cried a bit, if you want to know." },
			{ kind = "say", text = "She came and looked, and she nodded. \"Good,\" she said. \"Now learn to go home and have people know you again. That part takes longer.\"" },
		},
	},
	{
		title = "The Ten-Year Stave",
		mood = "wise",
		lines = {
			{ kind = "say", text = "A proper bow stave has to sit for years before it's fit to work. An old bowyer I used to buy from had rafters full of them, tagged by the year." },
			{ kind = "emote", text = "runs a slow hand along an invisible length of wood, feeling for the grain." },
			{ kind = "say", text = "I asked how old the newest one was. He said he'd cut it that spring. He was eighty, easily, and his hands shook." },
			{ kind = "say", text = "I told him, as politely as I could, that he'd never see that one strung. He said of course not, and that he'd shot staves cut by a man he never met." },
			{ kind = "say", text = "I've started cutting a stave every spring, though I can't work wood to save my life. They're for somebody." },
		},
	},
	{
		title = "Playing Dead",
		mood = "action",
		lines = {
			{ kind = "say", text = "Two ogres ran me down in a ravine once. Big ones, with clubs, and my companion was off chasing a rabbit, as companions do." },
			{ kind = "say", text = "There's a trick every hunter learns. You fall down, very convincingly, and you stay down. It works on most things that can't count." },
			{ kind = "emote", text = "slumps sideways with their tongue out and eyes rolled up, perfectly still." },
			{ kind = "say", text = "The ogres poked me, argued about whether I was dead, and then argued about which of them had killed me. It got loud." },
			{ kind = "say", text = "While they were shoving each other, my companion came back with the rabbit, saw the ogres, dropped it, and bit the bigger one somewhere tender." },
			{ kind = "say", text = "I got up, and we left, and the ogres went on arguing. I like to think they're still at it. I never did find out what happened to the rabbit." },
		},
	},
})
