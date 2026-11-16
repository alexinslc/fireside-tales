# Plan: Fireside Tales read aloud through Spoken

Status: research and plan only. Nothing is built, and nobody has been contacted.
Read against Spoken at `rusty-key/spoken-wow` master `d28f91e` (2026-11-16) and Fireside Tales
`main` at `f7be862`.

## The goal

A player tells a story with Fireside Tales. Anyone nearby who has Spoken and a Fireside Tales
voice pack hears each line read aloud in a voice that fits the teller: a dwarf sounds like a
dwarf, a female troll like a female troll. The teller doesn't need the pack, and the listener
doesn't need Fireside Tales.

## What Spoken does today

**Its parts.** `Spoken` is the player: one sound queue, the narrator window and settings.
Quests, Gossip, World Chatter, Places, Readables and Bosses are feature addons that register
with it. `addons/Spoken/API.lua` is the public contract (`API_VERSION` 1). A feature addon checks
`Spoken:IsCompatible(1)`, calls `Spoken:RegisterSource(key, info)` and queues clips with
`source:Enqueue(clip)`. A clip is `{ key, path, length, priority, present = { header, label,
transcript, timings, portrait, ... } }`. The caller owns the file and the duration, because the
client can't measure a sound's length. Any addon can be a source, so a Fireside Tales pack needs
no change to Spoken.

**How it matches chat.** World Chatter (`addons/Spoken_Quests/Chatter.lua`) is the closest model.
It listens to `CHAT_MSG_MONSTER_SAY`, `_YELL` and `_WHISPER`, looks the speaker up by creature id
(or by name on Forever, which sends no GUID with NPC chat), and needs the text to equal a known
line once `$n`, `$r` and `$c` are filled in. It plays at low priority, keeps at most three clips
waiting (`queueLimit = 3`), turns the narrator off (`noNarrator`, since the chat bubble already
shows the words), and won't repeat a line within two minutes. Gossip matches by speaker and the
words they share, with a similarity floor. Nothing in Spoken listens to player chat
(`CHAT_MSG_SAY` or `CHAT_MSG_EMOTE`).

**How it picks a voice.** Voices are named `race-gender-flavor`: `dwarf-male-grim`,
`nightelf-female-priestess`. Each playable race and sex has two or three NPC voice sets in the
game, recorded by different actors. `pipelines/quests/tts_cli/flavors.py` reads which one each NPC
uses from the game's SoundEntries names. Where the data has no answer, it uses "standard", or the
most common flavor if there's no standard (dwarf-female, goblin-female, goblin-male and
tauren-male have no standard). That gives about 54 voices. Forever's elves have two voice sets per
sex, named `skybourneelf-male-3776` and so on. `narrator-male` reads stage directions.

**How it makes the audio.**
- ElevenLabs voices are instant clones made from the game's own NPC greeting clips. The clips are
  merged into one to two minutes of audio per voice and kept in `voice/seed-clips/<race-gender>/<flavor>/`,
  which is gitignored and local only. A clone can't be exported, so the voices exist only in the
  author's ElevenLabs account and in those local clips.
- The settings are in `pipelines/quests/voice/generation.json`, but the site's `/voices` page
  overrides them: `eleven_v3`, stability 0.5, similarity 0.75, style 0, speaker boost on.
  The seed is fixed per NPC (crc32 of the NPC id), so all of one NPC's lines sound like one
  performer. Dwarf lines get a `[Scottish accent]` tag. There's a per-language pronunciation
  dictionary. Requests send no `output_format`, so the masters are ElevenLabs' default mp3.
- fish.audio is the second option (`apps/web/src/lib/generation/fish-tts.ts`). It works without
  saved voices: each request sends a 10 to 30 second reference clip of the voice with its exact
  transcript. The default model is `s2.1-pro`. Paragraphs are generated one at a time and joined
  with 0.9 s of silence.
- Packs ship Ogg Vorbis `-q 0` at 44.1 kHz (about 49 kbps), measured in
  `docs/quests/docs/pack-size.md`. Ogg at `-q -1` and 22.05 kHz (about 23 kbps) was tried and is
  roughly half the size.
- Spoken's repo never spends credits. Every take is made on the spoken.quest server, on the
  account of whoever is signed in, and stored in an archive (R2, named by SHA-256).

