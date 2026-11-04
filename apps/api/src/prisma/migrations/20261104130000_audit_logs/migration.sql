CREATE TABLE audit_logs (
 id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
 actor_type VARCHAR(16) NOT NULL CHECK (actor_type IN ('ADMIN','USER','SYSTEM')),
 actor_id UUID, action VARCHAR(64) NOT NULL, entity VARCHAR(64) NOT NULL,
 entity_id UUID, before JSONB, after JSONB, ip VARCHAR(45),
 at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp()
);
CREATE INDEX audit_logs_at_id_idx ON audit_logs(at, id);
CREATE FUNCTION reject_audit_mutation() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN RAISE EXCEPTION 'Audit logs are append-only'; END $$;
CREATE TRIGGER audit_logs_immutable BEFORE UPDATE OR DELETE ON audit_logs
FOR EACH ROW EXECUTE FUNCTION reject_audit_mutation();
CREATE TRIGGER audit_logs_no_truncate BEFORE TRUNCATE ON audit_logs
FOR EACH STATEMENT EXECUTE FUNCTION reject_audit_mutation();

-- Capture existing admin writes atomically. Explicit projection excludes email,
-- credentials, TOTP secrets/steps and future fields by default.
CREATE FUNCTION audit_admin_user() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE old_safe JSONB; new_safe JSONB; actor UUID;
BEGIN
 actor := NULLIF(current_setting('supplybiz.audit_actor', true), '')::uuid;
 IF TG_OP <> 'INSERT' THEN
  old_safe := jsonb_build_object('role', OLD.role, 'status', OLD.status,
   'failed_attempts', OLD.failed_attempts, 'locked_until', OLD.locked_until,
   'last_login_at', OLD.last_login_at, 'totp_enrolled', OLD.totp_secret_enc IS NOT NULL);
 END IF;
 IF TG_OP <> 'DELETE' THEN
  new_safe := jsonb_build_object('role', NEW.role, 'status', NEW.status,
   'failed_attempts', NEW.failed_attempts, 'locked_until', NEW.locked_until,
   'last_login_at', NEW.last_login_at, 'totp_enrolled', NEW.totp_secret_enc IS NOT NULL);
 END IF;
 INSERT INTO audit_logs(actor_type, actor_id, action, entity, entity_id, before, after, ip)
 VALUES(CASE WHEN actor IS NULL THEN 'SYSTEM' ELSE 'ADMIN' END, actor,
 'ADMIN_ACCOUNT_' || TG_OP, 'admin_users', COALESCE(NEW.id, OLD.id), old_safe, new_safe,
 NULLIF(current_setting('supplybiz.audit_ip', true), ''));
 RETURN COALESCE(NEW, OLD);
END $$;
CREATE TRIGGER admin_user_audit AFTER INSERT OR UPDATE OR DELETE ON admin_users
FOR EACH ROW EXECUTE FUNCTION audit_admin_user();

CREATE FUNCTION audit_admin_event() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
 IF TG_TABLE_NAME = 'admin_auth_events' THEN
  INSERT INTO audit_logs(id, actor_type, actor_id, action, entity, entity_id, at, ip)
  VALUES(NEW.id, 'ADMIN', NEW.admin_id, NEW.action, 'admin_auth', NEW.admin_id, NEW.at,
   NULLIF(current_setting('supplybiz.audit_ip', true), ''));
 ELSE
  INSERT INTO audit_logs(id, actor_type, actor_id, action, entity, entity_id, at, ip)
  VALUES(NEW.id, 'ADMIN', NEW.admin_user_id, NEW.action, 'media_files', NEW.media_id, NEW.created_at,
   NULLIF(current_setting('supplybiz.audit_ip', true), ''));
 END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER admin_auth_audit AFTER INSERT ON admin_auth_events
FOR EACH ROW EXECUTE FUNCTION audit_admin_event();
CREATE TRIGGER media_access_audit AFTER INSERT ON media_access_events
FOR EACH ROW EXECUTE FUNCTION audit_admin_event();
-- Preserve original actor/time; unavailable historical IP/snapshots stay null.
INSERT INTO audit_logs(id, actor_type, actor_id, action, entity, entity_id, at)
 SELECT id, 'ADMIN', admin_id, action, 'admin_auth', admin_id, at FROM admin_auth_events;
INSERT INTO audit_logs(id, actor_type, actor_id, action, entity, entity_id, at)
 SELECT id, 'ADMIN', admin_user_id, action, 'media_files', media_id, created_at FROM media_access_events;
