import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { toast } from "sonner";
import { Check, RotateCcw, X } from "lucide-react";
import { MOODS, KINDS, findProblems, tidyStory } from "@shared/rules.js";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { Separator } from "@/components/ui/separator";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { ChatPreview } from "@/components/chat";
import { Page } from "@/components/layout";
import { ApiError, api, post, type Line, type Story } from "@/lib/api";
import { aboutSeconds, credit } from "@/lib/format";
import { cn } from "@/lib/utils";

interface Submission extends Story {
	receipt: string;
	status: string;
	contact: string;
	emails: boolean;
	source: string;
	created_at: number;
	review_note: string;
	reviewed_by: string;
	shipped_version: string | null;
	stage: string;
	original: { lines: Line[] } | null;
}

interface Note {
	id: string; created_at: number; kind: string; message: string; contact: string; status: string; emailed: boolean;
	review: { category: string; priority: string; summary: string; notes: string } | null; reviewed_by: string;
}

// Where an approved story is on its way to players.
const STAGE: Record<string, { label: string; className?: string }> = {
	scheduled: { label: "Not in a release yet", className: "text-muted-foreground" },
	in_addon: { label: "In the addon", className: "border-good/60 text-good" },
	featured: { label: "Featured now", className: "border-gold/60 text-gold" },
	missed: { label: "Missed its release", className: "border-destructive/60 text-destructive" },
	past: { label: "Past week", className: "text-muted-foreground" },
};

function shortWeek(week: string) {
	return new Date(`${week}T12:00:00Z`).toLocaleDateString(undefined, { month: "short", day: "numeric", timeZone: "UTC" });
}

