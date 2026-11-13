-- T-045 additive order writers. Keep existing read-foundation rows intact.
CREATE SEQUENCE order_number_sequence AS BIGINT MINVALUE 1;
SELECT setval('order_number_sequence', COALESCE((SELECT max(substring(order_no FROM 4)::bigint) FROM orders WHERE order_no ~ '^ORD[0-9]+$'),0)+1,false);
ALTER TABLE order_items ADD COLUMN milk_quantity_ml DECIMAL(30,3) NOT NULL DEFAULT 0;
-- Existing rows are read foundations; preserve their unit snapshots for capacity.
UPDATE order_items i SET milk_quantity_ml =
  (i.unit_snapshot->>'value')::numeric * i.qty *
  CASE i.unit_snapshot->>'type' WHEN 'L' THEN 1000 ELSE 1 END
FROM products p WHERE p.id=i.product_id AND p.product_type='MILK'
  AND i.unit_snapshot->>'type' IN ('ML','L')
  AND i.unit_snapshot->>'value' ~ '^[0-9]+(\.[0-9]+)?$';
ALTER TABLE order_items ADD CONSTRAINT order_items_milk_nonnegative CHECK (milk_quantity_ml >= 0);
CREATE TABLE order_requests (
  request_key CHAR(64) PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  path VARCHAR(160) NOT NULL,
  request_hash CHAR(64) NOT NULL,
  response JSONB NOT NULL,
  created_at TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE order_status_events (
  id UUID PRIMARY KEY,
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE RESTRICT,
  status VARCHAR(24) NOT NULL,
  reason VARCHAR(200),
  at TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX order_status_events_order_id_at_idx ON order_status_events(order_id,at);
CREATE FUNCTION reject_order_history_mutation() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN RAISE EXCEPTION 'Order request and status history is append-only'; END;
$$;
CREATE TRIGGER order_requests_immutable BEFORE UPDATE OR DELETE OR TRUNCATE ON order_requests
FOR EACH STATEMENT EXECUTE FUNCTION reject_order_history_mutation();
CREATE TRIGGER order_status_events_immutable BEFORE UPDATE OR DELETE OR TRUNCATE ON order_status_events
FOR EACH STATEMENT EXECUTE FUNCTION reject_order_history_mutation();
