# Admin — T-150 handoff

## T-154 dashboard handoff (2026-11-12): READY_FOR_VERIFY

S-A-02 / FR-401: `/dashboard` is linked from the workspace for `dashboard.read`
(currently SUPER_ADMIN under ADR-026). The server component uses the generated TS
client and existing httpOnly session/BFF path. API authorization rechecks current
role, status and session on every read. All responses are no-store. Loading,
refresh, expired-login redirect, permission denial and unavailable/retry states
are explicit; API failure never becomes synthetic zero metrics.

One PostgreSQL statement provides a consistent all-time snapshot of retained
vendor/suspension, pending/verified KYC, CUSTOMER-role account/block, order,
delivered/failed and historical audited-assignment counts. Dual-role accounts
count once; offline vendor contacts are excluded. Deleted/blocked accounts remain
included, as the visible definitions explain. Database update time is shown in IST.

Recorded delivered-order value sums persisted DELIVERED `total_paise`, including
delivery charges; discounts remain zero under the existing schema. Decimal paise
strings and BigInt INR formatting preserve precision above Number's safe range.
PRD section 6 defines full platform GMV as delivered orders PLUS quick sales:
`gmvScope: DELIVERED_ORDERS_ONLY` and the page explicitly mark the quick-sale/full
GMV component unavailable until T-079/T-080. This is not payment collection or
platform revenue. Delivery success follows DELIVERED / (DELIVERED + FAILED), with
an explicit empty denominator. Audited grants include superseded history and do
not imply purchases. Automated plan revenue is UNAVAILABLE (SR-03), never zero or
inferred from assignments. Actual order/delivery writers remain T-045/T-049;
synthetic test DB records verify read paths, not those future business flows.

Executed commands and evidence (root unless stated):

- `& 'C:/Program Files/Git/bin/bash.exe' tools/codegen.sh`: PASS, OpenAPI and matching TS/Dart clients regenerated from DTO/controller source, including the explicit GMV scope.
- `pnpm.cmd --filter @supplybiz/api lint`, `pnpm.cmd --filter @supplybiz/api typecheck`, `pnpm.cmd --filter @supplybiz/api build`: PASS on final API source.
- `pnpm.cmd --filter @supplybiz/admin lint`, `pnpm.cmd --filter @supplybiz/admin typecheck`, `pnpm.cmd --filter @supplybiz/admin build`: PASS; final normal production build includes `/dashboard` and final user-facing GMV wording. TS consumer compiled against regenerated types.
- `pnpm.cmd --filter @supplybiz/admin exec tsx --test test/dashboard.test.ts`: PASS, two focused BigInt/INR/zero-denominator cases.
- From packages/api_client, `flutter analyze --no-pub`: PASS, no issues after final contract regeneration.
- From apps/api, `.\node_modules\.bin\jest.cmd --runInBand --testTimeout=60000 --runTestsByPath src/modules/dashboard/dashboard.postgres.spec.ts`: PASS, four native cases. NATIVE_TEST_DATABASE_URL was derived from existing .env DATABASE_URL with only the DB path replaced by `/supplybiz_service_area_test`; NODE_ENV=test, OTP_DELIVERY_MODE=disabled. Four focused native cases cover RBAC/current session denial, DB count deltas/exact large paise, real audited grants independent of GMV/revenue, and production Next.js to API to PostgreSQL rendering/refresh/API outage/restart recovery.
- `node --test tools/checks.spec.mjs`: PASS, five runner guards; T-154 registered for focused native/admin checks.
- `git diff --check`: PASS.

Initial test fixtures were corrected to the existing schema: order-number length,
creation preceding completion, and zero discount. HTTP 201 grant responses and
Next.js streamed login redirects are handled in assertions. No schema constraint,
permission or business rule was weakened. All native test services are temporary
and closed by teardown; synthetic immutable audit/grant records remain only in
the dedicated test DB. No dependency or migration added. TEMP logs are
supplybiz-t154-native.log and supplybiz-t154-codegen.log.

Manual verification (suggested, NOT_RUN):
1. Start the existing API/admin commands against an agreed migrated environment,
   sign in as SUPER_ADMIN and open Dashboard. Compare counts/value with DB records.
2. Change persisted KYC/customer/order state through its owning feature and Refresh;
   confirm fresh values, visible definitions and IST update time.
3. Check the partial delivered-order GMV label, unavailable quick-sale/full GMV and
   unavailable automated plan revenue. A manual grant changes only grant count.
4. Verify OPS/SUPPORT/FINANCE denial and hidden workspace link; test expired login,
   API offline/restart and Retry without fake zeroes or exposed credentials.
5. Check keyboard/screen reader and 200% browser zoom, responsive metric wrapping,
   labels and loading/error announcements.

Manual browser/accessibility/PASS, deployed HTTPS and module gates remain NOT_RUN.
No mobile UI changed; iOS checks deferred. Stop for task-specific manual verification.

