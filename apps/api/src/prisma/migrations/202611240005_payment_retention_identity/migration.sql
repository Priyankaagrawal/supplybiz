-- Permanent server-generated replay identities are pseudonymous proof, never rewritten.
CREATE OR REPLACE FUNCTION guard_payment_privacy() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
 IF NEW.note='' AND (to_jsonb(NEW)-'note') IS NOT DISTINCT FROM (to_jsonb(OLD)-'note')
  AND privacy_financial_scope(OLD.vendor_id,OLD.vendor_customer_id,greatest(OLD.created_at,OLD.received_on::timestamp AT TIME ZONE 'Asia/Kolkata')) THEN RETURN NEW; END IF;
 RAISE EXCEPTION 'Payment receipts are append-only';
END $$;
CREATE OR REPLACE FUNCTION privacy_redact_payment(target UUID,subject UUID) RETURNS INTEGER LANGUAGE plpgsql SECURITY DEFINER
 SET search_path=pg_catalog,public,pg_temp AS $$
DECLARE changed INTEGER;
BEGIN
 PERFORM set_config('supplybiz.financial_erasure',subject::text,true);
 UPDATE public.payments SET note='' WHERE id=target AND note<>''
  AND public.privacy_financial_scope(vendor_id,vendor_customer_id,greatest(created_at,received_on::timestamp AT TIME ZONE 'Asia/Kolkata'));
 GET DIAGNOSTICS changed=ROW_COUNT; RETURN changed;
END $$;
DO $$ BEGIN IF to_regrole('supplybiz_privacy_owner') IS NOT NULL THEN
 REVOKE UPDATE(client_ref) ON payments FROM supplybiz_privacy_owner;
END IF;END $$;
