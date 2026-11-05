# Supply Biz API

## T-015 sessions

Current status: READY_FOR_VERIFY for the user-approved development/test OTP scope
(2026-11-04). See **T-015 development/test verification handoff** below for current
native PostgreSQL evidence. Earlier check/codegen notes in this section are historical;
the Day 1 client audit supersedes the initial incomplete-generation notes.

Session source implements `POST /auth/otp/verify`, `/auth/refresh`, `/auth/logout`,
`GET /me`, `POST /me/roles`, and `PUT /me/active-role` under `/api/v1`.
Verify accepts `{mobile, code, device:{platform, appVersion?, osVersion?},
consent?:{termsVersion, privacyVersion}}`. New accounts require both consent
versions; server timestamps are recorded atomically with account creation.
New users have no held role and return `activeRole:null` until their first role
selection. Adding the first role selects it; switching requires a held role.

Access tokens are Ed25519 JWTs with a 15-minute lifetime. Configure
`AUTH_SIGNING_PRIVATE_KEY` as a PEM Ed25519 private key and `AUTH_SIGNING_KEY_ID`
as its public identifier through local secret configuration. Development/test
can use a process-local ephemeral key; persistent keys are required across
replicas/restarts and mandatory in staging/production. Rotate keys every 90 days;
retain still-valid public PEM keys in `AUTH_PREVIOUS_PUBLIC_KEYS` (JSON object
keyed by key ID). Public JWKS: `GET /api/v1/auth/.well-known/jwks.json`.

Refresh tokens contain 256 random bits, are stored only as SHA-256 hashes and
rotate with a sliding 30-day expiry. Consumed token records are retained for
family reuse detection. Reuse commits family revocation before returning 401
`REFRESH_REUSED`. Guards check live session/account state on every call.
`POST /auth/logout?all=true` revokes every session for the caller; default logout
revokes only the current family. All mutations require `Idempotency-Key`, but
these credential-sensitive endpoints deliberately bypass persistent response
caching. Retrying a consumed refresh token revokes its family, including when
the same idempotency key is reused. Clients must use single-flight refresh.

No persistent services were started. API typecheck and generated TypeScript
typecheck pass. The session/OTP service tests pass (17 tests); session/OTP HTTP
tests also pass (8 tests, using temporary Supertest loopback sockets outside the
sandbox). The production-key test explicitly isolates Jest's `NODE_ENV=test`
when verifying that production rejects an absent signing key.
The focused Swagger contract test also passes (1 test; 4 HTTP tests excluded
by its name filter), confirming optional logout scope and mutation-only headers.
The runtime specialist attempted API startup and received Prisma `P1001` because
PostgreSQL was unreachable at `localhost:5432`; no API process was left running.

Executed commands:
```sh
pnpm --filter @supplybiz/api typecheck
pnpm --filter @supplybiz/api test -- --runTestsByPath src/modules/auth/sessions.service.spec.ts src/modules/auth/otp.service.spec.ts
# HTTP suites passed in the focused four-file run; its service suite was
# subsequently corrected and passed in the two-file run above.
pnpm --filter @supplybiz/api test -- --runTestsByPath src/modules/auth/sessions.service.spec.ts src/modules/auth/sessions.http.spec.ts src/modules/auth/otp.service.spec.ts src/modules/auth/otp.http.spec.ts
pnpm --filter @supplybiz/api test -- --runTestsByPath src/modules/auth/sessions.http.spec.ts --testNamePattern=Swagger
pnpm --filter @supplybiz/api exec tsc --noEmit --skipLibCheck --strict --target es2021 --moduleResolution node ../../packages/ts-client/src/generated/openapi.ts
```

`tools/codegen.sh` regenerated OpenAPI, TypeScript types and Dart source, then
failed at Flutter SDK cache writes denied by the sandbox. Permission for the
outside-sandbox retry was declined without a stated reason. Dart serializers
and formatting remain incomplete; generated files were not edited manually.
The Day 1 audit has now completed `tools/codegen.sh` and `dart analyze lib` in `packages/api_client`; T-015 remains IN_PROGRESS for live session verification. Generated output currently includes
unformatted code/Markdown whitespace and missing serializers for new models.
Swagger source now marks logout's `all` query optional and limits required
idempotency headers to mutations. Those two corrections are now regenerated and checked by the Day 1 audit.
API source whitespace checks pass; T-184 now supplies real ESLint, which passes.

These checks used installed Node 26.13.0, pnpm 9.12.0 (repository version) and
Flutter 3.47.8/Dart 3.13.7. The repository pins Node 20 and Flutter 3.35.7;
repeat final client generation/checks with that toolchain when available.
Then verify real PostgreSQL transactions and concurrent refresh/reuse; two-device
logout-all; first signup consent records; and held-role switch persistence.
Revised PostgreSQL OTP/rate-state verification awaits T-180; real provider login awaits Q-09.

