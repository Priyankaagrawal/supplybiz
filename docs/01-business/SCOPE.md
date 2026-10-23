# SCOPE — Scope, Assumptions, Constraints, Dependencies, Risks, Open Questions

| Field | Value |
|---|---|
| Status | Draft v0.1 |
| Owner | Product Manager + Solution Architect |
| Last updated | 2026-10-19 |
| Related | [PRD](PRD.md), [DECISIONS](../05-ai-development/DECISIONS.md) |

> This file is the **single consolidated register** for assumptions (A-xx), constraints (C-xx), dependencies (D-xx), risks (R-xx) and open questions (Q-xx). Other documents reference these IDs instead of repeating them.

## 1. In Scope (v1.0)
| Area | Included |
|---|---|
| Platforms | Android & iOS phones (one Flutter app), web Admin Panel, NestJS backend |
| Common | OTP login (SMS/WhatsApp), role selection & switching, EN/HI, consent, account deletion, push + in-app notifications |
| Vendor | Onboarding (category, business info, KYC via API + manual fallback, bank/UPI), service area, dashboard, products & stock, orders, Quick Sale POS, customers, subscriptions, deliveries, availability & holidays, Khata & payment records, reports + download, SaaS plans, settings, Help/FAQ/call support |
| Customer | Home, location, search, services directory, vendor discovery/details, reviews, favorites, cart & checkout (pay-on-delivery / Khata), place new order (milk & water), subscriptions (create/pause/skip/modify/cancel), my orders & status tracking, Khata (vendor ledgers + personal entries), settle payment (UPI intent + claim), Money tracker, bill payments, grocery voice & image order, profile, addresses, payment methods, invite & earn, insights, settings, help |
| Admin | Auth + 2FA + RBAC, dashboard, KYC review, vendor/customer management, categories, plans & vendor subscriptions, banners/coupons, CMS/FAQ/legal, app config (force update, feature flags), broadcast notifications, review moderation, audit logs, data-subject requests, reports |

## 2. Out of Scope (v1.0)
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
| A-03 | Customer→vendor payments are off-platform (cash/UPI/bank/wallet); app records only. Exceptions: vendor SaaS fees, bill payments | Stakeholder answer |
| A-04 | Vendors are **not discoverable** by customers until KYC = VERIFIED and an active plan exists; they may set up catalog/customers before | Q-18 |
| A-05 | Subscription orders for date D are generated at **22:00 IST on D-1**; customer pause/skip/modify cutoff **21:00 IST on D-1** | Q-15 |
| A-06 | Subscription billing is **postpaid** via Khata: each delivered order debits the ledger; "Monthly amount" is an estimate | Q-19 |
| A-07 | Order/subscription quantity is an integer count of product packs (e.g., 2 × 1 L) | Q-11 |
| A-08 | Vendor (owner) performs delivery status updates himself (no staff accounts) | F-D1 |
| A-09 | Cart contains items from a single vendor only | — |
| A-10 | Aadhaar: only masked images and last 4 digits are stored; full number never persisted | ADR-014 |
| A-11 | Customer "Settle Payment" opens a UPI intent to the vendor's UPI ID and creates a **payment claim** the vendor confirms | Q-05 |
| A-12 | Firebase is used for FCM, Crashlytics, Analytics, Performance, Remote Config (Mixpanel not used) | ADR-010 |
| A-13 | Minimum OS: Android 7.0 (API 24), iOS 13 — re-validate against pinned Flutter version | — |
| A-14 | Source repository hosted on GitHub; CI on GitHub Actions | Q-31 |
| A-15 | A vendor has exactly one primary business category | Q-17 |
| A-16 | Delivery charge, minimum order value and time slots are configured per vendor in Delivery Settings | Q-13 |
| A-17 | Customer bottom navigation: Home · Orders · Khata · Services · Profile; Money accessed from Khata and Profile | Q-10 |
| A-18 | A subscription has one product line (as in mockups) | — |

