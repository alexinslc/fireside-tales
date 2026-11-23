// What there is to translate, read from the addon's own files.
//
// Stories: every title, heading, summary, line, and riddle hint and answer in the story files
// that ship (character stories stay on this computer), plus Openers.lua. Each file's strings
// are translated in translations/<language>/<the same path>.json.
// Spoken: text the addon says in chat itself, in code as ns.Locale.T("..."). spoken.json.
// Interface: everything else the player reads, in code as L["..."]. ui.json.
import { readdir, readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import path from "node:path";

export const ROOT = fileURLToPath(new URL("../..", import.meta.url));
export const ADDON_DIR = path.join(ROOT, "addon", "FiresideTales");
export const TRANSLATIONS_DIR = path.join(ROOT, "translations");

// The languages besides English, as the game names them.
export const LANGUAGES = ["deDE", "frFR", "esES", "esMX", "ruRU", "koKR"];

// Chat refuses a message over 255 bytes. Stories keep to 250, and a {target} counts as a long name.
export const MAX_BYTES = 250;
export const TARGET_ROOM = 24;

const LOCAL_ONLY = /^stories\/characters\//;
const STRING = /"((?:[^"\\]|\\.)*)"/;
const FIELD = new RegExp(String.raw`^\s*(title|theme|summary|hint|answer)\s*=\s*` + STRING.source + String.raw`\s*,?\s*$`);
const LINE = new RegExp(String.raw`\{\s*kind\s*=\s*"(say|emote)"\s*,\s*text\s*=\s*` + STRING.source + String.raw`\s*\}`);
const ANSWERS = /^\s*answers\s*=\s*\{(.*)\}\s*,?\s*$/;
const LEGEND = new RegExp(String.raw`^ns\.AddLegend\(` + STRING.source + String.raw`,\s*` + STRING.source);

export function unescapeLua(text) {
	return text.replace(/\\(\d{1,3}|.)/g, (_, c) => {
		if (/^\d+$/.test(c)) return String.fromCharCode(Number(c));
		return { n: "\n", t: "\t", r: "\r" }[c] ?? c;
	});
}

// The key for a riddle's list of answers, as Locale.lua's AnswersKey makes it.
export function answersKey(answers) {
	return `answers: ${answers.join(" | ")}`;
}

// The story files, as the .toc lists them, with forward slashes.
export async function storyFiles() {
	const toc = await readFile(path.join(ADDON_DIR, "FiresideTales.toc"), "utf8");
	const files = toc.split(/\r?\n/).map((l) => l.trim().replace(/\\/g, "/"))
		.filter((f) => f.startsWith("stories/") && f.endsWith(".lua") && !LOCAL_ONLY.test(f));
	return [...files, "Openers.lua"];
}

// A story file's strings, in order, each once: { en, kind, story }. kind is title, theme,
// summary, legend, say, emote, hint, answer or answers (whose en is the key, and list the words).
export async function fileStrings(file) {
	const source = await readFile(path.join(ADDON_DIR, file), "utf8");
	const out = [];
	const seen = new Set();
	let story = null;
	const add = (en, kind, extra = {}) => {
		if (!en || seen.has(en)) return;
		seen.add(en);
		out.push({ en, kind, story, ...extra });
	};
	for (const raw of source.split(/\r?\n/)) {
		let match;
		if ((match = raw.match(LEGEND))) {
			add(unescapeLua(match[2]), "legend");
		} else if ((match = raw.match(FIELD))) {
			const text = unescapeLua(match[2]);
			if (match[1] === "title") story = text;
			add(text, match[1]);
		} else if ((match = raw.match(LINE))) {
			add(unescapeLua(match[2]).replace(/\s+/g, " ").trim(), match[1]);
		} else if ((match = raw.match(ANSWERS))) {
			const words = [...match[1].matchAll(/"((?:[^"\\]|\\.)*)"/g)].map((m) => unescapeLua(m[1]));
			add(answersKey(words), "answers", { words });
		}
	}
	return out;
}

// Code strings: L["..."] for the interface, ns.Locale.T("...") for what the addon says.
export async function codeStrings() {
	const files = (await readdir(ADDON_DIR)).filter((f) => f.endsWith(".lua")).sort();
	const ui = new Map();
	const spoken = new Map();
	for (const file of files) {
		const source = await readFile(path.join(ADDON_DIR, file), "utf8");
		for (const m of source.matchAll(/\bL\["((?:[^"\\]|\\.)*)"\]/g)) {
			const en = unescapeLua(m[1]);
			if (!ui.has(en)) ui.set(en, { en, kind: "ui", file });
		}
		for (const m of source.matchAll(/ns\.Locale\.T\("((?:[^"\\]|\\.)*)"\)/g)) {
			const en = unescapeLua(m[1]);
			if (!spoken.has(en)) spoken.set(en, { en, kind: "say", file });
		}
	}
	return { ui: [...ui.values()], spoken: [...spoken.values()] };
}

// Where a story file's translations go.
export function translationFile(language, file) {
	return path.join(TRANSLATIONS_DIR, language, file.replace(/\.lua$/, ".json"));
}

const bytes = (text) => Buffer.byteLength(text.replaceAll("{target}", "x".repeat(TARGET_ROOM)), "utf8");
const placeholders = (text) => (text.match(/%[-0-9.]*[sdfx%]/g) ?? []).join(" ");
const count = (text, part) => text.split(part).length - 1;

// What's wrong with one translation, or nothing.
export function problems(entry, value) {
	const out = [];
	const { en, kind } = entry;
	if (kind === "answers") {
		if (!Array.isArray(value) || value.length === 0 || value.some((w) => typeof w !== "string" || !w.trim())) {
			return ["answers must be a list of words"];
		}
		for (const word of value) {
			if (word !== word.toLowerCase()) out.push(`answer "${word}" must be lowercase`);
		}
		return out;
	}
	const parts = typeof value === "string" ? [value] : value;
	if (!Array.isArray(parts) || parts.length === 0 || parts.some((p) => typeof p !== "string" || !p.trim())) {
		return ["must be text, or for a long line a list of parts"];
	}
	const spoken = ["say", "emote"].includes(kind);
	if (parts.length > 1 && !spoken) out.push("only a story line can be split into parts");
	const all = parts.join(" ");
	for (const part of parts) {
		// The interface can have the English's own line breaks; chat can't have any.
		if (kind === "ui" ? /[\r\t]/.test(part) || count(part, "\n") !== count(en, "\n") : /[\n\r\t]/.test(part)) {
			out.push(kind === "ui" ? "needs the English's line breaks" : "has a line break or tab");
		}
		if (part !== part.trim()) out.push("starts or ends with a space");
		if (spoken || kind === "hint" || kind === "answer") {
			if (bytes(part) > MAX_BYTES) out.push(`${bytes(part)} bytes, over chat's ${MAX_BYTES}: split it into parts`);
			// The game reads | as the start of a color or link and refuses the message.
			if (part.includes("|")) out.push("has a |, which chat refuses");
		}
	}
	if (count(all, "{target}") !== count(en, "{target}")) out.push(`needs {target} ${count(en, "{target}")} time(s), as the English has`);
	if (placeholders(all) !== placeholders(en)) out.push(`needs the same %s and %d, in the same order: ${placeholders(en) || "none"}`);
	if (kind === "ui" && count(all, "|c") !== count(en, "|c")) out.push("needs the same color codes as the English");
	return out;
}

