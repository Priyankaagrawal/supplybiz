# SCREEN SPECIFICATIONS

| Field | Value |
|---|---|
| Status | Draft v0.1 |
| Owner | UX Designer + Business Analyst |
| Last updated | 2026-10-19 |
| Related | [USER_FLOWS](USER_FLOWS.md), [UI_UX_GUIDELINES](UI_UX_GUIDELINES.md), [SRS](../02-requirements/SRS.md), `Wireframe.png` (customer screens 1–12) |

## 1. Purpose
Inventory of every screen with behaviour, validation and states. Visual tokens/components are in [UI_UX_GUIDELINES](UI_UX_GUIDELINES.md). Mockup references: **WF-n** = panel *n* of `Wireframe.png`; **DOC §x** = source document section.

## 2. Global State Patterns
Every data screen implements these states using shared components (`SbLoading`, `SbEmpty`, `SbError`, `SbOfflineBanner`).

| State | Behaviour |
|---|---|
| Loading (first) | Skeleton placeholders matching layout; no spinners for > 300 ms content |
| Loading (refresh) | Pull-to-refresh indicator; keep stale content visible |
| Empty | Illustration + one-line message + primary action (e.g., "Add your first product") |
| Error (recoverable) | Inline message + Retry; keep cached data if any |
| Offline | Top banner "You're offline — showing saved data (updated hh:mm)"; write actions either queued (vendor outbox list, NFR-007) or disabled with tooltip |
| Locked by plan | Content blurred/greyed + lock icon + "Available on BUSINESS plan" + Upgrade CTA |
| Permission denied | Rationale + "Open Settings" |
| Session expired | Silent refresh; if fails → logout to S-COM-03 with message |
| Validation | Inline under field on blur and on submit; first invalid field focused and announced |
| Destructive action | Confirmation dialog naming the object ("Delete Cow Milk 1 L?") |
| Success | Snackbar (4 s) ; critical successes (order placed, sale completed) use a success screen/sheet |

Lists: paginated (cursor, 20 per page), infinite scroll with footer loader, pull-to-refresh.

## 3. Screen Inventory

### 3.1 Common
| ID | Screen | FR | Notes |
|---|---|---|---|
| S-COM-01 | Splash | — | Checks config (force update), session, role; ≤ 1 s beyond native splash |
| S-COM-02 | Language select | FR-007 | English / हिन्दी cards; persisted locally and to profile after login |
| S-COM-03 | Mobile number | FR-001, FR-009 | +91 fixed prefix; numeric keyboard; "Send OTP" + "Continue with WhatsApp"; consent checkbox with Terms/Privacy links; trust messages (Secure Registration • Quick & Easy Setup • Start Supplying Today) |
| S-COM-04 | OTP | FR-003, FR-004 | 6 boxes, autofill; resend timer 30 s; "Change number"; errors: wrong OTP (remaining attempts), expired, too many requests (show wait time) |
| S-COM-05 | Role select | FR-005 | Two cards: "I want to buy" (Customer) / "I sell / supply" (Vendor) |
| S-COM-06 | Force update | FR-408 | Blocking; "Update" opens store |
| S-COM-07 | Maintenance / no service | — | Remote-config driven message |
| S-COM-08 | Legal/FAQ webview | FR-134 | Rendered CMS markdown, not external browser |
| S-COM-09 | Notification permission pre-prompt | FR-101 | Shown after first meaningful action, not at launch |
| S-COM-10 | Account deletion | FR-008 | Consequences list, OTP confirmation |

