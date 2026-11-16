// Tries narrator voices on a test story, so they can be compared before any real lines are made.
// Every file lands in voice-audio/auditions/. Each command spends a little.
//
//   node tools/voice/audition.mjs design "<description>"      (ElevenLabs Voice Design: three voices reading the story)
//   node tools/voice/audition.mjs fish <model id> <name>       (a fish.audio library voice, line by line)
//   node tools/voice/audition.mjs fish-from <preview.mp3>      (fish.audio copying a designed voice from its preview)
//   node tools/voice/audition.mjs eleven <voice id> <name>     (a saved ElevenLabs voice, with Spoken's narrator settings)
//
// Pass --env-file <path> for the API keys.
import { execFile } from "node:child_process";
import { mkdir, readFile, rm, writeFile } from "node:fs/promises";
import { promisify } from "node:util";
import path from "node:path";
import { AUDIO_DIR, loadConfig } from "./lines.mjs";

const run = promisify(execFile);
const DIR = path.join(AUDIO_DIR, "auditions");

const args = process.argv.slice(2);
const envAt = args.indexOf("--env-file");
if (envAt !== -1) {
	for (const row of (await readFile(args[envAt + 1], "utf8")).split(/\r?\n/)) {
		const m = row.match(/^\s*(?:export\s+)?([A-Z_][A-Z0-9_]*)\s*=\s*(.*?)\s*$/);
		if (m && !(m[1] in process.env)) process.env[m[1]] = m[2].replace(/^(["'])(.*)\1$/, "$2");
	}
	args.splice(envAt, 2);
}
const [command, ...rest] = args;
const config = await loadConfig();
const story = JSON.parse(await readFile(path.join(DIR, "story.json"), "utf8"));
await mkdir(DIR, { recursive: true });

async function check(response, name) {
	if (!response.ok) throw new Error(`${name} answered ${response.status}: ${(await response.text()).slice(0, 300)}`);
	return response;
}

// Joins line takes into one file with a pause between lines, as a teller would.
async function join(parts, out) {
	const list = path.join(DIR, "join.txt");
	const gap = path.join(DIR, "gap.mp3");
	await run("ffmpeg", ["-v", "error", "-y", "-f", "lavfi", "-t", "0.8", "-i", "anullsrc=r=44100:cl=mono", "-c:a", "libmp3lame", "-q:a", "4", gap]);
	await writeFile(list, parts.flatMap((p, i) => [`file '${p}'`, ...(i < parts.length - 1 ? [`file '${gap}'`] : [])]).join("\n"));
	await run("ffmpeg", ["-v", "error", "-y", "-f", "concat", "-safe", "0", "-i", list, "-ac", "1", "-ar", "44100", "-c:a", "libmp3lame", "-q:a", "4", out]);
	for (const p of [list, gap, ...parts]) await rm(p);
	console.log(`Wrote ${path.relative(process.cwd(), out)}`);
}

// Just enough MessagePack for fish.audio's inline references: maps, arrays, strings, binary,
// numbers and booleans.
function msgpack(value) {
	const out = [];
	const head = (small, base, n, codes) => {
		if (small !== null && n < small) out.push(base | n);
		else if (n < 256 && codes[0]) out.push(codes[0], n);
		else if (n < 65536) out.push(codes[1], n >> 8, n & 255);
		else out.push(codes[2], (n >>> 24) & 255, (n >> 16) & 255, (n >> 8) & 255, n & 255);
	};
	const put = (v) => {
		if (v === null || v === undefined) out.push(0xc0);
		else if (v === true || v === false) out.push(v ? 0xc3 : 0xc2);
		else if (typeof v === "number") {
			if (Number.isInteger(v) && v >= 0 && v < 128) out.push(v);
			else if (Number.isInteger(v) && v >= 0 && v < 256) out.push(0xcc, v);
			else if (Number.isInteger(v) && v >= 0 && v < 65536) out.push(0xcd, v >> 8, v & 255);
			else { const b = Buffer.alloc(9); b[0] = 0xcb; b.writeDoubleBE(v, 1); out.push(...b); }
		} else if (typeof v === "string") {
			const b = Buffer.from(v, "utf8");
			head(32, 0xa0, b.length, [0xd9, 0xda, 0xdb]);
			for (const x of b) out.push(x);
		} else if (Buffer.isBuffer(v)) {
			head(null, 0, v.length, [0xc4, 0xc5, 0xc6]);
			for (const x of v) out.push(x);
		} else if (Array.isArray(v)) {
			head(16, 0x90, v.length, [null, 0xdc, 0xdd]);
			v.forEach(put);
		} else {
			const entries = Object.entries(v);
			head(16, 0x80, entries.length, [null, 0xde, 0xdf]);
			for (const [k, x] of entries) { put(k); put(x); }
		}
	};
	put(value);
	return Buffer.from(out);
}

async function fishLine(text, extra, out) {
	const s = config.fish;
	const body = { text, format: "mp3", mp3_bitrate: 128, normalize: true, latency: "normal", temperature: s.temperature, top_p: s.topP, ...extra };
	const inline = "references" in extra;
	const response = await check(await fetch("https://api.fish.audio/v1/tts", {
		method: "POST",
		headers: {
			authorization: `Bearer ${process.env.FISH_API_KEY}`,
			"content-type": inline ? "application/msgpack" : "application/json",
			model: s.model,
		},
		body: inline ? msgpack(body) : JSON.stringify(body),
	}), "fish.audio");
	await writeFile(out, Buffer.from(await response.arrayBuffer()));
}

async function elevenLine(voiceId, text, out) {
	const s = config.elevenlabs;
	const response = await check(await fetch(`https://api.elevenlabs.io/v1/text-to-speech/${voiceId}?output_format=${s.outputFormat}`, {
		method: "POST",
		headers: { "xi-api-key": process.env.ELEVENLABS_API_KEY, "content-type": "application/json" },
		body: JSON.stringify({ text, model_id: s.model, language_code: s.languageCode, seed: s.seed, voice_settings: s.voiceSettings }),
	}), "ElevenLabs");
	await writeFile(out, Buffer.from(await response.arrayBuffer()));
}

async function eachLine(name, make) {
	const parts = [];
	for (const [i, text] of story.lines.entries()) {
		const part = path.join(DIR, `${name}-${i}.mp3`);
		await make(text, part);
		parts.push(part);
	}
	await join(parts, path.join(DIR, `${name}.mp3`));
}

if (command === "design") {
	const description = rest.join(" ");
	const text = story.lines.join(" ");
	const response = await check(await fetch("https://api.elevenlabs.io/v1/text-to-voice/design?output_format=mp3_44100_128", {
		method: "POST",
		headers: { "xi-api-key": process.env.ELEVENLABS_API_KEY, "content-type": "application/json" },
		body: JSON.stringify({ voice_description: description, text, model_id: "eleven_ttv_v3" }),
	}), "ElevenLabs");
	const result = await response.json();
	const saved = [];
	for (const [i, preview] of result.previews.entries()) {
		const file = path.join(DIR, `eleven-design-${i + 1}.mp3`);
		await writeFile(file, Buffer.from(preview.audio_base_64, "base64"));
		saved.push({ file: path.basename(file), generatedVoiceId: preview.generated_voice_id, seconds: preview.duration_secs });
		console.log(`Wrote ${path.relative(process.cwd(), file)} (${preview.duration_secs.toFixed(1)} s)`);
	}
	await writeFile(path.join(DIR, "design.json"), `${JSON.stringify({ description, text, previews: saved }, null, "\t")}\n`);
} else if (command === "fish") {
	const [id, name] = rest;
	await eachLine(`fish-${name}`, (text, out) => fishLine(text, { reference_id: id }, out));
} else if (command === "fish-from") {
	// The preview reads the whole story, so the story is its exact transcript.
	const preview = path.join(DIR, rest[0]);
	const audio = await readFile(preview);
	const name = `fish-from-${path.basename(preview, ".mp3")}`;
	await eachLine(name, (text, out) => fishLine(text, { references: [{ audio, text: story.lines.join(" ") }] }, out));
} else if (command === "eleven") {
	const [id, name] = rest;
	await eachLine(`eleven-${name}`, (text, out) => elevenLine(id, text, out));
} else {
	console.log("Use design, fish, fish-from or eleven. See the top of this file.");
}
