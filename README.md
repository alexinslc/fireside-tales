# Fireside Tales

An addon for telling stories at the campfire in World of Warcraft: Forever, one line at a time, using `/say` and `/e`. It works on Windows and macOS.

It comes in two halves:

- **The storytelling:** a story menu with filters, a small teller bar, favorites, and an evening list.
- **The stories:** a starter set that fits any character, plus prompts that get an AI to write more for yours, which you paste in from inside the game.

The addon never sends chat by itself. The game requires a key press or click for `/say` and `/e` outside instances, so every line waits for you to press Speak.

## Setup

1. Close the game and extract the zip into your AddOns folder, so its files end up in `AddOns/FiresideTales/`:

   - **Windows:** `C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\`
   - **macOS:** `/Applications/World of Warcraft/_forever_/Interface/AddOns/`

   Create the `AddOns` folder if it isn't there. Your game may be installed somewhere else.

2. Start the game. If addons load individually, turn on Fireside Tales at the character screen.

3. Optional: bind keys under **Options > Keybindings > Fireside Tales** for Speak, Skip, and the story menu. The on-screen buttons work without them.

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

To teach a zone new place names, add them to `ns.ZoneTerms` in `StoryData.lua`.

## Adding stories with AI

1. Pick a prompt from the addon's `prompts` folder, copy it into an AI, and fill in the bracketed parts. There are prompts for one character, a race or class, a zone, everyone, and stories told to someone by name.
2. In the game, press **Add Stories** in the menu, or type `/tales add`.
3. Paste what the AI wrote and press **Add**. A few stories at a time works best.

The window says how many it added, and why it skipped any. Pasted stories are saved with your account, outside the addon's folder, so updating the addon doesn't remove them. **Delete** in the menu removes a pasted story.

## Automatic prompts

A prompt appears when you enter a new zone, turn in a quest, level up, or come back from dying. Press **Speak** to say it or **Skip** to dismiss it, or ignore it and it disappears after 45 seconds. Drag either window to move it.

## Commands

| Command | What it does |
| --- | --- |
| `/tales stories` | Open or close the story menu |
| `/tales add` | Open or close the Add Stories window |
| `/tales minimap` | Show or hide the minimap icon |
| `/tales on`, `/tales off` | Turn automatic prompts on or off |
| `/tales cooldown 60` | Minimum seconds between prompts (default 30) |
| `/tales status` | Show who the addon thinks you are, plus settings and story counts |
| `/tales test quest_done` | Show a prompt: `zone_enter`, `quest_done`, `level_up`, or `death`. Speak on a test prompt is real. |

## Working on the addon

These commands need [PowerShell 7](https://learn.microsoft.com/powershell/scripting/install/installing-powershell), which also runs on macOS. To link the project into the game so edits load directly, run:

```powershell
./install-addon.ps1
```

Pass `-WowPath` if the game isn't in the default location. Restart the game after linking.

Built-in stories are in `addon/FiresideTales/`:

- **Starter stories for everyone:** `Stories.lua` and `MoreShared.lua`.
- **Starter stories told to a target:** `StoriesTargeted.lua`. Write `{target}` where the name goes, and describe only what the teller does, never what the listener does or feels.
- **Automatic prompt lines:** `Lines.lua`.

Each story needs a `title`, a `mood` (`funny`, `heartfelt`, `dark`, `action`, `spooky`, or `wise`), and `lines`. Shared stories also need a `theme`.

Stories are told sitting around a campfire, so write emotes that work while seated. Act out a past event with your hands and upper body, rather than standing, walking, kneeling, or crouching. Each line is one chat message, so keep it under 255 bytes. Emote lines begin with a verb because the game adds your name, and `|` isn't allowed in chat text.

Edits to these files load with `/reload`. A brand-new file needs a game restart and an entry in `FiresideTales.toc`. To catch mistakes before you load them, run:

```powershell
./tools/check-stories.ps1
```

### Local stories

Any other story files in `.gitignore` stay on the computer that has them, with no copy on GitHub. The `.toc` lists them, and the game skips any that aren't there. To add a new one, add it to `.gitignore` and `FiresideTales.toc`.

### Building the zip

This builds `dist/FiresideTales-<version>.zip` with the addon, starter stories, and prompts, and without local stories:

```powershell
./tools/build-release.ps1
```

To update, replace the whole `FiresideTales` folder with the new one. Pasted stories, favorites, and history aren't stored there, so they stay.

## Removing it

Delete the `FiresideTales` folder from `AddOns`. If you linked it instead, this removes the link and leaves your project files in place:

```powershell
./install-addon.ps1 -Uninstall
```

## Requirements

The WoW: Forever client (interface `16001`) on Windows or macOS. Update `## Interface` in `FiresideTales.toc` when the client's version changes, or the game will mark the addon out of date.
