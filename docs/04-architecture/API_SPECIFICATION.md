# API SPECIFICATION

| Field | Value |
|---|---|
| Status | Draft v0.1 |
| Owner | Technical Architect (Backend) |
| Last updated | 2026-10-29 |
| Related | [DATA_DESIGN](DATA_DESIGN.md), [AUTH_SECURITY](AUTH_SECURITY.md), [SRS](../02-requirements/SRS.md) |

## 1. Purpose
REST contract between the Flutter app / admin panel and the NestJS API. The machine-readable source of truth is `contracts/openapi.yaml` (generated, CI-diffed); this document defines conventions and the endpoint catalog the OpenAPI must implement.

## 2. Conventions
| Topic | Rule |
|---|---|
| Base URL | `https://{env-api-host}/api/v1` (domains TBD Q-33) |
| Format | JSON UTF-8; `camelCase` fields; dates `YYYY-MM-DD` (IST business date); timestamps ISO-8601 UTC |
| Money | Integer paise: `"totalPaise": 13000` |
| Auth | `Authorization: Bearer <accessToken>`; admin uses httpOnly cookie session |
| Role scoping | `/vendor/**` requires VENDOR role and resolves `vendorId` from token; `/customer/**` requires CUSTOMER role; `/admin/**` admin session + permission |
| Idempotency | `Idempotency-Key: <uuid>` **required** on all mobile POST/PATCH that create or change state; replay returns original response; same key + different body → `422 IDEMPOTENCY_MISMATCH` |
| Concurrency | Mutable resources return `version`; PATCH/transition bodies include `version` → `409 VERSION_CONFLICT` |
| Pagination | Cursor: `?limit=20&cursor=<opaque>`; response `{ "items": [], "nextCursor": "..." | null }`; max limit 100 |
| Filtering/sorting | Query params, e.g. `?status=NEW,ACCEPTED&q=ramesh&sort=-createdAt` |
| Localization | `Accept-Language: en` (unsupported locales fall back to English) for server-provided text (errors, CMS, notifications) |
| Tracing | `X-Request-Id` (client UUID) echoed; `traceparent` supported |
| Client info | `X-App-Version`, `X-Platform` (`android`/`ios`) — used for force-update (`426 UPGRADE_REQUIRED`) |
| Rate limits | Per IP & per user; `429` with `Retry-After` |

## 3. Error Model (RFC 9457 Problem Details)
```json
{
  "type": "https://docs.supplybiz.app/errors/INVALID_STATE_TRANSITION",
  "title": "Order cannot be accepted",
  "status": 409,
  "code": "INVALID_STATE_TRANSITION",
  "detail": "Order ORD00012345 is CANCELLED.",
  "requestId": "4f1c…",
  "errors": [{ "field": "qty", "code": "BELOW_MOQ", "message": "Minimum 2" }]
}
```
| HTTP | code | Meaning |
|---|---|---|
| 400 | `VALIDATION_FAILED` | Field errors in `errors[]` |
| 401 | `UNAUTHENTICATED`, `TOKEN_EXPIRED`, `REFRESH_REUSED` | Auth problems |
| 403 | `FORBIDDEN`, `ROLE_REQUIRED`, `PLAN_FEATURE_LOCKED`, `KYC_NOT_VERIFIED`, `ACCOUNT_BLOCKED` | Authorization |
| 404 | `NOT_FOUND` | Also returned for resources of other tenants (no existence leak) |
| 409 | `INVALID_STATE_TRANSITION`, `VERSION_CONFLICT`, `DUPLICATE`, `PRODUCT_IN_USE`, `PRICE_CHANGED` | Conflicts |
| 410 | `OTP_EXPIRED` | |
| 422 | `OTP_INVALID`, `OTP_ATTEMPTS_EXCEEDED`, `BELOW_MOQ`, `OUT_OF_STOCK`, `NOT_SERVICEABLE`, `VENDOR_UNAVAILABLE`, `VENDOR_HOLIDAY`, `CAPACITY_REACHED`, `PAST_CUTOFF`, `PLAN_CUSTOMER_LIMIT`, `WALKIN_MUST_BE_PAID`, `AMOUNT_EXCEEDS_DUE`, `SELF_ORDER_NOT_ALLOWED`, `IDEMPOTENCY_MISMATCH` | Business rule violations |
| 426 | `UPGRADE_REQUIRED` | App below min version |
| 429 | `RATE_LIMITED` | |
| 5xx | `INTERNAL`, `DEPENDENCY_UNAVAILABLE` | Retry with backoff (idempotent only) |

## 4. Endpoint Catalog

### 4.1 Auth & users (FR-001–FR-009)
| Method | Path | Purpose |
|---|---|---|
| POST | `/auth/otp/send` | `{ mobile, channel: SMS|WHATSAPP, appHash? }` → `{ resendAfterSec, expiresInSec }` |
| POST | `/auth/otp/verify` | `{ mobile, code, consent?: {termsVersion, privacyVersion}, device }` → tokens + user |
| POST | `/auth/refresh` | `{ refreshToken }` → rotated tokens |
| POST | `/auth/logout` | current session; `?all=true` revokes all |
| GET | `/me` | user, roles, activeRole, vendor summary (onboarding step, kycStatus, plan) |
| PATCH | `/me` | name, email, photoMediaId, language |
| POST | `/me/roles` | `{ role }` add role |
| PUT | `/me/active-role` | `{ role }` |
| PUT | `/me/devices/current` | push token, notification permission, app/os version |
| POST | `/me/deletion` | `{ otp }` → schedules deletion |

