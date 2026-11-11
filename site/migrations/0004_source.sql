-- Where a submission came from: the web form, or an AI agent through the API.
ALTER TABLE submissions ADD COLUMN source TEXT NOT NULL DEFAULT 'web';
