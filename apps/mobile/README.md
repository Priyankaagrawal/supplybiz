# Supply Biz Mobile

Flutter entrypoints are `lib/main_dev.dart`, `lib/main_staging.dart`, and
`lib/main_prod.dart`. Use the matching native flavor/scheme and
`config/<flavor>.json` when running or building. Firebase is opt-in per
flavor; see
[`ENVIRONMENT_SETUP.md`](../../docs/06-development/ENVIRONMENT_SETUP.md) for
required native configuration files.

From this directory, run each flavor on an Android emulator or Android device only (select `-d <android-device-id>`):

```sh
fvm flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json
fvm flutter run --flavor staging -t lib/main_staging.dart --dart-define-from-file=config/staging.json
fvm flutter run --flavor prod -t lib/main_prod.dart --dart-define-from-file=config/prod.json
```

The native flavor, entrypoint and `ENV_NAME` must match. Checked-in API hosts
for staging/prod are placeholders; auth now calls the configured API and requires
versioned legal content (see the T-016 handoff below).
Firebase-disabled configs run without Firebase project files. For a Firebase
check, supply the matching native config and set `FIREBASE_ENABLED` to `true`
in a local copy of that flavor's JSON. Android only processes Google Services
for flavors with a config file. Do not add placeholder credentials.

T-008 manual verification:
1. Run all three flavors on Android only; confirm the environment label.
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
- Edit `lib/l10n/app_en.arb`, then run `fvm flutter gen-l10n`.
  Commit the generated files in `lib/core/l10n/generated`; do not edit them.
- Use `context.l10n` for app strings. The delivery baseline supports English only with INR/IST formatting; T-183 removes obsolete locale selection and assets.
- Import `core/utils/money.dart` for the existing shared `formatInr(int paise)`.
  Import `core/utils/dates.dart` for `formatIstDate`, `formatIstDateTime`, and
  `istDateKey`. Pass an instant (UTC or with an explicit offset); omit device-local
  wall-clock parsing for server timestamps. Bootstrap initializes bundled date
  symbols; standalone tests should await `initializeDateFormatters()`.
- Date display accepts `locale: context.l10n.localeName`; business-date keys
  always use Gregorian `yyyy-MM-dd`. These are display helpers, not cutoff logic.
- `flutter_localizations` (Flutter SDK) and `intl` (BSD-3-Clause) are the
  ADR-023/ARCHITECTURE choices, already present in the workspace lockfile;
  this task declares direct imports without upgrading dependencies.

```sh
fvm flutter gen-l10n
fvm dart analyze lib test
fvm flutter test --no-pub test/core/utils test/widget_test.dart
```

T-010 manual verification (use the dev run command above):
1. With the device language set to English, launch and confirm
   “Development environment”.
2. Confirm no language selector appears after T-183; device locales fall back to English.
3. Increase device text size to 200%; confirm the English shell remains readable.
4. Switch to an unsupported language (for example French) and relaunch;
   confirm the shell falls back to English.

T-011 network foundation:
- Construct `NetworkClient` with the environment API URL, one shared
  `NetworkSession`, and a current `language` callback returning `en`.
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
  disabled. Use authenticated multipart upload and authorized content streaming per LOCAL_FILE_STORAGE.
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
3. Confirm Problem Details mapping and English message tests pass; raw server text
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
2. Run the native test on Android only (iOS native tests after Android release): confirm encrypted bytes, persisted
   data/refresh token after reopen, wrong-key rejection and new key after wipe.
   Test secrets and database use a separate namespace/directory.
3. Launch the dev flavor; restart and confirm startup succeeds with the same DB.
4. Review the native test's wipe assertions: DB/sidecars and secure secrets are
   removed. End-to-end logout button verification follows T-015/T-016.

T-013 navigation foundation:
- `SupplyBizApp` uses `MaterialApp.router` and owns/disposes its router. Inject
  one `RoutingController` to supply immutable `RouteAccess` updates from the
  real session/config integrations in T-015/T-016/T-017. The default state is
  signed out; after T-183, launch goes directly to auth/consent without language selection.
  Screens are placeholders, with no fake sign-in, onboarding or role changes.
