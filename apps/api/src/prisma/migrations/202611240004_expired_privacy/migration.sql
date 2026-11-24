-- Guarded retention only. Normal financial/audit operations remain append-only.
CREATE FUNCTION privacy_financial_cutoff() RETURNS TIMESTAMPTZ LANGUAGE sql STABLE AS $$
 SELECT make_date(extract(year FROM current_timestamp AT TIME ZONE 'Asia/Kolkata')::int
  -CASE WHEN extract(month FROM current_timestamp AT TIME ZONE 'Asia/Kolkata')<4 THEN 1 ELSE 0 END-8,4,1)::timestamp AT TIME ZONE 'Asia/Kolkata'
$$;
CREATE FUNCTION privacy_financial_scope(v UUID,c UUID,at TIMESTAMPTZ) RETURNS BOOLEAN LANGUAGE sql STABLE AS $$
 SELECT at<privacy_financial_cutoff() AND current_setting('supplybiz.financial_erasure',true) IS NOT NULL
 AND EXISTS(SELECT 1 FROM account_deletions d JOIN users u ON u.id=d.user_id
  WHERE d.user_id::text=current_setting('supplybiz.financial_erasure',true) AND u.status='DELETED'
  AND d.status='ERASED' AND d.retention_hold_reason IS NULL
  AND (EXISTS(SELECT 1 FROM vendors x WHERE x.id=v AND x.user_id=d.user_id)
    OR EXISTS(SELECT 1 FROM vendor_customers x WHERE x.id=c AND x.user_id=d.user_id)))
$$;
CREATE OR REPLACE FUNCTION reject_ledger_mutation() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
 IF TG_TABLE_NAME='ledger_entries' AND TG_OP='UPDATE' THEN
  IF NEW.note='' AND (to_jsonb(NEW)-'note') IS NOT DISTINCT FROM (to_jsonb(OLD)-'note')
   AND privacy_financial_scope(OLD.vendor_id,OLD.vendor_customer_id,OLD.created_at) THEN RETURN NEW; END IF;
 END IF;
 RAISE EXCEPTION 'Ledger entries are append-only';
END $$;
CREATE OR REPLACE FUNCTION guard_claim_state() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
 IF TG_OP='UPDATE' AND NEW.upi_txn_ref IS NULL
  AND NEW.reject_reason IS NOT DISTINCT FROM (CASE WHEN OLD.status='REJECTED' THEN 'Expired retained record'::varchar ELSE NULL::varchar END)
  AND (to_jsonb(NEW)-ARRAY['upi_txn_ref','reject_reason']) IS NOT DISTINCT FROM (to_jsonb(OLD)-ARRAY['upi_txn_ref','reject_reason'])
  AND EXISTS(SELECT 1 FROM vendor_customers c WHERE c.id=OLD.vendor_customer_id
   AND privacy_financial_scope(c.vendor_id,c.id,greatest(OLD.created_at,OLD.decided_at))) THEN RETURN NEW; END IF;
 IF TG_OP='INSERT' THEN
  IF NEW.status<>'PENDING' OR NEW.version<>1 OR NOT EXISTS(SELECT 1 FROM vendor_customers c WHERE c.id=NEW.vendor_customer_id AND c.user_id=NEW.user_id AND c.deleted_at IS NULL) THEN RAISE EXCEPTION 'Claim creator scope mismatch'; END IF;
 ELSE
  IF OLD.status<>'PENDING' OR NEW.status NOT IN ('CONFIRMED','REJECTED') OR NEW.version<>OLD.version+1
   OR NEW.id<>OLD.id OR NEW.vendor_customer_id<>OLD.vendor_customer_id OR NEW.user_id<>OLD.user_id OR NEW.amount_paise<>OLD.amount_paise
   OR NEW.method<>OLD.method OR NEW.upi_txn_ref IS DISTINCT FROM OLD.upi_txn_ref OR NEW.created_at<>OLD.created_at
   OR NOT EXISTS(SELECT 1 FROM vendor_customers c JOIN vendors v ON v.id=c.vendor_id WHERE c.id=NEW.vendor_customer_id AND v.user_id=NEW.decided_by) THEN RAISE EXCEPTION 'Claim decision scope mismatch'; END IF;
  IF NEW.status='CONFIRMED' AND NOT EXISTS(SELECT 1 FROM ledger_entries e WHERE e.ref_type='CLAIM' AND e.ref_id=NEW.id AND e.type='CREDIT' AND e.amount_paise=NEW.amount_paise AND e.vendor_customer_id=NEW.vendor_customer_id AND e.created_by=NEW.decided_by)
   OR NEW.status='REJECTED' AND EXISTS(SELECT 1 FROM ledger_entries e WHERE e.ref_type='CLAIM' AND e.ref_id=NEW.id AND e.type='CREDIT') THEN RAISE EXCEPTION 'Claim credit mismatch'; END IF;
 END IF; RETURN NEW;
