-- FR-030 requires positive selling price; optional subscription price may be zero.
-- Preserve the first migration already exercised against the isolated test database.
ALTER TABLE products DROP CONSTRAINT products_check;
ALTER TABLE products ADD CONSTRAINT products_subscription_price_paise_check
 CHECK (subscription_price_paise >= 0 AND subscription_price_paise <= selling_price_paise);
