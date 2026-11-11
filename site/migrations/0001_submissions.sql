-- Every story or rumor someone sends in, and what happened to it.
CREATE TABLE submissions (
	id TEXT PRIMARY KEY,
	receipt TEXT NOT NULL UNIQUE,      -- The code the submitter keeps to check on it.
	created_at INTEGER NOT NULL,
	updated_at INTEGER NOT NULL,
	kind TEXT NOT NULL,                -- story or rumor
	title TEXT NOT NULL,
	mood TEXT NOT NULL,
	lines_json TEXT NOT NULL,          -- [{ kind: "say" | "emote", text }]
	author TEXT NOT NULL DEFAULT '',   -- Optional; empty means anonymous.
	ruleset TEXT NOT NULL DEFAULT '',  -- Optional.
	contact TEXT NOT NULL DEFAULT '',  -- Optional, private, only for replying.
	ip_hash TEXT NOT NULL,             -- Salted hash, only for rate limits.
	-- pending: waiting for review. approved: scheduled for a week. rejected: not used.
	status TEXT NOT NULL DEFAULT 'pending',
	week TEXT,                         -- YYYY-MM-DD, the Tuesday it's featured from.
	review_note TEXT NOT NULL DEFAULT '', -- Shown to the submitter on the status page.
	original_json TEXT,                -- The story as sent, if a reviewer edited it.
	ai_status TEXT NOT NULL DEFAULT 'waiting', -- waiting, done, or failed
	ai_verdict TEXT,                   -- approve, needs_changes, or reject
	ai_json TEXT,                      -- The full moderation result.
	ai_model TEXT,
	ai_at INTEGER
);

CREATE INDEX submissions_status ON submissions (status, created_at);
CREATE INDEX submissions_week ON submissions (week);
CREATE INDEX submissions_ip ON submissions (ip_hash, created_at);
