import { useEffect, useState } from "react";
import { Link, useSearchParams } from "react-router";
import { ArrowRight } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { MoodDot } from "@/components/chat";
import { StoryEntry } from "@/components/story-entry";
import { PastFilters, filtersFrom, filtersTo, isFiltering, type Filters } from "@/components/past-filters";
import { Page, PageTitle } from "@/components/layout";
import { api, type Story } from "@/lib/api";
import { capitalize, weekName } from "@/lib/format";

interface WeekSummary { week: string; count: number; rumors: number; moods: Record<string, number>; titles: string[]; post: { title: string; excerpt: string } | null }
interface Results { total: number; page: number; pages: number; stories: Story[] }

function tales(count: number) {
	return `${count} ${count === 1 ? "tale" : "tales"}`;
}

// A week, like a post in a blog's archive: its date, what was in it, and a few titles.
function WeekPost({ week }: { week: WeekSummary }) {
	const moods = Object.entries(week.moods).sort((a, b) => b[1] - a[1]);
	return (
		<article className="border-b border-border/60 py-8 first:pt-0 last:border-b-0">
			<p className="mb-1 text-sm tracking-wide text-muted-foreground uppercase">From the fire</p>
			<h2 className="mb-2 text-3xl font-bold">
				<Link to={`/past/${week.week}`} className="text-foreground no-underline hover:text-gold">The week of {weekName(week.week, true)}</Link>
			</h2>
			{week.post && (
				<>
					<p className="mb-2 font-heading text-xl font-bold text-gold">{week.post.title}</p>
					<p className="mb-3 text-lg">{week.post.excerpt}</p>
				</>
			)}
			<p className="mb-3 text-muted-foreground">
				{tales(week.count)}{week.rumors > 0 && `, ${week.rumors} of them ${week.rumors === 1 ? "a rumor" : "rumors"}`}.
				{week.titles.length > 0 && <> Including <span className="text-foreground">{week.titles.join(", ")}</span>{week.count > week.titles.length && ", and more"}.</>}
			</p>
			<p className="mb-4 flex flex-wrap gap-x-4 gap-y-1 text-sm text-muted-foreground">
				{moods.map(([mood, n]) => <span key={mood} className="flex items-center gap-1.5"><MoodDot mood={mood} />{n} {mood === "heartfelt" ? "heartfelt" : capitalize(mood).toLowerCase()}</span>)}
			</p>
			<Button asChild variant="outline"><Link to={`/past/${week.week}`}>Read the week<ArrowRight /></Link></Button>
		</article>
	);
}

export function PastPage() {
	const [params, setParams] = useSearchParams();
	const filters = filtersFrom(params);
	const page = Math.max(1, Number(params.get("page")) || 1);
	const searching = isFiltering(filters);
	const [weeks, setWeeks] = useState<WeekSummary[] | null>(null);
	const [results, setResults] = useState<Results | null>(null);
	const [failed, setFailed] = useState(false);

	useEffect(() => {
		api<{ weeks: WeekSummary[] }>("/api/past").then((d) => setWeeks(d.weeks)).catch(() => setFailed(true));
	}, []);

	// Searches every past week, a moment after typing stops.
	const query = new URLSearchParams({ ...filtersTo(filters), page: String(page) }).toString();
	useEffect(() => {
		if (!searching) { setResults(null); return; }
		const timer = setTimeout(() => {
			api<Results>(`/api/past/search?${query}`).then(setResults).catch(() => setFailed(true));
		}, 250);
		return () => clearTimeout(timer);
	}, [query, searching]);

	const change = (next: Filters) => setParams(filtersTo(next), { replace: true });
	const goTo = (n: number) => {
		setParams({ ...filtersTo(filters), page: String(n) });
		window.scrollTo(0, 0);
	};

	return (
		<Page className="max-w-4xl">
			<PageTitle title="Past weeks">
				Every week of stories and rumors featured at the fire. Search them all, or open a week to read it. To tell one tonight, copy it into Write Your Tales in the game.
			</PageTitle>
			{weeks && weeks.length > 0 && <PastFilters filters={filters} onChange={change} placeholder="Search every week: a word, a place, an author" />}
			{failed && <p className="text-muted-foreground">Couldn't load past weeks. Try again in a moment.</p>}
			{!weeks && !failed && <Skeleton className="h-40 rounded-xl" />}
			{weeks?.length === 0 && (
				<Card className="max-w-xl">
					<CardContent className="space-y-4 pt-6">
						<p>No past weeks yet. This week's stories are on the home page.</p>
						<Button asChild variant="outline" size="lg"><Link to="/">This week</Link></Button>
					</CardContent>
				</Card>
			)}

			{searching ? (
				<section aria-live="polite">
					{!results && <Skeleton className="h-40 rounded-xl" />}
					{results && (
						<>
							<p className="mb-6 text-muted-foreground">
								{results.total === 0 ? "Nothing matches. Try fewer words, or another mood." : `${tales(results.total)} found.`}
							</p>
							{results.stories.map((story) => <StoryEntry key={story.id} story={story} showWeek />)}
							{results.pages > 1 && (
								<nav aria-label="More results" className="mt-8 flex items-center gap-3">
									<Button variant="outline" disabled={page <= 1} onClick={() => goTo(page - 1)}>Newer</Button>
									<span className="text-sm text-muted-foreground">Page {results.page} of {results.pages}</span>
									<Button variant="outline" disabled={page >= results.pages} onClick={() => goTo(page + 1)}>Older</Button>
								</nav>
							)}
						</>
					)}
				</section>
			) : (
				<section>{weeks?.map((week) => <WeekPost key={week.week} week={week} />)}</section>
			)}
		</Page>
	);
}
