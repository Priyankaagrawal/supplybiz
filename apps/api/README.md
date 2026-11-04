# Supply Biz API

## T-015 sessions (Dart generation pending)

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
