# Supply Biz UI kit (T-009)

Shared Flutter components from UI_UX_GUIDELINES. Import `package:ui_kit/ui_kit.dart`, install `SbLocalizations.delegates` and `SbLocalizations.supportedLocales` on MaterialApp, and use the shared light theme. Consumers supply feature labels through English strings; currency calculations use integer paise and accessible charts include table alternatives. Selection widgets remain controlled by callers. Server validation is authoritative for uploads.

ADR-023 sets an English-only baseline using `lib/l10n/ui_en.arb` and Noto Sans, with INR/IST formatting and accessibility intact. T-183 removes extra locale/font assets and visual snapshot generation/refresh code, dependencies and baselines. This documentation-only revision leaves package source unchanged; do not assume cleanup or current verification has passed. Prior implementation evidence is retained in Git history.

After each UI task run targeted analyze, lightweight app build, focused behavior/widget checks and screen smoke. At module completion verify representative widths, 200% text, 48dp targets, semantic labels and TalkBack along with comprehensive integrated journeys. No screenshot baseline regeneration is required. Use the actual test scripts/files available after T-183 and record unavailable checks honestly.

Approved SR-01–SR-06 applicability is defined in DELIVERY_SCOPE/ADR-024. Preserve security and shared iOS source/configuration; current mobile builds/runs/tests/releases are Android-only until Android production release, with iOS validation tracked separately in T-185 (ADR-025). Do not add deferred provider, telemetry, navigation or platform prerequisites. This revision changes documentation only.
