// Letting people know: optional emails to authors, and feedback to the maintainer.
// Both are off until their secrets are set, so local work never sends anything.
import type { Env } from "./index";

interface Story { title: string; author?: unknown; ruleset?: unknown; kind?: unknown; receipt?: unknown }

function credit(story: Story): string {
	const author = String(story.author ?? "");
	const ruleset = String(story.ruleset ?? "");
	if (author && ruleset) return `by ${author}, ${ruleset}`;
	if (author) return `by ${author}`;
	return "shared anonymously";
}

function weekName(week: string): string {
	return new Date(`${week}T12:00:00Z`).toLocaleDateString("en-US", { month: "long", day: "numeric", timeZone: "UTC" });
}

export function validEmail(text: string): boolean {
	return text.length <= 254 && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(text);
}

function escapeHtml(text: string): string {
	return text.replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c] as string);
}

// Sends one email through Resend. Returns whether it went. Emails to authors carry a
// stop link; notes to the maintainer can be replied to straight to the sender.
async function sendEmail(env: Env, to: string, subject: string, paragraphs: string[], stopUrl: string | null, replyTo?: string): Promise<boolean> {
	if (!env.RESEND_API_KEY) {
		console.log("email skipped (no RESEND_API_KEY):", subject);
		return false;
	}
	const footer = stopUrl ? `You asked us to tell you about this story. Stop these emails: ${stopUrl}` : "";
	const text = [...paragraphs, "Fireside Tales", footer].filter(Boolean).join("\n\n");
	const html = `<div style="font-family:Georgia,serif;font-size:16px;line-height:1.5;color:#2a1f16">${
		paragraphs.map((p) => `<p style="white-space:pre-line">${escapeHtml(p)}</p>`).join("")
	}<p>Fireside Tales</p>${stopUrl ? `<p style="font-size:13px;color:#7a6a55">You asked us to tell you about this story. <a href="${escapeHtml(stopUrl)}">Stop these emails</a>.</p>` : ""}</div>`;
	const response = await fetch(env.RESEND_API_URL || "https://api.resend.com/emails", {
		method: "POST",
		headers: { authorization: `Bearer ${env.RESEND_API_KEY}`, "content-type": "application/json" },
		body: JSON.stringify({ from: env.EMAIL_FROM, to: [to], subject, text, html, ...(replyTo ? { reply_to: replyTo } : {}) }),
	});
	if (!response.ok) console.error("email failed", response.status, await response.text());
	return response.ok;
}

function statusUrl(env: Env, story: Story, stop = false): string {
	return `${env.SITE_URL}/status?code=${encodeURIComponent(String(story.receipt ?? ""))}${stop ? "&stop=1" : ""}`;
}

export function mailApproved(env: Env, to: string, story: Story, week: string, featuredNow: boolean) {
	const paragraphs = featuredNow
		? [`Good news: "${story.title}" is featured at the fire this week, ${credit(story)}.`,
			"Players will find it in the Community tab of the Fireside Tales addon once they update, and on the home page now.",
			`See it here: ${env.SITE_URL}`]
		: [`Good news: "${story.title}" has been approved, ${credit(story)}.`,
			`It will be featured the week of ${weekName(week)}. We'll send one more note when that week starts.`,
			`Check on it any time: ${statusUrl(env, story)}`];
	const subject = featuredNow ? `"${story.title}" is at the fire this week` : `"${story.title}" was approved`;
	return sendEmail(env, to, subject, paragraphs, statusUrl(env, story, true));
}

export function mailFeatured(env: Env, to: string, story: Story) {
	return sendEmail(env, to, `"${story.title}" is at the fire this week`, [
		`"${story.title}" is featured at the fire this week, ${credit(story)}.`,
		"Players will find it in the Community tab of the Fireside Tales addon, and on the home page.",
		`See this week's stories: ${env.SITE_URL}`,
	], statusUrl(env, story, true));
}

export function mailRejected(env: Env, to: string, story: Story, note: string) {
	return sendEmail(env, to, `About "${story.title}"`, [
		`Thank you for sharing "${story.title}". We weren't able to use it this time.`,
		...(note ? [`A note from us: ${note}`] : []),
		`You're welcome to change it and send it again: ${env.SITE_URL}/submit`,
	], statusUrl(env, story, true));
}

const FEEDBACK_KIND_NAMES: Record<string, string> = { idea: "Idea", bug: "Bug", story: "Story request", other: "Other" };

// One feedback note, as sent, to the maintainer's inbox. A reply goes to the sender
// when they left an email address.
export function mailFeedback(env: Env, note: { id: string; kind: string; message: string; contact: string }) {
	if (!env.FEEDBACK_EMAIL) {
		console.log("feedback email skipped (no FEEDBACK_EMAIL)");
		return Promise.resolve(false);
	}
	const kind = FEEDBACK_KIND_NAMES[note.kind] ?? note.kind;
	const subject = `Fireside feedback (${kind}): ${note.message.replace(/\s+/g, " ").slice(0, 80)}`;
	const replyTo = validEmail(note.contact) ? note.contact : undefined;
	return sendEmail(env, env.FEEDBACK_EMAIL, subject, [
		`${kind}. ${note.contact ? `Contact: ${note.contact}${replyTo ? " (reply to this email to answer them)" : ""}.` : "No contact given."}`,
		note.message,
		`All feedback, with any review notes: ${env.SITE_URL}/admin`,
	], null, replyTo);
}