export function AdminPage() {
	const [tab, setTab] = useState("overview");
	const [who, setWho] = useState("");
	const [items, setItems] = useState<Submission[]>([]);
	const [chosenId, setChosenId] = useState<string | null>(null);
	const [loadError, setLoadError] = useState("");

	const load = useCallback(async (keepChoice = false) => {
		if (tab === "feedback" || tab === "posts" || tab === "overview") return;
		try {
			const data = await api<{ submissions: Submission[] }>(`/api/admin/submissions?status=${tab}`);
			setItems(data.submissions);
			setChosenId((current) => (keepChoice && data.submissions.some((s) => s.id === current) ? current : data.submissions[0]?.id ?? null));
			setLoadError("");
		} catch (e) {
			setLoadError(e instanceof Error ? e.message : "Couldn't load.");
		}
	}, [tab]);

	useEffect(() => { load(); }, [load]);
	useEffect(() => { api<{ email: string }>("/api/admin/me").then((m) => setWho(m.email)).catch(() => {}); }, []);

	// Every 5 minutes while the page is in view, checks for stories and feedback that
	// arrived since you last looked, without changing what you're reviewing.
	const [fresh, setFresh] = useState({ stories: 0, notes: 0 });
	const seen = useRef<{ stories: Set<string>; notes: Set<string> } | null>(null);
	const check = useCallback(async () => {
		try {
			const [pending, notes] = await Promise.all([
				api<{ submissions: { id: string }[] }>("/api/admin/submissions?status=pending"),
				api<{ feedback: { id: string }[] }>("/api/admin/feedback?status=new"),
			]);
			const stories = pending.submissions.map((s) => s.id);
			const noteIds = notes.feedback.map((n) => n.id);
			if (!seen.current) {
				seen.current = { stories: new Set(stories), notes: new Set(noteIds) };
				return;
			}
			const known = seen.current;
			setFresh({ stories: stories.filter((id) => !known.stories.has(id)).length, notes: noteIds.filter((id) => !known.notes.has(id)).length });
		} catch { /* try again next time */ }
	}, []);
	const markSeen = useCallback(() => {
		seen.current = null;
		setFresh({ stories: 0, notes: 0 });
		check();
	}, [check]);
	useEffect(() => {
		check();
		const timer = setInterval(() => { if (document.visibilityState === "visible") check(); }, 5 * 60 * 1000);
		const onShow = () => { if (document.visibilityState === "visible") check(); };
		document.addEventListener("visibilitychange", onShow);
		return () => { clearInterval(timer); document.removeEventListener("visibilitychange", onShow); };
	}, [check]);
	// Opening the Waiting or Feedback tab counts as having seen what's new.
	useEffect(() => { if (tab === "pending" || tab === "feedback") markSeen(); }, [tab, markSeen]);
	const freshTotal = fresh.stories + fresh.notes;
	useEffect(() => {
		document.title = `${freshTotal ? `(${freshTotal}) ` : ""}Story Review · Fireside Tales`;
	}, [freshTotal]);
	const showFresh = () => {
		const next = fresh.stories ? "pending" : "feedback";
		if (next === tab) { markSeen(); load(true); } else setTab(next);
	};

	const chosen = items.find((i) => i.id === chosenId) ?? null;

	return (
		<Page>
			<div className="mb-6 flex flex-wrap items-end justify-between gap-3">
				<h1 className="text-4xl font-bold">Story review</h1>
				<div className="flex flex-wrap items-center gap-3">
					{freshTotal > 0 && (
						<Button size="sm" onClick={showFresh}>
							{[fresh.stories && `${fresh.stories} new ${fresh.stories === 1 ? "story" : "stories"}`, fresh.notes && `${fresh.notes} new feedback`].filter(Boolean).join(", ")}: show
						</Button>
					)}
					{who && <p className="text-sm text-muted-foreground">Reviewing as {who}</p>}
				</div>
			</div>
			<Tabs value={tab} onValueChange={setTab} className="mb-6">
				<TabsList>
					<TabsTrigger value="overview">Overview</TabsTrigger>
					<TabsTrigger value="pending">Waiting</TabsTrigger>
					<TabsTrigger value="approved">Approved</TabsTrigger>
					<TabsTrigger value="rejected">Rejected</TabsTrigger>
					<TabsTrigger value="all">Everything</TabsTrigger>
					<TabsTrigger value="posts">Week posts</TabsTrigger>
					<TabsTrigger value="feedback">Feedback</TabsTrigger>
				</TabsList>
			</Tabs>

			{tab === "overview" ? <OverviewTab onOpen={setTab} /> : tab === "posts" ? <PostsTab /> : tab === "feedback" ? <FeedbackList /> : (
				<div className="grid items-start gap-6 lg:grid-cols-[minmax(260px,340px)_minmax(0,1fr)]">
					<div className="space-y-2">
						{loadError && <p className="text-destructive">{loadError}</p>}
						{!loadError && items.length === 0 && <Card><CardContent className="pt-6 text-muted-foreground">Nothing here.</CardContent></Card>}
						{items.map((item) => {
							return (
								<button key={item.id} type="button" onClick={() => setChosenId(item.id)}
									className={cn("block w-full rounded-lg border bg-card p-3 text-left transition-colors hover:border-gold/70", item.id === chosenId && "border-gold")}>
									<strong className="block">{item.title}</strong>
									<span className="block text-sm text-muted-foreground">{item.kind}, {item.mood || "no mood"}, {credit(item)}</span>
									<span className="mt-1 flex flex-wrap items-center gap-2 text-sm">
										{!item.mood && <Badge variant="outline" className="text-muted-foreground">needs a mood</Badge>}
										{item.source === "agent" && <Badge variant="outline">Agent</Badge>}
										{item.week && <span className="text-muted-foreground">week of {shortWeek(item.week)}</span>}
										{item.status === "approved" && <Badge variant="outline" className={STAGE[item.stage]?.className}>{STAGE[item.stage]?.label ?? item.stage}{item.shipped_version && ` · v${item.shipped_version}`}</Badge>}
									</span>
								</button>
							);
						})}
					</div>
					{chosen
						? <Review key={chosen.id + chosen.status} item={chosen} onSaved={() => load(true)} />
						: <Card><CardContent className="pt-6 text-muted-foreground">Pick a submission to review it.</CardContent></Card>}
				</div>
			)}
		</Page>
	);
}

