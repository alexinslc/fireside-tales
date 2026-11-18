// Keeps what the weekly community voices job has paid for between runs, so each week only the new
// lines are made. The job keeps it on a GitHub release (see .github/workflows/community-voices.yml).
//
//   node tools/voice/community-state.mjs save <folder>   (copies the community lines' takes and masters into it)
//
// Only the lines of the week being voiced are kept, so last week's drop out when the week turns.
// Restoring is unpacking the folder over voice-audio/.
import { copyFile, mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import { AUDIO_DIR, collectLines, currentTake, loadConfig, loadTakes, sourceFor } from "./lines.mjs";

const [command, out] = process.argv.slice(2);
if (command !== "save" || !out) throw new Error("Use: node tools/voice/community-state.mjs save <folder>");

const config = await loadConfig();
const takes = await loadTakes();
const lines = (await collectLines(config)).filter((l) => l.spoken && l.community);
const kept = {};
let count = 0;
for (const voice of Object.keys(config.voices)) {
	const source = sourceFor(config, voice);
	for (const line of lines) {
		const take = currentTake(takes, voice, line, source);
		if (!take) continue;
		await mkdir(path.join(out, "masters", voice), { recursive: true });
		await copyFile(path.join(AUDIO_DIR, "masters", voice, take.file), path.join(out, "masters", voice, take.file));
		(kept[voice] ??= {})[line.id] = take;
		count++;
	}
}
await writeFile(path.join(out, "takes.json"), `${JSON.stringify(kept, null, "\t")}\n`);
console.log(`Kept ${count} takes of ${lines.length} community lines.`);
