-- Additive T-180 migration. No existing identity/session data changes.
-- Rollback: revert application first, then drop this ephemeral state table;
-- doing so resets abuse budgets and invalidates pending OTP challenges.
CREATE TABLE "auth_abuse_state" (
    "key" VARCHAR(100) NOT NULL PRIMARY KEY,
    "value" JSONB NOT NULL,
    "expires_at" TIMESTAMPTZ(6) NOT NULL
);
CREATE INDEX "auth_abuse_state_expires_at_idx" ON "auth_abuse_state"("expires_at");