function Review({ item, onSaved }: { item: Submission; onSaved: () => void }) {
	const [draft, setDraft] = useState({ kind: item.kind, title: item.title, mood: item.mood, lines: item.lines.map((l) => ({ ...l })) });
	const [note, setNote] = useState(item.review_note ?? "");
	const [weeks, setWeeks] = useState<{ week: string; count: number }[]>([]);
	const [target, setTarget] = useState({ min: 5, max: 10 });
	const [week, setWeek] = useState<string | null>(item.week);
	const [busy, setBusy] = useState(false);

	useEffect(() => {
		api<{ weeks: { week: string; count: number }[]; target: { min: number; max: number } }>("/api/admin/weeks").then((data) => {
			setWeeks(data.weeks);
			setTarget(data.target);
			setWeek((w) => w ?? (data.weeks.find((x) => x.count < data.target.max) ?? data.weeks[0])?.week ?? null);
		}).catch(() => {});
	}, []);

	const story = useMemo(() => tidyStory({ ...draft, author: item.author, ruleset: item.ruleset }), [draft, item]);
	const problems = useMemo(() => findProblems(story), [story]);
	const setLine = (index: number, change: Partial<Line>) =>
		setDraft((d) => ({ ...d, lines: d.lines.map((l, i) => (i === index ? { ...l, ...change } : l)) }));

	const act = async (action: string, extra: Record<string, unknown> = {}) => {
		setBusy(true);
		try {
			await post(`/api/admin/submissions/${item.id}`, { action, note, story: draft, ...extra });
			toast.success(action === "approve" ? `Approved for the week of ${week ? shortWeek(week) : ""}` : action === "reject" ? "Turned away" : "Saved");
			onSaved();
		} catch (e) {
			const details = e instanceof ApiError && Array.isArray(e.data.problems) ? (e.data.problems as { message: string }[]).map((p) => p.message).join(" ") : "";
			toast.error(`${e instanceof Error ? e.message : "Couldn't save."} ${details}`);
		} finally {
			setBusy(false);
		}
	};

	return (
		<div className="space-y-6">
			<Card>
				<CardContent className="space-y-5 pt-6">
					<p className="text-sm text-muted-foreground">
						Sent {new Date(item.created_at).toLocaleString()} · code {item.receipt} · {credit(item)}
						{item.contact && ` · contact: ${item.contact}`}{item.emails && " · the author will be emailed"}{item.source === "agent" && " · sent by an AI agent"}
						{item.reviewed_by && ` · last decided by ${item.reviewed_by}`}
					</p>
					<div className="space-y-2">
						<Label htmlFor="r-title">Title</Label>
						<Input id="r-title" value={draft.title} onChange={(e) => setDraft((d) => ({ ...d, title: e.target.value }))} />
					</div>
					<div className="grid gap-4 sm:grid-cols-2">
						<div className="space-y-2">
							<Label>Kind</Label>
							<Select value={draft.kind} onValueChange={(v) => setDraft((d) => ({ ...d, kind: v as Story["kind"] }))}>
								<SelectTrigger className="w-full"><SelectValue /></SelectTrigger>
								<SelectContent>{KINDS.map((k: string) => <SelectItem key={k} value={k}>{k}</SelectItem>)}</SelectContent>
							</Select>
						</div>
						<div className="space-y-2">
							<Label>Mood</Label>
							<Select value={draft.mood || undefined} onValueChange={(v) => setDraft((d) => ({ ...d, mood: v }))}>
								<SelectTrigger className="w-full"><SelectValue placeholder="Pick one" /></SelectTrigger>
								<SelectContent>{MOODS.map((m: string) => <SelectItem key={m} value={m}>{m}</SelectItem>)}</SelectContent>
							</Select>
						</div>
					</div>
					<div className="space-y-2">
						<Label>Lines</Label>
						{draft.lines.map((line, index) => (
							<div key={index} className="grid grid-cols-[110px_minmax(0,1fr)] gap-2">
								<Select value={line.kind} onValueChange={(v) => setLine(index, { kind: v as Line["kind"] })}>
									<SelectTrigger className="w-full"><SelectValue /></SelectTrigger>
									<SelectContent><SelectItem value="say">say</SelectItem><SelectItem value="emote">emote</SelectItem></SelectContent>
								</Select>
								<Textarea rows={2} value={line.text} onChange={(e) => setLine(index, { text: e.target.value })} aria-label={`Line ${index + 1}`} />
							</div>
						))}
					</div>
					{item.original && (
						<details>
							<summary className="cursor-pointer font-semibold text-gold">As first sent</summary>
							<ChatPreview className="mt-2" lines={item.original.lines} name={item.author} />
						</details>
					)}
					<Separator />
					<h3 className="text-lg font-bold">In chat</h3>
					<ChatPreview lines={story.lines} name={item.author} />
					<p className="text-sm text-muted-foreground">About {aboutSeconds(story.lines)} seconds.</p>
					<ul className="text-sm">
						{problems.length === 0
							? <li className="text-good">Passes the addon's rules.</li>
							: problems.map((p) => <li key={p.message} className="text-destructive">{p.message}</li>)}
					</ul>
				</CardContent>
			</Card>

			<Card>
				<CardHeader><CardTitle className="font-heading text-xl text-gold">Feature it the week of</CardTitle></CardHeader>
				<CardContent className="space-y-4">
					<div className="grid grid-cols-[repeat(auto-fill,minmax(140px,1fr))] gap-2">
						{weeks.map((w) => (
							<button key={w.week} type="button" onClick={() => setWeek(w.week)}
								className={cn("rounded-lg border p-2 text-left text-sm transition-colors hover:border-gold/70", w.week === week && "border-gold bg-accent")}>
								{shortWeek(w.week)}
								<span className={cn("block text-xs", w.count >= target.min ? "text-good" : "text-muted-foreground")}>{w.count} of {target.min} to {target.max}</span>
							</button>
						))}
					</div>
					<Textarea rows={2} placeholder="A note for the author (shown on their status page)" value={note} onChange={(e) => setNote(e.target.value)} />
					<div className="flex flex-wrap gap-2">
						<Button disabled={busy || !week} onClick={() => act("approve", { week })}><Check />Approve for this week</Button>
						<Button variant="outline" disabled={busy} onClick={() => act("update")}>Save edits</Button>
						<Button variant="destructive" disabled={busy} onClick={() => act("reject")}><X />Turn it away</Button>
						{item.status !== "pending" && <Button variant="outline" disabled={busy} onClick={() => act("pending")}><RotateCcw />Back to waiting</Button>}
					</div>
				</CardContent>
			</Card>
		</div>
	);
}

