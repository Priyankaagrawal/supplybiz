CREATE OR REPLACE FUNCTION reject_admin_auth_event_mutation() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
 IF TG_OP='DELETE' AND current_setting('supplybiz.audit_retention',true)='expired' AND OLD.at<clock_timestamp()-interval '3 years'
  AND NOT EXISTS(SELECT 1 FROM account_deletions WHERE status='HELD' OR retention_hold_reason IS NOT NULL) THEN RETURN OLD; END IF;
 RAISE EXCEPTION 'Admin authentication events are append-only';
END $$;
CREATE OR REPLACE FUNCTION reject_media_access_event_mutation() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
 IF TG_OP='DELETE' AND current_setting('supplybiz.audit_retention',true)='expired' AND OLD.created_at<clock_timestamp()-interval '3 years'
  AND NOT EXISTS(SELECT 1 FROM account_deletions WHERE status='HELD' OR retention_hold_reason IS NOT NULL) THEN RETURN OLD; END IF;
 RAISE EXCEPTION 'Media access events are append-only';
END $$;
CREATE OR REPLACE FUNCTION reject_audit_mutation() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
 IF current_setting('supplybiz.audit_retention',true)='expired'
  AND NOT EXISTS(SELECT 1 FROM account_deletions WHERE status='HELD' OR retention_hold_reason IS NOT NULL) THEN
  IF TG_TABLE_NAME='kyc_notices' THEN
   IF TG_OP='DELETE' AND OLD.created_at<clock_timestamp()-interval '3 years' THEN RETURN OLD; END IF;
  ELSIF TG_TABLE_NAME='audit_logs' THEN
   IF OLD.at<clock_timestamp()-interval '3 years' THEN
    IF TG_OP='DELETE' AND NOT EXISTS(SELECT 1 FROM vendor_plan_assignments WHERE audit_id=OLD.id) THEN RETURN OLD; END IF;
    IF TG_OP='UPDATE' AND NEW.actor_id IS NOT DISTINCT FROM OLD.actor_id AND NEW.before IS NULL AND NEW.after IS NULL AND NEW.ip IS NULL
     AND (to_jsonb(NEW)-ARRAY['before','after','ip']) IS NOT DISTINCT FROM (to_jsonb(OLD)-ARRAY['before','after','ip']) THEN RETURN NEW; END IF;
   END IF;
  END IF;
 END IF;
 RAISE EXCEPTION 'Audit records are append-only';
END $$;
CREATE FUNCTION privacy_expire_sources() RETURNS INTEGER LANGUAGE plpgsql SECURITY DEFINER
 SET search_path=pg_catalog,public,pg_temp AS $$
DECLARE total INTEGER:=0;changed INTEGER;
BEGIN
 PERFORM pg_advisory_xact_lock(hashtextextended('privacy-audit-retention',0));
 IF EXISTS(SELECT 1 FROM public.account_deletions WHERE status='HELD' OR retention_hold_reason IS NOT NULL) THEN RETURN 0; END IF;
 PERFORM set_config('supplybiz.audit_retention','expired',true);
 DELETE FROM public.admin_auth_events WHERE id IN (SELECT id FROM public.admin_auth_events WHERE at<clock_timestamp()-interval '3 years' ORDER BY at,id LIMIT 100 FOR UPDATE SKIP LOCKED);
 GET DIAGNOSTICS changed=ROW_COUNT;total:=total+changed;
 DELETE FROM public.media_access_events WHERE id IN (SELECT id FROM public.media_access_events WHERE created_at<clock_timestamp()-interval '3 years' ORDER BY created_at,id LIMIT 100 FOR UPDATE SKIP LOCKED);
 GET DIAGNOSTICS changed=ROW_COUNT;total:=total+changed;
 DELETE FROM public.kyc_notices WHERE id IN (SELECT id FROM public.kyc_notices WHERE created_at<clock_timestamp()-interval '3 years' ORDER BY created_at,id LIMIT 100 FOR UPDATE SKIP LOCKED);
 GET DIAGNOSTICS changed=ROW_COUNT;total:=total+changed;
 DELETE FROM public.privacy_exports WHERE id IN (SELECT id FROM public.privacy_exports WHERE created_at<clock_timestamp()-interval '3 years' ORDER BY created_at,id LIMIT 100 FOR UPDATE SKIP LOCKED);
 GET DIAGNOSTICS changed=ROW_COUNT;total:=total+changed;
 UPDATE public.management_requests SET response=response||jsonb_build_object('reason',NULL) WHERE request_key IN (
  SELECT request_key FROM public.management_requests WHERE path LIKE 'privacy/%' AND created_at<clock_timestamp()-interval '3 years' AND response->>'reason' IS NOT NULL LIMIT 100 FOR UPDATE SKIP LOCKED);
 GET DIAGNOSTICS changed=ROW_COUNT;total:=total+changed;
 DELETE FROM public.idempotency_keys WHERE idempotency_key IN (SELECT idempotency_key FROM public.idempotency_keys WHERE expires_at<clock_timestamp() ORDER BY expires_at LIMIT 100 FOR UPDATE SKIP LOCKED);
 GET DIAGNOSTICS changed=ROW_COUNT;total:=total+changed;
 IF total>0 THEN INSERT INTO public.audit_logs(actor_type,action,entity,after) VALUES('SYSTEM','AUDIT_SOURCE_RETENTION_APPLIED','privacy_retention',jsonb_build_object('removedOrMinimized',total)); END IF;
 RETURN total;
END $$;
REVOKE ALL ON FUNCTION privacy_expire_sources() FROM PUBLIC;
