# Supply Biz Mobile

## T-019 account deletion (2026-11-24): READY_FOR_VERIFY

Q-20 retention is approved in ADR-035/SCOPE/DATA_DESIGN. Vendor/customer settings,
common account/role settings and `/account/delete` open S-COM-10. Authentication
and force-update guards apply, but unfinished role/vendor onboarding does not
prevent deletion. The generated-client screen previews exact vendor receivables,
states loss of access for both roles and the retention policy, requires explicit
acknowledgement, sends a purpose-bound deletion OTP to the server-owned mobile,
then requires a separate final confirmation. No arbitrary target/mobile is sent.
Login OTPs cannot authorize deletion, and resend shares the existing mobile/IP/
device budgets. Countdown updates enable resend after 30 seconds. Wrong/expired
codes allow correction; no offline success or automatic destructive retry.

Confirmation immediately deactivates the account and revokes all sessions and
push tokens; discovery and future generation stop through existing active-account
checks. Existing obligations/ledger entries/balances are retained, never settled
by deletion. Successful confirmation wipes local secrets/cache. A delayed response
can only clear its original account. An uncertain response freezes the exact
code/body/key in tab memory; no OTP is persisted to disk. A revoked-session retry
is denied, not a success replay. Reload requires fresh authentication/OTP; a
network error alone is never reported as completed deletion.

The API records an immutable ownership tombstone and 30-day deadline. The worker
starts personal erasure on day 29 (one day of retry headroom): clears live profile,
addresses/preferences and vendor/KYC personal fields, disables media reads, and
unlinks server-generated private media paths in bounded batches. ERASING state
survives failures; missing files are idempotent and the final ERASED/audit record
commits only after files are gone. Documented HELD requests are skipped. Ordinary
KYC mutation protection remains; a narrow due/deleted/authorized-retention-context
exception permits only field erasure. Financial/counterparty records and immutable
audit history retain their protected access. A later registration receives a new
ID and no old ownership. T-161 owns admin holds/privacy operations and long-term
financial/audit expiry; T-175 owns 90-day backups and deletion replay after restore.
Those release checks remain pending. No main database/source financial backfill,
new dependency or iOS change. Two additive migrations applied only to isolated
local supplybiz_service_area_test; tests create/erase only synthetic media files.

