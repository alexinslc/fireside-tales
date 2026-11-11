// firesidetales.dev API. Pages are static files in public/; this handles /api/*.
import { findProblems, tidyStory, parseWriting, weekStart, addWeeks, LIMITS, MOODS, RULESETS } from "../shared/rules.js";
import { isAdmin, isLocal } from "./access";
import { GUIDELINES } from "./guidelines";
import { POST_LIMITS, adminPost, checkPost, publicPost, publicPostTitles, savePost, validWeek } from "./posts";
import { validEmail, mailApproved, mailFeatured, mailRejected, mailFeedback } from "./notify";
import { pageFor, renderPage, type PageStory, type PastPost } from "./pages";

export interface Env {
	DB: D1Database;
	ASSETS: Fetcher;
	TURNSTILE_SITE_KEY: string;
	TURNSTILE_SECRET?: string;
	IP_SALT?: string;
	ACCESS_TEAM_DOMAIN: string;
	ACCESS_AUD: string;
	ADMIN_EMAILS?: string; // Secret: reviewers' emails, comma separated.
	SITE_URL: string;
	EMAIL_FROM: string;
	RESEND_API_KEY?: string; // Optional: emails to authors who ask for them.
	RESEND_API_URL?: string; // Only for local tests, to catch emails instead of sending them.
	DEV_ADMIN?: string; // "1" only in .dev.vars, to use the admin page locally.
	FEEDBACK_EMAIL?: string; // Secret: where feedback notes are emailed.
	SCHEDULE_TOKEN?: string; // Secret, shared with the GitHub jobs: reads upcoming weeks, and reports releases.
	REVIEW_TOKENS?: string; // Secret: "name=access-client-id" pairs for scripts that review stories.
	GITHUB_REPO?: string; // owner/name of the addon's repository.
	GITHUB_DISPATCH_TOKEN?: string; // Optional: lets an approval start the job that adds stories to the addon.
}

const DAILY_LIMIT = 10; // Submissions (and feedback notes) per visitor per day.
const AGENT_DAILY_LIMIT = 10; // Per address per day through the agent API, which has no bot check.
const AGENT_DAILY_TOTAL = 200; // All agents together, per day.
const WEEKLY_TARGET = { min: 50, max: 100 }; // Featured stories per week.

type Row = Record<string, unknown>;

function json(data: unknown, status = 200): Response {
	return new Response(JSON.stringify(data), {
		status,
		headers: { "content-type": "application/json; charset=utf-8", "cache-control": "no-store" },
	});
}

function fail(message: string, status = 400, extra: Record<string, unknown> = {}): Response {
	return json({ error: message, ...extra }, status);
}

async function sha256(text: string): Promise<string> {
	const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(text));
	return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

function receiptCode(): string {
	// Easy to read back: no 0/O or 1/I.
	const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
	const bytes = crypto.getRandomValues(new Uint8Array(10));
	const chars = [...bytes].map((b) => alphabet[b % alphabet.length]);
	return `${chars.slice(0, 5).join("")}-${chars.slice(5).join("")}`;
}

// The salt that keeps hashed addresses from being matched to real ones. The live site
// won't run without one.
function ipSalt(request: Request, env: Env): string {
	if (env.IP_SALT) return env.IP_SALT;
	if (isLocal(request)) return "local";
	throw new Error("IP_SALT isn't set");
}

async function verifyTurnstile(request: Request, env: Env, token: unknown, ip: string): Promise<boolean> {
	// Without the secret, only local work skips the check. The live site refuses instead.
	if (!env.TURNSTILE_SECRET) return isLocal(request);
	if (typeof token !== "string" || !token) return false;
	const body = new FormData();
	body.append("secret", env.TURNSTILE_SECRET);
	body.append("response", token);
	if (ip) body.append("remoteip", ip);
	const result = await fetch("https://challenges.cloudflare.com/turnstile/v0/siteverify", { method: "POST", body });
	const data = (await result.json()) as { success?: boolean };
	return data.success === true;
}

// What anyone may see of an approved story.
function publicStory(row: Row) {
	return {
		id: row.id,
		kind: row.kind,
		title: row.title,
		mood: row.mood,
		lines: JSON.parse(String(row.lines_json)),
		author: row.author || "",
		ruleset: row.ruleset || "",
		week: row.week,
	};
}

// Everything the review page needs.
function adminStory(row: Row) {
	return {
		...publicStory(row),
		receipt: row.receipt,
		status: row.status,
		contact: row.contact,
		emails: Boolean(row.notify_email), // The address itself never leaves the database.
		source: row.source,
		created_at: row.created_at,
		review_note: row.review_note,
		original: row.original_json ? JSON.parse(String(row.original_json)) : null,
		reviewed_by: row.reviewed_by || "",
		reviewed_at: row.reviewed_at ?? null,
		shipped_version: row.shipped_version ?? null,
		stage: stageOf(row),
	};
}

// Where a story is on its way to players:
// waiting, rejected, scheduled (approved, not in a release yet), in_addon (released,
// its week hasn't started), featured (its week is now), missed (this week started but
// no release carried it, so players don't have it), or past.
function stageOf(row: Row, current = weekStart()): string {
	if (row.status !== "approved") return row.status === "pending" ? "waiting" : String(row.status);
	const week = String(row.week ?? "");
	if (week < current) return "past";
	if (week === current) return row.shipped_version ? "featured" : "missed";
	return row.shipped_version ? "in_addon" : "scheduled";
}

// The Monday 18:00 UTC release before a week starts.
function releaseFor(week: string): Date {
	return new Date(Date.parse(`${week}T18:00:00Z`) - 86400000);
}