T-014 send boundary: `Idempotency-Key` and `X-Device-Id` (stable installation
identifier, 1–128 ASCII letters/digits/hyphens/underscores) are required headers.
Mobile accepts the ten Indian digits or the same number prefixed by `+91`.
The server uses the socket IP rather than a client-supplied forwarded-IP header.
Rate rejection returns `429 RATE_LIMITED` with a `Retry-After` seconds header.
Until Q-09 is resolved, real SMS/WhatsApp delivery returns
`503 OTP_PROVIDER_UNAVAILABLE`; explicitly enabled development/test console mode
simulates delivery without exposing OTPs. PostgreSQL OTP/rate-state failures return `503 OTP_UNAVAILABLE`.
OTP verification is an internal, single-use service in T-014; the public verify
endpoint, user/session creation and tokens belong to T-015.
| GET | `/config` | public: `minVersionAndroid` (numeric `major.minor.patch`), `flags` (boolean map); DB-backed, max-age 60 s; invalid/missing policy → 503. Categories/legal are owned by their content tasks |

### 4.2 Vendor onboarding, settings (FR-010–FR-018, FR-075, FR-082–FR-085, FR-130–FR-132)
| Method | Path |
|---|---|
| GET | `/vendor/onboarding/categories` (enabled SUPPLY categories, English names/icons, MILK first) |
| GET | `/vendor/onboarding` (owned profile, next step and settings defaults; 404 before category selection) |
| POST | `/vendor/onboarding/category` `{ categoryId }` |
| PUT | `/vendor/onboarding/business` `{ businessName, gstin?, addressLine, city, state, pincode, latitude, longitude, shopPhotoMediaId? }` |
| POST | `/vendor/kyc` (atomic validated document/bank submission; see T-022 below) |
| GET | `/vendor/kyc` (latest revision/status/reason; PAN/account last-4 only) |
| GET | `/vendor/kyc/notices` (latest 50 durable owned KYC decision notices) |
| GET/PATCH | `/vendor/settings` (delivery, subscription, availability, service area) |
| PUT | `/vendor/settings/service-pincodes` |
| GET/PUT | `/vendor/settings/service-area` (T-023 combined radius/pincode configuration; provisional until task verification) |
| GET/POST | `/vendor/holidays` ; DELETE `/vendor/holidays/{id}` |
| POST | `/vendor/delivery/pause` `{ until? }` ; POST `/vendor/delivery/resume` |
| GET | `/vendor/dashboard?date=YYYY-MM-DD` |

T-021 onboarding requires a held and active VENDOR role. Category creates the profile and
settings atomically, with next step 2; valid business save advances to step 3 without
regressing progress. GET restores persisted values. Business fields are required except
GSTIN and photo; omitted photo preserves it, null removes it. Photo IDs must be owned,
READY SHOP_PHOTO media. Mutations require a key of at most 120 characters; owner-scoped
24-hour replay and profile changes commit together; changed payload/endpoint returns 422.
Business before category returns 409. Onboarding writes cannot edit reviewed KYC business
fields (409); KYC-aware settings/re-verification editing belongs to T-106. No plan is granted.

T-023's combined service-area PUT accepts required `{ serviceRadiusKm, pincodes }`.
Radius is an integer 1–20 km or null to disable radius coverage; pincodes are unique
strings matching `^[1-9]\\d{5}$`. At least one coverage method must remain configured.
GET/PUT return the owned vendor profile with `settings.pincodes`, radius and version.
PUT requires Idempotency-Key and replaces the list/radius in the same replay-protected
transaction, incrementing settings version once. Radius requires saved shop coordinates
(409 SHOP_LOCATION_REQUIRED); no profile returns 409 CATEGORY_REQUIRED on PUT.
An empty combined area returns 400 SERVICE_AREA_REQUIRED. Session-derived ownership,
active vendor role and the onboarding replay rules apply. New settings default to 3 km;
the additive migration initializes previous unconfigured radii. Coverage is radius OR
listed pincode, using PostGIS geography meters (TC-028), with no geocoding fallback.
The shared coverage service is available to T-041/T-045; discovery and order integration
remain those tasks' responsibility. The combined endpoint is implemented by T-023;
the broader settings and separate pincode routes above remain future contracts.

### 4.3 Media
| Method | Path | Notes |
|---|---|---|
| POST | `/media` | Authenticated multipart `file` + allow-listed `purpose`; validate/quarantine then return `{mediaId, status}`; see LOCAL_FILE_STORAGE |
| GET | `/media/{id}/content` | Owner-only authenticated stream of READY file; no raw filesystem paths; cross-owner returns 404 |
| GET | `/admin/media/{id}/content` | KYC_DOC/SHOP_PHOTO stream with `kyc.documents` permission and persisted per-read audit; no-store, nosniff, attachment disposition |

### 4.4 Catalog (FR-030–FR-036)
T-027 adds `GET /vendor/products/options` → `{ productTypes: string[] }` for the
signed-in vendor's category. It uses the same active vendor-role/ownership and
suspension checks as catalog reads; types come from the admin-managed category,
with no client-invented taxonomy or cross-vendor category parameter.

`GET/POST /vendor/products`, `GET/PATCH/DELETE /vendor/products/{id}`, `POST /vendor/products/{id}/stock-adjustments` `{ delta, reason }`.

