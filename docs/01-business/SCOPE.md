# SCOPE — Scope, Assumptions, Constraints, Dependencies, Risks, Open Questions

| Field | Value |
|---|---|
| Status | Draft v0.1 |
| Owner | Product Manager + Solution Architect |
| Last updated | 2026-10-29 |
| Related | [PRD](PRD.md), [DECISIONS](../05-ai-development/DECISIONS.md) |

> This file is the **single consolidated register** for assumptions (A-xx), constraints (C-xx), dependencies (D-xx), risks (R-xx) and open questions (Q-xx). Other documents reference these IDs instead of repeating them.

## 1. Active 15-day delivery scope
| Area | Included |
|---|---|
| Platforms | One Flutter app; Android runtime verification now; iOS source/configuration preserved with all builds/runs/testing deferred until after Android production release; Next.js admin and NestJS/PostgreSQL API |
| Common | OTP login, role switching, English/INR/IST, consent/deletion/privacy, transactional push and inbox, basic config/force update and crash diagnostics |
| Vendor | Business/KYC submission with audited manual admin review, bank/UPI details, radius/pincode coverage via address/coordinate forms, products/stock, customers, orders, deliveries, subscriptions/holidays, offline delivery/payment/POS, immutable Khata, SQL/table reports and CSV export, admin-assigned plans with server entitlements/limits, settings/help/legal |
| Customer | Home with categories and deliveries, manual address/location with optional GPS coordinates, vendor/product discovery and favorites, cart/checkout, order history/status/cancel/reorder, subscriptions/statements, vendor and personal Khata, UPI intent/payment claims, service directory, profile/addresses/settings/help |
| Admin | Password + TOTP, RBAC/session, dashboard, manual KYC review with private document audit, vendor/customer management, categories, plans and audited manual entitlement assignment/extension, CMS/legal/basic config, audit viewer, data-subject requests and CSV reports |

Approved reductions SR-01–SR-06 below define post-delivery scope and replace the prior full-feature v1.0 commitment. [DELIVERY_SCOPE](../05-ai-development/DELIVERY_SCOPE.md) is the applicability index; preserved future requirements do not block the 15-day handoff.

## 2. Outside this delivery
| Item | Note |
|---|---|
| Platform collection/escrow of customer payments, commission, payouts | ADR-008 |
| "Settle to Bank" as a real money movement | Blocked by Q-05 |
| Live GPS tracking, delivery partner assignment & delivery-staff app | F-D3 |
| Staff / delivery boys management | F-D1 |
| Support tickets & chat | F-D2 |
| Tablet-optimized layouts, web customer app, desktop vendor app | Phones only; tablets run phone layout |
| Category-specific workflows (tiffin menus, laundry pickup/return, newspaper billing) | Generic product/order model only; Q-12 |
| Countries other than India, currencies other than INR | C-01 |

## 3. Assumptions
| ID | Assumption | Confirm via |
|---|---|---|
| A-01 | India only: INR, +91 mobiles, IST (Asia/Kolkata); timestamps stored in UTC | — |
| A-02 | One app, role selection after login; one mobile number may hold both Customer and Vendor roles | Stakeholder answer |
| A-03 | Customer→vendor payments are off-platform (cash/UPI/bank/wallet); app records only. Future exceptions: automated vendor SaaS fees and bill payments are deferred by SR-02/SR-03 | Stakeholder answer |
| A-04 | Vendors are **not discoverable** by customers until KYC = VERIFIED and an active plan exists; they may set up catalog/customers before | Q-18 |
| A-05 | Subscription orders for date D are generated at **22:00 IST on D-1**; customer pause/skip/modify cutoff **21:00 IST on D-1** | Q-15 |
| A-06 | Subscription billing is **postpaid** via Khata: each delivered order debits the ledger; "Monthly amount" is an estimate | Q-19 |
| A-07 | Order/subscription quantity is an integer count of product packs (e.g., 2 × 1 L) | Q-11 |
| A-08 | Vendor (owner) performs delivery status updates himself (no staff accounts) | F-D1 |
| A-09 | Cart contains items from a single vendor only | — |
| A-10 | Aadhaar: only masked images and last 4 digits are stored; full number never persisted | ADR-014 |
| A-11 | Customer "Settle Payment" opens a UPI intent to the vendor's UPI ID and creates a **payment claim** the vendor confirms | Q-05 |
| A-12 | Firebase FCM and basic crash reporting remain; product analytics, performance telemetry and Remote Config campaigns are deferred by SR-06; basic API config stays | ADR-010 |
| A-13 | Minimum OS: Android 7.0 (API 24), iOS 13 — re-validate against pinned Flutter version | — |
| A-14 | Source repository hosted on GitHub; CI on GitHub Actions | Q-31 |
| A-15 | A vendor has exactly one primary business category | Q-17 |
| A-16 | Delivery charge, minimum order value and time slots are configured per vendor in Delivery Settings | Q-13 |
| A-17 | Customer bottom navigation: Home · Orders · Khata · Services · Profile; Money/insights entries absent in this delivery (SR-01) | Q-10 |
| A-18 | A subscription has one product line (as in mockups) | — |

