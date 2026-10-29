# USER FLOWS — Personas, Journeys, Navigation

| Field | Value |
|---|---|
| Status | Draft v0.1 |
| Owner | UX Designer |
| Last updated | 2026-10-29 |
| Related | [USER_STORIES](../02-requirements/USER_STORIES.md), [SCREEN_SPECIFICATIONS](SCREEN_SPECIFICATIONS.md), [MOBILE_STRATEGY](../04-architecture/MOBILE_STRATEGY.md) |

## 1. Personas
| Persona | Profile | Goals | Pain points | Design implications |
|---|---|---|---|---|
| **Rohit — milk vendor** (from mockup "Rohit Milk Center") | 38, runs a dairy with ~150 households, low-end Android, prefers simple text, delivers 6–9 AM | Never miss a delivery; know dues; get paid on time | Paper diary errors, month-end billing disputes | Big touch targets, simple English, offline delivery updates, one-tap actions |
| **Ramesh — household customer** (mockup "Ramesh Kumar") | 42, family of 4, daily 2 L milk, UPI user | Reliable delivery; easy pause when travelling; clear bill | Doesn't know monthly due until vendor tells | Today's delivery on home, pause/skip in 2 taps, transparent Khata |
| **Priya — multi-service customer** | 29, working professional, orders water cans, tiffin and grocery catalog items | One app for local needs | Many apps/contacts | Services grid, catalog search and recurring orders (bills/recognition deferred) |
| **Anita — ops admin** | Platform operations | Verify vendors quickly, resolve issues | Manual document checks | KYC queue with API results, audit trail |

## 2. App Entry & Role Flow
```mermaid
flowchart TD
    A[Launch] --> B{Force update needed?}
    B -- yes --> FU[S-COM-06 Force update]
    B -- no --> C{First launch?}
    C -- yes --> L[Auth and consent]
    C -- no --> D{Session valid?}
    L --> M[S-COM-03 Mobile number]
    D -- no --> M
    M --> O[S-COM-04 OTP]
    O --> E{Has role?}
    D -- yes --> R{Active role}
    E -- none --> RS[S-COM-05 Role select]
    E -- yes --> R
    RS -- Customer --> CH[Customer shell: S-C-01 Home]
    RS -- Vendor --> VO{Onboarding complete?}
    R -- CUSTOMER --> CH
    R -- VENDOR --> VO
    VO -- no --> VS[Resume onboarding step]
    VO -- yes --> VH[Vendor shell: S-V-05 Dashboard]
```

## 3. Navigation Structure

### 3.1 Vendor shell (bottom nav: Home · Orders · Products · Customers · More)
```mermaid
flowchart LR
    Home[S-V-05 Dashboard] --> QS[S-V-11 Quick Sale]
    Home --> Rep[S-V-17 Reports]
    Home --> Notif[S-V-18 Notifications]
    Orders[S-V-08 Orders] --> OD[S-V-09 Order details] --> RJ[S-V-10 Reject sheet]
    Products[S-V-06 Products] --> PE[S-V-07 Add/Edit product]
    Customers[S-V-12 Customers] --> CD[S-V-14 Customer detail] --> SUB[S-V-15 Subscription]
    Customers --> CE[S-V-13 Add/Edit customer]
    More[S-V-19 More] --> DL[S-V-16 Deliveries]
    More --> KH[S-V-23 Khata] --> LD[S-V-24 Ledger detail] --> RP[S-V-25 Record payment]
    More --> PAY[S-V-26 Payments]
    More --> PL[S-V-27 Plans] --> PC[S-V-28 Assigned plan validity]
    More --> ST[S-V-20 Settings]
    ST --> SS[S-V-21 Subscription settings]
    ST --> HO[S-V-22 Availability & holidays]
    ST --> SA[S-V-30 Service area]
    ST --> DS[S-V-31 Delivery settings]
    ST --> NS[S-V-32 Notification settings]
    ST --> BP[S-V-33 Business/KYC edit]
    More --> HELP[S-V-29 Help]
```

### 3.2 Customer shell (bottom nav: Home · Orders · Khata · Services · Profile — A-17/Q-10)
```mermaid
flowchart LR
    Home[S-C-01 Home] --> LOC[S-C-02 Location]
    Home --> SR[S-C-03 Search]
    Home --> VL[S-C-05 Vendor list] --> VD[S-C-06 Vendor details]
    VD --> PLs[S-C-07 Products] --> PD[S-C-08 Product details]
    VD --> SP[S-C-09 Subscription plans] --> SC[S-C-10 Subscription setup]
    PD --> CART[S-C-11 Cart & checkout]
    Home --> NO[S-C-12 Place new order]
    Orders[S-C-13 My orders] --> TR[S-C-14 Tracking]
    Khata[S-C-17 Khata] --> VLD[S-C-18 Vendor ledger] --> SET[S-C-20 Settle]
    Khata --> KE[S-C-19 Add entry]
    Services[S-C-04 Services] --> VL
    Profile[S-C-27 Profile] --> MS[S-C-15 My subscriptions] --> MSD[S-C-16 Manage]
    Profile --> ADR[S-C-28 Addresses] --> ADE[S-C-29 Edit address]
    Profile --> APS[S-C-33 Settings]
    Profile --> HLP[S-C-34 Help]
```

