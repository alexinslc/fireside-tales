-- A written post for a week: shown above that week's stories once the week starts.
CREATE TABLE week_posts (
	week TEXT PRIMARY KEY,               -- YYYY-MM-DD, a Tuesday.
	title TEXT NOT NULL,
	intro TEXT NOT NULL,                 -- Plain text; blank lines separate paragraphs.
	highlights_json TEXT NOT NULL DEFAULT '[]', -- [{ story_id, note }], stories from that week.
	status TEXT NOT NULL DEFAULT 'draft', -- draft or published. Published shows once the week starts.
	updated_at INTEGER NOT NULL,
	updated_by TEXT NOT NULL DEFAULT ''   -- Never shown publicly.
);