**Its pack format.** Community packs (`community/README.md`) are zips holding one folder,
`SpokenCommunity_<id>`. They're listed on spoken.quest, reviewed by an admin, and installed by the
Spoken Manager. The Manager only lists the `quests`, `places` and `readables` sections, so there's
no slot for a pack like ours yet. A pack is loaded by what its `.toc` and Lua say. Ours would just
be an addon that registers its own source.

**Licensing.** Spoken's code is MIT. `THIRD_PARTY.md` says the MIT grant doesn't cover game text,
lore or audio. The voice clones come from Blizzard's recordings, and Spoken treats that as fan
work. The community packs say "non-commercial" in their license field.

## 1. How a pack knows a line and its teller

**Recommended: match the chat line on the listener's side, and get race and sex from the sender's
GUID.**

1. The pack listens to `CHAT_MSG_SAY` (and `CHAT_MSG_EMOTE` if emotes are voiced, see below).
2. It normalises the text the way the site's `tidyText` does and looks it up in a table built from
   every voiced line. Story text is fixed and every line is unique enough that the text itself
   can be the key. A line with `{target}` becomes a pattern: everything before and after the name
   must match exactly, and the name is the gap.
3. Race and sex come from `GetPlayerInfoByGUID(guid)`, using the GUID in `CHAT_MSG_SAY`'s 12th
   argument (`englishRace`, `sex`). If that's missing or the result is a secret value, it falls
   back to scanning target, mouseover and nameplates for a unit with the sender's name and reading
   `UnitRace` and `UnitSex`. If both fail, the pack picks a voice from the sender's name so the same
   teller always gets the same one.
4. It picks the file for that voice and queues it on its own source, `fireside`.

Why this way:
- Fireside Tales needs no change, and every teller on every version is heard.
- A `/say` line already only reaches people nearby, which is exactly who should hear it.
- A teller of the other faction speaks a language the listener can't read, so the text doesn't
  match and nothing plays. That fits the game, and it's what lets packs be split by faction.

**Addon messages**, considered and not chosen as the main path. `C_ChatInfo.SendAddonMessage` only
reliably reaches party, raid, guild, whisper or a custom channel, and people at a campfire often
aren't grouped. Whether `SAY` works as an addon channel in the open world on Forever is untested.
They're worth adding later, as an extra: a message to the party or raid with
`{ story id, line number, race, sex }` would cover `{target}` and the riddle replies, and anything
else chat matching misses for group members. That would need a small change in Fireside Tales,
listed in section 5.

**Which voice within a race and sex.** Use one storyteller voice per race and sex, Spoken's
fallback flavor ("standard", or the most common). Picking a flavor per teller would double or
triple the audio. A later version could choose between two flavors with a hash of the teller's
name.

**Lines this doesn't cover:**
- **Emotes.** The game already shows "Thorgrim pokes at the fire." Leave them silent at first.
  Spoken hands stage directions to `narrator-male`, but the narrator would have to say the
  teller's name, which can't be recorded ahead of time. A short sound like `[sighs]` in the
  teller's own voice might work for some emotes later.
- **`{target}` stories** (121 say lines). The name can't be recorded ahead. Options: skip them,
  record them with "friend" in place of the name, or record the parts around the name and leave a
  short gap. **Needs a decision.**
- **Riddle answers and winners** are made up during play, so they stay silent.
- **Players' own imported stories** have no audio. One possible fallback is the game's own
  text-to-speech (`C_VoiceChat.SpeakText`), which uses the computer's voices and not the
  race-matched ones. Whether Forever has it is untested.

**Timing.** The teller bar suggests waiting 4 to 14 seconds per line (`readSeconds`: 3 seconds
plus one per 20 bytes). Speech runs about 15 characters a second, so a 120-byte line is about
8 seconds and a 250-byte line about 16 seconds. Long lines can run past the next line, so set
`queueLimit` to about 2 and drop the oldest waiting clip rather than fall further behind.

## 2. Making the audio

**Voices.** Use Spoken's roster, one voice per race and sex: human, dwarf, night elf, gnome, orc,
troll, tauren and Forsaken (`scourge`), plus Forever's Skyborne races. That's about 18 to 20
voices.

Checked on 2026-11-16 with a signed-in ElevenLabs account: Spoken's voices aren't in ElevenLabs'
public voice library. Searches for warcraft, azeroth, dwarf, forsaken, spoken and the slot names
found nothing of theirs. They're private clones, and Spoken looks them up by name in whichever
account is generating. On spoken.quest, anyone allowed to generate in a language can hear a
voice's source clips and clone them into their own ElevenLabs account (`apps/web/src/lib/voices/authz.ts`).
Each collaborator then generates on their own key and pays for their own credits.

