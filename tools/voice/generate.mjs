// Makes a take of each voiced line that has none yet, and records it in voice-audio/takes.json.
//
//   node tools/voice/generate.mjs                          (lists what it would make and what it costs; spends nothing)
//   node tools/voice/generate.mjs --spend                  (makes them with config.json's provider)
//   node tools/voice/generate.mjs --provider say --spend   (makes test takes with the Mac's own voice, as "narrator-dev"; free)
//
// config.json's "provider" is fish (needs FISH_API_KEY) or elevenlabs (needs ELEVENLABS_API_KEY).
// --voice <name> picks one of config.json's "voices" (its "voice" otherwise). Several can be given
// as a comma list, "races" for every race voice, or "all" for every voice with an id; one run then
// makes them all, sharing the work.
// Other options: --limit <n>, --file <stories/zones/Westfall.lua>, --community (only lines that are in community
// stories alone), --env-file <path> (reads the keys from it), --concurrency <n>, and
// --max-dollars <n>, which stops before spending anything if the run would cost more.
// Masters are mp3s in voice-audio/masters/<voice>/, one per line, provider and voice, so
// switching back to an earlier provider or voice reuses what was already paid for. Nothing here
// deletes a take.
import { execFile } from "node:child_process";
import { createHash } from "node:crypto";
import { existsSync } from "node:fs";
import https from "node:https";
import { mkdir, readFile, rm, writeFile } from "node:fs/promises";
import { promisify } from "node:util";
import path from "node:path";
import { AUDIO_DIR, TAKES_FILE, bytes, collectLines, currentTake, estimate, loadConfig, loadTakes, seconds, sourceFor, voiceOption } from "./lines.mjs";

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

// fetch sends every request down one connection, and fish.audio answers them there one at a time,
// so --concurrency did nothing. This posts each request on a connection of its own.
const agent = new https.Agent({ keepAlive: true, maxSockets: 64 });
function post(url, headers, body) {
	return new Promise((resolve, reject) => {
		const req = https.request(url, { method: "POST", headers, agent }, (res) => {
			const chunks = [];
			res.on("data", (chunk) => chunks.push(chunk));
			res.on("end", () => resolve(new Response(Buffer.concat(chunks), { status: res.statusCode, headers: res.headers })));
			res.on("error", reject);
		});
		req.setTimeout(120000, () => req.destroy(new Error("timed out")));
		req.on("error", reject);
		req.end(body);
	});
}

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
		console.warn(`  ${name} answered ${response.status}, trying again: ${detail.slice(0, 120)}`);
		await wait(attempt);
	}
}

async function fishTake(text, config, out, ref) {
	const settings = config.fish;
	const response = await request("fish.audio", () => post("https://api.fish.audio/v1/tts", {
		authorization: `Bearer ${process.env.FISH_API_KEY}`,
		"content-type": "application/json",
		model: settings.model,
	}, JSON.stringify({
		text,
		reference_id: ref,
		format: "mp3",
		mp3_bitrate: settings.mp3Bitrate,
		normalize: settings.normalize,
		latency: settings.latency,
		temperature: settings.temperature,
		top_p: settings.topP,
	})), [400, 401, 402, 403, 404]);
	await writeFile(out, Buffer.from(await response.arrayBuffer()));
	return { model: settings.model };
}

