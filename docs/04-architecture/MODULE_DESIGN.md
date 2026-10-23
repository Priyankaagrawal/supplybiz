# MODULE DESIGN

| Field | Value |
|---|---|
| Status | Draft v0.1 |
| Owner | Technical Architect |
| Last updated | 2026-10-19 |
| Related | [ARCHITECTURE](ARCHITECTURE.md), [FOLDER_STRUCTURE](FOLDER_STRUCTURE.md), [API_SPECIFICATION](API_SPECIFICATION.md) |

## 1. Purpose
Defines modules (backend, mobile, admin), their responsibilities, dependencies and public interfaces so that agents can implement modules independently.

## 2. Backend Modules (NestJS, `apps/api/src/modules/*`)
| Module | Responsibility | Owns tables | Depends on | FR |
|---|---|---|---|---|
| `auth` | OTP send/verify, tokens, sessions, devices, logout, deletion | users, sessions, devices, consents | `notify-channels`, `users` | FR-001–FR-009 |
| `users` | Profile, roles, active role, preferences, language | users, user_roles, user_preferences | — | FR-005, FR-007, FR-290 |
| `vendors` | Vendor profile, business info, onboarding progress, service area, settings, holidays, availability | vendors, vendor_settings, vendor_holidays, vendor_service_pincodes | `kyc`, `media`, `plans` | FR-010–FR-018, FR-075, FR-082–FR-085, FR-130–FR-132 |
| `kyc` | KYC submission, provider calls, manual review, encryption of bank data | vendor_kyc, kyc_documents, bank_accounts | `media`, `kyc-provider` adapter | FR-013–FR-015, FR-402 |
| `catalog` | Categories, products, stock movements | categories, products, stock_movements | `vendors`, `media` | FR-030–FR-036, FR-405 |
| `customers` | Vendor↔customer links, offline customers, linking flow | vendor_customers | `users`, `plans` | FR-060–FR-064 |
| `addresses` | Customer addresses, geocoding | addresses | `geo` adapter | FR-291 |
| `discovery` | Geo search, vendor listing, favorites, search | favorites (+ read models) | `vendors`, `catalog`, `reviews` | FR-202, FR-210–FR-212, FR-214 |
| `orders` | Order placement, validation, state machine, cancellation, capacity | orders, order_items, order_status_history, idempotency_keys | `catalog`, `vendors`, `ledger`, `customers` | FR-040–FR-046, FR-220–FR-225, FR-240–FR-243 |
| `subscriptions` | Subscriptions CRUD, pause/skip, approval, daily generation job | subscriptions, subscription_pauses, subscription_skips, job_runs | `orders`, `vendors`, `plans` | FR-070–FR-077, FR-230–FR-233 |
| `deliveries` | Delivery list queries & delivery actions (wraps order transitions) | — (uses orders) | `orders`, `ledger` | FR-080–FR-081 |
| `sales` | Quick sale (POS) | sales, sale_items | `catalog`, `ledger`, `customers` | FR-050–FR-054 |
| `ledger` | Khata entries, balances, payments, payment claims, reversals | ledger_entries, ledger_balances, payments, payment_claims | `customers` | FR-110–FR-116, FR-250–FR-253 |
| `personal-finance` | Customer personal Khata contacts/entries, Money transactions | personal_contacts, personal_entries, money_transactions | — | FR-252, FR-260–FR-263 |
| `reports` | Vendor reports, exports, customer insights | report_exports | `orders`, `sales`, `ledger` | FR-090–FR-095, FR-294 |
| `notifications` | In-app inbox, push dispatch, preferences, broadcast | notifications, notification_prefs, push_tokens | FCM adapter | FR-100–FR-104, FR-409 |
| `plans` | Plan catalog, vendor plan subscriptions, entitlements, billing, invoices | plans, plan_prices, vendor_plan_subscriptions, plan_payments | `billing-provider` adapter | FR-120–FR-126, FR-406 |
| `reviews` | Reviews & ratings, moderation | reviews, vendor_rating_stats | `orders` | FR-213, FR-410 |
| `bill-payments` | BBPS integration (flagged) | bill_payments | `bbps-provider` adapter | FR-271–FR-272 |
| `grocery-assist` | Parse transcript/OCR text → catalog matching | — | `catalog` | FR-282 |
| `content` | Banners, FAQs, legal docs, app config, feature flags | banners, faqs, legal_documents, app_config | `media` | FR-133, FR-134, FR-201, FR-407, FR-408 |
| `media` | Pre-signed upload/download URLs, file validation, scanning | media_files | storage adapter | FR-012, FR-013 |
| `referrals` | Referral codes & attribution (flagged) | referrals | — | FR-293 |
| `admin` | Admin auth (password + TOTP), admin users/roles, admin-only endpoints aggregation | admin_users, admin_sessions | most modules | FR-400–FR-413 |
| `audit` | Append-only audit log | audit_logs | — | FR-411, NFR-020 |
| `privacy` | Account deletion, data export, retention jobs | data_requests | all | FR-008, FR-412 |
| `common` | Errors, guards (auth, role, plan), interceptors (idempotency, logging), pagination, money/time utils | outbox_events | — | — |

