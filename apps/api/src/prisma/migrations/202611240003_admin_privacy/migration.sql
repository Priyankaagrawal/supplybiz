-- T-161: metadata only. Exported personal data is generated on authorized download.
ALTER TABLE account_deletions ADD COLUMN version INTEGER NOT NULL DEFAULT 1;
ALTER TABLE account_deletions ADD COLUMN retention_hold_reason VARCHAR(500),
 ADD COLUMN retention_hold_actor UUID REFERENCES admin_users(id), ADD COLUMN retention_hold_at TIMESTAMPTZ;
ALTER TABLE account_deletions ADD CONSTRAINT retention_hold_complete CHECK (
 (retention_hold_reason IS NULL AND retention_hold_actor IS NULL AND retention_hold_at IS NULL) OR
 (length(trim(retention_hold_reason))>=3 AND retention_hold_actor IS NOT NULL AND retention_hold_at IS NOT NULL));
CREATE TABLE privacy_exports (
 id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
 user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
 admin_id UUID NOT NULL REFERENCES admin_users(id) ON DELETE RESTRICT,
 reason VARCHAR(500) NOT NULL CHECK(length(trim(reason))>=3),
 request_key VARCHAR(64) NOT NULL UNIQUE, request_hash VARCHAR(64) NOT NULL,
 created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
 expires_at TIMESTAMPTZ NOT NULL DEFAULT (clock_timestamp()+interval '24 hours')
);
CREATE INDEX privacy_exports_created ON privacy_exports(created_at,id);
