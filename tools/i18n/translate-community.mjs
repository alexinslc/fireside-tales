// Translates the community stories in Community.lua into every language, for the weekly job.
// Only stories that don't have a translation yet are sent, and past weeks' strings are dropped.
// Each language goes through Claude twice: a translation, then a native editor's pass, the same
// two steps the built-in stories had. Anything the checks reject is sent back once to be fixed;
// a story that still fails stays in English.
//
//   ANTHROPIC_API_KEY=... node tools/i18n/translate-community.mjs [--only deDE]
//
// Needs `npm ci` in tools/i18n first. Then run node tools/i18n/build.mjs.
import Anthropic from "@anthropic-ai/sdk";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import path from "node:path";
import { LANGUAGES, ROOT, TRANSLATIONS_DIR, fileStrings, problems, translationFile } from "./strings.mjs";

const FILE = "stories/Community.lua";
const MODEL = "claude-opus-5-5";
const NAMES = { deDE: "German", frFR: "French", esES: "Spanish (Spain, esES client)", esMX: "Spanish (Latin America, esMX client)", ruRU: "Russian", koKR: "Korean" };

const only = process.argv.includes("--only") ? [process.argv[process.argv.indexOf("--only") + 1]] : LANGUAGES;
const client = new Anthropic();
const guide = await readFile(path.join(ROOT, "docs", "translation-guide.md"), "utf8");

async function readJson(file) {
	try { return JSON.parse(await readFile(file, "utf8")); } catch (error) {
		if (error.code === "ENOENT") return {};
		throw error;
	}
}

// The translations come back as a list, since JSON object keys can't be described ahead.
const FORMAT = {
	type: "json_schema",
	schema: {
		type: "object",
		properties: {
			translations: {
				type: "array",
				items: {
					type: "object",
					properties: {
						en: { type: "string" },
						parts: { type: "array", items: { type: "string" } },
					},
					required: ["en", "parts"],
					additionalProperties: false,
				},
			},
		},
		required: ["translations"],
		additionalProperties: false,
	},
};

async function ask(system, prompt) {
	// Streamed, since a long answer can take a while.
	const response = await client.beta.messages.stream({
		model: MODEL,
		max_tokens: 32000,
		betas: ["server-side-fallback-2026-07-01"],
		fallbacks: "default", // A declined request is re-run on another model in the same call.
		output_config: { effort: "high", format: FORMAT },
		system,
		messages: [{ role: "user", content: prompt }],
	}).finalMessage();
	if (response.stop_reason === "refusal") throw new Error(`declined: ${response.stop_details?.explanation ?? "no reason given"}`);
	if (response.stop_reason === "max_tokens") throw new Error("ran out of room for the answer");
	const text = response.content.filter((b) => b.type === "text").map((b) => b.text).join("");
	return JSON.parse(text).translations;
}

// A list back to { English: text or parts }, keeping only what passes the checks.
function accept(list, entries) {
	const byEn = new Map(entries.map((e) => [e.en, e]));
	const good = {};
	const bad = [];
	for (const { en, parts } of list) {
		const entry = byEn.get(en);
		if (!entry) continue;
		const value = entry.kind === "answers" || parts.length > 1 ? parts : parts[0];
		const found = problems(entry, value);
		if (found.length) bad.push(`"${en}": ${found.join("; ")}`);
		else good[en] = value;
	}
	return { good, bad };
}

function storiesText(entries) {
	let story = null;
	const out = [];
	for (const e of entries) {
		if (e.story !== story) { story = e.story; out.push(`\n# Story: ${story}`); }
		out.push(`${e.kind}: ${e.en}`);
	}
	return out.join("\n");
}

async function translate(code, entries, glossary) {
	const system = [
		`You translate Fireside Tales, a World of Warcraft storytelling addon, into ${NAMES[code]} (${code}).`,
		"Follow this guide exactly:", guide,
		`The ${code} client's official names:`, JSON.stringify(glossary),
		"Answer with every English string given, exactly as given, and its translation as parts: one part,",
		"or for a story line too long for chat, several. Riddle answers lists are lowercase words, one per part.",
		"Credited player character names stay as they are.",
	].join("\n\n");
	let list = await ask(system, `Translate these community stories. Each line is "kind: English".\n${storiesText(entries)}`);
	// The editor's pass, as a native speaker would make it.
	const draft = list.map((t) => `${t.en}\n=> ${t.parts.join(" / ")}`).join("\n\n");
	list = await ask(system, [
		`You are now a native ${NAMES[code]} editor. Improve this draft wherever it reads translated, stiff, or off in register;`,
		"make jokes land; fix emote grammar and official names. Return the full list, changed or not.",
		`The stories:\n${storiesText(entries)}`, `The draft:\n${draft}`,
	].join("\n\n"));
	let { good, bad } = accept(list, entries);
	if (bad.length) {
		const retry = entries.filter((e) => bad.some((b) => b.startsWith(`"${e.en}"`)));
		const fixed = await ask(system, `These translations failed the checks. Fix them and return just these:\n${bad.join("\n")}\n\nThe English:\n${storiesText(retry)}`);
		const again = accept(fixed, retry);
		Object.assign(good, again.good);
		bad = again.bad;
	}
	return { good, bad };
}

const entries = await fileStrings(FILE);
const wanted = new Set(entries.map((e) => e.en));
let failed = false;
for (const code of only) {
	const out = translationFile(code, FILE);
	const done = await readJson(out);
	// Past weeks have rotated out of Community.lua.
	for (const key of Object.keys(done)) if (!wanted.has(key)) delete done[key];
	const todo = entries.filter((e) => done[e.en] === undefined);
	if (todo.length === 0) {
		console.log(`${code}: nothing new.`);
	} else {
		const glossary = await readJson(path.join(TRANSLATIONS_DIR, code, "glossary.json"));
		try {
			const { good, bad } = await translate(code, todo, glossary);
			Object.assign(done, good);
			console.log(`${code}: ${Object.keys(good).length} of ${todo.length} strings translated.`);
			for (const b of bad) console.warn(`${code}: left in English: ${b}`);
		} catch (error) {
			if (error instanceof Anthropic.APIError) console.error(`${code}: API error ${error.status}: ${error.message}`);
			else console.error(`${code}: ${error.message}`);
			failed = true;
		}
	}
	if (todo.length === 0 && Object.keys(await readJson(out)).length === Object.keys(done).length) continue;
	await mkdir(path.dirname(out), { recursive: true });
	const sorted = Object.fromEntries(Object.keys(done).sort().map((k) => [k, done[k]]));
	await writeFile(out, JSON.stringify(sorted, null, "\t") + "\n");
}
if (failed) process.exit(1);
