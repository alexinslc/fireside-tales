import { useEffect, useState } from "react";
import { Link } from "react-router";
import { BookOpen, Download, Feather, Megaphone, ShieldCheck, Package } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { StoryBrowser } from "@/components/story-browser";
import { SubmitForm } from "@/components/submit-form";
import { WeekPost, type PublicPost } from "@/components/week-post";
import { api, type Story } from "@/lib/api";
import { weekName } from "@/lib/format";

const ADDON_URL = "https://www.curseforge.com/wow/addons/fireside-tales";
const PEEK = 3;

const STEPS = [
	{ icon: Feather, title: "Send it", text: "Write your tale above, the way you'd type it in game." },
	{ icon: ShieldCheck, title: "We read it", text: "Every story is checked against the guidelines. You can check on yours with your code." },
	{ icon: Package, title: "It ships", text: "Approved stories go out in the weekly addon update, in the Community tab and its voice pack." },
	{ icon: Megaphone, title: "You're credited", text: "Your character's name goes on the story, in the addon and on this site." },
];

const LINKS = [
	{ to: "/past", label: "Past weeks", text: "Every week of stories told so far." },
	{ to: "/guidelines", label: "Guidelines", text: "What makes a story that's ready for the fire." },
	{ to: "/status", label: "Check on yours", text: "Use your code to see where your story is." },
	{ to: "/feedback", label: "Feedback", text: "Bugs, ideas, or a story you'd like someone to write." },
];

type Featured = { week: string; stories: Story[]; post: PublicPost | null };

export function HomePage() {
	const [data, setData] = useState<Featured | null>(null);
	const [failed, setFailed] = useState(false);
	const [all, setAll] = useState(false);
	useEffect(() => { api<Featured>("/api/featured").then(setData).catch(() => setFailed(true)); }, []);
	const shown = data ? (all ? data.stories : data.stories.slice(0, PEEK)) : [];

	return (
		<>
			{/* Short on purpose, so the form starts on the first screen, even on a phone. */}
			<section className="mx-auto w-full max-w-6xl px-4 pt-6 pb-5 sm:pt-10 sm:pb-8">
				<h1 className="text-3xl font-bold leading-tight sm:text-5xl">Tell a tale at the fire.</h1>
				<p className="mt-2 max-w-2xl text-base text-foreground/90 sm:mt-3 sm:text-xl">
					Approved stories are featured for a week in the{" "}
					<a className="text-gold underline" href={ADDON_URL}>Fireside Tales</a> addon, with your name on them.
				</p>
			</section>

			<div className="mx-auto w-full max-w-6xl px-4 pb-12">
				<SubmitForm />
			</div>

			<div className="mx-auto w-full max-w-6xl space-y-16 px-4 pb-16">
				<section>
					<h2 className="mb-6 text-3xl font-bold">How it works</h2>
					<ol className="grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
						{STEPS.map(({ icon: Icon, title, text }, i) => (
							<li key={title}>
								<Card className="h-full">
									<CardHeader>
										<Icon className="mb-1 size-6 text-ember" aria-hidden="true" />
										<CardTitle className="font-heading text-xl text-gold"><span className="sr-only">Step {i + 1}: </span>{title}</CardTitle>
									</CardHeader>
									<CardContent><p>{text}</p></CardContent>
								</Card>
							</li>
						))}
					</ol>
				</section>

				<section>
					<h2 className="mb-2 text-3xl font-bold">This week at the fire</h2>
					{failed && <p className="text-muted-foreground">Couldn't load this week's stories. Try again in a moment.</p>}
					{!data && !failed && (
						<div className="mt-6 grid gap-5 md:grid-cols-2 lg:grid-cols-3">
							{[0, 1, 2].map((i) => <Skeleton key={i} className="h-56 rounded-xl" />)}
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
								<a className="text-gold underline" href={ADDON_URL}>Update Fireside Tales</a>.
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

				<section>
					<h2 className="mb-6 text-3xl font-bold">More around the fire</h2>
					<div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
						<a href={ADDON_URL} className="group rounded-xl border bg-card p-5 no-underline transition-colors hover:border-ember/70">
							<p className="flex items-center gap-2 font-heading text-lg font-bold text-gold"><Download className="size-5" aria-hidden="true" />Get the addon</p>
							<p className="mt-1 text-sm text-muted-foreground">Fireside Tales and its voice packs, free on CurseForge.</p>
						</a>
						{LINKS.map((link) => (
							<Link key={link.to} to={link.to} className="rounded-xl border bg-card p-5 no-underline transition-colors hover:border-ember/70">
								<p className="flex items-center gap-2 font-heading text-lg font-bold text-gold"><BookOpen className="size-5" aria-hidden="true" />{link.label}</p>
								<p className="mt-1 text-sm text-muted-foreground">{link.text}</p>
							</Link>
						))}
					</div>
				</section>
			</div>
		</>
	);
}
