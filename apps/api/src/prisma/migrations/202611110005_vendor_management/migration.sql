-- T-155 additive management metadata/replay. Existing account, KYC and plan states are unchanged.
ALTER TABLE vendors ADD COLUMN badges TEXT[] NOT NULL DEFAULT '{}'
  CHECK (cardinality(badges) <= 10);
CREATE TABLE management_requests (
  request_key VARCHAR(64) PRIMARY KEY CHECK (request_key ~ '^[a-f0-9]{64}$'),
  admin_id UUID NOT NULL REFERENCES admin_users(id) ON DELETE RESTRICT,
  path VARCHAR(100) NOT NULL, request_hash VARCHAR(64) NOT NULL, response JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER management_requests_immutable BEFORE UPDATE OR DELETE ON management_requests
FOR EACH ROW EXECUTE FUNCTION reject_audit_mutation();
CREATE TRIGGER management_requests_no_truncate BEFORE TRUNCATE ON management_requests
FOR EACH STATEMENT EXECUTE FUNCTION reject_audit_mutation();
