# Translating Fireside Tales

Fireside Tales is told out loud, in `/say` and `/emote`, by players sitting at a campfire. A
translation has to sound like a person telling a story to friends in that language, and like
it was written in that language first. Players will read it in chat next to real conversation,
so anything stiff, literal or machine-like stands out at once.

Languages: `deDE` German, `frFR` French, `esES` Spanish (Spain), `esMX` Spanish (Latin America),
`ruRU` Russian, `koKR` Korean. esES and esMX are separate translations, each in its own region's
Spanish and with its own client's official names.

## Where things go

Everything is `{ "English": "translation" }` JSON under `translations/<language>/`:

| File | What |
| --- | --- |
| `stories/<path>.json`, `Openers.json` | A story file's strings: titles, headings, summaries, lines, riddle hints and answers. Same path as the `.lua` file in `addon/FiresideTales/`. |
| `spoken.json` | Lines the addon says in chat by itself (a riddle's winner). |
| `ui.json` | The interface: buttons, tooltips, messages in the chat window. |
| `glossary.json` | The game's official names in that language (see below). |

`node tools/i18n/build.mjs --todo deDE stories/zones/Westfall.lua` prints what a file still
needs. `node tools/i18n/build.mjs` checks everything and writes the addon's `locales/` files; run
it after every change and fix what it reports. A story only shows translated when every one of
its strings is, so translate whole stories.

Read the English `.lua` file itself while translating, so each line has its story around it.

## The rules the checker enforces

- **250 bytes per chat line.** Bytes, not letters: Cyrillic letters are 2 bytes, Korean
  syllables 3, ä/é/ñ 2. `{target}` counts as 24. A line that won't fit becomes a list of parts,
  `["first part", "second part"]`, each said with its own press of Speak. Split at a natural
  pause (a sentence end, or a comma where a teller would breathe), never mid-phrase, and keep
  each part a sensible thing to say on its own. Prefer tightening the wording to splitting.
- Keep every `{target}` (the listener's name) and every `%s` / `%d`, in the same order.
- No `|` in story text, no line breaks, no leading or trailing spaces.
- Riddle answers (`"answers: ..."` keys) are a list of lowercase words that count as right:
  the common name, its plural or other forms players would type, and common short forms. Use
  the item's official name in that client.

## Sounding right

- **Retell, don't transliterate.** Keep what happens, who it happens to, the mood and the
  ending. Change the words freely to get there. Restructure sentences, split or merge clauses
  inside a line, pick the idiom a native teller would use.
- **Keep the line structure.** Line N of the translation is line N of the English (or its
  parts), and says the same beat. The voices play the English recording of that line.
- **Jokes have to land.** If a pun or wordplay doesn't survive, make a new one in the language
  that does the same job at the same moment. A punchline stays at the end of its line.
- **Register.** A storyteller at a fire: warm, spoken, a little theatrical. Not literary prose,
  not a quest log. Contractions and spoken forms where the language uses them.
- **Race voices.** Dwarves, trolls, orcs and others have a flavor in English (dropped letters,
  "ye", "mon"). Carry the flavor the way that language's own WoW client does for that race, if
  it does; otherwise keep it in word choice, not in broken spelling.
- **Official names only.** Zones, cities, NPCs, items, spells, races, classes and festivals use
  the names the game client shows in that language (`glossary.json`). Never invent a
  translation of a proper name the game already translates, and never translate one it
  leaves alone.
- **Titles** are short and natural, the way a book or song title reads in that language.
- **Emotes.** The game puts the teller's name in front: `/e pokes at the fire.` shows as
  `Mira pokes at the fire.` So an emote is a predicate in third person with the name as its
  subject, and must read correctly after a name:
  - German, French, Spanish, Russian: third-person singular verb first
    (`stochert im Feuer.`, `tisonne le feu.`, `atiza el fuego.`, `ворошит угли.`).
  - Russian: avoid past-tense forms that show gender (`наклонился/наклонилась`); use present
    tense, which doesn't.
  - Korean: the emote follows the name with no particle, so start with an adverb or object
    and end in the plain narrative form (`조용히 불씨를 뒤적인다.`), not a polite ending.
  - "their" for the teller stays neutral: `sein/ihr` is gendered in German, so prefer phrasing
    without it (`die Hand`, not `seine Hand`); the same in French and Spanish where possible.
- **The teller's gender** isn't known. Avoid forms that mark it in first-person speech too
  (Russian past tense: `я видел/видела`; French/Spanish adjectives about the speaker). Rephrase:
  present tense, a noun instead of an adjective, an impersonal turn.
- **Address.** The teller speaks to the people at the fire as friends: German `ihr`, French
  `vous` (plural), Spanish `vosotros` (esES) and `ustedes` (esMX), Russian `вы` (plural),
  Korean plain or `-요` speech, consistent within a story.
- **Typography.** French: a no-break space before `? ! : ;` is not needed in chat (it can't be
  typed reliably), so use a normal space before them and « » for quotes. German „ “, Spanish
  ¿ ¡ and « » or “ ”, Russian « », Korean “ ”.
- **Numbers, money and time.** Gold, silver, copper as the client names them. Keep in-world
  units ("leagues", "days' ride") in-world.

## Glossary

`glossary.json` has the client's own names, and the addon uses three parts of it:

```json
{
  "zones": { "Elwynn Forest": "Wald von Elwynn" },
  "zoneTerms": { "Elwynn Forest": ["Goldhain", "Nordhain"] },
  "festivals": { "Winter Veil": "Winterhauch" },
  "names": { "Hearthstone": "Ruhestein", "Thrall": "Thrall" }
}
```

- `zones`: every zone the stories are filed under (the keys of `ns.ZoneStories` and
  `ns.ZoneTerms` in `StoryData.lua`), exactly as `GetZoneText()` returns it in that client.
  The addon uses it to find the zone's stories, so it must match the game character for
  character.
- `zoneTerms`: the places in each zone from `ns.ZoneTerms`, in that language.
- `festivals`: each festival in `Seasons.lua` as that client's calendar names it.
- `names`: everything else that recurs (NPCs, items, factions, creatures), for consistency.
  The addon doesn't read it; translators do.
