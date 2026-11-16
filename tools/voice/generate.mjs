// Makes a take of each voiced line that has none yet, and records it in voice-audio/takes.json.
//
//   node tools/voice/generate.mjs                          (lists what it would make and what it costs; spends nothing)
//   node tools/voice/generate.mjs --spend                  (makes them with config.json's provider)
//   node tools/voice/generate.mjs --provider say --spend   (makes test takes with the Mac's own voice, as "narrator-dev"; free)
//
// config.json's "provider" is fish (needs FISH_API_KEY) or elevenlabs (needs ELEVENLABS_API_KEY).
// Other options: --limit <n>, --file <Stories.lua>, --env-file <path> (reads the keys from it), --concurrency <n>.
// Masters are mp3s in voice-audio/masters/<voice>/, one per line, provider and voice, so
// switching back to an earlier provider or voice reuses what was already paid for. Nothing here
// deletes a take.
import { execFile } from "node:child_process";
import { createHash } from "node:crypto";
import { existsSync } from "node:fs";
import { mkdir, readFile, rm, writeFile } from "node:fs/promises";
import { promisify } from "node:util";
import path from "node:path";
import { AUDIO_DIR, TAKES_FILE, bytes, collectLines, currentTake, estimate, loadConfig, loadTakes, seconds, sourceFor } from "./lines.mjs";

const run = promisify(execFile);

function option(name, fallback = null) {
	const at = process.argv.indexOf(`--${name}`);
	return at === -1 ? fallback : process.argv[at + 1];
}
const flag = (name) => process.argv.includes(`--${name}`);

