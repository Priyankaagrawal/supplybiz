# DECISIONS — Architecture Decision Records

| Field | Value |
|---|---|
| Status | Draft v0.1 |
| Owner | Technical Architect |
| Last updated | 2026-10-19 |
| Related | [ARCHITECTURE](../04-architecture/ARCHITECTURE.md), [SCOPE](../01-business/SCOPE.md) |

> **Source of truth for technical decisions.** If any document conflicts with an ADR marked *Accepted*, the ADR wins; fix the other document. New decisions are appended (never renumber). Status: *Proposed* → *Accepted* → (*Superseded by ADR-xxx*).

## Index
| ADR | Title | Status |
|---|---|---|
| ADR-001 | Flutter for the mobile app | Accepted (stakeholder) |
| ADR-002 | Single app with role-based shells | Accepted (stakeholder) |
| ADR-003 | Monorepo (melos + pnpm/Turborepo) | Accepted (stakeholder: one monorepo) / tooling Proposed |
| ADR-004 | NestJS + PostgreSQL (PostGIS) + Prisma modular monolith | Accepted (stack) / Prisma Proposed |
| ADR-005 | Riverpod + go_router | Proposed |
| ADR-006 | drift + SQLCipher local DB with outbox for vendor offline writes | Proposed |
| ADR-007 | OTP-only authentication; JWT access + rotating opaque refresh | Accepted (OTP-only) / token design Proposed |
| ADR-008 | Off-platform customer payments; app records only | Accepted (stakeholder) |
| ADR-009 | Money as integer paise | Proposed |
| ADR-010 | Firebase for push, analytics, crash, config, performance | Proposed |
| ADR-011 | Redis + BullMQ for jobs and scheduling | Proposed |
| ADR-012 | Next.js admin panel | Proposed |
| ADR-013 | OpenAPI-first contract with generated clients | Proposed |
| ADR-014 | KYC via third-party API with manual fallback; masked Aadhaar only | Accepted (API+manual) / masking Proposed |
| ADR-015 | Vendor SaaS plan billing channel | **Open — needs decision (Q-03)** |
| ADR-016 | Status-based delivery tracking; no live GPS in v1 | Accepted (stakeholder) |
| ADR-017 | Cloud provider | **Open (Q-02)** |
| ADR-018 | Direct-to-storage uploads with pre-signed URLs | Proposed |
| ADR-019 | Localization via ARB/intl, EN + HI | Accepted (languages) / tooling Proposed |
| ADR-020 | Certificate pinning (SPKI, intermediate + backups) | Proposed |
| ADR-021 | Append-only ledger with materialized balances | Proposed |
| ADR-022 | Single brand "Supply Biz" | Accepted (stakeholder) |

---

### ADR-001 Flutter for the mobile app
- **Context:** Android + iOS, small team/AI agents, consistent UI, low-end Android performance.
- **Decision:** Flutter (stable channel, version pinned with FVM).
- **Alternatives:** React Native (good, but stakeholder chose Flutter); native ×2 (cost).
- **Consequences:** Single Dart codebase; platform channels for FLAG_SECURE/UPI where plugins insufficient; must watch APK size.

### ADR-002 Single app with role-based shells
- **Context:** Stakeholder chose one store listing; users may be both vendor and customer.
- **Decision:** One app; `active_role` on user; separate `VendorShell`/`CustomerShell`; role switch without re-login; API namespaces `/vendor` & `/customer`.
- **Consequences:** Store listing must describe both audiences; larger binary; role-mismatch handling for deep links/notifications (R-12). Separate apps can be split later because features are role-scoped.

### ADR-003 Monorepo
- **Decision:** One repo: `apps/{mobile,api,admin}`, `packages/*`, `contracts/`. Dart workspace via **melos**; TS via **pnpm workspaces + Turborepo**. CI uses path filters.
- **Consequences:** Atomic contract changes across API and clients; two toolchains to maintain.

### ADR-004 NestJS + PostgreSQL + Prisma modular monolith
- **Decision:** One NestJS codebase with API & worker entry points; PostgreSQL 16 + PostGIS; Prisma ORM (raw SQL allowed for geo/reporting via `$queryRaw` with parameters only).
- **Alternatives:** TypeORM/Drizzle (viable); microservices (premature).
- **Consequences:** Simple deployment; module boundaries enforced by lint rules (eslint-plugin-boundaries).

### ADR-005 Riverpod + go_router
- **Decision:** Riverpod 2 with code generation for state/DI; go_router with typed routes and StatefulShellRoute.
- **Alternatives:** Bloc (more boilerplate), Provider (less capable).
- **Consequences:** Consistent patterns for agents; documented in CODING_STANDARDS.

### ADR-006 drift + SQLCipher + outbox
- **Context:** Vendors deliver in areas with poor connectivity (NFR-007).
- **Decision:** drift (SQLite) encrypted with SQLCipher; client outbox with idempotency keys; server-authoritative conflicts.
- **Alternatives:** Hive/Isar (less relational querying), full CRDT sync (overkill).
- **Consequences:** Idempotency required server-side for all offline-capable endpoints.