// Everything at a glance, for the review page and review scripts: how many stories are at
// each stage, the coming weeks, the last release, and what needs doing.
async function overview(env: Env): Promise<Response> {
	const current = weekStart();
	const now = Date.now();
	const { results } = await env.DB.prepare(
		`SELECT id, status, week, shipped_version, created_at FROM submissions
		 WHERE status = 'pending' OR (status = 'approved' AND week >= ?) OR (status = 'rejected' AND updated_at > ?)`,
	).bind(current, now - 7 * 86400000).all<Row>();
	const counts: Record<string, number> = { waiting: 0, scheduled: 0, in_addon: 0, featured: 0, missed: 0, rejected_this_week: 0 };
	let oldestWaiting: number | null = null;
	const perWeek: Record<string, { count: number; shipped: number }> = {};
	for (const row of results) {
		const stage = stageOf(row, current);
		if (stage === "rejected") counts.rejected_this_week++;
		else if (stage in counts) counts[stage]++;
		if (stage === "waiting") oldestWaiting = Math.min(oldestWaiting ?? now, Number(row.created_at));
		if (row.status === "approved" && String(row.week) >= current) {
			const w = (perWeek[String(row.week)] ??= { count: 0, shipped: 0 });
			w.count++;
			if (row.shipped_version) w.shipped++;
		}
	}
	const { results: posts } = await env.DB.prepare("SELECT week, status FROM week_posts WHERE week >= ?").bind(current).all<{ week: string; status: string }>();
	const postOf = Object.fromEntries(posts.map((p) => [p.week, p.status]));
	const weeks = Array.from({ length: 12 }, (_, i) => {
		const week = addWeeks(current, i);
		const w = perWeek[week] ?? { count: 0, shipped: 0 };
		return { week, count: w.count, shipped: w.shipped, post: postOf[week] ?? null, release: i === 0 ? null : releaseFor(week).toISOString() };
	});
	const last = await env.DB.prepare("SELECT * FROM releases ORDER BY released_at DESC LIMIT 1").first<{ version: string; released_at: number; stories: number }>();
	const feedback = await env.DB.prepare(
		"SELECT COUNT(*) AS open, SUM(CASE WHEN json_extract(review_json, '$.priority') = 'high' THEN 1 ELSE 0 END) AS high, SUM(CASE WHEN review_json IS NULL THEN 1 ELSE 0 END) AS unsorted FROM feedback WHERE status = 'new'",
	).first<{ open: number; high: number | null; unsorted: number | null }>();

	// What needs doing, most urgent first.
	const next = weeks[1];
	const cutoff = new Date(next.release!);
	const hoursLeft = Math.round((cutoff.getTime() - now) / 3600000);
	const day = (week: string) => new Date(`${week}T12:00:00Z`).toLocaleDateString("en-US", { month: "short", day: "numeric", timeZone: "UTC" });
	const todo: string[] = [];
	if (counts.missed > 0) todo.push(`${counts.missed} approved ${counts.missed === 1 ? "story is" : "stories are"} for a week that started without them in a release. Approve them again into a later week.`);
	if ((feedback?.high ?? 0) > 0) todo.push(`${feedback?.high} high-priority feedback ${feedback?.high === 1 ? "note is" : "notes are"} open.`);
	if (oldestWaiting && now - oldestWaiting > 86400000) todo.push(`${counts.waiting} ${counts.waiting === 1 ? "story is" : "stories are"} waiting, the oldest for ${Math.floor((now - oldestWaiting) / 86400000)} days.`);
	else if (counts.waiting > 0) todo.push(`${counts.waiting} ${counts.waiting === 1 ? "story is" : "stories are"} waiting for review.`);
	if (next.count < WEEKLY_TARGET.min) todo.push(`Next week (${day(next.week)}) has ${next.count} of ${WEEKLY_TARGET.min} stories. The release with it goes out in ${hoursLeft} hours.`);
	if (next.count > 0 && next.post !== "published") todo.push(`Next week (${day(next.week)}) has no published post yet.`);
	if ((feedback?.unsorted ?? 0) > 0) todo.push(`${feedback?.unsorted} feedback ${feedback?.unsorted === 1 ? "note needs" : "notes need"} sorting.`);
	if (last && now - last.released_at > 8 * 86400000) todo.push(`No release has reported in since ${new Date(last.released_at).toUTCString()}. Check the GitHub release job.`);

	return json({
		current_week: current,
		next_release: next.release,
		last_release: last ?? null,
		target: WEEKLY_TARGET,
		counts,
		oldest_waiting_at: oldestWaiting,
		weeks,
		feedback: { open: feedback?.open ?? 0, high: feedback?.high ?? 0, unsorted: feedback?.unsorted ?? 0 },
		todo,
	});
}