T-026 uses the held and active VENDOR role and derives vendor ownership from the
session; suspended vendors are denied. All mutations require `Idempotency-Key`.
List query: `search`, `productType` (category product-type code or `ALL`), `limit`
(1–100, default 50), `offset` (default 0); response `{ items, total }`. Vendor lists
include inactive products and exclude soft-deleted products. Other-owner/deleted
IDs return 404. Product input uses camelCase fields from FR-030; money is integral
paise, quantities are integer packs, and unitValue supports up to three decimals.
Required fields: name, productType, unitValue, unitType, sellingPricePaise; MILK
also requires milkType. Subscription price may be null or 0 through selling price.
Omitted stockQty/moq/description/isActive default to 0/1/empty/true. Image references
must be owned READY PRODUCT_IMAGE media; imageMediaId/subscriptionPricePaise and
non-milk milkType may explicitly be null. PATCH validates the merged product;
changing stockQty additionally requires stockReason. Delta adjustments require a
nonzero delta and nonblank reason; stock cannot become negative or overflow int32.
Soft delete returns `{ id, deleted: true }`, preserves history and returns 409
PRODUCT_IN_USE for ACTIVE/PAUSED subscription references. No customer/POS product
route is introduced here; those modules must use the active-selection guard.
Crossing from >10 to ≤10 packs atomically records a STOCK_LOW outbox domain event.
T-032 must gate notification delivery against real STOCK_ALERTS entitlements
(BUSINESS+) from T-084/T-103; recording an event is not a delivered notification.

### 4.5 Vendor customers (FR-060–FR-064)
`GET/POST /vendor/customers`, `GET/PATCH /vendor/customers/{id}`, `GET /vendor/customers/{id}/orders|subscriptions|ledger`. Customer side: `GET /customer/link-requests`, `POST /customer/link-requests/{id}/accept|decline`.

T-028 implements customer list/detail/create/PATCH and link-request list/accept/decline.
List accepts `search`, `filter=ALL|ACTIVE|SUBSCRIPTION|INACTIVE`, `limit` (1–100,
default 50), `offset`; response is `{items,total,activeCount,customerLimit}`.
Creation takes `name`, Indian `mobile` (10 digits or +91), optional `email`,
`address`, `preferredPayment=CASH|UPI|BANK|WALLET`; PATCH also accepts
`status=ACTIVE|INACTIVE`. Mobile is stored as +91 and unique per vendor, including
inactive rows. Null only clears email. Inactivation retains linkage/history;
linked mobile changes return 409 `LINKED_MOBILE_IMMUTABLE`.

ADR-028 permits exactly 50 active customers before any assignment, without
granting a plan. T-084/T-103 set the server-only assigned customer-limit projection
atomically with audited assignment; catalog caps remain 100/250/500/1000.
Create/reactivate lock the vendor and enforce capacity (422 `PLAN_CUSTOMER_LIMIT`),
including concurrent requests. No public field can set ownership, user linkage or
the limit. Every mutation requires Idempotency-Key; changed-body/path replay is 422.

Link requests are derived at read time from the authenticated, verified account's
mobile and unlinked vendor-customer records, so later registration is supported
without automatically linking. List accepts `limit`/`offset`, returning
`{items:[{id,vendorId,businessName}],total}`. IDs are vendor-customer IDs.
Decline persists and removes the prompt; only accept sets user_id. Another user's
ID/mobile, suspended vendor, or stale match is 404; conflicting decisions are 409.
Downstream ledger readers must use the accepted-link guard, never mobile matching.
Order/subscription/ledger histories and computed purchase/payment statistics remain
with their owning modules; T-028 does not return fabricated totals or history.

### 4.6 Orders & deliveries (FR-040–FR-046, FR-080–FR-081, FR-220–FR-225, FR-240–FR-243)
ADR-032: customer checkout accepts only `POD_CASH` / `POD_UPI`; reject `KHATA`
even when a legacy vendor credit flag is true. Existing ledger/payment access is
preserved. Vendor settings determine delivery charges, minimum, slots and cutoff;
today requires explicit enablement and a configured cutoff evaluated in server IST.
Customer cancellation is permitted only for NEW, without fee; later states return
409. T-045 implements quote/place, owned lists/details, NEW-only customer cancel
and vendor transitions through OUT_FOR_DELIVERY. Monetary responses use decimal
integer-paise strings to preserve BIGINT precision. Placement requires the reviewed
`expectedTotalPaise`; a mismatch returns 409 PRICE_CHANGED with `quote`. Product
errors include `productId`. Quote is a read-only POST (201), requiring no mutation
key; placement/cancel/transitions require Idempotency-Key. Request identity is
permanent and actor-scoped; mismatched path/body is 422. Reads use limit (20,
max 50)/offset and return `{items,total}`; vendor status CANCELLED includes REJECTED.
Optional vendor filters are status/q/date, customer filters include tab. Version
conflict is 409 VERSION_CONFLICT; capacity is 422 CAPACITY_REACHED. Details include
owned customer contact, address/item price snapshots and persisted status timeline.
Rejected-order reasons are available in detail; push content stays PII-minimized.
Unconfigured vendor slots/cutoff are not guessed. T-049 owns DELIVERED/FAILED and
financial/stock effects; T-051 owns reorder, T-074 vendor holiday/pause cancellation.
Vendor-created Add Order remains outside this customer-placement slice; the route
below is the planned contract and is not exposed by T-045. Check evidence/manual
handoff is recorded in the API README; this does not claim a module gate pass.

