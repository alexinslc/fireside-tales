// The story rules, shared by the submit page, the server, and the admin page.
// They match the addon's own checks (Import.lua and tools/check-stories.ps1), so a
// story that passes here passes when it ships.

export const MOODS = ["funny", "heartfelt", "dark", "action", "spooky", "wise"];
export const KINDS = ["story", "rumor"];
// WoW Forever groups players by ruleset rather than realm.
export const RULESETS = ["Normal", "PvP", "Roleplay", "Roleplay-PvP", "Hardcore"];

export const LIMITS = {
	titleMax: 60,
	authorMax: 30,
	maxBytes: 250, // One chat message, with room to spare.
	story: { minLines: 3, maxLines: 8, maxSeconds: 60 },
	rumor: { minLines: 3, maxLines: 4, maxSeconds: 35 },
};

const encoder = new TextEncoder();

export function byteLength(text) {
	return encoder.encode(text).length;
}

// The teller bar's read cue: 3 seconds plus 1 for every 20 bytes, from 4 to 14.
export function readSeconds(text) {
	return Math.max(4, Math.min(14, 3 + byteLength(text) / 20));
}

export function storySeconds(lines) {
	return lines.reduce((sum, line) => sum + readSeconds(line.text), 0);
}

// Typographic punctuation the game can't show, swapped for what it can.
const SWAPS = [
	[/[‘’‛′]/g, "'"],
	[/[“”‟″]/g, '"'],
	[/[–—―]/g, " - "],
	[/…/g, "..."],
	[/ /g, " "],
];

export function tidyText(text) {
	let out = String(text ?? "");
	for (const [pattern, replacement] of SWAPS) out = out.replace(pattern, replacement);
	return out.replace(/\s+/g, " ").trim();
}

// The game adds the character's name before an emote, so it continues a sentence.
export function tidyLine(line) {
	let text = tidyText(line.text);
	if (line.kind === "emote" && text) text = text.charAt(0).toLowerCase() + text.slice(1);
	return { kind: line.kind === "emote" ? "emote" : "say", text };
}

export function tidyStory(story) {
	return {
		kind: KINDS.includes(story.kind) ? story.kind : "story",
		title: tidyText(story.title),
		mood: String(story.mood ?? "").trim().toLowerCase(),
		lines: (Array.isArray(story.lines) ? story.lines : []).map(tidyLine).filter((line) => line.text !== ""),
		author: tidyText(story.author).slice(0, LIMITS.authorMax),
		ruleset: RULESETS.includes(story.ruleset) ? story.ruleset : "",
	};
}

