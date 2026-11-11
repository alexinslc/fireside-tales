import { useState } from "react";
import { Link } from "react-router";
import { Check, Copy, Link2 } from "lucide-react";
import { toPaste } from "@shared/rules.js";
import { Button } from "@/components/ui/button";
import { ChatPreview, MoodDot } from "@/components/chat";
import { aboutSeconds, capitalize, credit, weekName } from "@/lib/format";
import type { Story } from "@/lib/api";

// One story in a past week's post, or in search results. Its id is its anchor, so a
// search result can link straight to it. Past stories can be copied into Write Your
// Tales to tell again.
export function StoryEntry({ story, showWeek = false }: { story: Story; showWeek?: boolean }) {
	const [copied, setCopied] = useState<"no" | "yes" | "failed">("no");
	const copy = async () => {
		try {
			await navigator.clipboard.writeText(toPaste(story));
			setCopied("yes");
		} catch {
			setCopied("failed");
		}
	};
	const anchor = `/past/${story.week}#${story.id}`;
	return (
		<article id={story.id} className="scroll-mt-24 border-b border-border/60 py-8 first:pt-0 last:border-b-0">
			<h2 className="mb-1 font-heading text-2xl font-bold text-gold">{story.title}</h2>
			<p className="mb-4 flex flex-wrap items-center gap-x-2 gap-y-1 text-sm text-muted-foreground">
				<span className="flex items-center gap-1.5"><MoodDot mood={story.mood} />{capitalize(story.mood)} {story.kind}</span>
				<span aria-hidden>·</span>
				<span>about {aboutSeconds(story.lines)} seconds</span>
				<span aria-hidden>·</span>
				<span>{credit(story)}</span>
				{showWeek && story.week && (
					<>
						<span aria-hidden>·</span>
						<Link to={anchor} className="text-gold hover:underline">the week of {weekName(story.week, true)}</Link>
					</>
				)}
			</p>
			<ChatPreview lines={story.lines} name={story.author} />
			<div className="mt-4 flex flex-wrap gap-2">
				<Button variant="outline" onClick={copy}>
					{copied === "yes" ? <Check /> : <Copy />}
					{copied === "yes" ? "Copied! Paste it into Write Your Tales" : copied === "failed" ? "Couldn't copy it" : "Copy for the game"}
				</Button>
				{!showWeek && (
					<Button variant="ghost" asChild>
						<a href={anchor} aria-label={`Link to ${story.title}`}><Link2 />Link</a>
					</Button>
				)}
			</div>
		</article>
	);
}
