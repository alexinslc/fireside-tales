// Small helpers for talking to the site's own API.
export class ApiError extends Error {
	constructor(message: string, readonly status: number, readonly data: Record<string, unknown>) {
		super(message);
	}
}

export async function api<T>(path: string, init: RequestInit = {}): Promise<T> {
	const response = await fetch(path, {
		...init,
		headers: { "content-type": "application/json", ...(init.headers ?? {}) },
	});
	const data = (await response.json().catch(() => ({}))) as Record<string, unknown>;
	if (!response.ok) throw new ApiError(String(data.error ?? `Something went wrong (${response.status}).`), response.status, data);
	return data as T;
}

export function post<T>(path: string, body: unknown): Promise<T> {
	return api<T>(path, { method: "POST", body: JSON.stringify(body) });
}

export interface Line { kind: "say" | "emote"; text: string }

export interface Story {
	id: string;
	kind: "story" | "rumor";
	title: string;
	mood: string;
	lines: Line[];
	author: string;
	ruleset: string;
	week: string | null;
}

export interface Config { turnstileSiteKey: string; rulesets: string[]; week: string }
