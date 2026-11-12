CREATE TABLE favorites (user_id uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT, vendor_id uuid NOT NULL REFERENCES vendors(id) ON DELETE RESTRICT, PRIMARY KEY(user_id,vendor_id));
CREATE TABLE vendor_holidays (id uuid PRIMARY KEY, vendor_id uuid NOT NULL REFERENCES vendors(id) ON DELETE RESTRICT, date date NOT NULL, reason varchar(200) NOT NULL, UNIQUE(vendor_id,date));
CREATE TABLE orders (
 id uuid PRIMARY KEY, order_no varchar(40) UNIQUE NOT NULL,
 vendor_id uuid NOT NULL REFERENCES vendors(id) ON DELETE RESTRICT,
 vendor_customer_id uuid NOT NULL REFERENCES vendor_customers(id) ON DELETE RESTRICT,
 source varchar(16) NOT NULL CHECK(source IN ('APP','SUBSCRIPTION','VENDOR')),
 subscription_id uuid, status varchar(24) NOT NULL CHECK(status IN ('NEW','ACCEPTED','REJECTED','PREPARING','OUT_FOR_DELIVERY','DELIVERED','FAILED','CANCELLED')),
 delivery_date date NOT NULL, time_slot varchar(80) NOT NULL, address_snapshot jsonb NOT NULL,
 subtotal_paise bigint NOT NULL CHECK(subtotal_paise>=0), delivery_charge_paise bigint NOT NULL CHECK(delivery_charge_paise>=0),
 discount_paise bigint NOT NULL DEFAULT 0 CHECK(discount_paise=0), total_paise bigint NOT NULL CHECK(total_paise=subtotal_paise+delivery_charge_paise-discount_paise),
 payment_mode varchar(16) NOT NULL CHECK(payment_mode IN ('POD_CASH','POD_UPI','KHATA')), payment_status varchar(8) NOT NULL CHECK(payment_status IN ('UNPAID','PAID')),
 reject_reason varchar(500), cancel_reason varchar(500), fail_reason varchar(500), version integer NOT NULL DEFAULT 1,
 created_at timestamptz NOT NULL DEFAULT now(), completed_at timestamptz,
 CHECK((status='DELIVERED') = (completed_at IS NOT NULL)), CHECK(completed_at IS NULL OR completed_at>=created_at)
);
CREATE UNIQUE INDEX orders_subscription_date_once ON orders(subscription_id,delivery_date) WHERE subscription_id IS NOT NULL;
CREATE INDEX orders_vendor_id_delivery_date_status_idx ON orders(vendor_id,delivery_date,status);
CREATE INDEX orders_vendor_customer_id_created_at_idx ON orders(vendor_customer_id,created_at);
CREATE INDEX orders_vendor_id_completed_at_idx ON orders(vendor_id,completed_at);