- Guards enforce force-update, initialization, auth, selected role,
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
  through the guards. Deferred referral routes/actions are absent; unknown links use the generic safe Home fallback.
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
1. Run the existing dev flavor command; confirm the English sign-in
   placeholder and environment label without a language selector. Authentication UI follows T-016.
2. Run the focused router tests; verify all four link types reach the correct
   role's detail placeholders and pending links resume after the guards clear.
3. Check the tab-history test: navigate to an order, switch Home/Orders,
   reselect Orders, then Back; confirm retained detail, branch root, then Home.
4. Check mismatch and malformed-link tests: no automatic role change, cancel
   returns Home, and invalid IDs/unknown links never show raw URLs or errors.
5. Check the English/200% widget checks and 48dp/labelled-target accessibility checks.

## Revised delivery baseline (2026-10-29)
ADR-023 and T-183 supersede extra-language and snapshot-generation behavior in existing source. T-183 implements the English-only/source cleanup and removes snapshot tooling and baselines. Run lightweight build/analyze/smoke per task and comprehensive integrated tests at module completion. Android is the active runtime verification target; all iOS build/run/testing stays deferred until after Android production release (ADR-025). App media uploads and reads use authenticated API requests, not direct cloud storage. Follow ROADMAP for priority and report incomplete reconciliation honestly.

## Android release first
ADR-025: no iOS builds/runs/simulator/device/native-storage/VoiceOver/E2E testing, signing or TestFlight work before actual Android production release T-179. Keep `ios/` and platform settings intact. Android module gates include encrypted storage/logout, TalkBack, offline/replay, authentication and payment claims. T-185 handles iOS validation afterward; current success means Android evidence only, never implicit iOS support verification.

## Day 1 / T-183 handoff

Use the repository-pinned Flutter 3.35.7 SDK through FVM. The global Flutter 3.47.8 initially produced an incompatible shader-cache error; its incidental lockfile changes were reverted. Regenerate local plugin manifests with `fvm flutter pub get --enforce-lockfile` if they reference an old temporary package cache. See [Day 1 evidence](../../docs/05-ai-development/DAY1_HANDOFF.md) for focused test/build/device results and manual checks. Hindi device locales now use English throughout the shell and startup failure UI; language selection and deferred referral aliases are removed. Generated localization/router code was regenerated from source. All iOS checks remain deferred.

## T-016 auth verification handoff

S-COM-01/03/04/05 now restore sessions, validate +91 numbers, require explicit versioned
consent, send SMS/WhatsApp requests, accept/paste/autofill six OTP digits, display resend
and server rate-limit waits, and retain the number when changing it. Role selection and
switching use server responses; Vendor opens the existing onboarding destination, Customer
opens its shell. The Settings action provides role switching, current logout and logout-all,
including during onboarding. Remaining business destinations retain their owning tasks.

Riverpod owns the session; access tokens stay in memory and refresh tokens use the existing
native secure store. Refresh is single-flight, persisted before reuse, and fenced against
late replies after logout/new login. Cold-start network failures retain refresh credentials
with Retry/local logout instead of admitting another account into the existing local DB.
Logout wipes native SQLCipher files and session secrets; installation identity survives
logout to preserve a stable X-Device-Id. All mutations carry Idempotency-Key. Generated
client paths already contain /api/v1, so their Dio transport uses the configured origin.
The normal entrypoints enable auth; the explicit disabled mode preserves isolated router
foundation tests, not a runtime sign-in bypass.