## T-014 OTP and revised delivery baseline

`POST /api/v1/auth/otp/send` accepts `{mobile, channel?, appHash?}` with `Idempotency-Key` and a stable `X-Device-Id`. Normalize Indian mobile numbers; channel defaults to SMS. Responses expose only resend/expiry timing, never OTPs. Q-09 remains unresolved; disabled-provider mode fails safely, console delivery simulation is dev/test only and never logs OTPs. Production delivery requires the approved provider/DLT setup.

T-180 implements PostgreSQL OTP/shared HTTP abuse storage, preserving HMAC digest/salt and purpose-separated mobile/IP/device keys, constant-time comparison, five-minute expiry, five wrong-attempt limit, single-use consumption, 30-second resend cooldown, mobile/IP/device hourly budgets and escalating exhaustion lockout. PostgreSQL time and advisory-locked transactions enforce limits across processes. Delivery reservation/activation rejects stale revisions and retains failed-send abuse budgets. All HTTP routes, including verify/refresh/logout, use durable route/IP rolling budgets; database failure returns sanitized 503 without a local-counter fallback. Expiry cleanup deletes at most 500 expired rows/minute per API process and emits a redacted warning on failure.

The direct Redis client, OTP scripts and Redis environment settings/readiness dependency are removed by T-180. Broader native setup, storage and CI reconciliation remain T-182/T-184. Use native PostgreSQL/PostGIS and persistent local upload configuration after reconciliation. Files use authenticated multipart uploads and authorized API streaming per LOCAL_FILE_STORAGE; no public private-document links.

API build/typecheck scripts exist; lint is currently a placeholder and T-184 must replace it. Per task run real build/typecheck, lint and endpoint smoke with focused critical-rule checks. At module completion run comprehensive real-DB integration/regression/end-to-end cases. See TASKS, PROMPTS and TEST_STRATEGY for gates and exact evidence requirements.

Approved SR-01–SR-06 applicability is defined in DELIVERY_SCOPE/ADR-024. Preserve security and shared iOS source/configuration; current mobile builds/runs/tests/releases are Android-only until Android production release, with iOS validation tracked separately in T-185 (ADR-025). Do not add deferred provider, telemetry, navigation or platform prerequisites. This revision changes documentation only.

## T-180 verification handoff

Executed: the commands below pass (20 focused tests, 4 skeleton smoke tests and 8 native PostgreSQL tests).
After the user supplied a dedicated database, all three repository migrations applied successfully to `supplybiz_test` on `localhost:5432`. The 8 previously skipped tests now pass against real PostgreSQL: concurrent sends/single-use verification, mobile/IP/device budgets, escalating lockout, stale revisions, client reconnect persistence, shared HTTP counters and cleanup. Credentials were supplied only to subprocess environments and are omitted here.
Policy tests use an in-memory clock/store; HTTP/skeleton smoke uses fake persistence and temporary loopback sockets.
At initial T-180 implementation the lint command was a placeholder; T-184 now supplies real ESLint (including floating/misused promise checks), and it passes.
Prisma client regeneration and schema validation pass. No API/database service was started or left running.

```sh
pnpm --filter @supplybiz/api typecheck
pnpm --filter @supplybiz/api build
DATABASE_URL=postgresql://localhost:5432/supplybiz pnpm --filter @supplybiz/api exec prisma validate --schema src/prisma/schema.prisma
pnpm --filter @supplybiz/api exec jest --runInBand --runTestsByPath src/modules/auth/postgres-otp.store.spec.ts src/modules/auth/otp.service.spec.ts src/modules/auth/otp.http.spec.ts src/modules/auth/otp.postgres.spec.ts
pnpm --filter @supplybiz/api exec jest --config test/jest-e2e.json --runInBand --runTestsByPath test/app.e2e-spec.ts
# Executed with DATABASE_URL and ABUSE_TEST_DATABASE_URL supplied securely:
pnpm --filter @supplybiz/api prisma:migrate:deploy
pnpm --filter @supplybiz/api exec jest --runInBand --runTestsByPath src/modules/auth/otp.postgres.spec.ts
```

Manual verification (not executed):
1. Confirm the migrated test database is selected through local secret configuration; all 8 native PostgreSQL tests above have passed. Rerun them if the database or migration changes.
2. With development/test console delivery simulation and a local random `OTP_HMAC_PEPPER`, run the API using `pnpm --filter @supplybiz/api dev`. Send a synthetic OTP request with device/idempotency headers; immediate resend must return 429/Retry-After. Console simulation never exposes/logs a code; correct-code verification is covered through the test provider capture, not an HTTP backdoor.
3. Submit five wrong codes, confirm exhaustion and resend lockout, then restart the API with the same DB/pepper and confirm that the lockout remains. Inspect stored keys/values for absence of plaintext mobile/IP/device/code.
4. Set a small HTTP budget in test config and exhaust one route across two API processes; expect a shared 429. Interrupt test DB connectivity and confirm safe 503 responses; restore connectivity and confirm expiry recovery. Stop test processes afterward.

