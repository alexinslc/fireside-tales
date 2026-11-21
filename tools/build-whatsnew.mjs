// Writes addon/FiresideTales/WhatsNew.lua, the list the What's New window shows, from the
// CHANGELOG.md section for the version in FiresideTales.toc. Run it after writing a release's
// changelog; the weekly stories release runs it too.
//
//   node tools/build-whatsnew.mjs           (writes WhatsNew.lua)
//   node tools/build-whatsnew.mjs --check   (fails if WhatsNew.lua doesn't match, for the release job)
import { readFile, writeFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";

const root = (path) => fileURLToPath(new URL(`../${path}`, import.meta.url));
const OUTPUT = root("addon/FiresideTales/WhatsNew.lua");

// A weekly stories release lists the week and its authors. In game, one short line says it.
const COMMUNITY = /^New Community stories for the week/;
const COMMUNITY_LINE = "New community stories are now available.";

const toc = await readFile(root("addon/FiresideTales/FiresideTales.toc"), "utf8");
const version = toc.match(/^## Version:\s*(\S+)/m)?.[1];
if (!version) throw new Error("FiresideTales.toc has no ## Version.");

const changelog = (await readFile(root("CHANGELOG.md"), "utf8")).replace(/\r/g, "");
const start = changelog.search(new RegExp(`^## ${version.replace(/\./g, "\\.")}\\s*$`, "m"));
if (start === -1) throw new Error(`CHANGELOG.md has no "## ${version}" section.`);
const rest = changelog.slice(start).split("\n").slice(1);
const end = rest.findIndex((line) => line.startsWith("## "));
const items = [];
for (const line of end === -1 ? rest : rest.slice(0, end)) {
	const item = line.match(/^- (.+)$/)?.[1]?.trim();
	if (!item) continue;
	// Markdown the game can't show: bold, code and links become plain text.
	const plain = item.replace(/\*\*(.+?)\*\*/g, "$1").replace(/`(.+?)`/g, "$1").replace(/\[(.+?)\]\(.+?\)/g, "$1");
	const shown = COMMUNITY.test(plain) ? COMMUNITY_LINE : plain;
	if (!items.includes(shown)) items.push(shown);
}
if (items.length === 0) throw new Error(`CHANGELOG.md's "## ${version}" section has no "- " items.`);

const lua = (text) => `"${text.replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\|/g, "||")}"`;
const file = [
	"-- What's new in this version, for the What's New window. Written by tools/build-whatsnew.mjs",
	"-- from CHANGELOG.md, so edit the changelog, not this.",
	"local _, ns = ...",
	"",
	"ns.WhatsNew = {",
	`\tversion = ${lua(version)},`,
	"\titems = {",
	...items.map((item) => `\t\t${lua(item)},`),
	"\t},",
	"}",
	"",
].join("\n");

let before = "";
try { before = await readFile(OUTPUT, "utf8"); } catch {}
if (process.argv.includes("--check")) {
	if (before !== file) {
		console.error(`WhatsNew.lua doesn't match CHANGELOG.md for ${version}. Run node tools/build-whatsnew.mjs and commit it.`);
		process.exit(1);
	}
	console.log(`WhatsNew.lua matches CHANGELOG.md for ${version}.`);
} else {
	if (before !== file) await writeFile(OUTPUT, file);
	console.log(`${before === file ? "No change" : "Wrote WhatsNew.lua"}: ${items.length} item${items.length === 1 ? "" : "s"} for ${version}.`);
}
