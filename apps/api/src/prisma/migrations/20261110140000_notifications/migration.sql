CREATE TABLE notifications (
 id UUID PRIMARY KEY, user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
 role user_role_type NOT NULL, category VARCHAR(16) NOT NULL CHECK (category IN ('ORDERS','PAYMENTS','DELIVERY','SYSTEM')),
 type VARCHAR(40) NOT NULL, source_key VARCHAR(120) NOT NULL UNIQUE,
 title VARCHAR(120) NOT NULL, body VARCHAR(300) NOT NULL, data JSONB NOT NULL,
 mandatory BOOLEAN NOT NULL DEFAULT false, read_at TIMESTAMPTZ, cleared_at TIMESTAMPTZ,
 created_at TIMESTAMPTZ NOT NULL DEFAULT now(), CHECK (role <> 'CUSTOMER' OR category <> 'DELIVERY'),
 CHECK (type NOT IN ('KYC_STATUS','SECURITY') OR (mandatory AND category = 'SYSTEM'))
);
CREATE INDEX notifications_user_id_role_created_at_id_idx ON notifications(user_id, role, created_at, id);
CREATE INDEX notifications_created_at_idx ON notifications(created_at);
CREATE TABLE notification_pushes (
 id UUID PRIMARY KEY, notification_id UUID NOT NULL REFERENCES notifications(id) ON DELETE CASCADE,
 device_id UUID NOT NULL REFERENCES devices(id) ON DELETE RESTRICT, token_hash CHAR(64) NOT NULL,
 status VARCHAR(16) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING','SENT','SKIPPED','INVALID')),
 event_id UUID NOT NULL UNIQUE REFERENCES outbox_events(id) ON DELETE RESTRICT, sent_at TIMESTAMPTZ,
 UNIQUE(notification_id, device_id)
);
-- Preserve prior actual KYC inbox history without sending retrospective pushes.
INSERT INTO notifications(id,user_id,role,category,type,source_key,title,body,data,mandatory,created_at)
 SELECT id,user_id,'VENDOR','SYSTEM','KYC_STATUS','kyc:' || submission_id,
 'KYC status updated','Open Supply Biz to view your verification decision.',
 '{"path":"/vendor/onboarding/status"}'::jsonb,true,created_at
 FROM kyc_notices WHERE created_at > now() - interval '90 days';