Manual PASS, actual API-process restart/failure drills and G0 remain pending. Client disconnect/reconnect is tested; it is not an API-process restart drill. Real SMS/WhatsApp delivery is still blocked by Q-09; this storage task does not claim live provider login.

## Native baseline / CI (T-002, T-182, T-184)

See [Day 1 handoff](../../docs/05-ai-development/DAY1_HANDOFF.md) for commands, results and manual checks. `infra:check` now loads local environment values and verifies authenticated PostgreSQL/PostGIS queries and persistent private upload directories. Normal API startup excludes synthetic `/test/idempotency` routes; automated test mode retains them. Basic pino/error diagnostics remain; automatic telemetry SDK/exporter startup and obsolete cloud-storage settings are removed. The shared OpenTelemetry API library is retained.

`pnpm --filter @supplybiz/api lint` is real ESLint. ESLint 9, @eslint/js and typescript-eslint 8 are MIT-licensed development-only tooling implementing the existing coding standard; they add no shipped API/mobile runtime SDK. Task CI uses explicit T-ID selections and native DB smoke; comprehensive gates run only through the manual module workflow after required task/manual/prior-gate evidence exists. Unsupported/missing test selections fail closed. Admin availability is explicitly NOT_RUN until real T-150 scripts exist. Hosted GitHub jobs have not been executed by this local work.

## T-181 durable worker handoff

`OutboxDispatcherService.register(eventType, handler)` registers a real consumer before
`start()`. There are no active domain consumers yet; later feature tasks register them.
Unknown events remain retryable, then fail with an alert; they are never silently delivered.
Handlers receive `(event, tx)` and may return JSON completion counts. Write DB effects
through `tx` so effects and acknowledgement commit together. External deliveries are
at least once and must deduplicate by the stable `event.id`; never perform financial
updates outside the originating business transaction.

`schedule(jobType, businessDate, scopeId, dueAt, payload)` atomically persists a job and
its outbox event. Its unique `(job_type, business_date, scope_id)` preserves the first
payload/due time on replay. Dates are explicit `YYYY-MM-DD` business dates, due instants
are UTC; callers compute IST business policy server-side. Retry status/attempts/time/lease
and sanitized error live on the linked event; counts/finish time live on `job_runs`.
T-073 supplies subscription recurrence, eligibility, cutoff and the 22:30 generation alert.

Worker polls immediately at startup and every 5 seconds without overlapping ticks.
PostgreSQL time controls due/retry/lease eligibility; `SKIP LOCKED` claims one event at a
time with a 60-second token lease. Execution holds the row lock in a transaction with a
45-second timeout. Expired claims are reclaimed, handlers run at most five times, and
failures back off from 5 seconds exponentially. Errors persist only fixed codes; retry
warnings, `WORKER_DELIVERY_EXHAUSTED` and `WORKER_POLL_FAILED` are redacted operational
log alerts. Graceful shutdown drains the in-flight poll. No broker or new dependency.

Executed successfully against isolated native `supplybiz_worker_test`:
```sh
pnpm --filter @supplybiz/api prisma:generate
DATABASE_URL=postgresql://ankit@localhost:5432/supplybiz_worker_test pnpm --filter @supplybiz/api prisma:migrate:deploy
WORKER_TEST_DATABASE_URL=postgresql://ankit@localhost:5432/supplybiz_worker_test pnpm --filter @supplybiz/api exec jest --runInBand --runTestsByPath src/outbox/outbox-dispatcher.postgres.spec.ts
pnpm --filter @supplybiz/api lint
pnpm --filter @supplybiz/api typecheck
pnpm --filter @supplybiz/api build
node --test tools/checks.spec.mjs
```
Eight worker checks and four task-runner guards passed. No long-running API/worker was
started. Test clients reconnect and the dispatcher startup path is tested; actual OS-process
restart/kill is a pending manual drill. `tools/check-task.mjs T-181` now selects these tests,
using `WORKER_TEST_DATABASE_URL` or the dedicated `NATIVE_TEST_DATABASE_URL` from CI.
No HTTP contract change or API-client codegen. G0/manual PASS remain pending.

Manual verification (use only an isolated migrated test database):
1. Stop any old workers before applying migration `20261104090000_durable_worker`;
   regenerate Prisma and run `pnpm --filter @supplybiz/api dev:worker` against that DB.
