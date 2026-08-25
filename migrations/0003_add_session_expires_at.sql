ALTER TABLE sessions ADD COLUMN expires_at INTEGER;

UPDATE sessions
SET expires_at = unixepoch() + 2592000
WHERE expires_at IS NULL;
