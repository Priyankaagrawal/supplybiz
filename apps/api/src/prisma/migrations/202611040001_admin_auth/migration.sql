ALTER TABLE admin_users ADD COLUMN failed_attempts INTEGER NOT NULL DEFAULT 0,
 ADD COLUMN locked_until TIMESTAMPTZ, ADD COLUMN last_totp_step BIGINT NOT NULL DEFAULT -1;
CREATE TABLE admin_auth_challenges (
 token_hash VARCHAR(64) PRIMARY KEY, admin_id UUID NOT NULL REFERENCES admin_users(id),
 secret_enc VARCHAR(512) NOT NULL, enrolling BOOLEAN NOT NULL, expires_at TIMESTAMPTZ NOT NULL
);
CREATE TABLE admin_sessions (
 token_hash VARCHAR(64) PRIMARY KEY, admin_id UUID NOT NULL REFERENCES admin_users(id),
 csrf_hash VARCHAR(64) NOT NULL, created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
 last_used_at TIMESTAMPTZ NOT NULL DEFAULT now(), expires_at TIMESTAMPTZ NOT NULL
);
CREATE INDEX admin_sessions_admin_id_idx ON admin_sessions(admin_id);
CREATE INDEX admin_sessions_expires_at_idx ON admin_sessions(expires_at);
CREATE TABLE admin_auth_events (
 id UUID PRIMARY KEY, admin_id UUID REFERENCES admin_users(id), action VARCHAR(64) NOT NULL,
 at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE FUNCTION reject_admin_auth_event_mutation() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN RAISE EXCEPTION 'Admin authentication events are append-only'; END $$;
CREATE TRIGGER admin_auth_events_immutable BEFORE UPDATE OR DELETE ON admin_auth_events
FOR EACH ROW EXECUTE FUNCTION reject_admin_auth_event_mutation();