2. Insert a synthetic due outbox event with an unregistered event type. Confirm it stays
   PENDING with `WORKER_HANDLER_MISSING`, increments attempts and waits until `available_at`.
3. Stop/restart the worker with the same DB. Confirm due work resumes, future rows wait,
   and a synthetic PENDING row with an expired lease is reclaimed. Run a second worker
   and confirm claims do not overlap (the focused test covers real-handler exclusion).
4. Let five attempts fail (or advance `available_at` in the test DB between attempts).
   Confirm FAILED plus `WORKER_DELIVERY_EXHAUSTED`; logs and `last_error` contain no payload.
5. Rerun the focused suite to inspect job-key deduplication, persisted counts and transactional
   rollback. Stop manual workers afterward. Rollback retains additive tables/columns and
   queued data with workers stopped; do not run the old acknowledge-only dispatcher.

## T-015 development/test verification handoff

User authorization (2026-11-04): proceed with T-015 using the existing development/test
OTP provider despite T-014/Q-09 being blocked. This exception permits session development
and verification; it does not resolve provider/DLT selection, enable production simulation,
claim real message delivery or pass G0. Mobile auth/manual Android UI belongs to T-016.

Login now reloads account status/roles after acquiring its user lock, preventing a stale
pre-lock snapshot from issuing a session for a newly blocked account or with old roles.
No HTTP contract, schema, client generation or provider behavior changed for T-015.
The new `sessions.postgres.spec.ts` boots the actual AppModule with PostgreSQL and shared
Ed25519 signing keys across independent API instances. Only delivery and Nest logging are
overridden: existing ConsoleOtpProvider captures random OTPs in test memory, with no code
logging, fixed code or HTTP backdoor. The suite closes/reboots one instance to verify durable
role/session state; an OS-process restart remains manual. Refresh reuse revokes its family
per AUTH_SECURITY §2.2 and TC-009; logout-all revokes every device's sessions.

Executed successfully (isolated native `supplybiz_sessions_test`, no tests skipped):
```sh
DATABASE_URL=postgresql://ankit@localhost:5432/supplybiz_sessions_test pnpm --filter @supplybiz/api prisma:migrate:deploy
SESSIONS_TEST_DATABASE_URL=postgresql://ankit@localhost:5432/supplybiz_sessions_test pnpm --filter @supplybiz/api exec jest --runInBand --runTestsByPath src/modules/auth/sessions.service.spec.ts src/modules/auth/sessions.http.spec.ts src/modules/auth/sessions.postgres.spec.ts
pnpm --filter @supplybiz/api lint
pnpm --filter @supplybiz/api typecheck
pnpm --filter @supplybiz/api build
node --test tools/checks.spec.mjs
```
24 session checks (8 native HTTP/DB, 5 HTTP boundary, 11 service/token checks) and 4 runner
guards pass. Checks cover TC-008/009/010/013, single-use OTP, consent timestamps/versions,
hashed refresh storage, role/account rechecks, replay, concurrent refresh and logout,
current/all-device revocation, expired sessions, blocked accounts and forged ownership.
Test fixtures/clients and the disposable private directory under
`~/.local/share/supplybiz/test-uploads` are cleaned afterward. No persistent API process
was started. T-015 is registered in `tools/check-task.mjs`; it uses SESSIONS_TEST_DATABASE_URL
or falls back to CI's dedicated NATIVE_TEST_DATABASE_URL. The entire runner was not rerun;
its selected session checks and the guard checks above were run directly.

Manual verification (pending; use this native harness in a debugger for code capture and
DB inspection, since the normal console simulation intentionally exposes no OTP):
1. Configure a migrated database ending in `_test` as SESSIONS_TEST_DATABASE_URL. Run the
   native suite above; set a breakpoint after signup in TC-013 before automatic cleanup.
   Inspect consent versions/timestamps, hashed refresh storage and the initial empty roles.
2. Step through TC-008: select Customer, add/switch to Vendor, then confirm `/me` and refresh
   preserve Vendor on the other/rebooted API instance without another login.
3. Step through TC-009: refresh once, confirm the prior access token fails, then replay the
   old refresh token and confirm REFRESH_REUSED and committed family revocation.
4. Step through TC-010: current logout leaves the second device active; logout-all makes
   its next `/me` and refresh fail. Confirm the concurrent-logout case leaves no active session.
5. Resume through cleanup. Record manual PASS separately. Real SMS/WhatsApp delivery,
   Android login UI, OS-process restart drills and G0 are not claimed by these test results.

## T-017 app configuration handoff (2026-11-04)

