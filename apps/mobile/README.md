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

T-011 network foundation:
- Construct `NetworkClient` with the environment API URL, one shared
  `NetworkSession`, and a current `language` callback returning `en` or `hi`.
  `request<T>()` throws `AppFailure`; pass `.dio` to generated clients and map
  their `DioException` with `mapDioFailure` at repository boundaries.
- T-015 implements `NetworkSession`: access tokens stay in memory; refresh
  rotates/persists tokens before completing. Its implementation must prevent
  an in-flight refresh from restoring a logged-out or replaced session.
  No refresh endpoint or production token store is invented in this task.
- OTP/refresh/public requests must use
  `Options(extra: {NetworkClient.publicRequest: true})`; they omit bearer tokens
  and cannot trigger refresh recursively. Refresh can use the same client with
  that option or a separate transport. Permanent refresh rejection clears the
  session; transient failures preserve it and return a typed failure.
- Concurrent 401s share a refresh; each request replays at most once with its
  original body, correlation ID and idempotency key. Multipart bodies are cloned;
  single-use streams cannot be replayed. Only GET network/5xx failures retry
  twice (250/500 ms backoff). Mutations have no automatic transport retries.
- POST/PATCH/PUT/DELETE get UUID idempotency keys. For explicit retries/outbox
  replay, persist and supply the original `Idempotency-Key` yourself. Keys are
  preserved case-insensitively. `X-Request-Id` and `Accept-Language` accompany
  requests. API requests stay within the configured origin/path; redirects are
  disabled. Use a separate unauthenticated transport for presigned uploads.
- UI uses `failure.toMessage(context.l10n)`. Field errors retain field names and
  codes, never provider messages. Unknown codes use a safe localized fallback.
  No network logger is installed; do not log Dio options, headers or bodies.
- Dependency rationale: Dio is the architecture-selected HTTP client; UUID
  supplies random v4 correlation/idempotency keys without custom RNG code.
  Resolved versions are Dio 5.11.1 and UUID 4.6.0 (MIT), pinned in the lockfile.
  Both have upstream package releases and use Dart code without new native SDKs;
  future updates go through normal dependency review. Their library sources
  occupy about 280/104 KiB locally; compiled bundle impact remains unmeasured
  until build verification. Existing dependency versions were preserved.

```sh
fvm flutter test --no-pub test/core/network --reporter expanded
fvm dart analyze lib test
```

T-011 verification (fake transports; no API, credentials or native launch needed):
1. Run the focused test command; confirm concurrent and delayed 401 cases pass
   with one refresh and the original POST body/key preserved.
2. Confirm refresh rejection, transient failure, cancellation and second-401
   tests pass without loops or unwanted mutation retries.
3. Confirm Problem Details mapping and EN/HI message tests pass; raw server text
   must not appear in localized failure messages.
4. Confirm origin checks, public-request headers, multipart replay and GET
   backoff tests pass. Live authenticated verification follows T-015 integration.

T-012 encrypted storage:
- Bootstrap opens `AppStorage.instance` before the app shell; initialization
  errors use the existing localized startup failure screen. It owns a Drift
  schema-version-1 database in application support, encrypted through the
  official `encrypted_drift` adapter and `sqflite_sqlcipher`. A runtime
  `cipher_version` check rejects plaintext SQLite. There are no feature tables
  yet; add tables/DAOs, generated schema and explicit versioned migrations in
  their owning tasks. Unsupported version changes fail without deleting data.
- The random 256-bit database secret and refresh token use Keychain/Keystore;
  iOS uses `first_unlock_this_device`, Android disables silent key resets and
  app backup. Access tokens stay in session memory. Statements are never logged.
- T-015 must invalidate the memory session, cancel/drain requests and database
  consumers, then await `AppStorage.instance.wipeOnLogout()` from session clear.
  A persistent cleanup marker makes interrupted wipes retry on startup. Wiping
  closes the database, removes it and its sidecars, then clears secrets. Never
  retain old database/DAO references after logout. Refresh persistence must
  check the session generation before calling `writeRefreshToken`.
- Dependencies: Drift (MIT, pinned 2.31.0 for Dart 3.9 compatibility), its
  official SQLCipher adapter (MIT, immutable Git revision), secure storage
  (BSD-3-Clause), path (BSD-3-Clause) and path_provider (BSD-3-Clause) implement
  ADR-006 and the architecture's storage choices. The adapter uses SQLCipher
  4.10.0 native libraries through sqflite_sqlcipher (MIT). Native bundle impact
  is unmeasured; dependency updates require review. No generator is needed for
  the initial empty schema. SDK integration_test supplies native test support.

