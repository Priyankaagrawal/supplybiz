-- T-049 additive source receipts. No historical delivery/receipt fabrication.
CREATE TABLE payments (
 id UUID PRIMARY KEY,
 vendor_id UUID NOT NULL REFERENCES vendors(id) ON DELETE RESTRICT,
 vendor_customer_id UUID NOT NULL REFERENCES vendor_customers(id) ON DELETE RESTRICT,
 order_id UUID UNIQUE REFERENCES orders(id) ON DELETE RESTRICT,
 amount_paise BIGINT NOT NULL CHECK (amount_paise>0),
 method VARCHAR(8) NOT NULL CHECK (method IN ('CASH','UPI','BANK','WALLET')),
 received_on DATE NOT NULL,
 note VARCHAR(200) NOT NULL,
 client_ref VARCHAR(120) NOT NULL,
 created_by UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
 created_at TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
 UNIQUE(vendor_id,client_ref)
);
CREATE INDEX payments_vendor_customer_id_received_on_idx ON payments(vendor_customer_id,received_on);
CREATE FUNCTION guard_payment_scope() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
 IF NOT EXISTS(SELECT 1 FROM vendor_customers c WHERE c.id=NEW.vendor_customer_id AND c.vendor_id=NEW.vendor_id AND c.deleted_at IS NULL)
 OR NOT EXISTS(SELECT 1 FROM vendors v WHERE v.id=NEW.vendor_id AND v.user_id=NEW.created_by)
 OR (NEW.order_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM orders o WHERE o.id=NEW.order_id AND o.vendor_id=NEW.vendor_id AND o.vendor_customer_id=NEW.vendor_customer_id))
 THEN RAISE EXCEPTION 'Payment scope mismatch'; END IF;
 RETURN NEW;
END;
$$;
CREATE TRIGGER payment_scope_guard BEFORE INSERT ON payments FOR EACH ROW EXECUTE FUNCTION guard_payment_scope();
CREATE TRIGGER payments_immutable BEFORE UPDATE OR DELETE OR TRUNCATE ON payments
 FOR EACH STATEMENT EXECUTE FUNCTION reject_order_history_mutation();
-- One stock movement per delivered source/product, including alternate-key retries.
CREATE UNIQUE INDEX delivered_stock_source_once ON stock_movements(product_id,ref_id)
 WHERE reason='ORDER' AND ref_id IS NOT NULL;
