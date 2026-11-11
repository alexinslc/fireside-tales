import { Search, X } from "lucide-react";
import { MOODS, RULESETS } from "@shared/rules.js";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { MoodDot } from "@/components/chat";
import { capitalize } from "@/lib/format";
import type { Story } from "@/lib/api";

export interface Filters { q: string; mood: string; kind: string; ruleset: string }
export const NO_FILTERS: Filters = { q: "", mood: "", kind: "", ruleset: "" };
const ANY = "any";

export function isFiltering(filters: Filters): boolean {
	return Boolean(filters.q.trim() || filters.mood || filters.kind || filters.ruleset);
}

// The same matching the server's search does, for filtering one week in the browser.
export function matches(story: Story, filters: Filters): boolean {
	if (filters.mood && story.mood !== filters.mood) return false;
	if (filters.kind && story.kind !== filters.kind) return false;
	if (filters.ruleset && story.ruleset !== filters.ruleset) return false;
	const text = [story.title, story.author, ...story.lines.map((l) => l.text)].join(" ").toLowerCase();
	return filters.q.toLowerCase().split(/\s+/).filter(Boolean).every((word) => text.includes(word));
}

function Choice({ label, value, onChange, options }: {
	label: string;
	value: string;
	onChange: (value: string) => void;
	options: { value: string; label: React.ReactNode }[];
}) {
	return (
		<Select value={value || ANY} onValueChange={(v) => onChange(v === ANY ? "" : v)}>
			<SelectTrigger aria-label={label} className="h-11 w-full sm:w-36"><SelectValue /></SelectTrigger>
			<SelectContent>
				<SelectItem value={ANY}>{label}: any</SelectItem>
				{options.map((o) => <SelectItem key={o.value} value={o.value}>{o.label}</SelectItem>)}
			</SelectContent>
		</Select>
	);
}

export function PastFilters({ filters, onChange, placeholder }: {
	filters: Filters;
	onChange: (filters: Filters) => void;
	placeholder: string;
}) {
	const set = (key: keyof Filters) => (value: string) => onChange({ ...filters, [key]: value });
	return (
		<div className="mb-8 flex flex-col gap-3 sm:flex-row sm:flex-wrap sm:items-center">
			<div className="relative sm:min-w-56 sm:flex-1">
				<Search className="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground" />
				<Input
					type="search"
					aria-label="Search stories"
					placeholder={placeholder}
					value={filters.q}
					onChange={(e) => set("q")(e.target.value)}
					className="h-11 pl-9"
				/>
			</div>
			<Choice label="Mood" value={filters.mood} onChange={set("mood")}
				options={MOODS.map((m) => ({ value: m, label: <span className="flex items-center gap-2"><MoodDot mood={m} />{capitalize(m)}</span> }))} />
			<Choice label="Kind" value={filters.kind} onChange={set("kind")}
				options={[{ value: "story", label: "Stories" }, { value: "rumor", label: "Rumors" }]} />
			<Choice label="Ruleset" value={filters.ruleset} onChange={set("ruleset")}
				options={RULESETS.map((r) => ({ value: r, label: r }))} />
			{isFiltering(filters) && (
				<Button variant="ghost" size="lg" className="h-11" onClick={() => onChange(NO_FILTERS)}><X />Clear</Button>
			)}
		</div>
	);
}

// Filters live in the address, so a search can be shared or bookmarked.
export function filtersFrom(params: URLSearchParams): Filters {
	return { q: params.get("q") ?? "", mood: params.get("mood") ?? "", kind: params.get("kind") ?? "", ruleset: params.get("ruleset") ?? "" };
}

export function filtersTo(filters: Filters): Record<string, string> {
	return Object.fromEntries(Object.entries(filters).filter(([, v]) => v));
}
