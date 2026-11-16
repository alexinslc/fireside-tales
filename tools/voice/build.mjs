// Builds the voice pack: encodes each line's take into addon/FiresideTalesVoices/Sounds/<voice>/ and
// writes addon/FiresideTalesVoices/Lines.lua, the table the pack matches chat lines against.
//
//   node tools/voice/build.mjs                  (the "narrator" voice from config.json)
//   node tools/voice/build.mjs --voice narrator-dev
//
// Only lines still in the addon, with a take of the words they say now by config.json's provider
// and voice, go in. Sounds no line uses any more are removed from the pack (never from voice-audio).
import { execFile } from "node:child_process";
import { mkdir, readdir, rm, stat, writeFile } from "node:fs/promises";
import { promisify } from "node:util";
import path from "node:path";
import { AUDIO_DIR, ROOT, collectLines, currentTake, loadConfig, loadTakes, seconds, sourceFor } from "./lines.mjs";

const run = promisify(execFile);
const PACK = path.join(ROOT, "addon", "FiresideTalesVoices");

function lua(text) {
	return `"${String(text).replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\r?\n/g, " ")}"`;
}

async function newer(a, b) {
	try {
		return (await stat(a)).mtimeMs > (await stat(b)).mtimeMs;
	} catch {
		return true;
	}
}

const config = await loadConfig();
const at = process.argv.indexOf("--voice");
const voice = at === -1 ? config.voice : process.argv[at + 1];
if (!/^[a-z0-9-]+$/.test(voice)) throw new Error(`"${voice}" isn't a voice name.`);

const source = sourceFor(config, voice);
const takes = await loadTakes();
const lines = await collectLines(config);
const sounds = path.join(PACK, "Sounds", voice);
await mkdir(sounds, { recursive: true });

const entries = { say: [], emote: [] };
const keep = new Set();
let audioSeconds = 0;
for (const line of lines) {
	if (!line.spoken) continue;
	const take = currentTake(takes, voice, line, source);
	if (!take) continue;
	const master = path.join(AUDIO_DIR, "masters", voice, take.file);
	const out = path.join(sounds, `${line.id}.mp3`);
	if (await newer(master, out)) {
		// Mono VBR mp3 is about half the size of the master, and speech loses nothing you'd hear.
		await run("ffmpeg", ["-v", "error", "-y", "-i", master, "-ac", "1", "-c:a", "libmp3lame", "-q:a", String(config.mp3Quality), out]);
	}
	const length = await seconds(out);
	audioSeconds += length;
	keep.add(`${line.id}.mp3`);
	entries[line.kind].push({ text: line.text, id: line.id, length, spoken: line.spoken === line.text ? null : line.spoken });
}

let removed = 0;
for (const file of await readdir(sounds)) {
	if (!keep.has(file)) {
		await rm(path.join(sounds, file));
		removed++;
	}
}

const block = (list) => list
	.sort((a, b) => (a.text < b.text ? -1 : a.text > b.text ? 1 : 0))
	.map((e) => `\t\t[${lua(e.text)}] = { "${e.id}", ${e.length}${e.spoken ? `, ${lua(e.spoken)}` : ""} },`)
	.join("\n");
const file = [
	"-- The lines this pack can read, by chat type and the exact text as it arrives: the sound's",
	"-- file name, its length in seconds, and what the voice says if that isn't the line itself.",
	"-- Written by tools/voice/build.mjs, so don't edit it here.",
	"local _, ns = ...",
	"",
	`ns.Voice = ${lua(voice)}`,
	"ns.Lines = {",
	"\tsay = {",
	block(entries.say),
	"\t},",
	"\temote = {",
	block(entries.emote),
	"\t},",
	"}",
	"",
].join("\n");
await writeFile(path.join(PACK, "Lines.lua"), file);

let size = 0;
for (const f of keep) size += (await stat(path.join(sounds, f))).size;
const voiced = entries.say.length + entries.emote.length;
console.log(`Lines.lua: ${voiced} of ${lines.filter((l) => l.spoken).length} voiced lines in "${voice}", ` +
	`${(audioSeconds / 60).toFixed(1)} minutes, ${(size / 1e6).toFixed(1)} MB${removed ? `, ${removed} old sounds removed` : ""}.`);
