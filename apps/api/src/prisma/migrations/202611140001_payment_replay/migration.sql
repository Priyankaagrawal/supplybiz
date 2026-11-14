-- T-071: immutable receipt carries permanent normalized-request identity.
-- Existing delivery receipts keep NULL; no historical financial backfill.
ALTER TABLE payments ADD COLUMN request_hash VARCHAR(64);
