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
T-015 remains IN_PROGRESS until `tools/codegen.sh` finishes and `dart analyze
lib` passes in `packages/api_client`. Generated output currently includes
unformatted code/Markdown whitespace and missing serializers for new models.
Swagger source now marks logout's `all` query optional and limits required
idempotency headers to mutations. Those two corrections also await regeneration
in the partially generated contract/clients.
API source whitespace checks pass; the API lint script is only a placeholder,
and no TypeScript formatter is configured.

These checks used installed Node 26.13.0, pnpm 9.12.0 (repository version) and
Flutter 3.47.8/Dart 3.13.7. The repository pins Node 20 and Flutter 3.35.7;
repeat final client generation/checks with that toolchain when available.
Then verify real PostgreSQL transactions and concurrent refresh/reuse; two-device
logout-all; first signup consent records; and held-role switch persistence.
Revised PostgreSQL OTP/rate-state verification awaits T-180; real provider login awaits Q-09.

## T-014 OTP and revised delivery baseline

`POST /api/v1/auth/otp/send` accepts `{mobile, channel?, appHash?}` with `Idempotency-Key` and a stable `X-Device-Id`. Normalize Indian mobile numbers; channel defaults to SMS. Responses expose only resend/expiry timing, never OTPs. Q-09 remains unresolved; disabled-provider mode fails safely, console delivery simulation is dev/test only and never logs OTPs. Production delivery requires the approved provider/DLT setup.

ADR-023 replaces the prior shared-state implementation with PostgreSQL. T-180 must preserve HMAC digest/salt and purpose-separated mobile/IP/device keys, constant-time comparison, five-minute expiry, five wrong-attempt limit, single-use consumption, 30-second resend cooldown, mobile/IP/device hourly budgets and escalating exhaustion lockout. PostgreSQL time and atomic locked transactions enforce limits across processes. Delivery reservation/activation must reject stale revisions, consume failed-send abuse budgets and fail closed without logging secrets. Concurrent-send/verify/restart integration cases run at G0.

This revision changes documentation only. Current source/manifests/environment examples and infra scripts still reflect the old baseline until T-180/T-182/T-184; do not claim the new runtime is implemented. Existing focused checks are historical evidence, not a migration pass. Use native PostgreSQL/PostGIS and persistent local upload configuration after reconciliation. Files use authenticated multipart uploads and authorized API streaming per LOCAL_FILE_STORAGE; no public private-document links.

API build/typecheck scripts exist; lint is currently a placeholder and T-184 must replace it. Per task run real build/typecheck, lint and endpoint smoke with focused critical-rule checks. At module completion run comprehensive real-DB integration/regression/end-to-end cases. See TASKS, PROMPTS and TEST_STRATEGY for gates and exact evidence requirements.

Approved SR-01–SR-06 applicability is defined in DELIVERY_SCOPE/ADR-024. Preserve security and shared iOS source/configuration; current mobile builds/runs/tests/releases are Android-only until Android production release, with iOS validation tracked separately in T-185 (ADR-025). Do not add deferred provider, telemetry, navigation or platform prerequisites. This revision changes documentation only.