## 4. Constraints
| ID | Constraint |
|---|---|
| C-01 | India regulatory: DPDP Act 2023 & Rules; UIDAI Aadhaar regulations; TRAI DLT registration for SMS; RBI/NPCI rules for UPI and BBPS |
| C-02 | App-store policies: Apple IAP / Google Play Billing for digital goods (affects vendor SaaS plans, R-02); account deletion requirement; privacy labels / Data safety form |
| C-03 | Tech stack fixed: Flutter, NestJS, PostgreSQL, Next.js admin |
| C-04 | Must work on low-end Android devices (2–3 GB RAM) and 3G-class networks |
| C-05 | Hindi requires Devanagari-capable fonts and layouts tolerant of longer strings |
| C-06 | Data residency: personal data stored in India region (cloud provider TBD, Q-02) |

## 5. Dependencies (external)
| ID | Dependency | Used by | Provider |
|---|---|---|---|
| D-01 | SMS OTP gateway (DLT-registered) | FR-002 | TBD (Q-09) |
| D-02 | WhatsApp Business API (OTP template) | FR-002 | TBD (Q-09) |
| D-03 | KYC APIs: PAN verification, bank account verification (penny-drop), Aadhaar (DigiLocker / offline e-KYC) | FR-015 | TBD (Q-08) |
| D-04 | Payment gateway or store billing for vendor SaaS plans | FR-121 | Razorpay (suggested) / IAP — Q-03 |
| D-05 | BBPS bill-payment partner | FR-271–FR-272 | TBD (Q-07) |
| D-06 | Firebase (FCM/APNs, Crashlytics, Analytics, Remote Config, Performance) | Many | Google |
| D-07 | Maps/geocoding & places autocomplete | FR-200, FR-291, FR-018 | Google Maps Platform or MapmyIndia — TBD (Q-32) |
| D-08 | Object storage + KMS | Uploads | Cloud provider TBD (Q-02) |
| D-09 | Speech-to-text (EN/HI) and OCR (Latin + Devanagari) | FR-280–FR-281 | On-device vs cloud TBD (Q-28) |
| D-10 | Apple Developer & Google Play Console accounts (organization) | Release | Owner TBD |
| D-11 | Domain + HTTPS hosting for deep links (assetlinks / AASA) and legal pages | FR-104 | TBD (Q-33) |

