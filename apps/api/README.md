# Supply Biz API

## T-032 notification infrastructure handoff (2026-11-11): READY_FOR_VERIFY

Implemented role/owner-scoped operational inbox, persisted read/read-all/clear-all,
90-day visibility/retention, category push preferences and current-session Android
token registration. All mutations require Idempotency-Key; tokens are never echoed
or copied to jobs/logs. Omission/null of pushToken with pushEnabled=false removes
the token, supporting generated-client serialization. Old-key replay cannot restore
a rotated token. Logout/current-family and logout-all clear affected device tokens.

KYC decisions atomically preserve their existing notice/audit/state and add a
mandatory generic inbox item plus per-device outbox jobs. The additive migration
copies actual last-90-day KYC notice history without retrospective pushes; it does
not delete legacy KYC records or resolve their separate Q-20 retention policy.
Server templates contain no KYC/bank/name/address details. Optional category flags
control pushes, while inbox items persist; KYC/security bypass those flags but
respect device permission. Offers/campaigns remain excluded under approved SR-05.

FCM uses built-in Node crypto/fetch and fixed Google HTTPS endpoints, with scoped
RS256 OAuth assertions, bounded HTTP timeouts, token-cache refresh and no new SDK
dependency. FCM_ENABLED defaults false (unavailable, never simulated success).
Enable it only with private FCM_SERVICE_ACCOUNT_JSON and a registered Android device.
Provider failures use existing leased/bounded worker retries and exhaustion alerts;
only exact FCM UNREGISTERED clears the matching token. A concurrent replacement
token is preserved. Auth/user locks are not held during external HTTP, so slow
pushes cannot delay logout. Already in-flight/accepted messages cannot be recalled.
Inbox/job creation deduplicates by source key; external delivery is at least once,
using stable notificationId plus Android tag. T-033 must deduplicate by that ID and
confirm role changes on tap. No live Google message was sent by these checks.

The worker registers NOTIFICATION_PUSH; it also prunes expired inbox rows hourly
with bounded catch-up batches. Expired rows are hidden immediately. Cleared,
expired, blocked, signed-out, rotated-token or permission-disabled jobs are skipped.
The internal dispatchPendingBatch optional event-ID selector uses the same lease/
retry logic and lets focused checks operate only their own jobs, leaving other
queued events untouched. No public notification creation/retry endpoint was added.

Final evidence: 13 native notification/worker/session checks and 5 simulated FCM
adapter checks pass, including slow-provider/logout and token-rotation races.
Nine KYC native regression cases and 2 readiness/disabled-OTP runtime smoke cases
pass; the optional production Next.js KYC smoke was skipped (admin UI unchanged).
Four task-runner guards, API lint/typecheck/build/schema validation, generated TS
compile and generated Dart analysis pass. Clients/serializers were regenerated.
The migration was applied only to existing supplybiz_service_area_test. A separate
test-DB provisioning attempt could not proceed without local admin credentials;
no new database was created, and helper edits were reverted. Scoped job checks
used the existing isolated DB. No API/worker service was left running by this task.

Executed commands from apps/api (connection secrets loaded privately from ignored
.env; DATABASE_URL overridden to supplybiz_service_area_test for migrations;
NOTIFICATIONS_TEST_DATABASE_URL/KYC_TEST_DATABASE_URL/NATIVE_TEST_DATABASE_URL
point to that isolated DB; NODE_ENV=test, OTP_DELIVERY_MODE=disabled, FCM_ENABLED=false):
```powershell
.\node_modules\.bin\prisma.cmd generate --schema src/prisma/schema.prisma
.\node_modules\.bin\prisma.cmd migrate deploy --schema src/prisma/schema.prisma
.\node_modules\.bin\prisma.cmd validate --schema src/prisma/schema.prisma
.\node_modules\.bin\tsc.cmd --noEmit
.\node_modules\.bin\eslint.cmd src test scripts jest.config.ts --max-warnings=0
.\node_modules\.bin\tsc.cmd -p tsconfig.build.json
.\node_modules\.bin\jest.cmd --silent --runInBand --runTestsByPath src/modules/notifications/fcm.service.spec.ts
.\node_modules\.bin\jest.cmd --silent --runInBand --testTimeout=60000 --runTestsByPath src/modules/notifications/notifications.postgres.spec.ts src/modules/kyc/kyc.postgres.spec.ts
.\node_modules\.bin\jest.cmd --silent --runInBand --testTimeout=60000 --runTestsByPath src/modules/notifications/fcm.service.spec.ts src/modules/notifications/notifications.postgres.spec.ts
.\node_modules\.bin\jest.cmd --config test/jest-e2e.json --runInBand --testTimeout=60000 --runTestsByPath test/native-runtime.e2e-spec.ts
.\node_modules\.bin\ts-node.cmd scripts/generate-openapi.ts
```
At repository root, executed the same openapi-typescript/openapi-generator-cli,
normalizer, Dart formatter and generated TS compile commands documented below for
T-026, plus `node --test tools/checks.spec.mjs`. From packages/api_client:
```powershell
& 'C:\flutter\bin\cache\dart-sdk\bin\dart.exe' run build_runner build '--build-filter=lib/src/model/*.g.dart'
& 'C:\flutter\bin\cache\dart-sdk\bin\dart.exe' analyze
```
The full task runner was not invoked; its focused T-032 commands are registered.
Native checks ran with permission for existing private Windows storage/ACL handling.
The KYC fixture now initializes ACLs on its newly created temporary test directory;
application storage validation was preserved. No dependencies/checks were disabled.

Manual verification (suggested, not manual PASS):
1. Apply migrations to your selected local DB before restarting API/worker. Sign in
   on Android and PUT /api/v1/me/devices/current with its token/pushEnabled and a new
   key. Check the response has deviceId/permission only, and another account cannot
   claim the registered token. With FCM disabled, inbox still works; push jobs must
   never be reported as SENT.
2. Review a synthetic vendor KYC submission through the existing authorized admin
   workflow. GET /api/v1/notifications?role=VENDOR&category=SYSTEM; verify generic
   KYC text, persisted read/all-read/clear and isolation from another account/role.
3. PUT /api/v1/me/notification-prefs with all four booleans. Verify optional pushes
   are suppressed while KYC/security bypass category preferences. Real order/POS/
   subscription producer integration is checked with their owning tasks, not faked.