`GET /api/v1/config` publicly reads only the `app_config` key `mobile`, validates
`{minVersionAndroid: "0.1.0", flags: {}}`, and caches the response for 60 seconds.
Other config keys never enter this response. Versions use three numeric components
(up to six digits each, no leading zeroes, prerelease or build suffixes). Android
requests declaring `X-Platform: android` must supply `X-App-Version`; older versions
receive Problem Details `426 UPGRADE_REQUIRED`, malformed/missing versions receive
400. Config/version/health GETs remain accessible. Non-mobile callers retain their
existing behavior; version metadata never replaces authentication or authorization.
Missing/invalid policy or DB failures return a redacted 503. There is no public
config mutation. Admin edits and their authorization/audit remain T-158/T-152.
The additive migration seeds the current `0.1.0` minimum with no enabled flags.

Executed from the repository root (native PostgreSQL; four focused checks passed,
including three HTTP/real-DB smoke checks; the test restores the original policy):
```sh
pnpm --filter @supplybiz/api prisma:generate
DATABASE_URL=postgresql://ankit@localhost:5432/supplybiz_sessions_test pnpm --filter @supplybiz/api prisma:migrate:deploy
CONFIG_TEST_DATABASE_URL=postgresql://ankit@localhost:5432/supplybiz_sessions_test pnpm --filter @supplybiz/api exec jest --runInBand --runTestsByPath src/modules/content/app-config.spec.ts
pnpm --filter @supplybiz/api typecheck
pnpm --filter @supplybiz/api lint
pnpm --filter @supplybiz/api build
JAVA_HOME=/Library/Java/JavaVirtualMachines/openjdk-21.jdk/Contents/Home PATH=/Users/ankit/.pub-cache/bin:$PATH tools/codegen.sh
pnpm --filter @supplybiz/api exec tsc --noEmit --skipLibCheck --target ES2022 --module ESNext ../../packages/ts-client/src/generated/openapi.ts
node --check tools/check-task.mjs
node --test tools/checks.spec.mjs
git diff --check
```
Generation succeeded after allowing SDK-cache access; no dependency upgrades or
hand edits to generated clients. Initial fixture type errors and mobile retry/test
failures were corrected before the recorded passing checks. Generated TypeScript contract standalone typecheck passed using the API workspace compiler
(the root has no tsc executable). Task-runner guards: 4 passed. T-017 is registered for API/mobile CI; the complete task runner, hosted
CI and module gates were NOT_RUN. No API service was left running. The dedicated
test DB was migrated; other databases still require migration before normal use.
See the mobile README for Android evidence and the manual verification procedure.

## T-020 scope clarification (2026-11-04)

Status: **TODO**; the user removed document malware scanning and automated
pre-persistence Aadhaar validation from T-020 (ADR-027), clearing the prior
prerequisite blocker. Neither a scanner nor an automated masking validator is
required for this task. The masked-Aadhaar-only storage rule remains; uploaders
must supply masked documents.

Retain file type/magic-byte/size/pixel/decode validation, image EXIF stripping,
private local storage, idempotency, authorized reads and admin KYC access audit.
PDFs remain attachment-only. No application implementation or task verification
is claimed by this documentation change.

## T-020 private media handoff (2026-11-04)

Status: **READY_FOR_VERIFY** under ADR-027. `POST /api/v1/media` streams one
multipart `file` plus `purpose` into private exclusive staging, enforces the
configured byte limit (inclusive), validates JPEG/PNG/PDF signatures and decode,
bounds image pixels/time, strips image EXIF and atomically publishes a private
file with durable READY metadata. Files are 0600; directories are checked 0700
without symlinks. Invalid/interrupted uploads and failed metadata transactions
are compensated. Uploads have a 30-second receive deadline. Each upload scans
at most 100 entries per directory for staging/unreferenced files older than
24 hours; referenced files are never removed by this cleanup.

Owner/key advisory locking prevents concurrent duplicate uploads. Identical
original bytes/purpose/MIME return the same mediaId after restart; mismatches
return 422. Mapping is retained with media metadata. Authenticated owner reads
use `/media/{id}/content`; another owner gets 404. Authorized `kyc.documents`
admins use `/admin/media/{id}/content` for KYC_DOC/SHOP_PHOTO, with an append-only
DB access event before streaming. Responses are no-store/nosniff and use safe
attachment names. PDFs never render inline. No static directory is exposed.
`MediaService.requireOwnedReady` supplies the attachment ownership/purpose
check for later vendor/catalog tasks. Business attachments/discovery/UI are
implemented in those owning tasks; an unattached ID grants no public access.
T-020 omits malware scanning and automated masking checks per ADR-027; supplied
Aadhaar must already be masked. No provider verification is claimed.

Additive migrations: `20261104040000_media` and
`20261104040100_media_audit_immutable`. Apply both before starting the API on
another database. Rollback: revert application routes first and retain private
files/metadata/audit history; do not drop data or bypass retention policy.

