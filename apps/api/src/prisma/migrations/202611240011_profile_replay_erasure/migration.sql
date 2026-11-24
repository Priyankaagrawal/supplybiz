-- Keep permanent replay identity immutable while erasing due profile copies.
CREATE OR REPLACE FUNCTION reject_audit_mutation() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE subject UUID;vendor UUID;expected JSONB;
BEGIN
 IF TG_TABLE_NAME='management_requests' AND TG_OP='UPDATE' THEN
  IF (to_jsonb(NEW)-'response') IS DISTINCT FROM (to_jsonb(OLD)-'response') THEN
   RAISE EXCEPTION 'Replay identity is immutable';
  END IF;
  IF current_setting('supplybiz.audit_retention',true)='expired'
   AND OLD.path LIKE 'privacy/%' AND OLD.created_at<clock_timestamp()-interval '3 years'
   AND NOT EXISTS(SELECT 1 FROM account_deletions WHERE status='HELD' OR retention_hold_reason IS NOT NULL)
   AND NEW.response IS NOT DISTINCT FROM OLD.response||jsonb_build_object('reason',NULL) THEN RETURN NEW; END IF;
  subject:=NULLIF(current_setting('supplybiz.retention_user',true),'')::uuid;
  IF subject IS NOT NULL AND EXISTS(SELECT 1 FROM account_deletions d JOIN users u ON u.id=d.user_id
   WHERE d.user_id=subject AND u.status='DELETED' AND d.status='ERASING' AND d.hold_reason IS NULL
    AND d.erase_by<=clock_timestamp()+interval '1 day') THEN
   SELECT id INTO vendor FROM vendors WHERE user_id=subject;
   expected:=OLD.response
    || CASE WHEN OLD.response->>'id'=subject::text THEN jsonb_build_object('name',NULL,'mobile','') ELSE '{}'::jsonb END
    || CASE WHEN OLD.response->>'id'=vendor::text THEN jsonb_build_object('businessName','Deleted account','city',NULL) ELSE '{}'::jsonb END
    || CASE WHEN OLD.response#>>'{account,id}'=subject::text THEN jsonb_build_object('account',(OLD.response->'account')||jsonb_build_object('name',NULL,'mobile','')) ELSE '{}'::jsonb END;
   IF expected IS DISTINCT FROM OLD.response AND NEW.response IS NOT DISTINCT FROM expected THEN RETURN NEW; END IF;
  END IF;
 ELSIF current_setting('supplybiz.audit_retention',true)='expired'
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