const NOTE_KINDS: Record<string, string> = { idea: "Idea", bug: "Bug", story: "Story request", other: "Other" };

function FeedbackList() {
	const [status, setStatus] = useState("new");
	const [notes, setNotes] = useState<Note[] | null>(null);
	const load = useCallback(() => {
		api<{ feedback: Note[] }>(`/api/admin/feedback?status=${status}`).then((d) => setNotes(d.feedback)).catch(() => setNotes([]));
	}, [status]);
	useEffect(() => { load(); }, [load]);
	const mark = async (note: Note, next: string) => {
		await post(`/api/admin/feedback/${note.id}`, { status: next });
		toast.success(next === "done" ? "Marked done" : "Moved back to new");
		load();
	};
	return (
		<div className="space-y-4">
			<Tabs value={status} onValueChange={setStatus}>
				<TabsList><TabsTrigger value="new">New</TabsTrigger><TabsTrigger value="done">Done</TabsTrigger></TabsList>
			</Tabs>
			{notes?.length === 0 && <Card><CardContent className="pt-6 text-muted-foreground">Nothing here.</CardContent></Card>}
			<div className="grid gap-4 md:grid-cols-2">
				{notes?.map((note) => (
					<Card key={note.id}>
						<CardHeader className="flex-row flex-wrap items-center gap-2">
							<Badge variant="outline">{NOTE_KINDS[note.kind] ?? note.kind}</Badge>
							{note.review && (
								<Badge variant="outline" className={cn(note.review.priority === "high" && "border-destructive/60 text-destructive", note.review.category === "spam" && "text-muted-foreground")}>
									{note.review.category.replace("_", " ")}, {note.review.priority}
								</Badge>
							)}
							<span className="text-sm text-muted-foreground">{new Date(note.created_at).toLocaleString()}{note.contact && ` · ${note.contact}`}{note.emailed && " · emailed"}</span>
						</CardHeader>
						<CardContent className="space-y-4">
							<p className="whitespace-pre-wrap">{note.message}</p>
							{note.review && (
								<div className="rounded-lg border bg-muted/40 p-3 text-sm">
									{note.review.summary && <p className="font-medium">{note.review.summary}</p>}
									{note.review.notes && <p className="mt-1 whitespace-pre-wrap text-muted-foreground">{note.review.notes}</p>}
									<p className="mt-2 text-xs text-muted-foreground">Reviewed by {note.reviewed_by}</p>
								</div>
							)}
							<Button size="sm" variant="outline" onClick={() => mark(note, note.status === "done" ? "new" : "done")}>
								{note.status === "done" ? "Move back to new" : "Mark done"}
							</Button>
						</CardContent>
					</Card>
				))}
			</div>
		</div>
	);
}

