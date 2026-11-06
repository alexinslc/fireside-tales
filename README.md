# Fireside Tales

An addon for World of Warcraft: Forever that helps you roleplay. It offers an in-character line when something happens as you play, and each character gets a menu of short stories to tell one line at a time.

The addon never sends chat by itself. The game requires a key press or click for `/say` and `/e` outside instances, so every line waits for you to press Speak.

## Setup

1. Link the addon into the game, then restart the game so it finds the addon:

   ```powershell
   ./install-addon.ps1
   ```

2. Optional: bind keys under **Options > Keybindings > Fireside Tales** for Speak, Skip, and the story menu. The on-screen buttons work without them.

## Telling a story

1. Click the book icon on the minimap, or type `/tales stories`. Drag the icon to move it around the minimap's edge.
2. Narrow the list with the filters, then pick a story to preview it. Scroll either pane with the mouse wheel.
3. Press **Speak** to send the first line. The menu shrinks to the teller bar, so you can see the fire again. Keep pressing **Speak** for each line.

### The teller bar

The bar shows the next line and your progress. After each line, a gold cue shows roughly how long people need to read it. It's only a suggestion, so **Speak** always works. **Menu** goes back to the list, and closing the menu partway through a story returns you to the bar.

The bar also shows up to three recent `/say` and `/e` lines from people nearby, each for 45 seconds, and it's shorter when there's nothing to show. A line that uses your name, or a plain emote aimed at you, turns gold and makes a sound. The game may hide chat from addons in instances, and the bar only listens while it's open.

### Stories told to someone

The **Target Someone First** section holds stories that use your listener's name. Target them, then press **Speak**, which stays unavailable until you do. The name stays the same for the rest of the story, even if your target changes, until you restart it.

### Favorites, told stories, and Tonight

- **Favorite** stars a story in the list.
- A story's title turns gray once you've spoken its last line. It stays in the same place, since your audience changes from night to night.
- **Add to Tonight** lines up stories in the order you add them, at the top of the list. When one ends, **Next story** loads the next without saying anything. The list stays until you remove stories or choose **Clear Tonight's list** from the **Show** filter.

These are saved separately for each character.

### Filters

Each story in the list has a colored square for its mood, matching the **Mood** filter, and its number of lines on the right. In the reader, emotes are orange and speech is white.

Sections start closed, except Tonight, your current zone, and your character's own, so click a section's name to open or close it. Any filter opens every section that has a match.

The filters sit in one row above the list. They combine, and the count at the top shows how many stories match:

- **Search:** type any words. A story matches if its title, theme, mood, or text contains all of them, such as `bear` or `winter inn`.
- **From:** show only the stories for where you are, your character's own, your race's, your class's, the ones told to a target, the ones for everyone, or tales of places.
- **Mood:** Funny, Heartfelt, Dark, Action, Spooky, or Wise.
- **Show:** Favorites, stories you haven't told yet, or only Tonight's list.

**Clear** appears while a filter is on and resets all four.

**Restart** goes back to the first line. **Escape** closes the menu. Automatic prompts pause while the menu or teller bar is open, and your place in a story is kept until you pick another or `/reload`.

### What's in the list

The list is built for whoever you're logged in as, in this order:

1. **Tonight**, if you've added any
2. **Here in your zone**: tales of the zone you're in, plus any of your other stories that mention it or a place in it. It updates as you travel.
3. **Personal stories**, matched by the character's first name
4. **Race stories**, chosen from what the game reports
5. **Class stories**, chosen the same way
6. **Target Someone First**, told to one listener
7. **Shared stories**, available to everyone
8. **Tales of other places**, grouped by zone

A new character gets everything except personal stories automatically, and personal ones once you add them. To teach a zone new place names, add them to `ns.ZoneTerms` in `StoryData.lua`.

## Automatic prompts

A prompt appears when you enter a new zone, turn in a quest, level up, or come back from dying. Press **Speak** to say it or **Skip** to dismiss it, or ignore it and it disappears after 45 seconds. Drag either window to move it.

## Commands

| Command | What it does |
| --- | --- |
| `/tales stories` | Open or close the story menu |
| `/tales minimap` | Show or hide the minimap icon |
| `/tales on`, `/tales off` | Turn automatic prompts on or off |
| `/tales cooldown 60` | Minimum seconds between prompts (default 30) |
| `/tales status` | Show who the addon thinks you are, plus settings and story counts |
| `/tales test quest_done` | Show a prompt: `zone_enter`, `quest_done`, `level_up`, or `death`. Speak on a test prompt is real. |

## Adding your own

All of these are in `addon/FiresideTales/`:

- **A character's stories:** `StoriesCharacters.lua`, `MoreCharacters1.lua`, and `MoreCharacters2.lua`. To add a new character, add a block under their first name.
- **Race and class stories:** `StoriesRaces.lua`, `MoreRaces.lua`, `StoriesClasses.lua`, and `MoreClasses.lua`.
- **Stories for everyone:** `Stories.lua` and `MoreShared.lua`.
- **Tales of a zone:** `MoreZones.lua`, under the zone's name exactly as the game shows it.
- **Stories told to a target:** `StoriesTargeted.lua`. Write `{target}` where the name goes, and describe only what the teller does, never what the listener does or feels.
- **Automatic prompt lines:** `Lines.lua`.
- **Stories from someone else's copy:** `MyStories.lua`, which ships empty. `STORY-PROMPT.md` has a prompt that gets an AI to write them.

Each story needs a `title`, a `mood` (`funny`, `heartfelt`, `dark`, `action`, `spooky`, or `wise`), and `lines`. Shared stories also need a `theme`.

Stories are told sitting around a campfire, so write emotes that work while seated. Act out a past event with your hands and upper body, rather than standing, walking, kneeling, or crouching. Each line is one chat message, so keep it under 255 bytes. Emote lines begin with a verb because the game adds your name, and `|` isn't allowed in chat text.

Edits to these files load with `/reload`. A brand-new file needs a game restart and an entry in `FiresideTales.toc`. To catch mistakes before you load them, run:

```powershell
./tools/check-stories.ps1
```

## What's in the repository

The story files and built zips are listed in `.gitignore`, so they stay on this computer and have no backup on GitHub. A fresh clone runs but has an empty story menu until story files are added. `STORY-PROMPT.md` explains how to write some in `MyStories.lua`.

## Sharing it

`dist/FiresideTales-0.7.0.zip` is ready to send. To install it, extract it into `World of Warcraft\_forever_\Interface\AddOns\` so the files end up in `AddOns\FiresideTales\`, then restart the game.

To update someone's copy, send a new zip and have them keep their `MyStories.lua`. Everyone's copy includes the personal stories in this project, which only appear for characters with those first names.

## Removing it

This removes the link from the game and leaves your project files in place:

```powershell
./install-addon.ps1 -Uninstall
```

## Requirements

The WoW: Forever client (interface `16001`), and PowerShell 7 for the install script. Update `## Interface` in `FiresideTales.toc` when the client's version changes, or the game will mark the addon out of date.
