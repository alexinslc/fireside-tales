import path from "node:path";
import { fileURLToPath } from "node:url";
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";
import { cloudflare } from "@cloudflare/vite-plugin";

const here = path.dirname(fileURLToPath(import.meta.url));

// The React pages in src/, and the Worker in worker/ that serves them and /api/*.
export default defineConfig({
	plugins: [react(), tailwindcss(), cloudflare({ viteEnvironment: { name: "worker" } })],
	resolve: {
		alias: {
			"@": path.resolve(here, "./src"),
			"@shared": path.resolve(here, "./shared"),
		},
	},
	environments: {
		worker: { build: { sourcemap: true } },
	},
});
