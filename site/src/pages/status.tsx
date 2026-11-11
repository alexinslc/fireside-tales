import { useEffect, useState } from "react";
import { useSearchParams } from "react-router";
import { Search } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { Page, PageTitle } from "@/components/layout";
import { api, post } from "@/lib/api";
import { weekName } from "@/lib/format";

interface Status { title: string; kind: string; status: string; week: string | null; note: string; emails: boolean }

const WORDS: Record<string, string> = {
	pending: "It's waiting for a review.",
	approved: "It's been approved!",
	rejected: "We weren't able to use it this time.",
};

export function StatusPage() {
	const [params] = useSearchParams();
	const [code, setCode] = useState((params.get("code") ?? "").toUpperCase());
	const [result, setResult] = useState<Status | null>(null);
	const [error, setError] = useState("");
	const [stopped, setStopped] = useState(false);

	const lookUp = async (value: string) => {
		setError("");
		try {
			setResult(await api<Status>(`/api/status/${encodeURIComponent(value)}`));
		} catch (e) {
			setResult(null);
			setError(e instanceof Error ? e.message : "Couldn't find it.");
		}
	};
	const stop = async (value: string) => {
		await post(`/api/status/${encodeURIComponent(value)}/stop`, {});
		setStopped(true);
		setResult((r) => (r ? { ...r, emails: false } : r));
	};

	// Links in emails land here with the code, and the stop link adds stop=1.
	useEffect(() => {
		const fromLink = (params.get("code") ?? "").toUpperCase();
		if (!fromLink) return;
		(params.get("stop") === "1" ? stop(fromLink) : Promise.resolve()).finally(() => lookUp(fromLink));
		// eslint-disable-next-line react-hooks/exhaustive-deps
	}, []);

	return (
		<Page className="max-w-2xl">
			<PageTitle title="Check on your story">Enter the code you got when you shared it.</PageTitle>
			<Card>
				<CardContent className="space-y-5 pt-6">
					<form className="flex flex-col gap-3 sm:flex-row sm:items-end" onSubmit={(e) => { e.preventDefault(); if (code.trim()) lookUp(code.trim()); }}>
						<div className="flex-1 space-y-2">
							<Label htmlFor="code">Your code</Label>
							<Input id="code" maxLength={11} autoComplete="off" placeholder="ABCDE-FGHJK" className="h-11 uppercase tracking-widest"
								value={code} onChange={(e) => setCode(e.target.value.toUpperCase())} />
						</div>
						<Button type="submit" size="lg" className="h-11 px-5"><Search />Look it up</Button>
					</form>
					{stopped && (
						<Alert><AlertTitle>Done. We've deleted your email address and won't write again.</AlertTitle></Alert>
					)}
					{error && <Alert variant="destructive"><AlertTitle>{error}</AlertTitle></Alert>}
					{result && (
						<Alert className={result.status === "approved" ? "border-good/60" : result.status === "rejected" ? "border-destructive/60" : ""}>
							<AlertTitle className="text-base">"{result.title}" ({result.kind}). {WORDS[result.status] ?? ""}</AlertTitle>
							<AlertDescription className="space-y-2 text-base text-foreground">
								{result.week && <p>It's featured the week of {weekName(result.week, true)}, in the addon's Community tab and on the home page.</p>}
								{result.note && <p><strong>A note for you:</strong> {result.note}</p>}
								{result.emails && (
									<div className="flex flex-wrap items-center gap-3 pt-1">
										<span>We'll email you when there's news.</span>
										<Button variant="outline" onClick={() => stop(code)}>Stop emails about this story</Button>
									</div>
								)}
							</AlertDescription>
						</Alert>
					)}
				</CardContent>
			</Card>
		</Page>
	);
}
