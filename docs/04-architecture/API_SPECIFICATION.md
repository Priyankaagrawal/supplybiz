# API SPECIFICATION

| Field | Value |
|---|---|
| Status | Draft v0.1 |
| Owner | Technical Architect (Backend) |
| Last updated | 2026-10-19 |
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
| Localization | `Accept-Language: en|hi` for server-provided text (errors, CMS, notifications) |
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
simulates delivery without exposing OTPs. Redis failures return `503 OTP_UNAVAILABLE`.
OTP verification is an internal, single-use service in T-014; the public verify
endpoint, user/session creation and tokens belong to T-015.
| GET | `/config` | public: minVersion, feature flags, categories, legal versions (cacheable) |

### 4.2 Vendor onboarding, settings (FR-010–FR-018, FR-075, FR-082–FR-085, FR-130–FR-132)
| Method | Path |
|---|---|
| POST | `/vendor/onboarding/category` |
| PUT | `/vendor/onboarding/business` |
| PUT | `/vendor/kyc` (documents mediaIds, pan, aadhaarLast4, bank, upiVpa) |
| POST | `/vendor/kyc/submit` |
| GET | `/vendor/kyc` (status, reason; masked values only) |
| GET/PATCH | `/vendor/settings` (delivery, subscription, availability, service area) |
| PUT | `/vendor/settings/service-pincodes` |
| GET/POST | `/vendor/holidays` ; DELETE `/vendor/holidays/{id}` |
| POST | `/vendor/delivery/pause` `{ until? }` ; POST `/vendor/delivery/resume` |
| GET | `/vendor/dashboard?date=YYYY-MM-DD` |

### 4.3 Media
| Method | Path | Notes |
|---|---|---|
| POST | `/media/upload-url` | `{ purpose: PRODUCT_IMAGE|SHOP_PHOTO|KYC_DOC|PROFILE, mime, sizeBytes, sha256 }` → `{ mediaId, url, headers, expiresAt }` (PUT, 10 min) |
| POST | `/media/{id}/complete` | server validates size/mime/hash, triggers scan |

### 4.4 Catalog (FR-030–FR-036)
`GET/POST /vendor/products`, `GET/PATCH/DELETE /vendor/products/{id}`, `POST /vendor/products/{id}/stock-adjustments` `{ delta, reason }`.

### 4.5 Vendor customers (FR-060–FR-064)
`GET/POST /vendor/customers`, `GET/PATCH /vendor/customers/{id}`, `GET /vendor/customers/{id}/orders|subscriptions|ledger`. Customer side: `GET /customer/link-requests`, `POST /customer/link-requests/{id}/accept|decline`.

### 4.6 Orders & deliveries (FR-040–FR-046, FR-080–FR-081, FR-220–FR-225, FR-240–FR-243)
| Method | Path | Notes |
|---|---|---|
| GET | `/vendor/orders?status=&q=&date=` | |
| GET | `/vendor/orders/{id}` | |
| POST | `/vendor/orders` | vendor-created order for a customer ("Add Order") |
| POST | `/vendor/orders/{id}/transitions` | `{ to: ACCEPTED|REJECTED|PREPARING|OUT_FOR_DELIVERY|DELIVERED|FAILED|CANCELLED, version, reason?, payment?: { collected, method, amountPaise } }` |
| GET | `/vendor/deliveries?date=&status=` | counts per tab included |
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
| GET | `/customer/home?lat=&lng=` (banners, categories, today's deliveries) |
| GET | `/customer/vendors?category=&lat=&lng=&sort=NEARBY|POPULAR|RATING&cursor=` |
| GET | `/customer/vendors/{id}` ; `/customer/vendors/{id}/products` ; `/customer/vendors/{id}/reviews` |
| GET | `/customer/search?q=&lat=&lng=` |
| POST | `/customer/orders/{id}/review` |
| PUT/DELETE | `/customer/favorites/{vendorId}` |
| GET/POST/PATCH/DELETE | `/customer/addresses[/{id}]` |
| GET | `/geo/reverse?lat=&lng=` ; `/geo/autocomplete?q=` (proxied, rate-limited) |

### 4.11 Other customer features
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
| GET | `/vendor/reports/summary?from=&to=` ; `/vendor/reports/sales-chart` ; `/vendor/reports/products` |
| POST | `/vendor/reports/exports` `{ from, to, format }` → `{ exportId }` ; GET `/vendor/reports/exports/{id}` → `{ status, downloadUrl }` |
| GET | `/notifications?role=&category=` ; POST `/notifications/read` `{ ids | all }` ; DELETE `/notifications` |
| GET/PUT | `/me/notification-prefs` |
| GET | `/vendor/plans` ; GET `/vendor/plan` (current, entitlements) |
| POST | `/vendor/plan/checkout` `{ planPriceId }` → provider payload (ADR-015) ; POST `/vendor/plan/verify` |
| POST | `/webhooks/billing/{provider}` ; `/webhooks/kyc/{provider}` (signature-verified, no auth) |
| GET | `/vendor/plan/invoices` |
| GET | `/content/faqs?topic=` ; `/content/legal/{type}` |

### 4.13 Admin (`/admin/**`, FR-400–FR-413)
`POST /admin/auth/login`, `/admin/auth/totp/verify`, `/admin/auth/logout`; `GET /admin/dashboard`; `GET /admin/kyc?status=`, `GET /admin/kyc/{vendorId}`, `POST /admin/kyc/{vendorId}/approve|reject`, `GET /admin/kyc/{vendorId}/documents/{docId}/url` (audit-logged, 60 s URL); `GET/PATCH /admin/vendors[/{id}]`, `POST /admin/vendors/{id}/suspend|reinstate`; `GET/PATCH /admin/customers[/{id}]`; CRUD `/admin/categories`, `/admin/plans`, `/admin/banners`, `/admin/coupons` (TBD), `/admin/faqs`, `/admin/legal`, `/admin/config`; `POST /admin/broadcasts`; `GET/PATCH /admin/reviews`; `GET /admin/audit-logs`; `GET/POST /admin/data-requests`; `POST /admin/reports/exports`; CRUD `/admin/admins`.

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
