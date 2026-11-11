-- Whether each feedback note was emailed on, and a reviewer's notes on it.
ALTER TABLE feedback ADD COLUMN emailed INTEGER NOT NULL DEFAULT 0;
ALTER TABLE feedback ADD COLUMN review_json TEXT;           -- { category, priority, summary, notes }
ALTER TABLE feedback ADD COLUMN reviewed_by TEXT NOT NULL DEFAULT '';