There are four ways to get voices, best first:

1. **Clone them on spoken.quest with our own key.** The author gives us access to generate in
   English. We clone the 18 to 20 voices we need into our account from the site's source clips,
   then generate with our own key and settings. This gives the exact voices and costs the author
   nothing except granting access. The catch is that it needs voice slots: our Starter plan has 10
   and 166k credits a month, so all the voices at once needs Creator (30 slots) or higher.
1b. **Spoken's author makes the takes** on spoken.quest, as a Fireside Tales section or team. Their
   `TEAMS.md` describes audio teams with their own voices, settings and releases (designed
   2026-10-31, phase 2 not built). This gives the exact voices and settings, plus their review and
   archive tools. It depends on the author agreeing.
2. **The author shares fish.audio reference clips** (or the merged clone sources) for the voices
   we need. fish.audio sends the reference with every request, so the clips are all we'd need to
   match Spoken's fish voices with our own key: `s2.1-pro`, one paragraph per request, mp3 out.
3. **We build our own voices** the same way Spoken does, from the game's NPC greeting clips for
   each race and sex, cloned with ElevenLabs or used as fish.audio references. These would be close
   to Spoken's voices but not the same, and they carry the same Blizzard-audio question.
4. **Use voices from the ElevenLabs library.** It has some general fantasy voices, such as an orc
   or troll ("Azgar"), a gnome ("Grimblewood Thornwhisker") and an elf ("Elowen"). They don't
   cover every race and sex, and they won't sound like Spoken or the game. But they need no clips
   from the game and no one's permission, and anyone with a paid plan can use them.

Settings, if we generate it ourselves: copy Spoken's. With ElevenLabs that's `eleven_v3`,
stability 0.5, similarity 0.75, style 0, speaker boost on, the dwarf `[Scottish accent]` tag, and
a fixed seed per voice (not per NPC, since we have none). With fish.audio, use Spoken's references
and model. Strip any square brackets from story text first, since `eleven_v3` reads them as
directions. Encode to Ogg Vorbis the way Spoken's packs are.

**What it costs and how big it gets.** These are estimates from the current data: 2,582 built-in
say lines averaging 120 bytes (310,770 bytes in all), and 100 community stories a week at about
4.5 say lines each.

