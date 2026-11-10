CREATE TABLE "vendor_service_pincodes" (
  "vendor_id" UUID NOT NULL REFERENCES "vendors"("id") ON DELETE RESTRICT,
  "pincode" VARCHAR(6) NOT NULL CHECK ("pincode" ~ '^[1-9][0-9]{5}$'),
  PRIMARY KEY ("vendor_id", "pincode")
);
-- Preserve explicitly configured areas; FR-018 supplies the initial default.
UPDATE "vendor_settings" SET "service_radius_km" = 3 WHERE "service_radius_km" IS NULL;
ALTER TABLE "vendor_settings" ALTER COLUMN "service_radius_km" SET DEFAULT 3;
