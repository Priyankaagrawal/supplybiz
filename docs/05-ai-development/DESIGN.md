# DESIGN — UI Implementation Guidance

| Field | Value |
|---|---|
| Status | Draft v0.1 |
| Owner | UX/UI Designer + Mobile Lead |
| Last updated | 2026-10-19 |
| Related | [UI_UX_GUIDELINES](../03-ux/UI_UX_GUIDELINES.md) (tokens & components — source of truth), [SCREEN_SPECIFICATIONS](../03-ux/SCREEN_SPECIFICATIONS.md) |

## 1. Purpose
How to turn the design system and screen specs into Flutter code consistently. This file does not repeat tokens; it explains how to apply them.

## 2. Design Principles in Code
| Principle | Implementation |
|---|---|
| One source of tokens | `packages/ui_kit/lib/src/tokens/` (`SbColors`, `SbSpacing`, `SbRadius`, `SbTypography`) → exposed via `ThemeData` + `ThemeExtension<SbTheme>`. No hex literals or magic numbers in features |
| Compose, don't fork | Features use `Sb*` components; if a variant is missing, add it to `ui_kit` (with golden test) rather than styling locally |
| Status consistency | Always render statuses via `SbStatusBadge(status)`; mapping lives in one place |
| Money & dates | Always `SbAmountText` / `formatInr`, `formatDate(context, date)`; never `toString()` |
| States first | Each screen builds `AsyncValue.when(loading, error, data)` with `SbSkeleton`/`SbError`/`SbEmpty` before the happy path |
| Accessibility built-in | `Sb*` components set semantics; features pass `semanticLabel` for icons-only buttons |

## 3. Theme Setup
```dart
// packages/ui_kit/lib/src/theme/sb_theme.dart (illustrative)
ThemeData sbLightTheme(Locale locale) => ThemeData(
  useMaterial3: true,
  colorScheme: SbColors.lightScheme,          // primary #1E88E5, etc.
  textTheme: SbTypography.textTheme(locale),  // Noto Sans / Noto Sans Devanagari
  extensions: const [SbTheme.light],          // status colors, metric tile tints, CTA accent
);
```
Platform adaptivity: use `Theme.of(context).platform` only inside `ui_kit` adaptive components (`SbDialog.adaptive`, `SbDatePicker`), not in features.

## 4. Screen Composition Template
```
Scaffold
 ├─ SbAppBar(title, actions)               // or SbGradientHeader for Home/Dashboard
 ├─ SbOfflineBanner (if offline)
 ├─ body: RefreshIndicator → CustomScrollView (slivers)
 │     ├─ header/summary slivers (metrics, filters)
 │     └─ SliverList.builder (paginated) + footer loader
 └─ bottom: SbStickyCta (primary action) | SbBottomNav (shell)
```
- Keep primary CTA reachable above the keyboard (`SbStickyCta` handles insets).
- Use slivers for long screens to avoid nested scroll views.

## 5. Mapping Mockups to Components
| Mockup element | Component |
|---|---|
| Metric tiles (dashboard) | `SbMetricTile` in `SbGrid(columns: 2)` |
| Category grid (WF-1) | `SbCategoryTile` in `SbGrid(columns: 3/4 responsive)` |
| Vendor card (WF-2) | `SbVendorCard` (image, rating, badges, quick add) |
| Product row with −/+ (WF-3/4/8) | `SbProductRow` + `SbQuantityStepper` |
| Plan radio cards (WF-6) | `SbSelectableCard` + `SbTag('Most Popular')` |
| Order timeline (WF-10) | `SbStepper.horizontal` |
| Ledger list (WF-11) | `SbLedgerTile` grouped by date + `SbMonthSelector` |
| Bottom navigation | `SbBottomNav` (vendor 5 / customer 5 items) |
| Filter tabs (All/New/…) | `SbFilterChips` with counts |

## 6. Imagery & Icons
- Product placeholders by product type (milk bottle, curd bowl, paneer, ghee jar) bundled as optimized WebP/SVG.
- Illustrations for empty states: single style, ≤ 30 KB each (assets TBD).
- Icons: Material Symbols Rounded via a subset font; filled variant for selected nav.

## 7. Motion
- Durations: 150 ms (micro), 250 ms (screen transitions default platform).
- No decorative looping animations; respect `MediaQuery.disableAnimations`.

## 8. Hindi Layout Rules
- Never set fixed widths on text containers; allow 2 lines for labels and buttons.
- Test every screen with `hi` locale and text scale 1.3 in golden tests.
- Numbers remain Western Arabic digits (0–9) in both locales (common in Indian apps; confirm with PO).

## 9. Golden Tests
Each `Sb*` component and each key screen (marked in TASKS) has golden tests: EN/HI × light × text scale 1.0/1.3 × small (320 dp) and baseline (390 dp) widths.

## 10. Design Handoff
Final high-fidelity designs (Figma or equivalent) are **TBD**. Until available, `Wireframe.png` + these specs are authoritative; agents must not invent new visual styles.
