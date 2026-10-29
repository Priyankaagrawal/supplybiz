# USER & ADMIN GUIDE

> Target user flows for retained scope, not a claim of current implementation. ROADMAP defines delivery order; approved SR-01–SR-06 backlog in SCOPE §9 is outside this delivery. English is the sole supported language.

| Field | Value |
|---|---|
| Status | Draft v0.1 — finalize with real screenshots before launch (T-177) |
| Owner | Product Manager + Ops |
| Last updated | 2026-10-29 |
| Related | [USER_FLOWS](../03-ux/USER_FLOWS.md), [SRS](../02-requirements/SRS.md) |

> This guide is the basis for in-app FAQs (CMS, English) and support training. Items marked TBD depend on open questions.

## 1. Getting Started (everyone)
1. Install **Supply Biz** on Android from the approved test distribution or Google Play after release; iOS testing/distribution follows Android production release.
2. Continue in English; no language selection is required.
3. Enter your mobile number, accept Terms & Privacy, tap **Send OTP** (or **Continue with WhatsApp**).
4. Enter the 6-digit code (auto-filled on most phones).
5. Choose **I want to buy** (Customer) or **I sell / supply** (Vendor). You can add the other role later from Profile/More → *Switch*.

## 2. Vendor Guide
### 2.1 Register your business
Category → Business details (name, optional GST, address/pincode/coordinates or optional GPS, shop photo) → KYC (Aadhaar front/back with first 8 digits covered, PAN, bank details, UPI ID) → Submit. Our authorized team manually reviews it (SLA TBD), with an audited approval/rejection. Automated provider checks are not run in this release. You can add products and customers meanwhile, but customers find you only after verification and an active plan.

### 2.2 Daily routine
| Task | Where |
|---|---|
| See today's numbers | Home (Dashboard) |
| Accept/reject new orders | Orders → New → open order |
| Deliver | More → Deliveries → Start Delivery → Mark Delivered (record payment if collected) |
| Counter sale | Home → Quick Sale |
| Record a payment | More → Khata → customer → Record Payment |
| Confirm payment a customer reported | More → Payments → Claims |
| Take a day off | Settings → Availability & Holidays → Mark Holiday |

### 2.3 Subscriptions
Customers → select customer → Add Subscription (product, quantity, days, start date). Orders for tomorrow are created automatically every night at 10 PM. Pause, skip a day or cancel from the subscription. Customers can request subscriptions from the app; approve them unless Auto-accept is on (Business plan and above).

### 2.4 Khata
Every delivered order adds to the customer's due; every payment reduces it. Mistakes are corrected with **Reverse entry** (the original stays visible for transparency). Linked customers see the same Khata in their app.

### 2.5 Working offline
Deliveries, payments and quick sales work without internet. They show **Pending sync** and upload automatically when you're online. Don't uninstall the app or log out while items are pending.

### 2.6 Plans
More → Plans. Your plan sets how many customers you can manage and which features are available (Subscriptions & Delivery from Standard; Auto-accept, Stock alerts and Advanced reports from Business). View your current assigned plan and validity; contact support for assignment changes. The admin grants/extends plans with reason/dates and audit. No in-app purchase or invoice flow is available in this release.

## 3. Customer Guide
| Task | How |
|---|---|
| Find milk vendors | Home → Milk & Dairy (or search). Set your location at the top |
| Order once | Vendor → Products → add → Cart → choose address, date, time, payment mode → Place Order |
| Subscribe | Vendor → Subscription → pick plan or Custom → Continue |
| Pause/skip | Profile → My Subscriptions → subscription → Pause / Skip date (before 9 PM for next day) |
| Track today's delivery | Home → Today's Delivery, or Orders |
| See what you owe | Khata → vendor → month |
| Pay vendor | Khata → vendor → Settle Payment → pay in UPI app → confirm "I've paid". The vendor confirms it |
| Personal lending | Khata → Add Entry |

## 4. Admin Guide (web)
| Task | Steps | Role |
|---|---|---|
| Sign in | Email + password → authenticator code (set up on first login) | All |
| Review KYC | KYC Queue → open oldest → review masked documents and bank details; automated checks show NOT_RUN → Approve or Reject with reason. Document views are logged | OPS |
| Suspend vendor | Vendors → vendor → Suspend (reason) | OPS |
| Block customer | Customers → customer → Block | OPS |
| Manage categories | Categories → enable / coming soon / hide; order; icons | OPS |
| Plans & pricing | Plans → edit catalog/limits/features under approved entitlement policy (purchases deferred) | FINANCE |
| Grant/extend plan | Vendor → Plan → Assign/Extend (valid start/end dates, required reason, permission check and audit) | FINANCE |
| FAQs/legal | Content → … (English) ; legal changes create new version | OPS |
| Force update / flags | Config → minVersion per platform; feature flags | SUPER_ADMIN |
| Deletion/export requests | Data Requests → process within policy (Q-20) | SUPER_ADMIN |
| Audit | Audit Log → filter by actor/entity | SUPER_ADMIN |
Admin role definitions are proposed pending Q-25.

## 5. FAQ
| Question | Answer |
|---|---|
| Does Supply Biz take my money? | No. You pay your vendor directly (cash/UPI). Supply Biz only records it. Automated vendor plan billing is deferred; admin plan assignment is not a payment. |
| I paid via UPI but my Khata still shows due | Your payment is pending until the vendor confirms. Contact the vendor; if rejected you'll see the reason |
| Why can't I find my vendor? | They may not serve your location, may not be verified yet, or have no active plan. Check your location |
| I didn't get the OTP | Wait for the timer and resend, or use WhatsApp. Check DND/SMS blocking. Max 5 OTPs per hour |
| Can I change my mobile number? | Not in v1 — TBD |
| Why was tomorrow's milk not skipped? | Changes after 9 PM apply from the day after tomorrow |
| Vendor: why can't I add more customers? | Your plan's customer limit is reached; upgrade or mark inactive customers |
| Vendor: why is my Aadhaar asked to be masked? | Law restricts storing full Aadhaar numbers; we keep only masked copies |

## 6. Troubleshooting
| Problem | Fix |
|---|---|
| App says "Update required" | Update from the store |
| Notifications not arriving | Enable notifications in phone settings; check Settings → Notifications; disable battery optimization for Supply Biz on some Android brands |
| Pending sync stuck | Open More → Sync queue → Retry; ensure internet; if "Failed", read the reason (e.g., order cancelled by customer) |
| UPI app unavailable (Android) | Copy the vendor's UPI ID or scan QR shown, pay, then tap "I've paid" |
| Location wrong | Tap location at top of Home → search or use current location |
| Voice order not understanding | Speak slowly, one item at a time, or use Image to Order / type |
| Support | Help & Support → Call / Email (contact TBD, Q-30) |

## 7. Deferred features and platform phase
Money/insights, voice/image recognition, bill payments, referrals/coupons, saved payment-method management, reviews, marketing banners/broadcasts and automated plan billing/KYC-provider checks are not part of this release (approved SR-01–SR-06). Personal lending entries, direct UPI claims and operational notifications remain. Reports export CSV; no PDF/interactive map requirement. This guide describes target functionality, not implemented status.

All current mobile testing and release preparation is Android-only. Preserve iOS source/configuration; actual iOS builds/runs/testing/signing/TestFlight follows Android production release via T-185, never an Android launch prerequisite.