Executed checks (PASS; native checks required sandbox escalation):
```sh
pnpm --filter @supplybiz/api prisma:generate
DATABASE_URL=postgresql://ankit@localhost:5432/supplybiz_sessions_test pnpm --filter @supplybiz/api prisma:migrate:deploy
MEDIA_TEST_DATABASE_URL=postgresql://ankit@localhost:5432/supplybiz_sessions_test pnpm --filter @supplybiz/api exec jest --runInBand --runTestsByPath src/modules/media/media.postgres.spec.ts
pnpm --filter @supplybiz/api lint
pnpm --filter @supplybiz/api typecheck
pnpm --filter @supplybiz/api build
pnpm --filter @supplybiz/api exec prisma validate --schema src/prisma/schema.prisma
pnpm --filter @supplybiz/api exec tsc --noEmit --skipLibCheck --target ES2022 --moduleResolution node ../../packages/ts-client/src/generated/openapi.ts
JAVA_HOME=/Library/Java/JavaVirtualMachines/openjdk-21.jdk/Contents/Home PATH=/Users/ankit/.pub-cache/bin:$PATH tools/codegen.sh
(cd packages/api_client && /Users/ankit/.pub-cache/bin/fvm dart analyze lib)
node --test tools/checks.spec.mjs
git diff --check
```
9 native HTTP/DB/files checks pass: image/metadata/read, restart/concurrent
replay, invalid inputs/limits, inclusive byte boundary, auth/multipart fields,
truncated stream cleanup, PDF/admin authorization/immutable access audit,
transaction rollback/file+directory symlink denial, and reference-safe cleanup.
The fixture starts real Nest HTTP servers, uses real sessions/PostgreSQL/private
files, and closes servers/removes its disposable files. No new service remains
running. The first boundary/config test setup and multipart part-count handling
were corrected before the final passing run. Codegen initially required SDK
cache access; the escalated full rerun passed. The test database also received
its previously pending T-150 migration; other databases were not migrated.

Dependency rationale: pinned busboy 1.6.0 (MIT; existing transitive dependency)
provides bounded streaming multipart parsing; pinned sharp 0.35.5 (Apache-2.0;
already present via Next.js) provides maintained native image decode/re-encode
with pixel/time bounds. Pinned pdf-lib 1.17.1 (MIT) adds PDF structural parsing
and its JS font/deflate dependencies; it adds no service/browser runtime and
avoids accepting a PDF from magic bytes alone. Its older release cadence is a
maintenance tradeoff; PDF parsing is size-bounded and delivery remains
attachment-only. @types/busboy 1.5.4 is development-only. Lockfile changes contain
no unrelated upgrades.

Manual verification (suggested; NOT yet executed):
1. Migrate your local DB, configure private persistent UPLOAD_ROOT, then start
   `pnpm --filter @supplybiz/api dev`. Use an existing local test session; live
   OTP is still subject to T-014/Q-09. POST multipart file/purpose with a bearer
   token and Idempotency-Key; confirm only mediaId/READY are returned.
2. GET `/api/v1/media/{id}/content` as owner; inspect the image/download and
   no-store/nosniff headers. Repeat as another user and unauthenticated: 404/401.
3. Repeat identical upload/key, including after restarting the API: same ID,
   one metadata/file record. Change content/purpose with that key: 422.
4. Try malformed/forged MIME, >5 MB, excessive pixels, extra fields and an
   interrupted upload: no READY metadata or staging leftovers for denied input.
5. Upload a synthetic KYC PDF. OPS/SUPER_ADMIN reads via the admin route download
   it and append an access row; SUPPORT/FINANCE are denied. Use no real identity
   documents for verification.

NOT_RUN: manual PASS, actual full-disk/device-abort drills, business attachment
and UI/discovery integration, complete task runner/hosted CI and G1 module suite.
This API-only change has no Android UI build requirement; iOS remains deferred.
The existing TASKS/LOCAL_FILE_STORAGE TC-508 reference names an upload case,
while TEST_CASES TC-508 currently names UI-kit interactions; evidence here is
explicitly TC-503 and the named security cases, not a TC-508 UI-suite pass.


## T-021 vendor profile/onboarding handoff (2026-11-04)

READY_FOR_VERIFY; FR-010/011/016, US-010/011, API portions of TC-020–022.
New source: `src/modules/vendors/{vendors.controller,vendors.dto,vendors.service,vendors.postgres.spec}.ts`,
additive `20261104120000_vendor_onboarding` migration/schema and AppModule wiring;
OpenAPI/TS/Dart clients regenerated; focused task runner registered. No new dependency.

