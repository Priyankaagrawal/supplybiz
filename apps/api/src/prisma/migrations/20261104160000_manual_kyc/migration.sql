CREATE TABLE vendor_kyc (
 id UUID PRIMARY KEY DEFAULT gen_random_uuid(), vendor_id UUID NOT NULL REFERENCES vendors(id) ON DELETE RESTRICT,
 status VARCHAR(24) NOT NULL DEFAULT 'MANUAL_REVIEW' CHECK(status IN ('MANUAL_REVIEW','VERIFIED','REJECTED')),
 verification_method VARCHAR(24) NOT NULL DEFAULT 'MANUAL_REVIEW' CHECK(verification_method = 'MANUAL_REVIEW'),
 provider_checks VARCHAR(16) NOT NULL DEFAULT 'NOT_RUN' CHECK(provider_checks = 'NOT_RUN'),
 aadhaar_front_media_id UUID NOT NULL REFERENCES media_files(id),
 aadhaar_back_media_id UUID NOT NULL REFERENCES media_files(id), pan_media_id UUID NOT NULL REFERENCES media_files(id),
 pan_enc TEXT NOT NULL, pan_last4 VARCHAR(4) NOT NULL,
 account_number_enc TEXT NOT NULL, account_last4 VARCHAR(4) NOT NULL,
 holder_name VARCHAR(120) NOT NULL, bank_name VARCHAR(120) NOT NULL, ifsc VARCHAR(11) NOT NULL,
 upi_id VARCHAR(321), submitted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
 reviewed_at TIMESTAMPTZ, reviewer_id UUID REFERENCES admin_users(id), reason VARCHAR(500),
 CHECK ((status = 'MANUAL_REVIEW' AND reviewed_at IS NULL AND reviewer_id IS NULL AND reason IS NULL)
   OR (status IN ('VERIFIED','REJECTED') AND reviewed_at IS NOT NULL AND reviewer_id IS NOT NULL AND length(trim(reason)) >= 3))
);
CREATE INDEX vendor_kyc_vendor_id_submitted_at_idx ON vendor_kyc(vendor_id,submitted_at);
CREATE INDEX vendor_kyc_status_submitted_at_id_idx ON vendor_kyc(status,submitted_at,id);
CREATE UNIQUE INDEX vendor_kyc_one_pending ON vendor_kyc(vendor_id) WHERE status = 'MANUAL_REVIEW';
CREATE TABLE kyc_notices (
 id UUID PRIMARY KEY DEFAULT gen_random_uuid(), user_id UUID NOT NULL REFERENCES users(id),
 submission_id UUID NOT NULL UNIQUE REFERENCES vendor_kyc(id), status VARCHAR(24) NOT NULL,
 reason VARCHAR(500), created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX kyc_notices_user_id_created_at_idx ON kyc_notices(user_id,created_at);
-- A decision closes a revision permanently; resubmission creates a fresh revision.
CREATE FUNCTION protect_kyc_revision() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
 IF TG_OP = 'DELETE' OR OLD.status <> 'MANUAL_REVIEW' THEN
  RAISE EXCEPTION 'KYC revisions are immutable';
 END IF;
 IF (to_jsonb(NEW) - ARRAY['status','reviewed_at','reviewer_id','reason'])
    IS DISTINCT FROM (to_jsonb(OLD) - ARRAY['status','reviewed_at','reviewer_id','reason']) THEN
  RAISE EXCEPTION 'KYC submission fields are immutable';
 END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER kyc_revision_immutable BEFORE UPDATE OR DELETE ON vendor_kyc
FOR EACH ROW EXECUTE FUNCTION protect_kyc_revision();
CREATE TRIGGER kyc_no_truncate BEFORE TRUNCATE ON vendor_kyc
FOR EACH STATEMENT EXECUTE FUNCTION reject_audit_mutation();
CREATE TRIGGER kyc_notices_immutable BEFORE UPDATE OR DELETE ON kyc_notices
FOR EACH ROW EXECUTE FUNCTION reject_audit_mutation();
