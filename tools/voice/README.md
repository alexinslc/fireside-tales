# Voices

Fireside Tales reads stories aloud. When someone nearby tells a story, or you do, each `/say` line
that matches one in `addon/FiresideTales/VoiceLines.lua` plays as a sound, in the voice of the
teller's race and sex. Without that voice, the narrator reads it. It only listens to chat. The teller
doesn't need the voices; each listener does.

`addon/FiresideTales/Voices.lua` finds the line, picks the voice and plays the sounds in turn.
`VoiceSettings.lua` is the Voices tab of the story menu. The sounds are in separate addons, the
voice packs, so a player downloads only the ones they want:

| Pack | Voices | Size |
| --- | --- | --- |
| `FiresideTalesVoices_<Race>` | one per race (Human, Dwarf, NightElf, Gnome, Orc, Undead, Tauren, Troll, Skyborne), its man and woman | 240 to 300 MB each |
| `FiresideTalesVoices_Narrator` | the narrator, for any teller without a race voice | about 130 MB |
| `FiresideTalesVoices_Community` | the lines only community stories have, in every voice | about 30 MB, new each week |

A pack per race isn't ideal, but CurseForge refuses an upload much over 500 MB (480 MiB went
through and 510 MiB didn't), and a faction's races together are about 1.3 GB. `build.mjs` says
when a pack is over. The Voices tab groups them as Alliance, Horde, Skyborne, Narrator, and
Community, so it stays short.

The sounds are Ogg Vorbis, mono, 44.1 kHz at about 48 kbps, as Spoken's quest audio is
(`config.json`'s `pack`).

Their CurseForge projects are at `curseforge.com/wow/addons/fireside-tales-voices-<race>` (like
`night-elf`). Narrator is 1812860 and Community 1812866 (the repository's
`CF_COMMUNITY_VOICES_PROJECT_ID`).

A pack needs Fireside Tales, and adds each of its voices with `FiresideTales_AddVoice`.
`config.json`'s `packs` says which voices go in each. Each pack is built whole by `build.mjs`, so
it's kept out of git.

Each race voice was designed with ElevenLabs Voice Design, read six lines from its race's stories
with expressive settings (and an accent tag where it has an accent), then copied to fish.audio from
that take. `tools/voice/audition.mjs` has the steps; `voice-audio/auditions/` keeps every take, so a
voice can be copied again.

## The steps

```sh
node tools/voice/lines.mjs                          # what's voiced, what has a take, what the rest costs
node tools/voice/generate.mjs                       # what it would make; spends nothing
node tools/voice/generate.mjs --spend --env-file ~/.config/fireside/voice.env
node tools/voice/generate.mjs --voice races --spend --concurrency 15 --env-file ~/.config/fireside/voice.env
node tools/voice/build.mjs                          # VoiceLines.lua and every pack (needs oggenc)
node tools/voice/build.mjs --pack FiresideTalesVoices_Narrator
luajit tools/voice/test-voices.lua                  # Voices.lua's own checks
luajit tools/harness/harness.lua                    # the whole addon, the Voices tab included
```

- `config.json`'s `voices` lists every voice: its title, order, race and sex for a race voice, and
  its voice id on each service. `voice` is the one used when a command has no `--voice`.
- `generate.mjs --spend` uses the `provider` in `config.json`:
  - `fish`: fish.audio with the voice's `fish` id. Needs `FISH_API_KEY`. Each request goes on a
    connection of its own, so `--concurrency` is how many run at once (fish.audio allows 15 on a
    balance of $100 or more).
  - `elevenlabs`: ElevenLabs with the voice's `elevenlabs` id. Needs `ELEVENLABS_API_KEY`.

  Put the keys in your shell or in one env file outside the repo (`--env-file`). Start with
  `--limit 20` or `--file Stories.lua`. Each take is saved as it's made, so a stopped run picks up
  where it left off, and running it again fills in any that failed.
- Switching the provider or a voice makes its lines need new takes. Earlier takes stay in
  `voice-audio/` (each file is named for its words, provider and voice), so switching back reuses them
  for free.
- `generate.mjs --provider say --spend` makes free test takes with the Mac's own voice, under the
  voice name `narrator-male-dev`. `build.mjs --voice narrator-male-dev` puts them in a test pack of
  their own, `FiresideTalesVoices_Test`.
- Masters and `takes.json` live in `voice-audio/` (or `$FIRESIDE_VOICE_DIR`). Both it and the
  packs are kept out of git. Back up `voice-audio/`: it's what was paid for.
- The packs' sounds are mono Ogg Vorbis (`config.json`'s `pack`). The game read our low-bitrate
  mp3s as shorter than they are and stopped them partway; Ogg plays to the end. `oggenc` makes them
  (`brew install vorbis-tools`), since ffmpeg's own Vorbis encoder is stereo only.

## Community stories

Lines only community stories have (from `Community.lua`) are in the community pack alone, never in
VoiceLines.lua or the main packs, since they change each week. The pack adds them with
`FiresideTales_AddLines`, along with its sounds for every voice, so its version is the newest week it
has (like `2026.11.17`), apart from Fireside Tales' own.

`.github/workflows/community-voices.yml` keeps it up to date. Each Monday evening (UTC), after
"Community stories" releases the week's stories, it:

1. brings back the takes it paid for earlier, from the `community-voices-state` GitHub release;
2. makes the new lines in every voice (`generate.mjs --voice all --community --max-dollars 15`), and
   stops before spending more than that;
3. keeps the takes for the lines `Community.lua` has now, so old weeks drop out;
4. builds the pack and uploads it to CurseForge if it changed.

It needs the `FISH_API_KEY` and `CF_API_TOKEN` secrets and the `CF_COMMUNITY_VOICES_PROJECT_ID`
variable. Run it by hand from the Actions tab to spend more than $15, or to upload again.

To do the same here:

```sh
node tools/voice/generate.mjs --voice all --community --spend --concurrency 15 --env-file ~/.config/fireside/voice.env
node tools/voice/build.mjs --pack FiresideTalesVoices_Community
```

## What's voiced

- Every `say` line in the addon's story files, keyed by its exact text. Character stories stay on
  your computer and are left out.
- `{target}` lines, with "friend" (or a line's own word from `config.json`'s `target`) said in place of
  the name. Voices.lua finds them by pattern, whatever name the teller used. Not riddle answers or
  imported stories.
- Emotes only when `config.json` says `"emotes": "teller"`, which reads them as "The teller pokes
  at the fire." With `"off"` they stay silent.

A line's file is named from its kind and text, so changing a line's words makes it need a new
take, and the old sound drops out of the packs at the next build.

## In the game

The story menu's Voices tab (the gear, last on the right) lists the packs: installed, or a button
with its CurseForge address to copy. It turns reading aloud on or off, picks who reads (race voices, or the narrator for every
story), turns hearing your own stories on or off, and plays a sample. `/tales voices` opens
it. Sounds play in turn at the game's Master volume (Dialog can cut a sound off partway); past two waiting lines, the oldest is dropped, so
a fast teller doesn't leave listeners behind.