interface PostDraft { title: string; intro: string; highlights: { story_id: string; note: string }[]; status: "draft" | "published" }
const EMPTY_POST: PostDraft = { title: "", intro: "", highlights: [], status: "draft" };

// Each week's written post, shown above its stories once the week starts.
function PostsTab() {
	const [weeks, setWeeks] = useState<{ week: string; count: number; post: string | null }[]>([]);
	const [week, setWeek] = useState<string | null>(null);
	const [draft, setDraft] = useState<PostDraft>(EMPTY_POST);
	const [stories, setStories] = useState<Submission[]>([]);
	const [saved, setSaved] = useState<{ by: string; at: number } | null>(null);
	const [busy, setBusy] = useState(false);

	const loadWeeks = useCallback(async () => {
		const data = await api<{ weeks: { week: string; count: number; post: string | null }[] }>("/api/admin/weeks?past=8");
		setWeeks(data.weeks);
		setWeek((w) => w ?? data.weeks[8]?.week ?? data.weeks[0]?.week ?? null);
	}, []);
	useEffect(() => { loadWeeks().catch(() => toast.error("Couldn't load the weeks.")); }, [loadWeeks]);

	useEffect(() => {
		if (!week) return;
		setDraft(EMPTY_POST);
		setSaved(null);
		api<{ submissions: Submission[] }>(`/api/admin/submissions?week=${week}`).then((d) => setStories(d.submissions)).catch(() => setStories([]));
		api<{ post: PostDraft & { updated_by: string; updated_at: number } }>(`/api/admin/weeks/${week}/post`)
			.then(({ post: p }) => {
				setDraft({ title: p.title, intro: p.intro, highlights: p.highlights, status: p.status });
				setSaved({ by: p.updated_by, at: p.updated_at });
			})
			.catch(() => {});
	}, [week]);

	const save = async (status: PostDraft["status"]) => {
		if (!week) return;
		setBusy(true);
		try {
			const result = await api<{ post: PostDraft & { updated_by: string; updated_at: number } }>(`/api/admin/weeks/${week}/post`, {
				method: "PUT", body: JSON.stringify({ ...draft, status }),
			});
			setDraft((d) => ({ ...d, status: result.post.status }));
			setSaved({ by: result.post.updated_by, at: result.post.updated_at });
			toast.success(status === "published" ? "Published. It shows once the week starts." : "Saved as a draft");
			loadWeeks();
		} catch (e) {
			const problems = e instanceof ApiError ? (e.data.problems as string[] | undefined) : undefined;
			toast.error(problems?.join(" ") ?? (e instanceof Error ? e.message : "Couldn't save."));
		} finally {
			setBusy(false);
		}
	};
	const remove = async () => {
		if (!week || !saved) return;
		await api(`/api/admin/weeks/${week}/post`, { method: "DELETE" });
		setDraft(EMPTY_POST);
		setSaved(null);
		toast.success("Post removed");
		loadWeeks();
	};
	const setHighlight = (index: number, change: Partial<{ story_id: string; note: string }>) =>
		setDraft((d) => ({ ...d, highlights: d.highlights.map((h, i) => (i === index ? { ...h, ...change } : h)) }));

	return (
		<div className="grid items-start gap-6 lg:grid-cols-[minmax(220px,280px)_minmax(0,1fr)]">
			<div className="order-last space-y-2 lg:order-none">
				{weeks.map((w) => (
					<button key={w.week} type="button" onClick={() => setWeek(w.week)}
						className={cn("block w-full rounded-lg border bg-card p-3 text-left transition-colors hover:border-gold/70", w.week === week && "border-gold")}>
						<strong className="block">Week of {shortWeek(w.week)}</strong>
						<span className="text-sm text-muted-foreground">{w.count} stories · {w.post === "published" ? "post published" : w.post === "draft" ? "draft" : "no post"}</span>
					</button>
				))}
			</div>
			{week && (
				<Card>
					<CardHeader>
						<CardTitle className="font-heading text-2xl">Post for the week of {shortWeek(week)}</CardTitle>
						<p className="text-sm text-muted-foreground">
							Shown above the week's stories (on the home page while it's this week, then on its past week page).
							{saved && ` Last saved by ${saved.by} on ${new Date(saved.at).toLocaleString()}.`}
						</p>
					</CardHeader>
					<CardContent className="space-y-5">
						<div className="space-y-2">
							<Label htmlFor="post-title">Title</Label>
							<Input id="post-title" maxLength={120} value={draft.title} onChange={(e) => setDraft((d) => ({ ...d, title: e.target.value }))} className="h-11" />
						</div>
						<div className="space-y-2">
							<Label htmlFor="post-intro">Intro (a blank line between paragraphs, no links)</Label>
							<Textarea id="post-intro" rows={8} maxLength={4000} value={draft.intro} onChange={(e) => setDraft((d) => ({ ...d, intro: e.target.value }))} />
						</div>
						<div className="space-y-3">
							<Label>Highlights</Label>
							{draft.highlights.map((h, i) => (
								<div key={i} className="grid gap-2 sm:grid-cols-[minmax(0,14rem)_minmax(0,1fr)_auto]">
									<Select value={h.story_id} onValueChange={(v) => setHighlight(i, { story_id: v })}>
										<SelectTrigger className="h-11 w-full"><SelectValue placeholder="Pick a story" /></SelectTrigger>
										<SelectContent>{stories.map((s) => <SelectItem key={s.id} value={s.id}>{s.title}</SelectItem>)}</SelectContent>
									</Select>
									<Input maxLength={300} placeholder="Why it stands out" value={h.note} onChange={(e) => setHighlight(i, { note: e.target.value })} className="h-11" />
									<Button variant="ghost" size="lg" className="h-11" aria-label="Remove highlight"
										onClick={() => setDraft((d) => ({ ...d, highlights: d.highlights.filter((_, j) => j !== i) }))}><X /></Button>
								</div>
							))}
							{draft.highlights.length < 10 && stories.length > 0 && (
								<Button variant="outline" onClick={() => setDraft((d) => ({ ...d, highlights: [...d.highlights, { story_id: "", note: "" }] }))}>Add a highlight</Button>
							)}
							{stories.length === 0 && <p className="text-sm text-muted-foreground">No stories are approved for this week yet, so there's nothing to highlight.</p>}
						</div>
						<Separator />
						<div className="flex flex-wrap items-center gap-2">
							<Button disabled={busy} onClick={() => save("published")}><Check />{draft.status === "published" ? "Save" : "Publish"}</Button>
							<Button variant="outline" disabled={busy} onClick={() => save("draft")}>{draft.status === "published" ? "Back to draft" : "Save draft"}</Button>
							{saved && <Button variant="ghost" disabled={busy} onClick={remove}><RotateCcw />Remove post</Button>}
							<Badge variant="outline" className="ml-auto">{draft.status === "published" ? "Published" : "Draft"}</Badge>
						</div>
					</CardContent>
				</Card>
			)}
		</div>
	);
}

