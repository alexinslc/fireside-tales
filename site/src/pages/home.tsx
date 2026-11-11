import { useEffect, useState } from "react";
import { Link } from "react-router";
import { BookOpen, Download, Feather, Flame, ShieldCheck } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { StoryBrowser } from "@/components/story-browser";
import { WeekPost, type PublicPost } from "@/components/week-post";
import { Page } from "@/components/layout";
import { api, type Story } from "@/lib/api";
import { weekName } from "@/lib/format";

const STEPS = [
	{ icon: BookOpen, title: "Write it", text: "Type a story or a quick rumor, one line per chat message. You'll see exactly how it looks in chat as you go." },
	{ icon: ShieldCheck, title: "We read it", text: "Every story is checked against the guidelines before it goes anywhere." },
	{ icon: Flame, title: "Players tell it", text: "Each week, up to 100 community stories are featured in the addon's own tab, credited to you or shared anonymously." },
];

export function HomePage() {
	const [data, setData] = useState<{ week: string; stories: Story[]; post: PublicPost | null } | null>(null);
	const [failed, setFailed] = useState(false);
	useEffect(() => { api<{ week: string; stories: Story[]; post: PublicPost | null }>("/api/featured").then(setData).catch(() => setFailed(true)); }, []);

	return (
		<>
			<section className="relative overflow-hidden border-b">
				<img src="/img/banner.jpg" alt="A campfire in a forest clearing at night, with an open storybook beside it"
					className="absolute inset-0 h-full w-full object-cover object-[center_40%]" />
				<div className="absolute inset-0 bg-gradient-to-r from-background via-background/70 to-transparent" />
				{/* The banner grows with its text, so nothing is cut off on a phone. */}
				<div className="relative flex min-h-[clamp(320px,40vw,480px)] items-center py-12">
					<div className="mx-auto w-full max-w-6xl px-4">
						<div className="max-w-xl">
							<h1 className="mb-4 text-4xl font-bold sm:text-6xl">Stories for the fire</h1>
							<p className="mb-6 text-lg sm:text-xl">Fireside Tales lets anyone tell a story at a campfire in World of Warcraft: Forever, one line at a time. Now the stories can come from you.</p>
							<div className="flex flex-col gap-3 sm:flex-row sm:flex-wrap">
								<Button asChild size="lg" className="h-14 rounded-xl px-8 text-lg font-bold shadow-lg shadow-ember/30 [&_svg]:size-5 sm:h-16 sm:text-xl">
									<Link to="/submit"><Feather />Contribute a story</Link>
								</Button>
								<Button asChild size="lg" variant="outline" className="h-14 rounded-xl border-2 border-gold/70 bg-background/60 px-8 text-lg font-bold text-gold backdrop-blur hover:bg-gold/10 hover:text-gold [&_svg]:size-5 sm:h-16 sm:text-xl">
									<a href="https://www.curseforge.com/wow/addons/fireside-tales"><Download />Get the addon</a>
								</Button>
							</div>
						</div>
					</div>
				</div>
			</section>

			<Page>
				<h2 className="mb-2 text-3xl font-bold">This week at the fire</h2>
				{failed && <p className="text-muted-foreground">Couldn't load this week's stories. Try again in a moment.</p>}
				{!data && !failed && (
					<div className="mt-6 grid gap-5 md:grid-cols-2 lg:grid-cols-3">
						{[0, 1, 2].map((i) => <Skeleton key={i} className="h-56 rounded-xl" />)}
					</div>
				)}
				{data && data.stories.length === 0 && (
					<Card className="mt-6 max-w-xl">
						<CardContent className="space-y-4 pt-6">
							<p>The week of {weekName(data.week)} is still waiting for its stories. Be one of the first!</p>
							<Button asChild size="lg" className="h-11 px-5"><Link to="/submit">Contribute a story</Link></Button>
						</CardContent>
					</Card>
				)}
				{data && data.stories.length > 0 && (
					<>
						{data.post && <div className="mt-6"><WeekPost post={data.post} stories={data.stories} /></div>}
						<p className="mb-6 text-muted-foreground">
							The week of {weekName(data.week)}. These are in the addon's Community tab. Not seeing them?{" "}
							<a className="text-gold underline" href="https://www.curseforge.com/wow/addons/fireside-tales">Update Fireside Tales</a>.
							{" "}Earlier weeks are on <Link className="text-gold underline" to="/past">Past weeks</Link>.
						</p>
						<StoryBrowser stories={data.stories} />
					</>
				)}

				<h2 className="mt-16 mb-6 text-3xl font-bold">How it works</h2>
				<div className="grid gap-5 md:grid-cols-3">
					{STEPS.map(({ icon: Icon, title, text }) => (
						<Card key={title}>
							<CardHeader>
								<Icon className="mb-1 size-6 text-ember" aria-hidden="true" />
								<CardTitle className="font-heading text-xl text-gold">{title}</CardTitle>
							</CardHeader>
							<CardContent><p>{text}</p></CardContent>
						</Card>
					))}
				</div>
			</Page>
		</>
	);
}
