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
		<section className="parchment mb-10 max-w-3xl px-6 py-7 sm:px-9">
			<h2 className="mb-4 text-4xl">{post.title}</h2>
			<div className="space-y-4 text-lg leading-relaxed">
				{post.intro.split(/\n\n/).map((paragraph, i) => <p key={i} className="whitespace-pre-line">{paragraph}</p>)}
			</div>
			{picks.length > 0 && (
				<div className="mt-6">
					<h3 className="rule-title mb-3 text-2xl">Highlights</h3>
					<ul className="space-y-2">
						{picks.map(({ story, note }) => (
							<li key={story.id}>
								<a href={`#${story.id}`} className="font-bold underline">{story.title}</a>
								<span className="text-[#6b4c22]"> {credit(story)}</span>
								{note && <span>: {note}</span>}
							</li>
						))}
					</ul>
				</div>
			)}
		</section>
	);
}
