import { useEffect, useState } from "react";
import { Link } from "react-router";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { StoryBrowser } from "@/components/story-browser";
import { SubmitForm } from "@/components/submit-form";
import { WeekPost, type PublicPost } from "@/components/week-post";
import { api, type Story } from "@/lib/api";
import { weekName } from "@/lib/format";

const ADDON_URL = "https://www.curseforge.com/wow/addons/fireside-tales";
const PEEK = 6;

// The hero's chat window plays a tale, the way the people at the fire see it.
const SAMPLE = [
	{ kind: "say", text: "Ever met an honest merchant? I did, once." },
	{ kind: "say", text: "He sold me a mule and told me it was a terrible mule." },
	{ kind: "emote", text: "rolls up one sleeve to show an old scar." },
	{ kind: "say", text: "He was not joking." },
] as const;

const OBJECTIVES = [
	["Write your tale", "Three to eight lines, the way you'd type them in game."],
	["Wait while it's read", "Every story is checked against the guidelines. Your code shows where it is."],
	["See it ship", "Approved tales go out in the weekly update, in the Community tab and its voice pack."],
];

const LINKS = [
	{ to: "/past", label: "Past weeks", text: "Every week of stories told so far." },
	{ to: "/guidelines", label: "Guidelines", text: "What makes a story ready for the fire." },
	{ to: "/status", label: "Check on yours", text: "Use your code to see where your story is." },
	{ to: "/feedback", label: "Feedback", text: "Bugs, ideas, or a story you'd like someone to write." },
];

type Featured = { week: string; stories: Story[]; post: PublicPost | null };

function Hero() {
	return (
		<section className="relative isolate overflow-hidden border-b border-black bg-[#0b1530]">
			{/* The art fills the left; the right is open night sky for the words. */}
			<img src="/img/banner.jpg" alt="" className="absolute inset-0 -z-10 h-full w-full object-cover object-[30%_50%] opacity-90 sm:object-left" />
			<div className="absolute inset-0 -z-10 bg-gradient-to-t from-[#0a0d16] via-[#0a0d16]/40 to-transparent sm:bg-gradient-to-r sm:from-transparent sm:via-[#0b1530]/30 sm:to-[#0b1530]" />
			<div className="mx-auto grid w-full max-w-6xl items-end gap-6 px-4 pt-24 pb-6 sm:min-h-[460px] sm:grid-cols-2 sm:pt-16 sm:pb-8">
				<div className="order-2 sm:order-1 sm:self-end">
					<div className="flex gap-1" role="presentation">
						<span className="chat-tab" aria-selected="false">General</span>
						<span className="chat-tab" aria-selected="true">Fireside</span>
					</div>
					<div className="chat-frame max-w-md px-3 py-2.5 text-[15px] leading-snug sm:text-[16px]" aria-label="A tale told in chat">
						{SAMPLE.map((line, i) => (
							<p key={i} className={`line-in mb-1 last:mb-0 ${line.kind === "emote" ? "text-emote" : "text-say"}`} style={{ animationDelay: `${0.3 + i * 0.7}s` }}>
								{line.kind === "emote" ? `Bram ${line.text}` : `[Bram] says: ${line.text}`}
							</p>
						))}
					</div>
				</div>
				<div className="order-1 sm:order-2 sm:self-center sm:pl-6">
					<h1 className="text-[42px] leading-[1.02] [text-shadow:0_2px_12px_#000] sm:text-[64px]">Tell a tale<br />at the fire.</h1>
					<p className="mt-3 max-w-md text-lg text-[#e6e1d3] [text-shadow:0_1px_6px_#000]">
						Write a story for the <a className="text-[#ffd100] underline" href={ADDON_URL}>Fireside Tales</a> addon. The best ones are told around campfires for a week, with your name on them.
					</p>
					<div className="mt-5 flex flex-wrap gap-3">
						<Button asChild size="lg" className="h-11 px-5 text-base"><a href="#write">Write a tale</a></Button>
						<Button asChild size="lg" variant="outline" className="h-11 px-5 text-base"><a href={ADDON_URL}>Get the addon</a></Button>
					</div>
				</div>
			</div>
		</section>
	);
}