interface Overview {
	current_week: string;
	next_release: string;
	last_release: { version: string; released_at: number; stories: number } | null;
	target: { min: number; max: number };
	counts: Record<string, number>;
	weeks: { week: string; count: number; shipped: number; post: string | null; release: string | null }[];
	feedback: { open: number; high: number; unsorted: number };
	todo: string[];
}

// Everything at a glance: what's waiting, what's on its way to players, and what needs doing.
function OverviewTab({ onOpen }: { onOpen: (tab: string) => void }) {
	const [data, setData] = useState<Overview | null>(null);
	const [error, setError] = useState("");
	useEffect(() => { api<Overview>("/api/admin/overview").then(setData).catch((e) => setError(e instanceof Error ? e.message : "Couldn't load.")); }, []);
	if (error) return <p className="text-destructive">{error}</p>;
	if (!data) return <p className="text-muted-foreground">Loading…</p>;

	const stages = [
		{ key: "waiting", label: "Waiting for review", tab: "pending" },
		{ key: "scheduled", label: "Approved, not in a release yet", tab: "approved" },
		{ key: "in_addon", label: "In the addon, coming up", tab: "approved" },
		{ key: "featured", label: "Featured this week", tab: "approved" },
		{ key: "missed", label: "Missed their release", tab: "approved" },
	];
	const hours = Math.max(0, Math.round((Date.parse(data.next_release) - Date.now()) / 3600000));
	return (
		<div className="space-y-6">
			<Card>
				<CardHeader><CardTitle className="font-heading text-xl text-gold">To do</CardTitle></CardHeader>
				<CardContent>
					{data.todo.length === 0
						? <p className="text-good">Nothing needs doing right now.</p>
						: <ul className="list-disc space-y-1 pl-5">{data.todo.map((t) => <li key={t}>{t}</li>)}</ul>}
				</CardContent>
			</Card>

			<div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-5">
				{stages.map((s) => (
					<button key={s.key} type="button" onClick={() => onOpen(s.tab)}
						className={cn("rounded-xl border bg-card p-4 text-left transition-colors hover:border-gold/70", s.key === "missed" && data.counts.missed > 0 && "border-destructive/60")}>
						<span className="block text-3xl font-bold">{data.counts[s.key] ?? 0}</span>
						<span className="text-sm text-muted-foreground">{s.label}</span>
					</button>
				))}
			</div>

			<Card>
				<CardHeader>
					<CardTitle className="font-heading text-xl text-gold">The coming weeks</CardTitle>
					<p className="text-sm text-muted-foreground">
						Next release in {hours} hours ({new Date(data.next_release).toLocaleString()}).
						{data.last_release
							? ` Last release: v${data.last_release.version} on ${new Date(data.last_release.released_at).toLocaleDateString()}, with ${data.last_release.stories} community stories.`
							: " No release has reported in yet."}
						{" "}Feedback: {data.feedback.open} open, {data.feedback.high} high priority, {data.feedback.unsorted} unsorted.
					</p>
				</CardHeader>
				<CardContent className="overflow-x-auto">
					<table className="w-full min-w-[520px] text-left text-sm">
						<thead className="text-muted-foreground">
							<tr><th className="py-2 pr-4 font-medium">Week</th><th className="pr-4 font-medium">Stories</th><th className="pr-4 font-medium">In the addon</th><th className="font-medium">Post</th></tr>
						</thead>
						<tbody>
							{data.weeks.map((w, i) => (
								<tr key={w.week} className="border-t">
									<td className="py-2 pr-4">{shortWeek(w.week)}{i === 0 && <span className="text-gold"> (now)</span>}{i === 1 && <span className="text-muted-foreground"> (next)</span>}</td>
									<td className={cn("pr-4", w.count >= data.target.min ? "text-good" : w.count === 0 ? "text-muted-foreground" : "")}>{w.count} of {data.target.min} to {data.target.max}</td>
									<td className={cn("pr-4", w.count > 0 && w.shipped === w.count ? "text-good" : "text-muted-foreground")}>{w.count === 0 ? "-" : w.shipped === w.count ? "All" : `${w.shipped} of ${w.count}`}</td>
									<td className={w.post === "published" ? "text-good" : "text-muted-foreground"}>{w.post === "published" ? "Published" : w.post === "draft" ? "Draft" : "None"}</td>
								</tr>
							))}
						</tbody>
					</table>
				</CardContent>
			</Card>
		</div>
	);
}

