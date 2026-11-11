-- Which addon release first carried each story, reported by the release job.
ALTER TABLE submissions ADD COLUMN shipped_version TEXT;
ALTER TABLE submissions ADD COLUMN shipped_at INTEGER;

CREATE TABLE releases (
	version TEXT PRIMARY KEY,           -- Like 1.6.2.
	released_at INTEGER NOT NULL,
	stories INTEGER NOT NULL            -- How many community stories it carried.
);
