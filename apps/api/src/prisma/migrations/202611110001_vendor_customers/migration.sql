-- T-028 additive foundation. No existing data/plan catalog is changed.
ALTER TABLE vendors ADD COLUMN assigned_customer_limit INTEGER
  CHECK (assigned_customer_limit IS NULL OR assigned_customer_limit >= 0);
CREATE TABLE vendor_customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vendor_id UUID NOT NULL REFERENCES vendors(id) ON DELETE RESTRICT,
  user_id UUID REFERENCES users(id) ON DELETE RESTRICT,
  name VARCHAR(120) NOT NULL CHECK (length(trim(name)) > 0),
  mobile VARCHAR(13) NOT NULL CHECK (mobile ~ '^\+91[6-9][0-9]{9}$'),
  email VARCHAR(254), address_text VARCHAR(500) NOT NULL DEFAULT '',
  preferred_payment VARCHAR(8) NOT NULL DEFAULT 'CASH' CHECK (preferred_payment IN ('CASH','UPI','BANK','WALLET')),
  status VARCHAR(8) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','INACTIVE')),
  deleted_at TIMESTAMPTZ, created_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX vendor_customers_vendor_mobile_live ON vendor_customers(vendor_id,mobile) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX vendor_customers_vendor_user_live ON vendor_customers(vendor_id,user_id) WHERE deleted_at IS NULL AND user_id IS NOT NULL;
CREATE INDEX vendor_customers_vendor_id_status_idx ON vendor_customers(vendor_id,status);
CREATE INDEX vendor_customers_user_id_idx ON vendor_customers(user_id);
CREATE INDEX vendor_customers_mobile_idx ON vendor_customers(mobile);
CREATE TABLE customer_link_decisions (
  vendor_customer_id UUID NOT NULL REFERENCES vendor_customers(id) ON DELETE RESTRICT,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  decision VARCHAR(8) NOT NULL CHECK (decision IN ('ACCEPTED','DECLINED')),
  decided_at TIMESTAMPTZ NOT NULL DEFAULT now(), PRIMARY KEY (vendor_customer_id,user_id)
);
CREATE TABLE customer_subscription_links (
  subscription_id UUID PRIMARY KEY,
  vendor_customer_id UUID NOT NULL REFERENCES vendor_customers(id) ON DELETE RESTRICT,
  status VARCHAR(12) NOT NULL CHECK (status IN ('PENDING','ACTIVE','PAUSED','ENDED','CANCELLED','REJECTED'))
);
CREATE INDEX customer_subscription_links_vendor_customer_id_status_idx ON customer_subscription_links(vendor_customer_id,status);
