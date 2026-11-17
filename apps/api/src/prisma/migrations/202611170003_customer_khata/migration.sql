-- T-082: additive personal/claim sources; no ledger/backfill/grant changes.
ALTER TABLE vendor_settings ADD COLUMN payment_upi_id VARCHAR(321);
CREATE TABLE personal_contacts (
 id UUID PRIMARY KEY,user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
 name VARCHAR(120) NOT NULL CHECK(length(trim(name))>0),mobile VARCHAR(20),version INTEGER NOT NULL DEFAULT 1 CHECK(version>0),
 deleted_at TIMESTAMPTZ(6),created_at TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX personal_contacts_user_id_deleted_at_name_idx ON personal_contacts(user_id,deleted_at,name);
CREATE TABLE personal_entries (
 id UUID PRIMARY KEY,user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
 contact_id UUID NOT NULL REFERENCES personal_contacts(id) ON DELETE RESTRICT,
 direction VARCHAR(4) NOT NULL CHECK(direction IN ('GAVE','GOT')),amount_paise BIGINT NOT NULL CHECK(amount_paise>0),
 date DATE NOT NULL,note VARCHAR(500) NOT NULL DEFAULT '',version INTEGER NOT NULL DEFAULT 1 CHECK(version>0),
 deleted_at TIMESTAMPTZ(6),created_at TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX personal_entries_user_id_contact_id_date_idx ON personal_entries(user_id,contact_id,date);
CREATE FUNCTION guard_personal_scope() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
 IF TG_OP='UPDATE' AND (NEW.user_id<>OLD.user_id OR NEW.created_at<>OLD.created_at OR OLD.deleted_at IS NOT NULL OR NEW.version<>OLD.version+1)
 THEN RAISE EXCEPTION 'Personal ownership or version mismatch'; END IF;
 IF TG_TABLE_NAME='personal_entries' THEN
  IF NOT EXISTS(SELECT 1 FROM personal_contacts c WHERE c.id=NEW.contact_id AND c.user_id=NEW.user_id AND c.deleted_at IS NULL)
  THEN RAISE EXCEPTION 'Personal contact scope mismatch'; END IF;
 END IF;
 RETURN NEW;
END;
$$;
CREATE TRIGGER personal_contacts_scope BEFORE UPDATE ON personal_contacts FOR EACH ROW EXECUTE FUNCTION guard_personal_scope();
CREATE TRIGGER personal_entries_scope BEFORE INSERT OR UPDATE ON personal_entries FOR EACH ROW EXECUTE FUNCTION guard_personal_scope();
CREATE TABLE payment_claims (
 id UUID PRIMARY KEY,vendor_customer_id UUID NOT NULL REFERENCES vendor_customers(id) ON DELETE RESTRICT,
 user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
 amount_paise BIGINT NOT NULL CHECK(amount_paise>0),method VARCHAR(4) NOT NULL CHECK(method IN ('UPI','CASH')),
 upi_txn_ref VARCHAR(120),status VARCHAR(12) NOT NULL DEFAULT 'PENDING' CHECK(status IN ('PENDING','CONFIRMED','REJECTED')),
 version INTEGER NOT NULL DEFAULT 1 CHECK(version>0),created_at TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
 decided_by UUID REFERENCES users(id) ON DELETE RESTRICT,decided_at TIMESTAMPTZ(6),reject_reason VARCHAR(200),
 CHECK((status='PENDING' AND decided_by IS NULL AND decided_at IS NULL AND reject_reason IS NULL)
    OR (status='CONFIRMED' AND decided_by IS NOT NULL AND decided_at IS NOT NULL AND reject_reason IS NULL)
    OR (status='REJECTED' AND decided_by IS NOT NULL AND decided_at IS NOT NULL AND reject_reason IS NOT NULL AND length(trim(reject_reason))>0)),
 CHECK(decided_at IS NULL OR decided_at>=created_at)
);
CREATE INDEX payment_claims_vendor_customer_id_status_created_at_idx ON payment_claims(vendor_customer_id,status,created_at);
CREATE INDEX payment_claims_user_id_created_at_idx ON payment_claims(user_id,created_at);
CREATE FUNCTION guard_claim_state() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
 IF TG_OP='INSERT' THEN
  IF NEW.status<>'PENDING' OR NEW.version<>1 OR NOT EXISTS(SELECT 1 FROM vendor_customers c WHERE c.id=NEW.vendor_customer_id AND c.user_id=NEW.user_id AND c.deleted_at IS NULL)
  THEN RAISE EXCEPTION 'Claim creator scope mismatch'; END IF;
 ELSE
  IF OLD.status<>'PENDING' OR NEW.status NOT IN ('CONFIRMED','REJECTED') OR NEW.version<>OLD.version+1
    OR NEW.id<>OLD.id OR NEW.vendor_customer_id<>OLD.vendor_customer_id OR NEW.user_id<>OLD.user_id OR NEW.amount_paise<>OLD.amount_paise
    OR NEW.method<>OLD.method OR NEW.upi_txn_ref IS DISTINCT FROM OLD.upi_txn_ref OR NEW.created_at<>OLD.created_at
    OR NOT EXISTS(SELECT 1 FROM vendor_customers c JOIN vendors v ON v.id=c.vendor_id WHERE c.id=NEW.vendor_customer_id AND v.user_id=NEW.decided_by)
  THEN RAISE EXCEPTION 'Claim decision scope mismatch'; END IF;
  IF NEW.status='CONFIRMED' AND NOT EXISTS(SELECT 1 FROM ledger_entries e WHERE e.ref_type='CLAIM' AND e.ref_id=NEW.id AND e.type='CREDIT' AND e.amount_paise=NEW.amount_paise AND e.vendor_customer_id=NEW.vendor_customer_id AND e.created_by=NEW.decided_by)
    OR NEW.status='REJECTED' AND EXISTS(SELECT 1 FROM ledger_entries e WHERE e.ref_type='CLAIM' AND e.ref_id=NEW.id AND e.type='CREDIT')
  THEN RAISE EXCEPTION 'Claim credit mismatch'; END IF;
 END IF;
 RETURN NEW;
END;
$$;
CREATE TRIGGER claim_state BEFORE INSERT OR UPDATE ON payment_claims FOR EACH ROW EXECUTE FUNCTION guard_claim_state();
CREATE TRIGGER claims_no_delete BEFORE DELETE OR TRUNCATE ON payment_claims FOR EACH STATEMENT EXECUTE FUNCTION reject_order_history_mutation();
CREATE TABLE khata_requests (
 request_key VARCHAR(64) PRIMARY KEY,user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
 path VARCHAR(120) NOT NULL,request_hash VARCHAR(64) NOT NULL,response JSONB NOT NULL,
 created_at TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TRIGGER khata_requests_immutable BEFORE UPDATE OR DELETE OR TRUNCATE ON khata_requests FOR EACH STATEMENT EXECUTE FUNCTION reject_order_history_mutation();
