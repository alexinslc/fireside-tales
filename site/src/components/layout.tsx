import { NavLink, Outlet, Link } from "react-router";
import { cn } from "@/lib/utils";

const NAV = [
	{ to: "/", label: "This week", end: true },
	{ to: "/past", label: "Past weeks" },
	{ to: "/submit", label: "Contribute a story" },
	{ to: "/guidelines", label: "Guidelines" },
	{ to: "/status", label: "Check on yours" },
	{ to: "/feedback", label: "Feedback" },
];

export function Page({ children, className }: { children: React.ReactNode; className?: string }) {
	return <div className={cn("mx-auto w-full max-w-6xl px-4 py-10", className)}>{children}</div>;
}

export function PageTitle({ title, children }: { title: string; children?: React.ReactNode }) {
	return (
		<div className="mb-8 max-w-3xl">
			<h1 className="mb-3 text-4xl font-bold sm:text-5xl">{title}</h1>
			{children && <div className="text-lg text-muted-foreground">{children}</div>}
		</div>
	);
}

export function Layout() {
	return (
		<div className="flex min-h-screen flex-col">
			<header className="sticky top-0 z-20 border-b bg-background/85 backdrop-blur">
				<div className="mx-auto flex min-h-16 w-full max-w-6xl flex-wrap items-center gap-x-6 gap-y-2 px-4 py-2">
					<Link to="/" className="flex items-center gap-2.5 font-heading text-lg font-bold text-gold no-underline">
						<img src="/img/icon.png" alt="" className="size-9 rounded-full border border-border" />
						Fireside Tales
					</Link>
					<nav aria-label="Main" className="flex flex-wrap gap-x-5 gap-y-1 sm:ml-auto">
						{NAV.map((item) => (
							<NavLink
								key={item.to}
								to={item.to}
								end={item.end}
								className={({ isActive }) => cn("py-1 font-medium no-underline transition-colors hover:text-gold", isActive ? "text-gold" : "text-foreground")}
							>
								{item.label}
							</NavLink>
						))}
					</nav>
				</div>
			</header>
			<main className="flex-1"><Outlet /></main>
			<footer className="border-t">
				<div className="mx-auto w-full max-w-6xl space-y-1 px-4 py-8 text-sm text-muted-foreground">
					<p>Fireside Tales is a free fan addon for World of Warcraft: Forever. It isn't affiliated with or endorsed by Blizzard Entertainment.</p>
					<p>
						<a className="text-gold hover:underline" href="https://www.curseforge.com/wow/addons/fireside-tales">Get the addon on CurseForge</a>
						{" · "}
						<a className="text-gold hover:underline" href="https://github.com/alexinslc/fireside-tales">GitHub</a>
						{" · "}
						<Link className="text-gold hover:underline" to="/feedback">Send feedback</Link>
					</p>
				</div>
			</footer>
		</div>
	);
}
