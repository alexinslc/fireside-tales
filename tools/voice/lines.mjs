// Every story line in the addon that can be read aloud, and what the voice says for it.
//
//   node tools/voice/lines.mjs   (prints how many lines there are, how many have a take, and the cost of the rest)
//
// A line is keyed by its kind and text, so the same words in two stories are one recording, and
// a fixed typo only needs that line again. Character stories stay on this computer, so they're left out.
import { execFile } from "node:child_process";
import { createHash } from "node:crypto";
import { promisify } from "node:util";
import { readdir, readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import path from "node:path";
import { weekStart } from "../../site/shared/rules.js";

export const ROOT = fileURLToPath(new URL("../..", import.meta.url));
export const ADDON_DIR = path.join(ROOT, "addon", "FiresideTales");
export const AUDIO_DIR = process.env.FIRESIDE_VOICE_DIR ?? path.join(ROOT, "voice-audio");
export const TAKES_FILE = path.join(AUDIO_DIR, "takes.json");

// Paths in the addon folder, with forward slashes.
const LOCAL_ONLY = /^stories\/characters\//;
export const COMMUNITY_FILE = "stories/Community.lua";
const LINE = /\{\s*kind\s*=\s*"(say|emote)"\s*,\s*text\s*=\s*"((?:[^"\\]|\\.)*)"\s*\}/g;

// Community stories rotate each week, and so does their pack: it has only the week being told
// tomorrow. On a Monday (UTC), when the weekly job runs, that's the week starting the next day.
// FIRESIDE_COMMUNITY_WEEK picks another (a Tuesday, YYYY-MM-DD).
export const COMMUNITY_WEEK = process.env.FIRESIDE_COMMUNITY_WEEK || weekStart(new Date(Date.now() + 86400000));

