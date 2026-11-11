import { useEffect, useMemo, useRef, useState } from "react";
import { useSearchParams } from "react-router";
import { Check, ChevronDown, Copy, Search, Shuffle, Timer, X } from "lucide-react";
import { MOODS, toPaste } from "@shared/rules.js";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { ChatPreview, MoodDot } from "@/components/chat";
import { aboutSeconds, capitalize, credit } from "@/lib/format";
import { cn } from "@/lib/utils";
import type { Story } from "@/lib/api";

const PAGE = 24;
const QUICK_SECONDS = 20;

const MOOD_BAR: Record<string, string> = {
	funny: "bg-mood-funny", heartfelt: "bg-mood-heartfelt", dark: "bg-mood-dark",
	action: "bg-mood-action", spooky: "bg-mood-spooky", wise: "bg-mood-wise",
};

// A week's worth of stories (up to 100), easy to narrow down: one tap on a mood, story
// or rumor, quick ones only, or a word. "Pick one for me" works like the addon's Tell
// a Tale. Stories are compact rows that open in place. Filters live in the address,
// so a filtered view can be shared.
export function StoryBrowser({ stories, copyable = false }: { stories: Story[]; copyable?: boolean }) {
	const [params, setParams] = useSearchParams();
	const q = params.get("q") ?? "";
	const mood = params.get("mood") ?? "";
	const kind = params.get("kind") ?? "";
	const quick = params.get("quick") === "1";
	const [open, setOpen] = useState<string | null>(null);
	const [limit, setLimit] = useState(PAGE);
	const [pinned, setPinned] = useState<string | null>(null);
	const listRef = useRef<HTMLDivElement>(null);
	const scrollTo = useRef<string | null>(null);

	const set = (changes: Record<string, string>) => {
		const next = new URLSearchParams(params);
		for (const [key, value] of Object.entries(changes)) value ? next.set(key, value) : next.delete(key);
		setParams(next, { replace: true, preventScrollReset: true });
		setLimit(PAGE);
	};
	const clear = () => set({ q: "", mood: "", kind: "", quick: "" });
	const filtering = Boolean(q.trim() || mood || kind || quick);

	const seconds = useMemo(() => new Map(stories.map((s) => [s.id, aboutSeconds(s.lines)])), [stories]);
	const words = q.toLowerCase().split(/\s+/).filter(Boolean);
	const matchesBase = (s: Story) => {
		if (kind && s.kind !== kind) return false;
		if (quick && (seconds.get(s.id) ?? 0) > QUICK_SECONDS) return false;
		const text = [s.title, s.author, ...s.lines.map((l) => l.text)].join(" ").toLowerCase();
		return words.every((w) => text.includes(w));
	};
	const base = stories.filter(matchesBase);
	const shown = mood ? base.filter((s) => s.mood === mood) : base;
	const page = shown.slice(0, limit);
	const pinnedStory = pinned && !page.some((s) => s.id === pinned) ? stories.find((s) => s.id === pinned) : undefined;
	const rows = pinnedStory ? [pinnedStory, ...page] : page;
	// Counts follow the other filters, so each chip says what tapping it would show.
	const moodCounts = Object.fromEntries(MOODS.map((m) => [m, base.filter((s) => s.mood === m).length]));
	const rumors = stories.filter((s) => s.kind === "rumor").length;

	// Opens a story by its link (#id) or a random pick. If filters or paging would hide
	// it, it's pinned to the top of the list instead, so it's always in view.
	const reveal = (id: string) => {
		if (!stories.some((s) => s.id === id)) return;
		setPinned(id);
		setOpen(id);
		scrollTo.current = id;
	};
	// Scrolls once the opened story has rendered.
	useEffect(() => {
		const id = scrollTo.current;
		if (!id) return;
		const element = document.getElementById(id);
		if (element) {
			scrollTo.current = null;
			element.scrollIntoView({ behavior: "smooth", block: "center" });
		}
	});
	useEffect(() => {
		const fromHash = () => { if (window.location.hash) reveal(window.location.hash.slice(1)); };
		fromHash();
		window.addEventListener("hashchange", fromHash);
		return () => window.removeEventListener("hashchange", fromHash);
		// eslint-disable-next-line react-hooks/exhaustive-deps
	}, [stories]);

	const pick = () => {
		const pool = shown.length ? shown : stories;
		const others = pool.filter((s) => s.id !== open);
		const story = (others.length ? others : pool)[Math.floor(Math.random() * (others.length || pool.length))];
		if (story) reveal(story.id);
	};

	const chip = (active: boolean) => cn(
		"inline-flex h-9 items-center gap-2 rounded-full border px-3.5 text-sm font-medium transition-colors",
		active ? "border-gold bg-gold/15 text-gold" : "border-border text-muted-foreground hover:border-gold/60 hover:text-foreground",
	);

	return (
		<div>
			<div className="mb-4 flex flex-col gap-3 sm:flex-row sm:items-center">
				<div className="relative sm:flex-1">
					<Search className="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground" />
					<Input type="search" aria-label="Search these stories" placeholder={`Search ${stories.length} tales: a word, a place, a teller`}
						value={q} onChange={(e) => set({ q: e.target.value })} className="h-11 pl-9" />
				</div>
				<Button size="lg" className="h-11 px-5" onClick={pick}><Shuffle />Pick one for me</Button>
			</div>

			<div className="mb-3 flex flex-wrap gap-2" role="group" aria-label="Mood">
				<button type="button" className={chip(!mood)} aria-pressed={!mood} onClick={() => set({ mood: "" })}>
					All moods <span className="text-xs opacity-70">{base.length}</span>
				</button>
				{MOODS.map((m) => (
					<button key={m} type="button" className={chip(mood === m)} aria-pressed={mood === m}
						disabled={moodCounts[m] === 0 && mood !== m}
						onClick={() => set({ mood: mood === m ? "" : m })}
						style={moodCounts[m] === 0 && mood !== m ? { opacity: 0.4 } : undefined}>
						<MoodDot mood={m} />{capitalize(m)} <span className="text-xs opacity-70">{moodCounts[m]}</span>
					</button>
				))}
			</div>
			<div className="mb-6 flex flex-wrap items-center gap-2">
				<div className="inline-flex rounded-full border p-0.5" role="group" aria-label="Kind">
					{[["", "Everything"], ["story", "Stories"], ["rumor", `Rumors (${rumors})`]].map(([value, label]) => (
						<button key={value} type="button" aria-pressed={kind === value} onClick={() => set({ kind: value })}
							className={cn("h-8 rounded-full px-3.5 text-sm font-medium transition-colors", kind === value ? "bg-gold/15 text-gold" : "text-muted-foreground hover:text-foreground")}>
							{label}
						</button>
					))}
				</div>
				<button type="button" className={chip(quick)} aria-pressed={quick} onClick={() => set({ quick: quick ? "" : "1" })}>
					<Timer className="size-4" />Under {QUICK_SECONDS} seconds
				</button>
				{filtering && <Button variant="ghost" onClick={clear}><X />Clear</Button>}
				<span className="ml-auto text-sm text-muted-foreground" aria-live="polite">
					{filtering ? `${shown.length} of ${stories.length}` : `${stories.length} ${stories.length === 1 ? "tale" : "tales"}`}
				</span>
			</div>

			{rows.length === 0 ? (
				<p className="rounded-xl border p-6 text-muted-foreground">Nothing matches. <button type="button" className="text-gold underline" onClick={clear}>Clear the filters</button></p>
			) : (
				<div ref={listRef} className="grid gap-x-6 gap-y-2 md:grid-cols-2">
					{rows.map((story) => (
						<StoryRow key={story.id} story={story} seconds={seconds.get(story.id) ?? 0} open={open === story.id}
							onToggle={() => setOpen(open === story.id ? null : story.id)} copyable={copyable} />
					))}
				</div>
			)}
			{shown.length > limit && (
				<div className="mt-6 flex justify-center">
					<Button variant="outline" size="lg" onClick={() => setLimit((l) => l + PAGE)}>
						Show {Math.min(PAGE, shown.length - limit)} more <span className="text-muted-foreground">({shown.length - limit} left)</span>
					</Button>
				</div>
			)}
		</div>
	);
}

