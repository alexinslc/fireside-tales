// Writes the addon's language files from translations/, after checking every translation.
//
//   node tools/i18n/build.mjs                    writes addon/FiresideTales/locales/<language>/*.lua
//   node tools/i18n/build.mjs --check            fails on a bad translation or a locale file out of date
//   node tools/i18n/build.mjs --dry              checks and reports, writing nothing
//   node tools/i18n/build.mjs --todo deDE stories/zones/Westfall.lua
//                                                the strings that file still needs in that language,
//                                                as JSON to fill in
//
// translations/<language>/ holds, all as { "English": "translation" }:
//   stories/**.json and Openers.json   the story files' strings, one file each. A line too long for
//                                      chat in that language is a list of parts instead.
//   spoken.json                        what the addon says in chat itself (ns.Locale.T in the code)
//   ui.json                            the interface (L["..."] in the code)
//   glossary.json                      { zones, zoneTerms, festivals, names }: the game's own names
//
// A translation that's missing is fine: that story stays in English. One that's wrong fails.
import { mkdir, readFile, writeFile } from "node:fs/promises";
import path from "node:path";
import {
	ADDON_DIR, LANGUAGES, TRANSLATIONS_DIR,
	codeStrings, fileStrings, problems, storyFiles, translationFile,
} from "./strings.mjs";

const args = process.argv.slice(2);
const CHECK = args.includes("--check");
// --dry: check and report, writing nothing (for translators working side by side).
const DRY = args.includes("--dry");

async function readJson(file, fallback = {}) {
	try {
		return JSON.parse(await readFile(file, "utf8"));
	} catch (error) {
		if (error.code === "ENOENT") return fallback;
		throw new Error(`${path.relative(TRANSLATIONS_DIR, file)}: ${error.message}`);
	}
}

const lua = (text) => `"${text.replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\n/g, "\\n")}"`;
const luaValue = (value) => (typeof value === "string" ? lua(value) : `{ ${value.map(lua).join(", ")} }`);
const luaMap = (map, indent = "\t") => Object.keys(map).sort()
	.map((key) => `${indent}[${lua(key)}] = ${luaValue(map[key])},`).join("\n");

function luaGlossary(glossary) {
	const section = (name) => {
		const map = glossary[name] ?? {};
		const body = luaMap(map, "\t\t");
		return `\t${name} = {\n${body ? body + "\n" : ""}\t},`;
	};
	return ["zones", "zoneTerms", "festivals"].map(section).join("\n");
}

const header = (what) => [
	`-- ${what} Written by tools/i18n/build.mjs from translations/, so edit those, not this.`,
	"local _, ns = ...",
	"",
].join("\n");

async function language(code, sources) {
	const dir = path.join(TRANSLATIONS_DIR, code);
	const errors = [];
	const stories = {};
	const stats = { stories: { done: 0, total: 0 }, ui: { done: 0, total: 0 }, spoken: { done: 0, total: 0 } };
	const take = (where, entries, translations, into, stat) => {
		const wanted = new Set(entries.map((e) => e.en));
		for (const entry of entries) {
			stat.total++;
			const value = translations[entry.en];
			if (value === undefined || value === "") continue;
			const found = problems(entry, value);
			if (found.length) {
				errors.push(`${code}/${where}: "${entry.en.slice(0, 60)}": ${found.join("; ")}`);
				continue;
			}
			stat.done++;
			into[entry.en] = value;
		}
		// Old strings (a story since rewritten, a past community week) are left out quietly.
		return Object.keys(translations).filter((k) => !wanted.has(k)).length;
	};

	for (const { file, entries } of sources.stories) {
		take(path.relative(dir, translationFile(code, file)), entries, await readJson(translationFile(code, file)), stories, stats.stories);
	}
	take("spoken.json", sources.spoken, await readJson(path.join(dir, "spoken.json")), stories, stats.spoken);
	const ui = {};
	take("ui.json", sources.ui, await readJson(path.join(dir, "ui.json")), ui, stats.ui);
	const glossary = await readJson(path.join(dir, "glossary.json"));

	const strings = [
		header(`The interface and the game's own names in ${code}.`),
		`ns.AddStrings("${code}", {`, luaMap(ui), "})", "",
		`ns.AddGlossary("${code}", {`, luaGlossary(glossary), "})", "",
	].join("\n").replace(/\n\n+(?=\})/g, "\n");
	const storiesLua = [
		header(`The stories in ${code}, by their English text.`),
		`ns.AddTranslations("${code}", {`, luaMap(stories), "})", "",
	].join("\n").replace(/\{\n\n\}/g, "{\n}");
	return { code, errors, stats, files: { "Strings.lua": strings, "Stories.lua": storiesLua } };
}

async function sources() {
	const stories = [];
	for (const file of await storyFiles()) stories.push({ file, entries: await fileStrings(file) });
	return { stories, ...(await codeStrings()) };
}

const all = await sources();

if (args[0] === "--todo") {
	const [, code, file] = args;
	if (!LANGUAGES.includes(code)) throw new Error(`Name a language: ${LANGUAGES.join(", ")}.`);
	const entries = file === "spoken.json" ? all.spoken : file === "ui.json" ? all.ui
		: all.stories.find((s) => s.file === file)?.entries;
	if (!entries) throw new Error(`${file} isn't a story file in the .toc (nor spoken.json or ui.json).`);
	const done = await readJson(file.endsWith(".json") ? path.join(TRANSLATIONS_DIR, code, file) : translationFile(code, file));
	const todo = {};
	for (const e of entries) if (done[e.en] === undefined) todo[e.en] = e.kind === "answers" ? e.words : "";
	console.log(JSON.stringify(todo, null, "\t"));
	process.exit(0);
}

let failed = false;
const report = [];
for (const code of LANGUAGES) {
	const result = await language(code, all);
	for (const error of result.errors) console.error(error);
	if (result.errors.length) failed = true;
	const s = result.stats;
	const pct = ({ done, total }) => `${done}/${total}`;
	report.push(`${code}: stories ${pct(s.stories)}, spoken ${pct(s.spoken)}, interface ${pct(s.ui)}`);
	for (const [name, text] of Object.entries(result.files)) {
		const out = path.join(ADDON_DIR, "locales", code, name);
		let before = "";
		try { before = await readFile(out, "utf8"); } catch {}
		if (before === text || DRY) continue;
		if (CHECK) {
			console.error(`locales/${code}/${name} is out of date. Run node tools/i18n/build.mjs and commit it.`);
			failed = true;
		} else {
			await mkdir(path.dirname(out), { recursive: true });
			await writeFile(out, text);
		}
	}
}
console.log(report.join("\n"));
if (failed) process.exit(1);
