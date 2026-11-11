import { credit } from "@/lib/format";
import type { Story } from "@/lib/api";

export interface PublicPost { title: string; intro: string; highlights: { story_id: string; note: string }[] }

// A week's written post, above its stories. Highlights link down to the story itself.
export function WeekPost({ post, stories }: { post: PublicPost; stories: Story[] }) {
	const byId = new Map(stories.map((s) => [s.id, s]));
	const picks = post.highlights.flatMap((h) => {
		const story = byId.get(h.story_id);
		return story ? [{ story, note: h.note }] : [];
	});
	return (
		<section className="mb-10 max-w-3xl">
			<h2 className="mb-4 text-3xl font-bold">{post.title}</h2>
			<div className="space-y-4 text-lg leading-relaxed">
				{post.intro.split(/\n\n/).map((paragraph, i) => <p key={i} className="whitespace-pre-line">{paragraph}</p>)}
			</div>
			{picks.length > 0 && (
				<div className="mt-6 rounded-xl border bg-card/60 p-5">
					<h3 className="mb-3 font-heading text-lg font-bold text-gold">Highlights</h3>
					<ul className="space-y-2">
						{picks.map(({ story, note }) => (
							<li key={story.id}>
								<a href={`#${story.id}`} className="font-semibold text-gold hover:underline">{story.title}</a>
								<span className="text-muted-foreground"> {credit(story)}</span>
								{note && <span>: {note}</span>}
							</li>
						))}
					</ul>
				</div>
			)}
		</section>
	);
}
