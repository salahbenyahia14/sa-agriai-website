PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL UNIQUE COLLATE NOCASE,
  display_name TEXT NOT NULL,
  password_salt TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  deleted_at INTEGER
);

CREATE INDEX IF NOT EXISTS idx_users_email_active ON users(email, deleted_at);

CREATE TABLE IF NOT EXISTS sessions (
  id TEXT PRIMARY KEY,
  token_hash TEXT NOT NULL UNIQUE,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL,
  revoked_at INTEGER
);

CREATE INDEX IF NOT EXISTS idx_sessions_user ON sessions(user_id, expires_at, revoked_at);

CREATE TABLE IF NOT EXISTS password_reset_tokens (
  id TEXT PRIMARY KEY,
  token_hash TEXT NOT NULL UNIQUE,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL,
  used_at INTEGER
);

CREATE INDEX IF NOT EXISTS idx_password_reset_user ON password_reset_tokens(user_id, expires_at, used_at);

CREATE TABLE IF NOT EXISTS auth_rate_limits (
  rate_key TEXT PRIMARY KEY,
  hits INTEGER NOT NULL,
  window_started_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS listings (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  category TEXT NOT NULL,
  price TEXT NOT NULL DEFAULT '',
  wilaya TEXT NOT NULL,
  phone TEXT NOT NULL DEFAULT '',
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER
);

CREATE INDEX IF NOT EXISTS idx_listings_created ON listings(deleted_at, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_listings_owner ON listings(user_id, deleted_at);

CREATE TABLE IF NOT EXISTS community_posts (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  deleted_at INTEGER
);

CREATE INDEX IF NOT EXISTS idx_posts_created ON community_posts(deleted_at, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_posts_owner ON community_posts(user_id, deleted_at);