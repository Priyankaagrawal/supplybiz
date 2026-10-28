# TEST CASES

| Field | Value |
|---|---|
| Status | Draft v0.1 |
| Owner | QA Engineer |
| Last updated | 2026-10-19 |
| Related | [TEST_STRATEGY](TEST_STRATEGY.md), [USER_STORIES](../02-requirements/USER_STORIES.md), [SRS](../02-requirements/SRS.md) |

## 1. Conventions
- **Level:** U = unit, W = widget, A = API e2e, E = mobile/admin E2E, M = manual.
- Times are IST. "Clock" = injected test clock. Amounts in ₹ for readability (stored in paise).
- Each TC references FR/US/RULE. Tests in code include the TC ID in their name, e.g. `test('TC-081 skip before cutoff …')`.

## 2. Authentication & Roles (E-01)
| ID | Scenario | Steps / Input | Expected | Refs | Level |
|---|---|---|---|---|---|
| TC-001 | Valid mobile enables Send OTP | Enter 9876543210, tick consent | Button enabled; OTP sent; timer 30 s | FR-001, US-001 | W, A |
| TC-002 | Invalid mobile | 5876543210 / 98765 / letters | Button disabled; inline error | FR-001 | W |
| TC-003 | Correct OTP | Verify within 5 min | Tokens returned; user created on first login | FR-003 | A, E |
| TC-004 | Wrong OTP 5 times | 5 wrong codes | 5th → `OTP_ATTEMPTS_EXCEEDED`; correct code then fails | RULE-19 | A |
| TC-005 | Expired OTP | Clock +5 min 1 s | `OTP_EXPIRED` | FR-003 | A |
| TC-006 | Resend limits | 6 sends within 1 h | 6th → `RATE_LIMITED` with Retry-After; resend before 30 s rejected | RULE-19 | A |
| TC-007 | WhatsApp channel | channel=WHATSAPP | Sent via WhatsApp adapter; UI shows channel | FR-002, US-002 | A, W |
| TC-008 | Role selection & switch | New user → Vendor; later add Customer; switch | Correct shell; role persisted after restart | FR-005, US-003 | E |
| TC-009 | Refresh rotation & reuse | Use refresh token twice | 2nd use → `REFRESH_REUSED`; all family sessions revoked | FR-006, US-005 | A |
| TC-010 | Logout all devices | Two sessions, logout all | Other session's next call → 401 | FR-006 | A |
| TC-011 | Force update | minVersion > app version | S-COM-06 blocking; API returns 426 for old version header | FR-408 | W, A |
| TC-012 | Account deletion | Request with OTP | Logged out; login creates no access to old data; vendor with dues warned | FR-008, US-006 | A, E |
| TC-013 | Consent required | Verify without consent for new user | 400 `VALIDATION_FAILED`; consent stored with version when given | FR-009, US-007 | A |
| TC-014 | Language switch | Change to हिन्दी | All visible strings Hindi; numbers formatted ₹1,20,000 | FR-007, US-004 | W, E |

## 3. Vendor Onboarding (E-02)
| ID | Scenario | Expected | Refs | Level |
|---|---|---|---|---|
| TC-020 | Category required | Continue disabled until selected | FR-010 | W |
| TC-021 | Business info validation | Name 1 char → error; bad GSTIN → error; empty GSTIN ok; pincode 5 digits → error | FR-011 | W, A |
| TC-022 | Resume onboarding | Kill app on step 3 → relaunch resumes step 3 with data | FR-016 | E |
| TC-023 | Upload > 5 MB / .docx | Rejected with message; nothing uploaded | FR-012, FR-013 | W, A |
| TC-024 | Bank validation | Account confirmation mismatch → error; IFSC `SBIN0001234` valid, `SBIN1001234` invalid | FR-014 | W |
| TC-025 | KYC API success | FakeKyc success → VERIFIED; push sent | FR-015 | A |
| TC-026 | KYC API failure | → MANUAL_REVIEW; appears in admin queue | FR-015 | A |
| TC-027 | Unverified vendor hidden | Vendor PENDING not in customer list/search | FR-017, RULE-13 | A |
| TC-028 | Service area | Radius 3 km: customer at 2.9 km sees vendor, 3.1 km does not; pincode list adds coverage | FR-018 | A |
| TC-029 | Aadhaar masking | Stored doc flagged masked; full number never persisted; API returns last-4 only | FR-013, A-10 | A |

