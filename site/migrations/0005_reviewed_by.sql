-- Who made the last review decision on a story: a reviewer's email or a service token's name.
ALTER TABLE submissions ADD COLUMN reviewed_by TEXT NOT NULL DEFAULT '';
ALTER TABLE submissions ADD COLUMN reviewed_at INTEGER;