// Only the voiced week's part of Community.lua.
function communityPart(source) {
	const parts = source.split(/(?=ns\.AddCommunityWeek\(")/);
	return parts.filter((part) => part.startsWith(`ns.AddCommunityWeek("${COMMUNITY_WEEK}"`)).join("");
}

export async function loadConfig() {
	return JSON.parse(await readFile(new URL("./config.json", import.meta.url), "utf8"));
}

function unescapeLua(text) {
	return text.replace(/\\(\d{1,3}|.)/g, (_, c) => {
		if (/^\d+$/.test(c)) return String.fromCharCode(Number(c));
		return { n: "\n", t: "\t", r: "\r" }[c] ?? c;
	});
}

// What the chat line looks like when it arrives, which is what the pack matches.
export function tidy(text) {
	return text.replace(/\s+/g, " ").trim();
}

export function lineId(kind, text) {
	return createHash("sha1").update(`${kind}\n${text}`).digest("hex").slice(0, 12);
}

// The words the voice reads, or null for a line that isn't voiced. A {target} line holds a name
// that can't be recorded ahead, so the voice says config.target's word in its place (a line can
// have its own word). An emote is voiced only if config.emotes says how.
export function spokenText(kind, text, config, id) {
	if (text.includes("{target}")) {
		if (kind !== "say" || !config.target) return null;
		const word = config.target.lines?.[id] ?? config.target.word;
		return text
			.replace(/(^|[.!?]\s+)\{target\}/g, (_, start) => start + word[0].toUpperCase() + word.slice(1))
			.replace(/\{target\}/g, word);
	}
	if (kind === "emote") return config.emotes === "teller" ? `The teller ${text}` : null;
	return text;
}

export async function collectLines(config) {
	const files = (await readdir(ADDON_DIR, { recursive: true }))
		.map((f) => f.split(path.sep).join("/"))
		.filter((f) => f.endsWith(".lua") && !LOCAL_ONLY.test(f)).sort();
	const byId = new Map();
	for (const file of files) {
		const text = await readFile(path.join(ADDON_DIR, file), "utf8");
		const source = file === COMMUNITY_FILE ? communityPart(text) : text;
		for (const match of source.matchAll(LINE)) {
			const kind = match[1];
			const text = tidy(unescapeLua(match[2]));
			if (!text) continue;
			const id = lineId(kind, text);
			const known = byId.get(id);
			if (known) {
				if (!known.files.includes(file)) known.files.push(file);
				continue;
			}
			byId.set(id, { id, kind, text, spoken: spokenText(kind, text, config, id), files: [file] });
		}
	}
	// A community line is one only community stories have. Those come and go each week, so their
	// sounds are in a pack of their own; a line a built-in story also has stays in the main packs.
	for (const line of byId.values()) line.community = line.files.every((f) => f === COMMUNITY_FILE);
	return [...byId.values()];
}

export async function loadTakes() {
	try {
		return JSON.parse(await readFile(TAKES_FILE, "utf8"));
	} catch (error) {
		if (error.code === "ENOENT") return {};
		throw error;
	}
}

// Which service and which of its voices make a voice's takes, from config.json's "voices". A "-dev"
// voice is the Mac's own, for testing. Changing the provider or a voice's id makes its takes out of date.
export function sourceFor(config, voice = config.voice) {
	if (voice.endsWith("-dev")) return { provider: "say", ref: "mac" };
	const settings = config.voices[voice];
	if (!settings) throw new Error(`config.json has no voice "${voice}". It has ${Object.keys(config.voices).join(", ")}.`);
	if (!["fish", "elevenlabs"].includes(config.provider)) {
		throw new Error(`config.json's provider is "${config.provider}". Use fish or elevenlabs.`);
	}
	return { provider: config.provider, ref: settings[config.provider] ?? "" };
}

// The voice a command names with --voice, or config.json's.
export function voiceOption(config) {
	const at = process.argv.indexOf("--voice");
	return at === -1 ? config.voice : process.argv[at + 1];
}

// The take of a line in a voice, if it was made from the words the voice says now, by the
// voice's current source.
export function currentTake(takes, voice, line, source) {
	const take = takes[voice]?.[line.id];
	if (!take || take.spoken !== line.spoken) return null;
	return take.provider === source.provider && (take.ref ?? "") === source.ref ? take : null;
}

// What making these lines would cost with a source: fish.audio bills UTF-8 bytes, ElevenLabs
// characters times the plan's rate.
export function estimate(lines, source, config) {
	if (source.provider === "say") return "free";
	if (source.provider === "fish") {
		const n = lines.reduce((sum, l) => sum + bytes(l.spoken), 0);
		return `${n.toLocaleString()} bytes, about $${((n / 1e6) * config.fish.dollarsPerMillionBytes).toFixed(2)} on fish.audio`;
	}
	const n = lines.reduce((sum, l) => sum + [...l.spoken].length, 0);
	const credits = Math.round(n * config.elevenlabs.creditsPerCharacter);
	return `${n.toLocaleString()} characters, about ${credits.toLocaleString()} ElevenLabs credits`;
}

// A sound's length, which the game can't measure, so the pack carries it.
export async function seconds(file) {
	const { stdout } = await promisify(execFile)("ffprobe", ["-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", file]);
	return Math.round(Number(stdout.trim()) * 100) / 100;
}

export function bytes(text) {
	return Buffer.byteLength(text, "utf8");
}

if (import.meta.url === `file://${process.argv[1]}`) {
	const config = await loadConfig();
	const lines = await collectLines(config);
	const takes = await loadTakes();
	const voiced = lines.filter((l) => l.spoken);
	console.log(`${lines.length} lines (${lines.filter((l) => l.kind === "say").length} say, ${lines.filter((l) => l.kind === "emote").length} emote).`);
	console.log(`${voiced.length} are voiced (emotes: ${config.emotes}; {target} lines say "${config.target?.word ?? "nothing"}").`);
	for (const voice of Object.keys(config.voices)) {
		const source = sourceFor(config, voice);
		const missing = voiced.filter((l) => !currentTake(takes, voice, l, source));
		console.log(`${voice}: ${voiced.length - missing.length} have a take, ${missing.length} don't${source.ref ? "" : " (no voice id yet)"}.`);
		if (missing.length > 0) {
			for (const provider of ["fish", "elevenlabs"]) {
				console.log(`  With ${provider}: ${estimate(missing, { provider }, config)}.`);
			}
		}
	}
}
