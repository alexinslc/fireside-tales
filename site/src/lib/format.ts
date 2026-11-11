import { storySeconds } from "@shared/rules.js";
import type { Line, Story } from "./api";

export function aboutSeconds(lines: Line[]): number {
	return Math.max(5, Math.round(storySeconds(lines) / 5) * 5);
}

export function credit(story: Pick<Story, "author" | "ruleset">): string {
	if (story.author && story.ruleset) return `by ${story.author}, ${story.ruleset}`;
	if (story.author) return `by ${story.author}`;
	return "shared anonymously";
}

export function weekName(week: string, withYear = false): string {
	return new Date(`${week}T12:00:00Z`).toLocaleDateString(undefined, {
		month: "long", day: "numeric", ...(withYear ? { year: "numeric" } : {}), timeZone: "UTC",
	});
}

export function capitalize(text: string): string {
	return text ? text[0].toUpperCase() + text.slice(1) : text;
}
