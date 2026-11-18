// Builds what reads stories aloud:
//   addon/FiresideTales/VoiceLines.lua   the lines Fireside Tales listens for, shared by every voice
//   addon/<pack>/                        a voice pack from config.json's "packs": its toc, Pack.lua
//                                        (each voice's sound lengths) and Sounds/<voice>/
//
//   node tools/voice/build.mjs                                       (VoiceLines.lua and every pack)
//   node tools/voice/build.mjs --pack FiresideTalesVoices_Narrator   (VoiceLines.lua and just that pack)
//   node tools/voice/build.mjs --voice narrator-male-dev             (the Mac's test takes, in a pack of their own)
//
// A pack holds each of its voices' lines that have a take of the words they say now, by config.json's
// provider and that voice. Sounds no line uses any more are removed from it (never from voice-audio).
import { execFile } from "node:child_process";
import { mkdir, mkdtemp, readdir, readFile, rm, stat, writeFile } from "node:fs/promises";
import os from "node:os";
import { promisify } from "node:util";
import path from "node:path";
import { AUDIO_DIR, COMMUNITY_WEEK, ROOT, collectLines, currentTake, loadConfig, loadTakes, seconds, sourceFor } from "./lines.mjs";

const run = promisify(execFile);
const ADDONS = path.join(ROOT, "addon");
const CORE = path.join(ADDONS, "FiresideTales");

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

const byText = (a, b) => (a.text < b.text ? -1 : a.text > b.text ? 1 : 0);

