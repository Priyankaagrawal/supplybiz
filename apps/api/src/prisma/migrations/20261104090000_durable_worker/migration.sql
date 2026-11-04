-- Additive migration; stop all old workers before deploying the new dispatcher.
ALTER TABLE outbox_events ADD COLUMN lease_token UUID, ADD COLUMN lease_until TIMESTAMPTZ(6);
ALTER TABLE outbox_events ADD CONSTRAINT outbox_lease_pair
  CHECK ((lease_token IS NULL) = (lease_until IS NULL));
CREATE TABLE job_runs (
  id UUID PRIMARY KEY,
  job_type VARCHAR(120) NOT NULL,
  business_date DATE NOT NULL,
  scope_id VARCHAR(120) NOT NULL,
  event_id UUID NOT NULL UNIQUE REFERENCES outbox_events(id),
  counts JSONB NOT NULL DEFAULT '{}',
  finished_at TIMESTAMPTZ(6),
  UNIQUE(job_type, business_date, scope_id)
);
-- Retry state/status/lease for each job is held on its unique linked outbox row.
-- Rollback: stop workers, retain both tables/columns and queued work; do not drop data.
