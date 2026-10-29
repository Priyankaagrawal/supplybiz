# TEST STRATEGY — task checks and module gates

Updated 2026-10-29. Accepted cadence: ADR-023. Coverage inventory: TEST_CASES; module membership/deadlines: ROADMAP G0–G6. This revision describes planned checks; existing CI and placeholder scripts must be reconciled by T-184/T-150.

## 1. After every task
Run the affected layer's lightweight build or compile/typecheck, lint/analyze/format and a runnable smoke of the changed path. Run focused tests for changed critical business rules and security failures. Smoke must verify real responses and persisted state where relevant; a mocked widget alone cannot prove UI/API/DB wiring. Report exact commands/results and unavailable checks. No comprehensive integration/regression/E2E suite or percentage coverage gate after each task.

| Layer | Lightweight checks | Smoke |
|---|---|---|
| API | `pnpm --filter @supplybiz/api build`, `typecheck`, real `lint` once T-184 replaces placeholder; focused Jest checks | Readiness plus affected request against native PostgreSQL; inspect/reload resulting state |
| Flutter | Targeted `fvm dart analyze`, format check, existing targeted widget/controller checks; one debug Android build for affected app changes | Run affected route, submit/reload via real API; include loading/error behavior |
| Admin | Real lint/typecheck/build implemented in T-150; placeholder scripts never count | Login and affected page action via API to DB and refreshed UI |
| Documentation only | Diff/whitespace, Markdown links/references and requirement/dependency consistency | No application tests needed |

Task READY_FOR_VERIFY requires runnable behavior and check evidence. DONE still requires manual verification PASS per AGENTS/PROMPTS. Task completion is separate from module completion.

## 2. After every completed module
Run comprehensive integration, regression and end-to-end tests once the integrated module is ready, and rerun relevant suites after module-gate defect fixes. Gate progression requires prerequisite modules passed; prepare tests during implementation, execute the comprehensive suite at module completion. No nightly/per-PR full-suite mandate during this delivery window.

| Level | Coverage / tools | Gate |
|---|---|---|
| API integration | Jest/Supertest → dedicated native PostgreSQL/PostGIS test DB; migrations/seeds, authZ/IDOR for every protected endpoint, errors and transactions | Each module |
| Mobile E2E | Existing Patrol tooling or documented repeatable device journey; real API/database, both roles, reload/restart; fake provider limitations explicit | Each module |
| Admin E2E | Playwright or documented repeatable browser journey, real API/database; TOTP, RBAC, KYC and audit | Relevant modules |
| Regression | Completed-module scenarios plus affected earlier modules; release candidate runs all retained scope | Each module + G6 |
| Contract/schema | Generated-client compatibility; source/contract drift and clean migration apply | Each relevant module; targeted checks after contract changes |
| Accessibility | Widget semantics/target assertions, TalkBack, 200% text scale and narrow-screen layouts | Each UI module; G6 consolidated review |
| Security/operations | Tenant isolation, unsafe input, secret/log redaction, dependency audit, file access, backup/restore, representative load | Relevant module + G6 |

Screenshot baseline generation, refresh and related dependencies are removed. Use behavioral/widget assertions and manual visual review. Prefer existing tools; do not add a test framework solely to meet a gate.

## 3. Required risk coverage
- Ledger: integer paise, sum(entries)=balance, immutable entries, reversals, concurrent payment/claim confirmation, delivered-order/stock/debit atomicity and duplicate replay.
- Orders/POS: server-calculated totals and prices, vendor/customer isolation, stock/capacity, cancellation and exact-once financial effects.
- Subscriptions: deterministic IST clock, weekday/pause/skip/holiday boundaries, 21:00 cutoff and 22:00 generation, uniqueness, restart/catch-up, concurrent worker claims and bounded retries.
- Auth: mobile/IP/device shared rate limits, wrong attempts, expiry, concurrent single-use OTP, refresh rotation/reuse, logout/revocation, consent, blocked accounts and admin TOTP/CSRF/RBAC.
- Offline: airplane mode, pending mutation replay, app kill during sync, duplicate replay and 409 conflict recovery; no lost or duplicated money/stock.
- Media/KYC: LOCAL_FILE_STORAGE validation/isolation cases TC-503/508, masking before persistence, no unauthorized private reads, audit and paired DB/file restore.
- Entitlements: server limits and feature gates; no client role/vendor/price trust. Active trial/expiry/visibility rules remain Q-04/Q-18 and must not be invented. Automated billing rules are post-delivery SR-03 and do not block manual-plan gates.
- Privacy/deletion: consent, reference-safe retention/erasure and immutable financial records per approved policy.

Coverage is risk-based: every retained business rule and protected endpoint has its critical positive and negative cases by its module gate; all retained P0 stories have an integrated automated or recorded repeatable end-to-end journey. Track uncovered cases explicitly. Do not replace financial/security cases with a broad line-coverage number. NFR-018 uses this policy.

## 4. Environments and devices
Native PostgreSQL/PostGIS dedicated test databases and separate temporary upload directories use synthetic fixtures only; never real customer PII. Fakes are allowed for isolated tests and labeled development demos. Provider sandboxes/live readiness must be verified for retained provider features before production; a fake pass is not a production pass.

Android is the active runtime/device/E2E platform under the existing 2026-10-29 scope: emulator plus one representative low-end physical device where available, English, small-screen/200% text, offline and flaky/3G network checks. iOS source/configuration stays supported, but all builds/runs/testing/signing/distribution remain explicitly DEFERRED until after Android production release (T-185) and is never reported as passed. Broad device farms and independent external audit scheduling are deferred by approved SR-06; baseline security checks remain mandatory.

## 5. Evidence and exit criteria
Record gate result, task/TC IDs, commands, commit/environment, provider mode, device, observed outcome and outstanding gaps in TASKS §10. All gates begin NOT RUN after this replan. Fix P0 (money/data/security/crash) and P1 (blocked core flow) defects before a module passes. Reproduce fixed defects with meaningful focused regression coverage.

Day 15 handoff requires G0–G6 for the explicitly agreed scope, no open P0/P1 or high/critical security defects, backup/restore evidence and a reproducible end-to-end demo. Approved SR-01–SR-06 deferrals are excluded from G5 and all gate counts, never marked PASS; any additional unapproved omission still leaves its gate incomplete. Production launch additionally requires real provider readiness, privacy/legal content, hosting/security/backup target approval, store/distribution approval where needed and release authorization. No deadline overrides these gates.

## 6. Post-Android-release test phase
All current mobile build/run/native-storage/device/accessibility/E2E checks are Android only. iOS simulator/device builds, signing, OTP autofill, secure storage, APNs, Universal Links, UPI fallback, VoiceOver and iOS E2E are T-185 after documented Android production release T-179 (ADR-025), not an automatic Day 15 job. Keep iOS source/configuration and record checks as DEFERRED, outside Android denominators. Server/admin integration tests remain active regardless of mobile platform.

SR-01–SR-06 are approved under ADR-024. Run TC-509–TC-512 for actual manual KYC/plan workflows and reduced-scope UI/CSV boundaries. Cases labeled POST-DELIVERY describe future scope only and are not expected to execute or pass now.