## 4. Dashboard (E-03)
| ID | Scenario | Expected | Refs | Level |
|---|---|---|---|---|
| TC-030 | Metrics correctness | Fixture: 5 orders today (2 NEW, 3 DELIVERED ₹450) → Today 5, Pending 2, Completed 3, Sales ₹450 | FR-021 | A |
| TC-031 | Offline dashboard | Airplane mode → cached tiles + "updated hh:mm" banner | NFR-007 | E |

## 5. Products (E-04)
| ID | Scenario | Expected | Refs | Level |
|---|---|---|---|---|
| TC-035 | Create product valid | Saved; appears in list | FR-030 | A, W |
| TC-036 | Subscription price > selling | Validation error | FR-030 | W, A |
| TC-037 | Search + filter | "cow" + Milk → only matching | FR-031 | W |
| TC-038 | Inactive hidden | Inactive not in customer products or POS | FR-034 | A |
| TC-039 | Delete with active subscription | 409 `PRODUCT_IN_USE` | RULE-17 | A |
| TC-040 | Stock decrement | Deliver order qty 2 → stock −2; stock_movement recorded | FR-035 | A |
| TC-041 | Low stock alert | Stock crosses threshold (BUSINESS plan) → one notification; BASIC → none | FR-035 | A |

## 6. Vendor Orders (E-05)
| ID | Scenario | Expected | Refs | Level |
|---|---|---|---|---|
| TC-045 | Filters & search | Status filter + "ORD000123" returns correct set | FR-040 | A, W |
| TC-046 | Accept | NEW → ACCEPTED; customer push | FR-042 | A |
| TC-047 | Reject with reason | Missing reason → 400; "Other" with 3 chars → 400; valid → REJECTED + push with reason | FR-043, RULE-03 | A |
| TC-048 | Invalid transition | DELIVERED → ACCEPTED → 409 `INVALID_STATE_TRANSITION` | FR-044 | A |
| TC-049 | Version conflict | Two accepts with same version → second 409 `VERSION_CONFLICT` | ARCH §7 | A |
| TC-050 | Call customer | Tap Call → dialer with number | FR-045 | E |
| TC-051 | Capacity reached | max_daily_orders=1, one order exists → new order 422 `CAPACITY_REACHED` | FR-046 | A |

## 7. Quick Sale (E-06)
| ID | Scenario | Expected | Refs | Level |
|---|---|---|---|---|
| TC-055 | Walk-in fully paid | Total ₹130, paid ₹130 → sale saved, stock decremented | FR-050, FR-054 | A |
| TC-056 | Walk-in partial | Paid ₹100 of ₹130 → 422 `WALKIN_MUST_BE_PAID` | RULE-11 | A, W |
| TC-057 | Customer sale with balance | Paid ₹100 of ₹130 → DEBIT 130, CREDIT 100, due +30 | FR-053, RULE-10 | A |
| TC-058 | Totals live update | Change qty/rate → amount & total update | FR-052 | W |
| TC-059 | Offline sale sync once | Offline complete sale → kill app → online → exactly one sale on server | FR-054, NFR-007 | E |

## 8. Vendor Customers (E-07)
| ID | Scenario | Expected | Refs | Level |
|---|---|---|---|---|
| TC-060 | List filters/search | Correct subsets | FR-060 | A |
| TC-061 | Duplicate mobile | Same mobile twice for vendor → 409 `DUPLICATE` | FR-061 | A |
| TC-062 | Plan limit | BASIC with 100 active → add 101st → 422 `PLAN_CUSTOMER_LIMIT`; inactive not counted | RULE-12 | A |
| TC-063 | Customer stats | Totals equal sums of orders & ledger | FR-062 | A |
| TC-064 | Link offline customer | Register with matching mobile → link prompt → accept → customer sees ledger | FR-064 | A, E |

