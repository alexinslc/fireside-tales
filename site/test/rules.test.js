import { test } from "node:test";
import assert from "node:assert/strict";
import {
	findProblems, parsePaste, parseWriting, toWriting, tidyStory, toPaste, storySeconds, weekStart, addWeeks,
} from "../shared/rules.js";

const good = tidyStory({
	kind: "story",
	title: "The Last Honest Merchant",
	mood: "funny",
	author: "Thorg",
	ruleset: "PvP",
	lines: [
		{ kind: "say", text: "Ever met an honest merchant? I did, once. He sold me a mule and told me it was a terrible mule." },
		{ kind: "say", text: "Bites, he said. Kicks. Lies down in rivers." },
		{ kind: "emote", text: "Rolls up one sleeve to show an old, crescent-shaped scar." },
		{ kind: "say", text: "He was not joking." },
	],
});

test("a good story has no problems", () => {
	assert.deepEqual(findProblems(good), []);
});

test("emotes are lowercased, and smart punctuation is swapped", () => {
	assert.equal(good.lines[2].text, "rolls up one sleeve to show an old, crescent-shaped scar.");
	const tidied = tidyStory({ ...good, title: "Didn’t “See” It…" });
	assert.equal(tidied.title, 'Didn\'t "See" It...');
});

test("the rules catch what the addon would refuse", () => {
	const problems = findProblems(tidyStory({
		kind: "story", title: "", mood: "silly",
		lines: [{ kind: "say", text: "x".repeat(251) }, { kind: "say", text: "Hello {target}" }],
	}));
	const text = problems.map((p) => p.message).join(" | ");
	assert.match(text, /title/);
	assert.match(text, /mood/);
	assert.match(text, /3 to 8 lines/);
	assert.match(text, /too long/);
	assert.match(text, /\{target\}/);
	assert.match(text, /Emote/);
});

test("rumors are shorter", () => {
	const long = tidyStory({ ...good, kind: "rumor", lines: [...good.lines, good.lines[0]] });
	assert.ok(findProblems(long).some((p) => /3 to 4 lines/.test(p.message)));
});

test("an emote must start with a verb, not punctuation", () => {
	const story = tidyStory({ ...good, lines: [...good.lines.slice(0, 3), { kind: "emote", text: "... sighs." }] });
	assert.ok(findProblems(story).some((p) => p.line === 4));
});

test("telling time uses the teller bar's read cue", () => {
	assert.equal(storySeconds([{ text: "Hi" }]), 4);
	assert.equal(storySeconds([{ text: "x".repeat(400) }]), 14);
});

test("pasting from the game reads the Write Your Tales format", () => {
	const text = [
		"Sure! Here's your story:",
		"CHARACTER: Bram",
		"**TITLE:** The Ferry at Dusk",
		"MOOD: Heartfelt",
		"EMOTE: Turns a worn ferry token over in their fingers.",
		"SAY: My father ran a ferry on a brown river.",
		"SAY: He came home soaked and said it had been a slow evening.",
		"```",
		"Let me know if you want another!",
	].join("\n");
	const [story] = parsePaste(text);
	assert.equal(story.title, "The Ferry at Dusk");
	assert.equal(story.mood, "heartfelt");
	assert.equal(story.lines.length, 3);
	assert.equal(story.lines[0].text, "turns a worn ferry token over in their fingers.");
	assert.deepEqual(findProblems(story), []);
});

test("copy for the game round-trips through the paste reader", () => {
	const [back] = parsePaste(toPaste(good));
	assert.deepEqual(back.lines, good.lines);
	assert.equal(back.title, good.title);
});

test("the easy way: one line per chat line, actions in asterisks", () => {
	const story = parseWriting([
		"They say a gnome in Ironforge sells the combination to a vault.",
		"",
		"*Counts the steps off on their fingers.*",
		"/e wrinkles their nose.",
		"/s Left, left, right, sneeze.",
	].join("\n"));
	assert.deepEqual(story.lines.map((l) => l.kind), ["say", "emote", "emote", "say"]);
	assert.equal(story.lines[1].text, "counts the steps off on their fingers.");
	assert.equal(story.lines[3].text, "Left, left, right, sneeze.");
	assert.deepEqual(parseWriting(toWriting(story.lines)).lines, story.lines);
});

test("the same box takes the Write Your Tales format, title and all", () => {
	const story = parseWriting("TITLE: The Ferry at Dusk\nMOOD: heartfelt\nSAY: My father ran a ferry.\nEMOTE: Sighs.\nSAY: He was good at it.");
	assert.equal(story.title, "The Ferry at Dusk");
	assert.equal(story.mood, "heartfelt");
	assert.deepEqual(story.lines.map((l) => l.kind), ["say", "emote", "say"]);
});

test("a new submission can leave the mood for the AI to suggest", () => {
	const noMood = tidyStory({ ...good, mood: "" });
	assert.deepEqual(findProblems(noMood, { moodOptional: true }), []);
	assert.ok(findProblems(noMood).some((p) => /mood/.test(p.message)));
});

test("weeks start on Tuesday, the weekly reset", () => {
	assert.equal(weekStart(new Date("2026-11-11T12:00:00Z")), "2026-11-10"); // a Wednesday
	assert.equal(weekStart(new Date("2026-11-10T00:00:00Z")), "2026-11-10"); // the Tuesday itself
	assert.equal(weekStart(new Date("2026-11-09T23:00:00Z")), "2026-11-03"); // Monday belongs to last week
	assert.equal(addWeeks("2026-11-10", 1), "2026-11-17");
});