### 3.2 Vendor
| ID | Screen | FR | Source |
|---|---|---|---|
| S-V-01 | Business category | FR-010 | DOC §3.1 step 3 |
| S-V-02 | Business information | FR-011, FR-012 | DOC §3.1 step 4 |
| S-V-03 | KYC & bank details | FR-013, FR-014 | DOC §3.1 step 5 |
| S-V-04 | Verification status | FR-015, FR-017 | Badges Not Verified/Pending/Verified/Rejected |
| S-V-05 | Dashboard | FR-020–FR-023 | DOC §3.2 |
| S-V-06 | Product list | FR-031, FR-034 | DOC §3.3 |
| S-V-07 | Add/Edit product | FR-030, FR-032, FR-035 | DOC §3.3 |
| S-V-08 | Order list | FR-040 | DOC §3.4 |
| S-V-09 | Order details | FR-041–FR-045 | DOC §3.4 |
| S-V-10 | Reject reason sheet | FR-043 | DOC §3.4 |
| S-V-11 | Quick Sale (POS) | FR-050–FR-054 | DOC §3.5 |
| S-V-12 | Customer list | FR-060 | DOC §3.6 |
| S-V-13 | Add/Edit customer | FR-061 | — |
| S-V-14 | Customer detail | FR-062, FR-063 | DOC §3.6 |
| S-V-15 | Create/Edit subscription | FR-070–FR-073 | DOC §3.7 |
| S-V-16 | Deliveries | FR-080, FR-081 | DOC §3.8 |
| S-V-17 | Reports | FR-090–FR-095 | DOC §3.9 |
| S-V-18 | Notifications | FR-100–FR-102 | DOC §3.10 |
| S-V-19 | More menu | — | DOC §3.13 (Staff hidden, Q-29) |
| S-V-20 | Settings | FR-130 | DOC §3.11 |
| S-V-21 | Subscription settings | FR-075 | DOC §3.11 |
| S-V-22 | Availability & holidays | FR-082–FR-085 | DOC §3.11 |
| S-V-23 | Khata list | FR-110 | DOC §3.12 |
| S-V-24 | Customer ledger detail | FR-110, FR-116 | — |
| S-V-25 | Record payment / opening balance sheet | FR-112, FR-113 | — |
| S-V-26 | Payments & collection (incl. claims) | FR-114, FR-115 | DOC §3.12 |
| S-V-27 | Plans | FR-120 | DOC §3.13 |
| S-V-28 | Plan checkout & status / invoices | FR-121, FR-124, FR-126 | — |
| S-V-29 | Help & FAQ | FR-133 | DOC §3.11 |
| S-V-30 | Service area | FR-018 | DOC §3.13 |
| S-V-31 | Delivery settings | FR-132 | — |
| S-V-32 | Notification settings | FR-103 | — |
| S-V-33 | Profile / business / KYC edit | FR-131 | — |
| S-V-34 | Sync queue (pending offline actions) | NFR-007 | — |
| S-V-35 | Stock adjustment sheet | FR-035 | — |

### 3.3 Customer
| ID | Screen | FR | Source |
|---|---|---|---|
| S-C-01 | Home | FR-200–FR-203 | WF-1, DOC §4.1 |
| S-C-02 | Location picker | FR-200 | — |
| S-C-03 | Search | FR-202 | — |
| S-C-04 | Services | FR-270 | DOC §4.4 |
| S-C-05 | Vendor list | FR-210, FR-214 | WF-2 |
| S-C-06 | Vendor details | FR-211 | WF-3, DOC §4.6 |
| S-C-07 | Vendor products | FR-211 | WF-4 |
| S-C-08 | Product details | FR-212 | WF-5 |
| S-C-09 | Subscription plans | FR-230 | WF-6 |
| S-C-10 | Subscription setup / custom | FR-231 | — |
| S-C-11 | Cart & checkout | FR-220–FR-223, FR-225 | WF-7 |
| S-C-12 | Place new order | FR-224 | WF-8, DOC §4.7 |
| S-C-13 | My orders | FR-240 | WF-9 |
| S-C-14 | Order tracking / details | FR-241–FR-243 | WF-10 (map removed) |
| S-C-15 | My subscriptions | FR-232 | — |
| S-C-16 | Subscription manage / statement | FR-232, FR-233 | — |
| S-C-17 | Khata | FR-250 | DOC §4.2 |
| S-C-18 | Vendor ledger | FR-251 | WF-11 |
| S-C-19 | Add personal entry / contact | FR-252 | — |
| S-C-20 | Settle payment sheet | FR-253 | WF-11 |
| S-C-21 | Money | FR-260–FR-262 | DOC §4.3 |
| S-C-22 | Add transaction | FR-261 | — |
| S-C-23 | Bill payments | FR-271 | DOC §4.8 |
| S-C-24 | Bill pay flow | FR-272 | — (TBD Q-07) |
| S-C-25 | Grocery voice/image order | FR-280–FR-283 | DOC §4.8 |
| S-C-26 | Notifications | FR-100–FR-102 | DOC §4.8 |
| S-C-27 | Profile | FR-290 | WF-12, DOC §4.5 |
| S-C-28 | Addresses | FR-291 | DOC §4.8 |
| S-C-29 | Add/Edit address | FR-291 | — |
| S-C-30 | Payment methods | FR-292 | (Q-22) |
| S-C-31 | Invite & earn | FR-293 | (Q-14) |
| S-C-32 | Reports & insights | FR-294 | — |
| S-C-33 | App settings | FR-295, FR-103 | — |
| S-C-34 | Help & support | FR-296 | — |
| S-C-35 | Write review | FR-213 | — |
| S-C-36 | Edit profile | FR-290 | — |
| S-C-37 | Favorites | FR-214 | — |
| S-C-38 | Link vendor account prompt | FR-064 | — |