### ADR-007 OTP-only authentication
- **Decision:** Mobile + OTP (SMS/WhatsApp) for vendors and customers; no passwords; access JWT 15 min; opaque rotating refresh 30 days with reuse detection. "Change Password" removed from vendor settings.
- **Consequences:** Dependent on SMS deliverability (R-05); account recovery = OTP to same number; number change flow TBD.

### ADR-008 Off-platform customer payments
- **Decision:** Customers pay vendors directly (cash/UPI/bank/wallet). The platform records payments and payment claims; it never holds customer funds. UPI via intent to vendor VPA.
- **Consequences:** No PA/PG licensing for customer payments; disputes handled by vendor confirmation (R-06). "Settle to Bank", "take-rate" and Premium "Wallet/Settlement" undefined (Q-05).

### ADR-009 Money as integer paise
- **Decision:** All amounts `BIGINT`/`int` paise; formatting only at UI; no floating point.
- **Consequences:** Unit conversions explicit; rounding rule: per-line `unit_price × qty` (exact).

### ADR-010 Firebase services
- **Decision:** FCM (with APNs), Analytics, Crashlytics, Performance, Remote Config, App Check. Mixpanel not used.
- **Consequences:** Google dependency; DPA required; consent gating for analytics.

### ADR-011 Redis + BullMQ
- **Decision:** Redis for OTP, rate limiting, cache, queues; BullMQ repeatable jobs for scheduling (22:00 IST generation, expiry reminders, retention).
- **Consequences:** Redis must be highly available; job idempotency enforced in DB.

### ADR-012 Next.js admin panel
- **Context:** Stakeholder requires fully documented admin panel; stack not specified.
- **Decision:** Next.js (App Router) + TypeScript + shadcn/ui + TanStack Query, consuming the same API via generated TS client; BFF route handlers hold session cookie.
- **Alternatives:** React + Vite SPA; Refine/React-Admin (faster CRUD, less control).
- **Consequences:** TS shared tooling with API.

### ADR-013 OpenAPI-first contract
- **Decision:** NestJS Swagger decorators produce `contracts/openapi.yaml`; CI fails if generated spec differs from committed; Dart client generated via `openapi-generator` (dart-dio) into `packages/api_client`; TS client via `openapi-typescript`.
- **Consequences:** No hand-written DTOs on clients.

### ADR-014 KYC verification
- **Decision:** Verify PAN and bank (penny-drop) via third-party API; Aadhaar method TBD (Q-08); mismatches/failures go to manual admin review. Store masked Aadhaar images and last-4 only; PAN/bank encrypted at field level.
- **Consequences:** Provider adapter interface; manual review SLA needed.

### ADR-015 Vendor SaaS plan billing channel — **OPEN**
- **Context:** Plans unlock in-app digital features. Apple guideline 3.1.1 and Google Play Payments policy generally require store billing for digital features sold in-app; exceptions are narrow. Using store billing costs 15–30% and complicates GST invoicing.
- **Options:** (A) Store billing (StoreKit 2 / Play Billing) with server receipt validation; (B) Sell plans only outside the app (web/admin/sales team) with no in-app purchase links/prompts on iOS; (C) Hybrid: Android user-choice billing where eligible + iOS per (A) or (B).
- **Required:** Product Owner + legal decision before M4. Implementation stays behind `BillingProvider` interface.

### ADR-016 Status-based tracking
- **Decision:** Order tracking via status timeline + push; no maps/live location in v1.
- **Consequences:** WF-10 map and delivery partner card replaced by vendor contact card.

### ADR-017 Cloud provider — **OPEN**
- **Decision pending (Q-02).** Constraint: India region, managed Postgres (PostGIS), managed Redis, S3-compatible storage with KMS, container runtime. Design stays provider-agnostic until decided.

### ADR-018 Pre-signed uploads
- **Decision:** Clients upload directly to object storage using short-lived pre-signed PUT URLs constrained by content-type and size; server finalizes, validates, scans. Two buckets: `media` (public via CDN, resized variants) and `kyc` (private, no CDN).

### ADR-019 Localization
- **Decision:** `flutter_localizations` + `intl` with ARB files (`app_en.arb`, `app_hi.arb`); server-side localized notifications/errors via `Accept-Language`/user language; CMS content stored per locale.

### ADR-020 Certificate pinning
- **Decision (proposed):** SPKI pin intermediate CA + 2 backup pins for API host in release builds; disabled in dev. Pins reviewed before every CA rotation; force-update used if pins must change.
- **Risk:** Mis-rotation can brick old clients — requires DevOps checklist.

### ADR-021 Append-only ledger
- **Decision:** `ledger_entries` insert-only (DB role lacks UPDATE/DELETE); corrections via reversal entries; `ledger_balances` updated in the same transaction; nightly reconciliation job compares sums and alerts on drift.

### ADR-022 Single brand
- **Decision:** App and store name "Supply Biz"; "SupplyMate" from mockups is not used.
