-- T-040: additive only. Retain historical address rows; future orders store snapshots.
CREATE TABLE addresses (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  label VARCHAR(50) NOT NULL CHECK (length(trim(label)) > 0),
  line1 VARCHAR(200) NOT NULL CHECK (length(trim(line1)) > 0),
  line2 VARCHAR(200) NOT NULL CHECK (length(trim(line2)) > 0),
  landmark VARCHAR(200) NOT NULL DEFAULT '',
  city VARCHAR(100) NOT NULL CHECK (length(trim(city)) > 0),
  state VARCHAR(100) NOT NULL CHECK (length(trim(state)) > 0),
  pincode VARCHAR(6) NOT NULL CHECK (pincode ~ '^[1-9][0-9]{5}$'),
  latitude DOUBLE PRECISION NOT NULL CHECK (latitude BETWEEN -90 AND 90),
  longitude DOUBLE PRECISION NOT NULL CHECK (longitude BETWEEN -180 AND 180),
  location geography(Point,4326) GENERATED ALWAYS AS
    (ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography) STORED,
  is_default BOOLEAN NOT NULL DEFAULT false,
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL,
  CHECK (deleted_at IS NULL OR NOT is_default)
);
CREATE INDEX addresses_user_id_deleted_at_idx ON addresses(user_id, deleted_at);
CREATE UNIQUE INDEX addresses_one_live_default ON addresses(user_id) WHERE is_default AND deleted_at IS NULL;
CREATE INDEX addresses_location_idx ON addresses USING GIST(location);
