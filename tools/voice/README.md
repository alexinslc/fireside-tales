# Voices

Fireside Tales Voices (`addon/FiresideTalesVoices`) reads stories aloud through [Spoken](https://github.com/rusty-key/spoken-wow).
When someone nearby tells a story, each `/say` line that matches one in the pack plays in the
narrator's voice. The pack only listens to chat. The teller doesn't need it, and the listener
doesn't need Fireside Tales. The plan behind it is in `docs/spoken-plan.md`.

## The steps

```sh
node tools/voice/lines.mjs                          # what's voiced, what has a take, what the rest costs
node tools/voice/generate.mjs                       # what it would make; spends nothing
node tools/voice/generate.mjs --spend --env-file ~/.config/fireside/fish.env
node tools/voice/build.mjs                          # Sounds/ and Lines.lua for the pack
luajit tools/voice/test-voices.lua                  # the pack's own checks
```

- `generate.mjs --spend` uses the `provider` in `config.json`:
  - `fish`: fish.audio with the voice `fish.referenceId`. Needs `FISH_API_KEY`.
  - `elevenlabs`: ElevenLabs with the voice `elevenlabs.voiceId`, and the same model and settings
    Spoken's narrator uses (`eleven_v3`, stability 0.5, similarity 0.75, speaker boost). Needs
    `ELEVENLABS_API_KEY`.

  Put the keys in your shell or in one env file outside the repo (`--env-file`). Start with
  `--limit 20` or `--file Stories.lua`. Each take is saved as it's made, so a stopped run picks up
  where it left off.
- Switching the provider or its voice makes every line need a new take. Earlier takes stay in
  `voice-audio/` (each file is named for its words, provider and voice), so switching back reuses them
  for free.
- `generate.mjs --provider say --spend` makes free test takes with the Mac's own voice, under the
  voice name `narrator-dev`. Build them with `build.mjs --voice narrator-dev`.
- Masters and `takes.json` live in `voice-audio/` (or `$FIRESIDE_VOICE_DIR`). Both it and the pack's
  `Sounds/` are kept out of git. Back up `voice-audio/`: it's what was paid for.

## What's voiced

- Every `say` line in the addon's story files, keyed by its exact text. Character stories stay on
  your computer and are left out.
- Not `{target}` lines, since the name can't be recorded ahead, or riddle answers, or imported
  stories.
- Emotes only when `config.json` says `"emotes": "teller"`, which reads them as "The teller pokes
  at the fire." With `"off"` they stay silent.

A line's file is named from its kind and text, so changing a line's words makes it need a new
take, and the old sound drops out of the pack at the next build.

## In the game

`/ftvoices` shows the status. `/ftvoices test` plays a line. `/ftvoices own` turns hearing your own
stories on or off (on by default). Spoken's page lists the pack as Fireside Tales, with its own
switch.
