# Test harness

`harness.lua` runs the whole addon outside the game. It loads the files in `FiresideTales.toc` order, stands in for the game's functions and events, and drives the menu, teller bar, Write My Story, the fire's offer, festivals, and Total RP 3 profiles. It finishes with a count of passed and failed checks.

It proves the addon's logic, not that the game has the functions it stands in for, so still try changes in the game.

## Running it

It needs [LuaJIT](https://luajit.org/) or any Lua 5.1, the same version the game uses. On a Mac, `brew install luajit`. From the repository:

```sh
luajit tools/harness/harness.lua
```

Every check should pass, ending in a line like `RESULT: 17290 passed, 0 failed`. A failure prints `FAIL` with the check's name. The last line lists anything the addon read from the game that the harness doesn't provide, which is fine for functions the addon checks for before using.

To test another copy of the addon, pass its folder. To also check a real AI reply against Write My Story, save it to a text file and pass it after the folder:

```sh
luajit tools/harness/harness.lua addon/FiresideTales reply.txt
```

## Keeping it current

Some checks count things, such as the number of published stories. When you add stories, update those numbers, or the harness reports the difference.
