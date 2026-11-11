import { useEffect, useRef, useState } from "react";
import { api, type Config } from "@/lib/api";

declare global {
	interface Window {
		turnstile?: {
			render: (el: HTMLElement, options: Record<string, unknown>) => string;
			reset: (id: string) => void;
		};
	}
}

// Cloudflare's bot check. It usually passes without a click, and only asks when
// something looks off. Returns the current token and a reset for after a send.
export function useTurnstile() {
	const ref = useRef<HTMLDivElement>(null);
	const widget = useRef<string | null>(null);
	const [token, setToken] = useState("");

	useEffect(() => {
		let stopped = false;
		let timer: ReturnType<typeof setInterval> | undefined;
		api<Config>("/api/config").then((config) => {
			const tryRender = () => {
				if (stopped || !window.turnstile || !ref.current || !config.turnstileSiteKey) return false;
				widget.current = window.turnstile.render(ref.current, {
					sitekey: config.turnstileSiteKey,
					theme: "dark",
					appearance: "interaction-only",
					callback: (value: string) => setToken(value),
					"expired-callback": () => setToken(""),
				});
				return true;
			};
			if (!tryRender()) {
				timer = setInterval(() => { if (tryRender()) clearInterval(timer); }, 300);
				setTimeout(() => clearInterval(timer), 15000);
			}
		}).catch(() => {});
		return () => { stopped = true; clearInterval(timer); };
	}, []);

	const reset = () => {
		setToken("");
		if (window.turnstile && widget.current) window.turnstile.reset(widget.current);
	};
	return { ref, token, reset };
}
