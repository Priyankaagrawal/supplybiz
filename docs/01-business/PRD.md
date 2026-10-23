# PRD — Product Requirements Document

| Field | Value |
|---|---|
| Status | Draft v0.1 |
| Owner | Product Manager |
| Last updated | 2026-10-19 |
| Related | [BRD](BRD.md), [SCOPE](SCOPE.md), [SRS](../02-requirements/SRS.md), [USER_STORIES](../02-requirements/USER_STORIES.md), [ROADMAP](../05-ai-development/ROADMAP.md) |

## 1. Purpose
Defines product features (`F-xx`), priorities, plan gating and success metrics. Each feature maps to functional requirements in the [SRS](../02-requirements/SRS.md).

## 2. Product Shape
- **Mobile app:** one Flutter app "Supply Biz" for Android and iOS. After OTP login the user selects a role (**Customer** or **Vendor**). One mobile number may hold both roles and switch between them.
- **Admin Panel:** web app (Next.js) for platform staff.
- **Backend:** NestJS + PostgreSQL REST API, shared by mobile and admin.

## 3. Priority Definitions
| Priority | Meaning |
|---|---|
| P0 | Core loop; release blocked without it |
| P1 | Required for v1.0 launch per stakeholder decision |
| P2 | Required for v1.0 per stakeholder decision but has unresolved external dependency; may slip behind a feature flag (see risk R-01) |

> Stakeholder decision (2026-10-19): **all customer features in the source document and the selected vendor features are in v1.0.** Priorities set build order, not inclusion.

## 4. Feature Catalog
| ID | Feature | App | Priority | FR range | Plan gate |
|---|---|---|---|---|---|
| F-01 | OTP authentication, role selection, session, language, consent, account deletion | Common | P0 | FR-001–FR-009 | — |
| F-02 | Vendor onboarding: category, business info, KYC (API + manual), bank/UPI, service area | Vendor | P0 | FR-010–FR-018 | — |
| F-03 | Vendor dashboard & metrics | Vendor | P0 | FR-020–FR-023 | — |
| F-04 | Product management & stock | Vendor | P0 | FR-030–FR-036 | Stock alerts: BUSINESS+ |
| F-05 | Vendor order management (accept/reject/status) | Vendor | P0 | FR-040–FR-046 | — |
| F-06 | Quick Sale (POS) | Vendor | P0 | FR-050–FR-054 | — (proposed) |
| F-07 | Vendor customer management | Vendor | P0 | FR-060–FR-064 | Customer limit by plan |
| F-08 | Subscriptions (vendor + customer) incl. daily order generation | Both | P0 | FR-070–FR-077, FR-230–FR-233 | STANDARD+ |
| F-09 | Delivery management, availability, holidays | Vendor | P0 | FR-080–FR-085 | STANDARD+ |
| F-10 | Reports & analytics + download | Vendor | P1 | FR-090–FR-095 | Advanced: BUSINESS+ |
| F-11 | Notifications (push + in-app) | Both | P0 | FR-100–FR-104 | — |
| F-12 | Vendor Khata & payment recording/confirmation | Vendor | P0 | FR-110–FR-116 | — (proposed) |
| F-13 | Vendor SaaS plans & billing | Vendor | P1 | FR-120–FR-126 | — |
| F-14 | Vendor settings, delivery settings, help/FAQ, legal | Vendor | P1 | FR-130–FR-134 | — |
| F-15 | Customer home, location, search | Customer | P0 | FR-200–FR-203 | — |
| F-16 | Vendor discovery, vendor/product details, favorites | Customer | P0 | FR-210–FR-212, FR-214 | — |
| F-17 | Cart, checkout, place new order (one-time) | Customer | P0 | FR-220–FR-225 | — |
| F-18 | My orders & status tracking | Customer | P0 | FR-240–FR-243 | — |
| F-19 | Customer Khata (vendor ledgers + personal entries) & settle payment | Customer | P0 | FR-250–FR-253 | — |
| F-20 | Money (income/expense tracker) | Customer | P1 | FR-260–FR-263 | — |
| F-21 | Services directory & bill payments | Customer | P2 | FR-270–FR-272 | — |
| F-22 | Grocery voice & image order | Customer | P2 | FR-280–FR-283 | — |
| F-23 | Profile, addresses, payment methods, referral, insights, settings, help | Customer | P1 | FR-290–FR-297 | — |
| F-24 | Reviews & ratings | Customer | P1 | FR-213 | — |
| F-25 | Admin Panel | Admin | P0 | FR-400–FR-413 | — |

