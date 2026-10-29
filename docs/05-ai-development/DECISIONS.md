# DECISIONS — Architecture Decision Records

| Field | Value |
|---|---|
| Status | Draft v0.1 |
| Owner | Technical Architect |
| Last updated | 2026-10-29 |
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
| ADR-010 | Firebase services | Basic push/crash retained; advanced portions superseded by ADR-024 |
| ADR-011 | Prior decision (historical only) | Superseded by ADR-023 |
| ADR-012 | Next.js admin panel | Proposed |
| ADR-013 | OpenAPI-first contract with generated clients | Proposed |
| ADR-014 | KYC and masked Aadhaar | Provider automation superseded for delivery by ADR-024; manual review/security retained |
| ADR-015 | Vendor SaaS plan billing channel | **Open — needs decision (Q-03)** |
| ADR-016 | Status-based delivery tracking; no live GPS in v1 | Accepted (stakeholder) |
| ADR-017 | Prior decision (historical only) | Superseded by ADR-023 |
| ADR-018 | Prior decision (historical only) | Superseded by ADR-023 |
| ADR-019 | Prior decision (historical only) | Superseded by ADR-023 |
| ADR-020 | Certificate pinning (SPKI, intermediate + backups) | Deferred by ADR-024 |
| ADR-021 | Append-only ledger with materialized balances | Proposed |
| ADR-022 | Single brand "Supply Biz" | Accepted (stakeholder) |
| ADR-023 | 15-day delivery baseline | Accepted (user instruction, 2026-10-29) |
| ADR-024 | Apply approved SR-01–SR-06 delivery scope | Accepted (user approval, 2026-10-29) |
| ADR-025 | Android-only execution until Android release | Accepted (user instruction, 2026-10-29) |

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
> ADR-024 controls current applicability: advanced/provider/billing/pinning portions below are POST-DELIVERY; preserved security, push/basic crash and manual-review behavior remain active.
- **Decision:** FCM (with APNs), Analytics, Crashlytics, Performance, Remote Config, App Check. Mixpanel not used.
- **Consequences:** Google dependency; DPA required; consent gating for analytics.

### ADR-011 Prior decision — superseded
- Superseded by ADR-023 on 2026-10-29 at the user’s explicit direction. Previous text is available in Git history and is not an implementation requirement.

### ADR-012 Next.js admin panel
- **Context:** Stakeholder requires fully documented admin panel; stack not specified.
- **Decision:** Next.js (App Router) + TypeScript + shadcn/ui + TanStack Query, consuming the same API via generated TS client; BFF route handlers hold session cookie.
- **Alternatives:** React + Vite SPA; Refine/React-Admin (faster CRUD, less control).
- **Consequences:** TS shared tooling with API.

### ADR-013 OpenAPI-first contract
- **Decision:** NestJS Swagger decorators produce `contracts/openapi.yaml`; CI fails if generated spec differs from committed; Dart client generated via `openapi-generator` (dart-dio) into `packages/api_client`; TS client via `openapi-typescript`.
- **Consequences:** No hand-written DTOs on clients.

### ADR-014 KYC verification
> ADR-024 controls current applicability: advanced/provider/billing/pinning portions below are POST-DELIVERY; preserved security, push/basic crash and manual-review behavior remain active.
- **Decision:** Verify PAN and bank (penny-drop) via third-party API; Aadhaar method TBD (Q-08); mismatches/failures go to manual admin review. Store masked Aadhaar images and last-4 only; PAN/bank encrypted at field level.
- **Consequences:** Provider adapter interface; manual review SLA needed.

### ADR-015 Vendor SaaS plan billing channel — **OPEN**
> ADR-024 controls current applicability: advanced/provider/billing/pinning portions below are POST-DELIVERY; preserved security, push/basic crash and manual-review behavior remain active.
- **Context:** Plans unlock in-app digital features. Apple guideline 3.1.1 and Google Play Payments policy generally require store billing for digital features sold in-app; exceptions are narrow. Using store billing costs 15–30% and complicates GST invoicing.
- **Options:** (A) Store billing (StoreKit 2 / Play Billing) with server receipt validation; (B) Sell plans only outside the app (web/admin/sales team) with no in-app purchase links/prompts on iOS; (C) Hybrid: Android user-choice billing where eligible + iOS per (A) or (B).
- **Required:** Product Owner + legal decision before M4. Implementation stays behind `BillingProvider` interface.

### ADR-016 Status-based tracking
- **Decision:** Order tracking via status timeline + push; no maps/live location in v1.
- **Consequences:** WF-10 map and delivery partner card replaced by vendor contact card.

### ADR-017 Prior decision — superseded
- Superseded by ADR-023 on 2026-10-29 at the user’s explicit direction. Previous text is available in Git history and is not an implementation requirement.

### ADR-018 Prior decision — superseded
- Superseded by ADR-023 on 2026-10-29 at the user’s explicit direction. Previous text is available in Git history and is not an implementation requirement.

### ADR-019 Prior decision — superseded
- Superseded by ADR-023 on 2026-10-29 at the user’s explicit direction. Previous text is available in Git history and is not an implementation requirement.