| Method | Path | Notes |
|---|---|---|
| GET | `/vendor/orders?status=&q=&date=` | |
| GET | `/vendor/orders/{id}` | |
| POST | `/vendor/orders` | vendor-created order for a customer ("Add Order") |
| POST | `/vendor/orders/{id}/transitions` | `{ to: ACCEPTED|REJECTED|PREPARING|OUT_FOR_DELIVERY|DELIVERED|FAILED|CANCELLED, version, reason?, payment?: { collected, method, amountPaise } }` |
| GET | `/vendor/deliveries?date=&status=` | counts per tab included |
| GET | `/customer/orders/options?vendorId=&addressId=` | T-046: owned address and eligible vendor; serverTime/businessDate, configured timeSlots/sameDayCutoff and availableDates today through +7 excluding cutoff/holiday/pause. Quote/place recheck price, stock and capacity. No guessed defaults or business writes. |
| POST | `/customer/orders/quote` | validates cart and returns priced bill (no side effects) |
| POST | `/customer/orders` | place order |
| GET | `/customer/orders?tab=ALL|ONGOING|DELIVERED|CANCELLED` | |
| GET | `/customer/orders/{id}` | |
| POST | `/customer/orders/{id}/cancel` | |
| POST | `/customer/orders/{id}/reorder` | returns cart lines + unavailable items |

### 4.7 Quick sale (FR-050–FR-054)
`POST /vendor/sales`, `GET /vendor/sales?date=`.

### 4.8 Subscriptions (FR-070–FR-077, FR-230–FR-233)
| Method | Path |
|---|---|
| GET/POST | `/vendor/subscriptions` ; GET/PATCH `/vendor/subscriptions/{id}` |
| POST | `/vendor/subscriptions/{id}/{approve|reject|pause|resume|cancel|skip}` |
| GET | `/customer/vendors/{vendorId}/subscription-plans` |
| GET/POST | `/customer/subscriptions` ; GET/PATCH `/customer/subscriptions/{id}` |
| POST | `/customer/subscriptions/{id}/{pause|resume|cancel|skip}` |
| GET | `/customer/subscriptions/{id}/statement?month=YYYY-MM` |

### 4.9 Ledger & payments (FR-110–FR-116, FR-250–FR-253)
| Method | Path |
|---|---|
| GET | `/vendor/khata?tab=ALL|RECEIVABLE|PAID&q=` |
| GET | `/vendor/khata/{vendorCustomerId}/entries?month=` |
| POST | `/vendor/khata/{vendorCustomerId}/opening` |
| POST | `/vendor/payments` |
| GET | `/vendor/payments/summary` ; GET `/vendor/payments` |
| GET | `/vendor/payment-claims?status=PENDING` ; POST `/vendor/payment-claims/{id}/confirm|reject` |
| POST | `/vendor/ledger-entries/{id}/reverse` `{ reason }` |
| GET | `/customer/khata/summary` ; GET `/customer/khata/vendors/{vendorId}/entries?month=` |
| POST | `/customer/khata/vendors/{vendorId}/claims` |
| GET/POST/PATCH/DELETE | `/customer/personal-contacts[/{id}]`, `/customer/personal-entries[/{id}]` |

