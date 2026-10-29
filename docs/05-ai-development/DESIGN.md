# DESIGN — UI Implementation Guidance

| Field | Value |
|---|---|
| Status | Draft v0.1 |
| Owner | UX/UI Designer + Mobile Lead |
| Last updated | 2026-10-29 |
| Related | [UI_UX_GUIDELINES](../03-ux/UI_UX_GUIDELINES.md) (tokens & components — source of truth), [SCREEN_SPECIFICATIONS](../03-ux/SCREEN_SPECIFICATIONS.md) |

## 1. Purpose
How to turn the design system and screen specs into Flutter code consistently. This file does not repeat tokens; it explains how to apply them.

## 2. Design Principles in Code
| Principle | Implementation |
|---|---|
| One source of tokens | `packages/ui_kit/lib/src/tokens/` (`SbColors`, `SbSpacing`, `SbRadius`, `SbTypography`) → exposed via `ThemeData` + `ThemeExtension<SbTheme>`. No hex literals or magic numbers in features |
| Compose, don't fork | Features use `Sb*` components; if a variant is missing, add it to `ui_kit` (with focused widget checks) rather than styling locally |
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
  textTheme: SbTypography.textTheme(locale),  // Noto Sans
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

## 8. Readability and accessibility
Use English ARB strings, flexible widths, wrapping labels, 48dp interactive targets and text scale up to 200%. Never truncate amounts. Check representative narrow-screen layouts with widget assertions and manual review at module completion.

## 9. Visual verification
Use focused widget tests and module-level manual UI review. Screenshot baseline generation, refresh commands, font/locale snapshot matrices and related tooling are removed from the delivery plan (ADR-023). Existing implementation cleanup belongs to T-183; no baseline update is a task gate.

Approved SR-01–SR-06 applicability is defined in DELIVERY_SCOPE/ADR-024. Preserve security and shared iOS source/configuration; current mobile builds/runs/tests/releases are Android-only until Android production release, with iOS validation tracked separately in T-185 (ADR-025). Do not add deferred provider, telemetry, navigation or platform prerequisites. This revision changes documentation only.
