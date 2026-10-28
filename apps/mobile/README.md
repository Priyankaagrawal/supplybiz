# Supply Biz Mobile

Flutter entrypoints are `lib/main_dev.dart`, `lib/main_staging.dart`, and
`lib/main_prod.dart`. Use the matching native flavor/scheme and
`config/<flavor>.json` when running or building. Firebase is opt-in per
flavor; see
[`ENVIRONMENT_SETUP.md`](../../docs/06-development/ENVIRONMENT_SETUP.md) for
required native configuration files.

From this directory, run each flavor on an Android emulator or iOS simulator:

```sh
fvm flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json
fvm flutter run --flavor staging -t lib/main_staging.dart --dart-define-from-file=config/staging.json
fvm flutter run --flavor prod -t lib/main_prod.dart --dart-define-from-file=config/prod.json
```

The native flavor, entrypoint and `ENV_NAME` must match. Checked-in API hosts
for staging/prod are placeholders; the skeleton makes no API requests.
Firebase-disabled configs run without Firebase project files. For a Firebase
check, supply the matching native config and set `FIREBASE_ENABLED` to `true`
in a local copy of that flavor's JSON. Android only processes Google Services
for flavors with a config file. Do not add placeholder credentials.

T-008 manual verification:
1. Run all three flavors on Android and iOS; confirm the environment label.
2. Confirm dev/staging/prod install with distinct app identifiers and names.
3. Use a mismatched entrypoint/config; confirm a localized error screen appears
   without raw configuration or provider error text.
4. With valid native Firebase files, enable Firebase for each flavor and confirm
   startup succeeds; without a file, confirm startup shows the error screen.

Focused checks (no native build):
```sh
fvm dart analyze lib test
fvm flutter test --no-pub test/core/config/app_environment_test.dart test/widget_test.dart test/smoke_test.dart
```

T-010 localization and formatting:
- Edit `lib/l10n/app_en.arb` and `app_hi.arb`, then run `fvm flutter gen-l10n`.
  Commit the generated files in `lib/core/l10n/generated`; do not edit them.
  Hindi machine translations carry `@@x-reviewNeeded` for copy review.
- Use `context.l10n` for app strings. The device locale selects EN/HI;
  other languages fall back to English. Language selection/persistence belongs
  to T-016.
- Import `core/utils/money.dart` for the existing shared `formatInr(int paise)`.
  Import `core/utils/dates.dart` for `formatIstDate`, `formatIstDateTime`, and
  `istDateKey`. Pass an instant (UTC or with an explicit offset); omit device-local
  wall-clock parsing for server timestamps. Bootstrap initializes bundled date
  symbols; standalone tests should await `initializeDateFormatters()`.
- Date display accepts `locale: context.l10n.localeName`; business-date keys
  always use Gregorian `yyyy-MM-dd`. These are display helpers, not cutoff logic.
- `flutter_localizations` (Flutter SDK) and `intl` (BSD-3-Clause) are the
  ADR-019/ARCHITECTURE choices, already present in the workspace lockfile;
  this task declares direct imports without upgrading dependencies.

```sh
fvm flutter gen-l10n
fvm dart analyze lib test
fvm flutter test --no-pub test/core/utils test/widget_test.dart
```

T-010 manual verification (use the dev run command above):
1. With the device language set to English, launch and confirm
   “Development environment”.
2. Switch the device language to Hindi and relaunch; confirm “डेवलपमेंट परिवेश”.
3. Increase device text size to 200%; confirm the Hindi shell remains readable.
4. Switch to an unsupported language (for example French) and relaunch;
   confirm the shell falls back to English.