// Saves a new submission for review. Shared by the form and the agent API.
async function createSubmission(
	request: Request, env: Env, ctx: ExecutionContext, ip: string, body: Record<string, unknown>,
	source: "web" | "agent", limit: number,
): Promise<Response> {
	// Writers don't pick story or rumor, and may skip the mood; reviewers set both.
	const story = tidyStory({ ...(body as Parameters<typeof tidyStory>[0]), kind: "story" });
	const problems = findProblems(story, { moodOptional: true });
	if (problems.length > 0) return fail("The story needs a few fixes.", 422, { problems });
	const contact = String(body.contact ?? "").trim().slice(0, 120);
	const notifyEmail = String(body.notify_email ?? "").trim().toLowerCase();
	if (notifyEmail && !validEmail(notifyEmail)) return fail("That email address doesn't look right.");

	const ipHash = await sha256(`${ipSalt(request, env)}:${ip}`);
	const since = Date.now() - 24 * 60 * 60 * 1000;
	const recent = await env.DB.prepare("SELECT COUNT(*) AS n FROM submissions WHERE ip_hash = ? AND created_at > ?")
		.bind(ipHash, since).first<{ n: number }>();
	if ((recent?.n ?? 0) >= limit) {
		return fail(`That's ${limit} today. Thank you! Please send more tomorrow.`, 429);
	}
	if (source === "agent") {
		const agents = await env.DB.prepare("SELECT COUNT(*) AS n FROM submissions WHERE source = 'agent' AND created_at > ?")
			.bind(since).first<{ n: number }>();
		if ((agents?.n ?? 0) >= AGENT_DAILY_TOTAL) return fail("We've had a lot of agent submissions today. Please try again tomorrow.", 429);
	}

	const id = crypto.randomUUID();
	const receipt = receiptCode();
	const now = Date.now();
	await env.DB.prepare(
		`INSERT INTO submissions (id, receipt, created_at, updated_at, kind, title, mood, lines_json, author, ruleset, contact, ip_hash, notify_email, source)
		 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
	).bind(id, receipt, now, now, story.kind, story.title, story.mood, JSON.stringify(story.lines),
		story.author, story.ruleset, contact, ipHash, notifyEmail, source).run();

	return json({
		receipt,
		status: "pending",
		status_url: `${env.SITE_URL}/status?code=${receipt}`,
		next: "It's checked against the guidelines before it's featured. Approved stories are featured in the addon's Community tab for one week.",
	}, 201);
}

async function submit(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
	let body: Record<string, unknown>;
	try {
		body = await request.json();
	} catch {
		return fail("That didn't look like a story.");
	}
	if (body.agree !== true) return fail("Please agree to the sharing terms first.");
	const ip = request.headers.get("cf-connecting-ip") ?? "";
	if (!(await verifyTurnstile(request, env, body.turnstileToken, ip))) {
		return fail("Couldn't confirm you're a person. Please try again.", 403);
	}
	return createSubmission(request, env, ctx, ip, body, "web", DAILY_LIMIT);
}

// The agent API: no bot check, so tighter limits. Takes JSON with the story as plain
// text (one line per chat message, actions in *asterisks*), or the game's paste format.
async function agentSubmit(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
	const ip = request.headers.get("cf-connecting-ip") ?? "";
	const type = request.headers.get("content-type") ?? "";
	let body: Record<string, unknown>;
	try {
		body = type.includes("application/json") ? await request.json() : { story: await request.text() };
	} catch {
		return fail("Send JSON like { \"title\": ..., \"story\": ... }. See /api/agent.", 400);
	}
	const text = typeof body.story === "string" ? body.story : typeof body.text === "string" ? body.text : "";
	if (text) {
		const parsed = parseWriting(text);
		body = { ...body, lines: parsed.lines, title: body.title || parsed.title, mood: body.mood || parsed.mood };
	}
	if (!Array.isArray(body.lines) || body.lines.length === 0) {
		return fail("Include the story in \"story\": one line per chat message, actions in *asterisks*. See /api/agent.", 422);
	}
	if (body.mood && !MOODS.includes(String(body.mood).toLowerCase())) body = { ...body, mood: "" };
	return createSubmission(request, env, ctx, ip, body, "agent", AGENT_DAILY_LIMIT);
}

function agentDocs(env: Env): Response {
	return json({
		about: "Contribute a story or rumor to Fireside Tales, a World of Warcraft: Forever addon for telling stories at a campfire in game chat.",
		endpoint: { method: "POST", url: `${env.SITE_URL}/api/agent/submissions`, content_type: "application/json" },
		fields: {
			title: "Required. Up to 60 characters.",
			story: "Required. One line per chat message. Spoken lines are plain text; actions go in *asterisks* and start with a lowercase verb. The game's TITLE:/MOOD:/SAY:/EMOTE: format also works.",
			author: "Optional character name to credit, letters only. Leave out to share anonymously.",
			ruleset: `Optional: ${RULESETS.join(", ")}.`,
			mood: `Optional: ${MOODS.join(", ")}. If left out, it's suggested during review.`,
			notify_email: "Optional. Gets at most two emails: when it's approved and when its week starts. Deleted after.",
		},
		limits: {
			story: `${LIMITS.story.minLines} to ${LIMITS.story.maxLines} lines, under ${LIMITS.story.maxSeconds} seconds to tell`,
			rumor: `${LIMITS.rumor.minLines} or ${LIMITS.rumor.maxLines} lines`,
			line: `Under ${LIMITS.maxBytes} characters, plain ASCII, no |, { or }`,
			per_day: `${AGENT_DAILY_LIMIT} submissions per day from one address`,
		},
		rules: "Suitable for public game chat: nothing sexual beyond PG-13, no hate or harassment, no real people, no graphic gore, no personal information or links, no copied writing, English only. Only share writing the person you're helping wrote or asked you to write and share; it's shared under the addon's MIT license.",
		guidelines: `${env.SITE_URL}/guidelines`,
		example: {
			title: "The Last Honest Merchant",
			story: "Ever met an honest merchant? I did, once. He sold me a mule and told me it was a terrible mule.\n*rolls up one sleeve to show an old scar*\nHe was not joking.",
			author: "Thorg",
			ruleset: "PvP",
		},
		responses: {
			201: "Saved. Returns receipt, status_url, and what happens next.",
			422: "The story needs fixes. Returns problems: [{ line, message }].",
			429: "Daily limit reached.",
		},
	});
}

async function status(env: Env, receipt: string): Promise<Response> {
	const row = await env.DB.prepare("SELECT * FROM submissions WHERE receipt = ?").bind(receipt.toUpperCase()).first<Row>();
	if (!row) return fail("No story has that code.", 404);
	return json({
		title: row.title,
		kind: row.kind,
		status: row.status,
		week: row.status === "approved" ? row.week : null,
		note: row.review_note || "",
		emails: Boolean(row.notify_email),
	});
}

// "Stop these emails": forgets the address straight away.
async function stopEmails(env: Env, receipt: string): Promise<Response> {
	await env.DB.prepare("UPDATE submissions SET notify_email = '' WHERE receipt = ?").bind(receipt.toUpperCase()).run();
	return json({ emails: false });
}

// Each Tuesday: tell authors who asked that their story is featured.
export async function runWeekly(env: Env, week = weekStart()): Promise<{ mailed: number }> {
	const { results } = await env.DB.prepare(
		"SELECT * FROM submissions WHERE status = 'approved' AND week = ? ORDER BY updated_at",
	).bind(week).all<Row>();
	let mailed = 0;
	for (const row of results) {
		if (!row.notify_email || row.featured_mailed) continue;
		if (await mailFeatured(env, String(row.notify_email), row as { title: string })) {
			mailed++;
			await env.DB.prepare("UPDATE submissions SET featured_mailed = 1, notify_email = '' WHERE id = ?").bind(row.id).run();
		}
	}
	// An address is never kept past its story's week.
	await env.DB.prepare(
		"UPDATE submissions SET notify_email = '' WHERE notify_email != '' AND ((status = 'approved' AND week < ?) OR status = 'rejected')",
	).bind(week).run();
	return { mailed };
}

async function featuredStories(env: Env, week: string) {
	const { results } = await env.DB.prepare(
		"SELECT * FROM submissions WHERE status = 'approved' AND week = ? ORDER BY updated_at",
	).bind(week).all<Row>();
	return results.map(publicStory);
}

async function featured(env: Env, week: string): Promise<Response> {
	return json({ week, stories: await featuredStories(env, week), post: await publicPost(env, week) });
}

const FEEDBACK_KINDS = ["idea", "bug", "story", "other"];

// A suggestion, bug report, or anything else, from the Feedback page.
// Emails a feedback note on to the maintainer, once.
async function emailFeedback(env: Env, id: string): Promise<void> {
	const note = await env.DB.prepare("SELECT * FROM feedback WHERE id = ?").bind(id).first<{ id: string; kind: string; message: string; contact: string; emailed: number }>();
	if (!note || note.emailed) return;
	if (await mailFeedback(env, note)) {
		await env.DB.prepare("UPDATE feedback SET emailed = 1 WHERE id = ?").bind(id).run();
	}
}

const FEEDBACK_REVIEW = {
	category: ["bug", "idea", "story_request", "praise", "question", "spam", "other"],
	priority: ["high", "normal", "low"],
};

