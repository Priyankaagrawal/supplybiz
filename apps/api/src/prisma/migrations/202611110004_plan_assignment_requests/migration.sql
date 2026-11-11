-- T-103: no existing grant, catalog cap or price is changed.
CREATE TABLE plan_assignment_requests (
  request_key VARCHAR(64) PRIMARY KEY CHECK (request_key ~ '^[a-f0-9]{64}$'),
  admin_id UUID NOT NULL REFERENCES admin_users(id) ON DELETE RESTRICT,
  path VARCHAR(100) NOT NULL,
  request_hash VARCHAR(64) NOT NULL,
  response JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER plan_assignment_requests_immutable BEFORE UPDATE OR DELETE ON plan_assignment_requests
FOR EACH ROW EXECUTE FUNCTION reject_audit_mutation();
CREATE TRIGGER plan_assignment_requests_no_truncate BEFORE TRUNCATE ON plan_assignment_requests
FOR EACH STATEMENT EXECUTE FUNCTION reject_audit_mutation();
