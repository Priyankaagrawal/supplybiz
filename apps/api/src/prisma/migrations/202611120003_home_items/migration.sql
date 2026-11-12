-- Additive read foundation for FR-201; T-045 owns order/item write validation.
CREATE TABLE order_items (
  id UUID PRIMARY KEY,
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE RESTRICT,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
  product_name_snapshot VARCHAR(120) NOT NULL CHECK (length(trim(product_name_snapshot)) > 0),
  unit_snapshot JSONB NOT NULL,
  unit_price_paise BIGINT NOT NULL CHECK (unit_price_paise >= 0),
  qty INTEGER NOT NULL CHECK (qty > 0),
  line_total_paise BIGINT NOT NULL CHECK (line_total_paise = unit_price_paise * qty)
);
CREATE INDEX order_items_order_id_id_idx ON order_items(order_id, id);
