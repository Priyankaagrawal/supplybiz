-- Preserve financial history visibility: redaction does not soft-delete a customer.
ALTER TABLE vendor_customers ADD COLUMN privacy_erased_at TIMESTAMPTZ;
ALTER TABLE vendor_customers DROP CONSTRAINT vendor_customers_mobile_check;
ALTER TABLE vendor_customers ADD CONSTRAINT vendor_customers_mobile_check CHECK(
 mobile ~ '^\+91[6-9][0-9]{9}$' OR (mobile='' AND status='INACTIVE' AND privacy_erased_at IS NOT NULL));
DROP INDEX vendor_customers_vendor_mobile_live;
CREATE UNIQUE INDEX vendor_customers_vendor_mobile_live ON vendor_customers(vendor_id,mobile) WHERE deleted_at IS NULL AND mobile<>'';
