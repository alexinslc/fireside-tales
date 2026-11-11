// Real HTML for each public page, so search engines and AI agents that don't run
// JavaScript still see the content. The React app replaces it as soon as it loads.
import type { Env } from "./index";

export interface PageStory {
	kind: string;
	title: string;
	mood: string;
	lines: { kind: string; text: string }[];
	author: string;
	ruleset: string;
	week?: unknown;
}

const NAME = "Fireside Tales";
const ADDON_URL = "https://www.curseforge.com/wow/addons/fireside-tales";
const REPO_URL = "https://github.com/alexinslc/fireside-tales";

export function escape(text: unknown): string {
	return String(text ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c] as string);
}

function credit(story: PageStory): string {
	if (story.author && story.ruleset) return `by ${story.author}, ${story.ruleset}`;
	if (story.author) return `by ${story.author}`;
	return "shared anonymously";
}

function weekName(week: string): string {
	return new Date(`${week}T12:00:00Z`).toLocaleDateString("en-US", { month: "long", day: "numeric", year: "numeric", timeZone: "UTC" });
}

function storyHtml(story: PageStory): string {
	const lines = story.lines.map((line) => line.kind === "emote"
		? `<p><em>${escape(story.author || "The teller")} ${escape(line.text)}</em></p>`
		: `<p>${escape(line.text)}</p>`).join("");
	return `<article><h3>${escape(story.title)}</h3><p>A ${escape(story.mood)} ${escape(story.kind)}, ${escape(credit(story))}.</p>${lines}</article>`;
}

function storyJson(env: Env, story: PageStory) {
	return {
		"@type": "CreativeWork",
		name: story.title,
		genre: story.mood,
		text: story.lines.map((line) => line.text).join(" "),
		...(story.author ? { author: { "@type": "Person", name: story.author } } : {}),
		isPartOf: { "@type": "WebSite", name: NAME, url: env.SITE_URL },
	};
}

const NAV = `<nav><a href="/">This week</a> · <a href="/past">Past weeks</a> · <a href="/submit">Contribute a story</a> · <a href="/guidelines">Guidelines</a> · <a href="/status">Check on yours</a> · <a href="/feedback">Feedback</a></nav>`;

const ABOUT = `<p>${NAME} is a free World of Warcraft: Forever addon for telling stories at a campfire, one line at a time, in /say and /e. Anyone nearby sees the story in chat, without needing the addon. This site collects stories and rumors from players: each week, up to 100 community stories are featured in the addon's Community tab, credited to their authors.</p><p><a href="${ADDON_URL}">Get the addon on CurseForge</a> · <a href="${REPO_URL}">Source on GitHub</a></p>`;

export const FAQ: [string, string][] = [
	["What is Fireside Tales?", "A free World of Warcraft: Forever addon for telling stories at a campfire, one chat line at a time, using /say and /e. Players nearby see the story without needing the addon."],
	["How do I contribute a story?", "Go to firesidetales.dev/submit, give it a title, and write one line per chat message, with actions in *asterisks*. Your character name, ruleset, and email are optional. AI agents can send stories to the API described at firesidetales.dev/llms.txt."],
	["How long can a story be?", "A story is 3 to 8 lines and takes under a minute to tell. A rumor is 3 or 4 lines and about half a minute. Each line must fit in one chat message, under 250 characters."],
	["What happens after I contribute a story?", "It's checked against the guidelines, and we may fix a typo or leave you a note. Approved stories are scheduled for a week and featured in the addon's Community tab, credited to you or shared anonymously."],
	["What isn't allowed?", "Nothing sexual beyond PG-13, no hate or harassment, no stories about real people, no graphic gore, no personal information or links, and no copied writing such as Blizzard's quest text."],
	["Is Fireside Tales made by Blizzard?", "No. It's a free fan addon, not affiliated with or endorsed by Blizzard Entertainment."],
];

interface Page { title: string; description: string; body: string; jsonLd: object[] }

export interface PublicPost { title: string; intro: string; highlights: { story_id: string; note: string }[] }
export interface PastSummary { week: string; count: number; rumors: number; moods: Record<string, number>; titles: string[]; post: { title: string; excerpt: string } | null }
export interface PastPost { week: string; stories: PageStory[]; older: string | null; newer: string | null; post: PublicPost | null }

// A week's written post: its title, paragraphs, and the stories it picks out.
function postHtml(post: PublicPost | null, stories: PageStory[]): string {
	if (!post) return "";
	const byId = new Map(stories.map((s) => [String((s as { id?: unknown }).id), s]));
	const picks = post.highlights.map((h) => {
		const story = byId.get(h.story_id);
		return story ? `<li><strong>${escape(story.title)}</strong> (${escape(credit(story))})${h.note ? `: ${escape(h.note)}` : ""}</li>` : "";
	}).join("");
	return `<section><h2>${escape(post.title)}</h2>${post.intro.split(/\n\n/).map((p) => `<p>${escape(p)}</p>`).join("")}${picks ? `<h3>Highlights</h3><ul>${picks}</ul>` : ""}</section>`;
}