### 3.4 Admin (web, desktop ≥ 1280 px; tablet ≥ 768 px read-only acceptable)
| ID | Screen | FR |
|---|---|---|
| S-A-01 | Login + TOTP (+ TOTP enrolment) | FR-400 |
| S-A-02 | Dashboard | FR-401 |
| S-A-03 | KYC queue | FR-402 |
| S-A-04 | KYC case detail | FR-402 |
| S-A-05 | Vendors list | FR-403 |
| S-A-06 | Vendor detail (profile, KYC, plan, badges, suspend) | FR-403 |
| S-A-07 | Customers list/detail | FR-404 |
| S-A-08 | Categories | FR-405 |
| S-A-09 | Plans | FR-406 |
| S-A-10 | Vendor plan subscriptions & payments | FR-406 |
| S-A-11 | Banners & coupons | FR-407 |
| S-A-12 | CMS (FAQ, legal) | FR-408 |
| S-A-13 | App config & feature flags | FR-408 |
| S-A-14 | Broadcast notifications | FR-409 |
| S-A-15 | Review moderation | FR-410 |
| S-A-16 | Audit log | FR-411 |
| S-A-17 | Admin users & roles | FR-400 |
| S-A-18 | Data-subject requests | FR-412 |
| S-A-19 | Reports export | FR-413 |

## 4. Detailed Specifications (key screens)

### S-COM-03 / S-COM-04 Login
| Element | Rule |
|---|---|
| Mobile field | `^[6-9]\d{9}$`; strips spaces; paste supported |
| Send OTP | Enabled when valid + consent checked; shows loader; errors: `RATE_LIMITED` → "Try again in mm:ss" |
| OTP boxes | Auto-advance, paste 6 digits, auto-submit on 6th digit |
| Accessibility | OTP field exposed as single text field to screen readers |

### S-V-02 Business information
| Field | Type | Validation |
|---|---|---|
| Shop/Business Name* | text | 2–80 chars |
| GST Number | text, uppercase | optional; `^\d{2}[A-Z]{5}\d{4}[A-Z][1-9A-Z]Z[0-9A-Z]$` |
| Address* | multiline | 5–200 chars |
| City* / State* | text / dropdown | required |
| Pincode* | numeric | `^[1-9]\d{5}$` |
| Shop location* | map pin | lat/lng required; "Use current location" |
| Shop photo | file | JPG/PNG/PDF ≤ 5 MB; preview; replace |
Stepper header shows step 2 of 4. Primary CTA "Save & Continue" (saves draft server-side).

### S-V-03 KYC & bank
Sections: Aadhaar (front/back upload; app shows mask guidance and applies auto-masking where detectable — manual masking tool fallback), PAN (upload + PAN number `^[A-Z]{5}\d{4}[A-Z]$`), Bank (holder name, IFSC → bank/branch lookup, account no. + confirm, masked display after save), UPI ID (`^[\w.\-]{2,256}@[a-zA-Z]{2,64}$`). Security note: "Used only for verification". Screenshots blocked on this screen (Android FLAG_SECURE; iOS blur on app switcher). CTA "Submit for verification".

### S-V-05 Dashboard
Header (photo, shop name, location, Verified badge), date chip (Today ▾), 4 primary metric tiles (pastel backgrounds) in 2×2 grid, 3 secondary tiles, quick-action grid, KYC/plan banners when applicable. Tiles are tappable → filtered lists. States: offline cached; unverified banner; plan expired banner.

### S-V-07 Add/Edit product
Fields per FR-030. Unit chips: 250 ml / 500 ml / 1 L / Other (reveals value + unit dropdown). Price fields with ₹ prefix, numeric with 2 decimals. "Milk Type" visible only when type = Milk. Save disabled until valid. Edit mode shows Delete (RULE-17) and "Adjust stock".

### S-V-09 Order details
Sections: status stepper (New → Accepted → Out for Delivery → Delivered), customer card (Call), items table (Product, Price, Qty, Total), bill summary, payment method/status, source badge. Bottom actions by status: NEW → [Reject] [Accept]; ACCEPTED → [Mark Packed] [Start Delivery]; OUT_FOR_DELIVERY → [Failed] [Mark Delivered]. Mark Delivered opens sheet: "Payment collected?" Yes (method, amount, default = total) / No (added to Khata).

### S-V-11 Quick Sale
Segmented control: Sale on POS | Customer Sale (search field appears). Product picker (search, chips). Table rows: Product, Qty (−/+), Rate (editable), Amount, Delete. Footer: Total Items, Total Amount; Payment Status (Paid/Not Paid); Method (Cash/UPI/Other); Paid Amount; Balance (read-only). Validation RULE-11. CTA "Complete Sale" → success sheet with "New sale" / "Share receipt" (receipt share TBD).

