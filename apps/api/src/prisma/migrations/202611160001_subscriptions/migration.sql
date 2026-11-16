-- T-072 additive only. No historical subscriptions or financial entries are fabricated.
CREATE TABLE subscriptions (
 id UUID PRIMARY KEY, vendor_id UUID NOT NULL REFERENCES vendors(id) ON DELETE RESTRICT,
 vendor_customer_id UUID NOT NULL REFERENCES vendor_customers(id) ON DELETE RESTRICT,
 product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
 start_date DATE NOT NULL, end_date DATE, address_snapshot JSONB NOT NULL,
 payment_method VARCHAR(8) NOT NULL CHECK(payment_method IN ('CASH','UPI','WALLET')),
 created_by VARCHAR(8) NOT NULL CHECK(created_by IN ('VENDOR','CUSTOMER')),
 creator_user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
 version INTEGER NOT NULL DEFAULT 1 CHECK(version>0),
 created_at TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CHECK(end_date IS NULL OR end_date>=start_date)
);
CREATE INDEX subscriptions_vendor_id_created_at_idx ON subscriptions(vendor_id,created_at);
CREATE INDEX subscriptions_vendor_customer_id_created_at_idx ON subscriptions(vendor_customer_id,created_at);
CREATE TABLE subscription_revisions (
 subscription_id UUID NOT NULL REFERENCES subscriptions(id) ON DELETE RESTRICT,
 version INTEGER NOT NULL CHECK(version>0), effective_from DATE NOT NULL,
 qty INTEGER NOT NULL CHECK(qty>0), weekdays SMALLINT NOT NULL CHECK(weekdays BETWEEN 1 AND 127),
 time_slot VARCHAR(80) NOT NULL CHECK(length(time_slot)>0),
 status VARCHAR(24) NOT NULL CHECK(status IN ('PENDING_APPROVAL','ACTIVE','CANCELLED','REJECTED')),
 action VARCHAR(16) NOT NULL, reason VARCHAR(200), actor_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
 created_at TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
 PRIMARY KEY(subscription_id,version)
);
CREATE INDEX subscription_revisions_subscription_id_effective_from_version_idx ON subscription_revisions(subscription_id,effective_from,version);
CREATE TABLE subscription_pauses (
 id UUID PRIMARY KEY, subscription_id UUID NOT NULL REFERENCES subscriptions(id) ON DELETE RESTRICT,
 from_date DATE NOT NULL, to_date DATE, resumed_from DATE,
 CHECK(to_date IS NULL OR to_date>=from_date)
);
CREATE INDEX subscription_pauses_subscription_id_from_date_idx ON subscription_pauses(subscription_id,from_date);
CREATE TABLE subscription_skips (
 subscription_id UUID NOT NULL REFERENCES subscriptions(id) ON DELETE RESTRICT, date DATE NOT NULL,
 PRIMARY KEY(subscription_id,date)
);
CREATE TABLE subscription_requests (
 request_key CHAR(64) PRIMARY KEY, user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
 path VARCHAR(160) NOT NULL, request_hash CHAR(64) NOT NULL, response JSONB NOT NULL,
 created_at TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP
);
ALTER TABLE orders ADD CONSTRAINT orders_subscription_id_fkey FOREIGN KEY(subscription_id) REFERENCES subscriptions(id) ON DELETE RESTRICT;
CREATE TRIGGER subscription_revisions_immutable BEFORE UPDATE OR DELETE OR TRUNCATE ON subscription_revisions
 FOR EACH STATEMENT EXECUTE FUNCTION reject_order_history_mutation();
CREATE TRIGGER subscription_requests_immutable BEFORE UPDATE OR DELETE OR TRUNCATE ON subscription_requests
 FOR EACH STATEMENT EXECUTE FUNCTION reject_order_history_mutation();
CREATE FUNCTION guard_subscription_scope() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
 IF NOT EXISTS(SELECT 1 FROM vendor_customers c WHERE c.id=NEW.vendor_customer_id AND c.vendor_id=NEW.vendor_id)
 OR NOT EXISTS(SELECT 1 FROM products p WHERE p.id=NEW.product_id AND p.vendor_id=NEW.vendor_id)
 THEN RAISE EXCEPTION 'Subscription scope mismatch'; END IF;
 RETURN NEW;
END;
$$;
CREATE TRIGGER subscription_scope_guard BEFORE INSERT OR UPDATE ON subscriptions FOR EACH ROW EXECUTE FUNCTION guard_subscription_scope();
