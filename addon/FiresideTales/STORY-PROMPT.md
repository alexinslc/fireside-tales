# Writing stories for your characters

Fireside Tales shows a character's personal stories to any character with that first name. You can have an AI write them for you:

1. Copy everything under **The prompt** into your AI.
2. Fill in the **My characters** section at the end of it.
3. Paste what it writes at the end of `MyStories.lua`, below the existing lines, and save.
4. Restart WoW the first time you add stories. After that, `/reload` is enough.

To add more later, run the prompt again and paste the new blocks below your old ones.

Read the stories before you use them, since you're the one saying them out loud in the game. If your stories don't appear, the file probably has a mistake, and the game will usually show an error when it loads. You can paste that error back into your AI to fix it.

To check the file first, if you have PowerShell 7, run this from the addon's folder:

```
pwsh -ExecutionPolicy Bypass -File .\check-stories.ps1
```

When you get a new version of the addon, keep your `MyStories.lua` and replace everything else.

## The prompt

Write short roleplay stories for my World of Warcraft: Forever characters. They're for an addon called Fireside Tales. My character tells them one line at a time, sitting at a campfire with other players, using `/say` and `/e`.

### Output format

Output only Lua code in a single code block, using exactly this layout. Use one `ns.AddStories` block per character. Do not add `local _, ns = ...`, because my file already has it.

```lua
ns.AddStories("character", "Bram", {
	{
		title = "The Ferry at Dusk",
		mood = "heartfelt",
		lines = {
			{ kind = "emote", text = "turns a worn ferry token over in their fingers, watching the fire." },
			{ kind = "say", text = "My father ran a ferry on a brown river. He said every crossing was a promise you made to a stranger." },
			{ kind = "say", text = "The night the bridge fell, he made eleven trips in the dark. He came home soaked and told us it had been a slow evening." },
			{ kind = "emote", text = "sets the token on one knee and leaves it there." },
			{ kind = "say", text = "I've carried this ever since. I haven't found a promise as heavy, and I've been looking." },
		},
	},
})
```

Keep the same layout line for line, including one `{ kind = ..., text = ... },` per line of the story.

### Rules that keep the addon working

- The name after `"character",` must be the character's first name, spelled exactly as it is in the game, with one word only.
- `mood` must be exactly one of: `funny`, `heartfelt`, `dark`, `action`, `spooky`, `wise`.
- `kind` must be `say` or `emote`.
- Each story has 3 to 8 lines, with at least one `say` and at least one `emote`.
- Each line must be under 250 characters, because it's sent as one chat message.
- Use plain keyboard characters only. Don't use curly quotes, long dashes, accented letters, `|`, `{`, or `}` in the text.
- Don't use double quotes inside the text. Apostrophes are fine.
- Each title must be unique for that character.

### How to write them

- Write `say` lines in the first person, as if the character is talking to people at the fire.
- The game puts the character's name in front of an emote, so start every `emote` line with a lowercase verb, such as "leans toward the flames and lowers their voice."
- Every emote must work while sitting down. Act things out with the hands and upper body, and never stand, walk, kneel, or crouch.
- Use the campfire and the people around it as the stage. Don't describe a tavern table or a road ahead as if it's there.
- Don't say what listeners do, feel, or say, since they're other real players.
- Each story should have a clear hook, a turn, and an ending worth waiting for. Use real specifics rather than vague fantasy phrases, and keep the sentences easy to say aloud.
- Mix the moods, and don't let every story end on the same note.
- Fit each character's class, race, home, and backstory, and stay true to Warcraft's setting. Name real places when they fit, because the addon moves stories that mention a place to the top when the character is there.
- Write original stories. Don't retell existing Warcraft quests or books.

### My characters

Write **[how many, such as 15]** stories for each character.

- **First name:**
- **Race and class:**
- **Where they're from:**
- **Backstory, personality, and how they talk:**
- **Anything to include or avoid:**

(Copy this list for each character.)
