-- T-100: additive, immutable source metadata. No financial backfill or grant changes.
ALTER TABLE sale_items ADD COLUMN milk_quantity_ml NUMERIC(30,3) NOT NULL DEFAULT 0,
  ADD COLUMN milk_quantity_known BOOLEAN NOT NULL DEFAULT false,
  ADD CONSTRAINT sale_items_milk_volume CHECK (milk_quantity_ml>=0 AND (milk_quantity_known OR milk_quantity_ml=0));
ALTER TABLE order_items ADD COLUMN milk_quantity_known BOOLEAN NOT NULL DEFAULT false;
-- Existing positive order milk_quantity_ml remains reliable. Legacy zero-volume
-- order/POS lines are explicitly unknown; do not infer history from today's catalog.