## 6. Internal Document Dependencies
See [README](../../README.md#document-dependencies).

## 7. Risks
| ID | Risk | Impact | Likelihood | Mitigation |
|---|---|---|---|---|
| R-01 | v1.0 scope is very large (all customer features + admin) | Delayed launch | High | Milestones M0–M6; P2 behind feature flags; ability to launch with flags off |
| R-02 | Apple/Google may require in-app purchase for vendor SaaS plans | Rejection; 15–30% fee | High | Decide ADR-015 early (Q-03); design billing behind `BillingProvider` interface |
| R-03 | Bill payments require a licensed BBPS partner and platform-handled funds | Feature blocked | High | Partner selection (Q-07); feature flag `bill_payments` |
| R-04 | Mishandling Aadhaar/KYC data | Legal penalties | Medium | Masking, encryption, restricted access, retention policy (AUTH_SECURITY) |
| R-05 | SMS DLT template registration delay | Login blocked | Medium | Start registration in M0; WhatsApp OTP fallback |
| R-06 | Off-platform payments cause disputes | Trust | Medium | Payment claims with vendor confirmation; immutable ledger; audit trail |
| R-07 | Subscription generation bugs (holidays/pauses/skips) | Financial errors | Medium | Idempotent job, unique constraints, exhaustive tests (TC-070 series) |
| R-08 | Low-end devices / poor networks | Poor UX | High | Performance budgets, offline outbox, image compression |
| R-09 | Voice/OCR accuracy for Hindi & handwriting | Low feature value | Medium | Editable detected list; feature flag |
| R-10 | Low vendor digital literacy | Adoption | Medium | Hindi-first UX, simple flows, onboarding help |
| R-11 | UPI intent behaves differently on iOS (no generic chooser) | Settle flow friction | Medium | Show UPI ID + QR + copy; app-specific schemes where allowed |
| R-12 | Dual-role users confuse contexts | Data errors | Low | Clear role indicator, separate shells, role-scoped API |
| R-13 | Cloud provider & launch timeline undecided | Planning | Medium | Cloud-agnostic design (containers, Postgres, S3-compatible) |

## 8. Open Questions
| ID | Question | Blocks | Owner |
|---|---|---|---|
| Q-01 | Launch city/region and target launch date? | Roadmap, seed data | PO |
| Q-02 | Cloud provider (AWS ap-south-1 / GCP asia-south1 / other)? | Infra, ADR-017 | PO + Architect |
| Q-03 | Vendor SaaS plan purchase channel: Apple IAP + Google Play Billing, or web checkout (Razorpay) outside app? | FR-121, ADR-015 | PO + Legal |
| Q-04 | Free trial? Grace period after expiry? Behaviour on expiry/downgrade? Final feature-to-plan mapping? | FR-123–FR-125 | PO |
| Q-05 | Meaning of "Settle to Bank", "Wallet/Settlement" (Premium) and "take-rate" under direct payments? | FR-114, plan gating | PO |
| Q-06 | Coupons: who creates and funds them (vendor or platform)? Rules? | FR-222 | PO |
| Q-07 | Bill payments: BBPS partner, payment method, commission, licensing? | FR-271–FR-272 | PO + Legal |
| Q-08 | KYC API provider; Aadhaar method (DigiLocker vs offline XML vs image only)? | FR-015 | PO + Legal |
| Q-09 | SMS and WhatsApp OTP providers; DLT entity & sender ID? | FR-002 | PO |
| Q-10 | Customer bottom navigation (mockup vs document conflict) — accept A-17? | UX | PO + UX |
| Q-11 | Support loose/fractional quantities (e.g., 1.5 L)? | Data model | PO |
| Q-12 | Category-specific flows for tiffin, laundry, flowers, newspaper, home services? | Customer services | PO |
| Q-13 | Who sets delivery charges / minimum order — vendor (A-16) or platform? | FR-132 | PO |
| Q-14 | Invite & Earn: reward type, amount, eligibility, fraud rules? | FR-293 | PO |
| Q-15 | Subscription generation time and customer change cutoff (A-05)? | FR-074, FR-077 | PO |
| Q-16 | Can customers cancel after vendor ACCEPTED? Any cancellation fee? | FR-242 | PO |
| Q-17 | Can a vendor operate multiple categories (A-15)? | FR-010 | PO |
| Q-18 | Visibility before KYC verification (A-04)? | FR-017 | PO |
| Q-19 | Subscription billing prepaid vs postpaid (A-06)? | FR-233 | PO |
| Q-20 | Data retention periods (KYC docs, ledger, deleted accounts)? | AUTH_SECURITY | Legal |
| Q-21 | Money tracker: auto-import Supply Biz payments as expenses? | FR-263 | PO |
| Q-22 | "Payment Methods" screen meaning under direct payments (saved UPI IDs? preferred method?) | FR-292 | PO |
| Q-23 | Report download formats (PDF, CSV, both)? | FR-094 | PO |
| Q-24 | GST: plan prices inclusive/exclusive; GST invoices for plans; vendor GST invoices to customers? | FR-126 | Finance |
| Q-25 | Admin roles & permissions list; admin panel domain? | FR-400 | PO |
| Q-26 | Review moderation policy (auto-publish vs pre-moderation)? | FR-410 | PO |
| Q-27 | Target scale (vendors, customers, orders/day) and business KPI targets? | NFR-005 | PO |
| Q-28 | Voice/OCR processing on-device vs cloud (privacy/cost/accuracy)? | FR-280–FR-281 | Architect |
| Q-29 | Confirm "Staff" menu item hidden in v1? | UX | PO |
| Q-30 | Support phone number / email / hours for "Call Support"? | FR-133 | Ops |
| Q-31 | Git hosting & CI platform (A-14)? | GIT_CICD | Engineering |
| Q-32 | Maps provider: Google Maps Platform or MapmyIndia? | D-07 | Architect |
| Q-33 | Production domain(s) for API, admin, deep links, legal pages? | Deep links | PO |
| Q-34 | Low-stock threshold default and who sets it? | FR-035 | PO |
| Q-35 | What does the "+" button on the customer vendor-list header do (mockup)? | S-C-05 | UX |