async function loadEnvFile(file) {
	for (const row of (await readFile(file, "utf8")).split(/\r?\n/)) {
		const match = row.match(/^\s*(?:export\s+)?([A-Z_][A-Z0-9_]*)\s*=\s*(.*?)\s*$/);
		if (match && !(match[1] in process.env)) process.env[match[1]] = match[2].replace(/^(["'])(.*)\1$/, "$2");
	}
}

class Fatal extends Error {}

const wait = (attempt) => new Promise((resolve) => setTimeout(resolve, 2000 * 2 ** attempt + Math.random() * 1000));

// Sends one request, retrying what can pass (busy, rate limited) and stopping the run on what
// fails every line the same way (a bad key, no credit, a missing voice).
async function request(name, send, fatal) {
	for (let attempt = 1; ; attempt++) {
		const response = await send();
		if (response.ok) return response;
		const detail = (await response.text()).slice(0, 300);
		if (fatal.includes(response.status)) throw new Fatal(`${name} answered ${response.status}: ${detail}`);
		if (attempt >= 4) throw new Error(`${name} answered ${response.status} ${attempt} times: ${detail}`);
		await wait(attempt);
	}
}

async function fishTake(text, config, out) {
	const settings = config.fish;
	const response = await request("fish.audio", () => fetch("https://api.fish.audio/v1/tts", {
		method: "POST",
		headers: {
			authorization: `Bearer ${process.env.FISH_API_KEY}`,
			"content-type": "application/json",
			model: settings.model,
		},
		body: JSON.stringify({
			text,
			reference_id: settings.referenceId,
			format: "mp3",
			mp3_bitrate: settings.mp3Bitrate,
			normalize: settings.normalize,
			latency: settings.latency,
			temperature: settings.temperature,
			top_p: settings.topP,
		}),
	}), [400, 401, 402, 403, 404]);
	await writeFile(out, Buffer.from(await response.arrayBuffer()));
	return { model: settings.model };
}

// The same request Spoken makes for its narrator: eleven_v3, its voice settings and a fixed seed.
async function elevenlabsTake(text, config, out) {
	const settings = config.elevenlabs;
	const url = `https://api.elevenlabs.io/v1/text-to-speech/${encodeURIComponent(settings.voiceId)}?output_format=${settings.outputFormat}`;
	const response = await request("ElevenLabs", () => fetch(url, {
		method: "POST",
		headers: { "xi-api-key": process.env.ELEVENLABS_API_KEY, "content-type": "application/json" },
		body: JSON.stringify({
			text,
			model_id: settings.model,
			language_code: settings.languageCode,
			seed: settings.seed,
			voice_settings: settings.voiceSettings,
		}),
	}), [400, 401, 402, 403, 404, 422]);
	await writeFile(out, Buffer.from(await response.arrayBuffer()));
	// What the account was actually charged, which the plan's rate decides.
	const credits = Number(response.headers.get("character-cost") ?? response.headers.get("x-character-count"));
	return { model: settings.model, ...(Number.isFinite(credits) && credits > 0 ? { credits } : {}) };
}

async function sayTake(text, _config, out) {
	const aiff = `${out}.aiff`;
	await run("say", ["-o", aiff, text]);
	await run("ffmpeg", ["-v", "error", "-y", "-i", aiff, "-ac", "1", "-c:a", "libmp3lame", "-q:a", "4", out]);
	await rm(aiff);
	return {};
}

const MAKERS = { fish: fishTake, elevenlabs: elevenlabsTake, say: sayTake };
const KEYS = { fish: "FISH_API_KEY", elevenlabs: "ELEVENLABS_API_KEY" };

const config = await loadConfig();
const asked = option("provider");
if (asked && asked !== "say") throw new Error(`Set "provider" in tools/voice/config.json to switch; --provider only takes say.`);
const voice = asked === "say" ? `${config.voice}-dev` : config.voice;
const source = sourceFor(config, voice);
const envFile = option("env-file");
if (envFile) await loadEnvFile(envFile);

const takes = await loadTakes();
const onlyFile = option("file");
let todo = (await collectLines(config))
	.filter((line) => line.spoken && !currentTake(takes, voice, line, source))
	.filter((line) => !onlyFile || line.files.includes(onlyFile));
const limit = Number(option("limit", "0"));
if (limit > 0) todo = todo.slice(0, limit);

console.log(`${todo.length} lines to make in "${voice}" with ${source.provider}: ${estimate(todo, source, config)}.`);
if (todo.length === 0) process.exit(0);
if (!flag("spend")) {
	for (const line of todo.slice(0, 5)) console.log(`  ${line.id}  ${line.spoken.slice(0, 90)}`);
	console.log("Nothing was made. Add --spend to make them.");
	process.exit(0);
}
const key = KEYS[source.provider];
if (key && !process.env[key]) throw new Error(`Set ${key}, or pass --env-file with it.`);
if (source.provider !== "say" && !source.ref) {
	throw new Error(`Set ${source.provider === "fish" ? "fish.referenceId" : "elevenlabs.voiceId"} in tools/voice/config.json to the narrator's voice id.`);
}

const make = MAKERS[source.provider];
const folder = path.join(AUDIO_DIR, "masters", voice);
await mkdir(folder, { recursive: true });
takes[voice] ??= {};

let done = 0;
let failed = 0;
let reused = 0;
let saving = Promise.resolve();
const save = () => (saving = saving.then(() => writeFile(TAKES_FILE, `${JSON.stringify(takes, null, "\t")}\n`)));

let next = 0;
let stop = null;
async function worker() {
	while (!stop && next < todo.length) {
		const line = todo[next++];
		// Named for the words, the provider and its voice, so a recording made before is found
		// again after switching back, and not paid for twice.
		const words = createHash("sha1").update(line.spoken).digest("hex").slice(0, 8);
		const file = `${line.id}-${words}-${source.provider}-${source.ref.slice(0, 8)}.mp3`;
		const out = path.join(folder, file);
		try {
			const made = existsSync(out) ? { reused: true } : await make(line.spoken, config, out);
			if (made.reused) reused++;
			takes[voice][line.id] = {
				kind: line.kind,
				text: line.text,
				spoken: line.spoken,
				provider: source.provider,
				ref: source.ref,
				file,
				...made,
				seconds: await seconds(out),
				bytes: bytes(line.spoken),
				at: new Date().toISOString(),
			};
			done++;
			await save();
			if (done % 25 === 0) console.log(`  ${done} of ${todo.length}`);
		} catch (error) {
			if (error instanceof Fatal) stop = error;
			else {
				failed++;
				console.warn(`  ${line.id} failed: ${error.message}`);
			}
		}
	}
}
const concurrency = Math.max(1, Number(option("concurrency", { fish: "3", elevenlabs: "2", say: "4" }[source.provider])));
await Promise.all(Array.from({ length: concurrency }, worker));
await saving;
console.log(`Made ${done - reused} takes${reused ? `, reused ${reused} already on disk` : ""}${failed ? `, ${failed} failed` : ""}.`);
if (stop) {
	console.error(`Stopped: ${stop.message}`);
	process.exit(1);
}