4. Configure live FCM privately, register your permitted Android device, produce a
   fresh synthetic KYC decision and check actual delivery. Rotate/unregister/logout
   and confirm later queued attempts are skipped. Check failure/retry/exhaustion
   records without exposing tokens. Real FCM/Android delivery is NOT_RUN here.

Remaining: T-033 mobile inbox/push handling; T-052 order fan-out and owning-domain
producers; actual STOCK_LOW consumption must wait for T-084/T-103 server entitlement
rules (no fabricated BUSINESS plans or ungated stock pushes). Existing STOCK_LOW
jobs retain their explicit missing-handler state. Full FR-101/TC-103 coverage,
manual PASS and G0/G1/G2 gates remain pending. No Android/iOS builds were needed for
this API-only task; iOS remains deferred. No separate RUN or DONE finalization.

Protocol references: [FCM HTTP v1](https://firebase.google.com/docs/cloud-messaging/send/v1-api),
[service-account OAuth](https://developers.google.com/identity/protocols/oauth2/service-account),
[FCM error codes](https://firebase.google.com/docs/cloud-messaging/error-codes).

## T-070 ledger foundation handoff (2026-11-11): READY_FOR_VERIFY

T-005 DONE / T-028 READY_FOR_VERIFY permit this foundation under TASKS §10.
Day-4 plan policy is now approved in ADR-029 (Q-04 resolved); implement T-084 then
T-103/T-156 in dependency order rather than skipping that workstream.
This implementation adds internal transaction services, not ungated public
financial HTTP routes. No plan, payment provider or entitlement policy is invented.
Future financial endpoints must apply approved entitlements and derive actor/vendor
from the session before calling these methods. Order/POS/payment/claim state
transitions and actual UI flows remain owning tasks, including T-049/T-071/T-079/
T-081/T-082; no financial source transition is simulated as implemented here.

Implemented: append-only ledger entries; positive BIGINT paise; vendor/customer scope;
source-reference uniqueness; permanent opening/reversal request identity; immutable
opposite-entry reversal; an insert trigger updating balance and redacted audit
atomically; database UPDATE/DELETE/TRUNCATE rejection. Internal serialized amounts
are decimal strings to preserve values above JavaScript safe integers. Default
entry business dates use PostgreSQL's Asia/Kolkata clock. No history is overwritten.

The worker registers LEDGER_RECONCILE, schedules a daily 00:15 IST cumulative check
from the DB clock, catches the most recent due check on startup and uses existing
durable leases/retries. Batches are bounded to 100 customers, with transactional
continuations scoped to the root run and cursor. Single-statement snapshots compare entry sums and balances without
false alerts from concurrent commits. Drift records and audits are immutable;
alerts contain a fixed code, never notes or account details. No automatic repair.
`ledger:reconcile` processes the latest scheduled run and its continuations; it
does not create a second daily run if that run already completed.

The operator configuration blocker is resolved. The application role remains
non-superuser/NOCREATEROLE. The additive migration and separate ownership/grants
were applied only to `supplybiz_service_area_test`; the configured app DB was not
migrated or granted here. The runtime can SELECT/INSERT entries/findings and SELECT
balances. Unsafe table/column write privileges fail closed with
LEDGER_GRANTS_NOT_APPLIED; runtime ownership or administrator privileges are not needed.

POSTGRES_ADMIN_URL is in ignored `.env.ledger-operator.local`, separate from the
normal API `.env`. Normal API/worker startup must never load the operator file.
For another environment, copy `.env.ledger-operator.example` to that ignored file
and configure it privately. The operator uses `tools/ledger-grants.sql` with an existing runtime
role and a dedicated non-login owner. It transfers only the new ledger tables/
trigger functions, grants runtime SELECT/INSERT on entries/findings and SELECT on
balances, and rejects unsafe table/column permissions or owner-role membership.
Future migrations changing these owned objects need operator/migration ownership,
not elevated API credentials. The SQL script applied and reapplied successfully
to the isolated test DB without elevating the runtime login. No credential values
were printed, committed or used by the runtime-only CLI smoke.

Executed checks (apps/api, native URL privately loaded from ignored .env and
overridden to supplybiz_service_area_test):
```powershell
.\node_modules\.bin\prisma.cmd generate --schema src/prisma/schema.prisma
.\node_modules\.bin\prisma.cmd migrate deploy --schema src/prisma/schema.prisma
.\node_modules\.bin\prisma.cmd validate --schema src/prisma/schema.prisma
.\node_modules\.bin\tsc.cmd --noEmit
.\node_modules\.bin\eslint.cmd src test scripts jest.config.ts --max-warnings=0
.\node_modules\.bin\tsc.cmd -p tsconfig.build.json
.\node_modules\.bin\tsc.cmd --noEmit --strict --esModuleInterop --experimentalDecorators --emitDecoratorMetadata --target ES2021 --module commonjs --moduleResolution node --skipLibCheck scripts/reconcile-ledger.ts
.\node_modules\.bin\jest.cmd --runInBand --runTestsByPath src/modules/ledger/ledger.service.spec.ts
.\node_modules\.bin\jest.cmd --runInBand --testTimeout=60000 --runTestsByPath src/modules/ledger/ledger.service.spec.ts src/modules/ledger/ledger.postgres.spec.ts
.\node_modules\.bin\jest.cmd --config test/jest-e2e.json --runInBand --testTimeout=60000 --runTestsByPath test/native-runtime.e2e-spec.ts
.\node_modules\.bin\ts-node.cmd scripts/reconcile-ledger.ts
```
Final focused checks pass: 6 boundary/IST-clock unit and 11 real PostgreSQL cases.
Native cases cover source replay/concurrency/reconnect, atomic source/entry/balance/
audit rollback, precision above JS safe integers, int64 overflow rollback, permanent
opening identity, sequential/concurrent reversal, tenant/role/suspension denial,
DB-level scope/reversal validation, table and column privileges, immutable drift
evidence without silent repair, scheduling and bounded continuation after reconnect.
The column-grant test restores its temporary operator grant in finally. Synthetic
append-only ledger/audit fixtures remain in the isolated DB. Drift-fixture balance
changes are restored by the test operator, not the reconciliation job.

Both native startup/readiness checks pass. The runtime-only CLI completed 3 durable
batches and closed its context. Before that CLI run, POSTGRES_ADMIN_URL,
LEDGER_TEST_ADMIN_URL and PGPASSWORD were removed from the child process environment;
only the restricted runtime test URL was supplied. No process/service was retained.
No API contract/client codegen or Android build was needed; iOS remains deferred.

At repository root, executed `node --test tools/checks.spec.mjs` (5 guards PASS)
and `git diff --check` (PASS). T-070's new task registration refuses missing
native administrator/grant coverage before running commands. The full task runner
was not invoked on Windows; its registered checks were executed directly using
installed binaries. No manual PASS or module gate is claimed.

Executed operator command (repository root; administrator connection/password and
runtime role loaded privately from the separate files; psql 18 client):
```powershell
& 'C:\Program Files\PostgreSQL\18\bin\psql.exe' -X -w -v ON_ERROR_STOP=1 -h $taskAdmin.Host -p $taskAdmin.Port -U ([uri]::UnescapeDataString($taskAdminAuth[0])) -d supplybiz_service_area_test -v "runtime_role=$taskRuntimeRole" -v ledger_owner=supplybiz_ledger_test_owner -f tools/ledger-grants.sql
```
The password was supplied only through the operator child's PGPASSWORD, not a
command argument. For native tests, LEDGER_TEST_DATABASE_URL used the restricted
login and LEDGER_TEST_ADMIN_URL the operator login, both explicitly targeting the
same local `_test` DB. The CLI and runtime smokes used the restricted login only.

Next verification steps (suggested, not executed):
1. On your selected verification environment, apply the migration and use the
   operator-only credentials for `tools/ledger-grants.sql` with `runtime_role` and `ledger_owner`.
   Verify the API login cannot UPDATE/DELETE/TRUNCATE entries or mutate balances.
2. Set LEDGER_TEST_DATABASE_URL to the runtime test URL and LEDGER_TEST_ADMIN_URL
   to the operator URL pointing to that same local `_test` DB. Run the focused
   `src/modules/ledger/ledger.postgres.spec.ts` suite. Its 11 cases cover concurrency/
   reconnect replay, rollback, precision, opening/reversal, isolation, actual DB
   permissions, drift evidence and durable scheduling; failed grants cannot skip.
3. Check reversal leaves the original and one audited opposite entry; changed
   opening payload under the same permanent key must fail. Financial source
   reference replay must not add another balance effect.
4. Run `ledger:reconcile` using runtime credentials against the isolated DB.
   Check job counts and immutable findings; simulate drift only through the test
   suite's operator fixture, and confirm the job reports rather than repairs it.

Full ordering/delivery/payment/claim integration and G2 follow their owning tasks.
Operator setup is complete for the isolated DB. Manual PASS, actual worker-process
restart/alert drill and G2 remain pending. Stop at READY_FOR_VERIFY; do not mark DONE.

## T-028 customers handoff (2026-11-11): READY_FOR_VERIFY

ADR-028 resolves the pre-assignment policy: allow 50 active customers, excluding
inactive records; no default plan or feature entitlement is granted. Assigned
catalog caps remain BASIC 100, STANDARD 250, BUSINESS 500, PREMIUM 1000; seed data
is unchanged. ADR-028 resolves this cap; ADR-029 now resolves Q-04 trial/expiry/
downgrade policy. T-084/T-103 must wire the approved lifecycle checks into this hook.

Implemented owned vendor customer list/detail/create/PATCH (inactivation retains
history), case-insensitive name/mobile search, All/Active/Inactive/Subscription
filters and pagination. Normalize Indian mobiles to +91 and enforce per-vendor
uniqueness even for inactive records. Creation/reactivation locks the vendor and
counts active rows in the same transaction; simultaneous final-slot attempts
cannot exceed the limit. Mutations require a body/path-sensitive idempotency key.
Clients cannot supply vendorId, userId or customerLimit.

GET `/api/v1/customer/link-requests` derives pending prompts from the authenticated
verified mobile, including accounts registered after the offline record existed.
Only explicit accept writes user_id; decline is durable. IDs are vendor-customer
IDs, not user IDs. Declining removes the prompt. Cached writes still require a
current authorized role; wrong owner/match and suspended vendors are denied.
Linking an existing row does not consume a second customer slot. Linked mobile
cannot be edited; inactivation preserves accepted linkage and history.

Internal transaction hooks: `requireCapacity` locks/counts before future customer
creation by orders; `setAssignedCustomerLimit` writes a real catalog limit within
T-084/T-103's audited assignment transaction; `setSubscriptionReference` must be
maintained by T-072; `requireLinked` must guard later customer ledger/history
reads. The nullable vendors.assigned_customer_limit means never assigned, not
expired. Never clear it on expiry to reinstate the 50 allowance. No assignment
API, expiry behavior, subscription/order/ledger history or financial totals are
fabricated by this slice. TC-063 and full TC-064 ledger visibility remain NOT_RUN
until their owning modules exist; T-029/T-053 own the mobile flows. Audited plan
assignment integration remains T-084/T-103/T-156. G0/G1/manual PASS remain pending.
Generated Dart nullable fields omit null on serialization; T-029's email-clear
request must preserve an explicit `email:null` in its request map.

Checks executed: 8 focused customer PostgreSQL/HTTP tests (two API instances and
restart), 2 native runtime smoke tests, 4 task-runner guards, API lint/typecheck/
build/schema, regenerated TS compile and Dart serializer generation/analysis pass.
The first runtime attempt stopped at sandbox Windows private-upload ACL access;
the host-access rerun exposed independent ephemeral signing keys in the test
harness. Sharing a newly generated test-only key across instances fixed the
harness; no production auth code changed. The final 8 tests all pass. Initial
Dart generation needed host network access for pub.dev advisories. Client analysis
also caught an enum-default generator issue; removing wire defaults from optional
input fields fixed it and prevents PATCH from overwriting omitted fields.
No new dependencies. No check process/service was left running. iOS is deferred;
this API-only task required no Android build. Local Node 23 differs from pinned 20.

Executed commands (apps/api, env loaded privately; only the existing isolated
`supplybiz_service_area_test` DB was migrated, never the configured app DB):
```powershell
.\node_modules\.bin\prisma.cmd generate --schema src/prisma/schema.prisma
.\node_modules\.bin\prisma.cmd migrate deploy --schema src/prisma/schema.prisma
.\node_modules\.bin\prisma.cmd validate --schema src/prisma/schema.prisma
.\node_modules\.bin\tsc.cmd --noEmit
.\node_modules\.bin\eslint.cmd src test scripts jest.config.ts --max-warnings=0
.\node_modules\.bin\tsc.cmd -p tsconfig.build.json
# CUSTOMERS_TEST_DATABASE_URL and NATIVE_TEST_DATABASE_URL point to the isolated DB:
.\node_modules\.bin\jest.cmd --silent --runInBand --testTimeout=60000 --runTestsByPath src/modules/customers/customers.postgres.spec.ts
.\node_modules\.bin\jest.cmd --config test/jest-e2e.json --runInBand --testTimeout=60000 --runTestsByPath test/native-runtime.e2e-spec.ts
.\node_modules\.bin\ts-node.cmd scripts/generate-openapi.ts
```
At repository root (installed codegen binaries, same options as tools/codegen.sh):
```powershell
.\node_modules\.bin\openapi-typescript.cmd contracts/openapi.yaml -o packages/ts-client/src/generated/openapi.ts
.\node_modules\.bin\openapi-generator-cli.cmd generate -g dart-dio -i contracts/openapi.yaml -o packages/api_client --template-dir tools/openapi/dart-dio --global-property=apiTests=false,modelTests=false --skip-validate-spec --additional-properties=pubName=supplybiz_api_client,pubVersion=0.1.0,serializationLibrary=json_serializable,skipCopyWith=true
node tools/normalize-generated-docs.mjs
& 'C:\flutter\bin\cache\dart-sdk\bin\dart.exe' format packages/api_client/lib
.\apps\api\node_modules\.bin\tsc.cmd packages/ts-client/src/generated/openapi.ts --noEmit --skipLibCheck
node --test tools/checks.spec.mjs
git diff --check
```
From packages/api_client:
```powershell
& 'C:\flutter\bin\cache\dart-sdk\bin\dart.exe' run build_runner build '--build-filter=lib/src/model/*.g.dart'
& 'C:\flutter\bin\cache\dart-sdk\bin\dart.exe' analyze
```
The task-runner command itself was not invoked on Windows; its registered focused
commands were run directly. Its new T-028 registration requires native DB coverage.
The module gate was not run. Migration is additive; rollback is to stop using the
new handlers while retaining new tables/column and all data; no reset/drop needed.

Manual verification (suggested; not executed as manual PASS):
1. Apply the additive migration to your selected local DB and start the API with
   an active vendor session/category. POST `/api/v1/vendor/customers` with a fresh
   Idempotency-Key and a synthetic `{name,mobile,address,preferredPayment}` record;
   replay it, confirm one row and normalized +91 mobile. Duplicate mobile with a
   fresh key must return 409 DUPLICATE. Search/filter and edit the record.
2. With no assignment, reach 50 active synthetic customers; the 51st must return
   422 PLAN_CUSTOMER_LIMIT. Inactivate one, add another, then try reactivating the
   old one: it must fail until another slot is freed. Assigned-cap hook tests cover
   100/250/500/1000; real admin-assignment verification waits for T-103/T-156.
3. Use a second vendor and customer-role session: cross-vendor detail/edit must
   return 404, and customer access to vendor routes 403. Attempting forged owner,
   linkage or limit fields must return 400.
4. Register/sign in with the synthetic offline record's matching verified mobile,
   hold/select CUSTOMER role, GET link-requests, and accept with a fresh key.
   Vendor detail must show LINKED and retain the same customer ID. Another
   account must not list/accept it. Retry accept without duplicating decisions.
5. Decline a separate matching record, reload and restart: its prompt must stay
   absent and user_id remain null. Deactivate an accepted record: the linkage is
   retained. Verify actual ledger/UI visibility only with the owning later tasks.

## T-026 catalog handoff (2026-11-10): READY_FOR_VERIFY

Final checks: 9 focused native PostgreSQL/HTTP/private-image cases pass (no skipped
cases), including concurrent/restarted replay, merged validation/zero subscription
price, ownership/role/suspension, upload/attachment/read, search/filter, selection
guard, stock crossings/concurrency/append-only history, rollback, delivery/reversal
transaction hooks and ACTIVE/PAUSED-reference deletion protection. Both native
runtime smoke checks and all 4 task-runner guards pass. API typecheck/build/lint,
Prisma validation, generated TypeScript compile and generated Dart analysis pass.
Clients were regenerated from the OpenAPI source, serializers generated and Dart
formatted; unchanged generated files have no retained formatting differences.
The full task runner was not invoked; its registered commands were executed
directly on Windows. Manual PASS and comprehensive G0/G1 gates remain pending.
Local Node 23.11.0 differs from pinned Node 20; Dart is 3.9.2 (Flutter 3.35.7).

Owned catalog CRUD/search/filter/pagination, merged PATCH validation, soft deletion,
private PRODUCT_IMAGE attachment, atomic stock movements and fixed 10-pack crossing
events are implemented. Q-34 is resolved. No new packages are needed. Earlier
scope/SRS edits in this working tree are the user's threshold decision.

Both additive migrations were applied only to the existing isolated local
`supplybiz_service_area_test`; the API-configured database was not migrated here.
The second migration permits zero subscription price per FR-030, retaining positive
selling-price validation. Its first isolated application failed before changing
data because the autogenerated constraint was named `products_check`; the corrected
migration was marked rolled back and successfully reapplied. No baseline data or
past migration was reset. Append-only synthetic stock fixtures/private test images
are retained in the isolated database/storage rather than bypassing immutability.

Executed commands (from apps/api unless stated; env values loaded privately from
ignored `.env`, database path overridden to supplybiz_service_area_test):
```powershell
.\node_modules\.bin\prisma.cmd generate --schema src/prisma/schema.prisma
.\node_modules\.bin\prisma.cmd migrate deploy --schema src/prisma/schema.prisma
# Recovery of the failed second migration, before its successful deploy:
.\node_modules\.bin\prisma.cmd migrate resolve --rolled-back 20261110123000_catalog_subscription_price --schema src/prisma/schema.prisma
.\node_modules\.bin\tsc.cmd --noEmit
.\node_modules\.bin\tsc.cmd -p tsconfig.build.json
.\node_modules\.bin\eslint.cmd src test scripts jest.config.ts --max-warnings=0
.\node_modules\.bin\prisma.cmd validate --schema src/prisma/schema.prisma
# CATALOG_TEST_DATABASE_URL points to the isolated database; NODE_ENV=test, OTP_DELIVERY_MODE=disabled:
.\node_modules\.bin\jest.cmd --silent --runInBand --testTimeout=60000 --runTestsByPath src/modules/catalog/catalog.postgres.spec.ts
# NATIVE_TEST_DATABASE_URL points to the isolated database:
.\node_modules\.bin\jest.cmd --config test/jest-e2e.json --runInBand --testTimeout=60000 --runTestsByPath test/native-runtime.e2e-spec.ts
.\node_modules\.bin\ts-node.cmd scripts/generate-openapi.ts
```
At repository root, contract/client generation used the installed binaries directly:
```powershell
.\node_modules\.bin\openapi-typescript.cmd contracts/openapi.yaml -o packages/ts-client/src/generated/openapi.ts
.\node_modules\.bin\openapi-generator-cli.cmd generate -g dart-dio -i contracts/openapi.yaml -o packages/api_client --template-dir tools/openapi/dart-dio --global-property=apiTests=false,modelTests=false --skip-validate-spec --additional-properties=pubName=supplybiz_api_client,pubVersion=0.1.0,serializationLibrary=json_serializable,skipCopyWith=true
node tools/normalize-generated-docs.mjs
& 'C:\flutter\bin\cache\dart-sdk\bin\dart.exe' format packages/api_client/lib
.\apps\api\node_modules\.bin\tsc.cmd packages/ts-client/src/generated/openapi.ts --noEmit --skipLibCheck
node --test tools/checks.spec.mjs
```
From packages/api_client:
```powershell
& 'C:\flutter\bin\cache\dart-sdk\bin\dart.exe' run build_runner build '--build-filter=lib/src/model/*.g.dart'
& 'C:\flutter\bin\cache\dart-sdk\bin\dart.exe' analyze
```
Initial sandboxed native tests failed at existing Windows private-storage ACL
verification, before catalog assertions. The rerun outside the sandbox passed;
the storage checks were preserved. Initial Dart serializer generation was blocked
by pub.dev advisory access; its approved rerun completed. The pnpm/Dart wrapper
attempts that stalled were stopped; direct installed binaries were used instead.

Manual verification (suggested; not executed as manual PASS):
1. Apply both migrations to your chosen local database, start the existing API
   normally, and use a real vendor session/category. POST `/api/v1/vendor/products`
   with a new Idempotency-Key and `{ "name":"Test Cow Milk", "productType":"MILK",
   "milkType":"COW", "unitValue":1, "unitType":"L", "sellingPricePaise":6000,
   "stockQty":12 }`; retry the same request and confirm one persisted product.
2. GET the list with `?search=cow&productType=MILK`; PATCH prices, MOQ and activity
   with fresh keys. Subscription price above selling price must return 400.
   Deactivation remains visible in the vendor list; downstream customer/POS hiding
   is verified when those routes are implemented.
3. POST `/{id}/stock-adjustments` with `{ "delta":-2, "reason":"Stock count" }`:
   stock becomes 10, one movement and one STOCK_LOW event persist. Retry the same
   key: no extra change. Drop to 9: no new event; replenish to 12 then drop to 10:
   one additional crossing event. Blank reason/insufficient stock must fail.
4. Use a second vendor/customer session: reads/edits/deletes/adjustments of this
   product must fail (404 for other vendor ownership, 403 for customer role).
5. DELETE an unreferenced product with a new key; repeat that key. Its list/detail
   disappears, its DB row and movements remain. ACTIVE/PAUSED reference protection
   is exercised by the focused suite through the real transaction hook; verify
   actual subscription create/pause/end/delete integration with T-072.

Remaining integration: T-049/T-079/T-071 own order/POS financial wiring and exactly
once delivery effects; T-072 must maintain product_subscription_links atomically.
STOCK_LOW is an ungated domain event with requiredFeature=STOCK_ALERTS and
minimumPlan=BUSINESS. T-032 must check actual T-084/T-103 server entitlements and
deduplicate before inbox/push delivery; BASIC must receive no notification. No
notification consumer/delivery or real plan assignment is claimed here. Until
registered, the dispatcher explicitly retries/fails these events as missing a
handler. Full TC-038/040/041 module integration, manual PASS and G0/G1 are pending.
No iOS work or separate RUN workflow was started.

## T-023 service-area handoff (2026-11-10): READY_FOR_VERIFY

Windows blocker resolved: new storage directories receive a protected owner-only
DACL; existing paths are validated without automatically changing their ACLs.
Ownership, protected directory inheritance and permitted principals (service user,
SYSTEM and local Administrators only) are checked using SIDs. File reads validate
their inherited/private ACLs and reject reparse points. POSIX 0700/0600 checks remain
unchanged. The user approved restricting the four existing local upload directory
ACLs; that one-time setup is separate from application startup. Windows PowerShell
is required for native ACL validation; subprocess failure/timeout fails closed.

Final evidence: all 11 native HTTP/PostGIS/onboarding checks pass, including real
photo upload/read, 2.9/3.1 km boundaries, pincode-only coverage, replay/restart,
rollback and ownership. Six storage checks pass, including rejection of a protected
ACL granting Everyone access. Both native readiness/disabled-provider smoke checks
and all four task-runner guards pass. API lint/typecheck/build and client/schema
evidence below remain passing. No new process remains running. Manual PASS and
module gates remain pending; this is a Windows/Node 23 local handoff, not a claim
of pinned Node 20 or production readiness.

Final executed commands from apps/api (environment: NODE_ENV=test,
OTP_DELIVERY_MODE=disabled, VENDORS_TEST_DATABASE_URL/NATIVE_TEST_DATABASE_URL loaded
privately from API credentials with database path supplybiz_service_area_test):
```powershell
.\node_modules\.bin\jest.cmd --silent --runInBand --testTimeout=60000 --runTestsByPath src/modules/vendors/vendors.postgres.spec.ts src/storage/local-storage.service.spec.ts
.\node_modules\.bin\jest.cmd --runInBand --testTimeout=60000 --runTestsByPath src/storage/local-storage.service.spec.ts
.\node_modules\.bin\jest.cmd --config test/jest-e2e.json --runInBand --testTimeout=60000 --runTestsByPath test/native-runtime.e2e-spec.ts
.\node_modules\.bin\tsc.cmd --noEmit
.\node_modules\.bin\tsc.cmd -p tsconfig.build.json
.\node_modules\.bin\eslint.cmd src test scripts jest.config.ts --max-warnings=0
```
The combined command passed all 11 vendor tests but exposed an ACL-tampering test
fixture issue (Set-Acl tried to use SeSecurityPrivilege). Changing the fixture to
icacls for its temporary DACL change made the subsequent six-test storage run pass.
No security check was weakened. Initial photo reads exposed a second POSIX-only
file-mode check, now fixed with Windows ACL validation. The task runner registers
both the vendor and storage suites; on this Windows host the explicit commands
above were used with a 60-second cold-start allowance.

Local setup is now complete: created `supplybiz_user` (LOGIN, no superuser/role/DB
creation privileges), API-configured `supplybiz_test` and isolated
`supplybiz_service_area_test`. Installed the official stable PostGIS 3.6.2 Windows
PG18 bundle after checking its published checksum; existing PostgreSQL files were
preserved. Enabled PostGIS in both databases and applied all 12 migrations to both.
The configured API login connects successfully; existing seed completed in the API
database only. No administrator password is saved in source or this documentation.
`tools/provision-local-postgres.ps1` reads DATABASE_URL and POSTGRES_ADMIN_URL from
the ignored environment file (or transient process environment for the admin URL),
preserving existing roles, credentials and database contents on rerun.

Selected in Day 4 roadmap order: T-021 is READY_FOR_VERIFY. Provisional source adds
GET/PUT `/api/v1/vendor/settings/service-area`, both returning the owned vendor
profile; `settings` includes `serviceRadiusKm`, sorted `pincodes` and `version`.
PUT replaces `{ serviceRadiusKm, pincodes }` atomically, requires an Idempotency-Key,
and derives ownership from the held/active vendor session. Radius is an integer
1–20 or null for pincode-only; pincodes are unique six-digit Indian pincodes;
an empty combined area is rejected. Radius requires shop coordinates. The shared
`VendorsService.covers` query uses PostGIS geography meters and radius OR pincode
coverage per TC-028. Discovery/order wiring belongs to T-041/T-045; it is not yet
an end-to-end customer order restriction. The additive migration creates the
pincode table and initializes previously unconfigured radii to FR-018's 3 km.

**Historical blocker (resolved by the Windows fix above):** storage checked POSIX
mode 0700 on Windows directories and fails closed during API startup. The focused
suite first exceeded the default cold-start timeout, then a 60-second allowance
revealed this existing runtime error. All 11 HTTP tests fail during setup; none
of their service-area assertions ran in that initial attempt. Windows-aware private
ACL validation was required; the implemented fix and passing HTTP/smoke results
are recorded above. No permission check was bypassed.
Local Node is v23.11.0; `.nvmrc` pins 20, so pinned-runtime evidence remains pending.

Executed successfully (API working directory unless noted; local `.cmd` shims
avoid PowerShell's blocked ps1 shims and package-manager startup downloads):
```powershell
# Repository root:
pnpm.cmd install --frozen-lockfile --reporter=append-only
node --test tools/checks.spec.mjs
node --check tools/check-task.mjs
# apps/api:
.\node_modules\.bin\prisma.cmd generate --schema src/prisma/schema.prisma
.\node_modules\.bin\prisma.cmd validate --schema src/prisma/schema.prisma
.\node_modules\.bin\prisma.cmd migrate deploy --schema src/prisma/schema.prisma
.\node_modules\.bin\tsc.cmd --noEmit
.\node_modules\.bin\tsc.cmd -p tsconfig.build.json
.\node_modules\.bin\eslint.cmd src test scripts jest.config.ts --max-warnings=0
.\node_modules\.bin\ts-node.cmd --transpile-only scripts/generate-openapi.ts
.\node_modules\.bin\ts-node.cmd --transpile-only src/prisma/seed.ts
.\node_modules\.bin\tsc.cmd --noEmit --skipLibCheck --target ES2022 --module NodeNext --moduleResolution NodeNext ../../packages/ts-client/src/generated/openapi.ts
```
Migration command ran once with the isolated DATABASE_URL and once with API `.env`.
OpenAPI generation used OTP_DELIVERY_MODE=disabled. Bare Prisma db seed failed
to find the ts-node shim; the explicit command above succeeded with DATABASE_URL
loaded from the ignored API environment file. No secrets were printed.

From repository root, OpenAPI/TS/Dart regeneration executed:
```powershell
.\node_modules\.bin\openapi-typescript.cmd contracts/openapi.yaml -o packages/ts-client/src/generated/openapi.ts
.\node_modules\.bin\openapi-generator-cli.cmd generate -g dart-dio -i contracts/openapi.yaml -o packages/api_client --template-dir tools/openapi/dart-dio --global-property=apiTests=false,modelTests=false --skip-validate-spec --additional-properties=pubName=supplybiz_api_client,pubVersion=0.1.0,serializationLibrary=json_serializable,skipCopyWith=true
node tools/normalize-generated-docs.mjs
C:\flutter\bin\flutter.bat pub get
# packages/api_client:
C:\flutter\bin\cache\dart-sdk\bin\dart.exe run build_runner build --delete-conflicting-outputs --build-filter='lib/src/model/*.g.dart'
# Repository root:
C:\flutter\bin\cache\dart-sdk\bin\dart.exe format packages/api_client/lib
C:\flutter\bin\cache\dart-sdk\bin\dart.exe analyze packages/api_client/lib
```
All pass; Dart analyzer reports no issues. The first serializer command without
--delete-conflicting-outputs stopped on existing generated outputs; the explicit
noninteractive regeneration above passed. Client files were generated, never edited.
Provisioning script syntax, four runner guards and whitespace checks pass.

Executed FAILED: `.\node_modules\.bin\jest.cmd --runInBand --testTimeout=60000
--runTestsByPath src/modules/vendors/vendors.postgres.spec.ts` from apps/api with
VENDORS_TEST_DATABASE_URL pointing to the isolated database, NODE_ENV=test and
OTP_DELIVERY_MODE=disabled. Runtime readiness smoke is NOT_RUN after the confirmed
shared startup blocker in the initial attempt; the final runtime smoke above passes.
The suite includes T-023 checks and affected onboarding
regressions. Both services and databases are preserved; no newly started service,
installer, download or check process remains running. No module-gate pass is claimed.

Suggested manual verification after successful implementation checks (NOT_RUN):
1. As a vendor with saved shop coordinates, load the service area; verify default
   3 km, no pincodes, then save radius and pincodes and reload after API restart.
2. Retry a PUT with the same key/body; verify identical response and one version
   increment; changing its body with the same key must return 422.
3. Try radius 0/21, malformed/duplicate pincodes, empty combined area and forged
   vendorId; confirm rejection without changing the saved area. Other owners and
   customer-role sessions must not read or mutate this vendor's area.
4. Run TC-028 against native PostGIS: 2.9 km inside and 3.1 km outside a 3 km radius;
   a listed pincode adds coverage, and null radius allows only listed pincodes.

Manual PASS and G0/G1 remain pending. No mobile runtime changes; iOS checks deferred.
Rollback application code while retaining the additive table/data; do not delete
saved service areas. This handoff stops for task-specific manual verification.

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

## T-084 plan entitlement implementation handoff (2026-11-11)

READY_FOR_VERIFY. ADR-029 policy is implemented as a reusable PlanGuard and
transactional PlanEntitlementsService. SessionGuard runs before PlanGuard;
the guard derives the vendor from the authenticated active vendor role.
Business mutations must also call requireFeature/requireOperation inside their
own transaction so a concurrent expiry/downgrade cannot bypass authorization.
Those methods supplement existing ownership/order-state/cutoff rules.

Assignment validity uses database time after the vendor-row lock (start inclusive,
end exclusive), with no trial or grace. The approved tier allowlist excludes
wallet/settlement and undefined support actions. Customer creation/reactivation
now checks effective validity and capacity under that same lock. Never-assigned
vendors retain 50 setup slots; assigned caps stay 100/250/500/1000. Expiry cannot
restore setup access; over-cap downgrades keep all rows and block growth until
below the new cap. Customer reads/edits/inactivation remain available. Stock
opening, adjustments and quantity-changing stockQty PATCH require BUSINESS+;
zero-stock setup and edits with unchanged quantity remain available. Existing
delivery/reversal stock changes remain subject
to their owning transaction's order/financial rules.

The additive vendor_plan_assignments table requires catalog/admin/audit links,
valid dates/reason and one non-superseded row per vendor. Effective grants require
matching ADMIN/PLAN_ASSIGNED/VENDOR audit evidence. T-103 must implement actual
authorized, idempotent assignment/extension writes: lock vendor, supersede current
assignment, write audit/assignment and update assigned_customer_limit atomically.
No public assignment endpoint, production default assignment, billing or fake
revenue was added. Test grants live only in test/fixtures/plans.ts, excluded from
the production build. The fixture guard routes exist only in the testing module.

Executed in apps/api (PowerShell; local binaries avoid a stalled pnpm launcher):

```powershell
.\node_modules\.bin\prisma.cmd generate --schema src/prisma/schema.prisma
$dbLine = Get-Content .env | Where-Object { $_ -match '^DATABASE_URL=' } | Select-Object -First 1
$taskUrl = [UriBuilder]::new(($dbLine -replace '^DATABASE_URL=', '').Trim('"', "'"))
$taskUrl.Path = '/supplybiz_service_area_test'
$env:DATABASE_URL = $taskUrl.Uri.AbsoluteUri
.\node_modules\.bin\prisma.cmd migrate deploy --schema src/prisma/schema.prisma
$env:NATIVE_TEST_DATABASE_URL = $taskUrl.Uri.AbsoluteUri
$env:CATALOG_TEST_DATABASE_URL = $env:NATIVE_TEST_DATABASE_URL
$env:NODE_ENV = 'test'
$env:OTP_DELIVERY_MODE = 'disabled'
.\node_modules\.bin\jest.cmd --runInBand --testTimeout=60000 --runTestsByPath src/modules/plans/plans.postgres.spec.ts src/modules/customers/customers.postgres.spec.ts src/modules/catalog/catalog.postgres.spec.ts
.\node_modules\.bin\jest.cmd --config test/jest-e2e.json --runInBand --testTimeout=60000 --runTestsByPath test/native-runtime.e2e-spec.ts
.\node_modules\.bin\eslint.cmd src test scripts jest.config.ts --max-warnings=0
.\node_modules\.bin\tsc.cmd --noEmit
.\node_modules\.bin\tsc.cmd -p tsconfig.build.json
.\node_modules\.bin\prisma.cmd validate --schema src/prisma/schema.prisma
```

From repository root: `node --test tools/checks.spec.mjs` and `git diff --check`.
Results: 30 focused native checks (12 plan, 8 customer, 10 catalog), 2 runtime
smokes and 5 runner guards PASS; lint/typecheck/build/schema PASS. The first native
run was blocked by sandbox ACL inspection; permitted reruns used the existing
Windows private-storage checks. Test expectations were corrected for the public
problem-detail envelope and disabled-user 403; retained synthetic fixture mobile
IDs were made unique across reruns. The final focused test log is in the host
temporary directory as supplybiz-t084-focused.log. No client contract changed;
OpenAPI/client generation NOT_RUN (unneeded). Only the isolated test DB migration
was applied; dev/staging/production migrations NOT_RUN. Test servers were closed;
pre-existing services were preserved. Synthetic append-only audit/stock fixtures
remain in the isolated DB.

Manual verification (suggested, NOT executed; dedicated local _test DB only):
1. Apply the migration to that isolated DB, start the API using its configuration
   and authenticate a synthetic vendor using the existing T-015 instructions.
   Create customers through the API: slot 50 succeeds and slot 51 returns 422
   PLAN_CUSTOMER_LIMIT with support guidance. No default assignment is created.
2. For this test DB only, use a ts-node REPL to import PrismaService and
   assignPlanFixture from test/fixtures/plans. Call the fixture in a transaction
   for that vendor with BASIC, then BUSINESS. Verify the displayed cap changes
   100 to 500 and stock adjustments/opening quantities require BUSINESS+.
3. Use the fixture's optional start/end Dates to assign an already-expired plan.
   Verify create/reactivate return 403 PLAN_FEATURE_LOCKED, reads/edits remain,
   and the count/records are retained. Renew to BASIC and verify capacity returns.
4. With more than 100 active synthetic customers under BUSINESS, assign BASIC.
   Verify no records are removed, new additions/reactivations are blocked, and
   growth resumes only below 100. Repeat attempts using another vendor's token
   and confirm ownership denial. Stop manually started processes afterward.

Remaining: T-103/T-156 actual admin workflow; downstream orders/POS/subscriptions/
generation/settlement/reports must call the transaction hooks as implemented.
Manual PASS and G0/G1 remain pending. Mobile/iOS checks NOT_RUN (API task; iOS
deferred under ADR-025). Preserve assignment/audit data during code rollback;
do not delete history or clear the projection to regain setup access.

## T-103 audited plan assignment implementation handoff (2026-11-11)

The API now supplies GET /vendor/plans and /vendor/plan, plus plans.manage-gated
GET /admin/plans and /admin/vendors/{id}/plan. Catalog names/prices/popularity
come from the database; approved tier caps/features are server-owned. Vendor
responses omit the internal assignment reason and admin/audit identifiers.
SUPER_ADMIN and FINANCE may POST /admin/vendors/{id}/plan-assignments with
{planId, startsAt, endsAt, reason}; extend the current assignment with POST
/admin/vendors/{id}/plan-assignments/{assignmentId}/extend and {endsAt, reason}.
Both require a live bearer session, matching X-CSRF-Token and Idempotency-Key.

Authorization/session, permanent actor-scoped replay, vendor lock, before/after
audit, assignment history, effective customer-limit projection and reminder jobs
share one transaction. A replay cannot bypass a revoked role/session. Changed
payload/path returns 422; failed writes reserve no key. Extensions preserve the
old record, retain its start and create a new current assignment ID with a later
end. End must be after start and DB now. New assignments replace the current row
immediately; future dates show SCHEDULED without paid/new-business access until
start. Previously authorized history/settlement/existing-order operations remain
subject to their normal domain rules. No trial/grace, fallback plan, automatic
customer deletion, checkout, invoice or revenue write is introduced.

No API timer is added. Existing worker/outbox leases execute persisted 7/3/1-day
and expiry jobs scheduled relative to the assignment end. Due stages before the
grant/start are omitted; restart catches up the latest meaningful stage and
skips obsolete stages or superseded assignments. Notification source identity
prevents duplicate inbox rows; expiry uses PLAN_EXPIRED. Actual provider push
delivery is NOT_RUN; notification preferences/ownership checks remain in force.

Executed from apps/api (PowerShell; credentials read locally without printing):

```powershell
.\node_modules\.bin\prisma.cmd generate --schema src/prisma/schema.prisma
$dbLine = Get-Content .env | Where-Object { $_ -match '^DATABASE_URL=' } | Select-Object -First 1
$taskUrl = [UriBuilder]::new(($dbLine -replace '^DATABASE_URL=', '').Trim('"', "'"))
$taskUrl.Path = '/supplybiz_service_area_test'
$env:DATABASE_URL = $taskUrl.Uri.AbsoluteUri
.\node_modules\.bin\prisma.cmd migrate deploy --schema src/prisma/schema.prisma
$env:NATIVE_TEST_DATABASE_URL = $taskUrl.Uri.AbsoluteUri
$env:ADMIN_TEST_DATABASE_URL = $env:NATIVE_TEST_DATABASE_URL
$env:NODE_ENV = 'test'
$env:OTP_DELIVERY_MODE = 'disabled'
.\node_modules\.bin\jest.cmd --runInBand --testTimeout=60000 --runTestsByPath src/modules/plans/plan-assignments.postgres.spec.ts src/modules/plans/plans.postgres.spec.ts src/modules/admin-auth/admin-auth.postgres.spec.ts
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
From apps/admin: `.\node_modules\.bin\tsc.cmd --noEmit`.

Results: 30 focused native checks (9 assignment/reminder, 12 entitlement, 9 admin
auth including production Next.js BFF), 2 runtime smokes and 5 runner guards PASS.
API lint/typecheck/build/schema, TS/Dart generation, TS client compile, Dart
client analysis and admin consumer typecheck PASS. Manual PASS/G0/G1 pending.

Native checks used permission for Windows ownership/ACL inspection. The existing
admin-auth fixture needed private ACL initialization and a longer production
Next.js startup allowance; its real BFF login/TOTP/logout smoke is included.
The stalled Windows pnpm.cmd version probe was cancelled; local binaries and
canonical Bash codegen completed. TS/Dart clients were regenerated from source.
Only the isolated _test DB migration was applied; dev/staging/production migration
is NOT_RUN. Immutable synthetic fixtures remain in that DB; test servers were
closed and pre-existing services preserved. Focused output is in the host temp
directory as supplybiz-t103-focused.log.

Manual verification (suggested, NOT executed):
1. Apply the migration to the intended local dev DB and start API/worker using
   the existing instructions. Use a synthetic vendor and a real local FINANCE
   or SUPER_ADMIN login/TOTP session; capture its CSRF token locally.
2. Read GET /admin/plans, assign a catalog plan with timezone-qualified dates,
   reason and fresh key. Check GET /vendor/plan and the audit viewer; repeat the
   request with the same key and confirm the same ID and one audit/grant.
3. Extend the current ID with a later end. Verify the returned ID changes, the
   old row/audit remains and vendor validity/cap reflect the new current record.
   Attempt a stale ID, wrong CSRF, changed payload/key and SUPPORT session.
4. Downgrade a synthetic vendor above the new cap. Verify every customer remains,
   additions/reactivations are denied and permitted existing business continues.
5. In the isolated test DB only, inspect the 7/3/1/expiry jobs and use the focused
   job drill to dispatch due stages. Verify one inbox entry per stage, expired
   new-business locks and successful renewal. Stop manually started processes.

T-156 still owns admin catalog editing/screens; T-105 owns the mobile plan UI.
Downstream domain services must use T-084's transactional operation hooks.
Manual PASS, live push and G0/G1 remain pending. Android/iOS builds NOT_RUN for
this API task; iOS validation remains deferred by ADR-025.