function postJson(post: PublicPost | null, week: string, url: string) {
	return post ? [{ "@type": "BlogPosting", headline: post.title, articleBody: post.intro, datePublished: week, url }] : [];
}

function tales(count: number): string {
	return `${count} ${count === 1 ? "tale" : "tales"}`;
}

export function pageFor(env: Env, path: string, data: { week: string; stories: PageStory[]; past: PastSummary[]; post: PastPost | null; homePost: PublicPost | null }): Page | null {
	const site = { "@type": "WebSite", name: NAME, url: env.SITE_URL, description: "Community stories and rumors for the Fireside Tales World of Warcraft: Forever addon." };
	const addon = {
		"@type": "SoftwareApplication", name: NAME, applicationCategory: "GameApplication", operatingSystem: "Windows, macOS",
		url: ADDON_URL, offers: { "@type": "Offer", price: "0", priceCurrency: "USD" },
		description: "A World of Warcraft: Forever addon for telling stories at the campfire, one line at a time.",
	};
	switch (path) {
		case "/":
			return {
				title: `${NAME} · Stories for the campfire`,
				description: `This week's community stories and rumors for ${NAME}, the World of Warcraft: Forever addon for telling tales at the campfire. Contribute your own.`,
				body: `<h1>Stories for the fire</h1>${ABOUT}<h2>This week at the fire: the week of ${escape(weekName(data.week))}</h2>${postHtml(data.homePost, data.stories)}${
					data.stories.length ? data.stories.map(storyHtml).join("") : "<p>This week is still waiting for its stories.</p>"
				}<h2>How it works</h2><ol><li>Write a story or rumor, one line per chat message.</li><li>It's checked against the guidelines.</li><li>Each week, up to 100 are featured in the addon's Community tab.</li></ol><p><a href="/submit">Contribute a story</a></p>`,
				jsonLd: [site, addon, ...postJson(data.homePost, data.week, `${env.SITE_URL}/`), ...(data.stories.length
					? [{ "@type": "ItemList", name: `This week at the fire: ${weekName(data.week)}`, itemListElement: data.stories.map((s, i) => ({ "@type": "ListItem", position: i + 1, item: storyJson(env, s) })) }]
					: [])],
			};
		case "/past":
			return {
				title: `Past Weeks · ${NAME}`,
				description: `Every week of community stories and rumors featured in ${NAME}, searchable by word, mood, kind, and ruleset.`,
				body: `<h1>Past weeks</h1><p>Every week of stories and rumors featured at the fire.</p>${
					data.past.map((w) => `<article><h2><a href="/past/${w.week}">The week of ${escape(weekName(w.week))}</a></h2>${w.post ? `<h3>${escape(w.post.title)}</h3><p>${escape(w.post.excerpt)}</p>` : ""}<p>${tales(w.count)}, ${w.rumors} of them rumors. Including ${w.titles.map((t) => escape(t)).join(", ")}.</p></article>`).join("") || "<p>No past weeks yet.</p>"
				}`,
				jsonLd: [site, ...(data.past.length ? [{
					"@type": "ItemList", name: "Past weeks",
					itemListElement: data.past.map((w, i) => ({ "@type": "ListItem", position: i + 1, url: `${env.SITE_URL}/past/${w.week}`, name: `The week of ${weekName(w.week)}` })),
				}] : [])],
			};
		case "/submit":
			return {
				title: `Contribute a Story · ${NAME}`,
				description: `Write a story or rumor for ${NAME}: one line per chat message, actions in asterisks. Featured stories are credited to you.`,
				body: `<h1>Contribute a story</h1><p>Give it a title, then write one line for each chat message. Put actions in *asterisks*, and everything else is spoken. You can also paste a story in the game's TITLE, SAY and EMOTE format.</p><ul><li>A story is 3 to 8 lines and under a minute to tell. A rumor is 3 or 4 lines.</li><li>Each line must fit in one chat message, under 250 characters.</li><li>Character name, ruleset, and an email for updates are all optional.</li></ul><p>AI agents: see <a href="/llms.txt">/llms.txt</a> and <a href="/api/agent">/api/agent</a> to submit stories through the API.</p><p>Read the <a href="/guidelines">guidelines</a> first.</p>`,
				jsonLd: [site],
			};
		case "/guidelines":
			return {
				title: `Guidelines · ${NAME}`,
				description: `What makes a good ${NAME} story, what can't be accepted, and what happens after you share.`,
				body: `<h1>Guidelines</h1><p>Everything is said out loud in game chat, where anyone nearby can read it.</p><h2>Questions</h2>${
					FAQ.map(([q, a]) => `<h3>${escape(q)}</h3><p>${escape(a)}</p>`).join("")
				}`,
				jsonLd: [site, { "@type": "FAQPage", mainEntity: FAQ.map(([q, a]) => ({ "@type": "Question", name: q, acceptedAnswer: { "@type": "Answer", text: a } })) }],
			};
		case "/status":
			return {
				title: `Check on Your Story · ${NAME}`,
				description: `Look up a story you shared with ${NAME} by its code.`,
				body: `<h1>Check on your story</h1><p>Enter the code you got when you shared your story to see whether it's waiting, approved, or featured.</p>`,
				jsonLd: [site],
			};
		case "/feedback":
			return {
				title: `Feedback · ${NAME}`,
				description: `Send ideas, bug reports, or story requests for ${NAME}.`,
				body: `<h1>Feedback</h1><p>Ideas for the addon or the site, something that's broken, or a story you wish someone would write.</p>`,
				jsonLd: [site],
			};
		default: {
			const post = data.post;
			if (!post || path !== `/past/${post.week}`) return null;
			const name = `The week of ${weekName(post.week)}`;
			const rumors = post.stories.filter((s) => s.kind === "rumor").length;
			return {
				title: `${post.post ? `${post.post.title}: ${name}` : name} · ${NAME}`,
				description: post.post ? post.post.intro.split(/\n\n/)[0].slice(0, 300) : `${tales(post.stories.length)} told at the fire the ${name.toLowerCase().replace(/^the /, "")}, including ${post.stories.slice(0, 3).map((s) => s.title).join(", ")}.`,
				body: `<h1>${escape(name)}</h1><p>${tales(post.stories.length)} were featured in the addon's Community tab this week, ${rumors} of them rumors.</p>${postHtml(post.post, post.stories)}${
					post.stories.map(storyHtml).join("")
				}<p>${post.older ? `<a href="/past/${post.older}">The week before</a>` : ""}${post.older && post.newer ? " · " : ""}${post.newer ? `<a href="/past/${post.newer}">The week after</a>` : ""}</p>`,
				jsonLd: [site, ...postJson(post.post, post.week, `${env.SITE_URL}/past/${post.week}`), {
					"@type": "CollectionPage", name, url: `${env.SITE_URL}/past/${post.week}`, datePublished: post.week,
					hasPart: post.stories.map((s) => storyJson(env, s)),
				}],
			};
		}
	}
}