### 2.1 Dependency rules
- No circular module imports; dependencies flow toward `common`. `ledger` must not depend on `orders` (orders call `LedgerService.post*`).
- External providers are behind **adapter interfaces** in `apps/api/src/integrations/*` with a fake implementation for dev/test:

| Interface | Methods | Implementations |
|---|---|---|
| `OtpChannel` | `send(mobile, code, channel)` | `Msg91Sms`* , `WhatsAppCloud`*, `ConsoleOtp` (dev) |
| `KycProvider` | `verifyPan`, `verifyBankAccount`, `verifyAadhaar` | TBD (Q-08), `FakeKyc` |
| `BillingProvider` | `createCheckout`, `verifyPayment`, `handleWebhook` | Razorpay* / AppStore / PlayBilling (ADR-015), `FakeBilling` |
| `BbpsProvider` | `listBillers`, `fetchBill`, `pay`, `status` | TBD (Q-07), `FakeBbps` |
| `PushProvider` | `sendToTokens`, `sendToTopic` | `FcmPush`, `LogPush` |
| `GeoProvider` | `geocode`, `reverseGeocode`, `autocomplete` | TBD (Q-32), `FakeGeo` |
| `StorageProvider` | `presignPut`, `presignGet`, `delete` | S3-compatible, `LocalMinio` |
*Suggested, pending confirmation.

### 2.2 Key service interfaces (TypeScript signatures)
```ts
// orders
placeOrder(customerId: string, dto: PlaceOrderDto, idemKey: string): Promise<Order>;
transition(orderId: string, actor: Actor, to: OrderStatus, meta?: TransitionMeta): Promise<Order>;
// subscriptions
generateForDate(vendorIds: string[], date: LocalDate): Promise<GenerationResult>;
// ledger
postDebit(input: { vendorId; vendorCustomerId; amountPaise; refType: 'ORDER'|'SALE'|'OPENING'; refId; note? }): Promise<LedgerEntry>;
postCredit(input: { vendorId; vendorCustomerId; amountPaise; method: PaymentMethod; refType: 'PAYMENT'|'CLAIM'|'OPENING'; refId; note? }): Promise<LedgerEntry>;
reverse(entryId: string, actor: Actor, reason: string): Promise<LedgerEntry>;
// plans
assertFeature(vendorId: string, feature: PlanFeature): Promise<void>; // throws PLAN_FEATURE_LOCKED
assertCustomerCapacity(vendorId: string): Promise<void>;            // throws PLAN_CUSTOMER_LIMIT
```

### 2.3 Domain events
| Event | Producer | Consumers |
|---|---|---|
| `order.created` | orders, subscriptions | notifications |
| `order.status_changed` | orders | notifications, ledger (DELIVERED → debit), catalog (stock), reviews (prompt) |
| `sale.completed` | sales | ledger, catalog, reports |
| `payment.recorded` / `claim.created` / `claim.decided` | ledger | notifications |
| `subscription.status_changed` | subscriptions | notifications |
| `vendor.holiday_created` | vendors | subscriptions (cancel orders), notifications |
| `kyc.status_changed` | kyc | vendors (visibility), notifications |
| `plan.activated` / `plan.expiring` / `plan.expired` | plans | vendors, notifications |
| `stock.low` | catalog | notifications |