END $$;
CREATE FUNCTION privacy_redact_claim(target UUID,subject UUID) RETURNS INTEGER LANGUAGE plpgsql SECURITY DEFINER
 SET search_path=pg_catalog,public,pg_temp AS $$
DECLARE changed INTEGER;
BEGIN
 PERFORM set_config('supplybiz.financial_erasure',subject::text,true);
 UPDATE public.payment_claims p SET upi_txn_ref=NULL,reject_reason=CASE WHEN status='REJECTED' THEN 'Expired retained record' ELSE NULL END
  WHERE p.id=target AND EXISTS(SELECT 1 FROM public.vendor_customers c WHERE c.id=p.vendor_customer_id
   AND public.privacy_financial_scope(c.vendor_id,c.id,greatest(p.created_at,p.decided_at)));
 GET DIAGNOSTICS changed=ROW_COUNT;RETURN changed;
END $$;
REVOKE ALL ON FUNCTION privacy_redact_claim(UUID,UUID) FROM PUBLIC;
CREATE OR REPLACE FUNCTION guard_personal_scope() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
 IF TG_OP='UPDATE' AND OLD.created_at<privacy_financial_cutoff()
  AND OLD.user_id::text=current_setting('supplybiz.financial_erasure',true)
  AND EXISTS(SELECT 1 FROM account_deletions d JOIN users u ON u.id=d.user_id WHERE d.user_id=OLD.user_id AND u.status='DELETED' AND d.status='ERASED' AND d.retention_hold_reason IS NULL) THEN
  IF TG_TABLE_NAME='personal_entries' THEN
   IF NEW.note='' AND OLD.date<privacy_financial_cutoff() AND (to_jsonb(NEW)-'note') IS NOT DISTINCT FROM (to_jsonb(OLD)-'note') THEN RETURN NEW; END IF;
  ELSIF TG_TABLE_NAME='personal_contacts' THEN
   IF NEW.name='Deleted contact' AND NEW.mobile IS NULL AND (to_jsonb(NEW)-ARRAY['name','mobile']) IS NOT DISTINCT FROM (to_jsonb(OLD)-ARRAY['name','mobile'])
    AND NOT EXISTS(SELECT 1 FROM personal_entries WHERE contact_id=OLD.id AND greatest(created_at,date::timestamp AT TIME ZONE 'Asia/Kolkata')>=privacy_financial_cutoff()) THEN RETURN NEW; END IF;
  END IF;
 END IF;
 IF TG_OP='UPDATE' AND (NEW.user_id<>OLD.user_id OR NEW.created_at<>OLD.created_at OR OLD.deleted_at IS NOT NULL OR NEW.version<>OLD.version+1) THEN RAISE EXCEPTION 'Personal ownership or version mismatch'; END IF;
 IF TG_TABLE_NAME='personal_entries' THEN
  IF NOT EXISTS(SELECT 1 FROM personal_contacts c WHERE c.id=NEW.contact_id AND c.user_id=NEW.user_id AND c.deleted_at IS NULL) THEN RAISE EXCEPTION 'Personal contact scope mismatch'; END IF;
 END IF;RETURN NEW;
END $$;
ALTER TABLE vendor_customers DROP CONSTRAINT vendor_customers_mobile_check;
ALTER TABLE vendor_customers ADD CONSTRAINT vendor_customers_mobile_check CHECK(mobile ~ '^\+91[6-9][0-9]{9}$' OR (mobile='ERASED' AND status='INACTIVE' AND deleted_at IS NOT NULL));
CREATE FUNCTION privacy_expire_audits() RETURNS TABLE(removed INTEGER,minimized INTEGER) LANGUAGE plpgsql SECURITY DEFINER
 SET search_path=pg_catalog,public,pg_temp AS $$
BEGIN
 PERFORM pg_advisory_xact_lock(hashtextextended('privacy-audit-retention',0));
 removed:=0;minimized:=0;
 IF EXISTS(SELECT 1 FROM public.account_deletions WHERE status='HELD' OR retention_hold_reason IS NOT NULL) THEN RETURN NEXT; RETURN; END IF;
 PERFORM set_config('supplybiz.audit_retention','expired',true);
 DELETE FROM public.audit_logs WHERE id IN (SELECT a.id FROM public.audit_logs a
  WHERE a.at<clock_timestamp()-interval '3 years'
  AND NOT EXISTS(SELECT 1 FROM public.vendor_plan_assignments p WHERE p.audit_id=a.id)
  ORDER BY a.at,a.id LIMIT 100 FOR UPDATE SKIP LOCKED);
 GET DIAGNOSTICS removed=ROW_COUNT;
 UPDATE public.audit_logs SET actor_id=NULL,before=NULL,after=NULL,ip=NULL WHERE id IN (
  SELECT a.id FROM public.audit_logs a WHERE a.at<clock_timestamp()-interval '3 years'
  AND (a.actor_id IS NOT NULL OR a.before IS NOT NULL OR a.after IS NOT NULL OR a.ip IS NOT NULL)
  AND EXISTS(SELECT 1 FROM public.vendor_plan_assignments p WHERE p.audit_id=a.id)
  AND NOT EXISTS(SELECT 1 FROM public.vendor_plan_assignments p WHERE p.audit_id=a.id AND p.ends_at>clock_timestamp())
  ORDER BY a.at,a.id LIMIT 100 FOR UPDATE SKIP LOCKED);
 GET DIAGNOSTICS minimized=ROW_COUNT;
 IF removed+minimized>0 THEN INSERT INTO public.audit_logs(actor_type,action,entity,after)
  VALUES('SYSTEM','AUDIT_RETENTION_APPLIED','privacy_retention',jsonb_build_object('removed',removed,'minimized',minimized)); END IF;
 RETURN NEXT;