| | Built-in stories | One community week |
| --- | --- | --- |
| Say lines | 2,582 (400 are race stories, which need only that race's 2 voices) | about 450 |
| Characters to generate, all voices | about 5.3 million | about 1.1 million |
| Audio per faction pack (about 10 voices) | about 48 hours | about 10 hours |
| Size per faction, ogg q0 44.1 kHz | about 1 GB | about 220 MB |
| Size per faction, ogg q-1 22.05 kHz | about 500 MB | about 105 MB |

On ElevenLabs, 1.1 million characters a week is far more than the 100k a month that a Creator
plan includes (check current plans), so voicing all of it every week isn't affordable at their
rates. fish.audio charges far less per character, so it's the realistic choice for weekly audio
(check current pricing). Either way, start small:

- **Phase 1:** a sample of about 20 built-in stories in every voice. That's enough to hear whether
  it works and to settle the questions below.
- **Then:** the built-in catalog, split by faction. Race stories only need their own race.
- **Community weeks:** start with a curated list each week, say 10 to 20 stories marked as voiced
  when they're approved, and grow it only if the cost and size hold up.

**What it would cost.** Prices checked on 2026-11-16. ElevenLabs charges 1 credit per character
with `eleven_v3`. Its plans are Creator at $22 a month (121k credits, 30 voice slots), Pro at $99
(600k), Scale at $299 (1.8M) and Business at $990 (6M). fish.audio has no subscription and charges
$15 per million bytes of text with `s2.1-pro`. Every story needs about 20 voices, so one story with
about 540 bytes of say lines costs about 11k credits.

| What's voiced | Credits | ElevenLabs | fish.audio |
| --- | --- | --- | --- |
| Sample of 20 stories | about 220k | 2 months of Creator ($44), or 1 month of Pro ($99) | about $3 |
| Every built-in story, once (2,400 say lines, not counting `{target}` and riddle lines) | about 5.0M | 1 month of Business ($990), or about 3 months of Scale ($900) | about $75 |
| 10 community stories a week | about 470k a month | Pro, $99 a month | about $7 a month |
| All 100 community stories a week | about 4.7M a month | Business, $990 a month | about $70 a month |

Creator alone covers about 11 stories a month. Flash and Turbo models cost half as much on
ElevenLabs, but they don't handle v3's tags like `[Scottish accent]`.

**Starting with one narrator voice.** Every story, from every teller, is read in one voice, and the
race voices come later. Costs and sizes drop by about 20 times:

| What's voiced | Credits | ElevenLabs | fish.audio | Pack size (ogg q0) |
| --- | --- | --- | --- | --- |
| Every built-in story, once | about 300k | 1 month of Pro ($99), or 3 months of Creator (about $55 with the first-month discount) | about $4.50 | about 120 MB |
| All 100 community stories a week | about 235k a month | Pro, $99 a month (Creator covers about 50 stories a week) | about $3.50 a month | about 22 MB a week |

What this changes:
- No race or sex lookup, so the GUID test on Forever (open question 1) can wait. Matching the chat
  line is all that's needed.
- No faction split. One pack covers everyone.
- Emotes can be read too: the narrator saying "pokes at the fire" fits better than a teller voice
  would. Leaving out the teller's name still needs a decision. That adds about 53k credits for the
  built-in stories.
- Spoken's narrator is `narrator-male`, the one voice behind Places, Readables, Bosses and the stage
  directions in Quests. It's an ElevenLabs Voice Design voice (`ggodpz28jXGN11DlccGk` since
  2026-08-09, from the old `zones/tools/voice/config.json`), with `eleven_v3`, stability 0.5,
  similarity 0.75 and speaker boost on. It's private to the author's account: our key gets
  "voice not found", and it isn't in the library. To use the same voice on fish.audio, take 10 to 30
  seconds of clean narration from Spoken's Places pack, with its exact text, and use it as a
  fish.audio reference. That needs the author's permission. The other way is for them to share
  the voice with our ElevenLabs account, which means paying ElevenLabs rates.
- The narrator doesn't have to be Spoken's `narrator-male`. A library voice or one we design works,
  so the first version needs nothing from Spoken's author but its public API. Their voices become a
  question for the second phase only.
- A male and a female narrator, picked by the teller's sex, doubles the cost and brings the GUID
  question back. Leave that for later.
- Keep the voice in the file path (`narrator/<hash>.ogg`), so race voices can be added beside it
  later without renaming anything.

**Naming the files.** Name each file after its text and voice, for example
`<voice>/<sha1(text)[:12]>.ogg`. The same words in the same voice are one file wherever they
appear, a fixed typo only regenerates that line, and community stories need no other id. Spoken
does the same: a gossip file is `md5(text + race + gender)`.

## 3. Keeping up with weekly community stories

Today, an approval on firesidetales.dev fires a `repository_dispatch` and the job also runs daily.
Each run rewrites `Community.lua`, and Monday at 18:00 UTC the job releases a new version if it
changed.

**Recommended: make the audio when a story is approved, and package it at release time.**

- **When a story is approved** (or edited after approval), queue its say lines for generation in
  every voice of its faction set. Store the masters in R2 by file name. Because the files are keyed
  by text, an edit only regenerates the lines it touched. Generating early spreads the cost over
  the week, and an admin can listen to a take on the admin page before Monday. If the site's
  Worker can't call the TTS service in time, a GitHub job can drain the queue instead.
- **At release time** (the same Monday job, or a second job right after it), build the voice pack:
  the line table (text or pattern, file, length), the ogg files for the weeks the pack carries,
  and a version bump. Then upload it. The durations come from the encoded files (`ffprobe`), since
  the client can't measure them.
- **What the pack carries:** the built-in audio, plus the current and next community weeks. That's
  less than `Community.lua`, which keeps 4 past weeks, because audio is so much bigger. Splitting
  it into a "core" pack that rarely changes and a small weekly "community" pack means the weekly
  download is only about 100 to 200 MB per faction, or much less with a curated list.
- **Release schedule:** weekly, with the Fireside Tales release. A story without audio yet just
  plays nothing.

## 4. Questions for Spoken's author

Ask before building anything that depends on their voices:

1. May we use your voices (the ElevenLabs clones, or the fish.audio references or seed clips) for
   Fireside Tales lines? Under what terms, and with what credit?