Executed checks (PASS):
- API (`apps/api`): `.\node_modules\.bin\prisma.cmd generate --schema src/prisma/schema.prisma`,
  `.\node_modules\.bin\prisma.cmd migrate deploy --schema src/prisma/schema.prisma`
  with DATABASE_URL restricted to the isolated test DB; `tsc.cmd --noEmit`,
  `tsc.cmd -p tsconfig.build.json` via `.\node_modules\.bin\`.
- API: `.\node_modules\.bin\eslint.cmd src/modules/privacy src/modules/media/media.service.ts src/modules/kyc/kyc.service.ts src/modules/auth/otp.service.ts src/modules/auth/otp.types.ts src/modules/auth/postgres-otp.store.ts src/app.module.ts src/worker.ts --max-warnings=0`.
- API: `.\node_modules\.bin\jest.cmd --runInBand --testTimeout=60000 src/modules/privacy/account-deletion.postgres.spec.ts src/modules/auth/otp.service.spec.ts src/modules/auth/postgres-otp.store.spec.ts`:
  22 unique cases across final runs (6 native HTTP/PostgreSQL/worker and 16 OTP).
  The final 6-case native rerun also checks deleted-account KYC denial/immutability.
  OTP delivery is captured in test memory, not live SMS/WhatsApp.
- Mobile (`apps/mobile`): `C:\flutter\bin\flutter.bat test --no-pub test/features/privacy/account_deletion_test.dart test/core/router/guards_test.dart test/features/profile/profile_test.dart`:
  21 passed; `flutter.bat test --no-pub test/features/auth/session_controller_test.dart --plain-name T-019`:
  1 passed; `flutter.bat analyze --no-pub`: clean. Commands use the installed SDK.
- `tools/codegen.sh` (Git Bash/Flutter PATH), `flutter.bat gen-l10n`,
  `dart.bat run build_runner build --build-filter=lib/core/router/routes.g.dart`:
  generated from source; existing OpenAPI paths/schemas compared unchanged,
  two new paths/three schemas. Generated Dart analysis and admin `tsc --noEmit` pass.
- `C:\flutter\bin\flutter.bat build apk --debug --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json --no-pub`:
  built `build/app/outputs/flutter-apk/app-dev-debug.apk`. Diff whitespace check passes.

Manual verification (pending; synthetic accounts only):
1. Open account deletion as a customer/vendor, including unfinished onboarding;
   review consequences and vendor dues. Cancel the final dialog; nothing deletes.
2. Send deletion OTP, reject a login/wrong code, then confirm the deletion code.
   Verify all devices sign out, local data clears and old tokens cannot read data.
3. In the isolated test environment, inspect the request/deadline and worker
   ERASING/ERASED audit; exercise a recorded hold/file failure and retry. Confirm
   financial balances remain identical and a fresh identity owns no old records.
4. Check actual Android keyboard/TalkBack/200% scroll, offline/uncertain retry,
   native secure-storage cleanup and real UI → API → DB → UI behavior.

Live OTP delivery remains NOT_RUN: provider delivery is simulated in native tests.
Physical-device secure storage/TalkBack and live UI/API journey are NOT_RUN: adb
devices reported no attached Android device. Manual PASS/G4 remain pending. iOS
validation is deferred. No standalone app service was started. The newly started
adb daemon was stopped after the device check; pre-existing services were preserved.

## T-107 Help/FAQ/legal (2026-11-19): READY_FOR_VERIFY

Vendor More/settings and customer Profile/settings now open `/account/help`
(S-V-29/S-C-34), including when personal-profile loading fails. The existing
published CMS FAQ API supplies expandable English plaintext questions/answers,
All/Orders/Payments/Delivery/Account/KYC/General and current-page custom topics,
20-row topic-preserving pagination and empty/error/retry states. Unknown topic
slugs display as readable CMS content. No seeded/fake FAQs or HTML renderer.

Five downloaded FAQ pages are retained in existing encrypted storage, scoped by
environment/account/role and exact topic/offset. Offline cached data is labelled
with its last download time (UTC download metadata, not an authoritative business
clock). Uncached queries never relabel another page. Read/write failures remain
readable where possible; recovery merges newer memory pages while preserving the
five-page bound and clears storage warnings after a successful write. Fresh empty
results replace old public entries, explicit denial drops the matching cached page,
and disposed responses cannot publish/write. No business mutation/queued write.

Terms/Privacy links from Help/vendor settings reuse T-126's CMS reader, now using
explicit public requests without account credentials or auth refresh/logout on a
public error. Returned document type must match the selected type; exact published
version/plaintext are shown, never invented legal text. S-COM-08 `/common/legal`
has a Terms/Privacy selector and is reachable from the sign-in form's Published
legal documents link. Reading it preserves a pending post-login destination;
force-update/startup guards retain priority and external unknown links remain
subject to normal validation. The existing sign-in consent review uses its reviewed
build-configured Terms/Privacy bundle; this read-only CMS viewer does not record
agreement, replace those accepted versions or rewrite historical consent records.

Q-30 exception (explicit user decision): phone, email and hours remain unpublished
TBD. Call/email buttons are disabled and explain unavailability. TODO(Q-30) beside
the controls and SCOPE records future configuration/verification and native intent
wiring. No contact values, dial/email requests, ticket/chat flows or deferred
finance/referral actions are fabricated. Contact intents are intentionally outside
this approved slice, not claimed as passing. T-019 deletion/retention is unchanged.

Changed source: `lib/features/help/`, shared profile/legal controller/view, auth
sign-in link, dashboard/profile/vendor settings links, router/guard handling,
English ARB/generated l10n and focused Help/routing tests. The existing T-158
content APIs/contracts/clients/schema are unchanged; no API codegen, dependency,
financial/grant/consent backfill, native Android/iOS source change or new migration.

Executed commands (C:/flutter/bin SDK, apps/mobile unless noted):

```powershell
flutter gen-l10n
flutter analyze --no-pub
flutter test --no-pub test/features/help/help_test.dart test/features/profile/profile_test.dart test/core/router/app_router_test.dart test/core/router/guards_test.dart test/features/auth/auth_pages_test.dart
flutter test --no-pub test/features/help/help_test.dart --plain-name 'common legal reader'
flutter test --no-pub test/features/help/help_test.dart
flutter build apk --debug --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json --no-pub
# apps/api; NATIVE_TEST_DATABASE_URL privately rewritten from .env to ONLY
# local supplybiz_service_area_test; credentials never printed:
.\node_modules\.bin\jest.cmd --runInBand --testTimeout=60000 src/modules/content/content.postgres.spec.ts
# repo root:
git diff --check
```

Results across final focused runs: 34 unique mobile cases (33 in the combined run
plus the new cache-read-recovery case in the nine-case Help rerun) + seven existing
native CMS/FAQ/legal/production Next-BFF/PostgreSQL regressions = 41 PASS. Mobile
coverage includes exact topics/pages, bounded scoped cache, late-response fencing,
read/write recovery, public 401/no account side effects, document-type binding,
360px/200% plaintext/support states, anonymous legal switching, pending-deep-link
preservation, auth consent/role/logout and existing profile/routing regressions.
Final mobile analysis, Android dev APK and diff check PASS. Localization regenerated;
no screenshot baselines. Existing test DB mobile/current legal pointers restored,
task-owned FAQ/legal fixture records removed and test API/Next processes closed.
Only task-created build daemon stopped; pre-existing services/devices preserved.

NOT_RUN: no attached adb device, so real native encrypted cache/process restart,
TalkBack/live Android UI-API-DB/auth journey and manual PASS/G4 remain pending.
Phone/email intent tests are intentionally deferred by Q-30, not a device failure.
iOS deferred. Main development DB was not changed; no API build was needed because
backend source/contracts are unchanged. Runtime requires the existing content API
and actual CMS publications; missing publication shows an explicit unavailable state.

Manual Android verification (not executed):
1. Publish synthetic English FAQs in the existing test CMS, including multiple
   topics and more than 20 records. Open Help from both roles, expand long text,
   filter/page and hide an entry; only fresh published records should appear.
2. Download several pages, disconnect/restart, and check exact cached topic/page
   labels/time, uncached empty/error behavior and refresh recovery. Switch accounts/
   roles/logout and verify there is no cross-owner cache reuse. No writes replay.
3. Signed out, open Published legal documents and switch Terms/Privacy; verify exact
   CMS versions/plaintext and unavailable/offline states. Repeat while a valid
   post-login deep link is pending, and confirm the destination resumes after
   normal sign-in. Force update must still block. Reading creates no consent.
4. Verify support phone/email/hours stay unpublished and both actions disabled.
   Check 360px layout, 200% text, keyboard, TalkBack and legal navigation from Help,
   Profile/About and vendor settings. Configure real contacts only under the later
   Q-30 TODO; do not use placeholder contact data.

## T-126 profile/settings/About (2026-11-19): READY_FOR_VERIFY

The customer Profile tab (S-C-27) and vendor Settings -> Profile and account open
owned profile details. `/account/profile/edit` edits personal name, optional
contact email and profile photo; authenticated mobile is selectable/read-only.
Personal name is users.name, not the reviewed vendors.business_name. No role,
mobile, status or KYC change is accepted by the profile API. Email is explicitly
unverified contact information. The role-specific customer entry links My addresses.

Settings (S-C-33) links existing notification preferences and role switching,
About, logout and Clear profile cache. Cache clearing removes only this owner's
saved profile/read photo bytes while retaining frozen profile changes and other
features' pending/offline-delivery state. The confirmation explains that scope.
Deletion remains unavailable under T-019/Q-20. Help remains with T-107; deferred
Money/referral/payment-method routes are absent. Q-30 contacts remain unpublished
TBD at the user's request; SCOPE records the TODO to configure them later, while
FAQ/legal work may proceed separately.

About (S-C-36) obtains the actual installed Android version, opens Flutter's
packaged open-source license page, and links Terms/Privacy. Legal links display
existing T-158 CMS plaintext and its exact published version, with unavailable/
retry and stale-in-memory states; no placeholder legal document or fake consent.
This viewer can be reused by T-107. Existing login consent/build legal text and
historical consent rows are unchanged by reading About/CMS content.

`GET/PUT /me/profile` uses current session/active-user ownership, expected server
updatedAt, owned READY PROFILE media, required Idempotency-Key, audit and atomic
replay. Stale edits are explicit conflicts; mobile/roles/status/owner fields are
rejected. Audit records field-change flags rather than name/email/photo bodies.
Profile/read-photo cache and frozen write body/key use existing encrypted SQLCipher
storage scoped by environment/account/role. Offline saved data cannot write;
uncertain replies keep the exact pending request across recreation. Clear cache
never clears pending changes. Photos are bounded to 5 MiB and fetched through the
authenticated UUID media endpoint, never an arbitrary URL. The existing Android
SAF picker/media normalization is reused without a new dependency. Uploading only
stages owned media; explicit Save applies it to the profile. Same-instance photo
upload retries reuse the bytes/key; after process loss the user may need to pick
again. Profile save retries are durable; no automatic upload/save on restoration.

Changed source: API `modules/profile/` and AppModule; mobile `features/profile/`,
customer/shared routes, vendor profile link, English ARB/generated l10n; focused
native/mobile tests and generated OpenAPI/TS/Dart clients. Existing users name/
email/photo columns suffice: no schema migration, dependency, KYC/financial/grant
or retention-policy changes. Compatibility comparison found one new path and two
schemas; every existing operation/schema remains unchanged.

Executed commands (repo root unless noted; C:/flutter/bin SDK):

```powershell
# Git Bash with Flutter SDK in PATH:
bash tools/codegen.sh
# apps/api:
.\node_modules\.bin\tsc.cmd --noEmit
.\node_modules\.bin\eslint.cmd src/modules/profile src/app.module.ts --max-warnings=0
.\node_modules\.bin\tsc.cmd -p tsconfig.build.json
# NATIVE_TEST_DATABASE_URL privately rewritten from API-local .env to ONLY
# local supplybiz_service_area_test; no credentials printed:
.\node_modules\.bin\jest.cmd --runInBand --testTimeout=60000 src/modules/profile/profile.postgres.spec.ts
# apps/admin (shared TS-client compatibility):
.\node_modules\.bin\next.cmd typegen
.\node_modules\.bin\tsc.cmd --noEmit
# apps/mobile:
flutter gen-l10n
flutter test --no-pub test/features/profile/profile_test.dart test/core/router/app_router_test.dart test/features/settings/vendor_settings_test.dart
flutter analyze --no-pub
dart analyze ../../packages/api_client
flutter build apk --debug --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json --no-pub
```

Results: five native profile HTTP/PostgreSQL + 23 focused mobile checks = 28 unique
PASS. Mobile tests include 200% text, read-only phone/validation, byte/key transport,
photo staging/removal, frozen recovery, safe cache clearing, disposal/owner denial,
CMS legal and About/license links plus route/vendor-settings regressions. Initial
MapEntry identity matcher and test lint findings were corrected. API checks/build,
admin typecheck, mobile/generated-client analysis, final Android dev APK and root
git diff --check PASS. Native media ownership fixtures use metadata; mobile media
HTTP is simulated, not evidence of live native picking/upload/download.

No adb device attached: actual Android photo picker/media round-trip, real native
storage/restart, TalkBack and live UI-API-DB journey NOT_RUN. Manual PASS/G4 pending;
iOS deferred. No main development DB mutation/migration. Test API processes closed;
only task-created build daemon stopped, pre-existing services/devices preserved.

Manual Android verification (not executed):
1. Open customer Profile, edit name/email and confirm mobile cannot change. Save,
   reload/restart and verify the values; test invalid email and stale-editor review.
   As vendor, confirm the personal profile does not change reviewed business/KYC.
2. Choose a PNG/JPEG photo through SAF, preview the staged result, explicitly Save,
   then remove it and Save. Verify ownership/private download and interruption/
   same-key recovery; no save should happen automatically after recreation.
3. Open notification preferences/role switch, clear profile cache and verify pending
   changes/offline deliveries remain. Test offline warnings, logout/account-role
   isolation and blocked-session denial, keyboard, 200% text and TalkBack.
4. Open About: compare installed version, inspect licenses, read published CMS
   Terms/Privacy and exact versions. With no published content or offline, check
   unavailable/stale messaging. Deferred finance/referral/payment-method links must
   be absent; help/contact/deletion remain with their owning tasks.

## T-106 vendor settings/re-verification (2026-11-19): READY_FOR_VERIFY

More -> Vendor settings opens S-V-20. Business information and delivery settings
have owned/versioned generated-client editors; KYC/bank opens a separate secure
S-V-33 instance of the existing masking/upload/FLAG_SECURE flow. The menu links
working account/role/logout, service area, notification preferences, subscription
settings and plans. Terms/Privacy/help and deletion stay unavailable until their
owning T-107/T-019 work; no placeholder route is enabled. Payment UPI publication
is not changed: KYC UPI remains verification-only, separate payment settings stay
outside this task. Shop photo is retained; this business editor does not replace it.

Business-name edits warn before save and create a fresh PENDING review snapshot.
Bank/PAN/Aadhaar edits warn and send an expected-submission revision. Discovery is
hidden until approval (ADR-034), and reappears only if normal active-plan/vendor
eligibility still holds. Pending revisions can be superseded atomically; approved/
rejected/superseded evidence cannot be changed or deleted. Reviewer UI accepts
PENDING and shows the submitted business-name snapshot. An initial MANUAL_REVIEW
submission must finish review before settings can replace it; stale reviewers
cannot approve a newer submission. Existing orders and financial records are
retained; no cancellation/reversal or historical price backfill is introduced.

Delivery settings use exact integer paise, explicit non-overlapping IST slots,
shared settings version and nullable same-day cutoff. Same-day requires an explicit
cutoff. Empty slots remain empty; the form suggests common slots without saving
them automatically. Changes affect future checkout quotes, not existing bills.
No setting enables checkout Khata. Availability/holidays use their existing flow.

Saved profiles and pending bodies/keys use existing encrypted per-environment/
account/role storage. Offline profiles are labelled stale and cannot write. New
writes require a durable frozen payload/key before sending. Pending settings show
the saved values; retry keeps the original operation even across recreation or
another editor. Definitive conflict requires explicit reload/review. KYC secrets
remain in the encrypted revision draft until acknowledgment can be persisted, then
PAN/account and replay body/key are cleared. No automatic submit on open/resume.
Session/role lifetime fences late reads and writes. Logout uses the existing
server-session/local-wipe flow.

Source: `features/settings/`, secure onboarding controller/page, dashboard/router,
English ARB/generated localization, API vendors/KYC/controller DTOs, two additive
migrations, reviewer page and regenerated clients. No new dependency/iOS change.
API compatibility check: three new paths plus PUT on existing /vendor/kyc, three
new schemas; only optional response fields businessName/sameDayCutoff were added.
Existing operations and other schemas were compared and remain unchanged.

Executed checks (C:/flutter/bin SDK; repo root for pnpm/codegen):

```powershell
pnpm.cmd --filter @supplybiz/api prisma:generate
pnpm.cmd --filter @supplybiz/api typecheck
pnpm.cmd --filter @supplybiz/api lint
pnpm.cmd --filter @supplybiz/api build
pnpm.cmd --filter @supplybiz/admin typecheck
pnpm.cmd --filter @supplybiz/admin lint
pnpm.cmd --filter @supplybiz/admin build
# Git Bash, SDK in PATH:
bash tools/codegen.sh
# apps/mobile:
flutter gen-l10n
flutter analyze --no-pub
flutter test --no-pub test/features/settings/vendor_settings_test.dart test/features/onboarding/onboarding_test.dart test/core/router/app_router_test.dart
flutter test --no-pub test/features/settings/vendor_settings_test.dart
dart analyze ../../packages/api_client
flutter build apk --debug --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json --no-pub
# apps/api; connection targets rewritten privately to supplybiz_service_area_test:
.\node_modules\.bin\prisma.cmd migrate deploy --schema src/prisma/schema.prisma
.\node_modules\.bin\jest.cmd --runInBand src/modules/vendors/vendor-settings.postgres.spec.ts
.\node_modules\.bin\jest.cmd --runInBand --testTimeout=60000 src/modules/kyc/kyc.postgres.spec.ts
```

Final evidence across focused runs: seven native settings/checkout/discovery/
re-verification cases + nine legacy native KYC/encryption/immutability/review cases
+ 23 focused mobile cases = 39 unique PASS. API/admin checks/builds, mobile and
Dart-client analysis, final Android dev APK and git diff --check PASS. Initial
native failures found the old KYC DB checks (expanded by migration), a synthetic
phone fixture and the existing hook's five-second Windows ACL timeout; corrected
and focused reruns pass. Initial route collision was fixed before final generation.
Optional legacy KYC_ADMIN_SMOKE browser-server case was skipped (flag not enabled),
not counted as PASS. A temporary automatic-approval usage limit was resolved on
retry; unavailable command was not claimed as executed.

Both 202611190003_kyc_business_snapshot and 202611190004_kyc_pending_review were
applied ONLY to supplybiz_service_area_test. Main development DB was not migrated.
The latter expands state checks/unique-open-review index and retains closed-row/
submission-field immutability in the DB trigger. Apply both through the normal
migration workflow before running this source against another local environment.
Rollback is by forward-compatible fixes: do not drop review evidence/columns or
shrink status checks while PENDING/SUPERSEDED rows exist. No financial backfill,
plan grant, source-ledger change or retention-policy decision. Native tests use
synthetic accounts/documents and local AES; existing production KMS fail-closed
behavior remains and no live KYC/provider delivery is claimed.

NOT_RUN: no attached adb device, so actual secure file picker/native encrypted
restart/OS-kill/live UI-API-DB/TalkBack journey. Manual browser pending-review UI,
manual PASS and G4 remain pending. iOS deferred. Task-created build daemons stopped;
pre-existing build daemons/devices preserved.

Manual Android verification (not executed):
1. With the migrations applied to the intended local runtime, open More -> Vendor
   settings. Change delivery charge/minimum/IST slots/cutoff, compare a new customer
   quote, and confirm a previously created order retains its saved bill.
2. Edit a verified business name: verify the warning and PENDING status, hidden
   customer discovery and the admin snapshot/queue. Approve the current review and
   confirm normal eligible discovery returns. Reject or supersede another revision;
   old submissions must not be editable/approvable.
3. Edit bank/PAN/masked Aadhaar using the secure picker, save for review, interrupt
   the response and restart. Retry must retain identical saved details/key, avoid
   duplicate review, and clear raw bank draft values after acknowledged success.
4. Test stale editors, offline saved profile, account/role/logout isolation and
   suspension. Check menu links, scrollable warnings, keyboard, 200% text, TalkBack
   and native FLAG_SECURE on Android. Legal/help/deletion entries remain unavailable.

## T-102 vendor Reports (2026-11-19): READY_FOR_VERIFY

More / dashboard Reports and recorded-sales tiles open `/vendor/reports`
(S-V-17). The sales tile carries the selected business date; lifetime sales opens
range reports with the explicit 366-day limit, never a fabricated lifetime range.
Today, week-to-date, month-to-date and custom inclusive IST dates use server
businessDate. Summary shows exact BigInt paise, signed net receipts, exact milk,
legacy unknown-volume warning, current dues/customers and gross reconciliation.
Daily/clipped-week tables and 20-row paginated sold-product snapshot groups use
the generated T-100 APIs. Product total covers every page. No chart/PDF scope.

T-101 generated export create/status/download freezes CSV dates/key before POST
in existing encrypted environment/account/role storage. Lost responses retain
that key/body through recreation; changing filters does not change a pending CSV.
Known artifacts can be explicitly reset for a new request. Downloads recheck live
server access. The mobile ignores downloadPath/remote filenames, checks byte size
and sends the original bytes to Android, which validates SHA-256, UUID, dates and
8 MiB capacity before opening ACTION_SEND with a narrow FileProvider content URI.
Only selected receivers get read permission; no new package/storage permission.
Chooser-open acknowledgment does not claim a recipient saved/sent the file.
Private temporary exported files are capped at ten; files older than 24 hours are
pruned on the next share, and logout deletes this dedicated cache before clearing
the wipe-pending marker. They are explicit exported copies, not offline report
storage. Copies saved to another app remain under that app's control.

A single encrypted saved summary is labelled stale offline; tables require fresh
reads and exports are disabled until summary refresh. Cached summaries never grant
advanced access. Server plan denial clears tables and shows support-assisted
BUSINESS/PREMIUM guidance; other authorization denial clears private report state.
Late disposed responses cannot publish/write/share. Pending export read/write
failure blocks sending a new request. All strings are English ARB; 200% text and
horizontal tables are covered by the focused widget smoke.

Changed source: `lib/features/reports/`, dashboard/router integration, `app_storage.dart`,
English ARB/generated l10n, Android `ReportSharing.kt`, MainActivity, manifest and
`res/xml/report_export_paths.xml`; focused report/dashboard/logout tests.
No API/schema/client-contract/dependency or iOS change.

Executed in `apps/mobile` with `C:\flutter\bin` tools:

```powershell
flutter gen-l10n
dart format lib/features/reports lib/core/router/app_router.dart lib/features/dashboard/dashboard_page.dart lib/core/storage/app_storage.dart test/features/reports test/core/storage/app_storage_test.dart
flutter analyze --no-pub
flutter test --no-pub test/features/reports/reports_test.dart test/core/network/reports_client_test.dart test/core/network/report_exports_client_test.dart test/core/storage/app_storage_test.dart test/features/dashboard/dashboard_test.dart test/core/router/app_router_test.dart
flutter build apk --debug --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json --no-pub
```

Results: final analysis clean; 34 focused tests PASS; final development APK PASS
(`build/app/outputs/flutter-apk/app-dev-debug.apk`). Root `git diff --check` PASS.
Initial checks exposed an outdated disabled-Reports expectation and widget finder/
reload issues; corrected, final combined run passed. `adb devices` showed no
attached device: native chooser/save, real encrypted-storage/process restart,
TalkBack and live UI-API-DB journey NOT_RUN. iOS deferred. Manual PASS/G4 pending.
Prior T-100/T-101 migrations were applied only to the isolated test database;
prepare the intended local runtime DB through the normal migration workflow before
live report/export verification. No runtime DB changes were made for T-102.

Manual Android verification (not yet executed):
1. Open Reports from More and the selected-date sales tile. Test Today/week/month,
   leap/custom dates and the 366-day boundary; compare gross, signed receipts,
   scheduled-order counts and current dues/customers with known records.
2. With active BUSINESS/PREMIUM, inspect zero-day/week rows, product pages and
   reconciliation. Downgrade/expire via the authorized admin flow: summary follows
   server history policy; tables/CSV lock with support guidance.
3. Download/share CSV to a receiving app and save/open it. Compare all product
   groups and exact paise/quantity columns; import large numbers as text. Cancel
   chooser, retry after connection loss/recreation, and verify frozen dates/key.
4. Test offline saved-summary warning, suspension, logout/account isolation and
   exported-cache deletion. Check long product names, horizontal tables, 200%
   text and TalkBack on a device; confirm no automatic sharing on recreation.

## T-105 vendor Plans (2026-11-19): READY_FOR_VERIFY

More → Plans, dashboard plan guidance → View plans and owned PLAN_EXPIRING/
PLAN_EXPIRED inbox items open `/vendor/plans` (S-V-27/28). This enables the Plans
entry recorded as future UI in the earlier T-031 handoff. The existing generated
`GET /vendor/plan` and `GET /vendor/plans` display assigned tier, server status,
start/end instants in IST, active-customer usage/cap/canAddCustomer, available/
locked features, admin-managed catalog names/features/reference duration prices
and the server's Most popular flag. Money uses integer paise via BigInt formatting.

The screen explains support-assisted assignment/extension, no trial/grace,
unassigned setup allowance, scheduled activation, expiry history/settlement/
existing-order exceptions and blocked new business. At/over-cap downgrades retain
customers/history and explain the server growth denial. It sends GET requests only:
no local plan grant, tier upgrade/deactivation, checkout, payment link, invoice,
receipt verification or fabricated payment/provider state. Status is taken from
the server, never inferred from device date, catalog price or a selected tier.

Bounded encrypted environment/account/role cache supports offline reading; current
assignment and catalog have separate stale/error states. A fresh EXPIRED assignment
is retained if catalog loading fails, and old ACTIVE data never replaces it. Auth/
ownership denial from either endpoint hides/clears both cached parts. Disposal
fences late reads and writes. Refresh/resume obtains current server policy; saved
features never grant an operation. Reminder routing accepts only the exact owned
vendor plan reminder type/path; arbitrary push paths still fall back to the inbox.
Existing 7/3/1-day/expiry scheduling, server grants/limits and FCM are unchanged.

Executed from `apps/mobile` using `C:\flutter\bin\flutter.bat` / `dart.bat`:

```powershell
flutter gen-l10n
dart format lib/features/plans lib/features/dashboard/dashboard_page.dart lib/features/notifications/notifications_controller.dart lib/core/router/app_router.dart
dart format test/features/plans/plans_test.dart test/features/dashboard/dashboard_test.dart
flutter test --no-pub test/features/plans/plans_test.dart test/core/router/app_router_test.dart
flutter test --no-pub test/features/dashboard/dashboard_test.dart --plain-name 'T-031 More shows working active destinations'
flutter test --no-pub test/features/notifications/notifications_test.dart --plain-name 'TC-104 paths allow only implemented destinations and normalize subscriptions'
flutter analyze --no-pub lib/features/plans lib/features/dashboard/dashboard_page.dart lib/features/notifications/notifications_controller.dart lib/core/router/app_router.dart test/features/plans/plans_test.dart test/features/dashboard/dashboard_test.dart
flutter build apk --debug --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json --no-pub
```

Nineteen focused cases PASS: 11 new plan controller/widget/reminder cases, six
existing router cases, one More entry and one notification-path compatibility
case. TC-120/124–126 cover all four catalog caps/features, exact reference prices,
server status independent of device clock, support/expiry/over-cap/unassigned
guidance, 200% scrolling/empty/offline states, cache owner isolation, partial
failure, denial purge and disposal. The reminder case proves local safe routing,
not reminder dispatch or provider delivery. HTTP and storage are simulated; the
existing T-103 real DB/plan-policy evidence is unchanged and was not rerun here.
Initial 200% widget assertion needed scrolling before locating off-screen state;
that check and focused brace lint issues were corrected. Final analysis clean and
normal Android dev APK PASS (63.1 seconds); build log `%TEMP%/supplybiz-t105-apk.log`.

No API/contract/schema/dependency change or API-client regeneration; English ARB/
localization regenerated. Root `git diff --check` passes. `adb devices` listed no
attached device; no emulator/service started. Native SQLCipher/restart/logout wipe,
TalkBack, actual plan-reminder/FCM delivery and live mobile→API→DB→admin refresh are
NOT_RUN, manual PASS/G4 pending; iOS deferred. Task-created Gradle daemon stopped;
pre-existing adb preserved.

Manual verification on Android (pending):
1. Open More → Plans as a synthetic vendor. Compare all four catalog prices/
   durations/caps/features/popular flags and current assignment/status/IST validity
   to API/admin values. Only informational prices and support guidance should show.
2. Use the authorized admin workflow to assign/extend/change a tier; refresh/resume
   mobile and verify limits/features/status update from the server. Check scheduled,
   unassigned, expired and unavailable states; no local trial or automatic upgrade.
3. Downgrade above the customer cap: all customer/history records remain, growth is
   blocked and guidance appears. Verify actual server expiry/locked operations and
   permitted existing-record/settlement exceptions using their owning screens.
4. Open an owned plan-expiry reminder and the dashboard View plans action. Wrong-
   role, spoofed/external/suffixed paths must not navigate. Real 7/3/1-day/expiry
   provider delivery remains a separate manual/server operational check.
5. Cache, disconnect, restart, refresh and switch role/account/logout; check stale
   labels, isolation/wipe and denial purge. Verify partial failures, 200% text,
   TalkBack, scrolling and labelled 48dp controls, with no purchase/invoice action.

## T-031 vendor dashboard/shell/More (2026-11-19): READY_FOR_VERIFY

Vendor Home now consumes the generated T-030 dashboard and existing current-plan
APIs. Header shows owned shop name/city/photo (private authorized media or icon)
and stored VERIFIED state. Seven tiles preserve exact server order counts, gross
sales/lifetime recorded sales, decimal milk volume and active customers. Today is
the server IST date; custom dates are validated, and cache misses never relabel a
different date's values. Current stock/customer semantics and incomplete milk
volume are explained. Gross sales are explicitly separate from payment receipts.

Encrypted cache keys include API environment, account and role, retaining at most
14 successful date snapshots. Offline reads show saved values and the server
last-updated timestamp in IST. Authorization/ownership denial hides and clears
cached metrics/plan/header; storage failure is reported separately from fresh
network success. Late reads after disposal cannot publish/persist new private
state. Refresh/resume, owned order notices and returns from destinations refresh
server metrics; no financial mutation is introduced by the dashboard. Cached plan
state never grants access; fresh plan failures remove old entitlements/banner state.

Existing Home/Orders/Products/Customers/More navigation stacks remain. Order-count
tiles open date-filtered lists; Pending maps to existing `status=ALL&tab=ONGOING`
(NEW/ACCEPTED/PREPARING/OUT_FOR_DELIVERY). Active milk/customer destinations reuse
their complete owned lists with initial filters; milk excludes inactive products.
Add Product opens the existing owned editor, retaining its mutation/retry guards.
Payments, Quick Sale, Khata, subscriptions, deliveries, availability, service area,
notifications and account/security open existing real pages. Verification and
expiry/unassigned/scheduled-plan banners offer status/support guidance, no purchase.
Reports/sales-history drilldowns, plan catalog, vendor settings and Help/FAQ are
disabled as Available soon until T-102/T-105/T-106/T-107; no placeholder route or
deferred staff/wallet/reviews/campaign item was added. Dashboard sales/lifetime
tiles currently display values; report history navigation belongs to T-102.

Executed from `apps/mobile` with `C:\flutter\bin\flutter.bat` / `dart.bat`:

```powershell
flutter gen-l10n
dart format lib/features/dashboard lib/features/orders/orders_controller.dart lib/features/orders/orders_pages.dart lib/core/router/routes.dart lib/core/router/app_router.dart
dart format test/features/dashboard/dashboard_test.dart lib/features/products/products_page.dart
flutter test --no-pub test/features/dashboard/dashboard_test.dart test/core/router/app_router_test.dart test/core/network/vendor_dashboard_client_test.dart
flutter test --no-pub test/features/orders/orders_test.dart --plain-name 'TC-045 list filters/search and pagination render at 200%'
flutter test --no-pub test/features/dashboard/dashboard_test.dart --plain-name 'T-031 milk stock drill-down'
flutter analyze --no-pub lib/features/dashboard lib/features/orders lib/features/products/products_page.dart lib/core/router test/features/dashboard/dashboard_test.dart
flutter build apk --debug --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json --no-pub
```

21 focused mobile cases PASS: 13 new dashboard/controller/widget checks, six router,
one T-030 transport and one existing order filter/pagination case. The first combined
command passed the initial 12 dashboard cases plus router/transport; the later added
active-milk case passed separately. Exact large paise/volume, per-date owner cache,
bound/denial/disposal/cache failure, optional plan outage, pending query, header,
offline expiry/banner, navigation, shared product editor and 200% layouts covered.
HTTP/storage are simulated; native SQLCipher, logout key wipe and OS recreation are
not claimed. Initial syntax/lint, locale setup and readable timestamp-format issues
were corrected before final checks. Final analysis clean; normal dev APK PASS
(25.2 s final build after active-milk correction; first build 58.7 s).

Executed from `apps/api` against only the existing isolated local test DB:

```powershell
$baseLine=Get-Content .env | Where-Object { $_ -match '^DATABASE_URL=' } | Select-Object -First 1
$dashUrl=[UriBuilder]::new(($baseLine -replace '^DATABASE_URL=', '').Trim('"', "'"))
$dashUrl.Path='/supplybiz_service_area_test'
$env:NATIVE_TEST_DATABASE_URL=$dashUrl.Uri.AbsoluteUri
$env:NODE_ENV='test'
$env:OTP_DELIVERY_MODE='disabled'
.\node_modules\.bin\jest.cmd --runInBand --testTimeout=90000 --runTestsByPath src/modules/dashboard/vendor-dashboard.postgres.spec.ts -t 'TC-030 five'
.\node_modules\.bin\eslint.cmd src/modules/dashboard/vendor-dashboard.postgres.spec.ts --max-warnings=0
```

One native HTTP/PostgreSQL check PASS proves Pending drilldown parity (five ongoing
orders matching dashboard) and tenant/date scoping. Six other API cases unselected;
no backend production/contract/schema/dependency change or client regeneration.
English ARB source/generated localization updated. Root `git diff --check` passes.
`adb devices` listed no attached devices; no emulator was started. Native device/
encrypted-storage/process-restart/TalkBack/private-photo/live UI–API–DB checks are
NOT_RUN, manual PASS/G4 pending; iOS deferred. No long-running app service started;
test contexts closed. Task-started build daemon stopped; pre-existing adb preserved.
Build/native logs: `%TEMP%/supplybiz-t031-apk.log`, `supplybiz-t031-pending.log`.

Manual verification on Android (pending):
1. With prior API migrations applied and synthetic vendor data, sign in and compare
   header/verified/photo and all seven Home metrics to the API. Change date, restore
   Today, check gross-sales/current-stock explanations and unknown-unit warning.
2. Tap all/pending/completed order tiles, active milk and customers; compare filter
   dates/status and counts. Add a product through Quick actions, then return and
   refresh. Confirm Home/Orders/Products/Customers/More retain independent stacks.
3. Open every enabled More/quick action and notification/account destination. Check
   real verification/expired/scheduled/unassigned plan banners and support guidance;
   future UI entries stay disabled and deferred items absent, with no purchase CTA.
4. Cache two dates, enable airplane mode, restart and inspect last-updated/saved
   values. An uncached date must show no borrowed metrics. Restore network; change
   role/account/logout and verify cache isolation/wipe and suspended access denial.
5. Check 200% text and TalkBack, labelled >=48dp controls, scrolling, empty/error/
   loading/photo-failure states, invalid date and plan/network/storage failures.

## T-083 customer Khata (2026-11-19): READY_FOR_VERIFY

Customer bottom navigation → Khata (`/customer/khata`) shows exact signed global
Receivable/Payable/Net, search, All/Customers (personal)/Vendors and paged account
rows. A vendor row opens its read-only monthly ledger, source product/quantity
snapshots, persisted payment status, payable/paid/opening/closing totals and claims.
Standalone payments are not allocated to individual purchases. Personal rows open
`/customer/personal-khata/:id`: manual contact creation, edit/clear optional mobile,
confirmed contact deletion and versioned Gave/Got entry create/edit/delete. Gave
increases receivable; Got reduces it. No contacts permission is requested.

Settle dues refetches the separate vendor-owned payment settings and account limits
before the final action. The editable default is the current payable capped by the
selected billing account's current due/claim limit. Unpublished/unset payment VPA
offers cash only; KYC UPI is never reused. Cash explicitly asserts an existing cash
payment; UPI opens only a validated `upi://pay` intent with exact amount/payee/INR/
note. Android ignores all provider status and transaction extras. An encrypted,
account/role/environment/vendor-scoped review draft is saved before leaving the
app. Return/cancel/recreation never auto-launches again or auto-submits a claim.
Only **I've paid** submits a PENDING claim; vendor confirmation creates credit.
No handler exposes the same URI as an offline QR, VPA and Copy. Discarding a review
draft never changes the ledger. An uncertain HTTP mutation retains one frozen
body/key for explicit retry, including accepted-write/failed-local-ack recovery.
Stale data disables new writes; auth/ownership denial hides cached private data.

