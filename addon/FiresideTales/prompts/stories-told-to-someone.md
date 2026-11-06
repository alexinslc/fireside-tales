# Stories told to someone

Stories told to one listener, using their name. You target someone first.

Copy everything below the line into an AI, and fill in the bracketed parts. Then paste what it writes into **Add Stories** in the game.

---

Write short roleplay stories for World of Warcraft: Forever. They're for an addon called Fireside Tales. A player tells them one line at a time, sitting at a campfire with other players, using `/say` and `/e`.

Write **[how many, such as 10]** stories told directly to one person at the fire.

The listener may be a stranger of any race or class, so don't assume any history with them. Say what the teller does, and never what the listener does or feels.

### Output format

Output only plain text in a single code block, exactly in this form. Don't add anything else.

```
TARGET:
TITLE: The Empty Seat
MOOD: heartfelt
EMOTE: looks across the flames at {target} and nods, as if something has been settled.
SAY: I keep a spot open at my fire, {target}. Someone I traveled with always sat there, and it felt wrong to let it go cold.
SAY: For two years nobody sat in it. Folk could tell, I suppose. Then one evening I stopped keeping it, and I can't tell you why.
EMOTE: pats the ground beside them, then lets the hand rest.
SAY: Anyway, {target}. It's good to have you here. It's a warmer fire with someone on the other side of it.
```

Start a new `TITLE:` line for each story. Put one `TARGET:` line at the very top, with nothing after it. Write `{target}` wherever the listener's name goes, at least once in each story.

### Rules that make it work

- `MOOD` must be exactly one of: `funny`, `heartfelt`, `dark`, `action`, `spooky`, `wise`.
- Each story has 3 to 8 `SAY` and `EMOTE` lines in total, with at least one of each.
- Each line must be under 220 characters, because it's sent as one chat message. Keep each one on a single line.
- Don't use `|`, `{`, or `}` in the text. The one exception is `{target}`.
- Each title must be unique.

### How to write them

- Write `SAY` lines in the first person, as if talking to people at the fire.
- The game puts the character's name in front of an emote, so start every `EMOTE` line with a lowercase verb, such as "leans toward the flames and lowers their voice."
- Every emote must work while sitting down. Act things out with the hands and upper body, and never stand, walk, kneel, or crouch.
- Use the campfire and the people around it as the stage. Don't describe a tavern table or a road ahead as if it's there.
- Emotes are beats inside the story. Don't add any that exist only to fill space.
- Don't say what listeners do, feel, or say, since they're other real players.
- Each story needs a clear hook, a turn, and an ending worth waiting for. Use real specifics rather than vague fantasy phrases, and keep the sentences easy to say aloud.
- Mix the moods, and don't let every story end on the same note.
- Stay true to Warcraft's setting. Name real places when they fit, because the addon moves stories that mention a place to the top when you're there.
- Write original stories. Don't retell existing Warcraft quests or books.