## T-153 — Categories implementation handoff (2026-11-10)

S-A-08 is `/categories`, linked from the workspace for OPS/SUPER_ADMIN.
Create/edit English name, code, icon identifier, type, availability, display order
and product types. Hidden preserves vendor references; referenced category types
cannot change. BILL taxonomy creates no bill-payment flow. Writes use the generated
server-side client, origin/session-bound CSRF, stable form retry keys and atomic
actor-scoped replay/category/audit persistence. No schema migration was needed.

Status: READY_FOR_VERIFY. API lint/typecheck/build, regenerated TypeScript/Dart
clients, admin lint/TypeScript/production build and Dart client analysis pass.
Native test DB `supplybiz_service_area_test` has all 12 migrations. Seven focused
checks pass, including production Next.js → BFF → API → PostgreSQL rendering/save,
cross-origin denial and restricted-role page denial. Four admin security tests,
two native-runtime checks and four task-runner guard checks also pass. The
audit-failure injection targets AppModule's database instance explicitly
(AuthModule has another instance) and proves the category write rolls back.
The earlier permission blocker is resolved by user approval; the initial sandbox
startup timeout is resolved by running the native checks outside the sandbox.
No manual PASS or G0/G1 pass is claimed.

Executed commands (repository root unless a directory is specified):
```powershell
pnpm.cmd --filter @supplybiz/api typecheck
pnpm.cmd --filter @supplybiz/api lint
pnpm.cmd --filter @supplybiz/api build
& 'C:/Program Files/Git/bin/bash.exe' tools/codegen.sh
pnpm.cmd --filter @supplybiz/api exec prisma migrate status --schema src/prisma/schema.prisma
pnpm.cmd --filter @supplybiz/admin typecheck # initially failed; fixed, then tsc below passed
pnpm.cmd --filter @supplybiz/admin lint
pnpm.cmd --filter @supplybiz/admin build
pnpm.cmd --filter @supplybiz/admin test
# In apps/admin and apps/api respectively:
node node_modules/typescript/bin/tsc --noEmit
# In packages/api_client:
dart.bat analyze
# Root, with ADMIN_TEST_DATABASE_URL and DATABASE_URL loaded from ignored local
# environment credentials, restricted to localhost/supplybiz_service_area_test:
$env:CATEGORIES_ADMIN_SMOKE = '1'
node apps/api/node_modules/jest/bin/jest.js --config apps/api/jest.config.ts --runInBand --testTimeout=30000 --runTestsByPath apps/api/src/modules/categories/categories.postgres.spec.ts
# NATIVE_TEST_DATABASE_URL and DATABASE_URL use that same isolated local database:
node apps/api/node_modules/jest/bin/jest.js --config apps/api/test/jest-e2e.json --runInBand --testTimeout=30000 --runTestsByPath apps/api/test/native-runtime.e2e-spec.ts
node --test tools/checks.spec.mjs
git diff --check
```
NOT_RUN: browser keyboard/200%/manual PASS and deployed HTTPS. No new check services
remain running; the production smoke server on port 3143 was stopped by its test.
Local Node 23 differs from the pinned Node 20 baseline. The registered T-153 task
runner includes admin checks and enables this production smoke automatically.

Manual verification after checks, using the existing local setup below:
1. Sign in as OPS/SUPER_ADMIN; open Categories, create a SUPPLY category, then
   reload and verify its icon, product types and display order persist.
2. Edit its name/order and set Coming soon, Enabled, then Hidden; verify the
   enabled supply list used by onboarding includes only enabled supply categories.
3. Repeat a save submission and try a duplicate code/invalid fields; confirm one
   write/audit for the replay and an understandable error for invalid changes.
4. As SUPER_ADMIN, filter Audit log by CATEGORY_CREATE/CATEGORY_UPDATE and check
   actor/before/after. SUPPORT/FINANCE must have no link or category API access.
5. Check keyboard focus, labels, expansion and saving at 200% zoom; hide a category
   referenced by a vendor and confirm that vendor record remains intact.

T-150 implements S-A-01 / FR-400 and ADR-026. Status: READY_FOR_VERIFY; manual PASS and G1 remain pending.

## Local setup (suggested commands; services are stopped after automated checks)

Use Node >=20.9 (the task checks ran on Node 26.13.0); admin CI uses Node 22.14.
Use the same migrated native PostgreSQL database as the API. Apply migrations with
`pnpm --filter @supplybiz/api prisma:migrate:deploy` using your local DATABASE_URL.
Set API `ADMIN_TOTP_KEY` to a persistent random 32-byte AES key encoded as 64 hex
characters. Missing configuration disables admin login. Back this key up securely;
changing it requires re-enrolling existing authenticators.

Create ignored `apps/admin/.env.local` with:

```dotenv
ADMIN_ORIGIN=http://127.0.0.1:3100
ADMIN_API_URL=http://127.0.0.1:3000
# Supply at least 32 random characters locally; no shared/default key.
ADMIN_CSRF_KEY=
NEXT_TELEMETRY_DISABLED=1
```

Start the API using its existing local environment and `pnpm --filter @supplybiz/api dev`.
Provision a staff account using `pnpm --filter @supplybiz/api admin:provision`, supplying
one JSON object on stdin containing email, password (12–128 characters) and role
(SUPER_ADMIN / OPS / SUPPORT / FINANCE). Feed credentials from a protected local
file/password manager, keeping them out of shell arguments, history and logs.
The operator command checks HIBP Pwned Passwords with only a five-character hash
prefix and fails closed on a breach/provider error; then stores Argon2id and an
auth event in one transaction. No default login is seeded. Account management UI
belongs to T-162. Start admin with `pnpm --filter @supplybiz/admin dev`, then open
http://127.0.0.1:3100/login (use that exact origin).

## Behavior and boundaries

A password creates a five-minute challenge, never a staff session. First login
shows a setup key for a standard time-based authenticator (SHA1, six digits, 30s).
A valid code persists the AES-256-GCM secret and creates a session atomically;
challenges and TOTP steps cannot be replayed across API processes. Five cumulative
password/code failures lock that account for 30 minutes. Successful 2FA resets
failures. Session credentials are hashed in PostgreSQL, revoked at logout, and
checked against the current account status/role on every request. Expiry is 30
minutes idle and eight hours absolute; login cannot extend an existing session.
Expired challenge/session records for an account are removed on its next login.

The server-only typed API wrapper uses generated TypeScript operations. Browser
forms submit only to the Next.js BFF. Session/challenge cookies are httpOnly and
SameSite=Strict; HTTPS sets Secure. HTTP is permitted solely for localhost.
Mutation forms require configured-origin matching and signed, expiring CSRF fields;
API session mutations also require the session-bound CSRF token. Responses are
not cached. Production origin/HTTPS/domain setup remains Q-33.

The workspace lists only the current role's explicit grants. No unfinished feature
routes are linked. The global API AdminGuard denies every unannotated admin route;
future routes declare `@AdminPermission(...)`. SUPPORT has read-only grants and
cannot review/view private KYC or export. Unknown/deferred permissions are denied,
including for SUPER_ADMIN. Auth-only append-only events are persisted now;
T-152 owns the general audit module/viewer.

## Dependency rationale