async function sendFeedback(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
	let body: Record<string, unknown>;
	try {
		body = await request.json();
	} catch {
		return fail("That didn't look like a message.");
	}
	const ip = request.headers.get("cf-connecting-ip") ?? "";
	if (!(await verifyTurnstile(request, env, body.turnstileToken, ip))) {
		return fail("Couldn't confirm you're a person. Please try again.", 403);
	}
	const kind = FEEDBACK_KINDS.includes(String(body.kind)) ? String(body.kind) : "other";
	const message = String(body.message ?? "").trim();
	if (message.length < 3) return fail("Tell us a little more.");
	if (message.length > 2000) return fail("Please keep it under 2000 characters.");
	const contact = String(body.contact ?? "").trim().slice(0, 120);

	const ipHash = await sha256(`${ipSalt(request, env)}:${ip}`);
	const since = Date.now() - 24 * 60 * 60 * 1000;
	const recent = await env.DB.prepare("SELECT COUNT(*) AS n FROM feedback WHERE ip_hash = ? AND created_at > ?")
		.bind(ipHash, since).first<{ n: number }>();
	if ((recent?.n ?? 0) >= DAILY_LIMIT) return fail("Thanks! That's plenty for today.", 429);

	const id = crypto.randomUUID();
	await env.DB.prepare("INSERT INTO feedback (id, created_at, kind, message, contact, ip_hash) VALUES (?, ?, ?, ?, ?, ?)")
		.bind(id, Date.now(), kind, message, contact, ipHash).run();
	ctx.waitUntil(emailFeedback(env, id));
	return json({ ok: true }, 201);
}

async function adminFeedback(env: Env, url: URL): Promise<Response> {
	const wanted = url.searchParams.get("status") === "done" ? "done" : "new";
	const { results } = await env.DB.prepare(
		"SELECT id, created_at, kind, message, contact, status, emailed, review_json, reviewed_by FROM feedback WHERE status = ? ORDER BY created_at DESC LIMIT 200",
	).bind(wanted).all<Row>();
	return json({ feedback: results.map(({ review_json, ...row }) => ({ ...row, emailed: Boolean(row.emailed), review: review_json ? JSON.parse(String(review_json)) : null })) });
}

// Stories from weeks that have ended, newest week first, for the Past weeks page.
// Weeks that have ended, newest first, each a "post" with its counts and a few titles.
async function pastIndex(env: Env) {
	const { results } = await env.DB.prepare(
		`SELECT week, COUNT(*) AS count, SUM(kind = 'rumor') AS rumors, json_group_array(mood) AS moods
		 FROM submissions WHERE status = 'approved' AND week < ? GROUP BY week ORDER BY week DESC LIMIT 520`,
	).bind(weekStart()).all<{ week: string; count: number; rumors: number; moods: string }>();
	const posts = await publicPostTitles(env);
	const weeks = [];
	for (const row of results) {
		const moods: Record<string, number> = {};
		for (const mood of JSON.parse(row.moods) as string[]) moods[mood] = (moods[mood] ?? 0) + 1;
		const { results: firsts } = await env.DB.prepare(
			"SELECT title FROM submissions WHERE status = 'approved' AND week = ? ORDER BY updated_at LIMIT 3",
		).bind(row.week).all<{ title: string }>();
		weeks.push({ week: row.week, count: row.count, rumors: row.rumors, moods, titles: firsts.map((r) => r.title), post: posts[row.week] ?? null });
	}
	return weeks;
}

// One past week's stories, with the weeks before and after it.
async function pastWeek(env: Env, week: string) {
	if (week >= weekStart()) return null;
	const stories = await featuredStories(env, week);
	if (stories.length === 0) return null;
	const older = await env.DB.prepare(
		"SELECT MAX(week) AS week FROM submissions WHERE status = 'approved' AND week < ?",
	).bind(week).first<{ week: string | null }>();
	const newer = await env.DB.prepare(
		"SELECT MIN(week) AS week FROM submissions WHERE status = 'approved' AND week > ? AND week < ?",
	).bind(week, weekStart()).first<{ week: string | null }>();
	return { week, stories, older: older?.week ?? null, newer: newer?.week ?? null, post: await publicPost(env, week) };
}

// Searches every past week: words in the title, the lines, or the author, plus filters.
async function pastSearch(env: Env, url: URL): Promise<Response> {
	const PAGE = 30;
	const page = Math.max(1, Number(url.searchParams.get("page")) || 1);
	const where = ["status = 'approved'", "week < ?"];
	const binds: unknown[] = [weekStart()];
	for (const word of (url.searchParams.get("q") ?? "").toLowerCase().split(/\s+/).filter(Boolean).slice(0, 6)) {
		const like = `%${word.replace(/[\\%_]/g, (c) => `\\${c}`)}%`;
		where.push("(LOWER(title) LIKE ? ESCAPE '\\' OR LOWER(lines_json) LIKE ? ESCAPE '\\' OR LOWER(author) LIKE ? ESCAPE '\\')");
		binds.push(like, like, like);
	}
	const mood = url.searchParams.get("mood");
	if (mood && (MOODS as readonly string[]).includes(mood)) { where.push("mood = ?"); binds.push(mood); }
	const kind = url.searchParams.get("kind");
	if (kind === "story" || kind === "rumor") { where.push("kind = ?"); binds.push(kind); }
	const ruleset = url.searchParams.get("ruleset");
	if (ruleset && (RULESETS as readonly string[]).includes(ruleset)) { where.push("ruleset = ?"); binds.push(ruleset); }
	const clause = where.join(" AND ");
	const total = await env.DB.prepare(`SELECT COUNT(*) AS n FROM submissions WHERE ${clause}`).bind(...binds).first<{ n: number }>();
	const { results } = await env.DB.prepare(
		`SELECT * FROM submissions WHERE ${clause} ORDER BY week DESC, updated_at LIMIT ? OFFSET ?`,
	).bind(...binds, PAGE, (page - 1) * PAGE).all<Row>();
	return json({ total: total?.n ?? 0, page, pages: Math.max(1, Math.ceil((total?.n ?? 0) / PAGE)), stories: results.map(publicStory) });
}

const PAGE_PATHS = new Set(["/", "/past", "/submit", "/guidelines", "/status", "/feedback"]);
const WEEK_PAGE = /^\/past\/(\d{4}-\d{2}-\d{2})$/;

