-- T-026 additive catalog; no changes to existing identity/business rows.
CREATE TABLE products (
 id UUID PRIMARY KEY, vendor_id UUID NOT NULL REFERENCES vendors(id) ON DELETE RESTRICT,
 name VARCHAR(120) NOT NULL CHECK (length(btrim(name)) > 0), product_type VARCHAR(80) NOT NULL,
 milk_type VARCHAR(24), unit_value DECIMAL(12,3) NOT NULL CHECK (unit_value > 0),
 unit_type VARCHAR(3) NOT NULL CHECK (unit_type IN ('ML','L','G','KG','PCS')),
 selling_price_paise INTEGER NOT NULL CHECK (selling_price_paise > 0),
 subscription_price_paise INTEGER CHECK (subscription_price_paise > 0 AND subscription_price_paise <= selling_price_paise),
 stock_qty INTEGER NOT NULL DEFAULT 0 CHECK (stock_qty >= 0), moq INTEGER NOT NULL DEFAULT 1 CHECK (moq >= 1),
 description VARCHAR(500) NOT NULL DEFAULT '', image_media_id UUID REFERENCES media_files(id) ON DELETE RESTRICT,
 is_active BOOLEAN NOT NULL DEFAULT true, deleted_at TIMESTAMPTZ,
 version INTEGER NOT NULL DEFAULT 1 CHECK (version > 0),
 created_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
 CHECK ((product_type = 'MILK' AND milk_type IN ('COW','BUFFALO','TONED','DOUBLE_TONED','FULL_CREAM','OTHER') AND milk_type IS NOT NULL)
   OR (product_type <> 'MILK' AND milk_type IS NULL))
);
CREATE INDEX products_vendor_id_is_active_idx ON products(vendor_id, is_active);
CREATE TABLE stock_movements (
 id UUID PRIMARY KEY, product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
 delta INTEGER NOT NULL CHECK (delta <> 0),
 reason VARCHAR(16) NOT NULL CHECK (reason IN ('OPENING','ADJUST','ORDER','SALE','REVERSAL')),
 note VARCHAR(200) NOT NULL CHECK (length(btrim(note)) > 0), ref_id UUID,
 created_by UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
 created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX stock_movements_product_id_created_at_idx ON stock_movements(product_id, created_at);
CREATE FUNCTION reject_stock_movement_mutation() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN RAISE EXCEPTION 'Stock movements are append-only'; END $$;
CREATE TRIGGER stock_movements_immutable BEFORE UPDATE OR DELETE ON stock_movements
 FOR EACH ROW EXECUTE FUNCTION reject_stock_movement_mutation();
-- Minimal referential hook; subscriptions/state transitions are implemented by T-072.
CREATE TABLE product_subscription_links (
 subscription_id UUID PRIMARY KEY, product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
 status VARCHAR(24) NOT NULL CHECK (status IN ('PENDING','ACTIVE','PAUSED','ENDED','CANCELLED','REJECTED'))
);
CREATE INDEX product_subscription_links_product_id_status_idx ON product_subscription_links(product_id, status);
-- A shared row lock prevents racing subscription activation with product deletion.
CREATE FUNCTION check_subscription_product() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE removed TIMESTAMPTZ;
BEGIN
 IF TG_OP = 'UPDATE' AND (NEW.product_id <> OLD.product_id OR NEW.subscription_id <> OLD.subscription_id) THEN
   RAISE EXCEPTION 'Subscription product reference is immutable';
 END IF;
 SELECT deleted_at INTO removed FROM products WHERE id = NEW.product_id FOR UPDATE;
 IF NOT FOUND OR removed IS NOT NULL THEN RAISE EXCEPTION 'Product unavailable'; END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER subscription_product_available BEFORE INSERT OR UPDATE ON product_subscription_links
 FOR EACH ROW EXECUTE FUNCTION check_subscription_product();
