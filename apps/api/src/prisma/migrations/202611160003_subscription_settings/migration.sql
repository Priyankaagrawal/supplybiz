-- T-075: preserve existing configured subscriptions; no delivery hours are invented.
ALTER TABLE vendor_settings
 ADD COLUMN subscription_delivery_available BOOLEAN NOT NULL DEFAULT TRUE,
 ADD COLUMN subscription_delivery_start TIME(0),
 ADD COLUMN subscription_delivery_end TIME(0),
 ADD COLUMN pause_all_subscriptions BOOLEAN NOT NULL DEFAULT FALSE,
 ADD CONSTRAINT subscription_delivery_window CHECK (
   (subscription_delivery_start IS NULL AND subscription_delivery_end IS NULL)
   OR (subscription_delivery_start IS NOT NULL AND subscription_delivery_end IS NOT NULL
       AND subscription_delivery_start<>subscription_delivery_end)),
 ADD CONSTRAINT subscription_order_cap CHECK(max_daily_orders IS NULL OR max_daily_orders>=0),
 ADD CONSTRAINT subscription_milk_cap CHECK(daily_milk_capacity_ml IS NULL OR daily_milk_capacity_ml>=0);