// A public page as real HTML inside the app's shell, for search engines and agents.
async function page(request: Request, env: Env, path: string): Promise<Response> {
	const shell = await env.ASSETS.fetch(new Request(new URL("/", request.url)));
	const week = weekStart();
	const weekPage = path.match(WEEK_PAGE);
	const data = {
		week,
		stories: path === "/" ? (await featuredStories(env, week)) as unknown as PageStory[] : [],
		homePost: path === "/" ? await publicPost(env, week) : null,
		past: path === "/past" ? await pastIndex(env) : [],
		post: weekPage ? (await pastWeek(env, weekPage[1])) as unknown as PastPost | null : null,
	};
	const content = pageFor(env, path, data);
	return content ? renderPage(shell, env, path, content) : shell;
}

async function sitemap(env: Env): Promise<Response> {
	const today = new Date().toISOString().slice(0, 10);
	const urls = [...PAGE_PATHS].filter((p) => p !== "/status").map((p) =>
		`<url><loc>${env.SITE_URL}${p}</loc><lastmod>${p === "/" || p === "/past" ? weekStart() : today}</lastmod><changefreq>${p === "/" ? "weekly" : "monthly"}</changefreq></url>`);
	// Each past week is its own page, and doesn't change once it's over.
	for (const { week } of await pastIndex(env)) {
		urls.push(`<url><loc>${env.SITE_URL}/past/${week}</loc><lastmod>${addWeeks(week, 1)}</lastmod><changefreq>yearly</changefreq></url>`);
	}
	return new Response(`<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">${urls.join("")}</urlset>\n`, {
		headers: { "content-type": "application/xml; charset=utf-8", "cache-control": "public, max-age=3600" },
	});
}

// Compares two secrets in constant time, so the answer's timing gives nothing away.
function sameSecret(a: string, b: string): boolean {
	const x = new TextEncoder().encode(a);
	const y = new TextEncoder().encode(b);
	let diff = x.length ^ y.length;
	for (let i = 0; i < Math.max(x.length, y.length); i++) diff |= (x[i] ?? 0) ^ (y[i] ?? 0);
	return diff === 0;
}

// Whether a request carries the GitHub jobs' token (or comes from this computer, without one).
function fromAddonJob(request: Request, env: Env): boolean {
	const sent = (request.headers.get("authorization") ?? "").replace(/^Bearer\s+/i, "");
	return env.SCHEDULE_TOKEN ? sameSecret(sent, env.SCHEDULE_TOKEN) : isLocal(request);
}

// The release job reports which stories a new addon version carries. It can only mark
// approved stories as shipped, once each (the first version that carried them wins).
async function recordRelease(request: Request, env: Env): Promise<Response> {
	if (!fromAddonJob(request, env)) return fail("Not found.", 404);
	if (!(request.headers.get("content-type") ?? "").startsWith("application/json")) return fail("Send JSON.", 415);
	const body = (await request.json().catch(() => ({}))) as { version?: unknown; story_ids?: unknown };
	const version = String(body.version ?? "");
	if (!/^\d{1,3}\.\d{1,3}\.\d{1,4}$/.test(version)) return fail("version must look like 1.6.2.");
	const ids = Array.isArray(body.story_ids) ? body.story_ids.map(String) : [];
	if (ids.length > 5000 || ids.some((id) => !/^[0-9a-f-]{36}$/.test(id))) return fail("story_ids must be up to 5000 story ids.");
	const now = Date.now();
	let marked = 0;
	for (let i = 0; i < ids.length; i += 50) {
		const chunk = ids.slice(i, i + 50);
		const result = await env.DB.prepare(
			`UPDATE submissions SET shipped_version = ?, shipped_at = ? WHERE status = 'approved' AND shipped_version IS NULL
			 AND id IN (${chunk.map(() => "?").join(",")})`,
		).bind(version, now, ...chunk).run();
		marked += result.meta.changes ?? 0;
	}
	await env.DB.prepare("INSERT OR REPLACE INTO releases (version, released_at, stories) VALUES (?, ?, ?)").bind(version, now, ids.length).run();
	return json({ version, stories: ids.length, newly_shipped: marked });
}

// Every approved story with its week, for the job that builds the addon's file. It
// includes weeks that haven't started, so only the job (with SCHEDULE_TOKEN) may read it.
async function schedule(request: Request, env: Env): Promise<Response> {
	if (!fromAddonJob(request, env)) return fail("Not found.", 404);
	const { results } = await env.DB.prepare(
		"SELECT * FROM submissions WHERE status = 'approved' AND week IS NOT NULL ORDER BY week, updated_at",
	).all<Row>();
	return json({ generated_at: new Date().toISOString(), stories: results.map(publicStory) });
}

async function adminList(env: Env, url: URL): Promise<Response> {
	const wanted = url.searchParams.get("status") ?? "pending";
	const onlyWeek = url.searchParams.get("week");
	const query = onlyWeek
		? env.DB.prepare("SELECT * FROM submissions WHERE status = 'approved' AND week = ? ORDER BY updated_at LIMIT 200").bind(onlyWeek)
		: wanted === "all"
		? env.DB.prepare("SELECT * FROM submissions ORDER BY created_at DESC LIMIT 200")
		: env.DB.prepare("SELECT * FROM submissions WHERE status = ? ORDER BY created_at LIMIT 200").bind(wanted);
	const { results } = await query.all<Row>();
	return json({ submissions: results.map(adminStory) });
}

async function adminWeeks(env: Env, url: URL): Promise<Response> {
	// ?past=N also lists the N weeks before this one, for writing their posts.
	const past = Math.min(52, Math.max(0, Number(url.searchParams.get("past")) || 0));
	const first = addWeeks(weekStart(), -past);
	const weeks = Array.from({ length: 12 + past }, (_, i) => addWeeks(first, i));
	const { results } = await env.DB.prepare(
		"SELECT week, COUNT(*) AS n FROM submissions WHERE status = 'approved' AND week >= ? GROUP BY week",
	).bind(first).all<{ week: string; n: number }>();
	const counts = Object.fromEntries(results.map((r) => [r.week, r.n]));
	const { results: posts } = await env.DB.prepare("SELECT week, status FROM week_posts WHERE week >= ?").bind(first).all<{ week: string; status: string }>();
	const postStatus = Object.fromEntries(posts.map((p) => [p.week, p.status]));
	return json({ target: WEEKLY_TARGET, weeks: weeks.map((week) => ({ week, count: counts[week] ?? 0, post: postStatus[week] ?? null })) });
}

