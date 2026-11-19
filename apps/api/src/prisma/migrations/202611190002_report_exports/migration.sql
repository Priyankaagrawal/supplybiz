-- T-101: transient generated artifacts/replay cache, not source financial records.
CREATE TABLE report_exports (
 id UUID PRIMARY KEY, user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
 vendor_id UUID NOT NULL REFERENCES vendors(id) ON DELETE RESTRICT,
 request_key VARCHAR(64) NOT NULL UNIQUE, request_hash VARCHAR(64) NOT NULL,
 from_date DATE NOT NULL,to_date DATE NOT NULL,
 content BYTEA NOT NULL,byte_size INTEGER NOT NULL CHECK(byte_size>0 AND byte_size<=8388608),
 sha256 VARCHAR(64) NOT NULL,created_at TIMESTAMPTZ NOT NULL,expires_at TIMESTAMPTZ NOT NULL,
 CHECK(to_date>=from_date AND to_date-from_date<366),CHECK(expires_at>created_at)
);
CREATE INDEX report_exports_expiry_idx ON report_exports(expires_at);
