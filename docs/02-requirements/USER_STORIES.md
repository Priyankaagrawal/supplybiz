# USER STORIES — Stories, Business Rules, Acceptance Criteria

| Field | Value |
|---|---|
| Status | Draft v0.1 |
| Owner | Business Analyst + Product Manager |
| Last updated | 2026-10-19 |
| Related | [SRS](SRS.md), [USER_FLOWS](../03-ux/USER_FLOWS.md), [TEST_CASES](../07-testing/TEST_CASES.md), [TASKS](../05-ai-development/TASKS.md) |

## 1. Conventions
- Format: **US-xxx** — story — `FR refs` · priority. Acceptance criteria (AC) use Given/When/Then and are directly testable; each AC maps to at least one `TC-xxx`.
- Global ACs apply to every story unless stated: loading/empty/error states per [SCREEN_SPECIFICATIONS §2](../03-ux/SCREEN_SPECIFICATIONS.md#2-global-state-patterns); EN/HI strings; accessibility per NFR-010.

## 2. Business Rules
| ID | Rule | FR |
|---|---|---|
| RULE-01 | Money is stored as integer paise; displayed as ₹ with Indian digit grouping (₹1,20,000); paise shown only if non-zero. | All |
| RULE-02 | Order status changes only via transitions in [SRS §4.1](SRS.md#41-order). | FR-044 |
| RULE-03 | Reject requires a reason; "Other" requires text of 5–200 chars. | FR-043 |
| RULE-04 | Customer can cancel only while order is NEW (Q-16). | FR-242 |
| RULE-05 | Cart holds items of one vendor only. | FR-220 |
| RULE-06 | One-time order qty ≥ MOQ and ≤ current stock. Subscription orders are generated regardless of stock; low stock triggers an alert. | FR-225, FR-074 |
| RULE-07 | No subscription order is generated for a date that is: not a selected delivery day, before start/after end, inside a pause, skipped, a vendor holiday, while vendor delivery is paused, or when vendor is suspended/plan inactive (Q-04). | FR-074 |
| RULE-08 | Subscription changes made before cutoff (21:00 IST D-1) affect date D; after cutoff they affect D+1 onward. | FR-073, FR-232 |
| RULE-09 | Ledger entries are append-only; corrections use a reversal entry referencing the original with a reason. | FR-116 |
| RULE-10 | DEBIT is posted when an order becomes DELIVERED or a customer quick sale completes; CREDIT is posted when a payment is recorded or a claim confirmed. If payment is collected at delivery, both entries are posted. | FR-111 |
| RULE-11 | Walk-in POS sales must be fully paid (Paid = Total). | FR-053 |
| RULE-12 | Active linked customers per vendor ≤ plan customer limit; exceeding attempts return `PLAN_CUSTOMER_LIMIT` with upgrade prompt. | FR-061, FR-122 |
| RULE-13 | Customers see only vendors that are VERIFIED, not suspended, with active plan, serving the selected location. | FR-017, FR-210 |
| RULE-14 | Subscription orders use subscription price (else selling price). | FR-036 |
| RULE-15 | Orders store a price snapshot; later product price changes do not alter existing orders or subscriptions' generated orders. Subscriptions use the price current at generation time. | FR-032 |
| RULE-16 | Monthly estimate = daily amount × count of selected weekdays in the calendar month between max(start, 1st) and min(end, last day). | FR-071 |
| RULE-17 | A product with ACTIVE/PAUSED subscriptions cannot be deleted (only deactivated after subscriptions end). | FR-033 |
| RULE-18 | Payment claim amount must be > 0 and ≤ current due to that vendor. | FR-253 |
| RULE-19 | OTP: 6 digits, 5 min TTL, resend after 30 s, ≤ 5 sends/hour/number, ≤ 5 attempts/OTP. | FR-003 |
| RULE-20 | A holiday or delivery pause cancels NEW/ACCEPTED/PREPARING orders on affected dates; OUT_FOR_DELIVERY orders are unaffected. | FR-083, FR-084 |
| RULE-21 | One review per DELIVERED order; reviewer must be the order's customer. | FR-213 |
| RULE-22 | Editing verified KYC/bank/business-name fields sets KYC to PENDING. | FR-131 |
| RULE-23 | A user cannot place orders with their own vendor business. | FR-225 |
| RULE-24 | Business dates (delivery date, holidays, reports) use IST; storage uses UTC. | All |
| RULE-25 | Order number format `ORD` + zero-padded sequence (e.g., ORD00012345), unique platform-wide. | FR-041 |

## 3. Stories

### Epic E-01 Authentication & Roles
**US-001** As a user, I want to log in with my mobile number and an OTP so that I don't need a password. — FR-001–FR-004 · P0
- AC1: Given a valid 10-digit number starting 6–9, when I tap "Send OTP", then an SMS OTP is sent and the OTP screen shows a 30 s resend timer.
- AC2: Given an invalid number, then "Send OTP" stays disabled and an inline error is shown.
- AC3: Given the correct OTP within 5 min, when I submit, then I am logged in; given 5 wrong attempts, then the OTP is invalidated and I must resend.
- AC4: When I tap "Change number", then I return to the number screen with my number prefilled.

**US-002** As a user, I want to receive my OTP on WhatsApp so that I can log in when SMS is delayed. — FR-002 · P0
- AC1: When I choose "Continue with WhatsApp", then the OTP is sent via WhatsApp and the OTP screen indicates the channel.

**US-003** As a new user, I want to choose whether I am a customer or a vendor so that I see the right app. — FR-005 · P0
- AC1: Given first login, then I see role selection; choosing Vendor starts onboarding; choosing Customer opens Home.
- AC2: Given I hold both roles, when I tap "Switch to Vendor/Customer", then the shell changes without re-login and the role is remembered on next launch.

**US-004** As a user, I want to use the app in Hindi so that I understand everything. — FR-007 · P0
- AC1: On first launch I pick English or हिन्दी; all UI text, dates and numbers render in that locale; changing language in settings applies instantly.

**US-005** As a user, I want to stay logged in securely and log out from all devices. — FR-006 · P0
- AC1: Given an expired access token, when the app calls the API, then it refreshes silently; given a reused refresh token, then all sessions are revoked and I'm logged out.
- AC2: When I choose "Logout from all devices", then other devices are logged out on their next API call.

**US-006** As a user, I want to delete my account. — FR-008 · P0
- AC1: When I confirm deletion with OTP, then I am logged out and cannot log in to the deleted account; vendors with receivables see a warning first.

**US-007** As a user, I want to accept the terms and privacy policy before signing up. — FR-009 · P0
- AC1: Account creation is blocked until consent is given; consent version and timestamp are stored.

### Epic E-02 Vendor Onboarding & KYC
**US-010** As a vendor, I want to pick my business category. — FR-010 · P0
- AC1: All admin-enabled categories are listed with icons; Dairy/Milk is first; one selection is required to continue.

**US-011** As a vendor, I want to enter my business information and shop photo. — FR-011, FR-012, FR-016 · P0
- AC1: Required fields validated inline; GSTIN validated only if entered; pincode 6 digits.
- AC2: Files > 5 MB or other types are rejected with a message; images are compressed before upload.
- AC3: If I close the app mid-way, I resume at the same step with data preserved.

**US-012** As a vendor, I want to submit KYC and bank details so that I become verified. — FR-013–FR-015 · P0
- AC1: Account number must match its confirmation; IFSC format validated; bank name auto-filled from IFSC when available.
- AC2: On submit, status becomes PENDING; on API success it becomes VERIFIED and I get a notification; on API failure it moves to MANUAL_REVIEW.
- AC3: If REJECTED, I see the reason and can resubmit.

**US-013** As a vendor, I want to know that I'm not visible to customers until verified. — FR-017 · P0
- AC1: While not VERIFIED, dashboard shows a status banner; my shop does not appear in customer search or lists.

**US-014** As a vendor, I want to set my service area. — FR-018 · P0
- AC1: I can set a radius (1–20 km) on a map and/or pincodes; customers outside cannot order.

### Epic E-03 Vendor Dashboard
**US-020** As a vendor, I want to see today's business at a glance. — FR-020–FR-023 · P0
- AC1: Metrics match server values for the selected IST date; changing date refreshes metrics.
- AC2: Offline, the last cached metrics show with a "last updated" time.

### Epic E-04 Products
**US-030** As a vendor, I want to add milk products with prices and stock. — FR-030, FR-036 · P0
- AC1: Name, type, unit and selling price are required; subscription price ≤ selling price; MOQ ≥ 1.
- AC2: Saved product appears in the list and (if active and vendor visible) to customers.

**US-031** As a vendor, I want to find, edit, deactivate or delete products. — FR-031–FR-034 · P0
- AC1: Search and filters work together; inactive products are hidden from customers and POS.
- AC2: Deleting a product with active subscriptions is blocked with an explanation (RULE-17).

**US-032** As a vendor, I want stock to update automatically and be warned when low. — FR-035 · P0
- AC1: Delivering an order of 2 packs reduces stock by 2; manual adjustment requires a reason.
- AC2: On BUSINESS+, when stock ≤ threshold a Low Stock notification is sent once per crossing.

### Epic E-05 Vendor Orders
**US-040** As a vendor, I want to see and filter my orders. — FR-040, FR-041 · P0
- AC1: Filters and search combine; list paginates; order details show all fields in FR-041.

**US-041** As a vendor, I want to accept or reject new orders. — FR-042–FR-044 · P0
- AC1: Accept moves NEW → ACCEPTED and notifies the customer.
- AC2: Reject requires a reason (RULE-03) and notifies the customer with it.
- AC3: Acting on an order already cancelled by the customer shows "Order no longer available" and refreshes.

**US-042** As a vendor, I want to call a customer from an order. — FR-045 · P0
- AC1: Tapping Call opens the dialer with the customer's number.

**US-043** As a vendor, I want to cap daily orders and milk capacity. — FR-046, FR-075 · P1
- AC1: When the cap is reached for a date, customers cannot place new orders for that date and see "Vendor fully booked for this date".

### Epic E-06 Quick Sale
**US-050** As a vendor, I want to record a walk-in sale quickly. — FR-050, FR-052–FR-054 · P0
- AC1: I can add products, change qty/rate, see totals update instantly; Complete Sale requires Paid = Total.
- AC2: Stock decrements; sale appears in reports; works offline and syncs once (no duplicates).

**US-051** As a vendor, I want to record a sale on a customer's Khata. — FR-051, FR-053 · P0
- AC1: Selecting a customer allows Paid < Total; the balance is posted as DEBIT to that customer's Khata.

### Epic E-07 Vendor Customers
**US-060** As a vendor, I want to see and search my customers. — FR-060 · P0
- AC1: Filters All/Active/Subscription/Inactive; search by name or mobile.

**US-061** As a vendor, I want to add a customer who doesn't use the app. — FR-061, FR-064 · P0
- AC1: Mobile must be unique within my customers; adding beyond plan limit shows upgrade prompt (RULE-12).
- AC2: When that person later registers, they get a prompt to link; after acceptance they see my ledger.

**US-062** As a vendor, I want a customer profile with history, subscription and payments. — FR-062, FR-063 · P0
- AC1: Stats equal sums of orders/ledger; tabs show Order History, Current Subscription, Payments; I can mark the customer inactive.

### Epic E-08 Subscriptions
**US-070** As a vendor, I want to create a daily subscription for a customer. — FR-070, FR-071 · P0 (STANDARD+)
- AC1: Daily and monthly amounts are auto-calculated per RULE-16 as I change qty/days/dates.
- AC2: Start date must be ≥ tomorrow; at least one delivery day required.

**US-071** As a vendor, I want subscription orders to be created automatically every day. — FR-074 · P0
- AC1: At 22:00 IST, orders for tomorrow exist for every eligible subscription and none for excluded dates (RULE-07).
- AC2: Re-running the job creates no duplicates.
- AC3: With auto-accept ON (BUSINESS+) orders are ACCEPTED; otherwise NEW.

**US-072** As a vendor, I want to pause, resume, edit or cancel a subscription. — FR-072, FR-073 · P0
- AC1: Paused subscriptions generate no orders; changes follow RULE-08; customer is notified.

**US-073** As a vendor, I want subscription settings (auto-accept, availability window, caps, pause all). — FR-075 · P0
- AC1: Auto-accept toggle is locked below BUSINESS with upgrade prompt; Pause all stops generation for all subscriptions.

**US-074** As a customer, I want to subscribe to daily milk from a vendor. — FR-230, FR-231, FR-076 · P0
- AC1: Plans show computed monthly and per-day prices; Custom Plan lets me pick product, qty, days.
- AC2: After "Continue" and confirmation, the subscription is PENDING_APPROVAL (or ACTIVE if vendor auto-accepts) and I'm notified when approved.

**US-075** As a customer, I want to pause, skip, modify or cancel my subscription. — FR-232, FR-077 · P0
- AC1: Skip before cutoff prevents tomorrow's order; after cutoff the app explains it applies from the day after (RULE-08).
- AC2: Cancel requires confirmation; no further orders are generated.

**US-076** As a customer, I want a monthly statement for my subscription. — FR-233 · P1
- AC1: Statement lists delivered dates, qty, amount, paid, due and matches the vendor ledger.

### Epic E-09 Delivery & Holidays
**US-080** As a vendor, I want today's delivery list and to update status on the go. — FR-080, FR-081 · P0
- AC1: Tabs filter by status; Start Delivery, Mark Delivered (with optional payment collected), Mark Failed (reason) update status and notify the customer.
- AC2: Without network, actions are queued, shown as "Pending sync", and synced automatically in order.

**US-081** As a vendor, I want to mark holidays or pause deliveries. — FR-082–FR-085 · P0
- AC1: A holiday on date D stops generation for D and cancels affected orders (RULE-20); affected customers are notified.
- AC2: Upcoming holidays are listed; deleting a future holiday before generation restores deliveries.

### Epic E-10 Reports
**US-090** As a vendor, I want sales reports for a date range. — FR-090–FR-093, FR-095 · P1
- AC1: Summary values equal the sums of underlying records for the range (IST).
- AC2: Chart and product-wise table are locked below BUSINESS with upgrade prompt.

**US-091** As a vendor, I want to download and share a report. — FR-094 · P1
- AC1: Download generates a file in the agreed format (Q-23) and opens the share sheet.

### Epic E-11 Notifications
**US-100** As a user, I want push and in-app notifications for important events. — FR-100–FR-102, FR-104 · P0
- AC1: Each event in FR-101 produces a push (if permitted) and an in-app item in the right tab.
- AC2: Tapping a notification opens the target screen, switching role after confirmation if needed.

**US-101** As a user, I want to control which notifications I get. — FR-103 · P1
- AC1: Toggling a category off stops pushes of that category; security/KYC cannot be disabled.

### Epic E-12 Vendor Khata & Payments
**US-110** As a vendor, I want a Khata showing what each customer owes. — FR-110, FR-111 · P0
- AC1: Due = Σ DEBIT − Σ CREDIT per customer; tabs All/Receivable/Paid filter correctly.

**US-111** As a vendor, I want to record payments received. — FR-112, FR-114 · P0
- AC1: Recording ₹500 cash posts a CREDIT and reduces due by ₹500; appears in Recent Payments and This Month Received.

**US-112** As a vendor, I want to add opening balances for existing customers. — FR-113 · P0
- AC1: Opening entry requires amount, type and note; it is shown distinctly in the ledger.

**US-113** As a vendor, I want to confirm payments customers say they made. — FR-115 · P0
- AC1: Confirming posts CREDIT; rejecting requires reason and notifies the customer.

**US-114** As a vendor, I want to correct a wrong ledger entry. — FR-116 · P0
- AC1: Correction creates a reversal entry; original remains visible; audit log records actor and reason.

### Epic E-13 Vendor Plans
**US-120** As a vendor, I want to choose and pay for a plan. — FR-120, FR-121, FR-126 · P1
- AC1: Plans show prices for 3 durations, limits and features; entitlement activates only after server-verified payment; invoice available.

**US-121** As a vendor, I want to know when I hit plan limits or my plan expires. — FR-122–FR-125 · P1
- AC1: Locked features show an upgrade prompt; reminders at 7/3/1 days before expiry.

### Epic E-14 Vendor Settings & Help
**US-130** As a vendor, I want to manage business, KYC/bank, delivery and notification settings. — FR-130–FR-132 · P1
- AC1: Editing verified fields shows a warning and sets KYC to PENDING after save (RULE-22).

**US-131** As a vendor, I want help and FAQs and to call support. — FR-133, FR-134 · P1
- AC1: FAQs load in my language by topic; Call Support opens the dialer.

### Epic E-15 Customer Home & Discovery
**US-200** As a customer, I want the app to know my location. — FR-200 · P0
- AC1: With permission, location auto-detects; without it, I can search a city/address; content updates for the selected location.

**US-201** As a customer, I want a home screen with categories and today's deliveries. — FR-201, FR-203 · P0
- AC1: Today's Delivery shows my orders for today with live status; disabled categories show "Coming soon".

**US-202** As a customer, I want to search for vendors and products. — FR-202 · P0
- AC1: Results only include serviceable vendors (RULE-13); empty state suggests changing location.

**US-210** As a customer, I want to browse milk vendors nearby. — FR-210, FR-214 · P0
- AC1: Sorting by Nearby/Popular/Rating works; favorites appear first; outside-area vendors never appear.

**US-211** As a customer, I want vendor and product details. — FR-211, FR-212 · P0
- AC1: Tabs Products/Subscription/Reviews/About load; qty stepper respects MOQ; Add to Cart updates cart badge.

**US-212** As a customer, I want to rate a vendor after delivery. — FR-213 · P1
- AC1: Rating prompt appears for DELIVERED orders; one review per order (RULE-21); vendor average updates.

### Epic E-16 Cart, Checkout & Orders
**US-220** As a customer, I want to review my cart and place an order. — FR-220, FR-221, FR-223, FR-225 · P0
- AC1: Bill shows item total, delivery charge, total; changing qty recalculates.
- AC2: Adding another vendor's item asks to replace the cart (RULE-05).
- AC3: Placing an order validates per FR-225 and shows specific errors; double-tap does not create duplicates.

**US-221** As a customer, I want a quick "Place New Order" screen for milk and water. — FR-224 · P0
- AC1: Tabs Milk & Dairy / Water Can; One Time adds to cart with date/slot; Subscription goes to subscription setup.

**US-222** As a customer, I want to apply a coupon. — FR-222 · P2
- AC1: Blocked until Q-06 is answered; hidden while flag off.

**US-240** As a customer, I want to see my orders and track status. — FR-240, FR-241 · P0
- AC1: Tabs filter correctly; tracking timeline reflects server status within 5 s of push receipt or on refresh.

**US-241** As a customer, I want to cancel or reorder. — FR-242, FR-243 · P0
- AC1: Cancel available only when NEW (RULE-04); reorder adds available items at current prices and lists unavailable ones.

### Epic E-17 Customer Khata & Money
**US-250** As a customer, I want to see what I owe each vendor. — FR-250, FR-251 · P0
- AC1: Vendor ledger matches the vendor's Khata for me; month selector filters entries; totals correct.

**US-251** As a customer, I want to track personal lending/borrowing. — FR-252 · P0
- AC1: Adding "You gave ₹200 to Ravi" increases Receivable by ₹200; entries editable/deletable by me only.

**US-252** As a customer, I want to pay my vendor via UPI from the Khata. — FR-253 · P0
- AC1: Settle opens a UPI app with vendor VPA and amount; after return I confirm and a PENDING claim is created; vendor confirmation updates my ledger.
- AC2: If no UPI app is available (or on iOS fallback), I see VPA, QR and Copy.

**US-260** As a customer, I want to track monthly income and expenses. — FR-260–FR-262 · P1
- AC1: Net Saving = Income − Expense for the month; pie chart percentages sum to 100%.

### Epic E-18 Services, Bills, Grocery
**US-270** As a customer, I want a services directory. — FR-270 · P1
- AC1: Supply categories open vendor lists; bill categories open bill payments (if enabled); others show "Coming soon".

**US-271** As a customer, I want to pay utility bills. — FR-271, FR-272 · P2
- AC1: Blocked pending Q-07; AC to be defined with BBPS partner.

**US-280** As a customer, I want to order groceries by speaking or photographing my list. — FR-280–FR-283 · P2
- AC1: Spoken "2 kilo chawal, 1 litre tel" yields 2 items with quantities; unmatched items are flagged.
- AC2: Photo of a list yields editable detected items; Add All to Cart adds matched items only.
- AC3: Denying mic/camera permission shows rationale and an option to open settings.

### Epic E-19 Profile
**US-290** As a customer, I want to manage my profile and addresses. — FR-290, FR-291 · P0
- AC1: Address requires house, area, city, pincode and map pin; one default address.

**US-291** As a customer, I want insights on my spending. — FR-294 · P1
- AC1: Monthly totals by vendor/category match orders and Money data.

**US-292** As a customer, I want to invite friends. — FR-293 · P2
- AC1: Share link opens app (or store) with referral code attached; rewards TBD (Q-14).

**US-293** As a customer, I want settings, help and about. — FR-292, FR-295–FR-297 · P1
- AC1: All menu items open their screens; Payment Methods per Q-22.

### Epic E-20 Admin Panel
**US-400** As an admin, I want secure login with 2FA and role-based access. — FR-400 · P0
- AC1: Login requires password + TOTP; pages/actions not allowed for my role return 403 and are hidden.

**US-401** As an ops admin, I want to review KYC submissions. — FR-402 · P0
- AC1: Queue lists PENDING/MANUAL_REVIEW oldest first; approve/reject (reason required) updates vendor and notifies them; document views are audit-logged.

**US-402** As an admin, I want to manage vendors and customers. — FR-403, FR-404 · P0
- AC1: Suspending a vendor hides them from discovery immediately and blocks new orders; action audit-logged.

**US-403** As an admin, I want to manage categories, plans, banners, CMS and app config. — FR-405–FR-408 · P0/P1
- AC1: Changes reflect in the app within 5 min (cache TTL); min-version change forces update on older apps.

**US-404** As an admin, I want to broadcast notifications and moderate reviews. — FR-409, FR-410 · P1
- AC1: Broadcast to a segment is delivered and logged; hidden reviews disappear from app and average.

**US-405** As an admin, I want audit logs, data requests and reports. — FR-411–FR-413 · P0/P1
- AC1: Every admin write appears in audit log; deletion requests processed within policy (Q-20).

## 4. Traceability Summary
| Epic | Stories | FRs | Tests |
|---|---|---|---|
| E-01 | US-001–US-007 | FR-001–FR-009 | TC-001–TC-014 |
| E-02 | US-010–US-014 | FR-010–FR-018 | TC-020–TC-029 |
| E-03 | US-020 | FR-020–FR-023 | TC-030–TC-031 |
| E-04 | US-030–US-032 | FR-030–FR-036 | TC-035–TC-041 |
| E-05 | US-040–US-043 | FR-040–FR-046 | TC-045–TC-051 |
| E-06 | US-050–US-051 | FR-050–FR-054 | TC-055–TC-059 |
| E-07 | US-060–US-062 | FR-060–FR-064 | TC-060–TC-064 |
| E-08 | US-070–US-076 | FR-070–FR-077, FR-230–FR-233 | TC-070–TC-084 |
| E-09 | US-080–US-081 | FR-080–FR-085 | TC-085–TC-091 |
| E-10 | US-090–US-091 | FR-090–FR-095 | TC-095–TC-097 |
| E-11 | US-100–US-101 | FR-100–FR-104 | TC-100–TC-104 |
| E-12 | US-110–US-114 | FR-110–FR-116 | TC-110–TC-116 |
| E-13 | US-120–US-121 | FR-120–FR-126 | TC-120–TC-124 |
| E-14 | US-130–US-131 | FR-130–FR-134 | TC-130–TC-132 |
| E-15 | US-200–US-212 | FR-200–FR-214 | TC-200–TC-212 |
| E-16 | US-220–US-241 | FR-220–FR-225, FR-240–FR-243 | TC-220–TC-245 |
| E-17 | US-250–US-260 | FR-250–FR-263 | TC-250–TC-262 |
| E-18 | US-270–US-280 | FR-270–FR-283 | TC-270–TC-283 |
| E-19 | US-290–US-293 | FR-290–FR-297 | TC-290–TC-294 |
| E-20 | US-400–US-405 | FR-400–FR-413 | TC-400–TC-410 |
