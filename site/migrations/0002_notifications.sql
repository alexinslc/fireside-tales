-- Optional emails to the author, and the weekly "This week at the fire" post.
-- The address is cleared once the last email is sent, or when the author stops them.
ALTER TABLE submissions ADD COLUMN notify_email TEXT NOT NULL DEFAULT '';
ALTER TABLE submissions ADD COLUMN approved_mailed INTEGER NOT NULL DEFAULT 0;
ALTER TABLE submissions ADD COLUMN featured_mailed INTEGER NOT NULL DEFAULT 0;

-- One row per week once its post has gone out, so it never posts twice.
CREATE TABLE weekly_posts (
	week TEXT PRIMARY KEY,
	posted_at INTEGER NOT NULL
);
