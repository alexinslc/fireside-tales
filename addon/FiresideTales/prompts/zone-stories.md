# Tales of a zone

Tales of one place. They rise to the top of the list when you're in that zone.

Copy everything below the line into an AI, and fill in the bracketed parts. Then paste what it writes into **Add Stories** in the game.

---

Write short roleplay stories for World of Warcraft: Forever. They're for an addon called Fireside Tales. A player tells them one line at a time, sitting at a campfire with other players, using `/say` and `/e`.

Write **[how many, such as 5]** stories for each of these zones: **[zones, such as Westfall and Duskwood]**.

Root each story in that zone's real places and history, and tell it as something the teller saw or heard there. Don't assume the teller's race or class.

### Output format

Output only plain text in a single code block, exactly in this form. Don't add anything else.

```
ZONE: Westfall
TITLE: The Scarecrow's Coat
MOOD: spooky
EMOTE: tugs at their own collar and glances toward the dark past the firelight.
SAY: There's an empty farm on the road out of Sentinel Hill, with a scarecrow still standing in the field. It wears a good wool coat.
SAY: I was cold, so I took the coat. Next morning, a mile up the road, I found the scarecrow standing in a new field.
EMOTE: slowly shrugs off an invisible coat and lays it aside.
SAY: I left that coat on a fence post. It seemed to me that someone would be along for it.
```

Start a new `TITLE:` line for each story. Use one `ZONE:` line per zone, spelled exactly as the game shows it, and put its stories below it.

### Rules that make it work

- `MOOD` must be exactly one of: `funny`, `heartfelt`, `dark`, `action`, `spooky`, `wise`.
- Each story has 3 to 8 `SAY` and `EMOTE` lines in total, with at least one of each.
- Each line must be under 220 characters, because it's sent as one chat message. Keep each one on a single line.
- Don't use `|`, `{`, or `}` in the text.
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
