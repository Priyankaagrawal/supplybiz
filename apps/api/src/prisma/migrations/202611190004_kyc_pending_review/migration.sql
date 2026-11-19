-- T-106 / ADR-034: expand the manual-review state machine, retaining closed evidence.
BEGIN;
ALTER TABLE vendor_kyc DROP CONSTRAINT vendor_kyc_status_check;
ALTER TABLE vendor_kyc ADD CONSTRAINT vendor_kyc_status_check
 CHECK (status IN ('MANUAL_REVIEW','PENDING','SUPERSEDED','VERIFIED','REJECTED'));
ALTER TABLE vendor_kyc DROP CONSTRAINT vendor_kyc_check;
ALTER TABLE vendor_kyc ADD CONSTRAINT vendor_kyc_check CHECK (
 (status IN ('MANUAL_REVIEW','PENDING','SUPERSEDED') AND reviewed_at IS NULL AND reviewer_id IS NULL AND reason IS NULL)
 OR (status IN ('VERIFIED','REJECTED') AND reviewed_at IS NOT NULL AND reviewer_id IS NOT NULL AND length(trim(reason)) >= 3)
);
DROP INDEX vendor_kyc_one_pending;
CREATE UNIQUE INDEX vendor_kyc_one_pending ON vendor_kyc(vendor_id) WHERE status IN ('MANUAL_REVIEW','PENDING');
CREATE OR REPLACE FUNCTION protect_kyc_revision() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
 IF TG_OP = 'DELETE' OR OLD.status NOT IN ('MANUAL_REVIEW','PENDING') THEN
  RAISE EXCEPTION 'KYC revisions are immutable';
 END IF;
 IF NOT (NEW.status IN ('VERIFIED','REJECTED') OR (OLD.status='PENDING' AND NEW.status='SUPERSEDED')) THEN
  RAISE EXCEPTION 'Invalid KYC review transition';
 END IF;
 IF (to_jsonb(NEW) - ARRAY['status','reviewed_at','reviewer_id','reason'])
    IS DISTINCT FROM (to_jsonb(OLD) - ARRAY['status','reviewed_at','reviewer_id','reason']) THEN
  RAISE EXCEPTION 'KYC submission fields are immutable';
 END IF;
 RETURN NEW;
END $$;
COMMIT;
