# Supply Biz API

## T-014 OTP foundation

`POST /api/v1/auth/otp/send` accepts `{mobile, channel?, appHash?}`. Both
`Idempotency-Key` and a stable `X-Device-Id` installation identifier are required.
Mobile accepts ten Indian digits beginning 6–9, optionally prefixed by `+91`.
Channel defaults to SMS; WhatsApp is explicitly selectable. `appHash`, if sent,
must be the 11-character Android SMS Retriever hash. Responses contain only
`{resendAfterSec:30, expiresInSec:300}`; errors use Problem Details.

Q-09 is unresolved. The user approved provider stubs for T-014:
`OTP_DELIVERY_MODE=disabled` is the default, returning safe 503 errors for both
real-provider adapters. `console` is an explicit development/test **simulation**;
it neither delivers messages nor prints, retains or exposes OTPs. Tests inject
a delivery sink in process. Console simulation is rejected in staging/production.
No credentials, DLT identifiers or third-party provider contract are invented.

For simulation, configure a reachable `REDIS_URL`, `NODE_ENV=development` (or
`test`), `OTP_DELIVERY_MODE=console` and a cryptographically random
`OTP_HMAC_PEPPER` of at least 32 characters through local secret configuration.
The pepper has no default and must not be logged or committed. Postgres remains
required for the existing global idempotency store. The API's existing dev
command is `pnpm --filter @supplybiz/api dev`; implementation did not start it.

OTP keys use purpose-separated HMACs of mobile/IP/device; values contain a
fresh random salt, HMAC digest, revision and state, never plaintext OTP/mobile.
Codes use Node CSPRNG and constant-time digest comparison. Redis scripts enforce
single-use consumption, a five-minute TTL, 30-second resend cooldown, rolling
five sends/mobile/hour and 20 sends/IP/hour. The approved configurable defaults
are five sends/device/hour, 30-second exponential send lockout per exhausted OTP,
and a one-hour cap. The escalation counter expires one hour after its latest
exhaustion. The fifth wrong attempt invalidates that OTP. Redis TIME is
authoritative; atomic Lua scripts coordinate replicas. Rate errors include
`Retry-After`. Socket IP is used; forwarded-IP headers are not trusted here.
Installation IDs are an additional abuse signal, not authentication.

Delivery is reserved as PENDING before the adapter call; verification cannot
succeed until activation. Provider failure discards only that revision, and
stale requests cannot activate/delete a newer OTP. Failed delivery still consumes
its send budget/cooldown to prevent unlimited retry abuse. Redis/provider errors
are sanitized and fail closed. Runtime Redis errors are never logged with command
arguments. The Redis namespace defaults to `OTP_REDIS_PREFIX=otp`.

T-015 consumes `OtpService.verify(mobile, code)` before issuing a real session.
Public `/auth/otp/verify`, user creation, consent and token issuance are deferred
to T-015. TC-003 is covered here only for OTP comparison/consumption, not tokens.

Dependency rationale: `redis` (MIT, resolved 5.12.1) is the official maintained
Node Redis client for architecture ADR-011 and atomic shared OTP/rate state.
It adds a backend runtime dependency; deployment size has not been measured.
Generated Dart clients use the existing Dio choice plus json_annotation
(BSD-3-Clause); json_serializable 6.9.5 and build_runner are development-only,
pinned for the workspace's Dart 3.9/analyzer compatibility. The codegen template
preserves workspace metadata, completes serializers and formats generated Dart.
API CI installs the pinned Flutter SDK for this required client generation.

Executed checks (Node 20 restored in `/tmp/node-v20.20.0-darwin-arm64/bin`;
pnpm 9.12.0 via Corepack, Flutter 3.35.7 in `/tmp/supplybiz-sdk/flutter/bin`):
```sh
pnpm --filter @supplybiz/api typecheck
pnpm --filter @supplybiz/api test -- --runTestsByPath src/modules/auth/otp.service.spec.ts src/modules/auth/otp.http.spec.ts src/modules/auth/otp.redis.spec.ts
pnpm --filter @supplybiz/api test:e2e -- --runTestsByPath test/app.e2e-spec.ts
tools/codegen.sh
# From packages/api_client:
dart analyze lib
```
The focused tests pass (11), the existing startup/idempotency e2e passes (4),
and the generated Dart library analyzes cleanly. Five real Redis tests are
opt-in and were not executed: no local Redis was listening on port 6379.
No API, worker or Redis service was started and left running.

Manual verification:
1. Run the focused service/HTTP tests above; confirm validation, both simulated
   channels, safe failure responses, HMAC comparison and Retry-After checks.
2. With an already-running **test** Redis, set `OTP_TEST_REDIS_URL` and run
   `pnpm --filter @supplybiz/api test -- --runTestsByPath src/modules/auth/otp.redis.spec.ts`.
   Confirm atomic sends/consumption, cooldown, hourly mobile/IP/device budgets,
   fifth-attempt invalidation, expiry, lockout escalation and stale-revision safety.
   Tests isolate and remove their own namespace; they never flush the database.
3. Start API with delivery disabled; valid send requests with both headers must
   return `503 OTP_PROVIDER_UNAVAILABLE` without OTPs/provider details in logs.
4. Enable console simulation with a local pepper and Redis; verify a send returns
   the two timing fields, an immediate resend with a fresh idempotency key gets
   429/Retry-After, and changing the number format cannot bypass mobile limits.
5. Verify staging/production rejects console configuration. Real delivery awaits
   Q-09 provider/DLT details; end-to-end login and tokens await T-015.
