# ROADMAP — 15-day integrated delivery plan

Updated 2026-10-29. Authority: ADR-023/ADR-024/ADR-025; scope decisions: SCOPE §9. Task acceptance/status: TASKS. Day numbers are consecutive working days from an agreed kickoff, not promised public-release dates.

## 1. Outcome and capacity
Day 15 target: a functional integrated Android app, NestJS API, PostgreSQL database and Next.js admin handoff on an agreed test/staging host, with real persisted UI → API → DB → UI business flows and comprehensive module/release evidence. Preserve iOS source/configuration; all iOS builds/runs/testing/signing/distribution work is deferred until after Android production release (ADR-025). Store review, production rollout, contracts and regulatory approvals have external lead times and cannot be guaranteed inside 15 days. Do not label a fake-provider demo production-ready.

Planning assumption: three experienced implementers (API/data, Flutter, admin/runtime) plus one QA/release owner, all available daily; foundations already present are reusable after verification. This offers 45 developer-days, with 6–8 reserved for integration/defects. Estimate remaining core scope at 30–38 developer-days after approved simplifications; uncertainty is high until Day 1 repository/runtime triage. These are planning estimates, not measured velocity. Full original extended scope plus unresolved integrations is not credibly committed in the same capacity. SR-01–SR-06 are approved by the user on 2026-10-29 and now define the active/simplified release scope. Deferred tasks stay outside G0–G6. Remaining delivery risk is capacity, runtime defects and unresolved active decisions; do not claim full historical scope or guarantee external release dates.

## 2. Daily milestones and safe parallel lanes
Each row ends with lightweight integrated smoke. QA prepares module scenarios during implementation and executes comprehensive integration/regression/E2E **when that module completes**. Daily demos do not substitute for module gates.

| Day | API/data lane | Flutter lane | Admin/runtime lane | Milestone / gate |
|---|---|---|---|---|
| 1 | Audit T-004–T-007; T-180 OTP/shared rate-state migration | Audit T-008–T-013; T-183 English/UI cleanup | T-002/T-182 native DB/files; audit T-001/T-003; start T-184 CI | Boot API/mobile against native DB; inspect admin scaffold; owners/contracts and active decision register fixed |
| 2 | Complete T-014/T-015, durable dispatcher T-181 | T-009–T-013 completion, T-016 auth | T-150 admin auth start; finish T-184; T-017 minimum config/force-update contract | G0 auth/baseline: login, roles, refresh/logout, concurrent abuse protection and isolation |
| 3 | T-020/T-021/T-022 media/vendor/KYC | T-024 onboarding, upload and resume | T-150/T-152 audit, T-151 review start | Upload → persisted masked document → review; no discoverable unverified vendor |
| 4 | T-023/T-026/T-028/T-084 plus T-103 manual-plan service completion | T-025/T-027/T-029 catalog/customers | T-151/T-153 KYC/categories; T-156 audited plan assignment; paired restore preparation | G1 vendor/admin core: manual KYC, assigned plan/limits, products/stock/customers, authorized media |
| 5 | After G1 manual-plan pass: T-040/T-041/T-042 discovery/addresses; T-070 ledger foundation | T-047/T-043/T-044 address/discovery | T-154/T-155 management/dashboard start | Customer discovers only eligible vendor; prices/coverage server enforced |
| 6 | T-045 orders; T-049/T-071 atomic stock/ledger delivery | T-046 checkout, T-048 vendor orders | T-032 notification API; admin support read views | Place → accept → deliver → order status and balances reloaded from DB |
| 7 | T-051 cancel/reorder; T-052 events; T-053 linking | T-050 offline delivery; T-051/T-053 customer views; T-033 push/inbox | Finish T-154/T-155; order authorization regression fixes | G2 ordering/delivery: replay, concurrency, stock and ledger integrity; offline replay |
| 8 | T-072/T-075 subscriptions; T-073 schedule/generation | T-076/T-078 subscription creation/approval | Worker retry/catch-up operational drill | Create subscription → generated dated order visible to both roles |
| 9 | T-074 holidays; T-079 POS; T-082 Khata claims/personal entries | T-077/T-080/T-081/T-083 holiday/POS/Khata/UPI | Claims, reconciliation and audit verification | G3 daily operations: cutoffs, skip/pause, restart catch-up, POS, confirmed credit/reversal |
| 10 | T-030 metrics; T-100 reports; T-103 expiry-reminder regression | T-031/T-102/T-105 dashboard/reports/plan states | T-101 CSV-only export; T-156 admin assignment regression | Sales/deliveries/payments reconcile to reports; plan locks server enforced |
| 11 | T-106/T-107 settings/help; finish T-017 prerequisite; T-019 privacy deletion | T-106/T-107/T-126 profile/settings | T-158/T-161/T-162 CMS/config/privacy/RBAC | G4 business/admin: settings, consent/deletion, entitlement behavior and admin permissions |
| 12 | Active-scope gap fixes and service-directory API checks | T-122 service directory; T-185 iOS work stays deferred | T-018 minimal crash diagnostics; T-017 config regression; scope-boundary navigation/config checks | G5 all active/simplified scope integrated; deferred routes/actions absent; no placeholders |
| 13 | Module-gate defects and cross-module regression | T-170/T-172 representative performance/accessibility fixes | T-171/T-173 security/load; T-175 restore; T-176 alerts | Release candidate; DB + files restore and security evidence recorded |
| 14 | Complete regression fixes | Full customer/vendor journeys and offline/restart checks | T-177 release package/privacy disclosures; T-178 UAT | G6 comprehensive RC suite; manual UAT; no P0/P1, high/critical security issues |
| 15 | Fix/retest final blockers, verify migration/rollback notes | Reproducible Android handoff/demo | Final backup/restore evidence, runbook, known gaps and release approval packet | Signed-off integrated application handoff; production T-179 remains approval/external-gated |

