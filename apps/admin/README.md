# Admin — T-150 handoff

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