Next.js/React and Tailwind implement the documented admin stack; openapi-fetch is
a small typed transport over the generated contract, and server-only prevents
accidental browser imports. Argon2 0.41.1 implements the required password scheme
with native Node support. These MIT-licensed packages are pinned in the workspace
lockfile; the framework adds the largest runtime/build footprint. ESLint,
TypeScript, PostCSS and tsx supply actual checks/build tooling. No authentication
SDK, UI framework, QR service or browser-test runtime is added. The operator breach
check follows the [HIBP range protocol](https://haveibeenpwned.com/API/v3#PwnedPasswords);
password hashing follows [node-argon2](https://github.com/ranisalt/node-argon2).

## Executed checks (2026-11-04)

The isolated database is `supplybiz_admin_test` on native PostgreSQL 17.11. The
additive migration was applied there only; the normal development DB was untouched.
Exact task command (exit 0):

```sh
DATABASE_URL=postgresql://ankit@localhost:5432/supplybiz_admin_test NATIVE_TEST_DATABASE_URL=postgresql://ankit@localhost:5432/supplybiz_admin_test ABUSE_TEST_DATABASE_URL=postgresql://ankit@localhost:5432/supplybiz_admin_test node tools/check-task.mjs T-150
```

This executes API/admin lint, typecheck and builds; two admin CSRF/cookie tests;
12 focused API/password/real-PostgreSQL checks; and two native readiness/fail-closed
provider checks. The production Next.js smoke submits rendered password, TOTP and
logout forms through the BFF to the real API/DB; it checks pending-only login,
SUPPORT permission visibility, CSRF/origin rejection, session-cookie flags and
revocation. It starts/stops its own Next process on 3139 and uses no browser.
Synthetic accounts are disabled afterward; immutable auth events remain in the
isolated DB. Pre-existing services are preserved.

Also executed successfully:

```sh
DATABASE_URL=postgresql://ankit@localhost:5432/supplybiz_admin_test pnpm --filter @supplybiz/api prisma:migrate:deploy
PATH=/Users/ankit/.pub-cache/bin:$PATH tools/codegen.sh
/Users/ankit/.pub-cache/bin/fvm dart analyze packages/api_client
node --test tools/checks.spec.mjs
```

Prisma/client generation completed; TS and Dart clients match the changed source
contract. Dart analysis: no issues; task-runner guards: 4/4 pass. Generated Markdown
normalization also covers the client README. Initial lint/typecheck/test assertions
were corrected before the successful task run. Local build/log output is ignored.

NOT_RUN: browser visual/keyboard/screen-reader/200% scale checks, live HIBP account
provisioning and deployed HTTPS cookie checks, hosted CI, process-restart manual
drill, manual PASS and comprehensive G1. HIBP parser/network-failure handling uses
focused injected responses; no live breach-provider result is claimed. Mobile
build/run is not affected; iOS remains deferred under ADR-025. Q-09 still blocks
live mobile OTP; it does not block password/TOTP staff login.

## Manual verification

1. Configure persistent keys, migrate your local DB, provision a synthetic staff
   account and start the API/admin using the setup above.
2. Open `/login`; enter credentials, add the setup key to an authenticator, enter
   its code and confirm the expected role/grants. Sign out and sign in again with
   a fresh code; no new enrolment should be requested.
3. Use a SUPPORT account and confirm KYC/private-document/export/admin-account
   permissions are absent. The focused HTTP probe verifies forbidden API access;
   actual KYC business screens are later tasks.
4. Submit wrong password/codes five times, verify lockout persists across API
   restart, then check logout revokes access and idle/absolute expiry rejects the
   next request (use isolated fixtures to adjust timestamps for a quick check).
5. Check keyboard navigation, error announcements and layout at 200% zoom; on an
   HTTPS origin inspect Secure/httpOnly/Strict cookies and reject cross-origin or
   altered-CSRF form submissions.

## T-152 — Audit viewer handoff (2026-11-04)

READY_FOR_VERIFY; FR-411 / TC-408 / S-A-16. SUPER_ADMIN sees “Open audit log”
on the workspace and can open `/audit-logs`. OPS/SUPPORT/FINANCE have neither
navigation nor API access. This server-rendered page uses the generated client,
server-held session cookie and uncached API responses. It provides action/actor
filters, 50-record cursor pages, empty/invalid-filter/error states and read-only
actor/action/entity/before/after/IP/UTC time. Keyboard and 200% browser checks
remain manual; no browser visual/accessibility pass is claimed.

The additive `20261104130000_audit_logs` migration installs append-only audit
storage (UPDATE/DELETE/TRUNCATE rejected). Triggers capture current admin-account
writes with an explicit safe projection: role, status, failure count, lock/login
times and whether TOTP is enrolled. Emails, password hashes, tokens, TOTP secrets,
request bodies, filenames and private document contents never enter snapshots.
Auth events and private-document reads are mirrored atomically, with historical
actor/time backfilled; historical IP/snapshots are null, never fabricated.
Auth challenges/session usage and expired-session housekeeping are represented by
auth outcome events rather than credential snapshots. Account provisioning or
operator writes without authenticated request context are labeled SYSTEM.

`auditContext(tx, actorId, socketIp)` sets transaction-local identity/IP; use only
server-derived identities in the business transaction. Auth and private-media
paths set it now. IP is the API socket address (behind the BFF it is the BFF IP),
never an untrusted forwarded header. Future KYC/plan/ledger/admin tasks must add
their own atomic audit records and explicit redacted snapshot contracts when
implementing those actions. No future business action is claimed covered here.
No purge schedule is invented: Q-20 retention remains unresolved. Removing this
feature requires an approved follow-up migration; never drop retained audit data.

Executed successfully (native PostgreSQL 17.11, isolated `supplybiz_admin_test`):

```sh
pnpm --filter @supplybiz/api prisma:generate
DATABASE_URL=postgresql://ankit@localhost:5432/supplybiz_admin_test pnpm --filter @supplybiz/api prisma:migrate:deploy
PATH=/Users/ankit/.pub-cache/bin:$PATH tools/codegen.sh
DATABASE_URL=postgresql://ankit@localhost:5432/supplybiz_admin_test NATIVE_TEST_DATABASE_URL=postgresql://ankit@localhost:5432/supplybiz_admin_test ABUSE_TEST_DATABASE_URL=postgresql://ankit@localhost:5432/supplybiz_admin_test node tools/check-task.mjs T-152
/Users/ankit/.pub-cache/bin/fvm dart analyze packages/api_client
node --test tools/checks.spec.mjs
git diff --check
```

The task runner executes API/admin lint, typecheck and builds; 2 CSRF/cookie
checks; 6 focused audit checks; and 2 native runtime checks. All pass, alongside
4 runner guards and clean generated Dart analysis. Audit checks exercise native
HTTP auth/TOTP/logout/document access, all role restrictions, redaction,
transaction-local context, rollback/fail-closed atomic writes, immutability and
tied-timestamp pagination. A production Next.js server on 3140 renders real
API/DB records, denies SUPPORT and exercises empty/invalid filters; this is an
HTTP-rendering smoke, not browser interaction. It stops its Next.js/API processes
and removes temporary test files. Disabled synthetic accounts and immutable audit
fixtures remain only in the isolated DB. No development DB migration was applied.

Initial sandbox-only commands could not access PostgreSQL/SDK cache and were
rerun with permission. The first migration name sorted ahead of media tables;
PostgreSQL rolled it back, Prisma's failed record was resolved as rolled back and
the correctly ordered migration applied successfully. No retained data was dropped.

Suggested manual verification (use T-150 setup above; these are not executed):

1. Migrate your local DB, start API/admin, sign in as SUPER_ADMIN and open the audit
   log. Confirm actor/action/entity, UTC times, safe snapshots and IP are displayed.
2. Sign out/in, reload the viewer and confirm fresh auth events. Filter using an
   action and actor UUID, follow Older records, clear filters and try an empty result.
3. Sign in as OPS/SUPPORT/FINANCE; confirm the audit link is absent and direct
   `/audit-logs` access is denied. Confirm unauthenticated access returns to login.
4. Use keyboard navigation and 200% zoom; verify readable records, labels, focus
   and error announcements. Stop the API briefly and confirm a recoverable error.

NOT_RUN: manual PASS, browser keyboard/screen-reader/200% checks, hosted CI,
deployed HTTPS/proxy verification and comprehensive G1. Q-33 still owns production
domains; Q-20 owns retention. iOS remains deferred; this task changes no mobile UI.


## T-151 — Manual KYC review handoff (2026-11-10)

READY_FOR_VERIFY; FR-402 / S-A-03–04 / TC-402/403/509. OPS and SUPER_ADMIN
can open `/kyc` from the workspace, page through the oldest waiting cases and
open `/kyc/{submissionId}`. SUPPORT/FINANCE are denied navigation, case data,
documents and decisions. The API rechecks current permissions for each operation.
The queue handles empty/error states; cases show persisted status, reviewer,
reason, UTC timestamps, masked PAN/account endings and MANUAL_REVIEW/NOT_RUN.

Documents are opened explicitly, never prefetched. The BFF resolves only the
chosen case's front/back/PAN attachment and proxies the existing audited private
stream using the server-held session. API access auditing completes before bytes
are returned. Responses are uncached, inline and restricted to PNG/JPEG/PDF;
credentials, filenames and storage paths never enter the page. The viewer overlays
CONFIDENTIAL, reviewer ID and current UTC time, with no application download
button. PDF toolbar hiding uses the browser viewer's `#toolbar=0`; actual browser
PDF behavior remains a manual check. Only `/kyc/:id/documents/:kind` permits
same-origin framing; all other admin pages retain DENY/frame-ancestors none.
Watermarking is a UI overlay, not alteration of retained originals.

Decisions require a reason (3–500 trimmed characters), signed session/case-bound
retry key, expiring form CSRF, configured Origin and API session CSRF. Repeated
POSTs reuse the key. The API atomically persists vendor status, immutable case
review, redacted audit and in-app notice; conflicting decisions cannot overwrite
an earlier review. Errors return to the current persisted case so an uncertain
network outcome can be checked before retrying. Reviewed cases have no decision
form. VERIFIED explicitly means manual approval; provider checks and push delivery
are NOT_RUN. The existing T-022 staging/production KMS limitation still applies.
No API/schema change or client regeneration was required.

Executed successfully against existing migrated native PostgreSQL 17.11,
isolated `supplybiz_sessions_test` (no migration applied by this task):

```sh
DATABASE_URL=postgresql://ankit@localhost:5432/supplybiz_sessions_test NATIVE_TEST_DATABASE_URL=postgresql://ankit@localhost:5432/supplybiz_sessions_test ABUSE_TEST_DATABASE_URL=postgresql://ankit@localhost:5432/supplybiz_sessions_test node tools/check-task.mjs T-151
node --test tools/checks.spec.mjs
git diff --check
```

The registered task runner passed API/admin lint, typecheck and builds, 4 admin
CSRF/cookie/retry-key/document-selector checks, 10 focused native KYC checks and
2 native runtime checks; runner guards passed 4/4. The KYC suite includes a
production Next.js server on 3141 → native API → PostgreSQL/private files smoke:
role denial, login redirect, queue/case rendering without raw account/session data,
attachment selection, access audit, cache/framing headers, cross-origin/CSRF/key
and blank-reason rejection, persisted rejection and duplicate form replay with
one notice/audit. Existing focused API cases cover approval, rejection/resubmission,
concurrent conflicting decisions, immutable audit, rollback and provider truthfulness.
Temporary servers/files are stopped/removed; disabled synthetic accounts and
immutable test audits/revisions remain only in the isolated database. The successful
runner log is `/tmp/supplybiz-t151-checks.log` (local, uncommitted).

Standalone admin typecheck/lint/build, API lint, and runner guards also passed.
Initial sandboxed `pnpm --filter @supplybiz/admin test` could not create its IPC
socket and was rerun successfully through the permitted native task runner.
The first runner attempt caught a test lint escape; later smoke attempts corrected
an assertion for Next.js streamed redirects and caught/fixed the global framing
header blocking embedded documents. A focused intermediate command was:
`KYC_TEST_DATABASE_URL=postgresql://ankit@localhost:5432/supplybiz_sessions_test KYC_ADMIN_SMOKE=1 pnpm --filter @supplybiz/api exec jest --runInBand --runTestsByPath src/modules/kyc/kyc.postgres.spec.ts`.
All final registered task checks pass; earlier failures are not counted as passes.

Suggested manual verification (not executed; use T-150 local setup above):

1. Start API/admin against the same migrated local DB. Submit synthetic masked
   documents through the T-024 flow or existing T-022 API instructions, then sign
   in as OPS and open the manual KYC queue/case; confirm persisted identity/status
   summaries and provider NOT_RUN. Exercise pagination/empty/error recovery.
2. Open each PNG/JPEG/PDF attachment. Confirm readable masked documents,
   reviewer/time watermark, no application download button and a new immutable
   KYC_DOCUMENT_READ audit row per view (SUPER_ADMIN audit viewer). Check PDF
   rendering/toolbar behavior in the supported browser.
3. Reject with a reason, reload and check vendor status/reason/in-app notice;
   resubmit as the vendor, then approve the fresh case. Confirm MANUAL_REVIEW
   method, one audit/notice per decision and no form on a reviewed submission.
4. Use SUPPORT/FINANCE and signed-out sessions to try direct queue/case/document
   URLs; confirm denial. Test expired forms and two reviewers deciding one case;
   the saved decision must remain immutable.
5. Check keyboard focus, screen-reader labels/errors and 200% zoom; briefly stop
   the API and confirm recoverable queue/case/document errors.

NOT_RUN: manual PASS; browser PDF/visual/keyboard/screen-reader/200% checks;
deployed HTTPS/proxy and hosted CI; push/provider delivery; comprehensive G0/G1.
Q-09 live OTP and production KMS/domain prerequisites remain outside this local
admin handoff. Mobile is unchanged; iOS checks remain deferred under ADR-025.

## T-156 plan catalog and assignment handoff (2026-11-11)

READY_FOR_VERIFY: S-A-09 `/plans` and S-A-10 `/plans/vendors/{vendorId}`.
The workspace link appears only for plans.manage (SUPER_ADMIN and FINANCE).
Scoped vendor search returns business name/ID without granting broader vendor,
contact, customer or KYC access. Pages use Server Components and the generated
TypeScript client; API bearer credentials stay in HttpOnly cookies/server calls.

Catalog forms edit English name, availability, popularity and three reference
prices. Approved caps and feature gates remain read-only. Decimal rupees convert
to integer paise without floating-point rounding. A required reason, stable key
and expectedUpdatedAt protect audited writes against duplicate/stale submissions.
Changing availability to INACTIVE also removes active entitlements; the form
explains this effect. No purchase, receipt, invoice or revenue flow is added.

Vendor pages display real status, cap/count/growth availability, features, validity
and paginated assignment/audit history. Assignment and extension forms send IST
dates as timezone-qualified timestamps, with reason and current assignment ID.
The backend retains records and applies ADR-029 expiry/downgrade rules. Dates and
money are independent of the browser/host timezone. Only audit.read users receive
a link to the existing audit viewer; FINANCE still sees plan assignment evidence.

Every mutation checks origin, session CSRF and a session/operation/target-bound
request key. A connection failure creates a signed, HttpOnly/Strict recovery
cookie under `/plans` for 10 minutes, preserving the same key and submitted body.
`/plans/retry` offers a safe retry; success clears recovery state. The API still
rechecks permission/session, payload identity, validity and ownership before any
write/replay. Loading, empty, unavailable, denied and success states are rendered.
Controls use associated labels and 48px targets; full browser/accessibility PASS
remains manual. No client component or dependency was added.

Executed from apps/admin (PowerShell):

```powershell
.\node_modules\.bin\eslint.cmd . --max-warnings=0
node node_modules/next/dist/bin/next typegen
.\node_modules\.bin\tsc.cmd --noEmit
.\node_modules\.bin\tsx.cmd --test test/*.test.ts
node node_modules/next/dist/bin/next build --webpack
```

Executed from apps/api:

```powershell
.\node_modules\.bin\eslint.cmd src test scripts jest.config.ts --max-warnings=0
.\node_modules\.bin\tsc.cmd --noEmit
.\node_modules\.bin\tsc.cmd -p tsconfig.build.json
.\node_modules\.bin\prisma.cmd validate --schema src/prisma/schema.prisma
.\node_modules\.bin\tsc.cmd --noEmit --skipLibCheck --target ES2022 --module NodeNext --moduleResolution NodeNext ../../packages/ts-client/src/generated/openapi.ts
$dbLine = Get-Content .env | Where-Object { $_ -match '^DATABASE_URL=' } | Select-Object -First 1
$taskUrl = [UriBuilder]::new(($dbLine -replace '^DATABASE_URL=', '').Trim('"', "'"))
$taskUrl.Path = '/supplybiz_service_area_test'
$env:NATIVE_TEST_DATABASE_URL = $taskUrl.Uri.AbsoluteUri
$env:NODE_ENV = 'test'
$env:OTP_DELIVERY_MODE = 'disabled'
.\node_modules\.bin\jest.cmd --runInBand --testTimeout=60000 --runTestsByPath src/modules/plans/plan-admin.postgres.spec.ts src/modules/plans/plan-assignments.postgres.spec.ts src/modules/plans/plans.postgres.spec.ts
.\node_modules\.bin\jest.cmd --config test/jest-e2e.json --runInBand --testTimeout=60000 --runTestsByPath test/native-runtime.e2e-spec.ts
```

From root: `& 'C:/Program Files/Git/bin/bash.exe' tools/codegen.sh`,
`node --test tools/checks.spec.mjs`, `git diff --check`.
From packages/api_client: `flutter.bat analyze lib`.

Results: 25 native checks PASS (4 catalog/admin with production Next.js/BFF/DB,
9 assignment/reminder and 12 entitlement), 8 admin security/form checks PASS,
2 runtime smokes and 5 runner guards PASS. API/admin lint/typecheck/build/schema,
TS/Dart generation and client compile/analysis PASS. The native drill stopped and
restarted its API, preserved the form/key, replayed without duplicate grants,
extended the assignment and read retained escaped history. Requests used synthetic
sessions; this is not live OTP/provider or manual-browser verification. The tsx
runner initially failed sandbox Windows user-info access; permitted rerun passed.
Native checks/build used permission for Windows ACL/host calls. No new migration
was required or applied. Only the dedicated test DB was exercised; catalog
metadata/prices were restored afterward and immutable synthetic audit/replay/
assignment records retained. Temporary servers were closed; pre-existing services
were preserved. Native output: host temp `supplybiz-t156-focused.log`.

Manual verification (suggested, NOT executed):
1. Apply pending T-103 migrations to the intended local dev DB and start the API
   and admin using existing instructions. Sign in as FINANCE or SUPER_ADMIN;
   open Manage plans and assignments. SUPPORT/OPS must see no forms/access.
2. Edit a catalog reference price/name with a reason. Confirm refreshed values
   and audit, fixed caps/features, rejection of invalid prices/blank reasons,
   and conflict/reload when submitting an older tab after another edit.
3. Find a synthetic vendor, choose an active tier and valid IST start/end with
   reason. Confirm persisted current plan/cap/features and one audit/history row.
   Resubmit the same form and confirm no duplicate grant.
4. Extend the current plan and verify the old record remains. Use an over-cap
   downgrade/expired synthetic fixture to confirm retained customers, restricted
   growth and the documented renewal behavior. No payment/invoice should appear.
5. Check keyboard order, labels, errors and 200% zoom. Briefly stop only your
   manually started API during a request, then restart it and use Retry this
   request safely. Verify one result; stop your manually started services.

NOT_RUN: manual PASS, browser/screen-reader/200% acceptance, deployed HTTPS,
live push and G0/G1 comprehensive gates. Mobile builds are not needed for this
ADM/API change; iOS remains deferred under ADR-025. Roll back source/clients
together and retain existing catalog/assignment/audit/replay evidence.

## T-155 vendor/customer administration handoff (2026-11-11)

READY_FOR_VERIFY: S-A-05 `/vendors`, S-A-06 `/vendors/{id}` and S-A-07
`/customers` / `/customers/{id}`. SUPPORT may search/view; OPS and SUPER_ADMIN
may also mutate; FINANCE has no general vendor/customer access. Read-only vendor
detail includes real KYC/plan metadata without exposing private KYC documents.
Customer management covers app accounts with CUSTOMER role, including dual-role
accounts. Vendor-owned offline contacts stay in the existing vendor-customer flow.

Suspend/reinstate, badge edits and block/unblock require reason, expected version,
session CSRF and a stable operation/target-bound key. Destructive status forms
require confirmation naming the target. Signed HttpOnly/Strict recovery cookies
preserve the original request/key for 10 minutes after a connection failure;
success clears recovery state. Backend role/session checks precede every replay.
Status/badge writes, PII-minimized audit and permanent replay commit together.
Stale tabs return conflict rather than overwrite another admin's decision.

Vendor suspension uses existing server vendor guards and preserves records,
KYC and assigned plans. Display badges are editable labels (up to ten, 40 chars
each), not verification or entitlement grants. Customer blocking applies across
the shared account's roles, revokes sessions and clears device push tokens under
the existing auth user lock. Unblock permits fresh sign-in; old tokens remain
revoked and deleted accounts cannot be restored here. No order/GMV values or
discovery eligibility are fabricated.

Selection: ROADMAP Day 5 explicitly puts T-040/T-041/T-042 after G1 manual-plan
pass (currently NOT RUN). T-154's required orders/GMV/delivery sources are absent.
T-155's T-150 dependency is READY_FOR_VERIFY, so this independent admin lane was
eligible. No prior task status or gate was changed to bypass those prerequisites.

Executed from apps/admin (PowerShell):

```powershell
.\node_modules\.bin\eslint.cmd . --max-warnings=0
node node_modules/next/dist/bin/next typegen
.\node_modules\.bin\tsc.cmd --noEmit
.\node_modules\.bin\tsx.cmd --test test/*.test.ts
node node_modules/next/dist/bin/next build --webpack
```

Executed from apps/api:

```powershell
.\node_modules\.bin\prisma.cmd generate --schema src/prisma/schema.prisma
$dbLine = Get-Content .env | Where-Object { $_ -match '^DATABASE_URL=' } | Select-Object -First 1
$taskUrl = [UriBuilder]::new(($dbLine -replace '^DATABASE_URL=', '').Trim('"', "'"))
$taskUrl.Path = '/supplybiz_service_area_test'
$env:DATABASE_URL = $taskUrl.Uri.AbsoluteUri
.\node_modules\.bin\prisma.cmd migrate deploy --schema src/prisma/schema.prisma
$env:NATIVE_TEST_DATABASE_URL = $taskUrl.Uri.AbsoluteUri
$env:SESSIONS_TEST_DATABASE_URL = $env:NATIVE_TEST_DATABASE_URL
$env:NODE_ENV = 'test'
$env:OTP_DELIVERY_MODE = 'disabled'
.\node_modules\.bin\jest.cmd --runInBand --testTimeout=60000 --runTestsByPath src/modules/management/management.postgres.spec.ts src/modules/auth/sessions.postgres.spec.ts
.\node_modules\.bin\jest.cmd --config test/jest-e2e.json --runInBand --testTimeout=60000 --runTestsByPath test/native-runtime.e2e-spec.ts
.\node_modules\.bin\eslint.cmd src test scripts jest.config.ts --max-warnings=0
.\node_modules\.bin\tsc.cmd --noEmit
.\node_modules\.bin\tsc.cmd -p tsconfig.build.json
.\node_modules\.bin\prisma.cmd validate --schema src/prisma/schema.prisma
.\node_modules\.bin\tsc.cmd --noEmit --skipLibCheck --target ES2022 --module NodeNext --moduleResolution NodeNext ../../packages/ts-client/src/generated/openapi.ts
```

From root: `& 'C:/Program Files/Git/bin/bash.exe' tools/codegen.sh`,
`node --test tools/checks.spec.mjs`, `git diff --check`.
From packages/api_client: `flutter.bat analyze lib`.

PASS: 14 native checks (6 management including production Next.js/BFF/API/DB and
real API outage/restart, 8 session regressions), 10 admin security/form checks,
2 runtime smokes, 5 runner guards, API/admin lint/typecheck/build/schema, regenerated
TS/Dart clients and client compile/analysis. Blocked-login OTP verification was
simulated; account/session HTTP and PostgreSQL effects were real. Native UI checks
used synthetic admin sessions, not a live-provider or manual-browser login pass.
The rollback drill's first stub targeted the root Prisma delegate rather than
the transaction; the corrected in-transaction failure proves status/audit/replay
rollback. The existing session fixture now initializes private Windows ACLs.
Only the isolated test DB was migrated; immutable synthetic fixtures remain.
Temporary test servers were closed and pre-existing services preserved. Native
output: host temp `supplybiz-t155-focused.log`.

Manual verification (suggested, NOT executed):
1. Apply the migration to the intended local dev DB, start API/admin with the
   existing instructions, then sign in as SUPPORT. Search/view vendors/customers;
   confirm mutation forms are absent. FINANCE must be denied these pages.
2. As OPS/SUPER_ADMIN, suspend a synthetic vendor with reason/confirmation.
   Confirm stored state, business API denial and audit; reinstate and verify
   records/KYC/plan metadata are retained. Replaying the old suspension request
   must not reapply it after reinstatement.
3. Edit display badges and inspect escaped rendering/audit. Verify duplicates,
   overlong labels, blank reasons and stale-tab edits are rejected.
4. Block a synthetic customer and verify existing access/refresh and new login
   are denied. Unblock, sign in afresh and confirm old sessions stay revoked.
   Deleted accounts must offer no reactivation form.
5. Test keyboard order/200% zoom and API-stop/restart recovery with Retry this
   request safely. Confirm one audit/change and stop manually started services.

NOT_RUN: manual browser/accessibility/PASS, live OTP/push, deployed HTTPS and
G0/G1 comprehensive gates. Discovery hiding/order-acceptance E2E awaits T-041/
T-045; existing vendor business denial and the persisted suspension contract were
checked here. No mobile native build was needed; iOS remains deferred (ADR-025).
Preserve audit/replay/customer history during source/client rollback.