## 3. Mobile Feature Modules (`apps/mobile/lib/features/*`)
| Module | Path | Screens | Backend module |
|---|---|---|---|
| auth | `common/auth` | S-COM-01–05, S-COM-10 | auth, users |
| settings_common | `common/settings` | language, legal, notification prefs | users, content, notifications |
| notifications | `common/notifications` | S-V-18, S-C-26 | notifications |
| onboarding | `vendor/onboarding` | S-V-01–S-V-04, S-V-30 | vendors, kyc, media |
| dashboard | `vendor/dashboard` | S-V-05 | reports |
| products | `vendor/products` | S-V-06, S-V-07, S-V-35 | catalog |
| vendor_orders | `vendor/orders` | S-V-08–S-V-10 | orders |
| quick_sale | `vendor/quick_sale` | S-V-11 | sales |
| vendor_customers | `vendor/customers` | S-V-12–S-V-14 | customers |
| vendor_subscriptions | `vendor/subscriptions` | S-V-15, S-V-21 | subscriptions |
| deliveries | `vendor/deliveries` | S-V-16, S-V-22, S-V-34 | deliveries, vendors |
| vendor_khata | `vendor/khata` | S-V-23–S-V-26 | ledger |
| reports | `vendor/reports` | S-V-17 | reports |
| plans | `vendor/plans` | S-V-27, S-V-28 | plans |
| vendor_settings | `vendor/settings` | S-V-19, S-V-20, S-V-29, S-V-31–S-V-33 | vendors, content |
| home | `customer/home` | S-C-01–S-C-04 | discovery, content |
| discovery | `customer/discovery` | S-C-05–S-C-08, S-C-37 | discovery, catalog, reviews |
| cart_checkout | `customer/cart` | S-C-11, S-C-12 | orders |
| customer_orders | `customer/orders` | S-C-13, S-C-14, S-C-35 | orders, reviews |
| customer_subscriptions | `customer/subscriptions` | S-C-09, S-C-10, S-C-15, S-C-16 | subscriptions |
| customer_khata | `customer/khata` | S-C-17–S-C-20, S-C-38 | ledger, personal-finance |
| money | `customer/money` | S-C-21, S-C-22 | personal-finance |
| bill_payments | `customer/bills` | S-C-23, S-C-24 | bill-payments |
| grocery_assist | `customer/grocery_assist` | S-C-25 | grocery-assist, catalog |
| profile | `customer/profile` | S-C-27–S-C-34, S-C-36 | users, addresses, referrals, reports |

### 3.1 Mobile core (`apps/mobile/lib/core`)
| Component | Responsibility |
|---|---|
| `network/` | dio setup, auth interceptor (token refresh with single-flight lock), idempotency header, correlation ID, error mapping to `AppFailure` |
| `storage/` | secure storage wrapper, drift database, DAOs registry |
| `sync/` | Outbox, `SyncService` (connectivity + lifecycle triggered) |
| `session/` | `SessionController` (tokens, active role, user), role switch |
| `router/` | go_router config, guards (auth, role, onboarding, force update), deep-link parser |
| `config/` | flavors, `AppConfig`, Remote Config & feature flags |
| `l10n/` | ARB files, `context.l10n` extension, money/date formatters |
| `analytics/`, `logging/`, `crash/` | wrappers (no PII) |
| `permissions/` | pre-prompt + request + settings redirect |
| `upi/` | UPI intent builder & launcher with iOS fallback |

Module rules: feature modules may depend on `core`, `ui_kit`, `api_client`, and other features only via `features/<x>/<x>.dart` public barrel (exports routes + public providers). No feature imports another feature's `data/` folder.

## 4. Admin Panel Modules (`apps/admin/src/app/*`)
Routes mirror S-A-01–S-A-19: `(auth)/login`, `dashboard`, `kyc`, `vendors`, `customers`, `categories`, `plans`, `content/{banners,coupons,faqs,legal}`, `config`, `broadcasts`, `reviews`, `audit`, `admins`, `data-requests`, `reports`. Each uses generated TS client, server-side session cookie, and `<Can permission="...">` RBAC wrapper.

## 5. Open Questions
Q-07, Q-08, Q-28, Q-32 affect adapter implementations only — interfaces are stable.