2. Could we get access to generate in English on spoken.quest, so we can clone the voices into our
   own ElevenLabs account and pay for our own credits? Or would you rather make the takes yourself,
   as a section or team for us?
3. Can the Spoken Manager list a pack outside `quests`, `places` and `readables`, or would you add
   a section for it? Or should we just ship on CurseForge?
4. Is `RegisterSource` with `CHAT_MSG_SAY` matching the way you'd want a third-party source to
   work? Is there a priority, queue limit or setting you'd want us to use, or anything we
   shouldn't do?
5. Have you checked whether player chat on Forever carries a GUID, or whether `GetPlayerInfoByGUID`
   returns secret values there?
6. The voices come from Blizzard's recordings. Do you have any guidance from Blizzard or
   CurseForge on that, and should our packs also say "non-commercial"?
7. What should the credit line say? Their packs say things like "Voices designed with ElevenLabs".

And on our side:

- Community authors agreed to have their stories shown in game, not read aloud by a synthetic
  voice. Add that to the submission terms before voicing community stories, and let authors opt
  out. Don't voice stories submitted before the change without asking. The site and addon still
  mustn't suggest that AI approves stories. Saying the voices are synthetic is a separate thing,
  and we should say it.
- Fireside Tales is MIT, so the story text is ours to voice. Community story text belongs to
  whatever the submission terms say.

## 5. Changes in Fireside Tales

None are needed for the first version. The pack lives in its own addon and reads only chat.

Useful later, in rough order:
1. **A line manifest from the build:** a Node script, next to `tools/build-community.mjs`, that
   parses the addon's story tables and `Community.lua` and writes `voice-lines.json` (text, kind,
   story key or id, race key, target or not). It's the single input to generation and to the
   pack's lookup table, and it needs no change to the addon itself.
2. **Site:** a voiced status on approved stories and an approval-time generation queue (D1 table
   `voice_takes`: line hash, voice, status, R2 key, length), plus playback on the admin page and the
   submission-terms change above.
3. **Addon:** an optional party or raid addon message on each line, for `{target}` and riddle
   lines (section 1).
4. **Addon:** if the teller has the pack, the teller bar could wait for the clip to finish before
   suggesting the next line. That would use the pack's lengths, and nothing ever sends on its own.
5. **Release:** a job that packages and uploads the voice packs after `community.yml` releases.

Keep the standing rules: nothing is sent without a key press, never `/run`, and every line stays
under 250 bytes. Voicing doesn't change any of them.

## 6. Open questions

1. Does `CHAT_MSG_SAY` on Forever carry the sender's GUID, and does `GetPlayerInfoByGUID` return
   plain race and sex for a nearby stranger? (Test in game with two characters.)
2. Which faction is each Skyborne race on, and which Spoken voice set should each use?
3. What to do with `{target}` stories: skip them, say "friend", or leave a gap for the name?
4. Should emotes stay silent, or use the narrator or sound tags?
5. ElevenLabs or fish.audio, and what's the weekly budget? That decides how many community stories
   get voiced.
6. Ship on CurseForge, in the Spoken Manager, or both? What are the pack names (for example
   `FiresideTalesVoices_Alliance`, `_Horde`, `_Community`)?
7. Should the teller hear their own story? (`CHAT_MSG_SAY` fires for your own lines too.) Default
   to off.
8. Does Forever have `C_VoiceChat.SpeakText`, as a fallback for imported stories?

## 7. Rough order of work

1. **Ask Spoken's author** (section 4). Don't build on their voices until they answer.
2. **Spike in game, no audio:** a test addon that logs `CHAT_MSG_SAY` arguments and
   `GetPlayerInfoByGUID` results while a second character tells a story. Answers questions 1 and 2.
3. **Line manifest script** (section 5, item 1) and a lookup table built from it.
4. **Pack addon skeleton:** register the `fireside` source, match chat, choose a voice, and queue
   clips. Test it with a few hand-made clips, then add a harness test like `tools/harness`.
5. **Sample voicing:** about 20 stories in every voice, from whichever voice source is agreed.
   Listen, tune the settings, and check the timing against the teller bar.
6. **Built-in catalog** for each faction pack. Check sizes and release.
7. **Community pipeline:** approval-time generation on the site, packaging at release, a curated
   weekly list, and the submission-terms change.
8. **Extras:** the addon message for group members, `{target}` handling, teller-bar timing, and
   emotes.