## 9. Subscriptions (E-08)
| ID | Scenario | Expected | Refs | Level |
|---|---|---|---|---|
| TC-070 | Amount calculation | 1 × ₹48, Mon–Sun, Oct 2026 (31 days) → daily ₹48, monthly ₹1,488; Mon/Wed/Fri → ₹48 × 13 = ₹624 | RULE-16 | U |
| TC-071 | Start date validation | Start today → error; tomorrow ok; no weekday → error | FR-070 | W, A |
| TC-072 | Customer subscription pending | Vendor auto-accept off → PENDING_APPROVAL; vendor approves → ACTIVE + push | FR-076 | A |
| TC-073 | Auto-accept subscription | BUSINESS + auto-accept → ACTIVE immediately | FR-076 | A |
| TC-074 | Pause range | Pause 10–12 → no orders those dates; resumes 13 | FR-072, RULE-07 | A |
| TC-075 | Skip before cutoff | Clock 20:59 D-1, skip D → no order for D | FR-077, RULE-08 | A |
| TC-076 | Skip after cutoff (customer) | Clock 21:01 D-1 → 422 `PAST_CUTOFF` with message; vendor can still skip (cancels generated order) | RULE-08 | A |
| TC-077 | Modify qty | Change before cutoff → D uses new qty; after → D+1 | FR-232, RULE-08 | A |
| TC-078 | Pause all subscriptions setting | No orders generated for vendor | FR-075 | A |
| TC-079 | Cancel | No future orders; status CANCELLED | FR-072 | A |
| TC-080 | Generation eligibility matrix | Property test: random subscriptions/holidays/pauses/skips/weekdays → orders exactly match RULE-07 oracle | FR-074 | U |
| TC-081 | Generation idempotency | Run job twice for same date → no duplicates (unique constraint) | FR-074 | A |
| TC-082 | Generation timing | Scheduler triggers at 22:00 IST (16:30 UTC) | FR-074 | U |
| TC-083 | Price at generation | Subscription price changed before job → new orders use new price; old orders unchanged | RULE-14, RULE-15 | A |
| TC-084 | Job failure alert | Simulated worker failure → job_runs not SUCCESS by 22:30 → alert fired | NFR-006 | A (staging) |

## 10. Delivery & Holidays (E-09)
| ID | Scenario | Expected | Refs | Level |
|---|---|---|---|---|
| TC-085 | Delivery tabs & counts | Counts per tab correct for date | FR-080 | A |
| TC-086 | Start delivery | ACCEPTED → OUT_FOR_DELIVERY; customer push | FR-081 | A |
| TC-087 | Delivered with payment | DEBIT + CREDIT posted; paymentStatus PAID; stock decremented | FR-081, RULE-10 | A |
| TC-088 | Offline delivered then conflict | Customer cancelled (NEW) while vendor offline marks delivered → sync 409 → local rollback + message | NFR-007 | E |
| TC-089 | Holiday cancels orders | Holiday on D with 3 ACCEPTED, 1 OUT_FOR_DELIVERY → 3 CANCELLED, 1 unchanged; customers notified | RULE-20 | A |
| TC-090 | Pause/resume delivery | Paused → no generation; resume → generation next run | FR-084 | A |
| TC-091 | Delete holiday before generation | Orders generated normally | FR-085 | A |

## 11. Reports (E-10)
| ID | Scenario | Expected | Refs | Level |
|---|---|---|---|---|
| TC-095 | Summary correctness | Fixture range → each card equals SQL oracle | FR-091 | A |
| TC-096 | Plan gating | BASIC: chart/product endpoints 403 `PLAN_FEATURE_LOCKED`; UI locked state | FR-095 | A, W |
| TC-097 | Export | Export job completes; file downloadable via short-lived URL; share sheet opens | FR-094 | A, E |

## 12. Notifications (E-11)
| ID | Scenario | Expected | Refs | Level |
|---|---|---|---|---|
| TC-100 | Inbox tabs | Items categorized per role tabs | FR-100 | A, W |
| TC-101 | Mark read / clear all | State persisted | FR-102 | A |
| TC-102 | Preferences | Offers off → no offer push; KYC cannot be disabled | FR-103 | A |
| TC-103 | Event coverage | Each FR-101 event produces push + inbox item | FR-101 | A |
| TC-104 | Deep link with role switch | Vendor-role user taps customer notification → confirm → customer shell target screen | FR-104 | E |