Dependencies: flutter_riverpod 2.6.1 (MIT; implements the existing Riverpod 2 architecture,
no generator added), and the existing generated workspace API client. Android adds only
play-services-auth-api-phone 18.2.0 (Google Play services SDK terms; limited phone API,
not Firebase Auth). It is pinned for the existing Kotlin toolchain; 18.3.1 required newer
Kotlin metadata. Dependency size growth was not benchmarked. Native SMS Retriever follows
[Android's receiver/start guidance](https://developer.android.com/identity/sms-retriever)
with SEND_PERMISSION on the receiver, no SMS read/receive permission, runtime app hash,
short startup timeout and lifecycle cleanup. Real broadcast/autofill delivery awaits Q-09;
manual entry remains available. No iOS source/configuration was changed or validated.

Consent requires TERMS_VERSION, TERMS_TEXT, PRIVACY_VERSION and PRIVACY_TEXT in the build
configuration; absent documents disable signup. Only config/dev.json contains labelled
synthetic development documents. Supply approved content/versions for deployed builds;
T-017/T-107 own subsequent API-config/CMS integration. No production legal policy is invented.
This task uses stable T-015 contracts and test-only delivery for checks; T-014 stays BLOCKED.

Executed with Flutter 3.35.7 / Dart 3.9.2 and JDK 21 (commands from apps/mobile unless noted):
```sh
# Installed pinned SDK used for checks:
FLUTTER_BIN=/Users/ankit/fvm/versions/3.35.7/bin/flutter
# Dependency resolution/localization were run through ~/.pub-cache/bin/fvm:
fvm flutter pub get
fvm flutter gen-l10n
"$FLUTTER_BIN" analyze --no-pub
"$FLUTTER_BIN" test --no-pub --reporter expanded test/features/auth/session_controller_test.dart test/features/auth/auth_pages_test.dart test/core/router/app_router_test.dart test/core/router/guards_test.dart test/core/network/network_client_test.dart test/core/storage/secure_store_test.dart test/core/storage/app_storage_test.dart test/widget_test.dart
# From packages/ui_kit:
"$FLUTTER_BIN" analyze --no-pub
"$FLUTTER_BIN" test --no-pub --reporter expanded test/src/components_test.dart
# From apps/mobile, with JAVA_HOME=/Library/Java/JavaVirtualMachines/openjdk-21.jdk/Contents/Home:
"$FLUTTER_BIN" test integration_test/auth_test.dart -d emulator-5554 --flavor dev --dart-define-from-file=config/dev.json --no-pub --reporter expanded
"$FLUTTER_BIN" build apk --debug --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json --no-pub
# From repository root:
pnpm --filter @supplybiz/api exec eslint test/mobile-auth-harness.ts --max-warnings=0
pnpm --filter @supplybiz/api typecheck
node --check tools/check-task.mjs
node --test tools/checks.spec.mjs
git diff --check
```
55 focused mobile checks (including 200%/Android semantics), 8 UI-kit checks and 4 CLI guards
pass. The Android integration check passed once after the navigation fixes: real renderer,
secure storage and SQLCipher, with simulated API responses confined to test code. It uses
an isolated storage namespace/directory and cleans it afterward. This is not a mobile →
real PostgreSQL integrated pass; prior T-015 provides separate native API/DB evidence.
The final normal dev APK was rebuilt and installed on emulator-5554 after testing, replacing
the integration-test APK. The emulator was already running and was left available. No API
service/manual harness was started. No full G0 suite or manual PASS is claimed. T-016 is
registered in tools/check-task.mjs; that full runner/hosted CI was not executed this turn.

Manual verification (pending):
1. For real API/DB testing, select an already migrated dedicated _test database and private
   persistent UPLOAD_ROOT. Stop any other process occupying port 3000. From apps/api run
   `MOBILE_AUTH_TEST_DATABASE_URL=<test-db-url> pnpm exec node --inspect-brk -r ts-node/register test/mobile-auth-harness.ts`.
   Attach a local debugger, set a breakpoint on `void delivery` in inspectDelivery, then resume.
   This harness binds only 127.0.0.1, accepts development/test only, never logs codes and adds
   no code-retrieval endpoint. Its ephemeral pepper/signing keys are unsuitable for restart
   abuse-control evidence. It was statically checked but not started in this implementation.
2. Run the normal Android dev entrypoint with config/dev.json. Confirm invalid numbers and
   unchecked consent disable sending; open both synthetic legal documents. Send SMS or
   WhatsApp for a synthetic account, inspect the code at the debugger breakpoint, resume the
   API and enter/paste it. Confirm the resend timer, wrong/expired/exhausted errors and Change
   number behavior. The harness simulates delivery; actual carrier/template tests await Q-09.
3. Choose Customer, open Settings, switch to Vendor and confirm onboarding; open Settings
   again and switch back. Restart the Android app with the same API and confirm refresh/role
   restoration. Test offline restore → Retry without clearing saved credentials.
4. Exercise logout and logout-all, including another test device/session. Confirm the next
   API call on a revoked session returns to login, local secrets/database are wiped, and a
   fresh login works. Review TalkBack and 200% layouts manually; automated semantics are not
   a TalkBack PASS. Stop the manual harness afterward and record PASS separately.

## T-017 config / Android update gate handoff (2026-11-04)

Normal entrypoints now load the generated `/config` client with a bounded four-second
network wait, refresh on resume and every four minutes while active, and keep an
atomic, API-URL-scoped public JSON cache in application support. Cache survives
logout; it contains no account data. With no valid policy/version, startup offers
localized Retry; offline startup can use the last valid policy and keeps any update
block. Native Android package metadata supplies the installed version. S-COM-06
blocks Back, deep links and all routed content until the minimum version permits
entry. HTTP 426 immediately blocks the UI and refreshes policy without replaying
the failed request or clearing the session. Simple boolean flags are exposed through
`configProvider` / `value.enabled(key)`; unknown flags default false and cannot grant
server permissions or enable deferred feature routes. Update opens the installed
package's Play listing via Android intent, with HTTPS fallback and localized launch
failure. Dev packages may have no published listing; actual Play publication is pending.
Terms/Privacy continue using T-016's explicit legal build configuration; CMS/legal
content and audited admin config editing belong to T-107/T-158.

Executed from `apps/mobile` with pinned Flutter 3.35.7 / Dart 3.9.2 and JDK 21:
```sh
/Users/ankit/.pub-cache/bin/fvm flutter gen-l10n
/Users/ankit/.pub-cache/bin/fvm dart format lib/app.dart lib/core/config test/core/config
/Users/ankit/.pub-cache/bin/fvm dart format lib/app.dart test/core/config/app_config_test.dart test/core/network/network_client_test.dart
/Users/ankit/.pub-cache/bin/fvm flutter analyze --no-pub
/Users/ankit/.pub-cache/bin/fvm flutter test --no-pub --reporter expanded test/core/config/app_config_test.dart test/features/auth/auth_pages_test.dart test/core/router/guards_test.dart test/core/network/network_client_test.dart
JAVA_HOME=/Library/Java/JavaVirtualMachines/openjdk-21.jdk/Contents/Home /Users/ankit/.pub-cache/bin/fvm flutter test integration_test/config_test.dart -d emulator-5554 --flavor dev --dart-define-from-file=config/dev.json --no-pub --reporter expanded
JAVA_HOME=/Library/Java/JavaVirtualMachines/openjdk-21.jdk/Contents/Home /Users/ankit/.pub-cache/bin/fvm flutter build apk --debug --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json --no-pub
```
Results: clean analysis, 31 focused mobile checks (including TC-407 periodic refresh,
200% text and Android semantics), one Android native smoke passed, dev APK built.
Native smoke uses simulated API responses and a separate disposable cache directory;
it proves real native version lookup, disk-cache persistence, origin separation,
offline blocking, Back prevention and recovery. API/real PostgreSQL evidence is
separate in the API README; an integrated mobile → live API/DB journey is NOT_RUN.
The normal dev APK was restored with the command below from repository root; the
pre-existing emulator remains available. No iOS source/config was edited; all iOS
build/runtime/accessibility checks are DEFERRED under ADR-025. TalkBack/manual PASS,
actual Play listing availability and module gates remain pending.
```sh
/Users/ankit/Library/Android/sdk/platform-tools/adb -s emulator-5554 install -r apps/mobile/build/app/outputs/flutter-apk/app-dev-debug.apk
```

Manual verification (suggested commands/actions, not an automated PASS):
1. Use an existing dedicated `_test` DB, apply migrations, and start the normal API
   against it using its documented native configuration. Run the normal Android dev
   entrypoint. `curl http://localhost:3000/api/v1/config` should show minimum `0.1.0`
   and `{}` flags; the Android app should reach Sign in. Preserve the original row.
2. In that test DB only, set the policy using
   `UPDATE app_config SET value='{"minVersionAndroid":"0.2.0","flags":{"operationalNotice":true}}'::jsonb, updated_at=now() WHERE key='mobile';`.
   Resume Android or wait four minutes: the update screen must block navigation and
   Back. Open Update and check the Play target or its unavailable-store behavior.
   Inspect `configProvider` to confirm the boolean flag is true (no unrelated UI added).
3. Stop that test API and relaunch Android: the cached update requirement must remain.
   A request to `/api/v1/me` declaring Android version `0.1.0` should return 426 when
   the API is running; config must remain readable without authentication.
4. Restore the original test policy and resume/Retry: the block should clear. With
   TalkBack and 200% text, review labels, targets, scrolling and the store error.
   Restore all test data and stop the manually started API; record manual PASS separately.

## T-024 vendor onboarding handoff (2026-11-10)

S-V-01–04 now use the existing generated onboarding/KYC/media clients. Vendor session
restoration loads the server's saved step. Category selection, validated business
fields/manual coordinates, owned shop-photo attachment, KYC uploads, bank validation,
manual-review status/rejection reason and resubmission are connected. Submitted vendors
can enter the existing vendor shell; its status banner links back to verification.
Dashboard business metrics remain T-031. Discovery enforcement remains server-owned;
this task does not claim a discovery journey or resolve plan/visibility policy questions.

Unfinished fields and opaque attachment IDs are serialized to account/API-scoped SQLCipher
rows (local schema v2, additive migration from v1). Form mutation keys/payloads persist
before requests, retaining the key for identical retries. Successful KYC submission clears
full PAN/account inputs and its retry payload from the draft; status only shows account
last-four. Logout's existing database wipe removes drafts. Disposed account controllers
cannot enqueue further writes. No document bytes enter drafts or logs.

Android uses the Storage Access Framework without broad storage permissions or a new
package. Selection is bounded to 5 MB, validates decoded image type/dimensions, re-encodes
images with EXIF removal/orientation, and leaves PDFs unchanged. Uploads use opaque media
IDs and authenticated reads; images display in a private dialog and PDFs preview their
first page. PDFs must be supplied already masked on every page. Aadhaar image selection
includes masking guidance, an accessible adjustable black-rectangle fallback and explicit
masking confirmation. Encoded masking is flattened into pixels; no automatic OCR/masking
verification is claimed (ADR-027). Supply pre-masked files for documents with multiple
number copies that need more than one rectangle. Server byte/decode/ownership checks
remain authoritative. Transient failed uploads retain their in-memory bytes/key for Retry;
non-retryable validation failures permit selecting a replacement.

All onboarding screens acquire owner-scoped Android FLAG_SECURE before exposing fields
and release it when disposed. Failure blocks the forms with Retry while Settings stays
available for role switching/logout. Sensitive form data is never sent to diagnostics.
No iOS source/configuration changed; iOS build/run/security checks are DEFERRED (ADR-025).
No API contract changed; only ARB localization output was regenerated.

Executed from `apps/mobile`, pinned Flutter 3.35.7 / Dart 3.9.2, JDK 21:
```sh
/Users/ankit/.pub-cache/bin/fvm flutter gen-l10n
/Users/ankit/.pub-cache/bin/fvm dart format lib/features/onboarding lib/core/storage/onboarding_device.dart test/features/onboarding integration_test/onboarding_test.dart
/Users/ankit/.pub-cache/bin/fvm flutter analyze --no-pub
/Users/ankit/.pub-cache/bin/fvm flutter test --no-pub --reporter expanded test/features/onboarding test/core/router/guards_test.dart test/core/storage/app_storage_test.dart test/features/auth/auth_pages_test.dart
JAVA_HOME=/Library/Java/JavaVirtualMachines/openjdk-21.jdk/Contents/Home /Users/ankit/.pub-cache/bin/fvm flutter test integration_test/onboarding_test.dart -d emulator-5554 --flavor dev --dart-define-from-file=config/dev.json --no-pub --reporter expanded
JAVA_HOME=/Library/Java/JavaVirtualMachines/openjdk-21.jdk/Contents/Home /Users/ankit/.pub-cache/bin/fvm flutter build apk --debug --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json --no-pub
```
Results: clean analysis; 22 focused checks; one Android native smoke; normal dev APK built.
The native smoke exercises real SQLCipher v1→v2 migration, close/reopen persistence,
plaintext absence in the DB file, owner separation, restored KYC fields and native secure
flag acquisition/release, using isolated secrets/files with cleanup. Generated-client
HTTP responses are simulated: mobile → live API/PostgreSQL/provider delivery is NOT_RUN.
The native file-picker interaction and PDF rendering are NOT_RUN by automation; they need
manual checks below. Prior API T-020–022 evidence remains separate. Initial test fixture,
widget async/lint and Settings-on-security-failure defects were corrected; final commands
pass. The first native install failed with an offline emulator; retry after boot passed.

Executed from repository root:
```sh
node --check tools/check-task.mjs
node --test tools/checks.spec.mjs
git diff --check
/Users/ankit/Library/Android/sdk/platform-tools/adb -s emulator-5554 install -r apps/mobile/build/app/outputs/flutter-apk/app-dev-debug.apk
```
Four task-runner guard tests pass. T-024 is registered for focused mobile CI; the full task
runner/hosted CI and comprehensive G0/G1 suites were NOT_RUN. No API/worker/manual harness
was started. The headless emulator launched for this check exited; a separately launched
emulator subsequently available on emulator-5554 is preserved. The normal dev APK replaces
the integration-test APK after checking; no test process is left running.

Manual verification (pending; use synthetic documents/accounts only):
1. Start the documented T-016 development/test auth harness or an existing test API against
   an appropriately migrated dedicated test DB, private UPLOAD_ROOT and the local-only KYC
   encryption configuration described in the API T-022 README. Use the normal Android dev
   entrypoint, log in and choose Vendor. Verify category selection is required; save business
   fields with coordinates and optional GSTIN; reject invalid names/GSTIN/pincode/coordinates.
2. Choose a JPG/PNG and a PDF shop attachment; preview/reload it through the authenticated API.
   Reject a >5 MB or unsupported file; try offline upload then Retry. Kill/relaunch during a
   partially filled step: saved fields and completed attachments must resume for this account.
3. Attach already-masked synthetic Aadhaar front/back and PAN. Exercise image masking and
   confirm encoded preview hides the first eight digits; PDFs must already be masked on all
   pages (in-app preview shows the first page only). Mismatched account confirmation, malformed
   PAN/IFSC/UPI and missing documents must prevent submission. Check screenshots are blocked.
4. Submit once, retry/refresh/relaunch and confirm the API/DB has one manual-review case and
   provider checks remain NOT_RUN. Use the T-022 authorized API review instructions (T-151 UI
   is still TODO) to reject with a reason; refresh, correct/resubmit, then approve. Confirm the
   reason/status/masked account and vendor-shell banner reflect server results.
5. Review all four screens, file controls and mask sliders with TalkBack and 200% text. Switch
   roles/log out, sign in as a different synthetic user and verify draft isolation; log back
   in and verify the expected server step. Stop manually started services afterward. Record
   task-specific manual PASS separately; T-024 is not DONE and no module gate is passed.

## T-025 service area implementation handoff (2026-11-10)

IN_PROGRESS: Vendor → More → Service area (`/vendor/service-area`, S-V-30).
T-016 and T-023 are READY_FOR_VERIFY and permit work against their stable contracts.
Day 4 catalog T-026 was skipped because its required BUSINESS+ low-stock alert behavior
still references open Q-34 threshold and Q-04 entitlement policies; those tasks/statuses
were not changed. Existing API, migration and generated-client working edits were preserved.

The form reads the authenticated generated vendor API. Shop address, pincode and finite
coordinates save through the existing business endpoint, preserving business name, GSTIN
and owned photo; server re-verification rejection is displayed without bypassing policy.
Coverage saves separately through T-023, with an integer radius of 1–20 km and/or unique
six-digit Indian pincodes. Radius OR additional pincodes matches server coverage semantics.
Blank radius disables radius coverage. Empty combined coverage is rejected locally.
Customer outside-coverage enforcement remains server-owned (T-023, downstream order flow).

Save payload/key pairs persist before requests in the existing SQLCipher draft store,
scoped to API/account and wiped by logout. Interrupted payloads restore fields on reopen;
identical retries reuse their key, changed payloads receive a new one, and accepted writes
clear their pending entry. Unsaved typing is not persisted. Initial loading, empty-business,
request errors, save progress and localized live-region feedback are present.
Android GPS is explicit and foreground-only, requests runtime location permission, waits
at most 20 seconds for a fix after permission, and removes listeners on completion/cancel.
Permission denial or disabled/unavailable location leaves manual fields available. No map,
geocoder, background location, new package or iOS source/configuration change was introduced.

Executed from `apps/mobile` using installed Flutter 3.35.7 / Dart 3.9.2:
```powershell
flutter --version
flutter gen-l10n
dart run build_runner build --build-filter=lib/core/router/routes.g.dart --delete-conflicting-outputs
dart format lib/features/service_area lib/core/storage/device_location.dart test/features/service_area lib/core/router/routes.dart lib/core/router/route_widgets.dart
flutter analyze --no-pub
flutter test --no-pub --reporter expanded test/features/service_area/service_area_test.dart test/core/router/guards_test.dart
flutter build apk --debug --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json --no-pub
```
Generation/formatting succeed; analysis is clean; all 9 focused checks pass. The widget
smoke exercises GPS denial and invalid coverage at 200% text; simulated HTTP tests exercise
saved-value reload, interrupted request recreation/key reuse, changed-payload keys and
server re-verification rejection. This is not native Android or live API/DB evidence.
The initial generator run without `--delete-conflicting-outputs` failed on its existing
generated output; the corrected scoped command passed. Initial analysis errors and a
widget-test async setup stall were corrected before the passing checks.

APK build: NOT PASSED. Online attempts stalled in Gradle and were cancelled. An offline
diagnostic from `apps/mobile/android` (`.\gradlew.bat :app:assembleDevDebug --offline
--console=plain -Ptarget=lib/main_dev.dart -Ptarget-platform=android-arm64`) failed while
configuring existing `flutter_secure_storage`: missing cached AGP/builder 8.13.2,
Kotlin reflect/stdlib 2.2.0 and analytics protos 31.13.2. PowerShell split the unquoted
target argument in that diagnostic; dependency resolution failed before target evaluation.
No APK/native Kotlin compilation success is claimed. Do not downgrade dependencies or
disable checks to bypass this prerequisite; restore artifact access and rerun the normal
Flutter build above. No build/test service is intentionally left running.

Executed from repository root:
```powershell
adb devices
node --check tools/check-task.mjs
node --test tools/checks.spec.mjs
git diff --check
```
ADB lists no devices; the installed `C:/Android` SDK has no emulator executable.
Runner syntax and all 4 guard checks pass; diff whitespace check passes. T-025 focused
checks are registered in the existing runner; full runner/hosted CI/module suites NOT_RUN.
Native GPS permission/fix, app → live API/PostgreSQL, TalkBack and manual PASS are NOT_RUN.
iOS checks are DEFERRED (ADR-025). G0/G1 remain pending; task is not READY_FOR_VERIFY/DONE.

Manual verification after a successful Android build (not executed):
1. Start the existing test API with the T-023 migration applied. On Android sign in as a
   synthetic vendor, complete business onboarding, then open More → Service area. Confirm
   server location and coverage prefill; save valid shop details and reopen to verify DB
   persistence. For a verified vendor, confirm any required re-verification error is shown.
2. Save radius-only (1 and 20), pincodes-only and combined coverage; reopen each. Reject
   0/21/fractional radius, malformed/duplicate pincodes, NaN/out-of-range coordinates and
   empty coverage. Check T-023 radius OR pincode behavior server-side; full checkout is T-045.
3. Deny GPS permission, disable location, then grant permission with a fresh Android fix.
   Manual entry must always remain available; GPS fills only coordinates and does not save
   automatically. Navigate away during acquisition and confirm the listener is cancelled.
4. Disconnect during Save, close/reopen and retry the restored payload. Verify one DB
   mutation with the same key; changed input uses a different key. Log out/switch accounts
   and check isolation. Review TalkBack labels, 48dp controls and 200% scrolling/errors.
