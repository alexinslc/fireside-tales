import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router";
import { CircleCheck, CircleAlert, Send } from "lucide-react";
import { LIMITS, findProblems, parseWriting, toWriting, tidyStory, storySeconds } from "@shared/rules.js";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { ChatPreview } from "@/components/chat";
import { Page, PageTitle } from "@/components/layout";
import { useTurnstile } from "@/components/turnstile";
import { ApiError, api, post, type Config, type Line } from "@/lib/api";
import { aboutSeconds } from "@/lib/format";

const DRAFT_KEY = "fireside-draft-v3";
const NO_RULESET = "none";

interface Draft { title: string; writing: string; author: string; ruleset: string; mood: string }

function loadDraft(): Draft {
	try {
		return { title: "", writing: "", author: "", ruleset: "", mood: "", ...JSON.parse(localStorage.getItem(DRAFT_KEY) ?? "{}") };
	} catch {
		return { title: "", writing: "", author: "", ruleset: "", mood: "" };
	}
}

export function SubmitPage() {
	const [draft, setDraft] = useState<Draft>(loadDraft);
	const [email, setEmail] = useState("");
	const [rulesets, setRulesets] = useState<string[]>([]);
	const [sending, setSending] = useState(false);
	const [error, setError] = useState<{ message: string; details: string[] } | null>(null);
	const [sent, setSent] = useState<{ receipt: string; title: string; emailed: boolean } | null>(null);
	const turnstile = useTurnstile();

	useEffect(() => { api<Config>("/api/config").then((c) => setRulesets(c.rulesets)).catch(() => {}); }, []);
	useEffect(() => { try { localStorage.setItem(DRAFT_KEY, JSON.stringify(draft)); } catch { /* drafts are a convenience */ } }, [draft]);

	const lines: Line[] = useMemo(() => parseWriting(draft.writing).lines, [draft.writing]);
	const story = useMemo(() => tidyStory({ kind: "story", ...draft, lines }), [draft, lines]);
	const problems = useMemo(() => findProblems(story, { moodOptional: true }), [story]);
	const started = Boolean(draft.title.trim() || lines.length);
	const limit = LIMITS.story.maxSeconds;
	const seconds = storySeconds(lines);

	// Text pasted in the game's format is tidied into the simple form.
	const changeWriting = (text: string) => {
		const parsed = parseWriting(text);
		if (parsed.title || /^\s*\**\s*(SAY|EMOTE)\s*\**\s*:/m.test(text)) {
			setDraft((d) => ({ ...d, writing: toWriting(parsed.lines), title: d.title.trim() ? d.title : parsed.title, mood: parsed.mood || d.mood }));
		} else {
			setDraft((d) => ({ ...d, writing: text }));
		}
	};
	const flip = (index: number) => {
		const next = lines.map((line, i) => (i === index ? { ...line, kind: line.kind === "emote" ? "say" : "emote" } as Line : line));
		setDraft((d) => ({ ...d, writing: toWriting(next) }));
	};

	const send = async (event: React.FormEvent) => {
		event.preventDefault();
		if (problems.length) {
			setError({ message: problems[0].message, details: [] });
			return;
		}
		setSending(true);
		setError(null);
		try {
			const result = await post<{ receipt: string }>("/api/submissions", {
				...story, notify_email: email.trim(), agree: true, turnstileToken: turnstile.token,
			});
			try { localStorage.removeItem(DRAFT_KEY); } catch { /* fine */ }
			setSent({ receipt: result.receipt, title: story.title, emailed: Boolean(email.trim()) });
		} catch (e) {
			const problemsFromServer = e instanceof ApiError && Array.isArray(e.data.problems)
				? (e.data.problems as { message: string }[]).map((p) => p.message) : [];
			setError({ message: e instanceof Error ? e.message : "That didn't go through.", details: problemsFromServer });
		} finally {
			setSending(false);
			turnstile.reset();
		}
	};

	if (sent) {
		return (
			<Page className="max-w-2xl">
				<Card>
					<CardHeader>
						<CardTitle className="font-heading text-2xl text-gold">Thank you!</CardTitle>
						<CardDescription className="text-base">"{sent.title}" is waiting at the fire. Every story is checked before it goes in the game.</CardDescription>
					</CardHeader>
					<CardContent className="space-y-4">
						<p>Your code: <span className="font-[family-name:var(--font-chat)] text-2xl font-bold tracking-widest text-gold">{sent.receipt}</span></p>
						<p>{sent.emailed
							? "We'll email you when it's approved and again when it's featured."
							: <><Link className="text-gold underline" to={`/status?code=${sent.receipt}`}>Check on it later</Link> with that code.</>}</p>
						<Button size="lg" className="h-11 px-5" onClick={() => { setSent(null); setDraft({ title: "", writing: "", author: draft.author, ruleset: draft.ruleset, mood: "" }); setEmail(""); }}>
							Share another
						</Button>
					</CardContent>
				</Card>
			</Page>
		);
	}

	return (
		<Page>
			<PageTitle title="Contribute a story">Write a tale or a rumor for players to tell at the fire. Each week we feature community stories in the addon's own tab.</PageTitle>
			<form onSubmit={send} noValidate className="grid items-start gap-6 lg:grid-cols-[minmax(0,1.2fr)_minmax(0,1fr)]">
				<Card>
					<CardContent className="space-y-6 pt-6">
						<div className="space-y-2">
							<Label htmlFor="title" className="text-base">Title</Label>
							<Input id="title" maxLength={60} autoComplete="off" placeholder="The Last Honest Merchant" className="h-11 text-base"
								value={draft.title} onChange={(e) => setDraft((d) => ({ ...d, title: e.target.value }))} />
						</div>
						<div className="space-y-2">
							<Label htmlFor="writing" className="text-base">Your story</Label>
							<p className="text-sm text-muted-foreground">One line for each chat message. Put actions in *asterisks*, and everything else is spoken. Or paste a story straight from the game.</p>
							<Textarea id="writing" rows={9} className="min-h-52 text-base"
								placeholder={"Ever met an honest merchant? I did, once. He sold me a mule and told me it was a terrible mule.\n*rolls up one sleeve to show an old scar*\nHe was not joking."}
								value={draft.writing} onChange={(e) => changeWriting(e.target.value)} />
						</div>
						<div className="grid gap-4 sm:grid-cols-2">
							<div className="space-y-2">
								<Label htmlFor="author">Character name <span className="font-normal text-muted-foreground">(optional)</span></Label>
								<Input id="author" maxLength={30} autoComplete="off" placeholder="Anonymous" className="h-11"
									value={draft.author} onChange={(e) => setDraft((d) => ({ ...d, author: e.target.value }))} />
							</div>
							<div className="space-y-2">
								<Label htmlFor="ruleset">Ruleset <span className="font-normal text-muted-foreground">(optional)</span></Label>
								<Select value={draft.ruleset || NO_RULESET} onValueChange={(v) => setDraft((d) => ({ ...d, ruleset: v === NO_RULESET ? "" : v }))}>
									<SelectTrigger id="ruleset" className="h-11 w-full"><SelectValue /></SelectTrigger>
									<SelectContent>
										<SelectItem value={NO_RULESET}>Not saying</SelectItem>
										{rulesets.map((r) => <SelectItem key={r} value={r}>{r}</SelectItem>)}
									</SelectContent>
								</Select>
							</div>
						</div>
						<div className="space-y-2">
							<Label htmlFor="notify-email">Email me when it's featured <span className="font-normal text-muted-foreground">(optional)</span></Label>
							<Input id="notify-email" type="email" maxLength={254} autoComplete="email" placeholder="you@example.com" className="h-11"
								value={email} onChange={(e) => setEmail(e.target.value)} />
							<p className="text-sm text-muted-foreground">At most two short emails: when it's approved and when its week starts. We delete your address after that, and never show it to anyone.</p>
						</div>
						<div ref={turnstile.ref} />
						{error && (
							<Alert variant="destructive">
								<CircleAlert />
								<AlertTitle>{error.message}</AlertTitle>
								{error.details.length > 0 && <AlertDescription><ul className="list-disc pl-5">{error.details.map((d) => <li key={d}>{d}</li>)}</ul></AlertDescription>}
							</Alert>
						)}
						<div className="space-y-3">
							<Button type="submit" size="lg" disabled={sending} className="h-11 px-6 text-base">
								<Send />{sending ? "Sending..." : "Send it to the fire"}
							</Button>
							<p className="text-sm text-muted-foreground">
								By sending it, you're saying it's your own writing and we can share it in Fireside Tales under the addon's{" "}
								<a className="text-gold underline" href="https://github.com/alexinslc/fireside-tales/blob/main/LICENSE">MIT license</a>. We may tidy a line or two.
							</p>
						</div>
					</CardContent>
				</Card>

				<Card className="lg:sticky lg:top-24">
					<CardHeader>
						<CardTitle className="font-heading text-xl text-gold">How it looks</CardTitle>
						<CardDescription>Got a line the wrong way round? Click it to switch between spoken and action.</CardDescription>
					</CardHeader>
					<CardContent className="space-y-4">
						<ChatPreview lines={lines} name={draft.author} onFlip={flip} />
						{lines.length > 0 && (
							<div className="space-y-1.5">
								<div className="h-2 overflow-hidden rounded-full border bg-black/40" aria-hidden="true">
									<div className={Math.round(seconds) > limit ? "h-full bg-destructive" : "h-full bg-gradient-to-r from-gold to-ember"}
										style={{ width: `${Math.min(100, (seconds / limit) * 100)}%` }} />
								</div>
								<p className="text-sm text-muted-foreground">About {aboutSeconds(lines)} seconds to tell. Keep it under {limit}.</p>
							</div>
						)}
						{started && (
							<ul className="space-y-1.5 text-sm">
								{problems.length === 0
									? <li className="flex items-center gap-2 text-good"><CircleCheck className="size-4" />Ready to send.</li>
									: problems.map((p) => <li key={p.message} className="flex items-start gap-2 text-destructive"><CircleAlert className="mt-0.5 size-4 shrink-0" />{p.message}</li>)}
							</ul>
						)}
					</CardContent>
				</Card>
			</form>
		</Page>
	);
}