### ADR-020 Certificate pinning
> ADR-024 controls current applicability: advanced/provider/billing/pinning portions below are POST-DELIVERY; preserved security, push/basic crash and manual-review behavior remain active.
- **Decision (proposed):** SPKI pin intermediate CA + 2 backup pins for API host in release builds; disabled in dev. Pins reviewed before every CA rotation; force-update used if pins must change.
- **Risk:** Mis-rotation can brick old clients — requires DevOps checklist.

### ADR-021 Append-only ledger
- **Decision:** `ledger_entries` insert-only (DB role lacks UPDATE/DELETE); corrections via reversal entries; `ledger_balances` updated in the same transaction; nightly reconciliation job compares sums and alerts on drift.

### ADR-022 Single brand
- **Decision:** App and store name "Supply Biz"; "SupplyMate" from mockups is not used.

### ADR-023 15-day delivery baseline — Accepted, 2026-10-29
- **Authority:** Explicit user instruction to revise documentation/planning only. Supersedes ADR-011, ADR-017 infrastructure constraints, ADR-018 and ADR-019. Existing business invariants and other accepted decisions remain in force.
- **Decision:** English only using existing ARB/intl tooling; native Node processes and PostgreSQL/PostGIS; uploaded files on a persistent local server filesystem; PostgreSQL-backed OTP/rate limits, scheduled jobs and transactional outbox. Remove Hindi support, Redis/BullMQ, Docker/container tooling, cloud image buckets and golden-image generation/refresh requirements from the delivery baseline.
- **Testing:** lightweight build/typecheck, lint/analyze and smoke after every task; focused critical-logic checks where changed; comprehensive integration, regression and end-to-end suites at every module completion and again for the release candidate. No screenshot baseline refresh tooling or visual snapshot gate.
- **Delivery:** prioritize complete UI → API → database → UI flows. ROADMAP defines module gates, staffing assumptions and the 15-day schedule; SCOPE records the reductions subsequently approved under ADR-024. The deadline does not authorize additional business-feature removals.
- **Implementation gap:** existing source, lockfiles, environment examples, generated contracts and scripts are deliberately unchanged in this documentation-only revision. T-180–T-184 own reconciliation; old implementation behavior is not the new specification. Do not hand-edit generated clients.
- **Tradeoffs:** one persistent application host is a failure domain. Back up files and DB consistently, test restore, enforce disk quotas and alert on capacity. Horizontal app replicas require shared-file design and are outside this initial topology.

### ADR-024 Approved SR-01–SR-06 — Accepted, 2026-10-29
- **Authority:** User: “All additional reductions are approved do further changes in documents”. Apply all six proposals from SCOPE §9. This request remains documentation/planning only.
- **Decision:** Defer extended finance, recognition, BBPS, referrals, coupons, undefined saved payment methods, automated SaaS billing/invoices, automated KYC provider checks, reviews/moderation, banner marketing and bulk broadcasts. Simplify location to forms/GPS coordinates with server coverage validation, reports to tables/CSV and diagnostics/infrastructure to the SR-06 baseline.
- **Preserve:** Authentication, TOTP/RBAC/tenant isolation, masking/encryption, manual KYC with audited decisions, admin-assigned plans and server entitlements, order/subscription/delivery/POS/Khata flows including personal entries and payment claims, operational notifications, privacy, core admin, financial integrity, module tests and DB/file restore.
- **Precedence:** For this delivery, supersedes ADR-014's mandatory provider automation, ADR-010's advanced telemetry/Remote Config/App Check portions and ADR-020's proposed pinning additions; ADR-023 remains accepted. Original provider designs remain future reference, not launch prerequisites. Q-23 is resolved to CSV-only; Q-32 provider choice and automated Q-08 are deferred, not unresolved blockers for manual flows.
- **Consequences:** TASKS explicitly labels deferred work; DELIVERY_SCOPE maps FR/US/screens/tests; ROADMAP removes future integrations from gates and schedules manual plan assignment before discovery. Deferred features have no active routes, navigation, credentials, dependencies or test gates. No fake provider verification, payments, invoices or revenue.
- **Open decisions:** Active plan/expiry/visibility, legal/retention, hosting, OTP delivery and core business-rule questions remain open where not already approved. This approval is not permission to invent their values, deploy production or submit stores.

### ADR-025 Android-only execution until Android release — Accepted, 2026-10-29
- **Authority:** User: “run app on Android only now for testing iOS we will do it later after Android is released”. This steers the documentation revision; no application code is changed.
- **Decision:** All current mobile builds, runs, smoke/native/device/accessibility/E2E tests, signing, CI distribution and release preparation target Android only. iOS testing begins **after actual Android production release T-179**, not merely after Day 15 or an internal demo.
- **Preserve:** Shared Flutter behavior and iOS source/configuration/platform security design. Do not delete iOS files or claim iOS checks passed. No Xcode/CocoaPods/Apple account/signing secrets/macOS runner requirement blocks Android delivery.
- **Follow-up:** T-185 is explicitly deferred until Android release. Then validate iOS toolchain/signing, simulator/device builds, OTP autofill, encrypted storage/logout, APNs, Universal Links, UPI fallback, snapshot privacy, VoiceOver/E2E and iOS store disclosures, fixing actual platform defects before iOS release.
- **Precedence:** Supersedes earlier cross-platform verification/release scheduling portions of ADR-001/ADR-023 and project docs, not the choice of Flutter or eventual iOS support. Android security, accessibility, financial and restore/module gates remain mandatory.