// How it works, as a quest from the log.
function Quest() {
	return (
		<section className="parchment mx-auto max-w-3xl px-6 py-7 sm:px-10 sm:py-9" aria-labelledby="quest-title">
			<p className="font-[family-name:var(--font-ui)] text-sm tracking-wide text-[#6b4c22] uppercase">How it works</p>
			<h2 id="quest-title" className="mt-1 text-4xl">A Tale for the Fire</h2>
			<p className="mt-3 text-lg leading-relaxed">
				The fire's burned low and the regulars have told every story twice. Bring a new one. Make it short, make it yours, and make them lean in.
			</p>
			<h3 className="rule-title mt-6 text-2xl">Objectives</h3>
			<ol className="mt-3 space-y-2.5">
				{OBJECTIVES.map(([title, text]) => (
					<li key={title} className="flex gap-3">
						<span aria-hidden className="mt-2 size-2.5 shrink-0 rotate-45 bg-[#6b4c22]" />
						<span><strong>{title}.</strong> {text}</span>
					</li>
				))}
			</ol>
			<h3 className="rule-title mt-6 text-2xl">Rewards</h3>
			<p className="mt-2">You will receive:</p>
			<div className="mt-2 inline-flex items-center gap-3 rounded-[3px] bg-[#2b1a0c]/10 py-1.5 pr-4 pl-1.5 shadow-[inset_0_0_0_1px_#7b5a2c]">
				<img src="/img/icon.png" alt="" className="size-10 rounded-[2px] shadow-[0_0_0_1px_#000]" />
				<span className="font-semibold">Your name on the tale, in the addon and on this site</span>
			</div>
		</section>
	);
}

export function HomePage() {
	const [data, setData] = useState<Featured | null>(null);
	const [failed, setFailed] = useState(false);
	const [all, setAll] = useState(false);
	useEffect(() => { api<Featured>("/api/featured").then(setData).catch(() => setFailed(true)); }, []);
	const shown = data ? (all ? data.stories : data.stories.slice(0, PEEK)) : [];

	return (
		<>
			<Hero />

			<div id="write" className="mx-auto w-full max-w-6xl scroll-mt-20 px-4 pt-12 pb-16">
				<h2 className="rule-title mb-6 text-4xl">Write your tale</h2>
				<SubmitForm />
			</div>

			<div className="mx-auto w-full max-w-6xl space-y-20 px-4 pb-20">
				<section>
					<h2 className="rule-title mb-2 text-4xl">This week at the fire</h2>
					{failed && <p className="text-muted-foreground">Couldn't load this week's stories. Try again in a moment.</p>}
					{!data && !failed && (
						<div className="mt-6 grid gap-3 md:grid-cols-2 lg:grid-cols-3">
							{[0, 1, 2].map((i) => <Skeleton key={i} className="h-36 rounded-[4px]" />)}
						</div>
					)}
					{data && data.stories.length === 0 && (
						<p className="text-muted-foreground">The week of {weekName(data.week)} is still waiting for its stories. Yours could be the first.</p>
					)}
					{data && data.stories.length > 0 && (
						<>
							{data.post && <div className="mt-6"><WeekPost post={data.post} stories={data.stories} /></div>}
							<p className="mb-6 text-muted-foreground">
								The week of {weekName(data.week)}, in the addon's Community tab now. Not seeing them?{" "}
								<a className="text-[#ffd100] underline" href={ADDON_URL}>Update Fireside Tales</a>.
							</p>
							<StoryBrowser stories={shown} />
							{data.stories.length > PEEK && (
								<Button variant="outline" className="mt-6 h-11 px-5" onClick={() => setAll((v) => !v)}>
									{all ? "Show fewer" : `Show all ${data.stories.length} stories`}
								</Button>
							)}
						</>
					)}
				</section>

				<Quest />

				<section>
					<h2 className="rule-title mb-6 text-4xl">More around the fire</h2>
					<div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
						{LINKS.map((link) => (
							<Link key={link.to} to={link.to} className="tooltip block p-4 no-underline">
								<p className="text-[17px] font-bold text-white">{link.label}</p>
								<p className="mt-0.5 text-[15px] text-flavor">&ldquo;{link.text}&rdquo;</p>
							</Link>
						))}
					</div>
				</section>
			</div>
		</>
	);
}
