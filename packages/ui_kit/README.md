# Supply Biz UI kit (T-009)

Shared Flutter components from UI_UX_GUIDELINES §3–5. Import
`package:ui_kit/ui_kit.dart`, install `SbLocalizations.delegates` and
`SbLocalizations.supportedLocales` on `MaterialApp`, and use
`sbLightTheme(Localizations.localeOf(context))` below the app's localization boundary.
The v1 theme is light only.

Package copy lives in `lib/l10n/ui_en.arb` and `ui_hi.arb`. The package delegate
loads the ARB assets; consumers supply localized feature labels, slot labels,
weekday names, plan descriptions and error details. Hindi copy is machine
translated and marked `@@x-reviewNeeded` pending T-174. No feature screen or
server integration is implemented here. Upload validation is a client-side
preflight; server validation remains authoritative (TC-503).

All amounts are integer paise, formatted by `formatInr` / `SbAmountText`.
The date selector accepts business calendar dates, not UTC instants; T-010 owns
instant-to-IST formatting. Selection widgets are controlled by their callers.
Charts convert integer display values to doubles only at the chart rendering
boundary; calculations and formatted currency remain integer based.

`fl_chart` 0.69.2 is the chart dependency already selected in ARCHITECTURE §3.
It is MIT licensed, pure Dart, maintained upstream, and adds no native SDK.
Both chart variants include an accessible table. Nonessential chart animation
and skeleton animation are disabled. Buttons have minimum 48dp targets; large
CTAs have minimum 52dp height and grow with text. Medium/small variants use
44/36dp minimum visual height with Material's padded 48dp hit area. Small buttons
are restricted to non-primary variants.

Fonts: Noto Sans and Noto Sans Devanagari, weights 400/500/600/700, bundled
under SIL OFL (`assets/fonts/OFL.txt`). Source:
https://github.com/notofonts/noto-fonts/tree/main/hinted/ttf
Subsets retain Latin-1, Devanagari, joiners, INR and common punctuation, including
OpenType shaping closure. Combined font payload is under 900KB. Package font
families include the package prefix; fonts never require a network request.
Rounded Material icons use Flutter's existing icon font and release tree shaking.

Verification (from this package):

```sh
flutter test test/src/components_test.dart
flutter test test/src/golden_test.dart
# After visually reviewing an intentional design change:
flutter test --update-goldens test/src/golden_test.dart
```

Golden catalogs cover every component in EN/HI × 320/390dp × 1.0/1.3 text scale.
Widget checks cover TC-502 and TC-610/611/613, plus client-side upload preflight,
quantity bounds, loading-button suppression, search cancellation and chart tables.
Manual TalkBack/VoiceOver journeys (TC-612) remain part of T-172.

Verification status: a complete 19-test UI run passed before final global font
fallback changes. Real-font checks then exposed Hindi helper-text contrast;
the 14sp semibold fix is implemented but its rerun was denied execution permission.
Refresh and visually inspect the eight committed goldens before marking T-009 done;
their current images precede that final helper/error/counter style change.
Workspace analysis, TS checks, API unit/e2e tests and the no-op Dart codegen check
passed earlier. Full OpenAPI client codegen stopped at the missing Java runtime
after generating unchanged OpenAPI/TS outputs; T-009 changes no API/schema.
