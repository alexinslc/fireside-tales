import { Page, PageTitle } from "@/components/layout";
import { SubmitForm } from "@/components/submit-form";

export function SubmitPage() {
	return (
		<Page>
			<PageTitle title="Contribute a story">Write a tale or a rumor for players to tell at the fire. Approved stories are featured for a week in the addon's Community tab, with your name on them.</PageTitle>
			<SubmitForm />
		</Page>
	);
}
