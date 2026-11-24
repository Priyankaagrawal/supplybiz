-- The advisory mutex serializes retention. Do not require UPDATE privileges on append-only source logs merely to select deletion candidates.
CREATE OR REPLACE FUNCTION privacy_expire_sources() RETURNS INTEGER LANGUAGE plpgsql SECURITY DEFINER
 SET search_path=pg_catalog,public,pg_temp AS $$
DECLARE total INTEGER:=0;changed INTEGER;
BEGIN
 PERFORM pg_advisory_xact_lock(hashtextextended('privacy-audit-retention',0));
 IF EXISTS(SELECT 1 FROM public.account_deletions WHERE status='HELD' OR retention_hold_reason IS NOT NULL) THEN RETURN 0; END IF;
 PERFORM set_config('supplybiz.audit_retention','expired',true);
 DELETE FROM public.admin_auth_events WHERE id IN (SELECT id FROM public.admin_auth_events WHERE at<clock_timestamp()-interval '3 years' ORDER BY at,id LIMIT 100);
 GET DIAGNOSTICS changed=ROW_COUNT;total:=total+changed;
 DELETE FROM public.media_access_events WHERE id IN (SELECT id FROM public.media_access_events WHERE created_at<clock_timestamp()-interval '3 years' ORDER BY created_at,id LIMIT 100);
 GET DIAGNOSTICS changed=ROW_COUNT;total:=total+changed;
 DELETE FROM public.kyc_notices WHERE id IN (SELECT id FROM public.kyc_notices WHERE created_at<clock_timestamp()-interval '3 years' ORDER BY created_at,id LIMIT 100);
 GET DIAGNOSTICS changed=ROW_COUNT;total:=total+changed;
 DELETE FROM public.privacy_exports WHERE id IN (SELECT id FROM public.privacy_exports WHERE created_at<clock_timestamp()-interval '3 years' ORDER BY created_at,id LIMIT 100);
 GET DIAGNOSTICS changed=ROW_COUNT;total:=total+changed;
 UPDATE public.management_requests SET response=response||jsonb_build_object('reason',NULL) WHERE request_key IN (
  SELECT request_key FROM public.management_requests WHERE path LIKE 'privacy/%' AND created_at<clock_timestamp()-interval '3 years' AND response->>'reason' IS NOT NULL LIMIT 100);
 GET DIAGNOSTICS changed=ROW_COUNT;total:=total+changed;
 DELETE FROM public.idempotency_keys WHERE idempotency_key IN (SELECT idempotency_key FROM public.idempotency_keys WHERE expires_at<clock_timestamp() ORDER BY expires_at LIMIT 100);
 GET DIAGNOSTICS changed=ROW_COUNT;total:=total+changed;
 IF total>0 THEN INSERT INTO public.audit_logs(actor_type,action,entity,after) VALUES('SYSTEM','AUDIT_SOURCE_RETENTION_APPLIED','privacy_retention',jsonb_build_object('removedOrMinimized',total)); END IF;
 RETURN total;
END $$;
