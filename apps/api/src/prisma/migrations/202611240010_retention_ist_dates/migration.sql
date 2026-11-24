-- Financial date columns use explicit IST instants, independent of session timezone.
CREATE OR REPLACE FUNCTION guard_personal_scope() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
 IF TG_OP='UPDATE' AND OLD.created_at<privacy_financial_cutoff()
  AND OLD.user_id::text=current_setting('supplybiz.financial_erasure',true)
  AND EXISTS(SELECT 1 FROM account_deletions d JOIN users u ON u.id=d.user_id WHERE d.user_id=OLD.user_id AND u.status='DELETED' AND d.status='ERASED' AND d.retention_hold_reason IS NULL) THEN
  IF TG_TABLE_NAME='personal_entries' THEN
   IF NEW.note='' AND (OLD.date::timestamp AT TIME ZONE 'Asia/Kolkata')<privacy_financial_cutoff() AND (to_jsonb(NEW)-'note') IS NOT DISTINCT FROM (to_jsonb(OLD)-'note') THEN RETURN NEW; END IF;
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