### 4.10 Discovery, reviews, favorites (FR-200–FR-214)
| Method | Path |
|---|---|
| GET | `/customer/home?lat=&lng=` (categories, today's deliveries) |
| GET | `/customer/vendors?category=&lat=&lng=&sort=NEARBY|POPULAR&cursor=` |
| GET | `/customer/vendors/{id}` ; `/customer/vendors/{id}/products` |
| GET | `/customer/search?q=&lat=&lng=` |
| PUT/DELETE | `/customer/favorites/{vendorId}` |
| GET/POST/PATCH/DELETE | `/customer/addresses[/{id}]` |

T-042 implements `GET /customer/home` for active CUSTOMER sessions, returning
`{serverTime,businessDate,categories,deliveries,nextCursor}` with `Cache-Control:
no-store`. Database time determines businessDate in Asia/Kolkata; clients cannot
override date, owner or vendor. Categories are SUPPLY with ENABLED/COMING_SOON
status, sorted by admin sort order then ID; names use name_en. `available` means
category ENABLED, not vendor coverage. Hidden and BILL categories are omitted;
productTypes come from admin-managed values. Marketing/billing/provider fields
are absent. Deliveries are persisted orders due on that IST date whose accepted
vendor-customer linkage belongs to the session user. Matching mobile alone grants
no access. All statuses are preserved, including cancelled/rejected history;
expired plans, vendor suspension, inactive linked customers or deleted products
do not hide existing owned orders. Cards expose order/vendor IDs, order number,
vendor name, source, status, slot, date and snapshot product names/quantities;
addresses, customer records and financial fields are not exposed.
`limit` defaults to 20 (1–50); the last returned order UUID is the next cursor,
validated against the same owner/current IST day. Order is created_at then ID,
descending. Foreign, stale-day or invalid cursors return 400 INVALID_CURSOR.
Optional lat/lng must be provided as a valid numeric pair; optional pincode is
validated. These do not filter existing orders; discovery enforces coverage.
Refresh without a cursor when the IST day changes. Status changes load on refresh;
T-033 supplies the existing notification bell/inbox rather than duplicating it here.

Discovery sorting follows ADR-031 / FR-210: apply RULE-13 eligibility first and
place the current customer's favorites first. Within each favorite/non-favorite
group, NEARBY sorts by distance ascending; POPULAR sorts by completed (DELIVERED)
order count in the preceding 30 days descending, then distance ascending. Count
completion timestamps, not order creation; no qualifying orders means zero.
Vendor ID breaks remaining ties for deterministic pagination. Ratings, reviews,
POS sales and plan assignments do not contribute to popularity.

T-041 implements authenticated active-CUSTOMER reads above plus
`GET /customer/favorites`, `GET /customer/vendors/{id}/products/{productId}`
(returns `{items:[product],total:1}`) and
`GET /customer/vendors/{id}/media/{mediaId}/content`. All accept required numeric
`lat`, `lng` and six-digit `pincode`; list/search additionally accept category UUID,
q (literal substring, max 120), NEARBY/POPULAR, limit 1–50 (default 20) and cursor.
Search matches vendor names or active product names; the vendor products endpoint
supports q filtering and exposes current paise prices, MOQ, attributes and owned
image IDs. List responses are `{items,nextCursor}` with no ratings or review counts.
The signed keyset cursor binds customer/location/search/category/sort/favorites,
fixes the database-time popularity window, and expires after 15 minutes. Refresh
without a cursor to see new completions/favorite ordering. Eligibility is rechecked
on every page/detail/product/image read; unavailable vendors return 404
VENDOR_UNAVAILABLE. About includes address, charges and persisted holidays;
openingHours is explicitly null until business-hours settings are configured.
Media reads permit only attached READY shop/product media of eligible vendors,
using existing private storage checks; KYC and unrelated uploads remain denied.
Favorites PUT/DELETE require Idempotency-Key (max 120), with transactional user-scoped
24-hour replay/mismatch rejection. PUT requires current vendor eligibility; DELETE
can remove an unavailable vendor without exposing its data. Responses are no-store.

T-040 / FR-291: authenticated active CUSTOMER role only. Collection GET returns
`{ items: AddressResponse[] }` (default first, then creation time/ID); detail GET
returns one owned live address. POST requires `label`, `line1` (house/flat), `line2`
(street/area), `city`, `state`, `pincode` (six digits, first nonzero), numeric
`latitude` [-90,90] and `longitude` [-180,180]. `landmark` is optional and defaults
to empty; `isDefault` is optional. PATCH accepts the same fields partially; null,
unknown ownership fields and numeric strings are rejected. Empty landmark clears it.
All mutations require `Idempotency-Key` (max 120 characters), scoped to the user
across address method/target/payload, with atomic 24-hour replay; mismatches return
422 `IDEMPOTENCY_MISMATCH`. First address becomes default; setting another default
clears the previous one atomically. Clearing the current default without choosing
another returns 409 `DEFAULT_ADDRESS_REQUIRED`. DELETE soft-deletes, returns
`{ id, deleted: true }`, and promotes the oldest remaining live address when needed.
Nonempty collections always have one default. Foreign/deleted IDs return 404
`ADDRESS_NOT_FOUND`; responses use `Cache-Control: no-store`. Saving addresses
does not assert vendor coverage: discovery/checkout must combine the transactional
owned-address lookup with the existing server radius-OR-pincode helper; no provider
or address-to-coordinate inference is used.

### 4.11 POST-DELIVERY customer features (SR-01/SR-02)
These endpoints are future reference only; no routes, credentials or tests are required for this delivery. Personal Khata endpoints in §4.9 remain active.
| Area | Endpoints |
|---|---|
| Money (FR-260–FR-262) | `GET /customer/money/summary?month=`, CRUD `/customer/money/transactions` |
| Insights (FR-294) | `GET /customer/insights?month=` |
| Grocery assist (FR-282) | `POST /customer/grocery/parse` `{ vendorId, text, source: VOICE|IMAGE, locale }` → `{ matched[], unmatched[] }` |
| Bill payments (FR-271–272) | `/customer/bills/**` — TBD with partner (Q-07) |
| Referral (FR-293) | `GET /customer/referral` — TBD (Q-14) |

### 4.12 Reports, notifications, plans, content
| Method | Path |
|---|---|
| GET | `/vendor/reports/summary?from=&to=` ; `/vendor/reports/sales-daily` (table data) ; `/vendor/reports/products` |
| POST | `/vendor/reports/exports` `{ from, to, format: CSV }` → `{ exportId }` ; GET `/vendor/reports/exports/{id}` → `{ status, downloadPath } (authenticated download endpoint; no public filesystem path)` |
| GET | `/notifications?role=&category=` ; POST `/notifications/read` `{ ids | all }` ; DELETE `/notifications` |
| GET/PUT | `/me/notification-prefs` |
| GET | `/vendor/plans` ; GET `/vendor/plan` (current, entitlements) |
| GET | `/content/faqs?topic=` ; `/content/legal/{type}` |

T-103 implements `/vendor/plans` (active DB catalog, integer-paise prices, approved
tier features/caps) and `/vendor/plan` (owned assignment ID/tier/dates, lifecycle
status, effective features, active customer count and growth availability).
Vendor responses exclude internal reasons/admin/audit identifiers. States are
UNASSIGNED, SCHEDULED, ACTIVE, EXPIRED and UNAVAILABLE; setup has limit 50 and no
paid features. No checkout, invoice or payment record is fabricated.

Plan administrators (SUPER_ADMIN/FINANCE, `plans.manage`) use GET `/admin/plans`
and `/admin/vendors/{id}/plan`, POST `/admin/vendors/{id}/plan-assignments`
`{ planId, startsAt, endsAt, reason }`, and POST
`/admin/vendors/{id}/plan-assignments/{assignmentId}/extend` `{ endsAt, reason }`.
Mutations require bearer session, X-CSRF-Token and Idempotency-Key. Dates must be
timezone-qualified ISO timestamps; end must be after start and DB now. Extension
targets the current owned assignment and strictly increases its end; it returns
a new assignment ID while retaining old dates/audit as history. A new assignment
supersedes the current row immediately; a future start remains SCHEDULED without
new-business access until validity begins. Earlier authorized history/settlement
operations remain available under ADR-029 and their normal domain rules.
Permanent actor-scoped replay returns the original result; changed payload/path
returns 422 IDEMPOTENCY_MISMATCH. Invalid input/dates return 400; unavailable plan
409; unknown vendor/current assignment 404; forbidden role/CSRF/suspension 403.
Assignment, audit, cap projection, replay identity and 7/3/1/expiry jobs commit
atomically. Catalog editing/admin screens are supplied by T-156; billing remains deferred.

T-156 implements PUT `/admin/plans/{id}` with `{ name, status, isPopular,
expectedUpdatedAt, reason, prices: [{ duration, pricePaise }] }`. All three catalog
durations are required once each; paise must be non-negative safe integers.
Approved tier codes/caps/features are read-only; attempts to submit policy fields
are rejected. `updatedAt` is returned by catalog reads; stale edits return 409
PLAN_CATALOG_CHANGED. Catalog metadata/prices, audit and permanent replay commit
atomically. INACTIVE catalog status also removes active assignment entitlements;
the admin screen explains this effect. Prices remain reference data, not payments.

GET `/admin/plan-vendors?search=&offset=` is a plans.manage-scoped lookup returning
only vendor ID/business name, 20 rows per page. It grants no KYC/customer/contact
access. GET `/admin/vendors/{id}/plan-history?offset=` returns 20 retained records
with reason, validity, superseded time, admin/audit IDs. Search is limited to 80
characters; offset is an integer from 0 to 1,000,000. All routes require the
existing SUPER_ADMIN/FINANCE plan permission. Admin BFF forms retain server-only
credentials and require same origin, session CSRF and operation/target-bound keys.

T-032 implements these notification routes and PUT `/me/devices/current`.
Session identity owns all reads/mutations; optional role must be held by that user
(default active role). Customer DELIVERY filtering is rejected. List supports
category ALL/ORDERS/PAYMENTS/DELIVERY/SYSTEM, limit 1–100 (default 50), offset ≥0;
returns items/total and role-wide unreadCount. Items expose id/role/category/type,
generic English title/body, safe internal path and UTC createdAt/readAt only.
Rows cleared or ≥90 days old are invisible. Read accepts exactly ids (1–100 UUIDs)
or all=true, plus optional role; foreign/wrong-role IDs fail atomically. Clear is
role-scoped. Every mutation requires Idempotency-Key. Preferences replace the four
orders/payments/delivery/system booleans; they affect optional pushes, not inbox
storage or mandatory KYC/security. Marketing preferences remain excluded.
Current-device updates derive the device from the authenticated session, never a
client device/user ID. pushEnabled is required; a token is required when enabled.
Null/omitted pushToken with false removes it. Only Android registration is active;
responses contain deviceId/pushEnabled, never tokens. Logout clears affected tokens.
Notification creation is internal to authorized domain transactions. FCM acceptance
is not proof of device delivery; live delivery and T-033 handling require separate
evidence. Existing low-stock domain events are not consumed without real entitlement
policy from T-084/T-103; this is not a module/event-coverage pass.

### 4.13 Admin (`/admin/**`, FR-400–FR-413)
T-150 implements password login → five-minute challenge → mandatory TOTP verification/enrolment → session. `GET /admin/auth/challenge` reads enrolment setup using the pending bearer credential; `GET /admin/auth/me` returns only id/role/permissions. These are server-to-server BFF operations; the browser receives httpOnly Strict cookies (Secure over HTTPS), while the Next.js server supplies the opaque bearer to the API. Logout additionally requires `X-CSRF-Token`; all mutations require `Idempotency-Key`, but auth responses are never replay-cached. Five password/TOTP failures lock an account for 30 minutes; session expiry is 30 minutes idle/eight hours absolute. Unannotated admin routes and unlisted permissions are denied. Local operator provisioning uses breached-password checks; admin-account management remains T-162.

`POST /admin/auth/login`, `/admin/auth/totp/verify`, `/admin/auth/logout`; `GET /admin/dashboard`; `GET /admin/kyc?beforeId=`, `GET /admin/kyc/{submissionId}`, `POST /admin/kyc/{submissionId}/decision` (T-022); document reads use `GET /admin/media/{mediaId}/content` (authorized private stream, audit-logged); `GET/PATCH /admin/vendors[/{id}]`, `POST /admin/vendors/{id}/suspend|reinstate`; `GET/PATCH /admin/customers[/{id}]`; CRUD `/admin/categories`, `/admin/plans`, `/admin/faqs`, `/admin/legal`, `/admin/config`; `GET /admin/audit-logs`; `GET/POST /admin/data-requests`; `POST /admin/reports/exports`; CRUD `/admin/admins`.

T-154 implements GET `/admin/dashboard`, with `dashboard.read` permission
(SUPER_ADMIN under ADR-026), live session authorization and `Cache-Control: no-store`.
One database statement returns `serverTime`, `vendorsTotal`, `vendorsSuspended`,
`kycPending` (MANUAL_REVIEW), `kycVerified`, `customersTotal`, `customersBlocked`,
`ordersTotal`, `ordersDelivered`, `ordersFailed`, `recordedGmvPaise`,
`gmvScope: DELIVERED_ORDERS_ONLY`, `planAssignmentsTotal` and `planRevenueStatus: UNAVAILABLE`. Counts are all-time
retained rows. Customer accounts require a CUSTOMER role (including dual-role,
blocked and deleted accounts); vendor-owned offline links are not accounts.
The available GMV component is the sum of persisted DELIVERED order totals, including stored delivery
charges/discounts, returned as a decimal integer paise string for exact BigInt
precision. It is not payment receipts or platform revenue. Full PRD platform GMV also includes quick sales; that component is unavailable before T-079/T-080 and is not fabricated here. Delivery success is
DELIVERED / (DELIVERED + FAILED), with no percentage when there are no completed
attempts. Pending/cancelled/rejected orders are excluded from this denominator.
Plan grants count all audited assignment rows, including superseded history;
there is no billing revenue calculation or purchase inference. No date filter or
forecast is implemented. Aggregate metrics expose no individual account/PII data.
Actual order/delivery writers remain T-045/T-049; seeded fixtures only verify reads.

T-155 implements GET `/admin/vendors` and `/admin/customers` with optional search
(name/mobile/ID, at most 80 characters) and offset (0–1,000,000), 20 records/page;
GET `/admin/vendors/{id}` and `/admin/customers/{id}` return retained details.
Customer management targets app accounts holding CUSTOMER, including dual-role
accounts, rather than vendor-owned offline contact records. vendors.read and
customers.read permit the corresponding views; FINANCE has neither permission.
Vendor detail includes safe read-only KYC/plan state, not private KYC documents.

POST `/admin/vendors/{id}/suspend|reinstate`, PATCH `/admin/vendors/{id}` (display
badges), and POST `/admin/customers/{id}/block|unblock` require the corresponding
manage permission (OPS/SUPER_ADMIN), CSRF and Idempotency-Key. Bodies contain
`{ reason, expectedUpdatedAt }`; badge PATCH additionally accepts `badges`, up to
10 unique trimmed display labels, each 1–40 characters. Labels do not alter KYC,
plan or discovery authorization. Other policy/status fields are rejected.
All mutations return 200; stale records/deleted accounts return 409, changed
replay payload/path 422. Status, redacted before/after audit and permanent replay
commit atomically. Customer block revokes active sessions and clears push tokens
under the session user lock; verified-OTP login fails ACCOUNT_BLOCKED until
unblocked. Unblock requires fresh login and cannot reactivate deleted accounts.
Suspension persists the server guard flag; T-041/T-045 must also enforce it on
discovery/new order acceptance. Those downstream journeys remain unverified.

T-153 implements `GET/POST /admin/categories` and `PUT /admin/categories/{id}`.
OPS/SUPER_ADMIN require `categories.manage`; writes also require CSRF and a
1–120 character Idempotency-Key. Fields: `code` (uppercase identifier), `name`
(English), `icon` (identifier or empty), `type` (SUPPLY/BILL), `status`
(ENABLED/COMING_SOON/HIDDEN), nonnegative integer `sortOrder`, `productTypes`
(up to 50 unique nonblank names). List returns `{ items }` in order/code order.
Hidden replaces removal and preserves vendor references. Type changes are rejected
when a vendor references the category. Duplicate code returns 409, missing ID 404,
changed retry payload/path 422. Actor-scoped concurrent replay, category write and
immutable before/after audit commit together. No bill-payment actions are added.

T-152 implements `GET /admin/audit-logs` with `audit.read` (SUPER_ADMIN only), no-store responses and no write endpoint. Optional `action` (uppercase/underscore, ≤64), `actorId` and `beforeId` (UUID cursor) filters return `{items, hasMore}` in descending `(at,id)` order, at most 50 rows. Each item includes actor type/id, action, entity/id, redacted before/after, socket IP and UTC time. Historical unavailable values remain null. S-A-16 calls this only from the Next.js server; no staff token reaches the browser.

## 5. Key Examples

### 5.1 Place order
```http
POST /api/v1/customer/orders
Authorization: Bearer eyJ…
Idempotency-Key: 0f8d6a1e-7c1b-4a8e-9a0b-3f0d1c2e4b5a
Content-Type: application/json

{
  "vendorId": "0192f…",
  "items": [{ "productId": "0192f…a1", "qty": 2 }, { "productId": "0192f…a2", "qty": 1 }],
  "addressId": "0192f…ad",
  "deliveryDate": "2026-10-20",
  "timeSlot": "07:00-08:00",
  "paymentMode": "POD_UPI",
  "expectedTotalPaise": 13000
}
```
```json
201 Created
{
  "id": "0192f…o1", "orderNo": "ORD00012345", "status": "NEW",
  "deliveryDate": "2026-10-20", "timeSlot": "07:00-08:00",
  "items": [
    { "productId": "…a1", "name": "Cow Milk", "unit": "1 L", "unitPricePaise": 5000, "qty": 2, "lineTotalPaise": 10000 },
    { "productId": "…a2", "name": "Curd", "unit": "500 g", "unitPricePaise": 3000, "qty": 1, "lineTotalPaise": 3000 }
  ],
  "subtotalPaise": 13000, "deliveryChargePaise": 0, "discountPaise": 0, "totalPaise": 13000,
  "paymentMode": "POD_UPI", "paymentStatus": "UNPAID", "version": 1
}
```
If server total ≠ `expectedTotalPaise` → `409 PRICE_CHANGED` with the new quote.

### 5.2 Mark delivered with payment
```http
POST /api/v1/vendor/orders/0192f…o1/transitions
Idempotency-Key: 6b1c…
{ "to": "DELIVERED", "version": 3, "payment": { "collected": true, "method": "CASH", "amountPaise": 13000 } }
```
Response: updated order (`paymentStatus: PAID`). Side effects: DEBIT 13000 + CREDIT 13000, stock −2/−1, push to customer.

### 5.3 Create subscription (vendor)
```json
POST /api/v1/vendor/subscriptions
{ "vendorCustomerId": "…", "productId": "…", "qty": 1, "weekdays": ["MON","TUE","WED","THU","FRI","SAT","SUN"],
  "startDate": "2026-10-21", "endDate": null, "timeSlot": "07:00-08:00", "paymentMethod": "CASH" }
→ 201 { "id": "…", "status": "ACTIVE", "dailyAmountPaise": 4800, "monthlyEstimatePaise": 148800, "version": 1 }
```

### 5.4 Error example
```json
422 { "code": "BELOW_MOQ", "status": 422, "title": "Quantity too low",
      "errors": [{ "field": "items[0].qty", "code": "BELOW_MOQ", "message": "Minimum order is 2" }] }
```

## 6. Validation Summary
Server re-validates everything listed in SRS/SCREEN_SPECIFICATIONS (regexes, ranges, RULE-xx). DTOs use `class-validator` + whitelist (`forbidNonWhitelisted: true`). Unknown enum values from newer clients are rejected with `VALIDATION_FAILED`.

## 7. Versioning & Compatibility
- URI major version (`/v1`). Additive changes only within v1; mobile tolerates unknown fields/enum values (maps to `unknown`).
- Breaking changes require `/v2` or a force-update via `minVersion` with ≥ 30 days overlap.

## 8. Open Questions
Bill payments, coupons, referral endpoints pending Q-07, Q-06, Q-14. Billing checkout payload depends on ADR-015.

## 7. Approved delivery contract boundaries
ADR-024: no active Money/insights/recognition/BBPS/referral/coupon/review/banner/broadcast, automated KYC webhook or billing checkout/verification/webhook/invoice routes. Future descriptions above remain POST-DELIVERY only. Unsupported client inputs such as Rating sort, coupon discount or provider status cannot bypass active server validation.

Manual KYC approval/rejection records reviewer, reason, method MANUAL_REVIEW, audit and notification; provider checks are NOT_RUN. `POST /admin/vendors/{id}/plan-assignments` and `POST /admin/vendors/{id}/plan-assignments/{assignmentId}/extend` accept validated catalog plan/dates/reason and require permission/idempotency; record audit and update effective entitlements atomically. `GET /vendor/plan` shows real assigned validity/limits. No assignment creates a payment, invoice or revenue. ADR-029 resolves Q-04: no automatic trial/grace; expired assignments retain history/settlement and normally permitted existing-order operations but deny new business/customer additions/reactivations; over-limit downgrade retains records and restricts additions/reactivations while applying new feature gates. No fallback to the pre-assignment allowance. Retain A-04/RULE-13 visibility baseline; Q-18 does not block the manual assignment service.

Address/discovery requests accept manual pincode/address/validated coordinates or device GPS; coverage checks stay server-side without a maps provider. Reports are tables and CSV-only authorized downloads. Basic `/config`/admin config uses existing API/DB, not campaign tooling.

ADR-025: active client platform is Android; keep compatible iOS enum values/contracts for later validation. Existing source/OpenAPI/generated clients are unchanged by this documentation revision; reconcile from source under authorized task implementation, never hand-edit generated artifacts.

### T-022 manual KYC contract
`POST /vendor/kyc` accepts `aadhaarFrontMediaId`, `aadhaarBackMediaId`, `panMediaId`,
`pan`, `holderName`, `bankName`, `accountNumber`, `accountNumberConfirmation`, `ifsc`,
and optional `upiId`. Requires active/held VENDOR role, completed business information,
three distinct owned READY KYC_DOC attachments and an Idempotency-Key. Uploaders supply
already-masked Aadhaar (ADR-027); no Aadhaar number is accepted or automatically validated.
This smallest slice saves all submission fields atomically rather than exposing a partial
KYC/bank draft. T-024 owns the mobile form. Invalid/confirmation input returns 400,
unavailable attachments 404, invalid state/incomplete business 409 and changed-key reuse 422.
Submission creates a revision in MANUAL_REVIEW and advances onboarding to step 4.

`GET /admin/kyc` requires `kyc.review`, returns `{items,hasMore}` (50 pending revisions,
oldest `(submittedAt,id)` first); `beforeId` is the continuation cursor. Detail and
`POST /admin/kyc/{submissionId}/decision` use revision IDs, not vendor IDs.
Decision body is `{decision: VERIFIED|REJECTED, reason}` with 3–500 characters after
trimming; Idempotency-Key and X-CSRF-Token are required. OPS/SUPER_ADMIN can review;
SUPPORT/FINANCE cannot. Reads are no-store; response objects expose only PAN/account
last-4, document IDs and the other submitted business fields, never full numbers/ciphertext.
Revision, vendor status, immutable redacted audit reference and owned durable in-app notice
commit together. Rejection permits a new revision; a closed revision cannot be edited/deleted.
Reason/reviewer/time remain on the revision; free-text reasons are omitted from general
audit snapshots. Status/method/provider evidence is explicit: MANUAL_REVIEW and NOT_RUN.
Push/SMS delivery is not claimed; the notice endpoint is runnable before T-032.

Development/test PAN and account encryption uses FIELD_ENCRYPTION_KEY with AES-256-GCM,
fresh nonces and vendor/field-bound AAD. No automatic secret fallback exists. Staging/production
writes return 503 KYC_ENCRYPTION_UNAVAILABLE until the documented KMS envelope path is
implemented/configured; local task evidence is not production encryption readiness.