## 13. Vendor Khata (E-12)
| ID | Scenario | Expected | Refs | Level |
|---|---|---|---|---|
| TC-110 | Balance invariant | After random sequence of entries, due = ΣDEBIT − ΣCREDIT = ledger_balances.due | FR-110 | U, A |
| TC-111 | Record payment | ₹500 cash → CREDIT; due −500; recent payments updated | FR-112 | A |
| TC-112 | Opening balance | Requires note; displayed as OPENING | FR-113 | A |
| TC-113 | Confirm claim | PENDING claim → confirm → CREDIT; customer push | FR-115 | A |
| TC-114 | Reject claim | Reason required; no CREDIT; customer push | FR-115 | A |
| TC-115 | Immutability | Attempt UPDATE/DELETE on ledger_entries via DB role → permission denied | FR-116 | A |
| TC-116 | Reversal | Reverse entry → opposite entry referencing original; audit log row | FR-116 | A |

## 14. Plans (E-13)
| ID | Scenario | Expected | Refs | Level |
|---|---|---|---|---|
| TC-120 | Feature gating per tier | Matrix test per PRD §5 for all gated endpoints | FR-123 | A |
| TC-121 | Customer limit per tier | 100/250/500/1000 boundaries | FR-122 | A |
| TC-122 | Purchase activation | Entitlement only after verified payment/webhook; replayed webhook ignored | FR-121 | A (blocked Q-03) |
| TC-123 | Expiry reminders | Notifications at 7/3/1 days and expiry | FR-124 | A |
| TC-124 | Plans screen | Prices/limits/features displayed; Most Popular on BUSINESS | FR-120 | W |

## 15. Settings & Help (E-14)
| ID | Scenario | Expected | Refs | Level |
|---|---|---|---|---|
| TC-130 | Re-verification | Edit bank account → KYC PENDING; warning shown before save | RULE-22 | A, W |
| TC-131 | Delivery settings | Delivery charge reflected in customer bill | FR-132 | A |
| TC-132 | FAQs localized | `Accept-Language: hi` returns Hindi FAQs | FR-133 | A |

## 16. Customer Home & Discovery (E-15)
| ID | Scenario | Expected | Refs | Level |
|---|---|---|---|---|
| TC-200 | Location permission denied | Manual search works; content loads | FR-200 | E |
| TC-201 | Home content | Banners, categories (coming soon disabled), today's deliveries with status | FR-201 | A, W |
| TC-202 | Search serviceable only | Results exclude out-of-area/unverified/suspended | FR-202, RULE-13 | A |
| TC-203 | Search empty | Empty state suggests changing location | FR-202 | W |
| TC-204 | Sort Nearby | Ordered by distance asc | FR-210 | A |
| TC-205 | Sort Rating | Ordered by rating desc, ties by count | FR-210 | A |
| TC-206 | Suspended vendor | Disappears immediately; open page → order fails `VENDOR_UNAVAILABLE` | FR-403 | A |
| TC-207 | Vendor details tabs | All tabs load; About shows delivery charge & holidays | FR-211 | W |
| TC-208 | Product MOQ | Stepper min = MOQ | FR-212 | W |
| TC-209 | Favorites | Favorite appears first in list | FR-214 | A |
| TC-210 | Pagination | 45 vendors → 3 pages, no duplicates | FR-210 | A |
| TC-211 | Review once | Second review for same order → 409 | RULE-21 | A |
| TC-212 | Rating aggregate | Hidden review excluded from average | FR-213 | A |

