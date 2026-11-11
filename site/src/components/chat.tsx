import { cn } from "@/lib/utils";
import type { Line } from "@/lib/api";

// A story as people around the fire see it in chat. With onFlip, each line can be
// clicked to switch it between spoken and action.
export function ChatPreview({ lines, name, onFlip, className }: {
	lines: Line[];
	name?: string;
	onFlip?: (index: number) => void;
	className?: string;
}) {
	const teller = name?.trim() || "Bram";
	const shown = lines.filter((line) => line.text);
	return (
		<div className={cn("rounded-lg border bg-black/55 px-4 py-3 font-[family-name:var(--font-chat)] text-[15px] leading-relaxed", className)}>
			{shown.length === 0 && <p className="text-muted-foreground italic">Your story will appear here as people will see it.</p>}
			{shown.map((line, index) => {
				const text = line.kind === "emote" ? `${teller} ${line.text}` : `[${teller}] says: ${line.text}`;
				const tone = line.kind === "emote" ? "text-emote" : "text-say";
				return onFlip ? (
					<button
						key={index}
						type="button"
						onClick={() => onFlip(index)}
						title="Click to switch between spoken and action"
						className={cn("mb-2 block w-full rounded text-left last:mb-0 hover:bg-white/5", tone)}
					>
						{text}
					</button>
				) : (
					<p key={index} className={cn("mb-2 last:mb-0", tone)}>{text}</p>
				);
			})}
		</div>
	);
}

export function MoodDot({ mood }: { mood: string }) {
	const colors: Record<string, string> = {
		funny: "bg-mood-funny", heartfelt: "bg-mood-heartfelt", dark: "bg-mood-dark",
		action: "bg-mood-action", spooky: "bg-mood-spooky", wise: "bg-mood-wise",
	};
	return <span aria-hidden="true" className={cn("inline-block size-2.5 rounded-[2px]", colors[mood] ?? "bg-muted-foreground")} />;
}
