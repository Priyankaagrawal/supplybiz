-- Additive draft/profile foundation; existing identity/media data is retained.
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE TABLE vendors (
 id UUID PRIMARY KEY, user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE RESTRICT,
 category_id UUID NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
 business_name VARCHAR(80), gstin VARCHAR(15), address_line VARCHAR(200), city VARCHAR(120), state VARCHAR(120), pincode VARCHAR(6),
 latitude DOUBLE PRECISION, longitude DOUBLE PRECISION,
 location geography(Point,4326) GENERATED ALWAYS AS
 (CASE WHEN latitude IS NOT NULL AND longitude IS NOT NULL THEN ST_SetSRID(ST_MakePoint(longitude,latitude),4326)::geography END) STORED,
 shop_photo_media_id UUID REFERENCES media_files(id) ON DELETE RESTRICT,
 onboarding_step INTEGER NOT NULL DEFAULT 2 CHECK (onboarding_step BETWEEN 2 AND 4),
 kyc_status VARCHAR(24) NOT NULL DEFAULT 'NOT_VERIFIED', is_suspended BOOLEAN NOT NULL DEFAULT false,
 created_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
 CHECK (latitude BETWEEN -90 AND 90), CHECK (longitude BETWEEN -180 AND 180),
 CHECK ((latitude IS NULL) = (longitude IS NULL))
);
CREATE INDEX vendors_location_idx ON vendors USING GIST(location);
CREATE INDEX vendors_kyc_status_idx ON vendors(kyc_status);
CREATE TABLE vendor_settings (
 vendor_id UUID PRIMARY KEY REFERENCES vendors(id) ON DELETE RESTRICT,
 service_radius_km INTEGER CHECK (service_radius_km BETWEEN 1 AND 20),
 delivery_charge_paise INTEGER NOT NULL DEFAULT 0 CHECK (delivery_charge_paise >= 0),
 min_order_paise INTEGER NOT NULL DEFAULT 0 CHECK (min_order_paise >= 0),
 time_slots JSONB NOT NULL DEFAULT '[]', same_day_cutoff TIME,
 auto_accept_subscriptions BOOLEAN NOT NULL DEFAULT false, accepting_today BOOLEAN NOT NULL DEFAULT false,
 delivery_paused BOOLEAN NOT NULL DEFAULT false, delivery_paused_until TIMESTAMPTZ,
 max_daily_orders INTEGER CHECK (max_daily_orders > 0), daily_milk_capacity_ml INTEGER CHECK (daily_milk_capacity_ml > 0),
 low_stock_threshold INTEGER NOT NULL DEFAULT 10 CHECK (low_stock_threshold >= 0),
 allow_khata_orders BOOLEAN NOT NULL DEFAULT false, version INTEGER NOT NULL DEFAULT 1
);