// How to review through the API, for scripts and tools signed in with a service token.
function reviewGuide(env: Env) {
	const base = `${env.SITE_URL}/api/admin`;
	return {
		about: "Review stories and rumors people sent to Fireside Tales. Every request needs the CF-Access-Client-Id and CF-Access-Client-Secret headers of an allowed Cloudflare Access service token.",
		start: `GET ${base}/overview first, every run. Its "todo" list says what needs doing, most urgent first. "counts" and each submission's "stage" say where stories are: waiting, scheduled (approved, not in a release yet), in_addon (released, its week hasn't started), featured (this week), missed (this week started but no release carried it: approve it again into a later week), or past.`,
		steps: [
			`GET ${base}/submissions?status=pending lists stories waiting for review, oldest first (?week=YYYY-MM-DD lists one week's approved stories instead). Each has its lines, mood (empty if the writer didn't pick one), kind, credit, and source ("web" or "agent").`,
			`GET ${base}/weeks shows how many stories each of the next 12 weeks has, and whether it has a post (?past=8 adds the 8 weeks before). Aim for ${WEEKLY_TARGET.min} to ${WEEKLY_TARGET.max} a week.`,
			`POST ${base}/submissions/{id} with {"action":"approve"} schedules it for the first week from next week that has room (from Monday 17:00 UTC, the week after), or add "week":"YYYY-MM-DD" (a Tuesday) to pick one.`,
			`POST ${base}/submissions/{id} with {"action":"reject","note":"..."} turns it away. The note is required and is shown to the author, so make it kind and specific about what to change.`,
			`Any action can include "story": {"kind","title","mood","lines":[{"kind":"say"|"emote","text"}]} to fix a typo or trim a line first. It's checked with the same rules as a new story, and the original is kept. {"action":"update"} saves an edit without deciding.`,
			`Writers don't choose story or rumor, and may skip the mood, so set them as you approve: add "mood" (${MOODS.join(", ")}) and "kind" ("story", or "rumor" for 3 or 4 lines of hearsay with a twist). A story needs a mood to be approved.`,
			`{"action":"pending"} undoes a decision.`,
		],
		rules: { limits: LIMITS, moods: MOODS, rulesets: RULESETS },
		guidelines: GUIDELINES,
		decide: [
			"Approve stories that follow every guideline, read well out loud, and fit the mood. Small fixes are fine to make yourself.",
			"Reject anything that breaks a content rule, copies someone else's writing, or needs more than small fixes, with a note on what would make it work.",
			"When unsure, leave it pending for a person to decide.",
		],
		feedback: [
			`GET ${base}/feedback?status=new lists feedback notes, newest first (status=done for finished ones). Each has the visitor's kind and message, their contact if they gave one, and "review": notes a reviewer saved, if any.`,
			`POST ${base}/feedback/{id} with {"review":{"category":"bug"|"idea"|"story_request"|"praise"|"question"|"spam"|"other","priority":"high"|"normal"|"low","summary":"one sentence","notes":"anything worth knowing: steps to reproduce, a suggested reply"}} saves your review of it. Add "status":"done" to mark it handled (spam can go straight to done), or "status":"new" to reopen it.`,
			"Every note is emailed to the maintainer when it arrives, so don't contact the sender; the maintainer replies by email. Priority high is for something broken for players, or a safety or privacy problem.",
		],
		posts: [
			`GET ${base}/weeks/{week}/post reads a week's post, if it has one. Every week can have one post, shown above its stories on the site (the home page for this week, /past/{week} after).`,
			`PUT ${base}/weeks/{week}/post with {"title","intro","highlights":[{"story_id","note"}],"status":"draft"|"published"} writes or replaces it. A published post goes public when its week starts, so posts can be written ahead.`,
			`Plain text only, no links. Title under ${POST_LIMITS.title} characters; intro under ${POST_LIMITS.intro}, with blank lines between paragraphs (at most ${POST_LIMITS.paragraphs}). Up to ${POST_LIMITS.highlights} highlights, each a story approved for that week and a note under ${POST_LIMITS.note} characters on why it stands out.`,
			"Write it like a short column by the fire: warm, specific about the stories, crediting authors by name when they gave one. Don't say who wrote the post or how stories were chosen.",
			`DELETE ${base}/weeks/{week}/post removes it.`,
		],
		after: "Approved stories are added to the addon's Community.lua by a GitHub job, which runs within minutes of an approval (or daily) and releases a new version before each week starts.",
	};
}

// The first week from next week on that still has room. Not this week: stories reach
// players with addon releases, which go out Monday at 18:00 UTC before each week starts.
// From Monday 17:00 UTC on, next week's release is about to go, so it starts a week later.
async function nextOpenWeek(env: Env): Promise<string> {
	const now = new Date();
	const lastCall = now.getUTCDay() === 1 && now.getUTCHours() >= 17;
	const first = addWeeks(weekStart(), lastCall ? 2 : 1);
	const { results } = await env.DB.prepare(
		"SELECT week, COUNT(*) AS n FROM submissions WHERE status = 'approved' AND week >= ? GROUP BY week",
	).bind(first).all<{ week: string; n: number }>();
	const counts = Object.fromEntries(results.map((r) => [r.week, r.n]));
	for (let i = 0; ; i++) {
		const week = addWeeks(first, i);
		if ((counts[week] ?? 0) < WEEKLY_TARGET.max) return week;
	}
}

// Starts the GitHub job that writes approved stories into the addon. Without the token,
// the job still runs on its own once a day.
async function startAddonUpdate(env: Env): Promise<void> {
	if (!env.GITHUB_DISPATCH_TOKEN || !env.GITHUB_REPO) return;
	const response = await fetch(`https://api.github.com/repos/${env.GITHUB_REPO}/dispatches`, {
		method: "POST",
		headers: {
			authorization: `Bearer ${env.GITHUB_DISPATCH_TOKEN}`,
			accept: "application/vnd.github+json",
			"user-agent": "fireside-tales-site",
		},
		body: JSON.stringify({ event_type: "community-stories" }),
	});
	if (!response.ok) console.error("addon update dispatch failed", response.status, await response.text());
}

