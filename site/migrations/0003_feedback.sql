-- Suggestions, bug reports, and anything else people want to tell us.
CREATE TABLE feedback (
	id TEXT PRIMARY KEY,
	created_at INTEGER NOT NULL,
	kind TEXT NOT NULL,                 -- idea, bug, story, or other
	message TEXT NOT NULL,
	contact TEXT NOT NULL DEFAULT '',   -- Optional, private, only for replying.
	ip_hash TEXT NOT NULL,              -- Salted hash, only for rate limits.
	status TEXT NOT NULL DEFAULT 'new'  -- new or done
);
CREATE INDEX feedback_status ON feedback (status, created_at);
CREATE INDEX feedback_ip ON feedback (ip_hash, created_at);
