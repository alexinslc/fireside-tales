import { StrictMode, useEffect } from "react";
import { createRoot } from "react-dom/client";
import { BrowserRouter, Route, Routes, useLocation } from "react-router";
import { Toaster } from "@/components/ui/sonner";
import { Layout } from "@/components/layout";
import { HomePage } from "@/pages/home";
import { PastPage } from "@/pages/past";
import { PastWeekPage } from "@/pages/past-week";
import { SubmitPage } from "@/pages/submit";
import { StatusPage } from "@/pages/status";
import { GuidelinesPage } from "@/pages/guidelines";
import { FeedbackPage } from "@/pages/feedback";
import { AdminPage } from "@/pages/admin";
import { NotFoundPage } from "@/pages/not-found";
import "./index.css";

const TITLES: Record<string, string> = {
	"/": "Fireside Tales · Stories for the campfire",
	"/past": "Past Weeks · Fireside Tales",
	"/submit": "Contribute a Story · Fireside Tales",
	"/status": "Check on Your Story · Fireside Tales",
	"/guidelines": "Guidelines · Fireside Tales",
	"/feedback": "Feedback · Fireside Tales",
	"/admin": "Story Review · Fireside Tales",
};

// Each page gets its own title, and starts at the top.
function PageChrome() {
	const { pathname } = useLocation();
	useEffect(() => {
		// Week pages set their own title once they know the date.
		if (!pathname.startsWith("/past/")) document.title = TITLES[pathname.replace(/\/$/, "") || "/"] ?? "Fireside Tales";
		if (!window.location.hash) window.scrollTo(0, 0);
	}, [pathname]);
	return null;
}

createRoot(document.getElementById("root")!).render(
	<StrictMode>
		<BrowserRouter>
			<PageChrome />
			<Routes>
				<Route element={<Layout />}>
					<Route index element={<HomePage />} />
					<Route path="past" element={<PastPage />} />
					<Route path="past/:week" element={<PastWeekPage />} />
					<Route path="submit" element={<SubmitPage />} />
					<Route path="status" element={<StatusPage />} />
					<Route path="guidelines" element={<GuidelinesPage />} />
					<Route path="feedback" element={<FeedbackPage />} />
					<Route path="admin" element={<AdminPage />} />
					<Route path="*" element={<NotFoundPage />} />
				</Route>
			</Routes>
		</BrowserRouter>
		<Toaster />
	</StrictMode>,
);
