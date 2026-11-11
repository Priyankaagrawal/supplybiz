-- Operator-only, after migration. Run with psql -X -v ON_ERROR_STOP=1
-- -v runtime_role=<API login> -v ledger_owner=<dedicated non-login owner> -f tools/ledger-grants.sql
-- Requires an administrator; never supply administrator credentials to the API/worker.
\set ON_ERROR_STOP on
BEGIN;
SELECT set_config('supplybiz.runtime_role', :'runtime_role', true), set_config('supplybiz.ledger_owner', :'ledger_owner', true);
DO $$
DECLARE runtime_name TEXT := current_setting('supplybiz.runtime_role'); owner_name TEXT := current_setting('supplybiz.ledger_owner');
BEGIN
 IF runtime_name = owner_name OR runtime_name !~ '^supplybiz_[a-z0-9_]+$' OR owner_name !~ '^supplybiz_[a-z0-9_]+$'
   OR length(runtime_name) > 63 OR length(owner_name) > 63 THEN RAISE EXCEPTION 'Invalid separate ledger roles'; END IF;
 IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = runtime_name AND NOT rolsuper AND NOT rolcreaterole) THEN
   RAISE EXCEPTION 'Runtime must be an existing non-superuser without CREATEROLE';
 END IF;
 IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = owner_name) THEN
   EXECUTE format('CREATE ROLE %I NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT',owner_name);
 END IF;
 IF EXISTS (SELECT FROM pg_roles WHERE rolname = owner_name AND (rolcanlogin OR rolsuper OR rolcreaterole))
   OR pg_has_role(runtime_name,owner_name,'MEMBER') THEN RAISE EXCEPTION 'Runtime must not control the ledger owner'; END IF;
 EXECUTE format('GRANT USAGE ON SCHEMA public TO %I',owner_name);
 EXECUTE format('GRANT SELECT ON public.vendor_customers TO %I',owner_name);
 EXECUTE format('GRANT UPDATE (id) ON public.vendor_customers TO %I',owner_name);
 EXECUTE format('GRANT INSERT ON public.audit_logs TO %I',owner_name);
 EXECUTE format('ALTER TABLE public.ledger_entries OWNER TO %I',owner_name);
 EXECUTE format('ALTER TABLE public.ledger_balances OWNER TO %I',owner_name);
 EXECUTE format('ALTER TABLE public.ledger_reconciliation_findings OWNER TO %I',owner_name);
 EXECUTE format('ALTER FUNCTION public.guard_ledger_insert() OWNER TO %I',owner_name);
 EXECUTE format('ALTER FUNCTION public.apply_ledger_insert() OWNER TO %I',owner_name);
 EXECUTE format('ALTER FUNCTION public.audit_ledger_finding() OWNER TO %I',owner_name);
 EXECUTE format('ALTER FUNCTION public.reject_ledger_mutation() OWNER TO %I',owner_name);
 EXECUTE format('REVOKE ALL ON public.ledger_entries,public.ledger_balances,public.ledger_reconciliation_findings FROM %I',runtime_name);
 EXECUTE format('GRANT SELECT,INSERT ON public.ledger_entries,public.ledger_reconciliation_findings TO %I',runtime_name);
 EXECUTE format('GRANT SELECT ON public.ledger_balances TO %I',runtime_name);
 IF has_table_privilege(runtime_name,'public.ledger_entries','UPDATE') OR has_table_privilege(runtime_name,'public.ledger_entries','DELETE')
   OR has_table_privilege(runtime_name,'public.ledger_entries','TRUNCATE') OR has_table_privilege(runtime_name,'public.ledger_entries','TRIGGER')
   OR has_any_column_privilege(runtime_name,'public.ledger_entries','UPDATE')
   OR has_table_privilege(runtime_name,'public.ledger_balances','INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER')
   OR has_any_column_privilege(runtime_name,'public.ledger_balances','INSERT,UPDATE')
   OR has_table_privilege(runtime_name,'public.ledger_reconciliation_findings','UPDATE,DELETE,TRUNCATE,TRIGGER')
   OR has_any_column_privilege(runtime_name,'public.ledger_reconciliation_findings','UPDATE') THEN
   RAISE EXCEPTION 'Inherited unsafe ledger privileges must be removed before runtime';
 END IF;
END $$;
COMMIT;
