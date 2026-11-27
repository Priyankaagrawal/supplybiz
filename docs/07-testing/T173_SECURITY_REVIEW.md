# T-173 focused security review — 2026-11-27

**READY_FOR_VERIFY**, not release/security certification. Manual PASS and G4/G6
remain pending; ADR-030 permits implementation with their prerequisite tasks ready.

## Fixes

- Initial production audit: 13 high, 0 critical advisories. Patch pins select
  multer 2.5.0, body-parser 1.20.9, qs 6.16.1, lodash 4.18.0 and js-yaml 4.3.2.
  Full-graph scanning additionally identified codegen-tool dependencies patched
  with follow-redirects 1.16.2 and basic-ftp 6.2.4. No clients were regenerated.
- Upgrade Zod to 4.6.6 and migrate both record schemas to explicit string keys,
  preserving boolean/public-config and string/signing-key values. Sources:
  [Zod](https://github.com/advisories/GHSA-mrhx-c7xc-m3w5),
  [Multer](https://github.com/advisories/GHSA-q7qp-rjg7-q26m),
  [YAML](https://github.com/advisories/GHSA-2883-xcg3-v3hh),
  [redirects](https://github.com/advisories/GHSA-mrwp-f3q8-3g9p),
  [FTP parser](https://github.com/advisories/GHSA-c475-qrg2-pj4r).
- API request-ID middleware previously echoed/logged arbitrary client strings.
  Only documented 36-character UUIDs now pass; other values get generated UUIDs.
  Nine new cases cover missing/private/oversized/multiple/newline-suffixed input;
  the real HTTP diagnostic regression still verifies redacted error correlation.
- Admin origin validation previously accepted FTP/WebSocket schemes on loopback.
  A reproduced failing regression now passes: HTTPS or loopback HTTP only.
  Secure/HttpOnly/SameSite cookies and session-bound CSRF remain enforced.

## Evidence

- **29 API cases**: request-ID/diagnostics, session HTTP boundary, native config,
  FCM payloads, subscription policy and real HTTP/PostgreSQL tenant/replay/stock/
  rate-limit smoke. **12 additional storage/ledger unit cases** pass.
- **7 admin cases**: CSRF, origin/cookies, management permissions and document
  controls. **28 mobile cases**: secure storage, deep links, guards and network
  refresh/redirect boundaries. No mobile source/dependency changes.
- API typecheck/build/lint and admin typecheck/lint/production webpack build pass.
  Codegen FTP exports consumed by get-uri pass a no-network compatibility smoke;
  FTP transport/JAR execution and client regeneration were not run.
- `flutter pub outdated --json`: 71-package inventory, no lockfile changes.
  This is not Dart advisory or native-SDK security clearance.
- Final Node audit: **production 0 high/critical, 3 moderate; full graph
  0 high/critical, 5 moderate**. Ignored artifacts:
  `build/t173-audit-prod-final.json`, `build/t173-audit-final.json`.
  pnpm returned exit 1 for residual advisories, including with audit-level high;
  the exit is retained and severity counts inspected explicitly. No clean-audit
  or vulnerability-free claim is made. Findings are time-specific snapshots.

Native smoke used only `supplybiz_service_area_test`, synthetic fixtures and the
existing bounded load harness. No grants/migrations or live provider delivery;
own app/DB handles and private storage were cleaned up, existing services/phone
preserved. Report: `apps/api/build/t173-http-smoke.json`. Mocked service/provider
unit checks are not full live journeys or immutable-ledger DB-privilege proof.

## Open findings and unavailable checks

| Open moderate finding | Disposition for technical architect/release reviewer |
|---|---|
| [file-type ASF loop](https://github.com/advisories/GHSA-5v7r-6r5c-r473), [ZIP bomb](https://github.com/advisories/GHSA-j47w-4g3g-c36v) | Nest dependency; current bounded busboy media routes do not use Nest FileTypeValidator/FileInterceptor. Still open: validate compatible parent/file-type migration and reachability before release. |
| [Nest ConsoleLogger injection](https://github.com/advisories/GHSA-36xv-jgw5-4q75) | Fix needs core >=11.1.18; current API installs structured Pino/redacted diagnostics. Retain finding; validate Nest major migration rather than force unsupported combinations. |
| [glob cancellation](https://github.com/advisories/GHSA-3g3m-2fjr-6pw4), [minimatch amplification](https://github.com/advisories/GHSA-g3hv-75wg-m249) | Build-tool dependencies; patched majors change APIs. Parent-tool remediation/release risk review required. |

No moderate finding is silently waived. Installed pnpm is 11.10.0 versus declared
9.12.0; pins are mirrored in workspace YAML (11) and package.json (9). Canonical
version probing refused a registry/signature fetch/verification: **canonical
frozen-install reproduction NOT_RUN**. No verification bypass or pmOnFail=ignore
was set. Resolve trusted canonical tooling before release.

CodeQL/Semgrep/MobSF/ZAP CLIs were unavailable: comprehensive SAST, APK/native SDK
scanning and staging DAST are NOT_RUN for G6. Native ledger operator tests require
the separately configured operator URL; grants were not weakened to run them.
Independent external pen-test scheduling is DEFERRED (SR-06), iOS is DEFERRED
(ADR-025). This focused review is not a comprehensive threat model or pen test.

## Executed commands

Root: `pnpm.cmd install --no-frozen-lockfile`; `pnpm.cmd audit --prod --json`;
`pnpm.cmd audit --json`; `pnpm.cmd audit --prod --audit-level=high --json`;
`flutter pub outdated --json`; `git diff --check`.

From apps/api, CONFIG_TEST_DATABASE_URL/NATIVE_TEST_DATABASE_URL privately point
to the isolated DB, as documented in T-171 (providers disabled):

```powershell
.\node_modules\.bin\jest.cmd --runInBand --testTimeout=180000 --runTestsByPath src/common/request-id.middleware.spec.ts src/common/problem-details.diagnostics.spec.ts src/modules/auth/sessions.http.spec.ts src/modules/content/app-config.spec.ts src/modules/notifications/fcm.service.spec.ts src/modules/subscriptions/subscription-generation.policy.spec.ts test/api-load.postgres.spec.ts
.\node_modules\.bin\jest.cmd --runInBand --testTimeout=60000 --runTestsByPath src/storage/local-storage.service.spec.ts src/modules/ledger/ledger.service.spec.ts
.\node_modules\.bin\tsc.cmd --noEmit
.\node_modules\.bin\tsc.cmd -p tsconfig.build.json
.\node_modules\.bin\eslint.cmd src test scripts jest.config.ts --max-warnings=0
```

apps/admin (existing node_modules/.bin): `tsx --test test/security.test.ts test/management.test.ts test/kyc.test.ts`;
`next typegen`; `tsc --noEmit`; `eslint . --max-warnings=0`; `next build --webpack`.

apps/mobile: `flutter test --no-pub test/core/storage/secure_store_test.dart test/core/router/deep_links_test.dart test/core/router/guards_test.dart test/core/network/network_client_test.dart`.

## Manual verification

1. Resolve canonical pnpm verification, reproduce frozen install/fresh audits,
   and review all five remaining moderate advisories.
2. On test/staging, check foreign-owner denial, expired/revoked sessions, invalid
   input and immutable/replayed mutations with synthetic accounts.
3. Check admin HTTPS cookies, cross-origin/CSRF/role-protected document denials,
   and malformed request-ID correlation in redacted logs.
4. Complete the NOT_RUN release checks; record manual PASS separately from
   G4/G6/release approval, after reviewing the remaining findings.
