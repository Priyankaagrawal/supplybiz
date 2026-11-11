-- T-084 additive assignment foundation. No default/trial assignments or catalog price/cap changes.
CREATE TABLE vendor_plan_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vendor_id UUID NOT NULL REFERENCES vendors(id) ON DELETE RESTRICT,
  plan_id UUID NOT NULL REFERENCES plans(id) ON DELETE RESTRICT,
  starts_at TIMESTAMPTZ NOT NULL,
  ends_at TIMESTAMPTZ NOT NULL CHECK (ends_at > starts_at),
  reason VARCHAR(500) NOT NULL CHECK (length(trim(reason)) > 0),
  granted_by_admin UUID NOT NULL REFERENCES admin_users(id) ON DELETE RESTRICT,
  audit_id UUID NOT NULL UNIQUE REFERENCES audit_logs(id) ON DELETE RESTRICT,
  superseded_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX vendor_plan_assignments_current ON vendor_plan_assignments(vendor_id) WHERE superseded_at IS NULL;
CREATE INDEX vendor_plan_assignments_vendor_id_idx ON vendor_plan_assignments(vendor_id);