Verification commands from `apps/mobile` (focused unit tests: 6 passed;
native integration test: not yet executed):
```sh
fvm flutter test --no-pub test/core/storage --reporter expanded
fvm flutter test integration_test/storage_test.dart -d <device-id> --flavor dev --dart-define-from-file=config/dev.json
```
T-012 manual verification:
1. Run the focused unit tests: initialization serialization, missing-key
   rejection, plaintext rejection, logout cleanup and interrupted-wipe recovery.
2. Run the native test on Android and iOS: confirm encrypted bytes, persisted
   data/refresh token after reopen, wrong-key rejection and new key after wipe.
   Test secrets and database use a separate namespace/directory.
3. Launch the dev flavor; restart and confirm startup succeeds with the same DB.
4. Review the native test's wipe assertions: DB/sidecars and secure secrets are
   removed. End-to-end logout button verification follows T-015/T-016.

T-013 navigation foundation:
- `SupplyBizApp` uses `MaterialApp.router` and owns/disposes its router. Inject
  one `RoutingController` to supply immutable `RouteAccess` updates from the
  real session/config integrations in T-015/T-016/T-017. The default state is
  signed out with no language selected; launch shows the language placeholder.
  Screens are placeholders, with no fake sign-in, onboarding or role changes.
- Guards enforce force-update, initialization, language/auth, selected role,
  vendor onboarding resume step, and active-role matching. Legal is accessible
  without sign-in; force-update still blocks it. The mismatch placeholder offers
  Back to home; the session owner must explicitly change the active role before
  a pending link can resume. API ownership/authZ remains enforced server-side.
- Both roles have five stateful branches. The A-17 customer tabs were explicitly
  approved as provisional placeholders for this task; Q-10 remains open for
  final product navigation. Switching tabs retains each stack, reselecting pops
  that branch to its root, and Back at a non-Home root selects Home.
- Use generated typed routes from `core/router/routes.dart` in widgets.
  External/push links enter through `RoutingController.openLink(raw)`; parser
  targets and the router accept `/o/{uuid}`, `/v/{uuid}`, `/s/{uuid}` and
  `/khata/{uuid}`, plus `supplybiz://` equivalents. Pending navigation stays in
  memory through login/role/onboarding gates, is consumed once, and is cleared
  on logout. It is not persisted across process death. IDs never grant ownership.
- Q-33: HTTPS links are disabled until exact hosts are supplied through
  `DeepLinkParser(trustedHosts: {...})`. No production domain, assetlinks/AASA or
  native URL registration is invented. Malformed/unknown links resolve Home
  through the guards. Q-14 referral attribution remains a Home fallback stub.
- Added dependencies: go_router 16.2.5, go_router_builder 3.0.0 and build_runner
  2.5.4 (BSD-3-Clause), pinned in the workspace lockfile. They implement the
  architecture's typed router choice with Dart 3.9-compatible tooling. The
  generator/build runner are development-only; native bundle impact is not
  measured. Dependency updates require normal review.

Executed commands from `apps/mobile` using the cached Flutter 3.35.7 SDK
(`/tmp/supplybiz-sdk/flutter/bin`, `PUB_CACHE=/tmp/supplybiz-pub-cache`):
```sh
flutter pub get
dart run build_runner build --build-filter=lib/core/router/routes.g.dart
flutter gen-l10n
dart analyze lib/app.dart lib/core/router test/core/router
flutter test --no-pub test/core/router test/widget_test.dart --reporter expanded
```
Results: generated route/l10n output, clean targeted analysis, 20 passing tests.
T-013 manual verification (native app execution has not been performed):
1. Run the existing dev flavor command; confirm the localized language
   placeholder and environment label. Authentication UI follows T-016.
2. Run the focused router tests; verify all four link types reach the correct
   role's detail placeholders and pending links resume after the guards clear.
3. Check the tab-history test: navigate to an order, switch Home/Orders,
   reselect Orders, then Back; confirm retained detail, branch root, then Home.
4. Check mismatch and malformed-link tests: no automatic role change, cancel
   returns Home, and invalid IDs/unknown links never show raw URLs or errors.
5. Check the Hindi/200% widget test and 48dp/labelled-target accessibility checks.