async function adminAct(request: Request, env: Env, ctx: ExecutionContext, id: string, who: string): Promise<Response> {
	const row = await env.DB.prepare("SELECT * FROM submissions WHERE id = ?").bind(id).first<Row>();
	if (!row) return fail("No such submission.", 404);
	const body = (await request.json()) as Record<string, unknown>;
	const now = Date.now();
	const note = String(body.note ?? "").slice(0, 500);

	// An edited version replaces the story, keeping what was first sent.
	// "mood" and "kind" on their own change just those, for a quick approval.
	let edited: ReturnType<typeof tidyStory> | null = null;
	const current = { kind: row.kind, title: row.title, mood: row.mood, lines: JSON.parse(String(row.lines_json)) };
	const quick = !body.story && (body.mood !== undefined || body.kind !== undefined)
		? { ...current, ...(body.mood !== undefined ? { mood: body.mood } : {}), ...(body.kind !== undefined ? { kind: body.kind } : {}) }
		: null;
	if (body.story || quick) {
		edited = tidyStory({ ...((body.story ?? quick) as object), author: row.author, ruleset: row.ruleset } as Parameters<typeof tidyStory>[0]);
		const problems = findProblems(edited);
		if (problems.length > 0) return fail("The edit breaks the rules.", 422, { problems });
	}
	const save = async (status: string, week: string | null) => {
		const decided = status !== row.status || week !== (row.week ?? null);
		const original = edited && !row.original_json
			? JSON.stringify({ kind: row.kind, title: row.title, mood: row.mood, lines: JSON.parse(String(row.lines_json)) })
			: row.original_json ?? null;
		await env.DB.prepare(
			`UPDATE submissions SET status = ?, week = ?, review_note = ?, kind = ?, title = ?, mood = ?, lines_json = ?,
			 original_json = ?, updated_at = ?, reviewed_by = ?, reviewed_at = ?,
			 shipped_version = CASE WHEN ? THEN NULL ELSE shipped_version END, shipped_at = CASE WHEN ? THEN NULL ELSE shipped_at END
			 WHERE id = ?`,
		).bind(status, week, note || String(row.review_note ?? ""), edited?.kind ?? row.kind, edited?.title ?? row.title,
			edited?.mood ?? row.mood, edited ? JSON.stringify(edited.lines) : row.lines_json, original, now,
			decided || edited ? who : String(row.reviewed_by ?? ""), decided || edited ? now : (row.reviewed_at ?? null),
			// A new week, or a change to the words, needs a new release to reach players.
			decided || edited ? 1 : 0, decided || edited ? 1 : 0, id).run();
		// Anything that changes what's scheduled changes the addon's file.
		if (status === "approved" || row.status === "approved") ctx.waitUntil(startAddonUpdate(env));
	};

	switch (body.action) {
		case "approve": {
			// The addon needs a mood for every story, and leaves out any without one.
			if (!(edited?.mood ?? row.mood)) return fail("Pick a mood before approving.");
			const week = body.week === undefined || body.week === "next" ? await nextOpenWeek(env) : String(body.week);
			if (!/^\d{4}-\d{2}-\d{2}$/.test(week) || weekStart(new Date(`${week}T12:00:00Z`)) !== week) {
				return fail("Pick a week (a Tuesday).");
			}
			await save("approved", week);
			// One email when it's approved; it counts as the "featured" email too if that's this week.
			if (row.notify_email && !row.approved_mailed) {
				const featuredNow = week === weekStart();
				ctx.waitUntil((async () => {
					const story = { ...(row as Row), title: edited?.title ?? row.title } as { title: string };
					if (!(await mailApproved(env, String(row.notify_email), story, week, featuredNow))) return;
					await env.DB.prepare(
						`UPDATE submissions SET approved_mailed = 1,
						 featured_mailed = CASE WHEN ? THEN 1 ELSE featured_mailed END,
						 notify_email = CASE WHEN ? THEN '' ELSE notify_email END WHERE id = ?`,
					).bind(featuredNow ? 1 : 0, featuredNow ? 1 : 0, id).run();
				})());
			}
			break;
		}
		case "reject":
			if (!note && !row.review_note) return fail("Add a note for the author saying why.");
			await save("rejected", null);
			if (row.notify_email) {
				ctx.waitUntil((async () => {
					await mailRejected(env, String(row.notify_email), row as { title: string }, note || String(row.review_note ?? ""));
					await env.DB.prepare("UPDATE submissions SET notify_email = '' WHERE id = ?").bind(id).run();
				})());
			}
			break;
		case "pending":
			await save("pending", null);
			break;
		case "update":
			await save(String(row.status), (row.week as string | null) ?? null);
			break;
		default:
			return fail("Unknown action. Use approve, reject, pending, or update.");
	}
	const fresh = await env.DB.prepare("SELECT * FROM submissions WHERE id = ?").bind(id).first<Row>();
	return json({ submission: adminStory(fresh as Row) });
}

// Changes to reviewer data must come from the review page itself or from a script, never
// from another site riding on a signed-in browser: they must be JSON, and a browser's
// Origin, when sent, must be this site's.
function trustedWrite(request: Request): boolean {
	if (request.method === "GET" || request.method === "HEAD") return true;
	if (!(request.headers.get("content-type") ?? "").toLowerCase().startsWith("application/json")) return false;
	const origin = request.headers.get("origin");
	if (origin && origin !== new URL(request.url).origin) return false;
	return request.headers.get("sec-fetch-site") !== "cross-site";
}

// Headers that keep browsers strict: no framing (so the review page can't be hidden inside
// another site), no guessing file types, and only this site's own scripts plus the bot check.
const CONTENT_SECURITY = [
	"default-src 'self'",
	"script-src 'self' https://challenges.cloudflare.com",
	"frame-src https://challenges.cloudflare.com",
	"style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
	"font-src 'self' https://fonts.gstatic.com",
	"img-src 'self' data:",
	"connect-src 'self'",
	"object-src 'none'",
	"base-uri 'self'",
	"form-action 'self'",
	"frame-ancestors 'none'",
].join("; ");

function secure(request: Request, response: Response): Response {
	const headers = new Headers(response.headers);
	headers.set("x-content-type-options", "nosniff");
	headers.set("x-frame-options", "DENY");
	headers.set("referrer-policy", "strict-origin-when-cross-origin");
	headers.set("permissions-policy", "camera=(), microphone=(), geolocation=(), payment=()");
	// The dev server injects its own scripts, so the strictest rules apply only live.
	if (!isLocal(request)) {
		headers.set("strict-transport-security", "max-age=31536000; includeSubDomains");
		if ((headers.get("content-type") ?? "").includes("text/html")) headers.set("content-security-policy", CONTENT_SECURITY);
	}
	if (new URL(request.url).pathname.startsWith("/api/admin")) headers.set("cache-control", "no-store");
	return new Response(response.body, { status: response.status, statusText: response.statusText, headers });
}

export default {
	async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
		return secure(request, await route(request, env, ctx));
	},
	async scheduled(controller: ScheduledController, env: Env, ctx: ExecutionContext): Promise<void> {
		await scheduledRun(controller, env, ctx);
	},
} satisfies ExportedHandler<Env>;

