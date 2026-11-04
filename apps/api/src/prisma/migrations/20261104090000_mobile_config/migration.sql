CREATE TABLE "app_config" (
  "key" VARCHAR(100) PRIMARY KEY,
  "value" JSONB NOT NULL,
  "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO "app_config" ("key", "value") VALUES
  ('mobile', '{"minVersionAndroid":"0.1.0","flags":{}}'::jsonb);