### S-V-15 Create subscription
Customer selector (search + "New"), product (with price), qty/day stepper + unit display, delivery days chips (Mon–Sun, "Daily" shortcut), start date, end date (optional), slot, payment method, status (edit mode: Active/Pause/Cancel). Live summary: Daily ₹, Monthly ₹ (estimate per RULE-16). Locked below STANDARD.

### S-V-16 Deliveries
Date selector (default today), status tabs with counts, cards sorted by slot then address. Card actions per status; Call. Pending-sync chip on cards modified offline. Empty: "No deliveries for this date".

### S-V-22 Availability & holidays
Toggle "Accepting deliveries today"; "Pause deliveries" (with optional resume date); "Mark Holiday" (date picker ≥ today, reason ≤ 100 chars) → confirm dialog shows affected order count; Upcoming holidays list with delete.

### S-C-01 Home (WF-1)
Header: logo, location selector, bell. Search bar. Hero banner carousel (admin). Category grid (8 tiles: Milk & Dairy, Water Can, Tiffin, Laundry, Grocery, Fruits & Veg, Food & Restaurant, More). Milk sub-grid (Cow Milk, Buffalo Milk, Toned Milk, Curd, Paneer, Ghee) as in WF-1. "Today's Delivery" list (product, vendor, slot, status chip) + View All. Empty: "No deliveries today — Order now".

### S-C-06 Vendor details (WF-3)
Cover image, favorite heart, name, rating (count), distance, badges; tabs Products | Subscription | Reviews | About. Products tab rows with −/+ steppers. Sticky CTA "View Subscription Plans".

### S-C-09 Subscription plans (WF-6)
Radio cards: 1 L Daily (₹/month, ₹/day, "Most Popular"), 500 ml Daily, 2 L Daily, Custom Plan. Feature list (Free delivery*, Pause or skip anytime, Monthly billing, Manage from app). CTA "Continue" → S-C-10. *Shown only if delivery charge = 0.

### S-C-11 Cart & checkout (WF-7)
Vendor name in title; item rows with steppers and line totals; Apply Coupon row (hidden while flag off); Bill details (Item total, Delivery charge or "₹0 (Free)", Total); address selector; date & slot; payment mode radio (Pay on delivery – Cash/UPI; Add to Khata). CTA "Place Order" (renamed from "Proceed to Pay" since no online payment — confirm with PO). Errors from FR-225 mapped to messages next to affected items.

### S-C-12 Place new order (WF-8)
Tabs One Time | Subscription; category tabs Milk & Dairy | Water Can; product rows with steppers + unit; Delivery Date (date field); Delivery Time chips (7–8 AM, 8–9 AM, 9–10 AM from vendor settings); CTA "Add to Cart".

### S-C-14 Order tracking (WF-10)
Order no., product, date, status chip; 4-step timeline Confirmed → Packed → Out for Delivery → Delivered (timestamps); vendor card with Call (replaces "Delivery partner" in WF-10); delivery address. Map omitted (F-D3). Cancel button when NEW; Rate button when DELIVERED.

### S-C-18 Vendor ledger (WF-11)
Month selector; summary tiles Total Payable (red tint) / Total Paid (green tint); entries grouped by date (product, qty, amount, Pending/Paid). CTA "Settle Payment" → S-C-20 (amount default = payable, editable per RULE-18).

### S-C-25 Grocery voice/image
Top segmented: Search | Voice Order | Image to Order. Voice: large mic button, waveform, live transcript, language chip (EN/HI). Image: camera/gallery. Detected Items list: name, matched product, qty stepper, remove; unmatched rows with "Find" action. CTA "Add All to Cart (n)".

## 5. Edge Cases Checklist
- [ ] Vendor suspended while customer on vendor page → order placement returns `VENDOR_UNAVAILABLE`.
- [ ] Price changed between cart and placement → server re-prices; app shows "Prices updated" and requires re-confirm.
- [ ] Order cancelled by customer while vendor viewing → action returns 409; UI refreshes.
- [ ] Role switch with pending vendor outbox → sync continues in background; switch allowed.
- [ ] Very long Hindi strings → wrap to 2 lines, never truncate amounts.
- [ ] Device date/time wrong → server time used for cutoffs; app displays server-provided cutoff.
- [ ] Notification for other role → confirm role switch.

## 6. Open Questions
Q-10, Q-22, Q-35; CTA wording "Place Order" vs "Proceed to Pay"; receipt sharing for Quick Sale.
