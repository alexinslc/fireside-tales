import { useEffect, useState } from "react";
import { Link, useParams } from "react-router";
import { ArrowLeft, ArrowRight } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { MoodDot } from "@/components/chat";
import { StoryBrowser } from "@/components/story-browser";
import { Page } from "@/components/layout";
import { WeekPost, type PublicPost } from "@/components/week-post";
import { NotFoundPage } from "@/pages/not-found";
import { ApiError, api, type Story } from "@/lib/api";
import { capitalize, weekName } from "@/lib/format";

interface Post { week: string; stories: Story[]; older: string | null; newer: string | null; post: PublicPost | null }

// One past week, read like a post: a heading, a line about what was told, then every
// story in full. It can be narrowed by the same search and filters as the archive.
export function PastWeekPage() {
	const { week = "" } = useParams();
	const [post, setPost] = useState<Post | null>(null);
	const [missing, setMissing] = useState(false);
	const [failed, setFailed] = useState(false);

	useEffect(() => {
		setPost(null);
		setMissing(false);
		api<Post>(`/api/past/${week}`)
			.then((data) => {
				setPost(data);
				document.title = `${data.post ? `${data.post.title}: ` : ""}The week of ${weekName(week, true)} · Fireside Tales`;
			})
			.catch((error) => (error instanceof ApiError && error.status === 404 ? setMissing(true) : setFailed(true)));
	}, [week]);

	if (missing) return <NotFoundPage />;
	const rumors = post?.stories.filter((s) => s.kind === "rumor").length ?? 0;
	const moods = Object.entries((post?.stories ?? []).reduce<Record<string, number>>((all, s) => ({ ...all, [s.mood]: (all[s.mood] ?? 0) + 1 }), {}))
		.sort((a, b) => b[1] - a[1]);

	return (
		<Page className="max-w-5xl">
			<Link to="/past" className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted-foreground no-underline hover:text-gold"><ArrowLeft className="size-4" />All past weeks</Link>
			<header className="mb-8">
				<p className="mb-1 text-sm tracking-wide text-muted-foreground uppercase">From the fire</p>
				<h1 className="mb-3 text-4xl font-bold sm:text-5xl">The week of {weekName(week, true)}</h1>
				{post && (
					<>
						<p className="mb-3 text-lg text-muted-foreground">
							{post.stories.length} {post.stories.length === 1 ? "tale was" : "tales were"} featured in the addon's Community tab this week
							{rumors > 0 && `, ${rumors} of them ${rumors === 1 ? "a rumor" : "rumors"}`}, all shared by players.
						</p>
						<p className="flex flex-wrap gap-x-4 gap-y-1 text-sm text-muted-foreground">
							{moods.map(([mood, n]) => <span key={mood} className="flex items-center gap-1.5"><MoodDot mood={mood} />{n} {capitalize(mood).toLowerCase()}</span>)}
						</p>
					</>
				)}
			</header>

			{failed && <p className="text-muted-foreground">Couldn't load this week. Try again in a moment.</p>}
			{!post && !failed && <Skeleton className="h-64 rounded-xl" />}
			{post && (
				<>
					{post.post && <WeekPost post={post.post} stories={post.stories} />}
					<StoryBrowser stories={post.stories} copyable />
					<nav aria-label="Other weeks" className="mt-10 flex flex-wrap justify-between gap-3 border-t pt-6">
						{post.older ? <Button asChild variant="outline"><Link to={`/past/${post.older}`}><ArrowLeft />The week of {weekName(post.older)}</Link></Button> : <span />}
						{post.newer && <Button asChild variant="outline"><Link to={`/past/${post.newer}`}>The week of {weekName(post.newer)}<ArrowRight /></Link></Button>}
					</nav>
				</>
			)}
		</Page>
	);
}