`GET /api/v1/vendor/onboarding/categories` lists enabled supply categories (MILK first).
`POST /api/v1/vendor/onboarding/category` with `{ "categoryId": "<UUID>" }` creates an owned
profile/default settings and returns next step 2. `PUT /api/v1/vendor/onboarding/business`
requires businessName (2–80), addressLine (5–200), city/state, six-digit pincode and numeric
latitude/longitude; GSTIN is optional/validated, shopPhotoMediaId optional (null clears).
GET `/api/v1/vendor/onboarding` resumes step/data; 404 means category not yet selected.
Held + active VENDOR required, with live session and account checks. Each mutation requires
Idempotency-Key (1–120 characters); profile and owner-scoped 24-hour replay commit together.
Changing endpoint/payload under the key returns 422. No plan/trial/KYC approval is assigned.
Reviewed-business editing is reserved for T-106, with onboarding returning 409 to avoid
bypassing its re-verification workflow. Settings are returned within the profile; the
separate settings editor is outside T-021. Onboarding saves completed steps, not each keystroke.

Executed successfully from repository root (native PostgreSQL 17, test DB only):
```sh
pnpm --filter @supplybiz/api prisma:generate
DATABASE_URL=postgresql://ankit@localhost:5432/supplybiz_sessions_test pnpm --filter @supplybiz/api prisma:migrate:deploy
pnpm --filter @supplybiz/api exec prisma validate --schema src/prisma/schema.prisma
NATIVE_TEST_DATABASE_URL=postgresql://ankit@localhost:5432/supplybiz_sessions_test ABUSE_TEST_DATABASE_URL=postgresql://ankit@localhost:5432/supplybiz_sessions_test node tools/check-task.mjs T-021
PATH=/Users/ankit/.pub-cache/bin:$PATH tools/codegen.sh
pnpm --filter @supplybiz/api exec tsc --noEmit --strict --skipLibCheck --target ES2022 --moduleResolution node ../../packages/ts-client/src/generated/openapi.ts
node --test tools/checks.spec.mjs
```
Also executed in `packages/api_client`: `/Users/ankit/.pub-cache/bin/fvm dart analyze`.
Results: real API lint/typecheck/build PASS; 8 focused HTTP→DB checks PASS (concurrent
retries, app recreation/replay, field validation, PostGIS coordinates, role/owner isolation,
real upload→profile→authorized byte display, attachment rejection, transaction rollback,
reviewed-field/account blocking); 2 native readiness/provider-fail-closed smoke checks PASS;
4 task-runner guards PASS; schema validation, complete codegen, TS compilation and Dart
analysis PASS. Earlier fixture failures (development signing-key renewal on app recreation,
invalid quarantine metadata unsupported by the media schema) were corrected; final checks
pass. Initial sandbox DB/Flutter-cache denials were rerun with approval. Only the isolated
`_test` DB received migration/PostGIS; the normal development DB was not migrated.
All started check apps closed and fixture users/rows/upload files were removed.

Manual verification (suggested; NOT_RUN):
1. Apply the migration to your intended local dev DB with `pnpm --filter @supplybiz/api prisma:migrate:deploy`,
   then start `pnpm --filter @supplybiz/api dev`. Use the existing development/test login
   harness or session to hold/select VENDOR; Q-09 live SMS remains unavailable.
2. List categories, save one with a fresh key, GET onboarding: verify step 2/defaults.
3. Save business (e.g. Synthetic Dairy, 123 Test Road, Test City/Test State, 560001,
   numeric 12.97/77.59); try short name, malformed GSTIN/pincode and out-of-range coordinates:
   invalid requests must return 400 without advancing progress; valid save returns step 3.
4. Upload SHOP_PHOTO via `/media`, save its ID, GET onboarding and `/media/{id}/content`;
   confirm display. Re-login/restart API and confirm persisted fields/step. Use refresh or
   re-login after restart when development signing keys are ephemeral.
5. Retry same request/key (same response), change its payload (422), then use a different
   vendor/customer session: no profile/photo leakage and customer access denied (403).

Pending: task-specific manual PASS, T-024 app onboarding UI/restart and Android accessibility,
T-022 KYC, T-106 reviewed settings, G0/G1 comprehensive gates (NOT_RUN). This API-only task
ran no mobile platform builds; iOS validation remains deferred to T-185.
Migration rollback: stop use of the new endpoints and roll application code back while
retaining the additive tables/data; do not drop populated profiles/settings or PostGIS.

## T-022 manual KYC handoff (2026-11-05)

Local API slice: validated atomic submission at `POST /api/v1/vendor/kyc`, owned
latest revision at `GET /api/v1/vendor/kyc`, durable decision notices at
`GET /api/v1/vendor/kyc/notices`; OPS/SUPER_ADMIN pending queue/detail/decision at
`GET /api/v1/admin/kyc`, `GET /api/v1/admin/kyc/{submissionId}` and
`POST /api/v1/admin/kyc/{submissionId}/decision`. See API_SPECIFICATION T-022
for request fields, cursor, state conflicts and replay behavior. The API-client
source includes all endpoints; mobile onboarding and admin review UI belong to
T-024/T-151. The existing T-020 private content stream remains the document reader.

