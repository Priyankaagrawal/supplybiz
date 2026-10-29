# CONTEXT — Project Context, Glossary, Conventions

| Field | Value |
|---|---|
| Status | Draft v0.1 |
| Owner | Product Manager + Technical Architect |
| Last updated | 2026-10-29 |
| Related | [AGENTS](AGENTS.md), [VISION](../01-business/VISION.md), [DECISIONS](DECISIONS.md) |

## 1. One-Paragraph Context
Supply Biz is a two-sided marketplace for India's local milk vendors (and other local suppliers) and households. One Flutter app (Android release first; iOS validation after Android release) serves both **Vendors** (catalog, orders, POS, daily subscriptions, deliveries, Khata ledger, reports, SaaS plans) and **Customers** (discover vendors, order/subscribe, track delivery, vendor/personal Khata, payment claims, profile and service directory; separate Money, bill payments and recognition are post-delivery SR-01/SR-02). A NestJS + PostgreSQL backend and a Next.js admin panel complete the system. Customers pay vendors directly; the app only records payments. Vendor plans are assigned manually with audit and server-side entitlements; automated SaaS checkout/invoices are post-delivery SR-03.

## 2. Glossary
| Term | Meaning |
|---|---|
| **Khata** | Traditional Indian credit ledger ("account book"). Per vendor–customer running balance of debits (goods given) and credits (payments). Kept as "Khata" in English |
| **Ledger entry** | One immutable DEBIT or CREDIT line in a Khata |
| **Due / Payable / Receivable** | Due = debits − credits. For the vendor it is *receivable*; for the customer it is *payable* |
| **Payment claim** | Customer's statement that they paid; becomes a CREDIT only after vendor confirms |
| **Quick Sale / POS** | Instant counter sale without the order flow; walk-in or linked to a customer |
| **Walk-in** | Anonymous counter customer; must pay in full |
| **Subscription** | Recurring delivery of a product on selected weekdays; generates one order per delivery date |
| **Generation job** | Nightly 22:00 IST job creating next-day subscription orders |
| **Cutoff** | 21:00 IST on D-1: last time changes affect date D |
| **Holiday** | Vendor day off; no deliveries; cancels affected orders |
| **Skip** | Customer/vendor removes a single delivery date from a subscription |
| **Pause** | Temporarily stop a subscription (or all vendor deliveries) |
| **Vendor customer** | Link record between a vendor and a person (app user or offline) — `vendor_customers` |
| **Offline customer** | Customer record created by vendor without an app account |
| **Plan** | Vendor SaaS tier: BASIC, STANDARD, BUSINESS, PREMIUM; durations monthly/half-yearly/yearly |
| **Entitlement** | Features + customer limit granted by the active plan |
| **MOQ** | Minimum order quantity (packs) |
| **Pack / unit** | Sellable unit of a product (e.g., 1 L pouch, 500 g curd) |
| **Toned / Double toned / Full cream** | Milk fat grades (~3% / ~1.5% / ~6% fat) |
| **Paneer, Dahi (Curd), Ghee** | Dairy products: cottage cheese, yogurt, clarified butter |
| **Water can** | 20 L reusable drinking-water container |
| **Tiffin** | Home-cooked meal delivery service |
| **UPI / VPA** | Unified Payments Interface / Virtual Payment Address (e.g., `rohit@okaxis`) |
| **UPI intent** | Deep link `upi://pay?...` opening a UPI app with prefilled payee & amount |
| **IFSC** | 11-char Indian bank branch code |
| **GSTIN** | 15-char GST registration number |
| **PAN** | 10-char Permanent Account Number (tax ID) |
| **Aadhaar** | 12-digit national ID; strictly regulated by UIDAI |
| **Penny drop** | Bank account verification by depositing ₹1 and reading the account holder name |
| **DigiLocker** | Government document wallet; can provide verified Aadhaar/PAN |
| **DLT** | TRAI Distributed Ledger registration mandatory for commercial SMS templates |
| **BBPS** | Bharat Bill Payment System (NPCI) for utility bill payments |
| **DPDP** | Digital Personal Data Protection Act 2023 |
| **Paise** | 1/100 rupee; all money stored in paise |
| **IST** | India Standard Time, UTC+05:30, no DST |

## 3. ID Conventions
| Prefix | Meaning | Defined in |
|---|---|---|
| G-xx | Goal | VISION |
| BR-xx | Business requirement | BRD |
| F-xx | Feature | PRD |
| A/C/D/R/Q-xx | Assumption / Constraint / Dependency / Risk / Question | SCOPE |
| FR-xxx / NFR-xxx | Requirement | SRS |
| RULE-xx | Business rule | USER_STORIES |
| US-xxx | User story | USER_STORIES |
| S-COM/S-V/S-C/S-A-xx | Screen | SCREEN_SPECIFICATIONS |
| ADR-xxx | Decision | DECISIONS |
| E-xx / T-xxx | Epic / Task | TASKS |
| M0–M6 | Milestone | ROADMAP |
| TC-xxx | Test case | TEST_CASES |

## 4. Key Conventions (summary)
- Money: integer paise; display via `formatInr()` (RULE-01).
- Time: store UTC; business dates in IST; never use device time for cutoffs.
- Quantities: integer packs.
- Status enums: UPPER_SNAKE in API/DB; localized labels in UI.
- Every screen file references its screen ID; every PR references FR/US/T IDs.
- Full rules: [CODING_STANDARDS](../06-development/CODING_STANDARDS.md).

## 5. Important Constraints (do not violate)
1. Never store full Aadhaar numbers or unmasked Aadhaar images (ADR-014).
2. Never move customer money through the platform (ADR-008).
3. Ledger entries are never updated or deleted (ADR-021).
4. Never trust client prices, totals, roles or vendorId — server recomputes/derives.
5. Never log PII, OTPs or tokens.
6. Plan gating and limits are enforced server-side.
7. Do not invent requirements; unresolved items are `TBD (Q-xx)`.

## 6. Source Material
- `SupplyBiz_Milk_Vendor_Customer_App_Project_Document.docx` (v1.0, Oct 2026) — referenced as "DOC".
- `Wireframe.png` — 12 customer screens, referenced as "WF-1…WF-12".
- Stakeholder decisions of 2026-10-19 (framework, backend, packaging, scope, payments, KYC, admin, tracking, brand/languages, auth) — recorded in SCOPE and DECISIONS.

## 7. Delivery baseline
As of 2026-10-29 use ADR-023, ROADMAP and TASKS: English-only, native processes/PostgreSQL/PostGIS, persistent local-file uploads, per-task build/lint/smoke and comprehensive module testing. Existing source/configuration is reconciled in T-180–T-184. Essential vendor/customer/admin flows and financial/security rules remain required; SR-01–SR-06 are approved (ADR-024); DELIVERY_SCOPE maps active/simplified and post-delivery requirements. Android-only build/run/testing/release continues through Android production release; T-185 validates iOS afterward (ADR-025).
