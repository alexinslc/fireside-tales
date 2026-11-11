// A written post for each week, shown above its stories. Reviewers (people or scripts
// signed in with a service token) write them; nothing public says who did.
import type { Env } from "./index";
import { weekStart } from "../shared/rules.js";

export const POST_LIMITS = { title: 120, intro: 4000, paragraphs: 12, highlights: 10, note: 300 };

export interface Highlight { story_id: string; note: string }
export interface WeekPost { week: string; title: string; intro: string; highlights: Highlight[]; status: "draft" | "published" }

// Plain text only: no markup, no links, nothing the game or a page could mistake for code.
function plain(text: unknown, max: number): string {
	return String(text ?? "")
		.replace(/\r\n?/g, "\n")
		.replace(/<[^>]*>/g, "")
		.replace(/[\u0000-\u0009\u000b-\u001f\u007f<>]/g, "")
		.replace(/[ \t]+/g, " ")
		.replace(/\n{3,}/g, "\n\n")
		.trim()
		.slice(0, max);
}

export function validWeek(week: string): boolean {
	return /^\d{4}-\d{2}-\d{2}$/.test(week) && weekStart(new Date(`${week}T12:00:00Z`)) === week;
}

// Checks a post someone sent. Returns the tidied post, or the problems with it.
export async function checkPost(env: Env, week: string, body: Record<string, unknown>): Promise<{ post?: WeekPost; problems: string[] }> {
	const problems: string[] = [];
	const title = plain(body.title, POST_LIMITS.title + 1).replace(/\n/g, " ");
	const intro = plain(body.intro, POST_LIMITS.intro + 1);
	if (!title) problems.push("Give the post a title.");
	if (title.length > POST_LIMITS.title) problems.push(`Keep the title under ${POST_LIMITS.title} characters.`);
	if (!intro) problems.push("Write an intro.");
	if (intro.length > POST_LIMITS.intro) problems.push(`Keep the intro under ${POST_LIMITS.intro} characters.`);
	if (intro.split(/\n\n/).length > POST_LIMITS.paragraphs) problems.push(`Use at most ${POST_LIMITS.paragraphs} paragraphs.`);
	if (/https?:\/\/|www\./i.test(`${title} ${intro}`)) problems.push("Leave out links.");
	const status = body.status === "published" ? "published" : "draft";

	const raw = Array.isArray(body.highlights) ? body.highlights : [];
	if (raw.length > POST_LIMITS.highlights) problems.push(`Highlight at most ${POST_LIMITS.highlights} stories.`);
	const highlights: Highlight[] = [];
	for (const item of raw.slice(0, POST_LIMITS.highlights)) {
		const entry = item as Record<string, unknown>;
		const id = String(entry.story_id ?? "");
		const row = await env.DB.prepare("SELECT title FROM submissions WHERE id = ? AND status = 'approved' AND week = ?").bind(id, week).first();
		if (!row) { problems.push(`Story ${id || "(no id)"} isn't approved for this week.`); continue; }
		if (highlights.some((h) => h.story_id === id)) continue;
		highlights.push({ story_id: id, note: plain(entry.note, POST_LIMITS.note).replace(/\n/g, " ") });
	}
	return problems.length ? { problems } : { post: { week, title, intro, highlights, status }, problems };
}

export async function savePost(env: Env, post: WeekPost, who: string): Promise<void> {
	await env.DB.prepare(
		`INSERT INTO week_posts (week, title, intro, highlights_json, status, updated_at, updated_by) VALUES (?, ?, ?, ?, ?, ?, ?)
		 ON CONFLICT(week) DO UPDATE SET title = excluded.title, intro = excluded.intro, highlights_json = excluded.highlights_json,
		 status = excluded.status, updated_at = excluded.updated_at, updated_by = excluded.updated_by`,
	).bind(post.week, post.title, post.intro, JSON.stringify(post.highlights), post.status, Date.now(), who).run();
}

type PostRow = { week: string; title: string; intro: string; highlights_json: string; status: string; updated_at: number; updated_by: string };

function fromRow(row: PostRow) {
	return { week: row.week, title: row.title, intro: row.intro, highlights: JSON.parse(row.highlights_json) as Highlight[], status: row.status };
}

// Everything, for reviewers.
export async function adminPost(env: Env, week: string) {
	const row = await env.DB.prepare("SELECT * FROM week_posts WHERE week = ?").bind(week).first<PostRow>();
	return row ? { ...fromRow(row), updated_at: row.updated_at, updated_by: row.updated_by } : null;
}

// What the public sees: only published posts for weeks that have started, and only
// highlights of stories still approved for that week.
export async function publicPost(env: Env, week: string) {
	if (week > weekStart()) return null;
	const row = await env.DB.prepare("SELECT * FROM week_posts WHERE week = ? AND status = 'published'").bind(week).first<PostRow>();
	if (!row) return null;
	const post = fromRow(row);
	const { results } = await env.DB.prepare("SELECT id FROM submissions WHERE status = 'approved' AND week = ?").bind(week).all<{ id: string }>();
	const live = new Set(results.map((r) => r.id));
	return { title: post.title, intro: post.intro, highlights: post.highlights.filter((h) => live.has(h.story_id)) };
}

// Public posts for many weeks at once, for the archive.
export async function publicPostTitles(env: Env): Promise<Record<string, { title: string; excerpt: string }>> {
	const { results } = await env.DB.prepare(
		"SELECT week, title, intro FROM week_posts WHERE status = 'published' AND week <= ?",
	).bind(weekStart()).all<{ week: string; title: string; intro: string }>();
	return Object.fromEntries(results.map((r) => {
		const first = r.intro.split(/\n\n/)[0];
		return [r.week, { title: r.title, excerpt: first.length > 220 ? `${first.slice(0, 217).replace(/\s+\S*$/, "")}…` : first }];
	}));
}
