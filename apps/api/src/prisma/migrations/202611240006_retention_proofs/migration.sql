-- Retain mandatory nonempty ledger tombstones and audited grant identity proofs.
CREATE OR REPLACE FUNCTION reject_ledger_mutation() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
 IF TG_TABLE_NAME='ledger_entries' AND TG_OP='UPDATE' THEN
  IF NEW.note='Expired retained record' AND (to_jsonb(NEW)-'note') IS NOT DISTINCT FROM (to_jsonb(OLD)-'note')
   AND privacy_financial_scope(OLD.vendor_id,OLD.vendor_customer_id,greatest(OLD.created_at,OLD.entry_date::timestamp AT TIME ZONE 'Asia/Kolkata')) THEN RETURN NEW; END IF;
 END IF;
 RAISE EXCEPTION 'Ledger entries are append-only';
END $$;
CREATE OR REPLACE FUNCTION privacy_redact_ledger(target UUID,subject UUID) RETURNS INTEGER LANGUAGE plpgsql SECURITY DEFINER
 SET search_path=pg_catalog,public,pg_temp AS $$
DECLARE changed INTEGER;
BEGIN
 PERFORM set_config('supplybiz.financial_erasure',subject::text,true);
 UPDATE public.ledger_entries SET note='Expired retained record' WHERE id=target AND note NOT IN ('','Expired retained record')
  AND public.privacy_financial_scope(vendor_id,vendor_customer_id,greatest(created_at,entry_date::timestamp AT TIME ZONE 'Asia/Kolkata'));
 GET DIAGNOSTICS changed=ROW_COUNT; RETURN changed;
END $$;
CREATE OR REPLACE FUNCTION reject_audit_mutation() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
 IF TG_TABLE_NAME='audit_logs' AND current_setting('supplybiz.audit_retention',true)='expired'
  AND OLD.at<clock_timestamp()-interval '3 years'
  AND NOT EXISTS(SELECT 1 FROM account_deletions WHERE status='HELD' OR retention_hold_reason IS NOT NULL) THEN
  IF TG_OP='DELETE' AND NOT EXISTS(SELECT 1 FROM vendor_plan_assignments WHERE audit_id=OLD.id) THEN RETURN OLD; END IF;
  IF TG_OP='UPDATE' AND NEW.actor_id IS NOT DISTINCT FROM OLD.actor_id AND NEW.before IS NULL AND NEW.after IS NULL AND NEW.ip IS NULL
   AND (to_jsonb(NEW)-ARRAY['before','after','ip']) IS NOT DISTINCT FROM (to_jsonb(OLD)-ARRAY['before','after','ip']) THEN RETURN NEW; END IF;
 END IF;
 RAISE EXCEPTION 'Audit records are append-only';
END $$;
CREATE OR REPLACE FUNCTION privacy_expire_audits() RETURNS TABLE(removed INTEGER,minimized INTEGER) LANGUAGE plpgsql SECURITY DEFINER
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
 UPDATE public.audit_logs SET before=NULL,after=NULL,ip=NULL WHERE id IN (
  SELECT a.id FROM public.audit_logs a WHERE a.at<clock_timestamp()-interval '3 years'
  AND (a.before IS NOT NULL OR a.after IS NOT NULL OR a.ip IS NOT NULL)
  AND EXISTS(SELECT 1 FROM public.vendor_plan_assignments p WHERE p.audit_id=a.id)
  AND NOT EXISTS(SELECT 1 FROM public.vendor_plan_assignments p WHERE p.audit_id=a.id AND p.ends_at>clock_timestamp())
  ORDER BY a.at,a.id LIMIT 100 FOR UPDATE SKIP LOCKED);
 GET DIAGNOSTICS minimized=ROW_COUNT;
 IF removed+minimized>0 THEN INSERT INTO public.audit_logs(actor_type,action,entity,after)
  VALUES('SYSTEM','AUDIT_RETENTION_APPLIED','privacy_retention',jsonb_build_object('removed',removed,'minimized',minimized)); END IF;
 RETURN NEXT;
END $$;
