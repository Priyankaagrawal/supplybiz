-- T-070 additive foundation. No financial stubs or existing-data rewrites.
CREATE TABLE ledger_entries (
 id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
 vendor_id UUID NOT NULL REFERENCES vendors(id) ON DELETE RESTRICT,
 vendor_customer_id UUID NOT NULL REFERENCES vendor_customers(id) ON DELETE RESTRICT,
 type VARCHAR(6) NOT NULL CHECK (type IN ('DEBIT','CREDIT')),
 amount_paise BIGINT NOT NULL CHECK (amount_paise > 0),
 ref_type VARCHAR(8) NOT NULL CHECK (ref_type IN ('ORDER','SALE','PAYMENT','CLAIM','OPENING','REVERSAL')),
 ref_id UUID NOT NULL,
 reverses_entry_id UUID UNIQUE REFERENCES ledger_entries(id) ON DELETE RESTRICT,
 request_key CHAR(64) UNIQUE, request_hash CHAR(64),
 note VARCHAR(500) NOT NULL,
 entry_date DATE NOT NULL DEFAULT (clock_timestamp() AT TIME ZONE 'Asia/Kolkata')::date,
 created_by UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
 created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
 CONSTRAINT ledger_reference_once UNIQUE (ref_type,ref_id,type),
 CHECK ((ref_type = 'REVERSAL') = (reverses_entry_id IS NOT NULL)),
 CHECK ((request_key IS NULL) = (request_hash IS NULL)),
 CHECK (ref_type NOT IN ('OPENING','REVERSAL') OR request_key IS NOT NULL),
 CHECK (ref_type NOT IN ('OPENING','REVERSAL') OR length(btrim(note)) > 0)
);
CREATE INDEX ledger_entries_vendor_customer_id_entry_date_id_idx ON ledger_entries(vendor_customer_id,entry_date,id);
CREATE TABLE ledger_balances (
 vendor_customer_id UUID PRIMARY KEY REFERENCES vendor_customers(id) ON DELETE RESTRICT,
 total_debit_paise BIGINT NOT NULL DEFAULT 0 CHECK (total_debit_paise >= 0),
 total_credit_paise BIGINT NOT NULL DEFAULT 0 CHECK (total_credit_paise >= 0),
 due_paise BIGINT NOT NULL DEFAULT 0,
 updated_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
 CHECK (due_paise = total_debit_paise - total_credit_paise)
);
CREATE TABLE ledger_reconciliation_findings (
 id UUID PRIMARY KEY DEFAULT gen_random_uuid(), business_date DATE NOT NULL,
 vendor_customer_id UUID NOT NULL REFERENCES vendor_customers(id) ON DELETE RESTRICT,
 expected JSONB NOT NULL, observed JSONB, created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
 UNIQUE (business_date,vendor_customer_id)
);
CREATE FUNCTION reject_ledger_mutation() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN RAISE EXCEPTION 'Ledger history is append-only' USING ERRCODE = '42501'; END $$;
CREATE TRIGGER ledger_entries_immutable BEFORE UPDATE OR DELETE ON ledger_entries
 FOR EACH ROW EXECUTE FUNCTION reject_ledger_mutation();
CREATE TRIGGER ledger_entries_no_truncate BEFORE TRUNCATE ON ledger_entries
 FOR EACH STATEMENT EXECUTE FUNCTION reject_ledger_mutation();
CREATE TRIGGER ledger_findings_immutable BEFORE UPDATE OR DELETE ON ledger_reconciliation_findings
 FOR EACH ROW EXECUTE FUNCTION reject_ledger_mutation();
CREATE TRIGGER ledger_findings_no_truncate BEFORE TRUNCATE ON ledger_reconciliation_findings
 FOR EACH STATEMENT EXECUTE FUNCTION reject_ledger_mutation();

-- Fixed search path and qualified tables: no caller-controlled object resolution.
-- Configure these functions' non-login owner with tools/ledger-grants.sql before runtime use.
CREATE FUNCTION guard_ledger_insert() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
 SET search_path = pg_catalog, public AS $$
DECLARE customer_vendor UUID; original public.ledger_entries;
BEGIN
 SELECT vendor_id INTO customer_vendor FROM public.vendor_customers WHERE id = NEW.vendor_customer_id FOR UPDATE;
 IF NOT FOUND OR customer_vendor <> NEW.vendor_id THEN
   RAISE EXCEPTION 'Invalid ledger customer scope' USING ERRCODE = '23514';
 END IF;
 IF NEW.reverses_entry_id IS NOT NULL THEN
   SELECT * INTO original FROM public.ledger_entries WHERE id = NEW.reverses_entry_id FOR UPDATE;
   IF NOT FOUND OR original.vendor_id <> NEW.vendor_id OR original.vendor_customer_id <> NEW.vendor_customer_id
     OR original.amount_paise <> NEW.amount_paise OR original.type = NEW.type
     OR NEW.ref_id <> original.id THEN
     RAISE EXCEPTION 'Invalid ledger reversal' USING ERRCODE = '23514';
   END IF;
 END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER ledger_insert_guard BEFORE INSERT ON ledger_entries FOR EACH ROW EXECUTE FUNCTION guard_ledger_insert();
CREATE FUNCTION apply_ledger_insert() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
 SET search_path = pg_catalog, public AS $$
DECLARE debit BIGINT; credit BIGINT;
BEGIN
 debit := CASE WHEN NEW.type = 'DEBIT' THEN NEW.amount_paise ELSE 0 END;
 credit := CASE WHEN NEW.type = 'CREDIT' THEN NEW.amount_paise ELSE 0 END;
 INSERT INTO public.ledger_balances(vendor_customer_id,total_debit_paise,total_credit_paise,due_paise)
 VALUES(NEW.vendor_customer_id,debit,credit,debit-credit)
 ON CONFLICT (vendor_customer_id) DO UPDATE SET
   total_debit_paise = public.ledger_balances.total_debit_paise + debit,
   total_credit_paise = public.ledger_balances.total_credit_paise + credit,
   due_paise = public.ledger_balances.due_paise + debit - credit,
   updated_at = clock_timestamp();
 INSERT INTO public.audit_logs(actor_type,actor_id,action,entity,entity_id,after)
 VALUES('USER',NEW.created_by,CASE WHEN NEW.ref_type = 'REVERSAL' THEN 'LEDGER_REVERSED' ELSE 'LEDGER_APPENDED' END,
   'ledger_entries',NEW.id,jsonb_build_object('id',NEW.id,'status',NEW.type));
 RETURN NEW;
END $$;
CREATE TRIGGER ledger_insert_effects AFTER INSERT ON ledger_entries FOR EACH ROW EXECUTE FUNCTION apply_ledger_insert();
CREATE FUNCTION audit_ledger_finding() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
 SET search_path = pg_catalog, public AS $$
BEGIN
 INSERT INTO public.audit_logs(actor_type,action,entity,entity_id,after)
 VALUES('SYSTEM','LEDGER_RECONCILIATION_DRIFT','ledger_reconciliation_findings',NEW.id,
   jsonb_build_object('id',NEW.id,'status','DRIFT'));
 RETURN NEW;
END $$;
CREATE TRIGGER ledger_finding_audit AFTER INSERT ON ledger_reconciliation_findings FOR EACH ROW EXECUTE FUNCTION audit_ledger_finding();
REVOKE ALL ON FUNCTION guard_ledger_insert(), apply_ledger_insert(), audit_ledger_finding(), reject_ledger_mutation() FROM PUBLIC;
REVOKE ALL ON ledger_entries, ledger_balances, ledger_reconciliation_findings FROM PUBLIC;