async function route(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
	{
		const url = new URL(request.url);
		const path = url.pathname;
		try {
			if (request.method === "GET" && (PAGE_PATHS.has(path) || WEEK_PAGE.test(path))) return page(request, env, path);
			if (request.method === "GET" && path === "/sitemap.xml") return await sitemap(env);
			if (path === "/api/config" && request.method === "GET") {
				return json({ turnstileSiteKey: env.TURNSTILE_SITE_KEY, rulesets: RULESETS, week: weekStart() });
			}
			if (path === "/api/submissions" && request.method === "POST") return submit(request, env, ctx);
			if (path === "/api/agent" && request.method === "GET") return agentDocs(env);
			if (path === "/api/agent/submissions" && request.method === "POST") return agentSubmit(request, env, ctx);
			const statusMatch = path.match(/^\/api\/status\/([A-Za-z0-9-]{11})$/);
			if (statusMatch && request.method === "GET") return status(env, statusMatch[1]);
			const stopMatch = path.match(/^\/api\/status\/([A-Za-z0-9-]{11})\/stop$/);
			if (stopMatch && request.method === "POST") return stopEmails(env, stopMatch[1]);
			if (path === "/api/featured" && request.method === "GET") {
				// This week or an earlier one only: later weeks stay a surprise until they start.
				const week = url.searchParams.get("week") ?? weekStart();
				if (!validWeek(week) || week > weekStart()) return fail("That week hasn't started yet.", 404);
				return featured(env, week);
			}
			if (path === "/api/release" && request.method === "POST") return recordRelease(request, env);
			if (path === "/api/schedule" && request.method === "GET") return schedule(request, env);
			if (path === "/api/past" && request.method === "GET") return json({ weeks: await pastIndex(env) });
			if (path === "/api/past/search" && request.method === "GET") return pastSearch(env, url);
			const pastMatch = path.match(/^\/api\/past\/(\d{4}-\d{2}-\d{2})$/);
			if (pastMatch && request.method === "GET") {
				const post = await pastWeek(env, pastMatch[1]);
				return post ? json(post) : fail("No such week.", 404);
			}
			if (path === "/api/feedback" && request.method === "POST") return sendFeedback(request, env, ctx);

			if (path === "/api/admin" || path.startsWith("/api/admin/")) {
				const who = await isAdmin(request, env);
				if (!who) return fail("Reviewers only.", 403);
				if (!trustedWrite(request)) return fail("Send changes as JSON from the review page or a script.", 403);
				if (path === "/api/admin/submissions" && request.method === "GET") return adminList(env, url);
				if (path === "/api/admin/weeks" && request.method === "GET") return adminWeeks(env, url);
				if (path === "/api/admin/feedback" && request.method === "GET") return adminFeedback(env, url);
				const note = path.match(/^\/api\/admin\/feedback\/([0-9a-f-]{36})$/);
				if (note && request.method === "POST") {
					const body = (await request.json()) as { status?: string; review?: Record<string, unknown> };
					// A reviewer's notes on it: what it is, how urgent, and anything worth knowing.
					if (body.review) {
						const r = body.review;
						const category = String(r.category ?? "");
						const priority = String(r.priority ?? "");
						if (!FEEDBACK_REVIEW.category.includes(category)) return fail(`category must be one of ${FEEDBACK_REVIEW.category.join(", ")}.`, 422);
						if (!FEEDBACK_REVIEW.priority.includes(priority)) return fail(`priority must be one of ${FEEDBACK_REVIEW.priority.join(", ")}.`, 422);
						const review = { category, priority, summary: String(r.summary ?? "").slice(0, 300), notes: String(r.notes ?? "").slice(0, 2000) };
						await env.DB.prepare("UPDATE feedback SET review_json = ?, reviewed_by = ? WHERE id = ?").bind(JSON.stringify(review), who, note[1]).run();
					}
					if (body.status) {
						await env.DB.prepare("UPDATE feedback SET status = ? WHERE id = ?").bind(body.status === "done" ? "done" : "new", note[1]).run();
					}
					return json({ ok: true });
				}
				const act = path.match(/^\/api\/admin\/submissions\/([0-9a-f-]{36})$/);
				if (act && request.method === "POST") return adminAct(request, env, ctx, act[1], who);
				const one = path.match(/^\/api\/admin\/submissions\/([0-9a-f-]{36})$/);
				if (one && request.method === "GET") {
					const row = await env.DB.prepare("SELECT * FROM submissions WHERE id = ?").bind(one[1]).first<Row>();
					return row ? json({ submission: adminStory(row) }) : fail("No such submission.", 404);
				}
				if (path === "/api/admin/me" && request.method === "GET") return json({ email: who });
				if (path === "/api/admin/overview" && request.method === "GET") return overview(env);
				const postPath = path.match(/^\/api\/admin\/weeks\/(\d{4}-\d{2}-\d{2})\/post$/);
				if (postPath) {
					const week = postPath[1];
					if (!validWeek(week)) return fail("Pick a week (a Tuesday).");
					if (request.method === "GET") {
						const post = await adminPost(env, week);
						return post ? json({ post }) : fail("This week has no post yet.", 404);
					}
					if (request.method === "PUT") {
						const checked = await checkPost(env, week, (await request.json()) as Record<string, unknown>);
						if (!checked.post) return fail("The post needs a few fixes.", 422, { problems: checked.problems });
						await savePost(env, checked.post, who);
						return json({ post: await adminPost(env, week) });
					}
					if (request.method === "DELETE") {
						await env.DB.prepare("DELETE FROM week_posts WHERE week = ?").bind(week).run();
						return json({ ok: true });
					}
				}
				if (path === "/api/admin" && request.method === "GET") return json(reviewGuide(env));
				// The same job the Tuesday schedule runs, for sending a week's notices by hand.
				if (path === "/api/admin/weekly-run" && request.method === "POST") {
					const week = url.searchParams.get("week") ?? weekStart();
					if (weekStart(new Date(`${week}T12:00:00Z`)) !== week) return fail("Pick a week (a Tuesday).");
					return json(await runWeekly(env, week));
				}
			}
			return fail("Not found.", 404);
		} catch (error) {
			console.error(error);
			return fail("Something went wrong on our side.", 500);
		}
	}
}

async function scheduledRun(_controller: ScheduledController, env: Env, ctx: ExecutionContext): Promise<void> {
	ctx.waitUntil(runWeekly(env).then((result) => console.log("weekly run", result)));
}
