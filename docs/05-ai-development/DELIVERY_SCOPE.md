# DELIVERY SCOPE — approved applicability, 2026-10-29

The user approved **all SR-01–SR-06** on 2026-10-29. ADR-024 records the decision; SCOPE §9 records reasons and savings. This index determines which preserved requirements, ACs, screens, tests and modules apply to the 15-day delivery. IDs are preserved for traceability. Approval authorizes documentation changes now, not application implementation or deployment.

## 1. Status semantics
- **ACTIVE:** required by the applicable ROADMAP gate.
- **SIMPLIFIED:** the explicit reduced acceptance criteria replace the previous advanced behavior for this delivery.
- **POST-DELIVERY:** retained backlog, excluded from task selection, active dependencies, module gates, production routes/navigation, permission requests and completion denominators. Not DONE, not passed, no placeholder implementation required.
- **REMOVED:** user-requested removals under ADR-023, not a future commitment.

## 2. Approved mapping
| Decision | POST-DELIVERY | Active/simplified acceptance |
|---|---|---|
| SR-01 | T-120/T-121/T-124/T-125/T-127; FR-260–FR-263/FR-280–FR-283/FR-294; US-260/US-280/US-291; S-C-21–S-C-25/S-C-32; related TC-260 series/TC-280 series/TC-294 | Catalog/text search, cart, subscriptions, vendor/customer Khata and personal lending/borrowing entries FR-252 remain. No Money/insights/grocery-assist navigation or speech/OCR permissions/dependencies. |
| SR-02 | T-123/T-128–T-130; FR-222/FR-271–FR-272/FR-292–FR-293; US-222/US-271/US-292; S-C-23/S-C-24/S-C-30/S-C-31; associated coupon/BBPS/referral/payment-method tests | Service directory lists supply categories; unsupported categories may be labeled unavailable, with no bill/payment action. Direct vendor cash/UPI payment recording and customer claims remain. No coupon CTA or platform fund handling. |
| SR-03 | T-104 and automated provider/billing portions of T-022/T-105/T-156; FR-121/FR-126, provider-specific FR-015/FR-402 ACs | Submission enters manual review; authorized admin approves/rejects with reason, audit and notification. Store `verificationMethod=MANUAL_REVIEW` (or equivalent); provider checks are NOT_RUN, never fabricated. VERIFIED means manually approved KYC for this release. Plan catalog/current tier/validity and server limits/features remain; authorized admin assigns/extends a plan with reason, actor, dates and audit. No checkout/payment-link/receipt-verification/invoice UI; no fake payments or revenue. Q-04 expiry/trial and Q-18 visibility policy still need existing approved rules/decisions. |
| SR-04 | Interactive maps/places/geocoding-provider integration; PDF export; chart polish | Manual address/pincode/coordinate fields plus optional device GPS. Validate coordinates and enforce existing radius AND/OR pincode business rules server-side; no postcode centroid or invented location fallback. Reports preserve accurate summary, daily sales and product-wise data as SQL-derived tables; CSV-only export/share, authorization and paise/IST correctness retained. Q-23 resolved; map-provider Q-32 deferred. |
| SR-05 | T-108/T-157/T-159/T-160; FR-213/FR-407/FR-409/FR-410; US-212/US-404; S-C-35/S-A-11/S-A-14/S-A-15; related review/banner/broadcast tests | No ratings/review counts, Rating sort, Reviews tab, marketing banners or bulk campaigns. Keep Nearby/Popular sort, favorites, category management, CMS/legal, operational inbox/push, customer/vendor admin management, dashboard and audit. Operational incident notices use basic config/support channels, not a broadcast dependency. |
| SR-06 | Product analytics/event funnels, custom performance traces/exporters, attestation, certificate-pinning additions, broad device/load farms, independent external pen-test scheduling, multi-zone/IaC automation | T-017 API-backed config/min-version/flags; T-018 existing basic crash diagnostics; T-170/T-171 representative Android/API measurements; T-172 Android accessibility; T-173 focused security/dependency/threat checks. Preserve HTTPS, TOTP/RBAC, rate limits, tenant isolation, money/idempotency/financial tests, privacy, alerts, encrypted backups and demonstrated DB/files restore. All iOS build/run/testing remains deferred until after Android production release (ADR-025). |

Mixed requirements/stories/screens/tests apply only to the active clauses rewritten in their owning documents. Future descriptions under POST-DELIVERY labels are not instructions to build stubs. Further changes beyond these six approvals still require a new scope decision.

## 3. Dependency and operational consequences
No active task or gate depends on T-104/T-108/T-120/T-121/T-123/T-124/T-125/T-127–T-130/T-157/T-159/T-160. Do not add recognition, BBPS, billing, maps or reviews adapters/packages to active work. Preserve existing generated/client/source files until an authorized implementation task reconciles them. T-182/T-183 remove obsolete active configuration/dependencies/navigation as applicable; shared libraries already used by retained components need no speculative replacement.

Native PostgreSQL/PostGIS, local server files, auth, manual KYC, manual plan administration, transactional business flows and module testing stay on the critical path. Manual plan assignment must be functional before active-plan discovery/order checks pass; seed fixtures alone are not an admin workflow. T-103/T-156 are scheduled with vendor/admin core, not after discovery.

## 4. Completion and evidence
G0–G6 cover the approved active/simplified application. Deferred cases are recorded DEFERRED with SR ID, never PASS, and excluded from required-case counts. No code or runtime gate has passed merely because documentation was updated. Hosting/SMS/legal/core-policy decisions and production deployment authorization remain distinct from the now-complete scope approval.