function StoryRow({ story, seconds, open, onToggle, copyable }: {
	story: Story; seconds: number; open: boolean; onToggle: () => void; copyable: boolean;
}) {
	const [copied, setCopied] = useState(false);
	const copy = async () => {
		try { await navigator.clipboard.writeText(toPaste(story)); setCopied(true); } catch { /* the button just stays as it was */ }
	};
	return (
		<article id={story.id} className={cn("scroll-mt-24 overflow-hidden rounded-lg border bg-card/60 transition-colors", open ? "border-gold/70 md:col-span-2" : "hover:border-gold/50")}>
			<button type="button" onClick={onToggle} aria-expanded={open} className="flex w-full items-stretch text-left">
				<span aria-hidden className={cn("w-1.5 shrink-0", MOOD_BAR[story.mood] ?? "bg-muted")} />
				<span className="min-w-0 flex-1 px-4 py-3">
					<span className="flex items-baseline gap-2">
						<span className="truncate font-heading text-lg font-bold text-gold">{story.title}</span>
						{story.kind === "rumor" && <span className="shrink-0 rounded-full border px-2 text-xs text-muted-foreground">rumor</span>}
					</span>
					<span className="block truncate text-sm text-muted-foreground">
						{capitalize(story.mood)} · {seconds}s · {credit(story)}
					</span>
				</span>
				<ChevronDown aria-hidden className={cn("m-4 size-5 shrink-0 self-center text-muted-foreground transition-transform", open && "rotate-180")} />
			</button>
			{open && (
				<div className="border-t px-4 py-4">
					<ChatPreview lines={story.lines} name={story.author} />
					<div className="mt-3 flex flex-wrap gap-2">
						{copyable && (
							<Button variant="outline" onClick={copy}>{copied ? <Check /> : <Copy />}{copied ? "Copied! Paste it into Write Your Tales" : "Copy for the game"}</Button>
						)}
						<Button variant="ghost" asChild><a href={`#${story.id}`}>Link to this tale</a></Button>
					</div>
				</div>
			)}
		</article>
	);
}
