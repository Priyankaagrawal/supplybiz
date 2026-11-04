CREATE TABLE "media_files" (
  "id" UUID PRIMARY KEY,
  "owner_user_id" UUID NOT NULL REFERENCES "users"("id") ON DELETE RESTRICT,
  "purpose" VARCHAR(24) NOT NULL CHECK (purpose IN ('PRODUCT_IMAGE', 'SHOP_PHOTO', 'PROFILE', 'KYC_DOC')),
  "relative_storage_key" VARCHAR(100) NOT NULL UNIQUE,
  "mime" VARCHAR(40) NOT NULL CHECK (mime IN ('image/jpeg', 'image/png', 'application/pdf')),
  "size" INTEGER NOT NULL CHECK (size > 0 AND size <= 5242880),
  "sha256" CHAR(64) NOT NULL,
  "status" VARCHAR(16) NOT NULL DEFAULT 'READY' CHECK (status = 'READY'),
  "request_key" CHAR(64) NOT NULL,
  "request_hash" CHAR(64) NOT NULL,
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE ("owner_user_id", "request_key")
);
CREATE INDEX "media_files_owner_user_id_created_at_idx" ON "media_files"("owner_user_id", "created_at");
CREATE TABLE "media_access_events" (
  "id" UUID PRIMARY KEY,
  "media_id" UUID NOT NULL REFERENCES "media_files"("id") ON DELETE RESTRICT,
  "admin_user_id" UUID NOT NULL REFERENCES "admin_users"("id") ON DELETE RESTRICT,
  "action" VARCHAR(32) NOT NULL DEFAULT 'KYC_DOCUMENT_READ',
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX "media_access_events_media_id_created_at_idx" ON "media_access_events"("media_id", "created_at");
