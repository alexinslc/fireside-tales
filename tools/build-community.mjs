// Writes addon/FiresideTales/Community.lua from the stories approved on firesidetales.dev.
// The addon can't reach the internet, so each release carries the weeks ahead.
//
//   SCHEDULE_TOKEN=... node tools/build-community.mjs  (reads https://firesidetales.dev/api/schedule)
//   node tools/build-community.mjs --from file.json   (reads a saved copy instead)
//   node tools/build-community.mjs --notes notes.md   (also writes a changelog line for a release)
//
// Prints a one-line summary. The file only changes when the stories do, so a run with
// nothing new leaves git clean.
import { readFile, writeFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { findProblems, weekStart, addWeeks } from "../site/shared/rules.js";

const SOURCE = process.env.SCHEDULE_URL ?? "https://firesidetales.dev/api/schedule";
const OUTPUT = fileURLToPath(new URL("../addon/FiresideTales/Community.lua", import.meta.url));
const KEEP_PAST_WEEKS = 4; // Recent weeks stay, for players who update late.

async function load() {
	const from = process.argv.indexOf("--from");
	if (from !== -1) return JSON.parse(await readFile(process.argv[from + 1], "utf8"));
	// The schedule includes weeks that haven't started, so it needs the shared token.
	const token = process.env.SCHEDULE_TOKEN;
	const response = await fetch(SOURCE, {
		headers: { "user-agent": "fireside-tales-build", ...(token ? { authorization: `Bearer ${token}` } : {}) },
	});
	if (!response.ok) throw new Error(`${SOURCE} answered ${response.status}`);
	return response.json();
}

function lua(text) {
	return `"${String(text).replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\r?\n/g, " ")}"`;
}

function storyLua(story) {
	const lines = story.lines.map((line) => `\t\t\t{ kind = ${lua(line.kind)}, text = ${lua(line.text)} },`).join("\n");
	return [
		"\t{",
		// The site's id, so a release can report which stories it carried.
		`\t\tid = ${lua(story.id)},`,
		`\t\tkind = ${lua(story.kind)},`,
		`\t\ttitle = ${lua(story.title)},`,
		`\t\tmood = ${lua(story.mood)},`,
		`\t\tauthor = ${lua(story.author ?? "")},`,
		`\t\truleset = ${lua(story.ruleset ?? "")},`,
		"\t\tlines = {",
		lines,
		"\t\t},",
		"\t},",
	].join("\n");
}

const data = await load();
const oldest = addWeeks(weekStart(), -KEEP_PAST_WEEKS);
const weeks = new Map();
const skipped = [];
for (const story of data.stories ?? []) {
	if (!story.week || story.week < oldest) continue;
	if (!/^[0-9a-f-]{36}$/.test(String(story.id))) { skipped.push(`${story.title}: no id`); continue; }
	// The site already checks these, but the addon must never get a line the game can't send.
	const problems = findProblems(story);
	if (problems.length > 0) {
		skipped.push(`${story.title}: ${problems.map((p) => p.message).join(" ")}`);
		continue;
	}
	if (!weeks.has(story.week)) weeks.set(story.week, []);
	weeks.get(story.week).push(story);
}

const blocks = [...weeks.keys()].sort().map((week) =>
	`ns.AddCommunityWeek("${week}", {\n${weeks.get(week).map(storyLua).join("\n")}\n})`);
const file = [
	"-- Community stories from firesidetales.dev, one list per week. A week starts on Tuesday (UTC).",
	"-- Written by tools/build-community.mjs, so edit stories on the site, not here.",
	"local _, ns = ...",
	"if not ns.AddCommunityWeek then return end",
	"",
	...blocks.flatMap((block) => [block, ""]),
].join("\n");

let before = "";
try { before = await readFile(OUTPUT, "utf8"); } catch {}
if (before !== file) await writeFile(OUTPUT, file);

const count = [...weeks.values()].reduce((n, list) => n + list.length, 0);
console.log(`${before === file ? "No change" : "Updated Community.lua"}: ${count} stories in ${weeks.size} weeks.`);
for (const line of skipped) console.warn(`Skipped ${line}`);

// A changelog line naming the weeks a release brings and who wrote them.
const notesAt = process.argv.indexOf("--notes");
if (notesAt !== -1) {
	const ahead = [...weeks.keys()].sort().filter((week) => week >= weekStart());
	const day = (week) => new Date(`${week}T12:00:00Z`).toLocaleDateString("en-US", { month: "long", day: "numeric", timeZone: "UTC" });
	const authors = [...new Set(ahead.flatMap((week) => weeks.get(week).map((s) => s.author).filter(Boolean)))];
	const credit = authors.length === 0 ? "" : authors.length <= 5
		? `, by ${authors.slice(0, -1).join(", ")}${authors.length > 1 ? " and " : ""}${authors.at(-1)}`
		: `, by ${authors.slice(0, 4).join(", ")} and ${authors.length - 4} more`;
	const list = ahead.map(day);
	const when = list.length <= 1 ? list.join("") : `${list.slice(0, -1).join(", ")} and ${list.at(-1)}`;
	await writeFile(process.argv[notesAt + 1], ahead.length === 0 ? "" :
		`- New Community stories for the week${ahead.length > 1 ? "s" : ""} of ${when}${credit}.\n`);
}
