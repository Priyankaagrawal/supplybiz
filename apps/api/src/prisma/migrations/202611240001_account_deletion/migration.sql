-- T-019 / ADR-035: additive durable erasure requests. No existing records are purged.
CREATE TABLE account_deletions (
 id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
 user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE RESTRICT,
 request_key VARCHAR(64) NOT NULL UNIQUE,
 request_hash VARCHAR(64) NOT NULL,
 requested_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
 erase_by TIMESTAMPTZ NOT NULL DEFAULT (clock_timestamp() + interval '30 days'),
 status VARCHAR(24) NOT NULL DEFAULT 'PENDING_ERASURE' CHECK(status IN ('PENDING_ERASURE','HELD','ERASED')),
 hold_reason VARCHAR(500), hold_actor UUID REFERENCES admin_users(id), hold_at TIMESTAMPTZ,
 erased_at TIMESTAMPTZ,
 CHECK (erase_by >= requested_at),
 CHECK ((status='HELD' AND length(trim(hold_reason))>=3 AND hold_actor IS NOT NULL AND hold_at IS NOT NULL)
 OR (status<>'HELD' AND hold_reason IS NULL AND hold_actor IS NULL AND hold_at IS NULL)),
 CHECK ((status='ERASED') = (erased_at IS NOT NULL))
);
CREATE INDEX account_deletions_due ON account_deletions(status,erase_by,id);