// Fills the app's HTML shell with a page's title, link previews, structured data, and text.
export function renderPage(shell: Response, env: Env, path: string, page: Page): Response {
	const url = `${env.SITE_URL}${path === "/" ? "/" : path}`;
	const image = `${env.SITE_URL}/img/og.jpg`;
	const head = [
		`<link rel="canonical" href="${escape(url)}">`,
		`<meta property="og:type" content="website">`,
		`<meta property="og:site_name" content="${NAME}">`,
		`<meta property="og:title" content="${escape(page.title)}">`,
		`<meta property="og:description" content="${escape(page.description)}">`,
		`<meta property="og:url" content="${escape(url)}">`,
		`<meta property="og:image" content="${image}">`,
		`<meta property="og:image:width" content="1200">`,
		`<meta property="og:image:height" content="630">`,
		`<meta name="twitter:card" content="summary_large_image">`,
		`<meta name="twitter:title" content="${escape(page.title)}">`,
		`<meta name="twitter:description" content="${escape(page.description)}">`,
		`<meta name="twitter:image" content="${image}">`,
		`<link rel="alternate" type="text/plain" title="For AI assistants" href="/llms.txt">`,
		`<script type="application/ld+json">${JSON.stringify({ "@context": "https://schema.org", "@graph": page.jsonLd }).replace(/</g, "\\u003c")}</script>`,
	].join("");
	const body = `<div class="prerender">${NAV}<main>${page.body}</main><footer><p>${NAME} is a free fan addon for World of Warcraft: Forever. It isn't affiliated with or endorsed by Blizzard Entertainment.</p></footer></div>`;
	const rewritten = new HTMLRewriter()
		.on("title", { element(el) { el.setInnerContent(page.title); } })
		.on('meta[name="description"]', { element(el) { el.setAttribute("content", page.description); } })
		.on("head", { element(el) { el.append(head, { html: true }); } })
		.on("div#root", { element(el) { el.setInnerContent(body, { html: true }); } })
		.transform(shell);
	const headers = new Headers(rewritten.headers);
	headers.set("content-type", "text/html; charset=utf-8");
	headers.set("cache-control", "public, max-age=300");
	return new Response(rewritten.body, { status: 200, headers });
}
