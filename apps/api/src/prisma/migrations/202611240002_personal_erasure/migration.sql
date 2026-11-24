-- Narrow retention exception: ordinary KYC updates/deletes remain immutable.
ALTER TABLE account_deletions DROP CONSTRAINT account_deletions_status_check;
ALTER TABLE account_deletions ADD CONSTRAINT account_deletions_status_check
 CHECK(status IN ('PENDING_ERASURE','HELD','ERASING','ERASED'));
ALTER TABLE media_files DROP CONSTRAINT media_files_status_check;
ALTER TABLE media_files ADD CONSTRAINT media_files_status_check CHECK(status IN ('READY','ERASING','ERASED'));
CREATE OR REPLACE FUNCTION protect_kyc_revision() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
 IF TG_OP='UPDATE' AND
   (to_jsonb(NEW) - ARRAY['business_name','pan_enc','pan_last4','account_number_enc','account_last4','holder_name','bank_name','ifsc','upi_id'])
    IS NOT DISTINCT FROM
   (to_jsonb(OLD) - ARRAY['business_name','pan_enc','pan_last4','account_number_enc','account_last4','holder_name','bank_name','ifsc','upi_id'])
   AND NEW.business_name IS NULL AND NEW.pan_enc='' AND NEW.pan_last4=''
   AND NEW.account_number_enc='' AND NEW.account_last4='' AND NEW.holder_name='Deleted account'
   AND NEW.bank_name='' AND NEW.ifsc='' AND NEW.upi_id IS NULL
   AND EXISTS(SELECT 1 FROM vendors v JOIN users u ON u.id=v.user_id JOIN account_deletions d ON d.user_id=u.id
     WHERE v.id=OLD.vendor_id AND u.status='DELETED' AND d.status='ERASING'
     AND d.erase_by<=clock_timestamp()+interval '1 day' AND d.hold_reason IS NULL
     AND current_setting('supplybiz.retention_user',true)=u.id::text)
 THEN RETURN NEW; END IF;
 IF TG_OP='DELETE' OR OLD.status NOT IN ('MANUAL_REVIEW','PENDING') THEN RAISE EXCEPTION 'KYC revisions are immutable'; END IF;
 IF NOT (NEW.status IN ('VERIFIED','REJECTED') OR (OLD.status='PENDING' AND NEW.status='SUPERSEDED')) THEN RAISE EXCEPTION 'Invalid KYC review transition'; END IF;
 IF (to_jsonb(NEW)-ARRAY['status','reviewed_at','reviewer_id','reason']) IS DISTINCT FROM
    (to_jsonb(OLD)-ARRAY['status','reviewed_at','reviewer_id','reason']) THEN RAISE EXCEPTION 'KYC submission fields are immutable'; END IF;
 RETURN NEW;
END $$;