END $$;
REVOKE ALL ON FUNCTION privacy_expire_audits() FROM PUBLIC;
CREATE FUNCTION privacy_redact_ledger(target UUID,subject UUID) RETURNS INTEGER LANGUAGE plpgsql SECURITY DEFINER
 SET search_path=pg_catalog,public,pg_temp AS $$
DECLARE changed INTEGER;
BEGIN
 PERFORM set_config('supplybiz.financial_erasure',subject::text,true);
 UPDATE public.ledger_entries SET note='' WHERE id=target AND note<>''
  AND public.privacy_financial_scope(vendor_id,vendor_customer_id,created_at);
 GET DIAGNOSTICS changed=ROW_COUNT; RETURN changed;
END $$;
CREATE FUNCTION privacy_redact_payment(target UUID,subject UUID) RETURNS INTEGER LANGUAGE plpgsql SECURITY DEFINER
 SET search_path=pg_catalog,public,pg_temp AS $$
DECLARE changed INTEGER;
BEGIN
 PERFORM set_config('supplybiz.financial_erasure',subject::text,true);
 UPDATE public.payments SET note='',client_ref='erased:'||id::text WHERE id=target
  AND (note<>'' OR client_ref<>'erased:'||id::text)
  AND public.privacy_financial_scope(vendor_id,vendor_customer_id,greatest(created_at,received_on::timestamp AT TIME ZONE 'Asia/Kolkata'));
 GET DIAGNOSTICS changed=ROW_COUNT; RETURN changed;
END $$;
REVOKE ALL ON FUNCTION privacy_redact_ledger(UUID,UUID),privacy_redact_payment(UUID,UUID) FROM PUBLIC;
CREATE OR REPLACE FUNCTION reject_order_history_mutation() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
 IF TG_TABLE_NAME='payments' AND TG_OP='UPDATE' AND current_setting('supplybiz.financial_erasure',true) IS NOT NULL THEN RETURN NULL; END IF;
 RAISE EXCEPTION 'Order history is append-only';
END $$;
CREATE FUNCTION guard_payment_privacy() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
 IF NEW.note='' AND NEW.client_ref='erased:'||OLD.id::text
  AND (to_jsonb(NEW)-ARRAY['note','client_ref']) IS NOT DISTINCT FROM (to_jsonb(OLD)-ARRAY['note','client_ref'])
  AND privacy_financial_scope(OLD.vendor_id,OLD.vendor_customer_id,greatest(OLD.created_at,OLD.received_on::timestamp AT TIME ZONE 'Asia/Kolkata')) THEN RETURN NEW; END IF;
 RAISE EXCEPTION 'Payment receipts are append-only';
END $$;
CREATE TRIGGER payment_privacy BEFORE UPDATE ON payments FOR EACH ROW EXECUTE FUNCTION guard_payment_privacy();
CREATE OR REPLACE FUNCTION reject_audit_mutation() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
 IF TG_TABLE_NAME='audit_logs' AND current_setting('supplybiz.audit_retention',true)='expired'
  AND OLD.at<clock_timestamp()-interval '3 years'
  AND NOT EXISTS(SELECT 1 FROM account_deletions WHERE status='HELD' OR retention_hold_reason IS NOT NULL) THEN
  IF TG_OP='DELETE' AND NOT EXISTS(SELECT 1 FROM vendor_plan_assignments WHERE audit_id=OLD.id) THEN RETURN OLD; END IF;
  IF TG_OP='UPDATE' AND NEW.actor_id IS NULL AND NEW.before IS NULL AND NEW.after IS NULL AND NEW.ip IS NULL
   AND (to_jsonb(NEW)-ARRAY['actor_id','before','after','ip']) IS NOT DISTINCT FROM (to_jsonb(OLD)-ARRAY['actor_id','before','after','ip']) THEN RETURN NEW; END IF;
 END IF;
 RAISE EXCEPTION 'Audit records are append-only';
END $$;
