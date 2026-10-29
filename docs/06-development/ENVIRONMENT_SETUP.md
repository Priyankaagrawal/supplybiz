# ENVIRONMENT SETUP

| Field | Value |
|---|---|
| Status | Draft v0.1 (commands finalized in T-001) |
| Owner | DevOps Engineer |
| Last updated | 2026-10-29 |
| Related | [FOLDER_STRUCTURE](../04-architecture/FOLDER_STRUCTURE.md), [GIT_CICD](GIT_CICD.md), [AGENTS §5](../05-ai-development/AGENTS.md#5-commands-canonical-finalized-in-t-001) |

## 1. Prerequisites
| Tool | Version | Notes |
|---|---|---|
| macOS / Linux / Windows | — | Android/backend/admin current scope; no Apple toolchain needed |
| FVM | latest | Flutter 3.35.7 pinned in `.fvmrc`; Dart 3.9 required by the workspace/Melos lockfile |
| Flutter / Dart | pinned | via `fvm flutter` |
| Android Studio + SDK | latest stable; compileSdk = latest; minSdk 24 | JDK 17 |
| Node.js | Active LTS (pinned in `.nvmrc`) | via nvm/fnm |
| Java | 17+ | Required by OpenAPI Generator for Dart client output |
| pnpm | pinned via `packageManager` field (corepack) | |
| Native PostgreSQL 16 + PostGIS | pinned compatible version | Local service or provisioned development DB; no container runtime |
| melos | pinned dev dependency | `dart pub global activate melos` |
| Firebase CLI + FlutterFire CLI | latest | for config generation (per flavor) |
| Fastlane (Ruby via bundler) | pinned in Gemfile | release builds |

## 2. First-Time Setup
```bash
git clone <repo-url> supplybiz && cd supplybiz
tools/bootstrap.sh          # run after T-182 reconciles it to native PostgreSQL setup
cp apps/api/.env.example apps/api/.env          # fill local values (no real secrets needed for dev)
cp apps/admin/.env.example apps/admin/.env.local
pnpm --filter @supplybiz/api prisma:migrate:dev
pnpm --filter @supplybiz/api prisma:seed
tools/codegen.sh            # OpenAPI → Dart/TS clients
melos run build_runner      # freezed/riverpod/drift codegen
```

## 3. Running
| Component | Command |
|---|---|
| API | `pnpm --filter @supplybiz/api dev` (http://localhost:3000/api/v1, Swagger at /docs in dev only) |
| Worker | `pnpm --filter @supplybiz/api dev:worker` |
| Admin | `pnpm --filter @supplybiz/admin dev` (http://localhost:3001) |
| Infra connectivity smoke check (API) | `pnpm --filter @supplybiz/api infra:check` |
| Mobile (Android emulator) | `cd apps/mobile && fvm flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json` |
Development OTP simulation must never log, expose or retain plaintext OTPs; use injected test delivery sinks. Console simulation is development/test only and rejected in staging/production. No fixed production OTP or invented provider credentials. Provider/KYC fakes are test-only and do not establish live readiness.

Android emulator reaches host API at `10.0.2.2`; set in `config/dev.json`.

## 4. Environment Variables & Secrets
### 4.1 API (`apps/api/.env`)
| Key | Example (dev) | Secret? |
|---|---|---|
| `NODE_ENV` | development | no |
| `PORT` | 3000 | no |
| `DATABASE_URL` | postgresql://sb:sb@localhost:5432/supplybiz | yes (prod) |
| `HEALTHCHECK_STRICT` | false | no |
| `RATE_LIMIT_TTL_SECONDS` | 60 | no |
| `RATE_LIMIT_MAX_REQUESTS` | 120 | no |
| `OTEL_ENABLED` | false | no |
| `AUTH_SIGNING_PRIVATE_KEY`, `AUTH_SIGNING_KEY_ID`, `AUTH_PREVIOUS_PUBLIC_KEYS` | generated dev keys | yes |
| `OTP_HMAC_PEPPER` (at least 32 random characters) | random | yes |
| `OTP_DELIVERY_MODE` | disabled or console (dev/test only) | no |
| `SMS_API_KEY`, `SMS_SENDER_ID`, `SMS_DLT_TEMPLATE_ID` | — | yes |
| `WHATSAPP_TOKEN`, `WHATSAPP_PHONE_ID`, `WHATSAPP_TEMPLATE` | — | yes |
| `UPLOAD_ROOT` | /var/tmp/supplybiz-dev-uploads (absolute, outside web/source/build roots) | no |
| `UPLOAD_MAX_BYTES`, `UPLOAD_MAX_PIXELS` | 5242880, 20000000 | no |
| `KMS_KEY_ID` / `FIELD_ENCRYPTION_KEY` (dev only) | — | yes |
| `FCM_SERVICE_ACCOUNT_JSON` | — | yes |
| Existing basic crash config (if used) | per configured Android environment | no new advanced telemetry requirement |
| `TEST_OTP_ALLOWLIST` | +919999900001,… (dev/staging only) | no |
Validated at startup with zod; app refuses to start on missing/invalid keys or if console OTP simulation enabled in staging/production.

### 4.2 Admin (`apps/admin/.env.local`)
`API_BASE_URL`, `SESSION_SECRET` (secret), `SENTRY_DSN`.

### 4.3 Mobile (`apps/mobile/config/<flavor>.json`, **non-secret only**)
`API_BASE_URL`, `LINK_DOMAIN`, `ENV_NAME`, `FIREBASE_ENABLED`, basic crash flags; maps/advanced telemetry/pinning configuration is POST-DELIVERY (ADR-024). Firebase is disabled in the checked-in flavor configs. To enable it for a configured Firebase project, set `FIREBASE_ENABLED` to `true` and provide the Android flavor's native config: `android/app/src/<flavor>/google-services.json`; iOS configuration is preserved for T-185 after Android release. Android applies Google Services when any flavor file exists and processes only flavors with a configuration file. Never create placeholder Firebase credentials; a Firebase-enabled app without valid native config displays a startup error.

Android application IDs are `in.supplybiz.mobile.dev`, `in.supplybiz.mobile.staging`, and `in.supplybiz.mobile`. iOS uses matching bundle IDs and shared `dev`, `staging`, and `prod` schemes.

### 4.4 Secrets management
| Environment | Storage |
|---|---|
| Local | `.env` files (git-ignored), dev-only values |
| CI | GitHub Environments secrets; cloud via OIDC |
| Staging/Prod | Cloud secret manager (provider TBD Q-02); injected at runtime; rotation policy 90 days for keys, immediate on suspicion |
| Signing | Android upload keystore (iOS certs/API keys deferred until after Android release) in CI secrets (base64) + offline backup in password manager owned by PO |

## 5. Build Instructions
| Target | Command |
|---|---|
| Android AAB (prod) | `fvm flutter build appbundle --flavor prod -t lib/main_prod.dart --dart-define-from-file=config/prod.json --obfuscate --split-debug-info=build/symbols` |
| API build | `pnpm --filter @supplybiz/api build` |
| Admin build | `pnpm --filter @supplybiz/admin build` (real implementation in T-150) |
Normally run via Fastlane/CI only ([GIT_CICD §5](GIT_CICD.md#5-cd-pipelines)).

## 6. Troubleshooting
| Symptom | Fix |
|---|---|
| Generated files missing | `melos run build_runner` / `tools/codegen.sh` |
| Android can't reach API | Use `10.0.2.2`; allow cleartext only in dev network config |
| Prisma drift error | `pnpm --filter @supplybiz/api prisma migrate reset` (dev only — destroys local data) |
| Push not received in dev | Check flavor Firebase config, notification permission, device token registered via `/me/devices/current` |

## 7. Baseline reconciliation and local files
These instructions define the ADR-023 target. Existing scripts/config examples are unchanged by this documentation revision; T-180/T-182/T-184 must reconcile them before native startup is claimed working. Inspect scripts before executing; current API lint and all admin checks are placeholders, not passing validation.

Provision native PostgreSQL/PostGIS using the host's normal service manager, create a dedicated application database/user, set DATABASE_URL locally, then apply existing Prisma migration/seed scripts. Use a different test database for destructive test fixtures. Configure an absolute persistent UPLOAD_ROOT and restricted owner permissions before media work; use LOCAL_FILE_STORAGE for validation, access and backup requirements. Production has no upload-root fallback. Workers use the same PostgreSQL/database clock, durable job/outbox rows and supervised restart. No cloud-upload access keys are required. Never publish local secrets.

## 8. Android-first active setup (ADR-025)
List Android devices with `fvm flutter devices`; select the Android device explicitly with `-d <android-device-id>` in the documented run command. Build/test only Android dev/staging/prod flavors as relevant. Do not start an iOS simulator, run iOS builds/tests or require Xcode/CocoaPods, Apple accounts, APNs keys, provisioning profiles or iOS CI runners now. Preserve existing iOS files/configuration without validating them. T-185 starts only after actual Android production release T-179.

Post-Android-release reference: iOS work will require a supported macOS/Xcode/CocoaPods setup, real signing and Firebase/APNs configuration, then native storage, UPI/deep links/VoiceOver/E2E checks. These are not bootstrap prerequisites for current delivery.

Approved SR scope: KYC/billing/maps/recognition/BBPS/campaign/advanced telemetry credentials are not active environment requirements. Do not create placeholder credentials or install future provider SDKs. Existing examples/source are reconciled only by authorized T-182/T-183 implementation; shared encryption and FCM/SMS configuration remains required where used.
