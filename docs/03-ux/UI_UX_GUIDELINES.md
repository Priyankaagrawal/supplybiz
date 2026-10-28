# UI/UX GUIDELINES — Design System

| Field | Value |
|---|---|
| Status | Draft v0.1 |
| Owner | UX/UI Designer |
| Last updated | 2026-10-19 |
| Related | [DESIGN](../05-ai-development/DESIGN.md) (implementation guidance), [SCREEN_SPECIFICATIONS](SCREEN_SPECIFICATIONS.md) |

## 1. Purpose
Source of truth for design tokens, components, accessibility and platform conventions. Derived from DOC §6 and `Wireframe.png`. Final brand assets (logo, illustrations) are **TBD**.

## 2. Principles
1. **Clarity over density** — one primary action per screen, large numerals for money and quantities.
2. **Hindi-first readiness** — layouts tolerate 30–40% longer strings; never truncate amounts.
3. **Status at a glance** — consistent colour + icon + text for every status (never colour alone).
4. **Forgiving** — confirm destructive actions; undo where possible (e.g., removing cart item).
5. **Fast on low-end devices** — flat layouts, cached images, minimal animation.

## 3. Design Tokens

### 3.1 Colour
| Token | Hex | Usage | Contrast note |
|---|---|---|---|
| `primary` | #1E88E5 | Brand blue: app bar accents, selected tab, icons, large text | 3.7:1 on white → **only for ≥ 18 pt text/icons** |
| `primaryStrong` | #1565C0 | Body-size text/links on white, filled buttons with white text | 5.8:1 ✓ |
| `primaryContainer` | #E3F2FD | Hero/background tints | — |
| `accent` (CTA) | #2E7D32 | Primary CTAs ("Order Now", "Add to Cart", "Continue") | White text 5.1:1 ✓ |
| `accentContainer` | #E8F5E9 | Add buttons, success tints | — |
| `success` / `successContainer` | #067647 / #DCFAE6 | Delivered, Active, Verified, Paid | ✓ |
| `warning` / `warningContainer` | #B54708 / #FEF0C7 | Pending, New, Low stock | ✓ |
| `error` / `errorContainer` | #B42318 / #FEE4E2 | Cancelled, Rejected, Failed, Inactive, Payable | ✓ |
| `info` / `infoContainer` | #175CD3 / #D1E9FF | Out for delivery, Scheduled | ✓ |
| `surface` | #FFFFFF | Cards | — |
| `background` | #F5F8FC | Screen background | — |
| `onSurface` | #101828 | Primary text | 17:1 ✓ |
| `onSurfaceVariant` | #475467 | Secondary text | 7.5:1 ✓ |
| `outline` | #D0D5DD | Dividers, input borders | — |
| Metric tile pastels | #E3F2FD, #E8F5E9, #FFF4E5, #F3E8FF | Dashboard tiles (text uses `onSurface`) | — |

Header gradient: `primary` → `accent` at 20% opacity overlay (DOC §6). Dark mode: **not in v1** (TBD).

### 3.2 Status badge mapping
| Status | Colour | Icon |
|---|---|---|
| NEW, PENDING, PENDING_APPROVAL, Low stock | warning | clock |
| ACCEPTED (Confirmed), PREPARING (Packed) | info | check-circle / package |
| OUT_FOR_DELIVERY, Scheduled | info | truck |
| DELIVERED, ACTIVE, VERIFIED, PAID, Settled | success | check |
| CANCELLED, REJECTED, FAILED, INACTIVE, Payable | error | x-circle |
| PAUSED | onSurfaceVariant on #F2F4F7 | pause |

### 3.3 Typography
Font: **Noto Sans** + **Noto Sans Devanagari** (bundled, subset). Respect OS text scaling up to 200%.

| Style | Size/Line (sp) | Weight | Usage |
|---|---|---|---|
| displaySmall | 28/36 | 700 | Hero headlines |
| headlineSmall | 22/30 | 700 | Screen titles (large) |
| titleMedium | 17/24 | 600 | App bar, card titles |
| bodyLarge | 16/24 | 400 | Primary body |
| bodyMedium | 14/20 | 400 | Secondary body |
| labelLarge | 15/20 | 600 | Buttons |
| labelSmall | 12/16 | 500 | Badges, captions (min size) |
| amountLarge | 24/32 | 700, tabular figures | Totals, metric values |

Implementation note (T-009): status badges, bottom navigation labels, and field
helper/error/counter text use 14 sp / 20 sp at weight 600 for Hindi legibility.
The 12 sp token remains available for captions. All Material text styles,
including field helper/error styles, inherit the bundled locale font and fallback.