## 4. Critical Journeys

### J-01 Vendor onboarding (US-010–US-014)
```mermaid
flowchart LR
    A[Mobile] --> B[OTP] --> C[Role: Vendor] --> D[S-V-01 Category] --> E[S-V-02 Business info + photo + location] --> F[S-V-03 KYC & bank] --> G[S-V-04 Status: PENDING] --> H[Dashboard with banner]
    H -. KYC VERIFIED push .-> I[Banner: choose plan] --> J[S-V-27 Plans] --> K[Discoverable]
```
Edge cases: app killed mid-step (resume, FR-016); file too large; KYC REJECTED → edit & resubmit; no network on submit (retry; uploads are not queued offline).

### J-02 Order lifecycle (US-041, US-080, US-240)
```mermaid
sequenceDiagram
    actor C as Customer
    participant API
    actor V as Vendor
    C->>API: Place order (Idempotency-Key)
    API-->>V: Push "New Order"
    V->>API: Accept
    API-->>C: Push "Order confirmed"
    V->>API: Start delivery
    API-->>C: Push "Out for delivery"
    V->>API: Mark delivered (+payment collected?)
    API->>API: Post DEBIT (+CREDIT if paid), decrement stock
    API-->>C: Push "Delivered" (no review prompt)
```
Alternatives: vendor rejects (reason) → customer notified; customer cancels while NEW; delivery FAILED (reason) → no DEBIT.

### J-03 Subscription (US-074, US-071, US-075)
```mermaid
flowchart TD
    A[Vendor details → Subscription tab] --> B[Select plan / Custom]
    B --> C[S-C-10 Qty, days, start, slot, address]
    C --> D[Confirm] --> E{Vendor auto-accept?}
    E -- yes --> F[ACTIVE]
    E -- no --> G[PENDING_APPROVAL] --> H{Vendor decision}
    H -- accept --> F
    H -- reject --> X[Customer notified]
    F --> J[[22:00 IST job generates tomorrow's order]]
    J --> K[Delivery flow J-02]
    F --> P[Pause / Skip / Modify before 21:00 cutoff]
```

### J-04 Quick Sale (US-050/051)
Dashboard → Quick Sale → choose mode → add products → adjust qty/rate → payment status/method/paid → Complete Sale → success toast + "New sale". Offline: saved to outbox with "Pending sync" chip.

### J-05 Holiday (US-081)
More → Settings → Availability & Holidays → Mark Holiday (date, reason) → confirm dialog shows count of affected orders/customers → save → customers notified.

### J-06 Khata settle (US-252, US-113)
```mermaid
sequenceDiagram
    actor C as Customer
    participant App
    participant UPI as UPI app
    participant API
    actor V as Vendor
    C->>App: Settle Payment ₹800
    App->>UPI: upi://pay?pa=vendor@upi&am=800.00&tn=SupplyBiz ORD...
    UPI-->>App: return (result unreliable)
    App->>C: "Did you complete payment?"
    C->>App: Yes
    App->>API: POST payment-claim (PENDING)
    API-->>V: Push "Payment claim ₹800"
    V->>API: Confirm
    API->>API: Post CREDIT
    API-->>C: Push "Payment recorded"
```

### J-07 Grocery voice/image (US-280) — POST-DELIVERY SR-01
Future journey reference only; not active navigation or acceptance.
Services → Grocery → vendor → Voice Order or Image to Order → permission pre-prompt → capture → detected items list (edit) → Add All to Cart → Cart → checkout.

### J-08 Admin KYC review (US-401)
Login + TOTP → KYC queue → open case → view docs & API results → Approve / Reject(reason) → vendor notified → audit log entry.

## 5. Deep-Link Entry Points
| Link | Target | Role |
|---|---|---|
| `/o/{orderId}` | Order details/tracking | Vendor or customer (per ownership) |
| `/v/{vendorId}` | Vendor details | Customer |
| `/s/{subscriptionId}` | Subscription detail | Both |
| `/khata/{vendorId}` | Customer vendor ledger | Customer |
| `/invite/{code}` | Install/referral attribution | Guest |
Unauthenticated deep links are stored and resumed after login. Details in [MOBILE_STRATEGY §4](../04-architecture/MOBILE_STRATEGY.md#4-deep-links).

## 6. Open Questions
Q-10 (customer nav), Q-16 (cancel after accept), Q-35 (vendor list "+" button).

## 7. Approved delivery journeys
SR-01–SR-06 are approved under ADR-024: the navigation diagrams above omit deferred screens; future J-07 is excluded. Manual KYC and admin plan assignment/extension are required before the discovery/order journey can pass. Plan changes show assigned validity/limits and support assistance, without a checkout. Reports show tables and CSV export; location/address flows use forms/optional GPS coordinates with server coverage validation. Android is the only runtime/test/release target; iOS validation follows actual Android release in T-185 (ADR-025).
