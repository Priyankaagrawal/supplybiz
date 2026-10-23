# BRD — Business Requirements Document

| Field | Value |
|---|---|
| Status | Draft v0.1 |
| Owner | Business Analyst |
| Last updated | 2026-10-19 |
| Related | [VISION](VISION.md), [PRD](PRD.md), [SCOPE](SCOPE.md), [SRS](../02-requirements/SRS.md) |

## 1. Purpose and Scope
Captures the business problems, stakeholders, business requirements (`BR-xx`) and expected outcomes. Product features are in [PRD](PRD.md); detailed functional requirements (`FR-xxx`) are in [SRS](../02-requirements/SRS.md).

## 2. Stakeholders
| Role | Responsibility | Interest |
|---|---|---|
| Product Owner / Founder | Final decisions on scope, pricing, priorities | Revenue, adoption |
| Vendors | Primary paying users | Ease of use, payment recovery |
| Customers | Demand side | Reliable delivery, transparency |
| Ops/Admin team | KYC review, vendor support, content | Efficient tooling |
| Finance | Plan revenue, invoices, reconciliation | Accurate billing |
| Engineering (incl. AI agents) | Build and run the system | Clear, unambiguous specs |
| Compliance / Legal | DPDP, UIDAI (Aadhaar), RBI/NPCI rules, app-store policy | Lawful operation |

## 3. Business Problems
| ID | Problem | Who |
|---|---|---|
| P-01 | Deliveries, quantities and credit are tracked in paper diaries → errors, disputes, lost revenue | Vendor |
| P-02 | Monthly billing for daily milk is manual and slow | Vendor, Customer |
| P-03 | Customers cannot easily pause/skip deliveries or see what they owe | Customer |
| P-04 | Vendors lack visibility of stock, sales and pending payments | Vendor |
| P-05 | Households use separate channels for milk, water, tiffin, groceries and bills | Customer |
| P-06 | Local vendors are not discoverable online | Vendor, Customer |
| P-07 | Trust: customers need assurance that a vendor is genuine | Customer |

## 4. Business Requirements
| ID | Requirement | Problem | Priority |
|---|---|---|---|
| BR-01 | Vendors onboard via mobile OTP, business details, KYC and bank details, with verification | P-06, P-07 | Must |
| BR-02 | Vendors manage a product catalog with prices, subscription prices and stock | P-04 | Must |
| BR-03 | Vendors receive, accept/reject and fulfil customer orders with status tracking | P-01 | Must |
| BR-04 | Vendors record walk-in and customer-linked quick sales (POS) | P-01, P-04 | Must |
| BR-05 | Vendors and customers manage recurring daily subscriptions with delivery days, pause, skip and holidays | P-01, P-03 | Must |
| BR-06 | Every sale and payment is reflected in a per-customer Khata ledger visible to both parties | P-01, P-02, P-03 | Must |
| BR-07 | Payments from customers to vendors happen directly (cash/UPI/bank/wallet); the app records them | P-02 | Must |
| BR-08 | Vendors view reports (sales, orders, milk sold, pending payments) and download them | P-04 | Must |
| BR-09 | Customers discover verified nearby vendors by category, rating and distance | P-06, P-07 | Must |
| BR-10 | Customers place one-time orders and subscriptions and track delivery status | P-03 | Must |
| BR-11 | Customers track personal income/expense ("Money") | P-05 | Must (per stakeholder) |
| BR-12 | Customers pay utility bills inside the app | P-05 | Must (per stakeholder; provider TBD) |
| BR-13 | Customers create grocery orders by voice or image of a list | P-05 | Must (per stakeholder) |
| BR-14 | Vendors pay a SaaS plan (Basic/Standard/Business/Premium; monthly/half-yearly/yearly) limited by customer count and features | Revenue | Must |
| BR-15 | Platform admins verify KYC, manage vendors, customers, categories, plans, content and notifications via a web Admin Panel | P-07 | Must |
| BR-16 | App available in English and Hindi | Adoption | Must |
| BR-17 | Comply with DPDP Act 2023, UIDAI Aadhaar handling rules, and app-store policies | Compliance | Must |

## 5. Revenue Model
Vendor SaaS plans (from source document, prices in ₹ incl./excl. GST = **TBD**, Q-24):

| Plan | Monthly | Half-Yearly | Yearly | Customer limit | Feature tier |
|---|---|---|---|---|---|
| BASIC | 99 | 499 | 999 | 100 | Basic order management |
| STANDARD | 199 | 999 | 1,499 | 250 | + Customer subscription + Delivery management |
| BUSINESS ★ | 299 | 1,499 | 1,999 | 500 | + Auto-accept + Stock + Advanced reports |
| PREMIUM | 499 | 1,999 | 3,499 | 1,000 | + Wallet/Settlement + Priority support + Complete management |

Exact feature-to-plan mapping is defined in [PRD §5](PRD.md#5-plan-feature-gating). Free trial, grace period and in-app purchase channel are **TBD** (Q-03, Q-04).

Other potential revenue (bill-payment commissions, take-rate) — **TBD**; the source KPI "take-rate" conflicts with the direct-payment model (Q-05).

## 6. Expected Outcomes
| Outcome | Target |
|---|---|
| Vendor completes onboarding in one session | TBD (proposed: median < 10 min excluding KYC review) |
| KYC decision turnaround | TBD (proposed: automated < 5 min; manual < 24 h) |
| Subscription delivery generation accuracy | 100% (zero missed/duplicate orders) |
| Crash-free sessions | ≥ 99.5% |
| Store rating | TBD (proposed ≥ 4.3) |
Business numeric targets (vendors, GMV, retention) are **TBD** by the Product Owner (Q-27).

## 7. Assumptions, Constraints, Dependencies, Risks
Consolidated in [SCOPE](SCOPE.md) (A-xx, C-xx, D-xx, R-xx) to avoid duplication.

## 8. Approval
| Role | Name | Decision | Date |
|---|---|---|---|
| Product Owner | TBD | Pending | — |