## 4. Constraints
| ID | Constraint |
|---|---|
| C-01 | India regulatory: DPDP Act 2023 & Rules; UIDAI Aadhaar regulations; TRAI DLT registration for SMS; RBI/NPCI rules for UPI and BBPS |
| C-02 | App-store policies: Apple IAP / Google Play Billing for digital goods (affects vendor SaaS plans, R-02); account deletion requirement; privacy labels / Data safety form |
| C-03 | Tech stack fixed: Flutter, NestJS, PostgreSQL, Next.js admin |
| C-04 | Must work on low-end Android devices (2–3 GB RAM) and 3G-class networks |
| C-05 | English only; retain accessible layouts, INR/IST formatters and externalized strings |
| C-06 | Data residency: personal data stored in India region (cloud provider TBD, Q-02) |

## 5. Dependencies (external)
| ID | Dependency | Used by | Provider |
|---|---|---|---|
| D-01 | SMS OTP gateway (DLT-registered) | FR-002 | TBD (Q-09) |
| D-02 | WhatsApp Business API (OTP template) | FR-002 | TBD (Q-09) |
| D-03 | KYC APIs: PAN verification, bank account verification (penny-drop), Aadhaar (DigiLocker / offline e-KYC) | FR-015 | POST-DELIVERY SR-03; manual review is active |
| D-04 | Payment gateway or store billing for vendor SaaS plans | FR-121 | POST-DELIVERY SR-03; audited manual assignments are active |
| D-05 | BBPS bill-payment partner | FR-271–FR-272 | POST-DELIVERY SR-02 |
| D-06 | Firebase FCM Android/basic Crashlytics now; APNs after Android release; analytics/performance/campaigns deferred SR-06 | Many | Google |
| D-07 | Maps/geocoding & places autocomplete | FR-200, FR-291, FR-018 | POST-DELIVERY SR-04; no maps/geocoding API needed |
| D-08 | Persistent local file volume + encryption and backups | Uploads | Application host TBD (Q-02); ADR-023 |
| D-09 | Speech-to-text (English) and OCR (Latin) | FR-280–FR-281 | POST-DELIVERY SR-01 |
| D-10 | Google Play Console organization account now; Apple account after Android release (T-185) | Android release; iOS future | Owner TBD; Apple setup does not block Android |
| D-11 | Domain + HTTPS hosting for deep links (assetlinks / AASA) and legal pages | FR-104 | TBD (Q-33) |

