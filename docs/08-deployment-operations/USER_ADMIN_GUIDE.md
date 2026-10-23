# USER & ADMIN GUIDE

| Field | Value |
|---|---|
| Status | Draft v0.1 — finalize with real screenshots before launch (T-177) |
| Owner | Product Manager + Ops |
| Last updated | 2026-10-19 |
| Related | [USER_FLOWS](../03-ux/USER_FLOWS.md), [SRS](../02-requirements/SRS.md) |

> This guide is the basis for in-app FAQs (CMS, EN/HI) and support training. Items marked TBD depend on open questions.

## 1. Getting Started (everyone)
1. Install **Supply Biz** from Google Play or the App Store.
2. Choose language: English or हिन्दी (changeable later in Settings).
3. Enter your mobile number, accept Terms & Privacy, tap **Send OTP** (or **Continue with WhatsApp**).
4. Enter the 6-digit code (auto-filled on most phones).
5. Choose **I want to buy** (Customer) or **I sell / supply** (Vendor). You can add the other role later from Profile/More → *Switch*.

## 2. Vendor Guide
### 2.1 Register your business
Category → Business details (name, optional GST, address, map pin, shop photo) → KYC (Aadhaar front/back with first 8 digits covered, PAN, bank details, UPI ID) → Submit. Verification usually completes automatically; otherwise our team reviews it (SLA TBD). You can add products and customers meanwhile, but customers find you only after verification and an active plan.

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
More → Plans. Your plan sets how many customers you can manage and which features are available (Subscriptions & Delivery from Standard; Auto-accept, Stock alerts and Advanced reports from Business). Purchase method TBD (Q-03).

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
| Track spending | Khata → Money (or Profile) |
| Pay bills | Services → bill category (availability TBD, Q-07) |
| Grocery by voice/photo | Services → Grocery → vendor → Voice Order / Image to Order → check items → Add All to Cart |
| Rate a vendor | Orders → delivered order → Rate |

## 4. Admin Guide (web)
| Task | Steps | Role |
|---|---|---|
| Sign in | Email + password → authenticator code (set up on first login) | All |
| Review KYC | KYC Queue → open oldest → compare documents & API results → Approve or Reject with reason. Document views are logged | OPS |
| Suspend vendor | Vendors → vendor → Suspend (reason) | OPS |
| Block customer | Customers → customer → Block | OPS |
| Manage categories | Categories → enable / coming soon / hide; order; icons | OPS |
| Plans & pricing | Plans → edit price/limits/features (affects new purchases) | FINANCE |
| Grant/extend plan | Vendor → Plan → Extend (reason, audited) | FINANCE |
| Banners/FAQs/legal | Content → … (EN + HI) ; legal changes create new version | OPS |
| Force update / flags | Config → minVersion per platform; feature flags | SUPER_ADMIN |
| Broadcast | Broadcasts → segment → message EN/HI → schedule | OPS |
| Moderate reviews | Reviews → Hide/Restore | SUPPORT |
| Deletion/export requests | Data Requests → process within policy (Q-20) | SUPER_ADMIN |
| Audit | Audit Log → filter by actor/entity | SUPER_ADMIN |
Admin role definitions are proposed pending Q-25.

## 5. FAQ
| Question | Answer |
|---|---|
| Does Supply Biz take my money? | No. You pay your vendor directly (cash/UPI). Supply Biz only records it. (Vendors pay Supply Biz only for their plan.) |
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
| UPI app doesn't open (iPhone) | Copy the vendor's UPI ID or scan QR shown, pay, then tap "I've paid" |
| Location wrong | Tap location at top of Home → search or use current location |
| Voice order not understanding | Speak slowly, one item at a time, or use Image to Order / type |
| Support | Help & Support → Call / Email (contact TBD, Q-30) |