## 17. Cart, Checkout, Orders (E-16)
| ID | Scenario | Expected | Refs | Level |
|---|---|---|---|---|
| TC-220 | Bill details | Items ₹100+₹30, charge ₹0 → total ₹130, "₹0 (Free)" | FR-221 | W, A |
| TC-221 | Replace cart vendor | Add other vendor item → dialog → replace clears old | RULE-05 | W |
| TC-222 | Below MOQ | 422 `BELOW_MOQ` mapped to item | FR-225 | A, W |
| TC-223 | Out of stock | 422 `OUT_OF_STOCK` | FR-225 | A |
| TC-224 | Not serviceable | Address outside area → `NOT_SERVICEABLE` | FR-225 | A |
| TC-225 | Holiday date | Delivery date = holiday → `VENDOR_HOLIDAY` | FR-225 | A |
| TC-226 | Price changed | expectedTotal mismatch → 409 `PRICE_CHANGED` + new quote; UI asks re-confirm | FR-225 | A, W |
| TC-227 | Idempotent place | Same Idempotency-Key twice → one order, same response | FR-225 | A |
| TC-228 | Self order | Vendor user ordering from own shop → `SELF_ORDER_NOT_ALLOWED` | RULE-23 | A |
| TC-229 | Same-day cutoff | After vendor same-day cutoff, today not selectable | FR-223 | W, A |
| TC-230 | Place new order screen | Tabs and slots work; Add to Cart adds selected | FR-224 | W |
| TC-231 | Khata payment mode | Vendor disallows credit → option hidden/rejected | FR-223 | A |
| TC-232 | Coupon hidden | Flag off → Apply Coupon row hidden | FR-222 | W |
| TC-240 | My orders tabs | Ongoing = NEW/ACCEPTED/PREPARING/OUT_FOR_DELIVERY | FR-240 | A |
| TC-241 | Tracking timeline | Status changes reflected after push or refresh | FR-241 | E |
| TC-242 | Cancel when NEW | Allowed; vendor notified | FR-242, RULE-04 | A |
| TC-243 | Cancel after ACCEPTED | 409 (pending Q-16) | RULE-04 | A |
| TC-244 | Reorder | Available items added at current price; unavailable listed | FR-243 | A, W |
| TC-245 | Delivery failed | Customer sees FAILED with reason; no DEBIT | FR-081 | A |

## 18. Customer Khata & Money (E-17)
| ID | Scenario | Expected | Refs | Level |
|---|---|---|---|---|
| TC-250 | Summary | Receivable/Payable/Net correct across vendors + personal | FR-250 | A |
| TC-251 | Vendor ledger parity | Customer view equals vendor ledger for that link | FR-251 | A |
| TC-252 | Month filter | Only entries of selected month; totals per month | FR-251 | A, W |
| TC-253 | Personal entry | "You gave ₹200" → receivable +200; edit/delete own only | FR-252 | A |
| TC-254 | UPI intent Android | Launches `upi://pay` with pa, pn, am, tn; return → confirm dialog | FR-253 | E |
| TC-255 | Claim amount > due | 422 `AMOUNT_EXCEEDS_DUE` | RULE-18 | A |
| TC-256 | iOS fallback | No UPI app → VPA + QR + Copy shown | FR-253, R-11 | E |
| TC-260 | Money summary | Income 30,000 − Expense 12,500 = Net 17,500 | FR-260 | A, W |
| TC-261 | Transaction CRUD | Category required; amount > 0 | FR-261 | A |
| TC-262 | Pie chart | Percentages sum to 100%; table alternative accessible | FR-262 | W |

## 19. Services, Bills, Grocery (E-18)
| ID | Scenario | Expected | Refs | Level |
|---|---|---|---|---|
| TC-270 | Services routing | Supply → vendor list; bill → bills (flag on) or coming soon | FR-270 | W |
| TC-271 | Bill payment | TBD with partner (Q-07) | FR-271–FR-272 | — |
| TC-280 | Voice parse EN/HI | "2 kilo chawal, 1 litre tel" → 2 items with qty | FR-280, FR-282 | A, M |
| TC-281 | Image OCR | Printed & handwritten Devanagari list samples → items detected (accuracy recorded) | FR-281 | M |
| TC-282 | Matching | Unmatched items flagged; Add All adds matched only | FR-282, FR-283 | A, W |
| TC-283 | Mic permission denied | Rationale + Open Settings; no crash | FR-280 | E |

