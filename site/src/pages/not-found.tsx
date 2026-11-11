import { Link } from "react-router";
import { Button } from "@/components/ui/button";
import { Page, PageTitle } from "@/components/layout";

export function NotFoundPage() {
	return (
		<Page className="max-w-2xl">
			<PageTitle title="This trail goes cold">Whatever was here has wandered off into the dark. Back to the fire?</PageTitle>
			<Button asChild size="lg" className="h-11 px-5"><Link to="/">Back to the fire</Link></Button>
		</Page>
	);
}
