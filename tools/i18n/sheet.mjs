// A compact sheet of a language's riskiest translations, for an editor to read in one go:
// riddles, jokes, openers, and every emote.
//
//   node tools/i18n/sheet.mjs deDE > sheet.txt        each string numbered, English then translation
//   node tools/i18n/sheet.mjs deDE --apply edits.json  { "12": "new text" or ["part", "part"], ... }
//
// Edits that fail the checks aren't applied, and are listed.
import { readFile, writeFile } from "node:fs/promises";
import { fileStrings, problems, storyFiles, translationFile } from "./strings.mjs";

const [code, flag, editsFile] = process.argv.slice(2);
const WHOLE = new Set(["stories/Riddles.lua", "stories/shared/TavernJokes.lua", "Openers.lua"]);
const rows = [];
for (const file of await storyFiles()) {
	const json = JSON.parse(await readFile(translationFile(code, file), "utf8"));
	for (const entry of await fileStrings(file)) {
		if (WHOLE.has(file) || entry.kind === "emote") rows.push({ file, entry, value: json[entry.en] });
	}
}

if (flag !== "--apply") {
	let at = "";
	rows.forEach(({ file, entry, value }, i) => {
		const here = WHOLE.has(file) ? `${file}: ${entry.story ?? ""}` : "emotes";
		if (here !== at) console.log(`\n## ${at = here}`);
		console.log(`${i} [${entry.kind}] ${entry.en}\n  ${Array.isArray(value) ? value.join(" / ") : value}`);
	});
} else {
	const edits = JSON.parse(await readFile(editsFile, "utf8"));
	let done = 0;
	for (const [i, value] of Object.entries(edits)) {
		const row = rows[i];
		const found = row ? problems(row.entry, value) : ["no such number"];
		if (found.length) { console.log(`${i}: not applied: ${found.join("; ")}`); continue; }
		const path = translationFile(code, row.file);
		const json = JSON.parse(await readFile(path, "utf8"));
		json[row.entry.en] = value;
		await writeFile(path, JSON.stringify(json, null, "\t") + "\n");
		done++;
	}
	console.log(`${done} of ${Object.keys(edits).length} edits applied.`);
}
