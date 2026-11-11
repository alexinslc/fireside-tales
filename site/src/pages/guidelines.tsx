import { Link } from "react-router";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Page, PageTitle } from "@/components/layout";

const GOOD = [
	["It makes sense heard once.", "People hear each line once, in order. Name who \"he\" is, and set up anything the ending calls back to."],
	["It works sitting down.", "You'll be seated at the fire, so actions are hands, face, and looks, like *leans in* or *glances over one shoulder*. No standing up, walking, or kneeling."],
	["Actions are about you.", "Never say what the listeners do or feel."],
	["Anyone can tell it.", "Any race, class, or faction should be able to tell it unless that's the point, and don't assume the teller's gender."],
	["It's short.", "A story is 3 to 8 lines and under a minute. A rumor is 3 or 4 lines, sounds like hearsay (\"They say...\"), and ends with a twist."],
	["It fits Azeroth.", "Invented people and small places are welcome. Keep real lore right."],
];

const NOT_OK = [
	"Anything sexual beyond PG-13. Romance and a little innuendo are fine.",
	"Hate, slurs, or harassment, or stories about real people, other players, streamers, or guilds by name.",
	"Graphic gore. Dark and spooky are welcome; dwell on dread, not wounds.",
	"Personal information, links, ads, or gold selling.",
	"Writing that isn't yours, including Blizzard's quest text, books, or songs. Retell the world in your own words.",
	"Stories that aren't in English, for now.",
];

const AFTER = [
	"It's checked against these guidelines, and given a mood if you didn't pick one.",
	"We may fix a typo or trim a line, and we'll leave you a note if we can't use it.",
	"Approved stories are scheduled for a week. Each week, up to 100 go into the addon's Community tab, credited to your character name and ruleset if you gave them, or anonymous if not.",
];

export function GuidelinesPage() {
	return (
		<Page className="max-w-3xl">
			<PageTitle title="Guidelines">Everything here is said out loud in game chat, where anyone nearby can read it. These rules keep the fire a good place to sit.</PageTitle>
			<div className="space-y-6">
				<Card>
					<CardHeader><CardTitle className="font-heading text-2xl text-gold">What makes a good story</CardTitle></CardHeader>
					<CardContent>
						<ul className="space-y-3">
							{GOOD.map(([lead, rest]) => <li key={lead}><strong>{lead}</strong> {rest}</li>)}
						</ul>
					</CardContent>
				</Card>
				<Card>
					<CardHeader><CardTitle className="font-heading text-2xl text-gold">What we can't accept</CardTitle></CardHeader>
					<CardContent><ul className="list-disc space-y-2 pl-5">{NOT_OK.map((item) => <li key={item}>{item}</li>)}</ul></CardContent>
				</Card>
				<Card>
					<CardHeader><CardTitle className="font-heading text-2xl text-gold">What happens after you share</CardTitle></CardHeader>
					<CardContent className="space-y-4">
						<ol className="space-y-4">
							{AFTER.map((step, i) => (
								<li key={step} className="flex gap-4">
									<span className="grid size-8 shrink-0 place-items-center rounded-full border font-heading text-gold">{i + 1}</span>
									<span>{step}</span>
								</li>
							))}
						</ol>
						<p className="text-muted-foreground">Sharing a story means you wrote it and are happy for it to be part of Fireside Tales under the addon's{" "}
							<a className="text-gold underline" href="https://github.com/alexinslc/fireside-tales/blob/main/LICENSE">MIT license</a>.
							We only keep an email if you give us one, and delete it once we've let you know.</p>
					</CardContent>
				</Card>
				<Button asChild size="lg" className="h-11 px-5"><Link to="/submit">Contribute a story</Link></Button>
			</div>
		</Page>
	);
}
