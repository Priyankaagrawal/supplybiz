-- T-073: operational progress only; no historical delivery or financial backfill.
CREATE TABLE subscription_generation_runs (
 delivery_date DATE PRIMARY KEY, due_at TIMESTAMPTZ(6) NOT NULL,
 scan_cursor UUID, scan_complete BOOLEAN NOT NULL DEFAULT FALSE,
 expected_work INTEGER NOT NULL DEFAULT 0 CHECK(expected_work>=0),
 completed_work INTEGER NOT NULL DEFAULT 0 CHECK(completed_work>=0),
 generated_orders INTEGER NOT NULL DEFAULT 0 CHECK(generated_orders>=0),
 skipped_subscriptions INTEGER NOT NULL DEFAULT 0 CHECK(skipped_subscriptions>=0),
 finished_at TIMESTAMPTZ(6), alerted_at TIMESTAMPTZ(6),
 created_at TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CHECK(completed_work<=expected_work)
);
CREATE INDEX subscription_generation_due_idx ON subscription_generation_runs(finished_at,due_at);
CREATE TABLE subscription_schedule_state (id VARCHAR(32) PRIMARY KEY,through_date DATE NOT NULL);