## 20. Profile (E-19)
| ID | Scenario | Expected | Refs | Level |
|---|---|---|---|---|
| TC-290 | Address CRUD & default | One default enforced; pin required | FR-291 | A, W |
| TC-291 | Edit profile | Name/email saved; mobile read-only | FR-290 | W |
| TC-292 | Settings | Language/notification prefs/switch role work | FR-295 | E |
| TC-293 | About | Version & legal links shown | FR-297 | W |
| TC-294 | Insights | Monthly totals equal orders + Money data | FR-294 | A |

## 21. Admin (E-20)
| ID | Scenario | Expected | Refs | Level |
|---|---|---|---|---|
| TC-400 | Login + TOTP | Wrong TOTP rejected; lockout after 5 failures | FR-400 | E |
| TC-401 | RBAC | SUPPORT cannot approve KYC (403, hidden) | FR-400 | A, E |
| TC-402 | KYC approve | Vendor VERIFIED; notification; audit row | FR-402 | A, E |
| TC-403 | KYC doc access log | Viewing doc creates audit row; URL expires in 60 s | FR-402 | A |
| TC-404 | Suspend vendor | Hidden from discovery; cannot accept orders | FR-403 | A |
| TC-405 | Block customer | Cannot log in (`ACCOUNT_BLOCKED`) | FR-404 | A |
| TC-406 | Plan edit | Price change applies to new purchases only | FR-406 | A |
| TC-407 | Config change | Feature flag toggled → app reflects within 5 min | FR-408 | E |
| TC-408 | Audit completeness | Every admin write produces audit row with before/after (PII redacted) | FR-411 | A |
| TC-409 | Broadcast | Segment delivery & log | FR-409 | A |
| TC-410 | Hide review | Removed from app & average | FR-410 | A |

## 22. Cross-Cutting
| ID | Scenario | Expected | Refs | Level |
|---|---|---|---|---|
| TC-500 | Idempotency replay | Same key + same body → same response; no duplicate side effects | API §2 | A |
| TC-501 | Idempotency mismatch | Same key + different body → 422 `IDEMPOTENCY_MISMATCH` | API §2 | A |
| TC-502 | INR formatting | 12000000 paise → "₹1,20,000"; 5050 → "₹50.50" | RULE-01 | U |
| TC-503 | Upload validation | Wrong magic bytes / size → rejected at finalize | ADR-018 | A |
| TC-504 | Outbox app kill | Kill during SENDING → on restart resent with same key; no duplicate | NFR-007 | E |
| TC-505 | IDOR suite | Each endpoint with another tenant's ID → 404 | AUTH_SECURITY §3 | A |
| TC-506 | Log redaction | Logs contain no mobile/OTP/token/PAN/bank patterns | AUTH_SECURITY §6 | U, A |
| TC-507 | UI kit golden catalogs | All shared components render in EN/HI, widths 320/390dp, text scale 1.0/1.3, using bundled fonts | T-009, DESIGN §9 | W |
| TC-508 | UI kit control interactions | Quantity bounds/repeat, loading suppression, search debounce/disposal, chart table access | T-009 | W |
| TC-509 | Upload client preflight | Invalid type/size never reaches upload callback; valid metadata accepted; does not replace server TC-503 | T-009 | W |

## 23. Non-Functional
| ID | Scenario | Expected | Refs | Level |
|---|---|---|---|---|
| TC-600 | Cold start | p90 ≤ 2.5 s on reference Android (10 runs, profile build) | NFR-001 | M |
| TC-601 | Scrolling | Orders list 500 items: janky frames < 1% | NFR-002 | M |
| TC-602 | API load | k6 at target load: p95 within NFR-003 | NFR-003 | M |
| TC-603 | App size | AAB per-ABI download ≤ 40 MB | NFR-013 | CI |
| TC-610 | Tap targets & labels | Guideline tests pass all screens | NFR-010 | W |
| TC-611 | Contrast | textContrastGuideline passes | NFR-010 | W |
| TC-612 | Screen readers | J-01, J-02, J-03, J-06 completable with TalkBack & VoiceOver | NFR-010 | M |
| TC-613 | Text scale 200% | No clipped text/overflow on key screens (EN/HI) | NFR-010 | W, M |
