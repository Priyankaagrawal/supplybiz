-- Operator-only, after migrations. Run with psql -v runtime_role=... -f this file.
-- Does not grant ordinary runtime UPDATE/DELETE on financial or audit sources.
\set ON_ERROR_STOP on
\if :{?runtime_role}
\else
\echo 'runtime_role is required'
\quit 1
\endif
BEGIN;
SELECT set_config('supplybiz.privacy_runtime', :'runtime_role',true);
DO $$ BEGIN
 IF NOT EXISTS(SELECT 1 FROM pg_roles WHERE rolname='supplybiz_privacy_owner') THEN
  CREATE ROLE supplybiz_privacy_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT;
 END IF;
END $$;
DO $$ BEGIN
 IF current_setting('supplybiz.privacy_runtime')='supplybiz_privacy_owner'
  OR EXISTS(SELECT 1 FROM pg_roles WHERE rolname='supplybiz_privacy_owner' AND (rolcanlogin OR rolsuper OR rolcreaterole OR rolcreatedb))
  OR NOT EXISTS(SELECT 1 FROM pg_roles WHERE rolname=current_setting('supplybiz.privacy_runtime') AND NOT rolsuper AND NOT rolcreaterole)
  OR pg_has_role(current_setting('supplybiz.privacy_runtime'),'supplybiz_privacy_owner','MEMBER')
 THEN RAISE EXCEPTION 'Privacy runtime must not control retention owner'; END IF;
END $$;
GRANT USAGE ON SCHEMA public TO supplybiz_privacy_owner;
GRANT SELECT ON account_deletions,users,vendors,vendor_customers,ledger_entries,payments,payment_claims,audit_logs,vendor_plan_assignments TO supplybiz_privacy_owner;
GRANT UPDATE(note) ON ledger_entries TO supplybiz_privacy_owner;
GRANT UPDATE(note) ON payments TO supplybiz_privacy_owner;
GRANT UPDATE(upi_txn_ref,reject_reason) ON payment_claims TO supplybiz_privacy_owner;
GRANT SELECT,DELETE ON admin_auth_events,media_access_events,kyc_notices,privacy_exports,idempotency_keys TO supplybiz_privacy_owner;
GRANT SELECT,UPDATE(response) ON management_requests TO supplybiz_privacy_owner;
GRANT UPDATE(actor_id,before,after,ip),DELETE,INSERT ON audit_logs TO supplybiz_privacy_owner;
ALTER FUNCTION privacy_redact_ledger(UUID,UUID) OWNER TO supplybiz_privacy_owner;
ALTER FUNCTION privacy_redact_payment(UUID,UUID) OWNER TO supplybiz_privacy_owner;
ALTER FUNCTION privacy_redact_claim(UUID,UUID) OWNER TO supplybiz_privacy_owner;
ALTER FUNCTION privacy_expire_audits() OWNER TO supplybiz_privacy_owner;
ALTER FUNCTION privacy_expire_sources() OWNER TO supplybiz_privacy_owner;
GRANT EXECUTE ON FUNCTION privacy_redact_ledger(UUID,UUID),privacy_redact_payment(UUID,UUID),privacy_redact_claim(UUID,UUID),privacy_expire_audits(),privacy_expire_sources() TO :"runtime_role";
COMMIT;