const config = await loadConfig();
const takes = await loadTakes();
const allLines = (await collectLines(config)).filter((l) => l.spoken);
// The main packs and VoiceLines.lua have the built-in stories' lines; the community pack, and the
// lines table it adds, the ones only community stories have.
const builtIn = allLines.filter((l) => !l.community);
const community = allLines.filter((l) => l.community);
const linesFor = (pack) => (pack.lines === "community" ? community : builtIn);
const coreToc = await readFile(path.join(CORE, "FiresideTales.toc"), "utf8");
const version = coreToc.match(/^## Version: (.+)$/m)[1].trim();
const interfaceVersion = coreToc.match(/^## Interface: (.+)$/m)[1].trim();

// A lines table: every voiced line, whichever voices have it.
const block = (lines, kind) => lines
	.filter((l) => l.kind === kind)
	.sort(byText)
	.map((l) => `\t\t[${lua(l.text)}] = { "${l.id}"${l.spoken !== l.text ? `, ${lua(l.spoken)}` : ""} },`)
	.join("\n");
await writeFile(path.join(CORE, "VoiceLines.lua"), [
	"-- The lines Voices.lua listens for, by chat type and the exact text as it arrives: the sound's",
	"-- file name, and what the voice says if that isn't the line itself. A {target} line matches",
	"-- whatever name is in its place. The voice packs have the sounds.",
	"-- Written by tools/voice/build.mjs, so don't edit it here.",
	"local _, ns = ...",
	"",
	"ns.VoiceLines = {",
	"\tsay = {",
	block(builtIn, "say"),
	"\t},",
	"\temote = {",
	block(builtIn, "emote"),
	"\t},",
	"}",
	"",
].join("\n"));
console.log(`VoiceLines.lua: ${builtIn.length} lines (and ${community.length} only community stories have).`);

// How a master becomes a pack's sound. Ogg Vorbis: the game reads some mp3s as shorter than they
// are and stops them partway, but plays Ogg to the end. ffmpeg here has no mono Vorbis encoder, so
// oggenc (brew install vorbis-tools) makes them, from a wav ffmpeg decodes. config.json's "pack"
// gives the sample rate and either kbps (an average bitrate, as Spoken's quest audio uses: 44.1 kHz
// mono at 48) or a Vorbis quality.
const encoding = (() => {
	const { format = "ogg", sampleRate = 44100, quality, kbps = 48 } = config.pack;
	if (format === "mp3") {
		const args = ["-ac", "1", "-ar", String(sampleRate), "-c:a", "libmp3lame", "-b:a", `${kbps}k`];
		return { ext: "mp3", stamp: args.join(" "), make: (master, out) => run("ffmpeg", ["-v", "error", "-y", "-i", master, ...args, out]) };
	}
	const rate = quality !== undefined ? ["-q", String(quality)] : ["-b", String(kbps)];
	return {
		ext: "ogg",
		stamp: `ogg mono ${sampleRate} ${rate.join("")}`,
		async make(master, out) {
			const dir = await mkdtemp(path.join(os.tmpdir(), "fireside-"));
			const wav = path.join(dir, "line.wav");
			try {
				await run("ffmpeg", ["-v", "error", "-y", "-i", master, "-map_metadata", "-1", "-fflags", "+bitexact", "-flags:a", "+bitexact", "-ac", "1", "-ar", String(sampleRate), wav]);
				await run("oggenc", ["-Q", ...rate, "-o", out, wav]);
			} finally {
				await rm(dir, { recursive: true, force: true });
			}
		},
	};
})();

// One voice's sounds, into the pack's Sounds/<voice>/. Returns what Pack.lua says about it.
async function buildVoice(voice, sounds, fresh, lines) {
	const base = voice.replace(/-dev$/, "");
	const settings = config.voices[base];
	if (!settings) throw new Error(`config.json has no voice "${base}".`);
	const source = sourceFor(config, voice);
	const folder = path.join(sounds, voice);
	await mkdir(folder, { recursive: true });

	const lengths = [];
	const keep = new Set();
	let audioSeconds = 0;
	const todo = lines.filter((line) => currentTake(takes, voice, line, source));
	// Several at once, one per core or so: each is an ffmpeg (and an oggenc) of its own.
	const workers = Array.from({ length: Math.max(1, os.cpus().length - 1) }, async () => {
		while (todo.length > 0) {
			const line = todo.shift();
			const take = currentTake(takes, voice, line, source);
			const master = path.join(AUDIO_DIR, "masters", voice, take.file);
			const file = `${line.id}.${encoding.ext}`;
			const out = path.join(folder, file);
			if (!fresh || await newer(master, out)) await encoding.make(master, out);
			const length = await seconds(out);
			audioSeconds += length;
			keep.add(file);
			lengths.push([line.id, length]);
		}
	});
	await Promise.all(workers);
	let removed = 0;
	for (const file of await readdir(folder)) {
		if (!keep.has(file)) {
			await rm(path.join(folder, file));
			removed++;
		}
	}
	if (lengths.length === 0) {
		await rm(folder, { recursive: true, force: true });
		console.log(`  ${voice}: no takes, so it's left out.`);
		return null;
	}
	let size = 0;
	for (const f of keep) size += (await stat(path.join(folder, f))).size;
	console.log(`  ${voice}: ${lengths.length} of ${lines.length} lines, ` +
		`${(audioSeconds / 60).toFixed(1)} minutes, ${(size / 1e6).toFixed(1)} MB${removed ? `, ${removed} old sounds removed` : ""}.`);
	lengths.sort((a, b) => (a[0] < b[0] ? -1 : 1));
	return { voice, settings, lengths, size };
}

async function buildPack(addon, pack) {
	const folder = path.join(ADDONS, addon);
	const sounds = path.join(folder, "Sounds");
	await mkdir(sounds, { recursive: true });

	// Sounds made with other settings are made again.
	const stamp = path.join(folder, ".encoding");
	const fresh = await readFile(stamp, "utf8").then((t) => t === encoding.stamp, () => false);

	console.log(`${addon}:`);
	const lines = linesFor(pack);
	const built = [];
	for (const voice of pack.voices) {
		const result = await buildVoice(voice, sounds, fresh, lines);
		if (result) built.push(result);
	}
	// Voices no longer in the pack.
	for (const name of await readdir(sounds)) {
		if (!pack.voices.includes(name)) await rm(path.join(sounds, name), { recursive: true, force: true });
	}
	await writeFile(stamp, encoding.stamp);
	if (built.length === 0) {
		await rm(folder, { recursive: true, force: true });
		console.log(`  no takes, so no addon.`);
		return;
	}

	const title = `Fireside Tales Voices: ${pack.title}`;
	await writeFile(path.join(folder, `${addon}.toc`), [
		`## Interface: ${interfaceVersion}`,
		`## Title: ${title}`,
		`## Notes: ${pack.notes} Fireside Tales reads stories aloud in these voices.`,
		`## Version: ${pack.lines === "community" ? communityVersion() : version}`,
		"## IconTexture: Interface\\AddOns\\FiresideTales\\Textures\\Icon",
		"## Dependencies: FiresideTales",
		"",
		"Pack.lua",
		"",
	].join("\n"));
	const voiceBlock = ({ voice, settings, lengths }) => [
		"FiresideTales_AddVoice({",
		`\tkey = ${lua(voice)},`,
		`\ttitle = ${lua(settings.title + (voice.endsWith("-dev") ? " (test)" : ""))},`,
		"\taddon = ADDON,",
		`\tfolder = ${lua(voice)},`,
		...(encoding.ext === "mp3" ? [] : [`\text = ${lua(encoding.ext)},`]),
		`\torder = ${Number(settings.order) || 99},`,
		...(settings.race ? [`\trace = ${lua(settings.race)},`, `\tsex = ${settings.sex === "female" ? 3 : 2},`] : []),
		"\tlengths = {",
		...lengths.map(([id, length]) => `\t\t["${id}"] = ${length},`),
		"\t},",
		"})",
	].join("\n");
	await writeFile(path.join(folder, "Pack.lua"), [
		`-- ${title}: each voice's sound lengths in seconds, by file name.`,
		"-- Written by tools/voice/build.mjs, so don't edit it here.",
		"local ADDON = ...",
		"",
		...(pack.lines === "community" ? [
			"-- The lines only community stories have, which Fireside Tales listens for along with its own.",
			"FiresideTales_AddLines({",
			"\tsay = {",
			block(lines, "say"),
			"\t},",
			"\temote = {",
			block(lines, "emote"),
			"\t},",
			"})",
			"",
		] : []),
		built.map(voiceBlock).join("\n\n"),
		"",
	].join("\n"));
	const size = built.reduce((sum, b) => sum + b.size, 0);
	console.log(`  ${built.length} ${built.length === 1 ? "voice" : "voices"}, ${(size / 1e6).toFixed(1)} MB in all.`);
	// CurseForge refuses an upload much over 500 MB (480 MiB went through and 510 MiB didn't).
	if (size > 480 * 2 ** 20) console.log(`  This is over CurseForge's upload limit of about 500 MB, so split the pack.`);
}

// The community pack changes each week, apart from Fireside Tales' own releases, so its version
// is the week it has, like 2026.11.24.
function communityVersion() {
	return COMMUNITY_WEEK.replaceAll("-", ".");
}

const packs = config.packs;
const packAt = process.argv.indexOf("--pack");
const voiceAt = process.argv.indexOf("--voice");
if (voiceAt !== -1) {
	// Test takes, in a pack of their own so they never mix with the real sounds.
	const voice = process.argv[voiceAt + 1];
	if (!/^[a-z0-9-]+-dev$/.test(voice)) throw new Error("--voice is for test takes, like narrator-male-dev. Use --pack for the real ones.");
	await buildPack("FiresideTalesVoices_Test", { title: "Test", notes: "Test takes.", voices: [voice] });
} else {
	const names = packAt === -1 ? Object.keys(packs) : [process.argv[packAt + 1]];
	for (const name of names) {
		if (!packs[name]) throw new Error(`config.json has no pack "${name}".`);
		await buildPack(name, packs[name]);
	}
}
