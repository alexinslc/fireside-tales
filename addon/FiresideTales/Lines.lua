-- Lines offered automatically when something happens.
-- Placeholders: {zone} (all), {quest} (quest_done), {level} (level_up).
-- A line using a placeholder the game can't fill in right then is skipped.
local _, ns = ...

ns.PromptLines = {
	zone_enter = {
		{ kind = "say", text = "So this is {zone}. Let's see what it wants from me." },
		{ kind = "say", text = "{zone}. I'd heard stories. I suppose I'll find out which ones were true." },
		{ kind = "say", text = "Someone told me to stay out of {zone}. Now I'm curious." },
		{ kind = "say", text = "Hm. {zone}. Smells like trouble, or possibly supper." },
		{ kind = "say", text = "Never thought I'd see {zone} with my own eyes." },
		{ kind = "say", text = "{zone}, is it? My boots had better be up to this." },
		{ kind = "say", text = "I've got a good feeling about {zone}. I've been wrong before, mind you." },
		{ kind = "emote", text = "pauses at the edge of {zone} and takes in the road ahead." },
		{ kind = "emote", text = "tightens a strap and walks on into {zone}." },
		{ kind = "emote", text = "checks a battered map, frowns, and decides this must be {zone}." },
		{ kind = "emote", text = "takes a slow breath of the air in {zone}." },
		{ kind = "emote", text = "keeps one hand near their weapon as they enter {zone}." },
	},
	quest_done = {
		{ kind = "say", text = "That's \"{quest}\" finished. On to the next thing." },
		{ kind = "say", text = "Done, and nobody can say I didn't earn it." },
		{ kind = "say", text = "Well, that's that. Easier than I expected. Don't tell them I said so." },
		{ kind = "say", text = "\"{quest}.\" One more story to tell at the fire." },
		{ kind = "say", text = "Another job done. I should really start charging more." },
		{ kind = "say", text = "If anyone asks, it was much more dangerous than it looked." },
		{ kind = "say", text = "Glad that's over. What's next?" },
		{ kind = "say", text = "I'll be telling people about \"{quest}\" for a while, whether they like it or not." },
		{ kind = "emote", text = "crosses \"{quest}\" off a worn list with a satisfied nod." },
		{ kind = "emote", text = "lets out a long breath, the job finally behind them." },
		{ kind = "emote", text = "counts their reward twice, just to be sure." },
		{ kind = "emote", text = "dusts off their hands and looks around for the next bit of trouble." },
	},
	level_up = {
		{ kind = "say", text = "I feel it. Stronger than I was this morning." },
		{ kind = "say", text = "Hah! A month ago that would have flattened me." },
		{ kind = "say", text = "Every scar's been a lesson. I think that last one finally sank in." },
		{ kind = "say", text = "I'm getting better at this. Don't let it get around." },
		{ kind = "say", text = "Something's changed. I can feel it in my hands." },
		{ kind = "emote", text = "rolls their shoulders, feeling newly capable." },
		{ kind = "emote", text = "stands a little taller, as though a weight has lifted." },
		{ kind = "emote", text = "flexes their hands and grins at nothing in particular." },
		{ kind = "emote", text = "tests their footing and nods, surer of themselves than before." },
	},
	death = {
		{ kind = "say", text = "Well. Let's not do that again." },
		{ kind = "say", text = "Back on my feet. {zone} won't be rid of me that easily." },
		{ kind = "say", text = "I meant to do that. All part of the plan." },
		{ kind = "say", text = "Note to self: that was a bad idea." },
		{ kind = "say", text = "I've had worse. I can't recall when, but I'm sure I have." },
		{ kind = "say", text = "Everything hurts. That's a good sign, I'm told." },
		{ kind = "say", text = "All right, {zone}. That's one to you." },
		{ kind = "emote", text = "staggers upright and checks that everything is still attached." },
		{ kind = "emote", text = "groans, picks themselves up, and spits out some dirt." },
		{ kind = "emote", text = "looks back at the spot where it all went wrong and shakes their head." },
		{ kind = "emote", text = "dusts themselves off and pretends nothing happened." },
	},
}
