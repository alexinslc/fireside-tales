import { NavLink, Outlet, Link } from "react-router";
import { cn } from "@/lib/utils";

const NAV = [
	{ to: "/", label: "Home", end: true },
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
			<h1 className="mb-3 text-4xl leading-tight sm:text-6xl">{title}</h1>
			{children && <div className="text-lg text-muted-foreground">{children}</div>}
		</div>
	);
}

export function Layout() {
	return (
		<div className="flex min-h-screen flex-col">
			<header className="sticky top-0 z-20 border-b border-black bg-[#06080f]/92 shadow-[0_1px_0_#2a2f3c] backdrop-blur">
				<div className="mx-auto flex min-h-14 w-full max-w-6xl flex-wrap items-center gap-x-6 gap-y-1 px-4 py-2">
					<Link to="/" className="flex items-center gap-2.5 font-heading text-[22px] text-[#f4ecd8] no-underline">
						<img src="/img/icon.png" alt="" className="size-9 rounded-[3px] shadow-[0_0_0_1px_#000,0_0_0_2px_#6f7484]" />
						Fireside Tales
					</Link>
					{/* One scrolling row on a phone, so the header stays short. */}
					<nav aria-label="Main" className="-mx-4 flex w-[calc(100%+2rem)] gap-x-5 overflow-x-auto px-4 font-[family-name:var(--font-ui)] text-[15px] whitespace-nowrap [scrollbar-width:none] sm:mx-0 sm:ml-auto sm:w-auto sm:overflow-visible sm:px-0">
						{NAV.map((item) => (
							<NavLink
								key={item.to}
								to={item.to}
								end={item.end}
								className={({ isActive }) => cn("py-1 no-underline transition-colors hover:text-[#ffd100]", isActive ? "text-[#ffd100]" : "text-[#cfc9b8]")}
							>
								{item.label}
							</NavLink>
						))}
					</nav>
				</div>
			</header>
			<main className="flex-1"><Outlet /></main>
			<footer className="border-t border-black shadow-[inset_0_1px_0_#2a2f3c]">
				<div className="mx-auto w-full max-w-6xl space-y-1 px-4 py-8 font-[family-name:var(--font-ui)] text-sm text-muted-foreground">
					<p>Fireside Tales is a free fan addon for World of Warcraft: Forever. It isn't affiliated with or endorsed by Blizzard Entertainment.</p>
					<p>
						<a className="text-[#ffd100] hover:underline" href="https://www.curseforge.com/wow/addons/fireside-tales">Get the addon on CurseForge</a>
						{" · "}
						<a className="text-[#ffd100] hover:underline" href="https://github.com/death-walrus-studios/fireside-tales">GitHub</a>
						{" · "}
						<a className="text-[#ffd100] hover:underline" href="https://discord.gg/GyrhmXnQTW">Discord</a>
						{" · "}
						<Link className="text-[#ffd100] hover:underline" to="/feedback">Send feedback</Link>
					</p>
				</div>
			</footer>
		</div>
	);
}
