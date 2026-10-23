# TEST STRATEGY

| Field | Value |
|---|---|
| Status | Draft v0.1 |
| Owner | QA Engineer |
| Last updated | 2026-10-19 |
| Related | [TEST_CASES](TEST_CASES.md), [SRS](../02-requirements/SRS.md), [GIT_CICD](../06-development/GIT_CICD.md) |

## 1. Objectives
Verify every FR/NFR and acceptance criterion, protect financial correctness (ledger, subscriptions), ensure security/privacy, and confirm usability on low-end devices in EN and HI.

## 2. Test Pyramid & Tools
| Level | Scope | Tools | Owner | Gate |
|---|---|---|---|---|
| Unit (mobile) | Controllers, repositories, mappers, formatters, validators, outbox | flutter_test, mocktail | Dev/agent | PR |
| Widget & golden | Screens & `Sb*` components, all states, EN/HI, text scale | flutter_test, alchemist (goldens) | Dev/agent | PR |
| Unit (API) | Services, business rules (RULE-xx), state machines, generation eligibility | Jest | Dev/agent | PR |
| Integration/e2e (API) | HTTP → DB with real Postgres/Redis; authZ/IDOR; idempotency | Jest + Supertest + Testcontainers | Dev/agent | PR |
| Contract | OpenAPI conformance & client compatibility | OpenAPI diff, Schemathesis (nightly fuzz) | CI | PR/nightly |
| Mobile E2E | Critical journeys on real/emulated devices incl. native dialogs | Patrol (+ Firebase Test Lab) | QA | Nightly/RC |
| Admin E2E | Login/TOTP, KYC review, suspend, CMS | Playwright | QA | PR (mocked) / nightly (staging) |
| Performance | App start, frames, memory; API load | Flutter DevTools/`flutter drive --profile`, Firebase Perf; k6 | QA/Dev | M6, RC |
| Security | SAST, DAST, mobile static analysis, pen test | CodeQL, Semgrep, ZAP, MobSF, external | Security | PR/nightly/M6 |
| Accessibility | Automated guidelines + manual screen readers | `meetsGuideline` (androidTapTargetGuideline, iOSTapTargetGuideline, textContrastGuideline, labeledTapTargetGuideline), TalkBack, VoiceOver | QA | PR/RC |
| Exploratory & UAT | Real vendors/customers in launch city | Beta builds | PM/QA | M6 |

## 3. Coverage Targets (NFR-018)
- ≥ 80% lines for API services & mobile domain/controllers; ≥ 60% overall.
- 100% of RULE-xx have unit tests; 100% of endpoints have authZ + IDOR e2e tests.
- 100% of P0 user stories have at least one automated E2E or e2e-API test.

## 4. Critical Areas (risk-based)
| Area | Why | Extra testing |
|---|---|---|
| Subscription generation (FR-074) | Financial & trust (R-07) | Property-based tests over random calendars (weekdays × pauses × skips × holidays × start/end); clock-injected; idempotency re-runs; DST-free IST boundary tests at 21:59/22:00/00:00 |
| Ledger (FR-110–FR-116) | Money correctness | Invariant tests: Σentries = balance; reversal symmetry; concurrency (parallel payments) |
| Offline outbox (NFR-007) | Data loss/duplication | Airplane-mode E2E; app kill during sync; duplicate replay; conflict 409 rollback |
| Auth/OTP | Abuse & account takeover | Rate limit, reuse detection, enumeration |
| KYC/PII | Compliance | Masking, encryption at rest, access logs, log redaction tests |
| Plan gating | Revenue | Every gated endpoint tested per plan tier |

## 5. Regression
- Automated suite runs nightly on `main` and on each release candidate.
- Manual regression checklist for RC: journeys J-01–J-08 (USER_FLOWS §4) on Android ref low-end + iPhone SE + one latest device, EN and HI.
- Bugs fixed get a regression test referencing the bug ID.

## 6. Accessibility Testing
- Automated guideline checks in widget tests for every screen.
- Manual per release: TalkBack (Android), VoiceOver (iOS) for J-01, J-02, J-03, J-06; text scale 200%; colour-blind simulation for status badges.

## 7. Device & OS Matrix
| Platform | Device class | OS | Frequency |
|---|---|---|---|
| Android | Low-end 3 GB (reference) | Android 10/11 | Every RC (manual + perf) |
| Android | Mid (Samsung A/Redmi Note) | 12–14 | Every RC |
| Android | Pixel latest | 15/16 | Every RC |
| Android | Emulator | API 24 (min) | Nightly smoke |
| Android | Firebase Test Lab matrix (5–8 popular Indian devices) | mixed | Nightly E2E |
| iOS | iPhone SE (2nd/3rd gen) small screen | latest-1 | Every RC |
| iOS | iPhone 13–16 | latest | Every RC |
| iOS | Simulator | min supported (13) or lowest available | Nightly smoke |
Network conditions: 3G profile (400 kbps, 300 ms RTT), offline, flaky (packet loss) via device network link conditioner/emulator settings.

## 8. Test Data & Environments
| Env | Data | Integrations |
|---|---|---|
| Local/CI | Factories (no real PII); seeded categories/plans | Fakes (ConsoleOtp, FakeKyc, FakeBilling, LogPush, FakeGeo) |
| Staging | Synthetic vendors/customers; test OTP allow-list | Provider sandboxes |
| Prod | No testing except post-deploy smoke with dedicated internal accounts | Real |
Clock is injectable in API & mobile for date/cutoff tests.

## 9. Entry/Exit Criteria
| Phase | Entry | Exit |
|---|---|---|
| Milestone demo | Tasks DONE | All TCs of the milestone pass; no open P0/P1 bugs |
| RC | Code freeze | Regression pass; crash-free ≥ 99.5% (beta); perf budgets met; a11y checks pass |
| Launch | RC approved | Pen-test highs fixed; store approvals; monitoring/alerts live |

## 10. Defect Severity
| Sev | Definition | Example |
|---|---|---|
| P0 | Data loss, money error, security breach, crash in core flow | Duplicate subscription orders; ledger mismatch |
| P1 | Core flow blocked with no workaround | Cannot accept orders |
| P2 | Degraded with workaround | Filter wrong count |
| P3 | Cosmetic | Alignment in HI |