// Returns a list of problems, each { line, message } where line is 1-based or null.
// A new submission may leave the mood empty; the AI check suggests one for review.
export function findProblems(story, { moodOptional = false } = {}) {
	const problems = [];
	const add = (message, line = null) => problems.push({ line, message });
	const limits = LIMITS[story.kind] ?? LIMITS.story;

	if (!story.title) add("Give it a title.");
	else if (story.title.length > LIMITS.titleMax) add(`Keep the title under ${LIMITS.titleMax} characters.`);
	if (/[|{}]|[^\x20-\x7E]/.test(story.title)) add("The title has a character the game can't show.");
	if (!MOODS.includes(story.mood) && !(moodOptional && story.mood === "")) add("Pick a mood.");

	const count = story.lines.length;
	if (count < limits.minLines || count > limits.maxLines) {
		add(`A ${story.kind} needs ${limits.minLines} to ${limits.maxLines} lines (this has ${count}).`);
	}
	let says = 0;
	let emotes = 0;
	story.lines.forEach((line, index) => {
		const n = index + 1;
		if (line.kind === "say") says++;
		else emotes++;
		if (byteLength(line.text) > LIMITS.maxBytes) add(`Line ${n} is too long for one chat message.`, n);
		if (line.text.includes("{target}")) add(`Line ${n} uses {target}, which community stories can't use yet.`, n);
		else if (/[|{}]/.test(line.text)) add(`Line ${n} uses |, { or }, which chat doesn't allow.`, n);
		if (/[^\x20-\x7E]/.test(line.text)) add(`Line ${n} has a character the game can't show.`, n);
		if (line.kind === "emote" && !/^[a-z]/.test(line.text)) {
			add(`Line ${n} is an emote, so it should start with a verb, like "leans in".`, n);
		}
	});
	if (count > 0 && says === 0) add("Add at least one spoken (Say) line.");
	if (count > 0 && emotes === 0) add("Add at least one Emote line.");

	const seconds = storySeconds(story.lines);
	if (Math.round(seconds) > limits.maxSeconds) {
		add(`It takes about ${Math.round(seconds)} seconds to tell. Keep a ${story.kind} under ${limits.maxSeconds}.`);
	}

	if (story.author && !/^[A-Za-z][A-Za-z' -]*$/.test(story.author)) {
		add("Your name can use letters, spaces, apostrophes and hyphens.");
	}
	return problems;
}

// Reads the same text Write Your Tales accepts: TITLE, MOOD, SAY and EMOTE lines, with
// any section lines (CHARACTER, EVERYONE, ...) and AI chatter ignored.
export function parsePaste(text) {
	const stories = [];
	let story = null;
	const finish = () => {
		if (story) stories.push(story);
		story = null;
	};
	for (const raw of String(text ?? "").split(/\r?\n/)) {
		const line = raw.trim().replace(/\*\*/g, "");
		const match = line.match(/^([A-Z]+):\s*(.*)$/);
		if (line.startsWith("```")) {
			finish();
			continue;
		}
		if (!match) continue;
		const [, label, value] = match;
		if (label === "TITLE") {
			finish();
			story = { kind: "story", title: value, mood: "", lines: [] };
		} else if (story && label === "MOOD") {
			story.mood = value.toLowerCase();
		} else if (story && (label === "SAY" || label === "EMOTE")) {
			story.lines.push({ kind: label === "SAY" ? "say" : "emote", text: value });
		}
	}
	finish();
	return stories.map(tidyStory);
}

// Reads a story typed the easy way: one chat line per line of text, with actions in
// *asterisks* (or starting with /e). Text in the Write Your Tales format works too.
// Returns { title, mood, lines }; title and mood are only filled from that format.
export function parseWriting(text) {
	const source = String(text ?? "");
	if (/^\s*\**\s*(TITLE|SAY|EMOTE)\s*\**\s*:/m.test(source)) {
		const [story] = parsePaste(/^\s*\**\s*TITLE/m.test(source) ? source : `TITLE: \n${source}`);
		if (story) return { title: story.title, mood: story.mood, lines: story.lines };
	}
	const lines = [];
	for (const raw of source.split(/\r?\n/)) {
		let text = raw.trim();
		if (!text) continue;
		let kind = "say";
		const action = text.match(/^\*+\s*(.*?)\s*\*+$/) ?? text.match(/^\*+\s*(.*)$/) ?? text.match(/^\/(?:e|em|emote|me)\s+(.*)$/i);
		if (action) {
			kind = "emote";
			text = action[1];
		} else {
			text = text.replace(/^\/(?:s|say)\s+/i, "");
		}
		lines.push(tidyLine({ kind, text }));
	}
	return { title: "", mood: "", lines: lines.filter((line) => line.text !== "") };
}

// The reverse, for showing a story back in the text box.
export function toWriting(lines) {
	return lines.map((line) => (line.kind === "emote" ? `*${line.text}*` : line.text)).join("\n");
}

// The same story in the paste format, for the "Copy for the game" button.
export function toPaste(story, heading = "EVERYONE: Community Tales") {
	const out = [heading, `TITLE: ${story.title}`, `MOOD: ${story.mood}`];
	for (const line of story.lines) out.push(`${line.kind === "emote" ? "EMOTE" : "SAY"}: ${line.text}`);
	return out.join("\n");
}

// Rotation weeks start on Tuesday, the game's weekly reset. Returns YYYY-MM-DD in UTC.
export function weekStart(date = new Date()) {
	const d = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
	const back = (d.getUTCDay() - 2 + 7) % 7;
	d.setUTCDate(d.getUTCDate() - back);
	return d.toISOString().slice(0, 10);
}

export function addWeeks(week, count) {
	const d = new Date(`${week}T00:00:00Z`);
	d.setUTCDate(d.getUTCDate() + count * 7);
	return d.toISOString().slice(0, 10);
}
