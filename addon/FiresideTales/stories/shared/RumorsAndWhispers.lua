-- Rumors and Whispers: short things people swear they heard, on the menu's Rumors tab.
-- Anything a listener might go and try has to be harmless, like an emote, a place, or a time of day.
local _, ns = ...

ns.AddStories("shared", nil, {
	{
		theme = "Rumors and Whispers",
		title = "Thirteen Bells",
		mood = "spooky",
		lines = {
			{ kind = "say", text = "They say the bells of Stromgarde still ring at midnight, up in the Arathi Highlands. Nobody's hung a bell in those ruins for years." },
			{ kind = "emote", text = "leans in close to the fire and lowers their voice." },
			{ kind = "say", text = "Most nights it's twelve. Some nights it's thirteen. Nobody I've met has heard the thirteenth, but everyone knows someone who stopped counting at twelve, just in case." },
		},
	},
	{
		theme = "Rumors and Whispers",
		title = "The Pulled-Out Chair",
		mood = "spooky",
		lines = {
			{ kind = "say", text = "Word is there's a table at the inn in Booty Bay where the chair is always pulled out and the mug is always full. Nobody's paid for it in forty years." },
			{ kind = "emote", text = "glances at the empty space beside them, and shifts over a little." },
			{ kind = "say", text = "Sit there, the barkeep says, and you'll dream of the sea every night for a week. Sailors line up for it. Not one of them will tell you what the dream is." },
		},
	},
	{
		theme = "Rumors and Whispers",
		title = "Your Name in the Snow",
		mood = "spooky",
		lines = {
			{ kind = "say", text = "Hunters in Winterspring say if you camp alone above Everlook, you'll wake to find your name written in the snow outside your tent. Spelled right." },
			{ kind = "emote", text = "traces a few letters in the dirt with one finger, then wipes them away." },
			{ kind = "say", text = "Nothing else happens, they say. It's just there. One fellow told me it was the neatest handwriting he'd ever seen, and that was the worst part." },
		},
	},
	{
		theme = "Rumors and Whispers",
		title = "The Old Page",
		mood = "spooky",
		lines = {
			{ kind = "say", text = "A trader in Ratchet swears there's a map of the whole world, cut into pieces, and every inn on the continent keeps one. Ask the innkeeper for the old page, he says." },
			{ kind = "emote", text = "taps the side of their nose twice." },
			{ kind = "say", text = "I asked at four inns. Three looked at me like I'd lost my wits. The fourth asked who sent me, and I've been trying to think of an answer ever since." },
		},
	},
	{
		theme = "Rumors and Whispers",
		title = "Three Bows at Dawn",
		mood = "funny",
		lines = {
			{ kind = "say", text = "An old dwarf in Thelsamar told me there's a stone on the shore of Loch Modan that opens if you sit facing the water at dawn and bow to it three times." },
			{ kind = "emote", text = "bows three times, very small, from where they sit." },
			{ kind = "say", text = "He's done it every morning for twenty years. Says it's opened twice. He won't say what was inside, but he hasn't paid for a drink since." },
		},
	},
	{
		theme = "Rumors and Whispers",
		title = "Left, Left, Right, Sneeze",
		mood = "funny",
		lines = {
			{ kind = "say", text = "There's a gnome in Ironforge who'll sell you, for one silver, the combination to a vault under Tinker Town. Left, left, right, sneeze." },
			{ kind = "emote", text = "counts the steps off on their fingers, then wrinkles their nose." },
			{ kind = "say", text = "Everyone laughs at the ones who pay. But I've watched three people buy it, and every one of them came back the next week in very nice boots." },
		},
	},
	{
		theme = "Rumors and Whispers",
		title = "The Magistrate's Lunch",
		mood = "funny",
		lines = {
			{ kind = "say", text = "You didn't hear this from me, but folk in Lakeshire say their magistrate is twins. One does mornings, one does afternoons. That's why he never remembers lunch." },
			{ kind = "emote", text = "glances left, then right, then leans closer." },
			{ kind = "say", text = "A cook there swears she served him two breakfasts on the same day. He tipped both times. Different amounts." },
		},
	},
	{
		theme = "Rumors and Whispers",
		title = "The Farmer Who Never Plants",
		mood = "dark",
		lines = {
			{ kind = "say", text = "Word around Westfall is that the farmer with the best harvest every year has never planted a seed. Nobody's ever seen him in his fields. Not once." },
			{ kind = "emote", text = "rubs the back of their neck, and looks down at the fire." },
			{ kind = "say", text = "The year his luck turned, every farm around him failed. His neighbors don't talk to him now. They don't talk about him, either. Not after dark." },
		},
	},
	{
		theme = "Rumors and Whispers",
		title = "The Sleeping Grunt",
		mood = "funny",
		lines = {
			{ kind = "say", text = "They say one of the grunts at the gates of Orgrimmar has been asleep on his feet for six years. Nobody has the nerve to wake him." },
			{ kind = "emote", text = "sits up very straight, folds their arms, and closes their eyes." },
			{ kind = "say", text = "People leave him little gifts. Bread, a flower, a nice rock. He's been promoted twice." },
		},
	},
	{
		theme = "Rumors and Whispers",
		title = "The Murloc Who Knows the Weather",
		mood = "funny",
		lines = {
			{ kind = "say", text = "Fishermen in Darkshore say there's a murloc out past the old wreck who speaks perfect Common, but only to complain about the weather." },
			{ kind = "emote", text = "puffs out their cheeks and frowns up at the sky." },
			{ kind = "say", text = "One fellow says it's never been wrong. Better than any almanac. He brings it a fish every week, and it has still never said thank you." },
		},
	},
	{
		theme = "Rumors and Whispers",
		title = "Councilor Kodo",
		mood = "funny",
		lines = {
			{ kind = "say", text = "Somebody told me there's a kodo in Mulgore that's been on the council at Bloodhoof Village three years running. Nobody's quite sure who voted for it." },
			{ kind = "emote", text = "raises one hand solemnly, as if casting a vote." },
			{ kind = "say", text = "It hasn't passed a single law. Folk there say that's the best record anyone's ever had." },
		},
	},
	{
		theme = "Rumors and Whispers",
		title = "The Key in the Fountain",
		mood = "wise",
		lines = {
			{ kind = "say", text = "There's talk that one of the coins in the fountain in Stormwind's Trade District isn't a coin at all. Turn it over, and it's a key." },
			{ kind = "emote", text = "flips an invisible coin and catches it on the back of one hand." },
			{ kind = "say", text = "Thing is, there are thousands of coins in there. They say the key knows who's looking. Look for it for the wrong reasons, and it's only copper." },
		},
	},
	{
		theme = "Rumors and Whispers",
		title = "The Deeprun Kiss",
		mood = "funny",
		lines = {
			{ kind = "say", text = "They say if you kiss someone in the middle of the Deeprun Tram, right where it's darkest, you'll be together until the tram stops running." },
			{ kind = "emote", text = "grins, then hides the grin behind one hand." },
			{ kind = "say", text = "Gnomes built that tram. It breaks down twice a week. Nobody has had the heart to tell the couples." },
		},
	},
	{
		theme = "Rumors and Whispers",
		title = "Two Captains in Ratchet",
		mood = "funny",
		lines = {
			{ kind = "say", text = "Two ship captains in Ratchet spent eleven years trying to win the same harbor mistress. Flowers, poems, duels. One of them named a ship after her." },
			{ kind = "emote", text = "holds up two fingers, then knocks them together." },
			{ kind = "say", text = "She married the fellow who repaired both their ships. The captains are still competing. Now it's over who gets to be godfather." },
		},
	},
	{
		theme = "Rumors and Whispers",
		title = "Dancing with No One",
		mood = "heartfelt",
		lines = {
			{ kind = "say", text = "Word is, if you dance alone at midnight on the high rises of Thunder Bluff, someone will step out of the dark and dance with you. They never say a word." },
			{ kind = "emote", text = "sways a little where they sit, as if to slow music." },
			{ kind = "say", text = "A friend tried it. She danced until dawn and never saw a face. She goes back every full moon now. She says she isn't lonely anymore, and that's the strange part." },
		},
	},
	{
		theme = "Rumors and Whispers",
		title = "The Top of the Stairs",
		mood = "funny",
		lines = {
			{ kind = "say", text = "They say the innkeeper in Goldshire keeps a second ledger, just for travelers who set their hearthstone there and swear they've no idea why they keep coming back." },
			{ kind = "emote", text = "raises an eyebrow and gives the fire a slow, knowing look." },
			{ kind = "say", text = "She says it's the stew. It is not the stew. Everybody knows whose room is at the top of the stairs." },
		},
	},
	{
		theme = "Rumors and Whispers",
		title = "Mostly Rosewater",
		mood = "funny",
		lines = {
			{ kind = "say", text = "There's an alchemist in Undercity who sells love potions by the canals. Two silver a vial. People swear by them." },
			{ kind = "emote", text = "holds up an invisible vial and squints at it against the firelight." },
			{ kind = "say", text = "I had one tested. It's water, a little rosewater, and a label that says go on, ask them. Half her customers come back married." },
		},
	},
	{
		theme = "Rumors and Whispers",
		title = "Two Flashes",
		mood = "heartfelt",
		lines = {
			{ kind = "say", text = "Word is the keeper of the Westfall lighthouse flashes the lamp twice every night at the same hour, though there's never a ship on the water." },
			{ kind = "emote", text = "blinks twice, slowly, at the fire." },
			{ kind = "say", text = "Somewhere across the sea, they say, there's another light that answers twice. Thirty years now. Neither of them has ever crossed." },
		},
	},
	{
		theme = "Rumors and Whispers",
		title = "The Warmest Forge",
		mood = "funny",
		lines = {
			{ kind = "say", text = "They say the Great Forge in Ironforge burns hotter whenever a certain blacksmith walks past a certain miner. The apprentices have started timing it." },
			{ kind = "emote", text = "fans their face with one hand." },
			{ kind = "say", text = "Nobody has said a word to either of them. There's a betting pool. It's up to forty gold, and the forge has never run so warm." },
		},
	},
	{
		theme = "Rumors and Whispers",
		title = "Guaranteed or Your Money Back",
		mood = "funny",
		lines = {
			{ kind = "say", text = "There's a goblin in Gadgetzan who runs a matchmaking service. One gold to meet the love of your life, guaranteed or your money back." },
			{ kind = "emote", text = "rubs a thumb and two fingers together." },
			{ kind = "say", text = "He's never paid out a single refund. Everyone who asked for one was introduced to him." },
		},
	},
	{
		theme = "Rumors and Whispers",
		title = "Yes, Every Evening",
		mood = "heartfelt",
		lines = {
			{ kind = "say", text = "They say there's an old couple in Menethil Harbor, married fifty-nine years, and he still comes to her door every evening with flowers, like he's asking for the first time." },
			{ kind = "emote", text = "smiles into the fire, and doesn't say anything for a moment." },
			{ kind = "say", text = "And every evening she makes him wait on the step a while before she says yes. The whole street stops to watch. Nobody's ever seen her say no." },
		},
	},
	{
		theme = "Rumors and Whispers",
		title = "Cold Roses in Darkshire",
		mood = "spooky",
		lines = {
			{ kind = "say", text = "In Darkshire they say a ghost in a fine old coat leaves a single rose on the windowsill of whoever's sleeping alone at the inn." },
			{ kind = "emote", text = "lays an invisible flower down beside them, very carefully." },
			{ kind = "say", text = "The roses are real. They're just cold, and they never wilt. The innkeeper has a vase of them going back thirty years. She won't rent that room to a couple." },
		},
	},
	{
		theme = "Rumors and Whispers",
		title = "Notes in the Wall",
		mood = "funny",
		lines = {
			{ kind = "say", text = "Word in Orgrimmar is that two grunts on opposite watches leave notes for each other in the same loose stone in the wall. Rude notes. Very rude." },
			{ kind = "emote", text = "tucks something small into an invisible crack, glancing left and right." },
			{ kind = "say", text = "They've been insulting each other for two years now. Everyone knows. The whole barracks is waiting for the wedding." },
		},
	},
	{
		theme = "Rumors and Whispers",
		title = "Moonlight in Ashenvale",
		mood = "funny",
		lines = {
			{ kind = "say", text = "They say there's a lake in Ashenvale where couples go to swim by moonlight, and whoever comes out first has to carry both sets of clothes home." },
			{ kind = "emote", text = "coughs, and becomes very interested in the fire." },
			{ kind = "say", text = "One couple came out at the very same moment and argued about it until dawn. Then they noticed a bear had taken both piles. They walked home with their dignity, which wasn't much." },
		},
	},
})
