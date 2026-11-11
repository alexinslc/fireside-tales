import { useState } from "react";
import { CircleAlert, Send } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { Alert, AlertTitle } from "@/components/ui/alert";
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group";
import { Page, PageTitle } from "@/components/layout";
import { useTurnstile } from "@/components/turnstile";
import { post } from "@/lib/api";

const KINDS = [
	{ value: "idea", label: "An idea" },
	{ value: "bug", label: "Something's broken" },
	{ value: "story", label: "A story I'd love to see" },
	{ value: "other", label: "Something else" },
];

export function FeedbackPage() {
	const [kind, setKind] = useState("idea");
	const [message, setMessage] = useState("");
	const [contact, setContact] = useState("");
	const [sending, setSending] = useState(false);
	const [error, setError] = useState("");
	const [sent, setSent] = useState(false);
	const turnstile = useTurnstile();

	const send = async (event: React.FormEvent) => {
		event.preventDefault();
		if (message.trim().length < 3) {
			setError("Tell us a little more.");
			return;
		}
		setSending(true);
		setError("");
		try {
			await post("/api/feedback", { kind, message, contact, turnstileToken: turnstile.token });
			setSent(true);
		} catch (e) {
			setError(e instanceof Error ? e.message : "That didn't go through.");
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
						<CardDescription className="text-base">We read every note. {contact.trim() ? "If we have a question, we'll get in touch." : ""}</CardDescription>
					</CardHeader>
					<CardContent>
						<Button size="lg" variant="outline" onClick={() => { setSent(false); setMessage(""); }}>Send another</Button>
					</CardContent>
				</Card>
			</Page>
		);
	}

	return (
		<Page className="max-w-2xl">
			<PageTitle title="Feedback">Ideas for the addon or the site, something that's broken, or a story you wish someone would write. We'd love to hear it.</PageTitle>
			<Card>
				<CardContent className="pt-6">
					<form onSubmit={send} noValidate className="space-y-6">
						<div className="space-y-3">
							<Label className="text-base">What's it about?</Label>
							<RadioGroup value={kind} onValueChange={setKind} className="grid gap-2 sm:grid-cols-2">
								{KINDS.map((k) => (
									<Label key={k.value} htmlFor={`kind-${k.value}`}
										className="flex min-h-11 cursor-pointer items-center gap-3 rounded-lg border px-3 font-normal has-[[data-state=checked]]:border-gold has-[[data-state=checked]]:bg-accent">
										<RadioGroupItem id={`kind-${k.value}`} value={k.value} />{k.label}
									</Label>
								))}
							</RadioGroup>
						</div>
						<div className="space-y-2">
							<Label htmlFor="message" className="text-base">Your note</Label>
							<Textarea id="message" rows={6} maxLength={2000} className="min-h-36 text-base" placeholder="It would be great if..."
								value={message} onChange={(e) => setMessage(e.target.value)} />
						</div>
						<div className="space-y-2">
							<Label htmlFor="contact">How to reach you <span className="font-normal text-muted-foreground">(optional)</span></Label>
							<Input id="contact" maxLength={120} autoComplete="off" placeholder="Character name or email" className="h-11"
								value={contact} onChange={(e) => setContact(e.target.value)} />
							<p className="text-sm text-muted-foreground">Only if you'd like a reply. It stays private.</p>
						</div>
						<div ref={turnstile.ref} />
						{error && <Alert variant="destructive"><CircleAlert /><AlertTitle>{error}</AlertTitle></Alert>}
						<Button type="submit" size="lg" disabled={sending} className="h-11 px-6 text-base">
							<Send />{sending ? "Sending..." : "Send feedback"}
						</Button>
					</form>
				</CardContent>
			</Card>
		</Page>
	);
}
