# Supply Biz Mobile

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