Supply only already-masked Aadhaar; automated masking checks remain excluded under
ADR-027. No full Aadhaar number input exists. PAN/account numbers are encrypted
with AES-256-GCM; responses/replay/audits never contain their full values. Use a
persistent, independently generated 32-byte `FIELD_ENCRYPTION_KEY` (64 hex chars)
in the local API environment; do not commit it or reuse the TOTP key. Development/
test permits this key per ENVIRONMENT_SETUP. KYC mutations in staging/production
return 503 until KMS envelope encryption is implemented/configured. This is a local
handoff, not production encryption readiness. Provider checks always remain NOT_RUN;
MANUAL_REVIEW is the verification method even after a manual VERIFIED decision.

Review status, reason/reviewer/time, vendor status, redacted append-only audit
(before/after and socket IP) and a durable owned in-app notice commit together.
Reason is retained on the immutable reviewed revision and linked by audit entity ID;
free text stays outside the general audit snapshot. Rejected cases can resubmit a
new revision; pending/approved cases cannot submit again through onboarding.
Notifications here mean persisted API-readable in-app notices. Push/SMS delivery
is NOT_RUN (T-032); no outbox event is silently discarded or marked delivered.
Retention/deletion remains Q-20. No plan/visibility/expiry policy was invented;
discovery enforcement is T-041. Do not interpret local task checks as a G0/G1 pass.

Executed successfully (repository root unless a directory is stated):
```sh
pnpm --filter @supplybiz/api prisma:generate
DATABASE_URL=postgresql://ankit@localhost:5432/supplybiz_sessions_test pnpm --filter @supplybiz/api prisma:migrate:deploy
NATIVE_TEST_DATABASE_URL=postgresql://ankit@localhost:5432/supplybiz_sessions_test ABUSE_TEST_DATABASE_URL=postgresql://ankit@localhost:5432/supplybiz_sessions_test node tools/check-task.mjs T-022
node --test tools/checks.spec.mjs
pnpm --filter @supplybiz/api exec prisma validate --schema src/prisma/schema.prisma
JAVA_HOME=/Library/Java/JavaVirtualMachines/openjdk-21.jdk/Contents/Home PATH=/Users/ankit/.pub-cache/bin:$PATH tools/codegen.sh
pnpm --filter @supplybiz/api exec tsc --noEmit --skipLibCheck --target ES2022 --module NodeNext --moduleResolution NodeNext ../../packages/ts-client/src/generated/openapi.ts
pnpm --filter @supplybiz/admin typecheck
```
Also executed from `packages/api_client`: `/Users/ankit/.pub-cache/bin/fvm dart analyze lib`.
Results: 9 focused real HTTP/PostgreSQL/upload checks, 2 native runtime smoke checks
and 4 runner guards PASS; API lint/typecheck/build, schema, TS/Dart generation and
client analysis/compilation and admin consumer typecheck PASS. The first expanded
suite exposed a stale synthetic token after API restart; reissuing it fixed the
fixture. A final audit assertion also caught a missing socket-IP argument in the
decision controller; that connection is fixed and the final nine checks pass. Earlier sandbox migration/codegen attempts
failed; reruns with approved access succeeded. Only the dedicated test DB migration
was applied; application/dev DB migration was NOT_RUN. Synthetic immutable test
records remain in that test DB; temporary private upload folders were removed.
No newly started service/check process remains running.

Manual verification (suggested, NOT executed; use synthetic details):
1. Configure the local encryption key, apply migrations to the intended local dev
   DB and start the API with `pnpm --filter @supplybiz/api dev`. Use existing
   T-015/T-150 development login/provisioning instructions, complete category/
   business onboarding and upload three distinct already-masked KYC attachments.
2. Submit valid bank/PAN/document data with a fresh Idempotency-Key. Verify
   MANUAL_REVIEW/NOT_RUN; retry across API restart with that key and verify the
   same revision; mismatch confirmation/IFSC must fail without saving a case.
3. As OPS, load the pending queue and private document streams. Reject with a
   reason, check vendor status/reason/notice, and resubmit a fresh revision.
4. As SUPER_ADMIN, approve the new revision; verify VERIFIED, MANUAL_REVIEW and
   NOT_RUN, exactly one notice, and before/after/actor/IP in the audit viewer.
   SUPPORT/FINANCE decisions and missing CSRF must be denied.

Manual PASS, T-024/T-151 screens/accessibility, live notifications, staging/production
KMS and G0/G1 remain pending; no mobile native checks were needed for this API task.
iOS testing remains deferred under ADR-025. Migration is additive: rollback API
code while preserving review/audit data; do not drop evidence tables to roll back.
