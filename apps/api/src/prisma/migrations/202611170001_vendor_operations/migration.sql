-- T-074: additive operational replay identity; no financial/history backfill or grants.
CREATE TABLE vendor_operation_requests (
 request_key VARCHAR(64) PRIMARY KEY,
 user_id UUID NOT NULL,
 path VARCHAR(120) NOT NULL,
 request_hash VARCHAR(64) NOT NULL,
 response JSONB NOT NULL,
 created_at TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP
);