// The same request Spoken makes for its narrator: eleven_v3, its voice settings and a fixed seed.
async function elevenlabsTake(text, config, out, ref) {
	const settings = config.elevenlabs;
	const url = `https://api.elevenlabs.io/v1/text-to-speech/${encodeURIComponent(ref)}?output_format=${settings.outputFormat}`;
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
const named = voiceOption(config);
const wanted = named === "races"
	? Object.keys(config.voices).filter((v) => config.voices[v].race)
	: named === "all"
		? Object.keys(config.voices).filter((v) => config.voices[v][config.provider])
		: named.split(",").map((v) => v.trim()).filter(Boolean);
const voices = wanted.map((v) => (asked === "say" ? `${v}-dev` : v));
const sources = new Map(voices.map((v) => [v, sourceFor(config, v)]));
const envFile = option("env-file");
if (envFile) await loadEnvFile(envFile);

const takes = await loadTakes();
const onlyFile = option("file");
const onlyCommunity = flag("community");
const lines = (await collectLines(config)).filter((line) => line.spoken
	&& (!onlyFile || line.files.some((f) => f === onlyFile || f.endsWith(`/${onlyFile}`))) && (!onlyCommunity || line.community));
const limit = Number(option("limit", "0"));
// One job per voice and line, a voice's lines together, so a stopped run leaves whole voices done.
let todo = [];
for (const voice of voices) {
	const source = sources.get(voice);
	let missing = lines.filter((line) => !currentTake(takes, voice, line, source));
	if (limit > 0) missing = missing.slice(0, limit);
	console.log(`${missing.length} lines to make in "${voice}" with ${source.provider}: ${estimate(missing, source, config)}.`);
	todo.push(...missing.map((line) => ({ voice, source, line })));
}
if (voices.length > 1) console.log(`${todo.length} in all: ${estimate(todo.map((j) => j.line), sources.get(voices[0]), config)}.`);
if (todo.length === 0) process.exit(0);
const maxDollars = option("max-dollars");
if (maxDollars !== null && sources.get(voices[0]).provider === "fish") {
	const dollars = (todo.reduce((sum, j) => sum + bytes(j.line.spoken), 0) / 1e6) * config.fish.dollarsPerMillionBytes;
	if (!(dollars <= Number(maxDollars))) {
		console.error(`This would cost about $${dollars.toFixed(2)}, over --max-dollars ${maxDollars}, so nothing was made.`);
		process.exit(2);
	}
}
if (!flag("spend")) {
	for (const { line } of todo.slice(0, 5)) console.log(`  ${line.id}  ${line.spoken.slice(0, 90)}`);
	console.log("Nothing was made. Add --spend to make them.");
	process.exit(0);
}
for (const [voice, source] of sources) {
	const key = KEYS[source.provider];
	if (key && !process.env[key]) throw new Error(`Set ${key}, or pass --env-file with it.`);
	if (source.provider !== "say" && !source.ref) {
		throw new Error(`Set voices["${voice}"].${source.provider} in tools/voice/config.json to the voice's id.`);
	}
	await mkdir(path.join(AUDIO_DIR, "masters", voice), { recursive: true });
	takes[voice] ??= {};
}

let done = 0;
let failed = 0;
let reused = 0;
let saving = Promise.resolve();
const write = () => (saving = saving.then(() => writeFile(TAKES_FILE, `${JSON.stringify(takes, null, "\t")}\n`)));
// At most every few seconds: the file holds every voice's takes, and a take lost in a crash is
// still on disk, so the next run reuses it for free.
let lastSave = 0;
const save = () => {
	if (Date.now() - lastSave < 5000) return saving;
	lastSave = Date.now();
	return write();
};

let next = 0;
let stop = null;
async function worker() {
	while (!stop && next < todo.length) {
		const { voice, source, line } = todo[next++];
		const make = MAKERS[source.provider];
		const folder = path.join(AUDIO_DIR, "masters", voice);
		// Named for the words, the provider and its voice, so a recording made before is found
		// again after switching back, and not paid for twice.
		const words = createHash("sha1").update(line.spoken).digest("hex").slice(0, 8);
		const file = `${line.id}-${words}-${source.provider}-${source.ref.slice(0, 8)}.mp3`;
		const out = path.join(folder, file);
		try {
			const made = existsSync(out) ? { reused: true } : await make(line.spoken, config, out, source.ref);
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
			if (done % 100 === 0) console.log(`  ${done} of ${todo.length} (${voice})`);
		} catch (error) {
			if (error instanceof Fatal) stop = error;
			else {
				failed++;
				console.warn(`  ${voice} ${line.id} failed: ${error.message}`);
			}
		}
	}
}
const concurrency = Math.max(1, Number(option("concurrency", { fish: "3", elevenlabs: "2", say: "4" }[sources.get(voices[0]).provider])));
await Promise.all(Array.from({ length: concurrency }, worker));
await write();
console.log(`Made ${done - reused} takes${reused ? `, reused ${reused} already on disk` : ""}${failed ? `, ${failed} failed` : ""}.`);
if (stop) {
	console.error(`Stopped: ${stop.message}`);
	process.exit(1);
}