## 3. Module completion gates
| Gate | Required integrated journeys and comprehensive checks | Deadline |
|---|---|---|
| G0 Baseline/auth | T-001–T-016 plus T-180–T-184; native startup, OTP send/verify/concurrency/expiry, refresh reuse, roles, secure logout/storage; build/client compatibility | Day 2 |
| G1 Vendor/admin core | T-020–T-029, T-084, T-150–T-153, T-103 manual-assignment slice, T-156; upload/read isolation, KYC approval, discovery prerequisite data, stock/customer limits; prior G0 regression | Day 4 |
| G2 Ordering/delivery | T-032/T-033, T-040–T-053, T-070/T-071; checkout quote → persisted order → accept → deliver → ledger/stock/UI; IDOR, replay, cancellation and offline recovery; G0/G1 regression | Day 7 |
| G3 Daily operations | T-072–T-083; next-date generation/cutoffs/holidays/restart, offline POS, balances, payment claim approval/reversal; G2 regression | Day 9 |
| G4 Business/admin | T-019/T-030/T-031/T-100–T-103/T-105–T-107/T-126/T-154–T-156/T-158/T-161/T-162; table/CSV reports reconcile, manual plans and limits, privacy/deletion and RBAC; billing T-104 excluded | Day 11 |
| G5 Agreed full application | T-017/T-018/T-122 and active-scope completeness; TC-509–TC-512 verify manual KYC/plans, scope-boundary navigation and CSV parity; no deferred provider integration required | Day 12 |
| G6 RC/handoff | T-170–T-173/T-175–T-178; cross-module E2E and regression, security/financial invariants, accessibility, representative load, DB/file restore, UAT, documented release blockers | Day 15 |

T-174 is explicitly removed. T-179 is production/store rollout after release approval; it is not silently marked delivered. Existing task criteria and referenced TC IDs remain required for retained features. SR-deferred tasks do not block gates; active functionality or a required OTP/hosting/legal decision can still block them. T-185 is after T-179 and is excluded from this Android delivery.

## 4. Critical path and concurrency rules
Critical path: native DB + secure auth → verified vendor/catalog/customer/entitlements → discovery/checkout → transactional delivery/ledger → subscription generation/POS/claims → reports/privacy/admin completion → active application completeness → RC/UAT.

One API/data owner serializes schema migrations, financial-state changes, OpenAPI and generated clients. Agree DTOs/error behavior before Flutter/admin work; mocks allow temporary parallel development, never gate completion. Admin auth/audit and media/KYC can proceed beside Flutter auth after API contracts stabilize. Address/discovery UI can proceed beside ledger foundations. Notification fan-out runs through the durable outbox; financial debits/stock changes occur atomically, not eventually. Assign explicit file ownership, merge daily, and smoke shared flows before dependent merges.

If a gate slips, use the reserved defect capacity and reforecast daily. Reduce work-in-progress before adding features. Do not compensate by removing authZ, integrity, module tests, backup evidence or business functionality without approval.

## 5. Remaining decisions and external prerequisites
Scope reductions SR-01–SR-06 are approved; do not ask again. Q-23 is resolved to CSV-only. Provider choices for maps Q-32, automated KYC Q-08, billing Q-03, BBPS Q-07, coupons Q-06, referrals Q-14, auto-import Q-21, saved payment methods Q-22, automated plan invoices/tax Q-24, reviews Q-26 and speech/OCR Q-28 are POST-DELIVERY and do not block G0–G6.

By Day 1 assign owners/deadlines for Q-02 host/backup targets, Q-09 SMS/DLT and retained WhatsApp delivery, Q-04/Q-18 plan/trial/expiry/visibility behavior, Q-13/Q-15/Q-16/Q-19 core order/subscription rules, Q-20 legal/retention, Q-25 admin RBAC, Q-30 support and Q-33 domains. Review approved assumptions before asking; do not invent unresolved policies. Lack of a real active provider still blocks production readiness; labeled local test simulation alone is not a live login pass.

By Day 3 prove retained OTP/push configuration; by Day 4 prove manual KYC/plan administration, or record the affected gate at risk. Hosting/restore/signing/legal decisions must support the Day 10 release packet; Android Play requirements only. Production release T-179 requires separate approval and store/distribution readiness. T-185 begins only after Android production release: iOS toolchain/signing/builds, simulator/device tests, storage/APNs/deep-link/UPI/VoiceOver validation and store package. No iOS secrets, Apple account, build, test or TestFlight requirement blocks the Android handoff/release. Preserve iOS source/configuration now; report all unrun iOS checks as deferred.

## 6. Deferred task inventory
T-104/T-108/T-120/T-121/T-123–T-125/T-127–T-130/T-157/T-159/T-160 are approved SR backlog. T-174 is removed by ADR-023. T-185 is the after-Android-release iOS phase. These IDs are retained for traceability, excluded from current scheduling and never counted as completed. Further scope changes require a new decision; these approvals do not waive authentication, authorization, money/data integrity, privacy, module tests or backup/restore.