### 3.4 Spacing, shape, elevation
- 4-pt grid: 4, 8, 12, 16, 20, 24, 32. Screen padding 16; card padding 12–16; list gap 12.
- Radius: cards 16, buttons 12, inputs 12, chips 20 (pill), bottom sheets 24 (top).
- Elevation: cards 0 with 1 px outline or 1 dp shadow; bottom nav 2 dp; sheets 4 dp.
- Iconography: rounded line icons (Material Symbols Rounded), filled when selected; colour-coded by function.

## 4. Components (Flutter package `ui_kit`, prefix `Sb`)
| Component | Variants / notes |
|---|---|
| `SbButton` | primary (accent), secondary (outline primaryStrong), tertiary (text), destructive; sizes L (52 h, full-width CTA), M (44), S (36 — only non-primary, still 48 hit area); loading state |
| `SbIconButton` | min 48×48 hit area |
| `SbTextField` | label, helper, error, prefix (₹, +91), counter; numeric/amount variants |
| `SbOtpField` | 6 boxes, autofill |
| `SbQuantityStepper` | −/value/+ ; min/max; long-press repeat; announces value |
| `SbChip` / `SbFilterChips` | filter tabs (All/New/…) with counts |
| `SbStatusBadge` | maps status enum → colour/icon/label (§3.2) |
| `SbMetricTile` | label, value (amountLarge), optional delta, tint |
| `SbCard`, `SbListTile` | product, vendor, order, customer, ledger entry variants |
| `SbProductRow` | image, name, unit, price, stepper/Add |
| `SbAmountText` | RULE-01 formatting, tabular figures, semantics "rupees" |
| `SbDateSelector`, `SbMonthSelector`, `SbTimeSlotPicker`, `SbWeekdayPicker` | |
| `SbBottomSheet`, `SbDialog` (confirm/destructive) | |
| `SbSearchBar` | debounce 300 ms |
| `SbEmpty`, `SbError`, `SbSkeleton`, `SbOfflineBanner`, `SbLockedFeature`, `SbSyncChip` | global states |
| `SbStepper` | order timeline & onboarding steps |
| `SbUploadField` | type/size validation, preview, progress, retry |
| `SbBottomNav` | 5 items max, labels always visible |
| `SbChart` (bar, pie) | wraps `fl_chart`; includes accessible data table alternative |

## 5. Accessibility (NFR-010)
- Contrast ≥ 4.5:1 text, ≥ 3:1 large text/icons/UI boundaries.
- Touch targets ≥ 48×48 dp (Android) / 44×44 pt (iOS).
- Every interactive element has a semantic label in both languages; images decorative unless informative.
- Amounts read as "eight hundred rupees"; statuses read with text, not colour.
- Charts provide a "View as table" alternative.
- Focus order follows visual order; errors announced via live region.
- Support OS text scaling to 200%: layouts wrap; no fixed-height text containers.
- Reduce-motion respected (disable non-essential animations).
- Test with TalkBack and VoiceOver ([TEST_STRATEGY §6](../07-testing/TEST_STRATEGY.md)).

## 6. Responsive Layout
| Width (dp) | Behaviour |
|---|---|
| < 360 | Compact: 2-column grids become 2 narrow columns; metric tiles stack; stepper compact |
| 360–480 | Baseline design (mockups) |
| > 480 (large phones/tablets) | Content max-width 560 centred; grids up to 4 columns |
Portrait-only on phones. Safe areas respected (notches, gesture bars). Keyboard never covers focused field or primary CTA (scroll into view).

## 7. Platform Guidelines
| Topic | Android | iOS |
|---|---|---|
| Back navigation | System back / predictive back (Android 14+); confirm before discarding forms | Swipe-back gesture; same discard confirmation |
| Date/time pickers | Material pickers | Cupertino-style via adaptive widgets |
| Dialogs | Material `AlertDialog` | `CupertinoAlertDialog` (adaptive) |
| Haptics | Light on stepper/confirm | Same (UIImpactFeedback light) |
| Share | Android sharesheet | UIActivityViewController |
| Permissions copy | Runtime rationale before system dialog | Info.plist purpose strings (EN/HI) |
| Fonts | Bundled Noto | Bundled Noto (consistency for Hindi) |

## 8. Content & Microcopy
- Tone: friendly, simple, respectful ("आप"). Avoid jargon; "Khata" kept as-is in both languages.
- Numbers: Indian grouping; dates `12 Sep 2025` (EN) / `12 सित॰ 2025` (HI); time `7:00 AM`.
- Error messages state what happened + what to do ("No internet. Your delivery update is saved and will sync automatically.").

## 9. Open Items
Logo/illustrations, dark mode, Hindi copy review by native speaker, final CTA wording "Place Order".
