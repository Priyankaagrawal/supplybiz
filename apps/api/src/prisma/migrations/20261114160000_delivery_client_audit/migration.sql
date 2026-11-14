-- T-050: additive, untrusted offline creation time; server `at` remains authoritative.
ALTER TABLE "order_status_events" ADD COLUMN "client_created_at" TIMESTAMPTZ(6);
