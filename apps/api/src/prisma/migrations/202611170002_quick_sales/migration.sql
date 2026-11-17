-- T-079: additive immutable POS sources; no financial backfill or grant changes.
CREATE SEQUENCE sale_number_sequence;
CREATE TABLE sales (
 id UUID PRIMARY KEY,sale_no VARCHAR(40) NOT NULL UNIQUE,
 vendor_id UUID NOT NULL REFERENCES vendors(id) ON DELETE RESTRICT,
 vendor_customer_id UUID REFERENCES vendor_customers(id) ON DELETE RESTRICT,
 created_by UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
 total_paise BIGINT NOT NULL CHECK(total_paise>=0),
 paid_paise BIGINT NOT NULL CHECK(paid_paise>=0 AND paid_paise<=total_paise),
 balance_paise BIGINT NOT NULL CHECK(balance_paise=total_paise-paid_paise),
 payment_method VARCHAR(8) NOT NULL CHECK(payment_method IN ('CASH','UPI','OTHER')),
 sale_date DATE NOT NULL,client_created_at TIMESTAMPTZ(6),created_at TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
 request_key VARCHAR(64) NOT NULL UNIQUE,request_hash VARCHAR(64) NOT NULL,
 CHECK(vendor_customer_id IS NOT NULL OR balance_paise=0)
);
CREATE INDEX sales_vendor_id_sale_date_created_at_idx ON sales(vendor_id,sale_date,created_at);
CREATE INDEX sales_vendor_customer_id_created_at_idx ON sales(vendor_customer_id,created_at);
CREATE TABLE sale_items (
 id UUID PRIMARY KEY,sale_id UUID NOT NULL REFERENCES sales(id) ON DELETE RESTRICT,
 product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
 name_snapshot VARCHAR(120) NOT NULL,unit_value_snapshot VARCHAR(40) NOT NULL,unit_type_snapshot VARCHAR(8) NOT NULL,
 qty INTEGER NOT NULL CHECK(qty>0),rate_paise BIGINT NOT NULL CHECK(rate_paise>=0),
 amount_paise BIGINT NOT NULL CHECK(amount_paise>=0 AND amount_paise::numeric=rate_paise::numeric*qty),
 UNIQUE(sale_id,product_id)
);
CREATE FUNCTION guard_sale_scope() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
 IF TG_TABLE_NAME='sales' THEN
  IF NOT EXISTS(SELECT 1 FROM vendors WHERE id=NEW.vendor_id AND user_id=NEW.created_by)
   OR (NEW.vendor_customer_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM vendor_customers WHERE id=NEW.vendor_customer_id AND vendor_id=NEW.vendor_id AND deleted_at IS NULL))
  THEN RAISE EXCEPTION 'Sale scope mismatch'; END IF;
 ELSE
  IF NOT EXISTS(SELECT 1 FROM sales s JOIN products p ON p.vendor_id=s.vendor_id WHERE s.id=NEW.sale_id AND p.id=NEW.product_id)
  THEN RAISE EXCEPTION 'Sale item scope mismatch'; END IF;
 END IF;
 RETURN NEW;
END;
$$;
CREATE TRIGGER sales_scope BEFORE INSERT ON sales FOR EACH ROW EXECUTE FUNCTION guard_sale_scope();
CREATE TRIGGER sale_items_scope BEFORE INSERT ON sale_items FOR EACH ROW EXECUTE FUNCTION guard_sale_scope();
CREATE FUNCTION verify_sale_total() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE sid UUID; expected BIGINT; actual NUMERIC; lines INTEGER;
BEGIN
 IF TG_TABLE_NAME='sales' THEN sid:=NEW.id; ELSE sid:=NEW.sale_id; END IF;
 SELECT total_paise INTO expected FROM sales WHERE id=sid;
 SELECT COALESCE(SUM(amount_paise),0),COUNT(*) INTO actual,lines FROM sale_items WHERE sale_id=sid;
 IF lines=0 OR actual<>expected THEN RAISE EXCEPTION 'Sale snapshots do not match total'; END IF;
 RETURN NULL;
END;
$$;
CREATE CONSTRAINT TRIGGER sales_total AFTER INSERT ON sales DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION verify_sale_total();
CREATE CONSTRAINT TRIGGER sale_items_total AFTER INSERT ON sale_items DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION verify_sale_total();
CREATE TRIGGER sales_immutable BEFORE UPDATE OR DELETE OR TRUNCATE ON sales FOR EACH STATEMENT EXECUTE FUNCTION reject_order_history_mutation();
CREATE TRIGGER sale_items_immutable BEFORE UPDATE OR DELETE OR TRUNCATE ON sale_items FOR EACH STATEMENT EXECUTE FUNCTION reject_order_history_mutation();
CREATE UNIQUE INDEX sale_stock_source_once ON stock_movements(product_id,ref_id) WHERE reason='SALE' AND ref_id IS NOT NULL;
