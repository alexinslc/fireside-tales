// Reviewer sign-in. Cloudflare Access puts a signed token on every request to /admin
// and /api/admin; this checks the signature, the audience, and that the email is on
// the reviewer list, so the API stays closed even if Access were misconfigured.
// Scripts sign in with an Access service token instead of an email: they send its
// CF-Access-Client-Id and CF-Access-Client-Secret headers, and Access signs a token
// whose common_name is the client ID. REVIEW_TOKENS names the ones allowed in.
import type { Env } from "./index";

interface Jwk extends JsonWebKey { kid: string }

let cachedKeys: { at: number; keys: Jwk[] } | null = null;

async function accessKeys(teamDomain: string): Promise<Jwk[]> {
	if (cachedKeys && Date.now() - cachedKeys.at < 60 * 60 * 1000) return cachedKeys.keys;
	const response = await fetch(`https://${teamDomain}/cdn-cgi/access/certs`);
	const data = (await response.json()) as { keys: Jwk[] };
	cachedKeys = { at: Date.now(), keys: data.keys };
	return data.keys;
}

function decodePart(part: string): Uint8Array<ArrayBuffer> {
	const base64 = part.replace(/-/g, "+").replace(/_/g, "/").padEnd(Math.ceil(part.length / 4) * 4, "=");
	const binary = atob(base64);
	const bytes = new Uint8Array(new ArrayBuffer(binary.length));
	for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
	return bytes;
}

// True only for the dev server on this computer. Cloudflare routes live requests by
// their real host name, so a request to firesidetales.dev can never claim to be local.
export function isLocal(request: Request): boolean {
	const host = new URL(request.url).hostname;
	return host === "localhost" || host === "127.0.0.1" || host === "[::1]";
}

export async function isAdmin(request: Request, env: Env): Promise<string | null> {
	// The sign-in bypass for local work. It does nothing anywhere but localhost, even if set.
	if (env.DEV_ADMIN === "1" && isLocal(request)) return "local reviewer";
	const token = request.headers.get("cf-access-jwt-assertion");
	if (!token || !env.ACCESS_TEAM_DOMAIN || !env.ACCESS_AUD) return null;
	const [head, body, signature] = token.split(".");
	if (!head || !body || !signature) return null;

	const header = JSON.parse(new TextDecoder().decode(decodePart(head))) as { kid?: string; alg?: string };
	if (header.alg !== "RS256") return null;
	const jwk = (await accessKeys(env.ACCESS_TEAM_DOMAIN)).find((key) => key.kid === header.kid);
	if (!jwk) return null;
	const key = await crypto.subtle.importKey("jwk", jwk, { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["verify"]);
	const valid = await crypto.subtle.verify("RSASSA-PKCS1-v1_5", key, decodePart(signature),
		new TextEncoder().encode(`${head}.${body}`));
	if (!valid) return null;

	const claims = JSON.parse(new TextDecoder().decode(decodePart(body))) as {
		aud?: string | string[]; exp?: number; iss?: string; email?: string; common_name?: string;
	};
	const audiences = Array.isArray(claims.aud) ? claims.aud : [claims.aud];
	if (!audiences.includes(env.ACCESS_AUD)) return null;
	if (!claims.exp || claims.exp * 1000 < Date.now()) return null;
	if (claims.iss !== `https://${env.ACCESS_TEAM_DOMAIN}`) return null;

	if (claims.common_name && !claims.email) {
		// "name=client-id" pairs, comma separated.
		for (const pair of (env.REVIEW_TOKENS ?? "").split(",")) {
			const [name, clientId] = pair.split("=").map((part) => part.trim());
			if (name && clientId && clientId === claims.common_name) return name;
		}
		return null;
	}

	const allowed = (env.ADMIN_EMAILS ?? "").split(",").map((e) => e.trim().toLowerCase()).filter(Boolean);
	const email = (claims.email ?? "").toLowerCase();
	return allowed.includes(email) ? email : null;
}