### Deferred (not v1.0)
| ID | Feature | Reason |
|---|---|---|
| F-D1 | Staff / Delivery boys management | Stakeholder deselected |
| F-D2 | Support tickets & in-app chat | Stakeholder deselected (Help/FAQ/call remain) |
| F-D3 | Live GPS delivery tracking & delivery-partner details | Stakeholder decision; status-only tracking |
| F-D4 | Platform-collected customer payments / settlement / commission | Direct-payment model (ADR-008) |

## 5. Plan Feature Gating
Derived from source "feature progression". Rows marked *(proposed)* are not explicit in the source and need confirmation (Q-04).

| Capability | BASIC | STANDARD | BUSINESS | PREMIUM |
|---|---|---|---|---|
| Max linked customers | 100 | 250 | 500 | 1,000 |
| Products, orders, accept/reject | ✓ | ✓ | ✓ | ✓ |
| Quick Sale, Khata, payment records *(proposed)* | ✓ | ✓ | ✓ | ✓ |
| Basic reports (summary cards) *(proposed)* | ✓ | ✓ | ✓ | ✓ |
| Customer subscriptions | ✗ | ✓ | ✓ | ✓ |
| Delivery management & holidays | ✗ | ✓ | ✓ | ✓ |
| Auto-accept subscription orders | ✗ | ✗ | ✓ | ✓ |
| Stock management & low-stock alerts | ✗ | ✗ | ✓ | ✓ |
| Advanced reports (chart, product-wise, download) | ✗ | ✗ | ✓ | ✓ |
| "Wallet/Settlement" | ✗ | ✗ | ✗ | TBD (Q-05) |
| Priority support | ✗ | ✗ | ✗ | ✓ (definition TBD) |

Gating is enforced **server-side**; the app hides/locks UI and shows an upgrade prompt.

## 6. Success Metrics
Source KPIs; targets **TBD** (Q-27). Event definitions in [QUALITY_OBSERVABILITY](../04-architecture/QUALITY_OBSERVABILITY.md#4-analytics).

| Area | KPI | Definition |
|---|---|---|
| Vendor | Active vendors | Vendors with ≥1 order/sale in last 7 days |
| Vendor | Avg orders per vendor per day | Orders (all sources) ÷ active vendors |
| Vendor | Subscription conversion | Customers with active subscription ÷ linked customers |
| Vendor | Stock-out incidents | Count of low-stock / out-of-stock events |
| Vendor | Plan upgrade rate | Upgrades ÷ paying vendors per month |
| Customer | DAU/MAU | Standard |
| Customer | Subscription retention | Subscriptions active after 30/60/90 days |
| Customer | Order frequency | Orders per customer per month |
| Customer | Khata usage | Customers opening Khata ≥1/week |
| Customer | NPS / store rating | Survey (tool TBD) / store |
| Platform | GMV (recorded) | Sum of delivered order + quick-sale value (recorded, not collected by platform) |
| Platform | Delivery success rate | Delivered ÷ (Delivered + Failed) |
| Platform | Payment recording latency | Time from delivery to payment recorded (replaces "settlement time", Q-05) |
| Platform | Crash-free sessions | ≥ 99.5% (NFR-015) |

## 7. Release Plan Summary
Detailed in [ROADMAP](../05-ai-development/ROADMAP.md). Single public release **v1.0** with internal milestones M0–M6; P2 features ship behind remote feature flags.

## 8. Risks
See [SCOPE §7](SCOPE.md#7-risks). Most significant: R-01 (scope size), R-02 (store billing for SaaS), R-03 (bill-payment licensing).