## 6. Internal Document Dependencies
See [README](../../README.md#document-dependencies).

## 7. Risks
| ID | Risk | Impact | Likelihood | Mitigation |
|---|---|---|---|---|
| R-01 | v1.0 scope is very large (all customer features + admin) | Delayed launch | High | Approved SR-01–SR-06; active/simplified scope only in G0–G6; daily dependency-aware demos |
| R-02 | Apple/Google may require in-app purchase for vendor SaaS plans | Rejection; 15–30% fee | High | Decide ADR-015 early (Q-03); design billing behind `BillingProvider` interface |
| R-03 | Bill payments require a licensed BBPS partner and platform-handled funds | Feature blocked | High | Partner selection (Q-07); feature flag `bill_payments` |
| R-04 | Mishandling Aadhaar/KYC data | Legal penalties | Medium | Masking, encryption, restricted access, retention policy (AUTH_SECURITY) |
| R-05 | SMS DLT template registration delay | Login blocked | Medium | Start registration in M0; WhatsApp OTP fallback |
| R-06 | Off-platform payments cause disputes | Trust | Medium | Payment claims with vendor confirmation; immutable ledger; audit trail |
| R-07 | Subscription generation bugs (holidays/pauses/skips) | Financial errors | Medium | Idempotent job, unique constraints, exhaustive tests (TC-070 series) |
| R-08 | Low-end devices / poor networks | Poor UX | High | Performance budgets, offline outbox, image compression |
| R-09 | Voice/OCR accuracy for English & handwriting | Low feature value | Medium | Editable detected list; feature flag |
| R-10 | Low vendor digital literacy | Adoption | Medium | Simple English UX, simple flows, onboarding help |
| R-11 | UPI intent behaves differently on iOS (no generic chooser) | Settle flow friction | Medium | Show UPI ID + QR + copy; app-specific schemes where allowed |
| R-12 | Dual-role users confuse contexts | Data errors | Low | Clear role indicator, separate shells, role-scoped API |
| R-13 | Cloud provider & launch timeline undecided | Planning | Medium | Native processes, PostgreSQL/PostGIS, persistent local file volume; see ROADMAP |

## 8. Open Questions
| ID | Question | Blocks | Owner |
|---|---|---|---|
| Q-01 | Launch city/region and public launch date? Internal 15-day delivery window is set by ROADMAP; store/public launch remains external. | Roadmap, seed data | PO |
| Q-02 | Cloud provider (AWS ap-south-1 / GCP asia-south1 / other)? | Hosting, ADR-023 | PO + Architect |
| Q-03 | Vendor SaaS plan purchase channel: Apple IAP + Google Play Billing, or web checkout (Razorpay) outside app? | POST-DELIVERY SR-03; billing-channel decision deferred | PO + Legal |
| Q-04 | Free trial? Grace period after expiry? Behaviour on expiry/downgrade? Final feature-to-plan mapping? | FR-123–FR-125 | PO |
| Q-05 | Meaning of "Settle to Bank", "Wallet/Settlement" (Premium) and "take-rate" under direct payments? | FR-114, plan gating | PO |
| Q-06 | Coupons: who creates and funds them (vendor or platform)? Rules? | POST-DELIVERY SR-02; coupon policy deferred | PO |
| Q-07 | Bill payments: BBPS partner, payment method, commission, licensing? | POST-DELIVERY SR-02; BBPS deferred | PO + Legal |
| Q-08 | KYC API provider; Aadhaar method (DigiLocker vs offline XML vs image only)? | Automated-provider choice POST-DELIVERY SR-03; audited manual KYC approved | PO + Legal |
| Q-09 | SMS and WhatsApp OTP providers; DLT entity & sender ID? | FR-002 | PO |
| Q-10 | Customer bottom navigation (mockup vs document conflict) — accept A-17? | UX | PO + UX |
| Q-11 | Support loose/fractional quantities (e.g., 1.5 L)? | Data model | PO |
| Q-12 | Category-specific flows for tiffin, laundry, flowers, newspaper, home services? | Customer services | PO |
| Q-13 | Who sets delivery charges / minimum order — vendor (A-16) or platform? | FR-132 | PO |
| Q-14 | Invite & Earn: reward type, amount, eligibility, fraud rules? | POST-DELIVERY SR-02; rewards deferred | PO |
| Q-15 | Subscription generation time and customer change cutoff (A-05)? | FR-074, FR-077 | PO |
| Q-16 | Can customers cancel after vendor ACCEPTED? Any cancellation fee? | FR-242 | PO |
| Q-17 | Can a vendor operate multiple categories (A-15)? | FR-010 | PO |
| Q-18 | Visibility before KYC verification (A-04)? | FR-017 | PO |
| Q-19 | Subscription billing prepaid vs postpaid (A-06)? | FR-233 | PO |
| Q-20 | Data retention periods (KYC docs, ledger, deleted accounts)? | AUTH_SECURITY | Legal |
| Q-21 | Money tracker: auto-import Supply Biz payments as expenses? | POST-DELIVERY SR-01; auto-import deferred | PO |
| Q-22 | "Payment Methods" screen meaning under direct payments (saved UPI IDs? preferred method?) | POST-DELIVERY SR-02; saved payment-method management deferred | PO |
| Q-23 | Report download formats (PDF, CSV, both)? | RESOLVED (SR-04): CSV only; PDF deferred | PO |
| Q-24 | GST: plan prices inclusive/exclusive; GST invoices for plans; vendor GST invoices to customers? | POST-DELIVERY SR-03: automated plan billing/invoices deferred; no fabricated invoices | Finance |
| Q-25 | Admin roles & permissions list; admin panel domain? | FR-400 | PO |
| Q-26 | Review moderation policy (auto-publish vs pre-moderation)? | POST-DELIVERY SR-05; review moderation deferred | PO |
| Q-27 | Target scale (vendors, customers, orders/day) and business KPI targets? | NFR-005 | PO |
| Q-28 | Voice/OCR processing on-device vs cloud (privacy/cost/accuracy)? | POST-DELIVERY SR-01; grocery recognition deferred | Architect |
| Q-29 | Confirm "Staff" menu item hidden in v1? | UX | PO |
| Q-30 | Support phone number / email / hours for "Call Support"? | FR-133 | Ops |
| Q-31 | Git hosting & CI platform (A-14)? | GIT_CICD | Engineering |
| Q-32 | Maps provider: Google Maps Platform or MapmyIndia? | POST-DELIVERY SR-04: interactive maps/provider choice deferred; manual address/coordinates + optional GPS approved | Architect |
| Q-33 | Production domain(s) for API, admin, deep links, legal pages? | Deep links | PO |
| Q-34 | Low-stock threshold default and who sets it? | FR-035 | PO |
| Q-35 | What does the "+" button on the customer vendor-list header do (mockup)? | S-C-05 | UX |

## 9. 15-day baseline and approved scope reductions
Accepted 2026-10-29: English-only UI; native processes and PostgreSQL/PostGIS; local server file storage; no screenshot baseline refresh functionality; task build/lint/smoke and module-level comprehensive tests (ADR-023). The user subsequently approved all six additional reductions on 2026-10-29: ‘All additional reductions are approved’. These changes are active delivery scope, not pending recommendations. Future functionality remains traceable in the backlog; no deferred task is marked DONE.

Decision owner: **user / Product Owner**. Approval date: **2026-10-29**. Authority: this conversation; recorded in ADR-024. ROADMAP and TASKS are rebaselined to the reduced scope. Implementation is still not authorized by this documentation-only request.

Estimates below are overlapping developer-days saved, not additive elapsed-day guarantees. Three implementers plus QA and reusable foundations remain planning assumptions. All six decisions are **APPROVED**. Further scope reductions still need explicit approval; do not request SR-01–SR-06 approval again.

| Decision | Approved action and affected tasks | Reason / preserved behavior | Estimated saving | Status |
|---|---|---|---|---|
| SR-01 | Defer money tracker/auto-import/insights and grocery speech/OCR: T-120/T-121/T-124/T-125/T-127; FR-260–263, FR-280–283, FR-294 | Avoid independent finance and recognition pipelines; catalog/cart ordering, vendor Khata and existing personal Khata entries stay | 5–8 days | APPROVED (user, 2026-10-29) |
| SR-02 | Defer BBPS, referrals, coupons and undefined payment-method management: T-123/T-128–T-130; FR-271–272/FR-292–293/FR-222 | External contracts, funds and reward rules unresolved; direct vendor payment records/UPI claims and service directory remain | 4–7 days plus provider wait | APPROVED (user, 2026-10-29) |
| SR-03 | Stage SaaS purchase integration T-104 and automated KYC provider integration within T-022; retain admin-reviewed KYC and audited manually assigned plan entitlements (T-103/T-105/T-156) | Avoid billing/store/provider uncertainty while preserving verified vendors and server plan limits; manual fallback and entitlement assignment approved; no fake purchases or automated-verification claims | 3–5 days plus provider wait | APPROVED (user, 2026-10-29) |
| SR-04 | Simplify discovery to existing radius/pincode checks and coordinate/address form, CSV-only report export T-101, SQL/table reports; defer interactive maps/places and chart polish | Keeps service-area enforcement and accurate reports; Q-23 resolved to CSV; Q-32 provider selection deferred because forms/GPS coordinates need no map provider | 2–3 days | APPROVED (user, 2026-10-29) |
| SR-05 | Defer reviews/moderation, banner marketing and bulk broadcasts: T-108/T-157/T-159/T-160; keep basic categories, CMS/legal, operational inbox/push, dashboard and audit | Reduce ancillary CRUD and moderation work without breaking order status communication | 2–4 days | APPROVED (user, 2026-10-29) |
| SR-06 | Stage advanced telemetry, device-attestation/pinning proposals, broad device/load matrices, external pen-test scheduling and multi-zone/IaC automation; T-017/T-018/T-170–T-173 limited to basic config/crash/security/performance checks | Preserve HTTPS, RBAC, OTP abuse controls, privacy, financial/security tests, basic alerts, encrypted DB/files backups and tested restore. Android-only build/run/testing/release applies until Android production release (ADR-025); public-launch authorization remains separate; baseline security and restore are mandatory | 2–4 days | APPROVED (user, 2026-10-29) |

### Delivery policy after approval
Day 15 completion means all active/simplified scope passes G0–G6. SR-deferred tasks, provider contracts and future-only acceptance cases do not block those gates and must not be implemented as placeholders or marked passed. Deferred routes, tabs, marketing actions and permission prompts are absent from active navigation. Keep provider automation, billing, maps, reviews, extended finance and marketing requirements labeled POST-DELIVERY for traceability.

Q-23 is resolved: CSV-only export. Q-32 maps and Q-08 automated KYC are deferred; manual review and coordinate/address input are approved. Q-03/Q-06/Q-07/Q-14/Q-21/Q-22/Q-24/Q-26/Q-28 affect deferred functionality and do not block the active delivery. Hosting, OTP delivery/DLT, privacy/retention, admin roles, active plan/expiry/visibility and core order/subscription rules remain real decisions; approval does not invent their answers. Record remaining blockers with owners/deadlines in ROADMAP §5.
