# Fireside Tales

## The vision

Fireside Tales is a rumor mill for World of Warcraft: Forever: a big, ever-growing collection of stories and legends that anyone can sit down and tell at a campfire. It's a fun side thing to the game, for people who want to tell a tale or stop and listen to one.

If you're working on this project, whether you're a person or an AI, these are the goals that decide what to do:

- **Keep adding stories.** The collection is the product. There should be so many that you always have something new to tell, whenever you reach a fire.
- **Stories belong to everyone.** Zone, race, and class stories are welcome as long as they're generic enough for any character who fits to tell. Stories tied to one specific character stay out of the shared collection.
- **Your own stories are what make you care.** The built-in stories give everyone something to tell, but telling your own character's story is what gives a player buy-in. Adding your own has to be easy, probably with the help of an AI, and they stay yours to tell at the fire.
- **Stories work at a campfire.** Each one takes 60 seconds or less to tell, including the pauses that let people read. Add up each line's read cue from `TellerBar.lua` to estimate this: 3 seconds plus 1 for every 20 characters, between 4 and 14 per line.
- **The addon stays stupid simple.** Pick a story and press Speak. A new feature has to earn its place, and it shouldn't make that any harder.
- **Delight the players.** Favor whatever makes someone at the fire smile, lean in, or want to tell one of their own.

For now, all the stories ship in this one addon. Text is small, so it doesn't need separate story packs, and it isn't on CurseForge yet.

## What it is

An addon for telling stories at the campfire in World of Warcraft: Forever, one line at a time, using `/say` and `/e`. It works on Windows and macOS.

It comes in two halves:

- **The storytelling:** a story menu with filters, a small teller bar, favorites, and an evening list.
- **The stories:** a shared collection for every race, class, and zone, plus **Write My Story**, which helps you use an AI to write your own character's stories right from the game.

The addon never sends chat by itself. The game requires a key press or click for `/say` and `/e` outside instances, so every line waits for you to press Speak.

## Setup

1. Close the game and extract the zip into your AddOns folder, so its files end up in `AddOns/FiresideTales/`:

   - **Windows:** `C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\`
   - **macOS:** `/Applications/World of Warcraft/_forever_/Interface/AddOns/`

   Create the `AddOns` folder if it isn't there. Your game may be installed somewhere else.

2. Start the game. If addons load individually, turn on Fireside Tales at the character screen.

3. Optional: bind keys under **Options > Keybindings > Fireside Tales** for Speak and the story menu. The on-screen buttons work without them.

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
- **Show:** Favorites, stories you haven't told yet, stories you've added, or only Tonight's list.

**Clear** appears while a filter is on and resets all four.

**Restart** goes back to the first line. **Escape** closes the menu. Your place in a story is kept until you pick another or `/reload`.

### What's in the list

The list is built for whoever you're logged in as, in this order:

1. **Tonight**, if you've added any
2. **Here in your zone**: tales of the zone you're in, plus any of your other stories that mention it or a place in it. It updates as you travel.
3. **Your character's tales**, matched by the character's first name. This section always lists all of them, so one that mentions your zone appears in both places.
4. **Race stories**, chosen from what the game reports
5. **Class stories**, chosen the same way
6. **Target Someone First**, told to one listener
7. **Shared stories**, available to everyone
8. **Tales of other places**, grouped by zone

To teach a zone new place names, add them to `ns.ZoneTerms` in `StoryData.lua`.

## Writing your own stories

1. Press **Write My Story** in the menu, or type `/tales add`.
2. Optionally, write a sentence or two about your character. It's saved for next time, and without it the AI invents something.
3. Press **Select Prompt**, copy it with Cmd+C or Ctrl+C, and paste it into any AI. Your character's name, race, class, and zone are already filled in.
4. Paste the AI's answer into the bottom box and press **Add**. It's fine to paste the whole reply.

Your stories appear under **`<name>`'s Tales**, near the top of the list. Anything you've added has a small note icon and says "added by you", and **Show: Added by me** lists just those. The window says how many it added, and why it skipped any. Read them before you tell them, since you're the one saying them out loud.

Pasted stories are saved with your account, outside the addon's folder, so updating the addon doesn't remove them. **Delete** in the menu removes a pasted story.

The addon's `prompts` folder has more prompts for a race or class, a zone, everyone, and stories told to someone by name. Their answers go in the same box.

## Commands

| Command | What it does |
| --- | --- |
| `/tales` or `/tales stories` | Open or close the story menu |
| `/tales help` | List the commands |
| `/tales add` | Open or close the Write My Story window |
| `/tales minimap` | Show or hide the minimap icon |
| `/tales status` | Show who the addon thinks you are, and your story counts |

## Working on the addon

These commands need [PowerShell 7](https://learn.microsoft.com/powershell/scripting/install/installing-powershell), which also runs on macOS. To link the project into the game so edits load directly, run:

```powershell
./install-addon.ps1
```

Pass `-WowPath` if the game isn't in the default location. Restart the game after linking.

Built-in stories are in `addon/FiresideTales/`:

- **Starter stories for everyone:** `Stories.lua` and `MoreShared.lua`.
- **Starter stories told to a target:** `StoriesTargeted.lua`. Write `{target}` where the name goes, and describe only what the teller does, never what the listener does or feels.
- **Race, class, and zone stories:** `StoriesRaces.lua`, `MoreRaces.lua`, `StoriesClasses.lua`, `MoreClasses.lua`, and `MoreZones.lua`.

Each story needs a `title`, a `mood` (`funny`, `heartfelt`, `dark`, `action`, `spooky`, or `wise`), and `lines`. Shared stories also need a `theme`.

Stories are told sitting around a campfire, so write emotes that work while seated. Act out a past event with your hands and upper body, rather than standing, walking, kneeling, or crouching. Each line is one chat message, so keep it under 255 bytes. Emote lines begin with a verb because the game adds your name, and `|` isn't allowed in chat text.

Edits to these files load with `/reload`. A brand-new file needs a game restart and an entry in `FiresideTales.toc`. To catch mistakes before you load them, run:

```powershell
./tools/check-stories.ps1
```

### Local stories

Any other story files in `.gitignore` stay on the computer that has them, with no copy on GitHub. The `.toc` lists them, and the game skips any that aren't there. To add a new one, add it to `.gitignore` and `FiresideTales.toc`.

### Releasing

Pushing a version tag publishes to CurseForge and GitHub. See [docs/RELEASING.md](docs/RELEASING.md).

### Building the zip

This builds `dist/FiresideTales-<version>.zip` with the addon, shared stories, and prompts, and without local stories:

```powershell
./tools/build-release.ps1
```

To update, replace the whole `FiresideTales` folder with the new one. Pasted stories, favorites, and history aren't stored there, so they stay.

## Removing it

Delete the `FiresideTales` folder from `AddOns`. If you linked it instead, this removes the link and leaves your project files in place:

```powershell
./install-addon.ps1 -Uninstall
```

## License

The code and stories are under the [MIT License](LICENSE).

## Requirements

The WoW: Forever client (interface `16001`) on Windows or macOS. Update `## Interface` in `FiresideTales.toc` when the client's version changes, or the game will mark the addon out of date.
