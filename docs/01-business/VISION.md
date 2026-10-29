# VISION — Supply Biz

| Field | Value |
|---|---|
| Status | Draft v0.1 (awaiting approval) |
| Owner | Product Manager |
| Last updated | 2026-10-29 |
| Sources | `SupplyBiz_Milk_Vendor_Customer_App_Project_Document.docx` v1.0 (Oct 2026), `Wireframe.png`, stakeholder answers (2026-10-19) |
| Related | [BRD](BRD.md), [PRD](PRD.md), [SCOPE](SCOPE.md) |

## 1. Purpose
Defines why Supply Biz exists, who it serves, and how success is measured. All other documents must stay consistent with this vision.

## 2. Vision Statement
> Digitize the traditional milk-vendor business in India by giving vendors a complete digital toolkit (orders, subscriptions, delivery, payments, stock, KYC) and giving households a seamless way to order and subscribe to milk and other local supplies.

Tagline (from source): **"Fresh Milk • Happy Homes"**.

## 3. Product Summary
Supply Biz is a **two-sided marketplace** delivered as **one Flutter mobile app (Android release first; iOS validation afterward) with role selection** (Vendor or Customer), plus a **web Admin Panel** for platform operations.

| Side | Primary value |
|---|---|
| Vendor (milk supplier, primary; also water, tiffin, grocery, flowers, laundry, F&V, others) | Run the whole business from a phone: catalog, orders, walk-in POS, daily subscriptions, deliveries, holidays, Khata (credit ledger), payment records, reports |
| Customer (household) | Discover nearby vendors, order one-time or subscribe, track today's delivery, manage vendor/personal Khata and UPI payment claims; separate Money/bill payments/voice-image recognition are post-delivery SR-01/SR-02 |
| Platform (Supply Biz) | Recurring SaaS revenue from vendor plans; network of verified local vendors |

> Branding decision: single brand **"Supply Biz"** (the name "SupplyMate" in mockups is replaced). Languages: **English**.

## 4. Target Users
| Segment | Description | Key need |
|---|---|---|
| Milk vendor / dairy owner | Small local business, often family-run, mostly credit-based (Khata) sales, daily delivery routes | Replace paper diary; never miss a delivery; know who owes what |
| Other local suppliers | Water can, tiffin, grocery, flowers, laundry, F&V | Same toolkit adapted to their category (category-specific flows TBD — see [SCOPE](SCOPE.md)) |
| Household customer | Urban/semi-urban families receiving daily milk | Reliable delivery, easy pause/skip, transparent monthly bill |
| Platform admin | Supply Biz operations, support, finance | Verify vendors, manage plans/content, monitor platform health |

Launch geography: **India** (₹ INR, +91, IST). Launch city: **TBD** (mockups show Bhopal).

## 5. Goals
| ID | Goal | Measure (see [PRD §6](PRD.md#6-success-metrics)) |
|---|---|---|
| G-01 | Fast vendor onboarding (mobile + OTP + KYC + bank) | Median onboarding completion time; KYC approval rate |
| G-02 | Support walk-in POS and customer-linked orders | Quick-sale volume per vendor |
| G-03 | Reliable daily/monthly subscriptions with pause/holiday controls | Subscription retention; delivery success rate |
| G-04 | Real-time order, delivery and payment status | Order status latency; notification delivery rate |
| G-05 | Digital Khata for credit sales | Khata usage; pending-payment recovery |
| G-06 | Actionable vendor reports | Report views / downloads per vendor |
| G-07 | One customer app for milk, water, tiffin and catalog grocery orders; bill payments deferred SR-02 | DAU/MAU; categories used per customer |
| G-08 | Sustainable revenue via vendor SaaS plans | Paid vendors; plan upgrade rate |

## 6. Business Value
- **Vendors:** less revenue leakage from forgotten credit, fewer missed deliveries, time saved on monthly billing.
- **Customers:** transparency of daily deliveries and monthly dues; one app for local needs.
- **Platform:** subscription (SaaS) revenue; marketplace network effects. Customer-to-vendor payments happen **directly** (cash/UPI to vendor); the app **records** them — the platform does not hold customer funds (see [DECISIONS ADR-008](../05-ai-development/DECISIONS.md)).

## 7. Guiding Principles
1. **Vendor-first simplicity** — usable by low digital-literacy users, in simple English, on low-end Android phones and weak networks.
2. **Trust & transparency** — every rupee in the Khata is traceable; ledger entries are immutable.
3. **Daily reliability** — subscription deliveries must be generated correctly every day.
4. **Privacy by design** — KYC and financial data minimized, encrypted, and DPDP Act 2023 compliant.
5. **Built for AI-assisted delivery** — every requirement has a stable ID and traceable tests.

## 8. Non-Goals (v1)
- Holding/escrowing customer funds or marketplace commission settlement.
- Live GPS delivery tracking and delivery-staff app (status-based tracking only).
- Vendor staff / delivery-boy management; support tickets and chat.

## 9. Open Questions
See consolidated list in [SCOPE §8](SCOPE.md#8-open-questions). Vision-level: Q-01 (launch city & timeline), Q-27 (target scale).

## 9. Approved delivery interpretation
User-approved SR-01–SR-06 (ADR-024) define the current reduced scope, with manually reviewed KYC, audited plan assignments, form/GPS location, SQL/table/CSV reports and basic diagnostics. SaaS collection is a future commercial workflow; current grants are not paid-revenue evidence. Android build/run/test/release is first; iOS validation starts after Android production release (ADR-025/T-185). See DELIVERY_SCOPE, SCOPE and ROADMAP for precise applicability.