Dependency justification: pinned `qr: 3.0.3` is the maintained Dart-3.4-compatible
line for this project's Dart >=3.5 / Flutter 3.35.7 (Dart 3.9.2); qr 4.x requires
a newer SDK. BSD-3-Clause; 32,796 bytes of Dart library source, one already-present
`meta` dependency, no native binary/plugin or network service. Flutter includes its
license notice. The small Canvas renderer adds a four-module white quiet zone.
See [published versions](https://pub.dev/packages/qr/versions) and
[license](https://pub.dev/packages/qr/versions/3.0.3/license). Android launches directly
and handles ActivityNotFoundException per the
[official package-visibility guidance](https://developer.android.com/training/package-visibility/use-cases);
no app enumeration or new permissions. No API/schema/client contract changes.

Executed from `apps/mobile` using `C:\flutter\bin\flutter.bat` / `dart.bat`:

```powershell
flutter pub get
flutter gen-l10n
dart format lib/features/khata/customer_khata_controller.dart lib/features/khata/customer_khata_page.dart lib/features/khata/upi_device.dart lib/core/router/routes.dart lib/core/router/app_router.dart
dart format test/features/khata/customer_khata_fixture.dart test/features/khata/customer_khata_test.dart
flutter analyze --no-pub lib/features/khata lib/core/router test/features/khata/customer_khata_fixture.dart test/features/khata/customer_khata_test.dart
flutter test --no-pub test/features/khata/customer_khata_test.dart
flutter test --no-pub test/core/network/khata_client_test.dart test/core/router
flutter build apk --debug --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json --no-pub
```

PASS: clean final analysis; 15 new customer controller/widget checks (TC-250–255),
15 existing transport/router checks, normal dev APK including native Kotlin bridge.
New tests cover exact large paise, month/account paging, personal wire versions/date/
clear/delete, cash-only/due caps, changed payee/offline fences, saved launch before
simulated destruction, explicit paid/cancel, ignored fake provider status, no-handler
QR/VPA UI, uncertain immutable retry and 200% personal/fallback forms. HTTP, storage
and external UPI return are simulated; these are not real financial/provider evidence.
Initial analysis found compile/lint issues, corrected before final PASS. An initial
l10n/fix command used repository root/multiple paths and failed; corrected commands
from the mobile directory passed. qr pub get added only the justified QR package.

`adb devices` (Android SDK platform-tools) listed no devices; no emulator was started.
Actual native launch/return/no-handler/QR scan, native SQLCipher/process kill, live
customer UI → API/DB → vendor confirmation, TalkBack and manual PASS are **NOT_RUN**.
G3 remains pending; TC-256/iOS validation is deferred by ADR-025. Existing backend
T-082/T-081 PostgreSQL evidence is unchanged, not re-claimed as an execution here.

Manual verification on Android with synthetic accounts (pending):
1. Open Khata, compare global totals/tabs and a vendor's two monthly ledgers against
   the vendor view/DB, including advances, paid snapshots and independent payments.
2. Add a personal contact; Gave ₹200 increases receivable by ₹200. Edit to Got,
   change date/note, clear mobile, then delete entry/contact; verify ownership/version
   conflicts, refreshed balances and confirmed deletion.
3. With no published payment VPA, confirm only cash appears. Submit an actual cash
   claim, confirm PENDING/customer due unchanged, then vendor-confirm it once. Reject
   zero, negative, above-account-limit and above-current-due amounts.
4. In a test environment with a vendor-published synthetic VPA, inspect Android UPI
   payee/amount, cancel and return without a claim. Use no handler and scan the QR/
   copy VPA; confirm matching fields. Submit **I've paid** only after a test payment;
   verify PENDING until vendor confirms. Never infer payment from provider SUCCESS.
5. Kill/reopen while external UI is open and after a lost claim response. Review
   without auto-payment; retry one stored key/body and verify a single credit after
   vendor confirmation. Check logout/role/account isolation, offline blocks, changed
   payee/due review, TalkBack labels, 48dp controls and 200% scrolling.

## T-081 vendor Khata (2026-11-18): READY_FOR_VERIFY

Vendor More → Customer Khata / Payments & collection opens `/vendor/khata` and
`/vendor/payments`. Owned account search/All/Receivable/settled tabs, exact signed
debit/credit/paid/due, month ledger/collection paging, customer creation entry,
external payment recording, opening debit/credit, appended reversals and confirmed/
rejected payment claims implement S-V-23–26. Vendor inbox claim notices open the
owned customer ledger. Collections distinguish value date from recorded IST time.
Opening credits remain separate from actual collections; immutable corrections
retain originals. No bank settlement/transfer, wallet balance or payment UPI
settings UI is exposed; payment method labels are external records only.

Fresh server reads/permission flags fence writes. Financial forms validate exact
positive paise and required reasons, own their controllers through dialog teardown,
and freeze account/body/key before transmission. The existing encrypted account/
environment store retains one uncertain financial change for explicit same-key
retry, with no automatic resend or new attempt replacing it. Cached data is labeled;
denied roles clear identity/history but preserve an uncertain private action until
authorized replay or normal logout wipe. Another selected customer never receives
the cached ledger from a previous selection. New adjustments require an active
Khata entitlement; eligible expiry payment/claim settlement and replay remain.

Executed PASS from apps/mobile:

```powershell
flutter gen-l10n
dart format lib/features/khata test/features/khata lib/features/notifications/notifications_controller.dart test/features/notifications/notifications_test.dart lib/core/router/app_router.dart lib/core/router/route_widgets.dart
flutter analyze --no-pub lib/features/khata test/features/khata lib/core/router lib/features/notifications/notifications_controller.dart test/features/notifications/notifications_test.dart ../../packages/api_client/lib
flutter test --no-pub --timeout 60s test/features/khata/vendor_khata_test.dart test/core/network/khata_client_test.dart test/core/router/app_router_test.dart test/features/notifications/notifications_test.dart
flutter build apk --debug --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json --no-pub
```

25 checks PASS: nine new vendor controller/widget, two existing Khata transport,
six router and eight notification cases. Includes huge exact amounts, owned paging/
tabs/global totals, date-only payment body, adjustment reasons/claim versions,
committed-response and acknowledgement-write recovery, no send before local save,
stale/role/account/expiry fences, explicit confirmation and 200% opening forms.
Clean app/generated-client analysis and normal Android dev APK PASS (22.3 seconds).
OpenAPI/TS/Dart regenerated; four paths/seven schemas added with existing contracts
unchanged. API/ledger build/typecheck/lint and 23 focused checks pass separately
(17 actual native HTTP/PostgreSQL, six unit); see API README T-081. No DB schema,
grant, dependency or historical financial-data change. Mobile HTTP is simulated.

Android device/SQLCipher/recreation/TalkBack/live UI–API–DB/FCM: NOT_RUN, adb
reported no attached device. The earlier T-080 read-only emulator boots in this
session were unstable; no additional emulator or app service was started for
T-081. The task-started discovery adb daemon was stopped. iOS deferred; manual
PASS and G3 remain pending. No live/provider or comprehensive gate pass is claimed.

Manual verification (not performed):

1. More → Customer Khata: check All/Receivable/settled/search, signed advances and
   global receivables against vendor ledger; open a customer and switch months.
2. Record a dated cash/UPI/Bank/external-wallet payment with note; verify one CREDIT,
   exact due reduction and collection line/net total. No order allocation is invented.
3. Add opening DEBIT/CREDIT with required note for an owned customer; verify the
   distinct ledger entry. Reverse with reason; original/audit remain and net updates.
4. Confirm/reject a customer claim after checking receipt; verify one credit or a
   required rejection reason/notice. Concurrent payment must recheck current due.
5. Interrupt a response and recreate/retry the original key; verify one financial
   effect. Check expiry permissions, logout/account isolation, 200% and TalkBack.

## T-080 Quick Sale / offline outbox (2026-11-18): READY_FOR_VERIFY

Vendor More → Quick Sale opens `/vendor/sales` (S-V-11). Walk-in and owned active
customer modes use cached/paginated vendor products/customers, product search/type
chips, editable whole-pack quantities and exact paise rates/totals. Cash/UPI/Other
record external payment only. Walk-ins must pay in full; customer sales may leave
a balance. Confirmation freezes explicit rates, customer, payment, audit timestamp
and draft key. Server receipts show immutable item snapshots and paid/balance;
pending local entries never pretend to be completed sales. New sale is explicit.
Receipt sharing stays absent while its S-V-11 specification is TBD.

The existing encrypted snapshot store and native DeviceCoordination lease cover
cache + durable FIFO together. Pending sales reserve local stock; acknowledgement
applies the stock delta and dequeues in one write. Unknown sends retain the exact
key/body; known validation/stock conflicts release reservations, show review and
never create a local financial correction. Six failures stop automatic attempts;
explicit retry keeps identity. Uncertain actions cannot be discarded. Storage
failure before persistence sends nothing; failed acknowledgement persistence
recovers from disk before further writes. Account/environment namespaces and
logout/session fencing reuse T-050. The shared Android network-constrained worker
now discovers `:sales` as well as `:deliveries`; foreground/off-screen/resume sync
drains both under the existing safeguards. API/schema/ledger/dependencies unchanged;
no API client regeneration. Only English l10n regenerated.

Executed PASS from apps/mobile:

```powershell
flutter gen-l10n
dart format lib/features/sales test/features/sales integration_test/sales_test.dart test/features/deliveries/deliveries_test.dart lib/features/deliveries lib/core/router/app_router.dart lib/core/router/route_widgets.dart
flutter analyze --no-pub lib/features/sales test/features/sales integration_test/sales_test.dart lib/features/deliveries test/features/deliveries/deliveries_test.dart lib/core/router/app_router.dart lib/core/router/route_widgets.dart
flutter test --no-pub --timeout 60s test/features/sales/sales_test.dart test/core/network/sales_client_test.dart test/features/deliveries/deliveries_test.dart test/core/router/app_router_test.dart
flutter build apk --debug --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json --no-pub
```

31 checks PASS: ten POS, one generated sales transport, fourteen delivery/outbox
and six router cases. Clean analysis; normal Android dev APK build PASS (30.6s).
The cases cover exact huge amounts/bounds, full walk-in versus customer partial/zero
payment, editable rates, stock reservation/rollback, queue paging/account scope,
same-key recreation and committed-response/local-write failure, retry bounds,
authorization, 200% UI and receipt-only completion. The shared scheduler regression
now asserts both queues stay paused and resume off-screen. Its mock sales client
must be constructed inside tester.runAsync; otherwise Flutter fake-async setup
stalls before any POS request. The corrected harness passes. All test HTTP is
simulated; T-079's recorded real API/PostgreSQL evidence remains separate.

Android native smoke `integration_test/sales_test.dart` is supplied and analyzed,
but NOT_RUN: no physical device was connected, and two hidden read-only attempts
to boot the existing Pixel_5_4 API-34 emulator (1536 MB then configured 2048 MB)
never reached stable `sys.boot_completed`; adb alternated connected/offline.
Both task-owned emulator instances and the discovery adb daemon were stopped.
No emulator data was wiped, app/API service started or native pass claimed.
Suggested after a healthy Android device is available (NOT executed):

```powershell
flutter test --no-pub integration_test/sales_test.dart -d <android-device-id> --flavor dev --dart-define-from-file=config/dev.json
```

The supplied native scenario covers SQLCipher, two handles/controllers, shared
worker entry, uncertain replay, logout and 200%; it still uses simulated HTTP and
controller/DB recreation. Actual OS process kill/headless scheduling TC-059, live
UI–API–DB reconciliation, TalkBack, task manual PASS and G3 remain pending. iOS
deferred. No comprehensive gate is claimed.

Manual verification (not executed):

1. More → Quick Sale: add products, edit quantity/rate and compare exact totals;
   walk-in partial payment must remain blocked. Complete a fully paid cash sale.
2. Customer Sale: select an owned active customer, record partial/zero payment;
   verify the server receipt, stock and gross debit/paid credit/net due in Khata.
3. Go offline, complete multiple sales and inspect Pending sync/local reserved
   stock. Kill/relaunch Android, reconnect and verify one server sale per saved key.
4. Interrupt a committed response; retry the same saved record. Confirm no duplicate
   sale/stock/ledger effect. Stock/plan/customer rejection must prompt review.
5. Leave the screen to test foreground/background reconnect; verify logout/account
   isolation, 200% layout and TalkBack. Only acknowledged records have receipts.

## T-077 availability & holidays (2026-11-18): READY_FOR_VERIFY

Vendor More → Availability & holidays opens `/vendor/availability` (S-V-22).
The generated T-074 client supplies accepting-today, open-ended pause/resume,
server IST dates, paginated upcoming holidays, impact previews and mutations.
Holiday date/reason validation, counted confirmation, strictly future-only deletion,
server plan/suspension/role/version feedback and expired-plan reducing controls
are wired. New pauses use explicit Resume under FR-084; an existing finite pause
end is displayed in IST read-only. Resume/delete never recreates cancelled orders.

Snapshots and uncertain mutation body/path/key use the existing encrypted,
account/environment-scoped store. New writes require a fresh read; recovery is
explicit same-key retry, including a deleted holiday and an acknowledgement-write
failure. Role denial clears data. No API/schema/financial/history/dependency changes
or API client regeneration; only English l10n was regenerated.

Executed from apps/mobile:

```powershell
flutter gen-l10n
dart format lib/features/availability test/features/availability lib/core/router/app_router.dart lib/core/router/route_widgets.dart
flutter analyze --no-pub lib/features/availability test/features/availability lib/core/router/app_router.dart lib/core/router/route_widgets.dart
flutter test --no-pub --timeout 60s test/features/availability/availability_test.dart test/core/network/availability_client_test.dart test/core/router/app_router_test.dart
flutter build apk --debug --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json --no-pub
```

Normal Android dev APK build PASS (30.2 seconds), clean analysis and 18 focused checks PASS (eleven new controller/widget cases,
one existing generated transport and six router regressions). Cases cover all
holiday pages, exact strings/versions/keys, no writes on preview/cancel, local-save
failure, committed-response recovery/recreation/account isolation, stale/conflict/
role/plan fencing, server date picker, today-delete restriction and 200% pause UI.
The first dialog check exposed controllers disposed during the closing animation;
the dialog now owns them until unmount, and the check passes. These HTTP calls
are simulated; actual cancellation/ledger-preservation evidence remains T-074's
recorded native API/PostgreSQL checks, not a live mobile financial test.

Device runtime/native SQLCipher/OS-kill/TalkBack/live UI–API–DB/FCM: NOT_RUN;
adb reported no attached Android device/emulator. No emulator/app service started;
the task-started discovery-only adb daemon was stopped. iOS deferred. Manual PASS
and G3 remain pending.

Manual verification (not executed):

1. More → Availability & holidays: check server IST today. Turn accepting-today off;
   verify new same-day one-time orders are blocked and existing orders retained.
2. Mark today/future holiday with a reason; inspect impact, cancel once, then confirm.
   Verify eligible cancellations/customer notices; progressed orders/ledger remain.
3. Pause, inspect impact and confirm; resume and verify cancelled orders stay cancelled.
   Check expired-plan reducing controls and locked enabling/resume/removal.
4. Delete a future holiday and check future eligibility; today's Delete stays disabled.
5. Interrupt a response and recreate/retry: same key, one server action. Check logout/
   account isolation and actual Android 200%/TalkBack behavior.

## T-078 customer subscriptions (2026-11-18): READY_FOR_VERIFY

S-C-09/10/15/16 use generated customer APIs for address-owned daily/custom plans,
server estimates/configured slots, confirmation, pending/active subscriptions,
versioned edit/pause/resume/skip/cancel and paginated monthly statements. Vendor
Subscription tab and New Order open plans; Orders opens My subscriptions; owned
inbox/deep links open manage. Cash is the only setup preference without a separate
published payment UPI ID. KYC is never reused. No wallet/payment-settings screen
was added. Monthly amounts remain postpaid estimates; setup takes no funds.

Account/environment-scoped encrypted snapshots and exact saved mutation/key are
restored for explicit retry, with no automatic resend/new key after uncertainty.
Stale data cannot authorize writes; denied roles clear data. Server effective dates
and the 21:00 IST explanation handle frozen changes. Statement dates/quantities/
amounts are subscription-specific; paid/opening/closing/current balances are
clearly labeled as the shared vendor account, without invented payment allocation.
The existing exact paise formatter now also handles negative advance balances.

Executed PASS from apps/mobile (HTTP simulated):

```powershell
flutter gen-l10n
dart format lib/features/subscriptions/customer_subscriptions_controller.dart lib/features/subscriptions/customer_subscriptions_pages.dart lib/features/subscriptions/vendor_subscriptions_pages.dart test/features/subscriptions/customer_subscription_fixture.dart test/features/subscriptions/customer_subscriptions_test.dart test/features/subscriptions/vendor_subscriptions_test.dart
flutter analyze --no-pub lib/features/subscriptions lib/core/router lib/features/discovery/vendor_page.dart lib/features/checkout/new_order_page.dart lib/features/orders/customer_orders_pages.dart lib/features/notifications/notifications_controller.dart test/features/subscriptions/customer_subscription_fixture.dart test/features/subscriptions/customer_subscriptions_test.dart test/features/subscriptions/vendor_subscriptions_test.dart ../../packages/api_client/lib
flutter test --no-pub --timeout 60s test/features/subscriptions/customer_subscriptions_test.dart test/features/subscriptions/vendor_subscriptions_test.dart test/core/router/app_router_test.dart test/features/notifications/notifications_test.dart
flutter build apk --debug --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json --no-pub
```

32 focused tests PASS (eight new customer, ten vendor, fourteen router/notice),
clean analysis and normal dev APK build PASS (88 seconds). Widget cases check
200% setup, optional cash-only UPI, plan selection and cancel confirmation.
Controller cases cover paging, date-only bodies, lost-response/recreation exact
replay, storage failure, account/role isolation, cutoff/conflict and exact ledger
strings. Early checks fixed a date-only UTC assertion, widget runAsync setup and
offscreen statement assertion. Actual API/PostgreSQL evidence is in API README.

Android native device/SQLCipher recreation/OS-kill/TalkBack/live UI–API–DB and
live FCM checks: NOT_RUN, adb reported no connected device/emulator. No emulator
or application service was started. The discovery-only adb daemon was stopped
after checking. iOS deferred; manual PASS and G3 remain pending.

Manual verification (not yet performed):

1. Vendor → Subscription tab → plans: select an owned address and daily/custom
   product/qty/days. Check estimates, slots, tomorrow start and cash-only fallback.
2. Confirm setup; check Pending Approval or Active, then vendor approval and inbox
   link → My subscriptions/manage. No payment/ledger entry should arise at setup.
3. Edit, range/open pause, resume and skip around 21:00 IST; inspect server effective
   date and frozen-date explanation. Cancel only after explicit confirmation.
4. Open a delivered month's statement; compare snapshots/quantity/subtotal and
   shared paid/due totals with vendor ledger, including a payment reversal.
5. Interrupt a response, recreate and explicitly retry the saved change; verify
   one server mutation. Check logout/account isolation, Android 200% and TalkBack.

## Manual delivery settlement runtime (2026-11-18)

The first live Delivered action remained in the vendor outbox because the manual
API used the PostgreSQL administrator. The ledger deliberately fails closed for
unsafe runtime UPDATE/DELETE/balance privileges. The dedicated manual DB now has
`supplybiz_manual_app` (restricted login) and `supplybiz_manual_ledger_owner`
(non-login financial owner), configured with `tools/ledger-grants.sql`.
Ignored apps/api/.env.manual.local now sets both DATABASE_URL and
MOBILE_AUTH_TEST_DATABASE_URL to the restricted manual connection; original KYC
and admin encryption keys were retained. Source that file when restarting API or
worker; do not override these URLs back to the administrator. Normal migrations
remain an operator action, separate from the runtime login.

After the manual API restarted, the app rotated its session and retried the
already-saved delivery action. The API/DB confirmed DELIVERED/PAID with exactly
one order debit and one payment credit, and refreshed Customer Orders displays
Delivered. No direct order/ledger edits or replacement delivery action were used.
FCM is disabled in this manual configuration; pull to refresh customer tracking
when testing across emulators. Automated-test databases and task/module acceptance
statuses were unchanged.

## T-048/T-050 selected-date query fix (2026-11-18)

Generated vendor Orders/Deliveries clients send DateTime query objects, while
the API requires YYYY-MM-DD. The selected delivery date therefore failed server
validation and showed an empty stale list. An endpoint-scoped GET interceptor
now preserves the selected calendar day as a date-only query; mutation/audit
timestamps remain untouched. No API or generated-client source changes.

The regression reproduces the validation failure before the fix, then loads and
reloads an OUT_FOR_DELIVERY order on its selected date. Both fixtures now enforce
the real date-only query contract. All 22 focused order/delivery/queue regressions
and targeted analysis pass. Task manual acceptance/module gates remain pending.

Android dev APK built/installed on vendor emulator-5554 with the existing
localhost override/ADB reverse. Live date selection for 2026-11-19 now displays
the saved OUT_FOR_DELIVERY order and enabled Mark delivered/Mark failed actions.
No delivery or payment mutation was submitted during this check.

## Two-emulator manual API connectivity (2026-11-18)

The vendor emulator later timed out through 10.0.2.2 and showed an empty stale
order cache. Both emulators now run the localhost-override dev APK with
`adb -s <device> reverse tcp:3000 tcp:3000` and
`--dart-define=API_BASE_URL=http://127.0.0.1:3000/api/v1` after the dev JSON flag.
Recreate forwarding after emulator restarts. config/dev.json remains unchanged.
After restoring the vendor session, the real Orders screen displays the placed
NEW order from the dedicated manual DB. No order transition was submitted.
Customer-detail activity panels remain separate from the main Orders screen.

## Retry controls and checkout choices (2026-11-18)

Load Retry buttons are conditional on failure/recovery, rather than present on
successfully loaded screens. Explicit saved-write retry controls are preserved.
Existing pull-to-refresh and dedicated refresh actions remain available.

Checkout options depend on vendor/address, so quantity edits retain valid dates
and slots while invalidating the quote. Filling an initially empty cart or
replacing its vendor automatically loads fresh choices, including when a prior
request is in flight. Responses for an old vendor/address remain fenced. Empty
server slot lists still disable Review bill and show the availability message.

Live bill review also exposed generated midnight timestamps in checkout's
calendar-date payloads. A checkout-owned interceptor normalizes only quote/place
POST `deliveryDate` fields to YYYY-MM-DD without editing generated clients or
changing the API. The transport fixture now enforces the real API's date-only
rule for both operations; all nine checkout checks pass, including permanent
same-key retries, and targeted analysis is clean. The native checkout fixture
uses the same feature-owned API factory.

101 affected checks across checkout, discovery, products, customers, addresses,
orders, deliveries and subscriptions pass. New regression coverage checks
quantity changes/fresh quotes, delayed cart population, missing-slot guidance and
Retry appearing on failed loads then disappearing after recovery. A synthetic
07:00–09:00 slot was configured only for the existing verified vendor in the
dedicated manual DB, incrementing settings version; vendor settings UI is T-106.
Manual task acceptance/module gates remain pending.

Updated Retry UI installed on both existing Android emulators. Live customer
discovery no longer displays Retry after success. On emulator-5556, checkout
loads the manual-test slot, enables Review bill and retrieves a real API quote:
two packs total ₹116 with ₹0 delivery and an enabled Place Order action. No order
was placed. Customer retains the command-line localhost API override/ADB reverse;
vendor APK retains config/dev.json's original 10.0.2.2 URL.

## T-044 View vendor navigation fix (2026-11-18)

Pushing vendor details from the root-level discovery list previously duplicated
the existing customer shell page and triggered Flutter's navigator page-key
assertion. Vendor/product details now explicitly use the root navigator via
typed `$parentNavigatorKey`; their URLs, role guards and Back history remain.
Router output was regenerated from source with the scoped build filter.

The new Home → discovery → View vendor → product → Back regression reproduces
the original assertion before the fix and passes afterward. All 33 checks across
discovery, Home, app router and guards pass; targeted analysis is clean.
Task-specific manual PASS and module gates remain pending.

Android dev APK build/install passes on customer emulator-5556 with the existing
ADB-forwarded API. Live restored session → Browse vendors → View vendor loads
Products/Subscription/About and the saved product; View product displays quantity
and Add to cart, and Back returns to vendor details without an assertion. No cart
or order mutation was submitted. The customer APK uses a command-line
`API_BASE_URL=http://127.0.0.1:3000/api/v1` override; config/dev.json is unchanged.

## T-013/T-025 manual-test navigation fix (2026-11-18)

An onboarding-step redirect could become a saved pending destination after the
server reported onboarding complete. Every subsequent vendor tab selection then
returned to Home. Internal onboarding destinations now follow the current server
step without becoming pending navigation; explicit business deep links retain
their existing guard/replay behavior. More → Service area is reachable again.

Verification: 25 focused checks across `test/core/router/app_router_test.dart`,
`test/core/router/guards_test.dart`, `test/features/onboarding/onboarding_test.dart`
and `test/features/service_area/service_area_test.dart` pass, including a new
restored-vendor → More → Service area regression. Targeted analysis is clean.
Rebuild/restart the app to clear the old in-memory pending destination; app data
does not need clearing. Task-specific manual acceptance and module gates remain
pending.

Android dev APK build/install passes. On the existing vendor emulator-5554,
the restored session now opens More → Service area and displays six editable
shop-location fields from the running API. No business mutation was submitted;
coverage/location save acceptance remains the user's manual check.

## T-082 generated Khata client compatibility (2026-11-17)

Generated CustomerKhataApi/VendorKhataApi now expose exact summary/month reads,
personal records, claim decisions and explicit payment-UPI publication/options.
Personal date inputs stay YYYY-MM-DD strings; clearMobile=true clears an omitted
nullable field; typed DELETE carries version/key. No app screens were added here.

Executed from apps/mobile, PASS:

```powershell
dart format test/core/network/khata_client_test.dart
flutter analyze --no-pub ../../packages/api_client/lib test/core/network/khata_client_test.dart
flutter test --no-pub test/core/network/khata_client_test.dart
```

Two simulated transport checks cover huge signed paise, deterministic body/key,
date/clear/delete serialization, claim status/role paths and nullable unpublished
UPI. Actual API/PostgreSQL evidence and five manual steps are in API README T-082.
T-078/T-081/T-083 own mobile screens, Android UPI/no-app fallback and runtime checks;
those are NOT_RUN here. No live provider/manual PASS/G3 claim; iOS deferred.

## T-079 generated Quick Sale client compatibility (2026-11-17)

Generated VendorSalesApi exposes complete/list/detail with exact string paise,
optional customer (walk-in omits the property), editable string rate, CASH/UPI/
OTHER and zoned audit metadata. A transport smoke checks huge paise, identical
same-key serialization, date query and immutable receipt decoding.

Executed from apps/mobile, PASS:

```powershell
dart format test/core/network/sales_client_test.dart
flutter analyze --no-pub ../../packages/api_client/lib test/core/network/sales_client_test.dart
flutter test --no-pub test/core/network/sales_client_test.dart
```

One simulated HTTP transport check and clean analysis pass. Actual HTTP/PostgreSQL
stock/ledger/replay evidence and five manual steps are in API README T-079.
T-080 owns the POS UI/outbox and native Android OS-kill/reconnect journey; those
checks are NOT_RUN for this API slice. No app source changed; no device/APK/live
payment-provider or manual PASS claim. iOS is deferred; G3 remains pending.

## T-074 client/notification compatibility (2026-11-17)

Generated VendorAvailabilityApi and new models expose the seven holiday/
availability operations. New outbound holiday date/body and impact/query fields
are exact YYYY-MM-DD strings, verified with the real generated client. Customer
ORDER_CANCELLED_CUSTOMER notices now enter the existing owned-order refresh path;
raw/spoofed or wrong-role paths remain rejected. S-V-22 UI remains T-077.

Executed from apps/mobile:

```powershell
dart format lib/features/notifications/order_notices.dart test/features/notifications/order_notifications_test.dart test/core/network/availability_client_test.dart
flutter analyze --no-pub ../../packages/api_client/lib lib/features/notifications/order_notices.dart test/features/notifications/order_notifications_test.dart test/core/network/availability_client_test.dart
flutter test --no-pub test/core/network/availability_client_test.dart test/features/notifications/order_notifications_test.dart
# Verification process only; default SDK's newest build-tools lack aapt.
$env:ANDROID_HOME='C:\Android'
flutter build apk --debug --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json --no-pub
```

Six targeted transport/notification checks, clean analysis and the normal Android
dev APK build (114.7s) pass. The local SDK selection was restored after checks.
HTTP and push
transport are simulated; actual API/PostgreSQL/generation evidence and five manual
steps are in the API README T-074 handoff. No device runtime or live FCM was tested
for this API task; full T-077 UI/a11y and manual PASS/G3 remain pending, iOS deferred.

## T-076 vendor subscriptions handoff (2026-11-17): READY_FOR_VERIFY

Open Vendor Customers → Subscriptions (`/vendor/subscriptions`) for owned history,
customer/product search, status filters, pagination and creation. The existing
typed subscription deep link now opens the owned detail at
`/vendor/customers/subscriptions/:id`. Detail supports editing quantity/weekdays/
configured slot, approval/rejection, dated pause, resume, skip and confirmed
cancellation. Creation selects an active customer or opens the existing New
Customer flow, product/pack/price, integer quantity with stepper, weekdays/Daily,
start/end dates, configured slot and external payment preference. Live estimates
clip the start calendar month/range with exact BigInt paise and Indian grouping;
the API acknowledgement supplies the effective date. Setup takes no payment.

Subscriptions → Subscription settings (`/vendor/subscription-settings`) shows
server summary/customer counts, configured/effective auto-accept, availability,
pause-all, paired IST window and exact shared order/milk caps. BUSINESS+ enables
auto-accept; STANDARD+ enables creation/edit/resume. Support-assisted plan guidance
and reducing controls survive expiry/downgrade according to server flags. Typed
clear flags remove nullable limits/window. Existing orders and individual pauses
are retained when global switches change. API authorization remains authoritative.

Snapshots and saved mutation envelopes use the existing SQLCipher-backed
OnboardingDrafts store, scoped to account/API environment. Cached data is read-only.
Requests persist payload/version/key before send and retain that identity after
network or local acknowledgement failure. Explicit retry blocks new mutations;
definitive conflicts require refresh/review. Settings retry is stopped after 23
hours, before the API's 24-hour replay TTL; explicit reload/review never creates
a replacement key automatically. Disposal/permission loss fences late results,
and logout wipes saved data. Foreground refresh reloads the subscription page.

The generated Dart serializer emits midnight timestamps for calendar date fields.
A feature-owned interceptor normalizes only create/pause/skip date fields back to
the existing YYYY-MM-DD contract; tests assert exact wire payloads. No generated
API files were edited and no public contract, migration or dependency changed.
Only English ARB localization output was regenerated.

Executed from apps/mobile (PowerShell):

```powershell
flutter gen-l10n
dart format lib/features/subscriptions lib/core/router/app_router.dart lib/core/router/routes.dart lib/features/customers/customers_page.dart test/features/subscriptions integration_test/vendor_subscriptions_test.dart
flutter test --no-pub --timeout=60s test/features/subscriptions test/core/router/guards_test.dart test/core/router/app_router_test.dart
flutter analyze --no-pub lib/features/subscriptions lib/core/router/app_router.dart lib/core/router/routes.dart lib/features/customers/customers_page.dart test/features/subscriptions integration_test/vendor_subscriptions_test.dart
# Verification process only: default SDK's newest build-tools lack aapt.
$env:ANDROID_HOME='C:\Android'
flutter build apk --debug --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json --no-pub
Copy-Item -LiteralPath build/app/outputs/flutter-apk/app-dev-debug.apk -Destination .dart_tool/t076-normal-app-dev-debug.apk
flutter test integration_test/vendor_subscriptions_test.dart -d emulator-5580 --flavor dev --dart-define-from-file=config/dev.json --no-pub
Copy-Item -LiteralPath .dart_tool/t076-normal-app-dev-debug.apk -Destination build/app/outputs/flutter-apk/app-dev-debug.apk
git diff --check
```

Results: 21 focused controller/widget/router checks pass, including exact calendar
estimates/date-only wire payloads, all generated mutations, all-page search,
offline/account isolation, lost-response recreation, write/ack disk failures,
version conflict, expiry fencing, permission/disposal, plan locks, validation and
200% stepper/settings layout. Final analysis is clean. Normal dev APK build passes
(124.6s); one actual Android SQLCipher/secure-storage/recreation/replay/logout/200%
scenario passes (native test build 91.9s). The first runtime attempt stopped at
SDK discovery before app launch; the documented SDK override passed. HTTP is
simulated in mobile tests, including the native scenario: no live API/DB/FCM or
manual accessibility/PASS claim. API/worker evidence remains the earlier T-072/
T-073/T-075 handoffs; no API checks were rerun for this mobile-only change.

The pre-existing emulator-5554 was offline and preserved. A temporary read-only
Pixel_7 emulator-5580 was used, then shut down; the initial already-in-use AVD
attempt exited. Native fixture data was wiped. The normal dev APK was restored
and its SHA-256 matches the pre-test backup. The temporary SDK selection in
android/local.properties was restored after checks. iOS checks remain deferred.

Manual verification (suggested, not yet executed):

1. Run the migrated API/worker and Android dev app with a valid vendor session and
   active STANDARD+ assignment. Open Customers → Subscriptions; select or create
   a customer, product, days/dates and slot. Check exact estimates and one owned
   subscription, with no setup stock/Khata/payment effects.
2. Open a pending request and approve/reject it. Edit quantity/days/slot; pause a
   date range, resume, skip and cancel after reviewing confirmations. Check the
   server effective-date acknowledgement and frozen-date/generated-order rules.
3. Open settings; verify STANDARD cannot enable auto-accept and BUSINESS can.
   Save/clear exact order/milk limits and a paired/overnight IST window; toggle
   availability/pause-all and inspect summary and generation behavior.
4. Lose connectivity/response during a save; recreate the app and explicitly retry
   the saved change. Check one effect with the original key, read-only offline
   history, refreshed version conflicts and no cross-account/logout data.
5. Use 200% text and TalkBack on forms/actions/settings. Check loading, empty,
   error and plan-lock messages, labels, keyboard access and 48dp targets; inspect
   the generated dated order in both roles after the real 22:00 IST job.

Manual PASS, live UI/API/DB/FCM journey and G3 remain pending. T-078 customer
subscription creation/statements remain separate and require T-082. Stop here
after T-076; do not mark DONE without task-specific manual verification.

## T-075 generated-client compatibility (2026-11-16)

No settings UI is implemented in this task (T-076 owns it). OpenAPI regenerated
VendorSubscriptionSettingsApi and its settings/summary/customer models. Nullable
PATCH fields are omitted by the generator, so typed callers use explicit true
clearDeliveryWindow/clearMaxDailyOrders/clearDailyMilkCapacity flags to clear
values. The generated transport smoke checks JSON, retry key, route and nullable
response decoding. Backend HTTP/PostgreSQL checks verify those flags actually
clear stored fields and reject conflicting replacement values.

Executed from apps/mobile, PASS:

```powershell
dart format test/core/network/subscription_settings_client_test.dart
flutter test --no-pub test/core/network/subscription_settings_client_test.dart
flutter analyze --no-pub ../../packages/api_client/lib test/core/network/subscription_settings_client_test.dart
```

HTTP in this one Dart transport check is simulated; real API/DB evidence and
five manual steps are in apps/api/README.md T-075. Android runtime/a11y UI checks
remain T-076; iOS is deferred. No device or UI-pass claim is made here.

## T-053 offline customer linking handoff (2026-11-16): READY_FOR_VERIFY

S-C-38 appears on customer Home after registration/login and refreshes on resume,
pull-to-refresh or Refresh account links. The generated CustomerLinksApi returns
only server-owned mobile matches. Each vendor has confirmed Link account/Decline
link actions, with a fallback for an absent business name, paginated requests,
loading/empty/error states and English accessibility text. No match auto-links.
Accept refreshes existing Home reads; decline permanently dismisses the request.

Before sending, the environment/account-scoped SQLCipher store saves only the
vendor-customer UUID, decision and idempotency key. A lost response or failed
acknowledgement write leaves an explicit same-choice/key retry and blocks new
decisions. Recreating the provider restores it even when the server has already
removed the prompt. The API's permanent consent record makes same-choice replay
safe beyond its 24-hour response cache. Definitive rejection requires refresh;
role/account replacement invalidates confirmations and late responses cannot
restore wiped data. No mobile numbers, ledger content or tokens are stored here.

This task connects consent to the existing T-028 API and accepted-link guard;
customer Khata readers/screens remain T-082/T-083, as specified in API_SPECIFICATION
4.5. Their visibility journey is not claimed as passed. No API contract/schema,
dependency or router change was necessary; English localization was regenerated.

Executed from apps/mobile:

```powershell
flutter gen-l10n
dart format lib/features/customers/customer_links_controller.dart lib/features/customers/customer_links_prompt.dart test/features/customers/customer_links_test.dart test/features/customers/customer_links_disposal_test.dart test/features/home/home_test.dart
flutter analyze --no-pub lib/features/customers/customer_links_controller.dart lib/features/customers/customer_links_prompt.dart lib/features/home/home_page.dart test/features/customers/customer_links_test.dart test/features/customers/customer_links_disposal_test.dart test/features/home/home_test.dart integration_test/customer_links_test.dart
flutter test --no-pub test/features/customers/customer_links_test.dart test/features/customers/customer_links_disposal_test.dart test/features/home/home_test.dart test/core/router/app_router_test.dart
```

PASS: clean analysis and 26 focused checks (nine consent/retry/loading/logout checks,
11 Home checks and six router checks). The Home fixtures now supply the consent
provider; the 200% test scrolls to its category assertion below the new prompt.
Root `node --test tools/checks.spec.mjs`: five runner guards PASS, not a module gate.
API README records nine real PostgreSQL/HTTP checks; mobile HTTP is simulated.

Normal Android APK build PASS (226.4 seconds, including automatic installation
of missing CMake 3.22.1 in the existing SDK):

```powershell
flutter build apk --debug --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json --no-pub
Copy-Item -LiteralPath build/app/outputs/flutter-apk/app-dev-debug.apk -Destination .dart_tool/t053-normal-app-dev-debug.apk
```

Native Android smoke PASS (one scenario, final build 83.9 seconds):

```powershell
# Verification process only; the default SDK's newest build-tools lack aapt.
$env:ANDROID_HOME = 'C:\Android'
flutter test integration_test/customer_links_test.dart -d emulator-5556 --flavor dev --dart-define-from-file=config/dev.json --no-pub
flutter analyze --no-pub test/features/customers/customer_links_test.dart
Copy-Item -LiteralPath .dart_tool/t053-normal-app-dev-debug.apk -Destination build/app/outputs/flutter-apk/app-dev-debug.apk
& "$env:LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe" -s emulator-5556 emu kill
```

The test exercises real Android SQLCipher/secure storage, confirmation cancellation,
lost-response provider recreation with the original decision/key, acknowledgement,
encrypted bytes, logout wipe and 200% text. HTTP is simulated, not live API/OTP.
The initial native harness lacked the UI kit localization delegate for loading;
the corrected delegate plus a loading-state check pass without suppressed errors.
An initial emulator-5554 attempt could not attach; that pre-existing emulator was
preserved. A separate read-only Pixel_7 emulator (5556) was used for the passing
run and shut down afterward. The normal APK is restored in the standard build
output; no integration APK was installed on the original emulator.

Manual verification:
1. As a vendor, create an offline customer with a synthetic mobile; sign up/log in
   with that mobile as Customer. Home must show that vendor's link prompt.
2. Cancel Link account confirmation, then accept it. Confirm linkage on the vendor
   record and successful checkout without creating a duplicate customer record.
3. Decline a separate vendor's prompt; refresh/reopen and verify it stays dismissed.
   A different customer account must not see or accept either request.
4. Interrupt connectivity during a decision, reopen Home and retry its saved
   choice; confirm one permanent decision. Logout/switch roles during confirmation
   and check that the previous confirmation cannot submit for the new session.
5. Check long/missing vendor names, multiple matches, empty/error states, TalkBack
   and 200% scrolling. Customer ledger visibility is verified with T-082/T-083.

Manual UI/API/DB registration journey, TalkBack/PASS and G2 remain pending;
live OTP/provider delivery is NOT_RUN, iOS checks are deferred.

## T-052 order notifications handoff (2026-11-14): READY_FOR_VERIFY

All seven FR-101 order event types now refresh already-open customer Home/order
and vendor order models from authoritative reads. Only an owned inbox item can
trigger refresh or navigation; raw push status/path/type is ignored. Account/role
changes reset the signal, duplicates are ignored, and unopened order providers
are not created by foreground delivery. Cold/warm taps retain role confirmation.
The auth-disabled customer router previews also restore three existing fixtures.
No API contract, migration, dependency or generated-code changes were needed.

Executed from apps/mobile (all final commands PASS):

```powershell
flutter analyze --no-pub lib/features/notifications lib/features/orders lib/features/home/home_controller.dart lib/core/router/routes.dart test/features/notifications/order_notifications_test.dart
flutter test --no-pub test/features/notifications test/core/router/guards_test.dart test/core/router/app_router_test.dart
flutter test --no-pub test/features/orders/orders_test.dart test/features/orders/customer_orders_test.dart
flutter test integration_test/order_notifications_test.dart -d emulator-5554 --flavor dev --dart-define-from-file=config/dev.json --no-pub
flutter build apk --debug --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json --no-pub
adb install -r build/app/outputs/flutter-apk/app-dev-debug.apk
```

PASS: 39 focused mobile/router checks and one native Android scenario exercising
actual order pages, cold/warm role confirmation, trusted foreground refresh,
SQLCipher cache/write/wipe and 200% text. Native asynchronous navigation needs
bounded waits; the initial immediate assertion failed, and the final bounded
version passes. HTTP/FCM are simulated in mobile tests; real HTTP/PostgreSQL
transaction/outbox evidence is recorded separately in the API README. The normal
app APK is restored after the test. Analysis also covers the integration fixture.
Root `node --test tools/checks.spec.mjs`: five runner guards PASS, not a G2 gate.

Live FCM/OS delivery is NOT_RUN: dev FIREBASE_ENABLED=false and dev
google-services.json is absent. Manual TalkBack/PASS and G2 remain pending;
iOS checks are deferred. Seven order events are covered, not unrelated FR-101
subscription/payment/stock event implementations owned by other tasks.

Manual verification:
1. On a configured Android environment, place/cancel orders; confirm the vendor
   receives the matching owned inbox notices and warm taps open the right order.
2. Accept/reject/start/deliver/fail separate orders; confirm all five customer
   notices, correct statuses and no duplicated financial/order effects on retry.
3. Keep customer Home/detail and vendor Orders/detail open while events arrive;
   confirm authoritative refresh, including OUT_FOR_DELIVERY and cancellation.
4. Tap a cold notice while using the opposite role; cancel once, then confirm
   the switch. Check the owned order opens and a stale/unknown notice grants no access.
5. Check inbox and order navigation with TalkBack and 200% text, then logout/login
   with another account and confirm no previous-account notice/cache appears.

## T-050 deliveries handoff (2026-11-14): READY_FOR_VERIFY

S-V-16 (/vendor/deliveries) is available from Vendor Orders → Deliveries; S-V-34
(/vendor/sync-queue) shows pending/retryable/rejected updates. Server-owned IST
date/cards/status counts, customer/address/items/amount/Call, preparing/start,
delivered with optional Cash/UPI receipt, and failure reasons are wired. Exact
positive integer paise follows the existing API receipt policy, including advances;
no local money or stock is posted. English strings and 200% forms/cards are covered.

One environment/account-scoped SQLCipher snapshot atomically saves cache + FIFO
actions before send. Each action freezes its body, version, UUID retry key and
clientCreatedAt. Pending projections never claim server confirmation. Transport
retries back off, stop after six action attempts, and use the same key on explicit
retry. Rejections roll back dependent projections and refresh authoritative state.
Discard confirms and cannot forget an uncertain sent payment. A failed local
acknowledgement commit stops new actions until restart for exact disk replay.

Android WorkManager registers network-constrained one-off work before new durable
actions are written. APPEND_OR_REPLACE (ExistingWorkPolicy.update) avoids losing
a wakeup as a prior job finishes. Foreground/resume retries remain available.
The headless worker restores only the current persisted session, derives its
own account cache key, preserves Android version headers, and drains the same
queue. No job input includes credentials, customer details or action payloads.
Android controls background timing; force-stop prevents jobs until the app opens.

First-party packages/device_coordination supplies a native FIFO lease shared by
all foreground/headless Flutter engines in the app process. Cache operations,
queue reload/write, key initialization/wipe and refresh-token rotation coordinate
under that lease. Reentrance expires when the owner finishes; engine destruction
releases abandoned native ownership. Late callbacks reacquire. Refresh requests
waiting outside a delivery lease cannot deadlock its 401 refresh. Stale SQLCipher
handles fail closed after another engine changes/wipes the key, preventing cached
data resurrection. A stale open card reloads its base version before enqueue.

The API accepts optional validated, zoned ISO clientCreatedAt audit metadata.
It is included in immutable request identity and stored as nullable
order_status_events.client_created_at. Server event/completion/payment time stays
authoritative. Existing queued bodies remain unchanged on retry; historical rows
stay null. OpenAPI, TS and Dart clients were regenerated. Additive migration
20261114160000_delivery_client_audit was applied only to the isolated test DB.
Apply it to the intended dev/staging environment before manual use. Rollback may
retain the nullable column; do not delete recorded audit history.

Dependency rationale: WorkManager is already specified by MOBILE_STRATEGY §2/§6.
workmanager 0.9.0+3 is MIT (https://pub.dev/packages/workmanager/versions/0.9.0+3),
maintained by Flutter Community. Its platform interface is pinned to 0.9.1+1 so
the published Android/Apple plugin family remains compatible with Flutter 3.35.
The local coordination plugin adds no third-party runtime dependency. The final
normal debug APK size comparison is recorded below; it measures the whole task,
not the isolated library. iOS source/configuration is preserved; iOS checks remain
DEFERRED under ADR-025.

Normal three-ABI debug APK: 230,587,903 bytes, versus the pre-background-work
snapshot of 206,473,797 bytes (+24,114,106 bytes, about 11.7%). This is observed
whole-task debug artifact growth, not a release-size or isolated-library measure.
Release size/performance acceptance remains the separate T-170 workflow.

Executed from apps/mobile:

```powershell
flutter pub get
flutter gen-l10n
flutter analyze --no-pub lib/features/deliveries lib/features/auth lib/features/onboarding/onboarding_controller.dart lib/core/storage/app_storage.dart integration_test/delivery_background_probe.dart integration_test/delivery_coordination_test.dart test/features/deliveries ../../packages/device_coordination/lib ../../packages/api_client/lib/src/model/order_transition_input.dart
flutter analyze --no-pub lib/features/deliveries/deliveries_controller.dart test/features/deliveries/deliveries_test.dart
flutter test --no-pub test/features/deliveries/deliveries_test.dart test/features/auth/session_controller_test.dart test/features/orders/orders_test.dart test/core/router/guards_test.dart test/core/storage
flutter test integration_test/delivery_coordination_test.dart integration_test/deliveries_test.dart -d emulator-5554 --flavor dev --dart-define-from-file=config/dev.json --no-pub
flutter test integration_test/delivery_coordination_test.dart -d emulator-5554 --flavor dev --dart-define-from-file=config/dev.json --no-pub
flutter build apk --debug --flavor dev -t integration_test/delivery_background_probe.dart --dart-define-from-file=config/dev.json --no-pub
adb install -r build/app/outputs/flutter-apk/app-dev-debug.apk
# Repository root, while the isolated probe APK is installed:
node tools/delivery-background-smoke.mjs
# apps/mobile, restore the normal application:
flutter build apk --debug --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json --no-pub
adb install -r build/app/outputs/flutter-apk/app-dev-debug.apk
```

PASS: 44 focused mobile checks (13 delivery, 11 session, 8 order, 5 guard, 7
storage), focused analysis including the generated timestamp model, two native
Android scenarios (delivery SENDING/FIFO/conflict/200%/wipe; native lease/stale
snapshot/escaped callback/refresh wait-cycle/logout/key fencing). The coordination
test deliberately opens distinct DB executors: Drift emits its debug multiple-
database warning; the warning was not suppressed.

The final normal main_dev APK build passed; its installation replaces the probe
APK on the existing emulator. No newly started fixture server/test runner remains.

Actual process-kill smoke PASS: a localhost synthetic HTTP fixture commits a start
then drops its response; the saved start + payment chain survives app-process
termination. Two real headless Android engines serialize one refresh, replay the
original start key/body, complete one synthetic payment, preserve min-version
headers and leave an empty encrypted queue. The probe uses separate secure-store
namespace/directory and cancels its own test jobs/wipes its fixture storage before
the normal APK is restored. HTTP/financial results here are simulated; real
transactional API/DB evidence is the separate ten-case native delivery suite.

API/client checks PASS: ten native delivery/audit/replay cases, two native runtime
smokes, five task-runner guards, affected API ESLint, API typecheck/build/schema
and generated TS compile. Exact API commands are in apps/api/README.md T-050.
Codegen: tools/codegen.sh; English generation: flutter gen-l10n; formatting: dart
format on the changed Dart files. git diff --check passes. The first SDK package
resolution exposed an incompatible transitive WorkManager interface; the
compatible family pin resolved it without disabling any compiler/check.

Known baseline issue: the earlier separate app_router_test.dart compatibility
run passed 22 checks and failed three existing customer placeholder/deep-link
tests against already-live T-051 pages/unset API_BASE_URL. HEAD routes.dart
confirmed that baseline. It remains outside T-050; no unrelated status changed.
Live UI→API→DB/FCM, manual TalkBack/PASS and G2 remain NOT_RUN. No provider
delivery, full module acceptance or iOS pass is inferred from these checks.

Manual verification:

1. Apply the additive migration to the intended local runtime, sign in as a vendor
   with accepted orders, and open Orders → Deliveries. Check dates/tabs/counts,
   slot/address ordering, empty/error/refresh, Call and the sync queue.
2. Load orders, disconnect network, queue start then delivered with a precise
   Cash/UPI amount. Reconnect and background the app (do not force-stop). Verify
   exactly one stock change/debit/receipt-credit and the original audit timestamp.
3. Interrupt an uncertain response and reopen; check same-key replay. Change the
   version in another session before sync and check rollback/rejected-chain
   discard. Review the explicit retry state after repeated failures.
4. Switch account/role and log out with pending work. Check cache isolation,
   absence of revived data/credentials, and that another account never sends it.
5. Check TalkBack labels, 48dp targets and 200% scrolling/payment sheet. Record
   manual PASS separately; READY_FOR_VERIFY does not mark the task DONE.


## T-051 customer orders handoff (2026-11-14): READY_FOR_VERIFY

S-C-13/14 / US-240/241: customer Orders now uses generated owned list/detail APIs,
All/Ongoing/Delivered/Cancelled tabs, snapshot item/paise/date/status cards and
pagination. Tracking shows address, vendor/contact dialer, saved bill, four
persisted step timestamps and rejection/cancellation/failure reasons. Unreached
steps have no invented timestamps; no map/rating is added (SR-05). Pull refresh
and a trusted owned foreground order notice refresh detail/list. Opening a
notification uses the existing owned route. Unknown/unowned push payloads cannot
directly change order state. Domain event fan-out/live FCM remain T-052/provider
verification, not evidence supplied by simulated mobile responses.

NEW-only, fee-free cancellation requires confirmation and a fresh detail; the
exact version/key is saved encrypted before sending. An uncertain result survives
restart for explicit same-key retry, with no background duplicate request.
Conflicts refresh server state, permission denial clears private snapshots, and
account/environment-scoped cache, disposal guards and existing logout wipe prevent
cross-account reuse. Cached offline data is labeled and cannot authorize actions.

Past-order reorder calls a read-only owned preview at current prices. Review lists
available products and unavailable saved quantities (removed, changed MOQ or stock).
Adding uses one encrypted cart write, confirms another vendor's replacement,
rechecks a replacement preview, and honors checkout's pending-order lock. It
preserves saved quantities rather than silently changing them; checkout still
revalidates server price/coverage/date/capacity. No reorder creates a server order,
financial entry or stock movement. Generated OpenAPI/TS/Dart clients include
reorder, optional saved item summaries and owned vendorMobile. No migration or
dependency was added; route definitions were unchanged, so no router codegen
was needed. Only English l10n was regenerated.

Executed checks: seven focused customer-order mobile tests and four targeted
native API/PostgreSQL cases PASS, plus five runner guards, API lint/typecheck/build,
mobile analysis, generated TS compile and generated Dart analysis PASS. Mobile
transport/dialer-channel responses were simulated; API checks used the real local
isolated test DB. The initial Windows jest.cmd regex command failed because cmd
interpreted pipe characters; invoking Node directly passed. The native Android
test APK built, but its first install failed when emulator-5554 disappeared;
the device returned and the retried native Android encrypted restart/cancellation
replay/200%/logout smoke PASS (one case). The final seven mobile cases were rerun
after the vendor-scope guard and Call vendor fixes and all PASS. Native smoke
recreates encrypted storage/controller state, not a literal OS process restart.

Executed from `apps/mobile`:
```powershell
flutter gen-l10n
& 'C:/flutter/bin/cache/dart-sdk/bin/dart.exe' format lib/features/orders/customer_orders_controller.dart lib/features/orders/customer_orders_pages.dart lib/features/notifications/notification_host.dart test/features/orders/customer_orders_test.dart integration_test/customer_orders_test.dart
flutter analyze --no-pub
flutter test --no-pub test/features/orders/customer_orders_test.dart
flutter devices --machine
flutter test integration_test/customer_orders_test.dart -d emulator-5554 --flavor dev --dart-define-from-file=config/dev.json --no-pub
flutter build apk --debug --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json --no-pub
flutter install -d emulator-5554 --debug --flavor dev --use-application-binary=build/app/outputs/flutter-apk/app-dev-debug.apk
```
Executed from `apps/api` with NATIVE_TEST_DATABASE_URL privately redirected to
local `supplybiz_service_area_test`, NODE_ENV=test, OTP_DELIVERY_MODE=disabled:
```powershell
node node_modules/jest/bin/jest.js --runInBand --testTimeout=60000 --runTestsByPath src/modules/orders/orders.postgres.spec.ts -t 'T-051|TC-242|TC-220/226'
.\node_modules\.bin\tsc.cmd --noEmit
.\node_modules\.bin\eslint.cmd src test scripts jest.config.ts --max-warnings=0
.\node_modules\.bin\tsc.cmd -p tsconfig.build.json
```
Executed from root:
```powershell
& 'C:/Program Files/Git/bin/bash.exe' tools/codegen.sh
node --check tools/check-task.mjs
node --test tools/checks.spec.mjs
.\apps\api\node_modules\.bin\tsc.cmd --noEmit --strict --skipLibCheck --lib 'ES2022,DOM' packages/ts-client/src/generated/openapi.ts
git diff --check
```
Executed from `packages/api_client`: `flutter analyze --no-pub`.
NOT_RUN: the combined order/discovery/notification/router compatibility command
was declined by the user; it was not retried or counted as passing.
The normal dev APK build passed and was restored after the native test. Only the
two Java build daemons created by T-051 were stopped after checking their PIDs,
creation timestamps and Gradle/Kotlin command lines; existing services and the
Android emulator were preserved.

Manual verification (NOT_RUN; use synthetic configured vendor/customer accounts
and a migrated verification DB with the existing operator ledger grants):
1. Open customer Orders, switch all four tabs and paginate. Open tracking and
   compare saved items/bill/address/vendor/contact/status timestamps with DB.
   Try 200% text and TalkBack; open the real OS dialer from Call vendor.
2. Cancel a NEW order after confirming no fee. Lose the response/restart the
   actual app, retry the saved request and confirm one cancellation. Race vendor
   acceptance: refresh to ACCEPTED and confirm cancellation becomes unavailable.
3. Disconnect and reopen cached history/tracking: offline label appears and
   actions are disabled. Switch account/role and logout; prior private data and
   pending requests must not appear in another account.
4. Reorder a past order after changing product prices/MOQ/stock/availability.
   Review the available/unavailable list, decline then approve vendor replacement,
   and confirm one cart batch at current prices; pending checkout must block edits.
5. With configured live FCM/worker, change order state and confirm tracking reloads
   within 5 seconds of an owned foreground push or on pull refresh. FAILED must
   show its reason and no delivery debit. Complete the live UI/API/DB journey.

Live UI/API/DB/FCM, manual accessibility/PASS and G2 remain pending. iOS checks are
deferred. This handoff does not finalize any earlier READY_FOR_VERIFY task.

## T-048 vendor orders handoff (2026-11-13): READY_FOR_VERIFY

S-V-08–10 / US-040–042 / TC-045–050: the existing vendor Orders tab and
`/vendor/orders/:id` now use the generated T-045 list/detail/transition client.
Status, customer-name/order-number search and optional validated IST delivery date
combine server-side; newest-first pages are deduplicated while retaining server
order. Cancelled includes Rejected per the API. Detail shows owned contact/address,
pack/price snapshots, bill/payment/source, current state and actual status timeline
(UTC timestamps displayed as IST). Call customer reuses the normalized Android
ACTION_DIAL helper; it does not place a phone call.

NEW supports accept or rejection with one of the documented reasons; Other needs
5–200 trimmed characters. Accepted supports Mark packed / Start delivery; Preparing
supports Start delivery. Delivered/failed/payment-collection controls are not
exposed until their owning T-049/T-050 integration. VERSION_CONFLICT / invalid
transition refresh detail and list and show “Order no longer available”. All writes
send the displayed version and an explicit Idempotency-Key.

Encrypted environment/account-scoped cache retains at most 100 list summaries /
20 details. Restored/offline data is labeled and cannot authorize a mutation until
refreshed. Before a transition, its exact body/ID/key is persisted; network/server /
auth uncertainty freezes further transitions until explicit same-key retry. There
is no automatic replay/expiry/new-key retry. Accepted writes clear pending state
before refreshing; a failed refresh blocks actions against stale details. Disk
failure never sends an untracked update. Permission denial removes private cached
snapshots and search/date filters while preserving any uncertain request identity;
logout wipes storage. Late responses cannot publish after controller disposal.

Executed: 19 focused order/router cases PASS, including replay/restart, disk
failure, conflict refresh, reason validation, account-scoped cache, late-response
guards and 200% list/detail/rejection UI. Dialer channel invocation uses a simulated
platform response and synthetic number. Five task-runner guards PASS. Final
mobile analysis and one targeted permission-denial cache-cleanup recheck PASS.
One native Android encrypted offline/restart/replay/200%/logout smoke PASS;
normal dev APK build and restore on emulator-5554 PASS. No API/schema/client
contract changes, dependencies, migrations, route
codegen, screenshot baselines or broad test suites were needed; only English l10n
was regenerated. API authorization/notifications rely on the READY_FOR_VERIFY
T-045 contract; no new live provider or DB-flow evidence is claimed here.

Executed from `apps/mobile`:
```powershell
flutter gen-l10n
& 'C:/flutter/bin/cache/dart-sdk/bin/dart.exe' format lib/features/orders lib/core/router/routes.dart
& 'C:/flutter/bin/cache/dart-sdk/bin/dart.exe' format test/features/orders
& 'C:/flutter/bin/cache/dart-sdk/bin/dart.exe' format lib/features/orders integration_test/orders_test.dart
flutter analyze --no-pub
flutter test --no-pub test/features/orders test/core/router/guards_test.dart test/core/router/app_router_test.dart
flutter test --no-pub test/features/orders/orders_test.dart --name 'TC-046 disk failures'
flutter test integration_test/orders_test.dart -d emulator-5554 --flavor dev --dart-define-from-file=config/dev.json --no-pub
flutter build apk --debug --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json --no-pub
```
Root: `node --check tools/check-task.mjs`, `node --test tools/checks.spec.mjs` and
`git diff --check` PASS. Check logs: `$env:TEMP/supplybiz-t048-{focused,security,analyze,android,build}.log`.
Root `& 'C:/Android/platform-tools/adb.exe' -s emulator-5554 install -r
apps/mobile/build/app/outputs/flutter-apk/app-dev-debug.apk` restored the normal
development app. Root `& 'D:/supplybiz/apps/mobile/android/gradlew.bat' --stop`
stopped the task's Gradle daemon; the task Kotlin compile daemon was stopped by
its verified process ID. No Java processes existed before the task builds.
Pre-existing services/emulator are preserved; no task check process remains.
No separate RUN workflow was started.
Initial test-only import/braces lint findings were fixed. The full runner, hosted
CI, live mobile/API/PostgreSQL, FCM delivery, actual OS dialer interaction, manual
TalkBack/PASS and module gates are NOT_RUN. iOS is DEFERRED under ADR-025.

Manual Android verification (pending; use an owned synthetic vendor/customer/order):
1. Open Orders; combine status, customer/order-number search and date filters,
   clear them, paginate, and confirm Cancelled includes Rejected. Check empty,
   denied and offline cached states; cached rows must not enable stale writes.
2. Open details and confirm contact/address, item price snapshots, totals, payment,
   source and IST timeline. Tap Call customer and verify the OS dialer has the
   expected number without initiating a call; verify no-dialer fallback as applicable.
3. Accept a NEW order. Reject another with each listed reason; Other must require
   5–200 trimmed characters. Mark packed / Start delivery on eligible existing
   orders. Check fresh status/timeline and persisted customer inbox through the API.
4. Cancel an order from the customer while its NEW vendor detail is open; acting
   must show the conflict and current state. Lose a transition response, restart
   and explicitly retry; verify one server transition with the same saved key.
5. Test role/account/logout isolation, denied access and local save failure;
   review keyboard, TalkBack, 48dp targets and 200% scrolling/reject sheet. Delivery
   completion and payment collection remain their later tasks, with no fake effect.

## T-046 cart/checkout handoff (2026-11-13): READY_FOR_VERIFY

S-C-11/S-C-12 / US-220/221 / ADR-032: the cart icon opens typed
`/customer/cart`. Vendor detail → Place new order opens typed
`/customer/new-order/:id`, with Milk & Dairy / Water Can one-time products,
MOQ/stock steppers, fresh product checks and confirmed single-vendor replacement.
Address add/selection, server IST dates/vendor slots, Cash/UPI on delivery,
reviewed server bill, changed-price reconfirmation and persisted order confirmation
are wired through generated clients. No Add to Khata/coupon action is present.
Subscription creation remains T-078; this slice supplies the one-time flow and
does not fabricate a subscription setup destination. Order tracking remains T-051.

`GET /customer/orders/options?vendorId=&addressId=` is the small supporting API
read: owned address, coverage, role/KYC/active plan, server date/cutoff, holidays /
pause and configured slots; quote/place still revalidate current capacity/price.
No migration/dependency added. Empty unconfigured slots show unavailable choices;
T-106 owns vendor settings UI. No guessed cutoff/date/slot is submitted.

An encrypted environment/account-scoped checkout draft is written before sending
the mutation. Lost responses keep the exact body/key and lock cart edits, including
after restart before checkout opens. Explicit retry uses the permanent server replay
identity; there is no automatic expiration/new-key retry. Definitive input/business
errors release the cart; transport/server/auth/permission uncertainty preserves the
pending order. A successful result persists before purchased cart removal, and
failed local cleanup can be retried without placing another order. Role/account
changes dispose controllers, late responses cannot publish into the next account,
and logout clears the encrypted store. Every input/cart change invalidates quotes.

Executed checks: 27 focused checkout/discovery/router checks PASS; one dedicated
native PostgreSQL/HTTP options case PASS; five runner guards PASS; clean mobile
analysis, API lint/typecheck/build and generated TS compile PASS. API/TS/Dart
codegen and scoped l10n/router generation PASS. One native Android encrypted
restart/cart-lock/retry/200% confirmation/logout smoke PASS; normal dev APK build
PASS and restored on emulator-5554. Mobile HTTP is simulated; the separate native API
case exercises the real endpoint/DB and is not a claim of a live mobile/API journey.

Executed from `apps/mobile`:
```powershell
flutter gen-l10n
& 'C:/flutter/bin/cache/dart-sdk/bin/dart.exe' run build_runner build --build-filter=lib/core/router/routes.g.dart
flutter analyze --no-pub
flutter test --no-pub test/features/checkout test/features/discovery test/core/router/guards_test.dart test/core/router/app_router_test.dart
flutter test integration_test/checkout_test.dart -d emulator-5554 --flavor dev --dart-define-from-file=config/dev.json --no-pub
flutter build apk --debug --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json --no-pub
```
Root: `& 'C:/Program Files/Git/bin/bash.exe' tools/codegen.sh`,
`node --test tools/checks.spec.mjs`, `node --check tools/check-task.mjs`,
`.\apps\api\node_modules\.bin\tsc.cmd --noEmit --strict --skipLibCheck --lib 'ES2022,DOM' packages/ts-client/src/generated/openapi.ts`,
and `git diff --check` PASS. From `apps/api`, local `.\node_modules\.bin\tsc.cmd
--noEmit`, `tsc.cmd -p tsconfig.build.json` and `eslint.cmd src test scripts
jest.config.ts --max-warnings=0` PASS. With NATIVE_TEST_DATABASE_URL set only to
the existing local `supplybiz_service_area_test` (same credential-safe setup as
the API T-045 handoff), executed:
`.\node_modules\.bin\jest.cmd --runInBand --testTimeout=60000 --runTestsByPath src/modules/orders/orders.postgres.spec.ts -t 'T-046'`.
Only that one metadata case ran; the eleven unrelated cases were intentionally
excluded. Logs: `$env:TEMP/supplybiz-t046-{api,mobile,analyze,android,codegen}.log`.
Build log: `$env:TEMP/supplybiz-t046-build.log`. From `packages/api_client`,
`flutter analyze --no-pub` PASS. Root command
`& 'C:/Android/platform-tools/adb.exe' -s emulator-5554 install -r apps/mobile/build/app/outputs/flutter-apk/app-dev-debug.apk`
restored the normal dev app. Root `& 'D:/supplybiz/apps/mobile/android/gradlew.bat'
--stop` stopped task Gradle daemons; the task Kotlin compile daemon was stopped
by its verified process ID. No Java processes existed before these builds.
Pre-existing services and the emulator are preserved; no task check process
remains running. No separate RUN workflow was started.

Earlier sandboxed Flutter processes stalled and were terminated; localization /
router generation, analysis and focused tests succeeded outside the sandbox.
Initial lint/fixture assertion/widget setup issues were corrected; the final
27 checks pass, including 200% checkout and category tabs. No screenshot baselines
or broad suite ran. Manual PASS, TalkBack, live UI/API/DB/provider delivery and
module gates are NOT_RUN; iOS is DEFERRED (ADR-025).

Manual Android verification (pending; use a synthetic customer, an owned address,
and a verified vendor with an audited active plan, configured slots and stock):
1. Open vendor detail → Place new order; switch Milk & Dairy / Water Can, change
   pack quantities and add. Verify MOQ/stock and confirmed replacement for another
   vendor. Open the cart icon and remove/change items; old quotes must disappear.
2. Add/select an address; refresh delivery choices. Confirm server dates/slots,
   unavailable states and same-day cutoff behavior with a deliberately wrong
   device clock. Select Cash or UPI on delivery; credit/coupons must be absent.
3. Review bill and place; verify free/nonzero delivery charge and server total.
   Change a price between review/place; reconfirm the new quote explicitly.
   Confirm the order and its persisted NEW row through the vendor API.
4. Disconnect during placement, close/reopen, and retry the saved order. Cart must
   stay locked and one server order must result. Check account/logout isolation;
   local disk failure must never send an untracked placement.
5. Test product/coverage/holiday/capacity/expiry errors, keyboard focus, TalkBack,
   48dp actions and 200% scrolling. Subscription setup/tracking are later owning
   tasks; no manual PASS or module-gate acceptance is claimed here.

## T-044 customer discovery handoff (2026-11-12): READY_FOR_VERIFY

S-C-05-08/37 / US-210-211 / TC-204-210: Home and category search now open
`/customer/vendors?category=<uuid>`. Nearby/Popular and cursor paging preserve
T-041 server ordering; the mobile client does not calculate eligibility or rank.
Favorites opens `/customer/favorites`; favorite writes use generated PUT/DELETE
clients and a durable account-scoped idempotency key. Response loss blocks further
favorite edits until explicit retry using the same key and original location.
A retry older than 24 hours is refused; confirmed refresh reads current favorites
before dropping the expired intent. Definitive rejection clears pending intent;
network/server errors retain it. No background mutation retry is introduced.

Vendor route `/customer/home/vendors/<uuid>` loads Products/Subscription/About;
`products/<productUuid>` shows authenticated attached images, localized milk type,
pack size, paise price, description, MOQ and stock-bounded quantity controls.
Each Add re-fetches product eligibility/details; changed version/price/MOQ/stock
requires review. Vendor denial removes product details. No ratings/reviews UI.
The subscription tab reads real subscription prices; subscription creation remains
T-078. T-041 returns null opening hours until configuration exists, shown explicitly
as unavailable. Holiday data comes from the API; holiday writes remain T-074.

The shared cart badge counts quantities in an encrypted environment/account-scoped
single-vendor local cart. Cross-vendor Add requires confirmation before atomic
replacement. Disk failure preserves the previous cart. The preview can clear the
cart; this is local intent with per-pack saved prices, no order submission or bill.
Checkout/T-046 must obtain authoritative current prices/availability before order
placement. Providers follow account/role/location changes; image bytes stay in
memory. Existing logout wipes encrypted drafts. No API/schema/dependency changes;
only typed route and English localization outputs were generated.

Executed from apps/mobile unless indicated:

- `flutter gen-l10n`: PASS; final English source preserved as UTF-8.
- `& 'C:/flutter/bin/cache/dart-sdk/bin/dart.exe' run build_runner build --build-filter=lib/core/router/routes.g.dart`: PASS; targeted route generation.
- `& 'C:/flutter/bin/cache/dart-sdk/bin/dart.exe' format lib/features/discovery test/features/discovery integration_test/discovery_test.dart`: formatter executed on these paths as files were added; Home/router files also formatted on edit.
- `& 'C:/flutter/bin/cache/dart-sdk/bin/dart.exe' fix --apply --code=curly_braces_in_flow_control_structures --code=unnecessary_import lib/features/discovery`: focused fixes; same check applied to new test paths.
- `flutter analyze --no-pub`: PASS, no issues on final source.
- `flutter test --no-pub test/features/discovery test/features/home test/core/router/guards_test.dart test/core/router/app_router_test.dart`: PASS, 32 checks; server query forwarding/pagination, MOQ/stock/single-vendor cart, encrypted-store failure behavior, response-loss favorite replay, 24-hour expiry, authorization/media denial, disposed requests, 200% screens and affected Home/router regressions.
- `flutter test integration_test/discovery_test.dart -d emulator-5554 --flavor dev --dart-define-from-file=config/dev.json --no-pub`: PASS, one final Android smoke. Isolated SQLCipher/secure-storage namespace, cart/favorite restart, exact replay, account isolation, DB/WAL plaintext absence, 200% product Add and logout wipe. HTTP is simulated.
- `flutter build apk --debug --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json --no-pub`: PASS, final normal universal dev APK.
- From root, `C:/Android/platform-tools/adb.exe -s emulator-5554 shell am force-stop in.supplybiz.mobile.dev` and `C:/Android/platform-tools/adb.exe -s emulator-5554 install -r apps/mobile/build/app/outputs/flutter-apk/app-dev-debug.apk`: PASS; normal dev app restored after the native smoke.
- From root, `node --test tools/checks.spec.mjs`: PASS, five runner guards; T-044 registered for focused mobile checks.
- From root, `git diff --check`: PASS.

Initial test import/tab-label and style issues were corrected. The first Android
attempt encountered a temporary localization-source encoding error during cleanup;
source repaired and regenerated before final analysis/focused tests and Android retry. The native smoke also caught a missing UI-kit loading-state localization delegate in the test harness; corrected to match the real app before the passing run.
Host TEMP logs: supplybiz-t044-focused.log, supplybiz-t044-analyze.log,
supplybiz-t044-android.log and supplybiz-t044-build.log. Test storage wiped; task-created build daemons stopped using recorded PID/start-time checks; pre-existing services/emulator preserved.

Manual verification (suggested, NOT executed):
1. Sign in as CUSTOMER on the normal dev app, select a real serviceable location,
   Browse vendors, switch Nearby/Popular and page results; compare with the real API.
2. Favorite/unfavorite, open Favorites, interrupt a write response and explicitly
   retry after restart. Confirm a single server change and correct list refresh.
3. Open a vendor and its Products/Subscription/About tabs; check protected photos,
   holiday/charge/address details, then a product's price, attributes and MOQ.
4. Add quantities and inspect badge/cart; restart, then add another vendor's item.
   Test both Cancel and Confirm replacement; change server price and require review.
5. Repeat at 200% font with TalkBack; test offline/error/denial and logout/account
   isolation. Checkout/subscription creation are their owning later tasks.

NOT_RUN: live UI/API/PostGIS/DB integration, real loss-of-response network behavior,
manual TalkBack/PASS and module gates. iOS checks deferred. Required task checks do
not certify module acceptance. Stop here for task-specific manual verification.

## T-043 customer Home/location/search handoff (2026-11-12): READY_FOR_VERIFY

S-C-01/02/03 / US-200–202 / TC-200–203: `/customer/home` now shows the generated
T-042 home feed, existing notification bell/unread dot, location selector, search,
responsive category grid and today's snapshot items/statuses. Coming-soon tiles
are disabled. Home pagination preserves server ordering, deduplicates IDs and
reloads the first page if the IST day/cursor changes. Pull refresh and Refresh home
load current persisted status; the displayed business date comes from the server.
Existing role shells/guards and bottom tabs are preserved; no marketing/billing/
review routes/actions were added.

`/customer/location` supports manual area/city/pincode/numeric coordinates,
explicit optional GPS fill and existing T-047 saved-address selection. Permission
denial leaves manual fields usable. No GPS request happens on entry and no pincode
centroid, geocoder or coordinate fallback is used. Selected discovery context is
stored in the existing encrypted environment/account-scoped draft store; it is
independent of delivery-address mutations and does not certify vendor coverage.
An owned default address initializes location when no local selection exists.

`/customer/search?category=<uuid>` calls the generated serviceable vendor/product-name
search API, with explicit current location, category, keyword and cursor. It shows
real response names/distances, loading/error/empty/retry states and pagination.
The latest ten successful nonempty queries persist in encrypted account-scoped
storage. Provider identity/location fences late responses; role denial clears
private view/history, including a handled storage-cleanup failure. Recent queries
and selected location are wiped with existing logout storage. In-memory Home can
remain visible with a stale warning after a network failure; there is no new disk
delivery cache. Search results are read-only here: vendor/product details remain
T-044, and order details/cart/checkout remain their owning tasks. No placeholder
navigation or fabricated delivery/order action is introduced by these screens.

Executed from apps/mobile unless stated otherwise:

- `flutter gen-l10n`: PASS; generated English ARB output.
- `& 'C:/flutter/bin/cache/dart-sdk/bin/dart.exe' run build_runner build --build-filter=lib/core/router/routes.g.dart`: PASS; only typed routes regenerated.
- `& 'C:/flutter/bin/cache/dart-sdk/bin/dart.exe' format lib/features/home lib/core/router/routes.dart test/features/home integration_test/home_test.dart`: formatter run in the relevant subsets as files were added; PASS.
- `& 'C:/flutter/bin/cache/dart-sdk/bin/dart.exe' fix --apply --code=curly_braces_in_flow_control_structures lib/features/home` and the same command targeting `test/features/home`: focused lint fixes applied to new files only.
- `flutter analyze --no-pub`: PASS, no issues on final source.
- `flutter test --no-pub test/features/home test/core/router/guards_test.dart test/core/router/app_router_test.dart`: PASS, 22 checks. Covers typed Home → manual selection → category search; snapshot/status/pagination refresh; account-scoped location and recent queries; IST-day cursor recovery; offline/auth/cache failure; in-flight disposal; coordinate validation; 200% Home/form/search; GPS denial; empty search and existing router guards.
- `flutter test integration_test/home_test.dart -d emulator-5554 --flavor dev --dart-define-from-file=config/dev.json --no-pub`: PASS, one final native Android smoke. Verifies selected location and recent searches across SQLCipher/secure-storage restart, account namespace isolation, absence of plaintext in DB/WAL bytes, 200% Home/status refresh and logout wipe. Uses an isolated test database/storage namespace. HTTP is simulated; no live UI/API/DB or GPS/provider delivery claim.
- `flutter build apk --debug --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json --no-pub`: PASS, final normal universal dev APK built.
- From root, `C:/Android/platform-tools/adb.exe -s emulator-5554 shell am force-stop in.supplybiz.mobile.dev` and `C:/Android/platform-tools/adb.exe -s emulator-5554 install -r apps/mobile/build/app/outputs/flutter-apk/app-dev-debug.apk`: PASS; restored the normal dev APK after native testing.
- From root, `node --test tools/checks.spec.mjs`: PASS, five runner guards; T-043 registered for focused mobile checks.
- From root, `git diff --check`: PASS. A read-only Python zipfile check of the final APK kernel also confirmed CustomerHomePage, CustomerLocationPage and CustomerSearchPage are packaged.

SDK/cache access was approved for Flutter generation/checks. Initial analysis found
a num-to-double conversion in the saved-address adapter plus source/test lint
issues; corrected before final checks. A cache-cleanup failure guard was added and
tested. The final responsive category grid was rechecked by the 22 focused checks,
analysis and native smoke. Logs are in host TEMP supplybiz-t043-focused.log,
supplybiz-t043-android.log and supplybiz-t043-build.log. New build daemons stopped,
test storage wiped, pre-existing services/devices preserved. No dependency,
API/schema/migration or generated API-client changes were needed.

Manual verification (suggested, NOT executed):
1. Use the restored normal dev build against the configured real API with a CUSTOMER
   login. Check Home categories, Coming soon, bell/inbox navigation, server business
   date, real owned deliveries, loading/empty/error and pull-refresh states.
2. Choose a saved address or enter area/city/pincode/coordinates manually. Deny GPS,
   verify manual entry remains usable, then optionally allow an actual GPS fix.
   Restart and verify the chosen discovery location; delivery addresses stay separate.
3. Open a supply category, search vendor/product names and check serviceable results,
   empty-location guidance, pagination and recent searches. Change location and check
   stale results do not reappear. Vendor details/cart continue with T-044/T-046.
4. In the isolated test environment, refresh changed order statuses and more than
   twenty deliveries, including midnight cursor recovery. Seeded-read checks are
   not actual T-045/T-049 delivery/financial-flow PASS. Test offline stale/retry states.
5. Check TalkBack, keyboard navigation and 200% text on Android. Sign out/switch
   role/account during loading; confirm another account sees no previous location,
   recent queries or private deliveries. Verify logout storage wipe.

NOT_RUN: live UI → API → PostgreSQL journey, actual GPS fix/OS permission-dialog
flow, manual TalkBack/PASS and module gates. These require the configured manual
environment/provider/device review; simulated HTTP supplies none of that evidence.
iOS build/run/accessibility checks remain deferred under ADR-025.

## T-047 addresses handoff (2026-11-12): READY_FOR_VERIFY

S-C-28/29 / FR-291 / US-290: Customer Profile → Addresses opens typed routes
`/customer/addresses`, `/customer/addresses/new`, `/customer/addresses/{id}/edit`.
The generated T-040 client loads, creates, edits, sets a default and soft-deletes
owned addresses. Required house/flat, street/area, label, city/state, six-digit
pincode and finite latitude/longitude are validated; landmark can be cleared.
Optional GPS fills coordinates only; denial leaves manual entry usable. The
current default cannot be unchecked; choose another address instead. Deletion
requires confirmation and reloads the server's default replacement.

Loading/empty/error/refresh and stale read-only states are implemented with English
ARB and UI-kit components. Last-loaded addresses remain in memory during a network
failure; there is no persistent address-list cache. Mutations wait for a successful
refresh. Uncertain mutations retain exact method/target/body/key in the existing
encrypted environment/account-scoped draft store, wiped with existing logout storage.
Restart never automatically resubmits them. Explicit retry uses the original key;
other edits remain disabled until resolved. Once the 24-hour API retry window ends
(or the local clock moves backward), retry is blocked: refresh/review addresses and
explicitly confirm dismissal before submitting a new request. Server time/validation
remain authoritative; the client window is a conservative retry guard. Role/authorization
denial clears private view/retry state; provider disposal fences late responses.
An accepted mutation leaves the editor even if its subsequent list refresh fails;
successful explicit retry also returns to the list. This prevents the editor from
offering a second submission after server acceptance. Pending keys are retained if
clearing encrypted retry storage fails.

Selection followed ADR-030: T-016/T-040 READY_FOR_VERIFY allow implementation.
T-041 was skipped before selection because FR-210/US-210 require Popular sorting
without defining its ranking metric; T-042 still depends on T-041. No ranking policy
or unrelated task status was invented/changed. No API/schema/client contract or new
dependency was added. Existing Android location support and encrypted storage reused.

Executed from `apps/mobile` unless stated otherwise:

- `flutter gen-l10n`: PASS. Generated English strings from ARB.
- `& 'C:/flutter/bin/cache/dart-sdk/bin/dart.exe' run build_runner build --build-filter=lib/core/router/routes.g.dart`: PASS; only typed route code regenerated.
- `& 'C:/flutter/bin/cache/dart-sdk/bin/dart.exe' format lib/features/addresses test/features/addresses integration_test/addresses_test.dart`: PASS. Routes/route widgets were also formatted using the same formatter.
- `& 'C:/flutter/bin/cache/dart-sdk/bin/dart.exe' fix --apply --code=curly_braces_in_flow_control_structures lib/features/addresses` and the same command targeting `test/features/addresses`: applied focused lint fixes to the new files.
- `flutter analyze --no-pub`: PASS, no issues.
- `flutter test --no-pub test/features/addresses test/core/router/guards_test.dart test/core/router/app_router_test.dart`: PASS, 21 checks including validation, generated-client CRUD/default/delete, same-key response-loss recovery, accepted-write/failed-refresh completion, account scoping, expiry, offline/role denial, disposal, 200% list/form/GPS denial, full typed form submission/retry recovery and existing router regressions. HTTP is simulated.
- `flutter test integration_test/addresses_test.dart -d emulator-5554 --flavor dev --dart-define-from-file=config/dev.json --no-pub`: PASS, one native Android encrypted-retry/restart/200%/delete smoke. Uses an isolated SQLCipher database and secure-storage namespace; verifies no plaintext address in DB bytes. HTTP is simulated, not live API/DB evidence.
- `flutter build apk --debug --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json --no-pub`: PASS on final source; normal universal dev debug APK is 206,473,797 bytes.
- From root, `C:/Android/platform-tools/adb.exe -s emulator-5554 shell am force-stop in.supplybiz.mobile.dev` and `C:/Android/platform-tools/adb.exe -s emulator-5554 install -r apps/mobile/build/app/outputs/flutter-apk/app-dev-debug.apk`: PASS; restored normal dev APK after the smoke. Emulator and pre-existing services preserved; isolated test storage wiped. Task-started build daemons were stopped after build completion.
- `node --test ../../tools/checks.spec.mjs`: PASS, five runner guards; T-047 registered for focused mobile CI checks.
- From root, `git diff --check`: PASS.

Initial sandboxed Flutter wrappers could not acquire their SDK cache lock and were
stopped. Sandboxed Dart dependency resolution failed on blocked pub.dev access;
approved cache/network access completed generation/checks. Initial source/fixture
type/lint issues were corrected. Widget setup needed runAsync; the router fixture
was adjusted to avoid starting an unrelated auth screen. The first native smoke
asserted deletion before asynchronous encrypted storage completed; the corrected
smoke waits for the operation. Review also found/fixed the accepted-write/failed-refresh
and editor retry completion paths; the 21 checks, native smoke, analysis and normal
APK build all passed again against final source. All cited results are subsequent successful runs.
Focused, Android and normal-build logs are in host TEMP as supplybiz-t047-focused.log,
supplybiz-t047-android.log and supplybiz-t047-build.log.

Manual verification (suggested, NOT executed):
1. Use the normal dev build with a CUSTOMER login against the real API after T-040's
   migration is applied. Open Profile → Addresses, add two addresses, reload/restart
   and verify both persisted under that customer.
2. Edit every address field and clear landmark. Try blank house/area, invalid pincode,
   NaN/out-of-range coordinates, deny GPS, and enter coordinates manually. Optionally
   allow GPS and verify an actual fix; saving does not certify vendor coverage.
3. Set the second address as default, reload, cancel one deletion, then confirm deleting
   the default. Verify the remaining address is default; deleting the last shows empty.
4. Interrupt a response, restart, refresh online and explicitly retry the saved request;
   confirm one server record and no duplicate. After expiry, review/dismiss before any
   new request. Verify offline errors and read-only last-loaded state.
5. Check TalkBack, keyboard/200% text and navigation. Sign out/switch role or account
   during a load; confirm private addresses/pending requests do not appear for another
   user. Backend foreign ownership is also enforced by T-040.

NOT_RUN: live UI → API → DB journey, real GPS fix/permission dialogs, manual TalkBack/
PASS and G0/G1/G2 acceptance. These need the configured manual environment and review;
simulated HTTP does not supply that evidence. iOS checks remain deferred by ADR-025.

## T-033 notifications handoff (2026-11-11): READY_FOR_VERIFY

The home-header bell opens `/common/notifications` (S-V-18 / S-C-26).
The signed-in role controls All/Orders/Payments/System tabs, with Delivery for
vendors. The center loads all 100-row API pages, displays relative timestamps and
read state, marks opened items read, confirms role-wide clearing and saves optional
push preferences. Mandatory security/KYC behavior remains server-enforced. Errors
retain the current in-memory view; there is no disk inbox cache. Pull to refresh.
Uncertain mutations retain the exact request/key for explicit retry in the current
account controller; they are never automatically submitted after restart.

The Android push bridge handles foreground alerts in-app, background notification
taps and cold starts, token refresh and resume registration. A push supplies only
an inbox ID/role hint: the client resolves it through the authenticated role inbox,
confirms switching to an already-held role and only opens allowlisted internal
destinations after marking read. Raw push paths/text are ignored. Logout/account
changes fence delayed responses and pending alerts; the API clears session tokens.
Existing legacy customer subscription paths normalize to the typed mobile route.
Vendor plans/delivery/Khata destinations whose screens are not implemented yet
fall back to the inbox; domain tasks must wire their final destinations. No deferred
offers features, contract changes, migrations or generated API edits were added.

Opening the inbox never requests OS permission. Explicit **Enable push alerts**
first explains the purpose, then requests permission. Account/environment consent
uses the existing encrypted draft store and logout wipe. Denial gives Android
Settings guidance and clears device registration on synchronization; an allowed
device registers/retries on consent, session/token changes and resume. Firebase
Messaging auto-init defaults off. Firebase-disabled builds retain a working inbox
and preferences and report push unavailable. Background system display uses the
existing server notification+data payload; no background data worker is needed.

Dependency justification: pinned `firebase_messaging` 15.2.10 matches the existing
Firebase Core 3.15.2 baseline. The Google-maintained FlutterFire package uses
[BSD-3-Clause](https://pub.dev/packages/firebase_messaging/versions/15.2.10).
It adds the FCM bridge/native SDK plus three Dart transitive packages; the cached
plugin source is 1,106,929 bytes (not installed APK overhead). Release-size impact
has not been measured. No local-notifications or analytics dependency was added.
Integration follows [Firebase receive/tap guidance](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages).

Executed checks (from `apps/mobile`, unless stated otherwise):

- `flutter pub get` and `flutter gen-l10n`: PASS; only notification dependency/l10n generated changes.
- `flutter analyze --no-pub`: PASS, no issues.
- `flutter test --no-pub test/features/notifications test/core/router/guards_test.dart`: PASS, 13 checks. Simulated HTTP/FCM; pagination, category/role scoping, response-loss replay, read/clear/preferences, authorization purge, safe paths, disposal, permission timing/200%, warm/cold taps and logout during confirmation.
- `flutter test integration_test/notifications_test.dart -d emulator-5554 --flavor dev --dart-define-from-file=config/dev.json --no-pub`: PASS, one native Android smoke. Checks the 200% inbox/permission denial and encrypted consent across storage restart, using a separate SQLCipher/secure-storage test namespace. Initial harness lacked the UI-kit loading localization delegate; corrected to match production. A 200% dialog overflow was fixed during the focused tests.
- `flutter build apk --debug --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json --no-pub`: PASS; final normal debug APK is 206,473,797 bytes (universal debug artifact; no release-size comparison).
- From repository root, `C:\Android\platform-tools\adb.exe -s emulator-5554 shell am force-stop in.supplybiz.mobile.dev` and `C:\Android\platform-tools\adb.exe -s emulator-5554 install -r apps/mobile/build/app/outputs/flutter-apk/app-dev-debug.apk`: PASS. Restored the normal dev app after the native test; emulator and pre-existing services preserved, no separate RUN workflow started.
- From repository root, `git diff --check`: PASS.

Manual verification (not yet PASS):

1. Run the existing dev build against the API after applying T-032's migration; sign in and open the home bell. Check both roles' categories, empty/error/pull-refresh states and 200% text/TalkBack.
2. Open an owned inbox item, return, restart, mark all read and clear with confirmation. Check persisted server state and role isolation.
3. Toggle category preferences, reopen, and confirm security/KYC remain mandatory. Test offline failure and explicit retry of a lost response.
4. With private native Firebase config and `FIREBASE_ENABLED=true`, enable alerts, deny/allow Android permission, rotate the token and resume. Verify owned registration and logout revocation with real T-032 FCM configured.
5. Deliver a real owned notification in foreground/background/terminated states. Confirm role switching; cancel once and sign out during confirmation. Verify forged/foreign/expired items do not navigate.

NOT_RUN: real FCM/OS push delivery, live UI-to-API-to-DB journey, manual TalkBack/PASS
and module gates. Dev Firebase is disabled and private provider config is absent.
Full FR-101/TC-103 fan-out and final missing domain destinations remain with T-052
and their owning tasks; no module gate claim. iOS checks are deferred per ADR-025.

## T-029 customers handoff (2026-11-11): READY_FOR_VERIFY

Vendor Customers `/vendor/customers` implements S-V-12 search by name/mobile,
All/Active/Subscription/Inactive filters, 20-row display with scroll/Show more and
pull refresh. Typed routes `/vendor/customers/new`, `/vendor/customers/{id}` and
`/vendor/customers/{id}/edit` provide S-V-13 Add/Edit and S-V-14 detail/status.
Required name/Indian mobile, optional email/address and preferred payment are
validated; linked mobiles are read-only, email clearing sends explicit null.
Inactivation/reactivation needs confirmation and keeps the same customer ID.
The API supplies capacity (50 before assignment under ADR-028, assigned caps
unchanged); duplicate/limit errors give specific messages and support guidance.
Android Call opens ACTION_DIAL without CALL_PHONE permission or a new dependency.

Complete customer and current-subscription membership snapshots are fetched in
100-row API pages before replacing the encrypted, environment/account-scoped
cache. This prevents offline search/filter from silently covering just one page.
Offline snapshots are read-only. Exact mutation payload/key persist before send;
Retry saved request handles response loss/restart without automatically submitting
an offline edit. Definitive rejections release the request for editing; auth denial
purges private cache, disposal fences late network writes, and existing logout
wipes the encrypted store. No new DB migration or API/contract/client changes.
Only typed routes and English l10n generated output changed.

Order history, current subscription/payment activity and Add Order remain clearly
unavailable until their owning M2/M3 tasks, as explicitly allowed by T-029. No
financial totals or history are fabricated. T-053 owns customer-side linking UI.

Executed checks (`apps/mobile`, Flutter 3.35.7, HTTP simulated):
```powershell
flutter gen-l10n
& 'C:\flutter\bin\cache\dart-sdk\bin\dart.exe' run build_runner build '--build-filter=lib/core/router/routes.g.dart'
& 'C:\flutter\bin\cache\dart-sdk\bin\dart.exe' format lib/features/customers lib/core/storage/customer_device.dart lib/core/router/routes.dart test/features/customers integration_test/customers_test.dart
flutter analyze --no-pub
flutter test --no-pub test/features/customers test/core/router/guards_test.dart test/core/router/app_router_test.dart
flutter test integration_test/customers_test.dart -d emulator-5554 --flavor dev --dart-define-from-file=config/dev.json --no-pub
flutter build apk --debug --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json --no-pub
```
Focused suite: 23 checks pass (12 customer, 11 router). Native smoke: 1 pass for
encrypted snapshot/retry across storage restart, owner isolation, 200% detail,
one committed change after response-loss replay and native invalid-number
rejection. Actual valid-number dialer launch is NOT_RUN. Initial route codegen
needed pub.dev advisory access outside the sandbox. Widget harness fixes used
runAsync for simulated HTTP, settled scrolling/field focus, expired snackbars and
explicit scrollable selection; no lint/tests were disabled. Auth-disabled scaffold
route tests retain placeholders; production auth-enabled routes use the new pages.
The registered task commands were executed directly, not through the full runner.
From repository root, `node --test tools/checks.spec.mjs` passes all 4 guards and
`git diff --check` passes. The final normal dev APK build passes; after the native
test the normal app is restored using these executed commands:
```powershell
& 'C:\Android\platform-tools\adb.exe' -s emulator-5554 shell am force-stop in.supplybiz.mobile.dev
& 'C:\Android\platform-tools\adb.exe' -s emulator-5554 install -r apps/mobile/build/app/outputs/flutter-apk/app-dev-debug.apk
```
The emulator and pre-existing host services are preserved. Kotlin's local compiler
cache is now ignored in .gitignore; generated API clients under packages are unchanged.

Manual verification (suggested, not manual PASS):
1. With a real vendor session and T-028 migration applied, open Customers; add/edit
   synthetic records, clear email, verify reload, name/mobile search and filters.
2. At 50 active pre-assignment records, confirm another create/reactivation gets
   PLAN_CUSTOMER_LIMIT guidance; inactivate a record and retry. Confirm identity
   and future history are retained, and assigned-plan caps come from the API.
3. Open detail, use Call to open the dialer without placing a call, and edit a
   linked customer: mobile must stay read-only. Unavailable activity has no fake
   totals or active Add Order destination.
4. Go offline and reopen: saved data is read-only. Interrupt a response, restart
   and explicitly retry; inspect DB for one change. Sign out/switch account and
   confirm no previous customer's data or pending request appears.
5. Check TalkBack, all action targets and 200% text on list/editor/detail; try a
   foreign customer ID and wrong-role route. Confirm API authorization denies it.

NOT_RUN: live mobile UI → API → DB journey, valid dialer launch/manual TalkBack/
manual PASS and G0/G1 gates. iOS remains deferred per ADR-025. No separate RUN,
finalization or DONE claim; no new check process/service is retained.

## T-027 products handoff (2026-11-10): READY_FOR_VERIFY

Products tab `/vendor/products` implements S-V-06 list/search/type filters,
S-V-07 Add/Edit and S-V-35 stock adjustment. English ARB strings, accessible
UI-kit controls and 200% layouts cover exact integer-paise prices, unit presets/
custom sizes, MOQ, activity, private product images, deletion confirmation and
PRODUCT_IN_USE/stock errors. Add/Edit and Adjust/Delete are reachable in the editor.

The complete catalog is read in 100-row pages and cached with category types in the
existing SQLCipher-backed draft store, keyed by API environment/account. No database
migration or dependency was added. Offline cache is read-only. Exact product mutation
payloads/keys persist before sending; Retry saved request explicitly recovers lost
responses after restart, without submitting an offline edit automatically. Definitive
validation/conflict/not-found errors permit editing again; authorization denial purges
cache, provider disposal fences late writes and existing logout wipes encrypted storage.

The only API addition is owned GET `/api/v1/vendor/products/options` → `{ productTypes }`,
using active vendor role, category and suspension checks. Types remain admin-managed.
Clients were regenerated. Full editor PATCH uses the shared NetworkClient/generated
response model: generated ProductPatch serialization omits nulls and supplies stock
defaults. Focused tests verify clearing optional values without resetting stock or
sending vendor identity. Other catalog/media operations use generated endpoints.

Executed from apps/mobile:
```powershell
flutter gen-l10n
flutter analyze --no-pub
flutter test --no-pub test/features/products test/core/router/guards_test.dart
flutter test integration_test/products_test.dart -d emulator-5554 --flavor dev --dart-define-from-file=config/dev.json --no-pub
flutter build apk --debug --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json --no-pub
```
The final normal dev APK was rebuilt after the native test, installed successfully
on the existing emulator, and the test app was stopped. From repository root:
```powershell
adb -s emulator-5554 shell am force-stop in.supplybiz.mobile.dev
adb -s emulator-5554 install -r apps/mobile/build/app/outputs/flutter-apk/app-dev-debug.apk
```
The emulator and pre-existing host services were preserved. Normal interactive
login/catalog verification was not started as a separate RUN workflow.
17 focused checks pass (12 products, 5 guards). One Android emulator smoke passes
encrypted cache close/reopen, non-plaintext DB bytes, account separation, durable
lost-response retry and a 200% cached screen. Its HTTP responses are simulated.
Separate native API checks pass all 10 catalog HTTP/PostgreSQL/private-file cases,
including product-options authorization/taxonomy updates. API lint/typecheck/build,
generated TS compile/Dart analysis and 4 runner guards pass. The native smoke uses
a separate products-test directory/secure-store namespace and wipes it in teardown.
Initial harness corrections covered fake-async setup, lazy scrolling, semantics-handle
cleanup and JSON-map assertions; no application checks were weakened.

Executed from apps/api, with CATALOG_TEST_DATABASE_URL loaded privately for existing
supplybiz_service_area_test and NODE_ENV=test/OTP_DELIVERY_MODE=disabled:
```powershell
.\node_modules\.bin\tsc.cmd --noEmit
.\node_modules\.bin\eslint.cmd src test scripts jest.config.ts --max-warnings=0
.\node_modules\.bin\tsc.cmd -p tsconfig.build.json
.\node_modules\.bin\jest.cmd --silent --runInBand --testTimeout=60000 --runTestsByPath src/modules/catalog/catalog.postgres.spec.ts
.\node_modules\.bin\ts-node.cmd scripts/generate-openapi.ts
```
At root, executed the same installed openapi-typescript/openapi-generator-cli,
normalizer, Dart formatter and generated TS compile commands documented under
T-026 in apps/api/README.md, plus `node --test tools/checks.spec.mjs`. From
packages/api_client, executed:
```powershell
& 'C:\flutter\bin\cache\dart-sdk\bin\dart.exe' run build_runner build '--build-filter=lib/src/model/*.g.dart'
& 'C:\flutter\bin\cache\dart-sdk\bin\dart.exe' analyze
```
Serializer generation's sandboxed pub.dev advisory lookup initially failed; the
approved rerun succeeded. Native API tests ran outside the sandbox for existing
Windows ACL verification. The full task runner was not invoked; its T-027 API/mobile
commands are registered and were executed directly. No separate RUN workflow started.

Manual verification (suggested, not PASS):
1. Run the migrated local API/app, sign in as an onboarded vendor and open Products.
   Add a product with prices/unit/stock/MOQ; refresh/relaunch and check the real DB.
   Live login still needs Q-09 or the existing development auth harness.
2. Search/filter, edit/clear prices, change type, toggle activity and upload/remove
   a JPEG/PNG via Android SAF; check authenticated image display and picker cancellation.
3. Adjust stock with a reason; reject zero/fractional adjustments/negative stock.
   Confirm deletion; verify real ACTIVE/PAUSED subscription blocking with T-072 later.
4. Load online, disconnect/reopen and confirm cached search with disabled mutations.
   Reconnect/refresh. Interrupt a sent write, reopen/Retry saved request and confirm
   exactly one server effect from the saved key.
5. Check TalkBack/200% layouts and logout/account switching with no cache exposure.
   Live UI/API/DB, SAF picker, TalkBack/manual PASS and G0/G1 remain NOT_RUN/pending;
   native HTTP simulation is not live integration evidence. iOS is deferred.

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

READY_FOR_VERIFY: Vendor → More → Service area (`/vendor/service-area`, S-V-30).
T-016 and T-023 are READY_FOR_VERIFY and permit work against their stable contracts.
At this handoff, Day 4 catalog T-026 was skipped pending Q-34/Q-04 policy decisions.
Those decisions have since been resolved; Q-04 is accepted in ADR-029. See TASKS.md
for current readiness and dependency order. Existing API, migration and generated-client
working edits were preserved at this handoff.

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
dart format integration_test/service_area_test.dart
flutter analyze --no-pub
flutter test --no-pub --reporter expanded test/features/service_area/service_area_test.dart test/core/router/guards_test.dart
flutter build apk --debug --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json --no-pub
flutter test integration_test/service_area_test.dart -d emulator-5554 --flavor dev --dart-define-from-file=config/dev.json --no-pub --reporter expanded
```
Generation/formatting succeed; analysis is clean; all 9 focused checks pass. The widget
smoke exercises GPS denial and invalid coverage at 200% text; simulated HTTP tests exercise
saved-value reload, interrupted request recreation/key reuse, changed-payload keys and
server re-verification rejection. Those focused tests use simulated HTTP responses.
The initial generator run without `--delete-conflicting-outputs` failed on its existing
generated output; the corrected scoped command passed. Initial analysis errors and a
widget-test async setup stall were corrected before the passing checks.

Initial attempt (superseded by the successful checks below): online attempts stalled in
Gradle and were cancelled. An offline
diagnostic from `apps/mobile/android` (`.\gradlew.bat :app:assembleDevDebug --offline
--console=plain -Ptarget=lib/main_dev.dart -Ptarget-platform=android-arm64`) failed while
configuring existing `flutter_secure_storage`: missing cached AGP/builder 8.13.2,
Kotlin reflect/stdlib 2.2.0 and analytics protos 31.13.2. PowerShell split the unquoted
target argument in that diagnostic; dependency resolution failed before target evaluation.
The build blocker was resolved on resumption: the normal Flutter build completed in
557 seconds, compiling native Kotlin and producing `build/app/outputs/flutter-apk/app-dev-debug.apk`.
No dependency, Gradle configuration or application-source change was needed. Android
emulator-5554 was available on resumption; the APK installed successfully.

Two native `integration_test/service_area_test.dart` checks PASS (13 seconds after test
startup): isolated SQLCipher storage closes/reopens and restores the pending payload/key;
another owner cannot read it and raw DB bytes do not expose the synthetic pincode; the
real Android form saves at 200% text using the same key and clears pending state; native
location requests can complete/cancel twice without leaving the channel busy. The test
uses separate secure-storage/DB files and cleans them afterward. API responses are
simulated, not live server/DB evidence. A successful GPS fix and OS permission dialogs
remain manual checks. The integration APK build also passed (80.7 seconds).

Executed from repository root:
```powershell
adb devices
adb -s emulator-5554 install -r -g apps/mobile/build/app/outputs/flutter-apk/app-dev-debug.apk
node --check tools/check-task.mjs
node --test tools/checks.spec.mjs
git diff --check
```
ADB initially listed no devices; emulator-5554 was connected for the successful checks.
The normal APK was preserved at ignored `.dart_tool/t025-normal-app-dev-debug.apk` before
the integration build, then restored with `adb -s emulator-5554 install -r
.dart_tool/t025-normal-app-dev-debug.apk` so the test entrypoint is not left installed.
The normal APK also replaces the integration APK in the standard build output path.
Location permission grants used by the smoke were revoked afterward with `adb -s
emulator-5554 shell pm revoke in.supplybiz.mobile.dev android.permission.ACCESS_FINE_LOCATION`
and the equivalent `ACCESS_COARSE_LOCATION` command, allowing manual permission testing.
Only the Gradle/Kotlin daemons started by these checks were stopped; the existing
emulator and services are preserved.
Runner syntax and all 4 guard checks pass; diff whitespace check passes. T-025 focused
checks are registered in the existing runner; full runner/hosted CI/module suites NOT_RUN.
GPS permission prompts/fix, app → live API/PostgreSQL, TalkBack and user manual PASS are
NOT_RUN. iOS checks are DEFERRED (ADR-025). G0/G1 remain pending. Task is READY_FOR_VERIFY;
DONE requires manual PASS under AGENTS §11/PROMPTS §6. The pre-existing emulator/services
are preserved; no newly started build/test process is intentionally left running.

Manual verification (pending; Android build prerequisite now passes):
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
