# ENVIRONMENT SETUP

| Field | Value |
|---|---|
| Status | Draft v0.1 (commands finalized in T-001) |
| Owner | DevOps Engineer |
| Last updated | 2026-10-19 |
| Related | [FOLDER_STRUCTURE](../04-architecture/FOLDER_STRUCTURE.md), [GIT_CICD](GIT_CICD.md), [AGENTS §5](../05-ai-development/AGENTS.md#5-commands-canonical-finalized-in-t-001) |

## 1. Prerequisites
| Tool | Version | Notes |
|---|---|---|
| macOS (for iOS) / Linux / Windows (Android + backend only) | — | iOS builds require macOS |
| FVM | latest | Flutter 3.35.7 pinned in `.fvmrc`; Dart 3.9 required by the workspace/Melos lockfile |
| Flutter / Dart | pinned | via `fvm flutter` |
| Xcode | latest stable supported by pinned Flutter | + CocoaPods |
| Android Studio + SDK | latest stable; compileSdk = latest; minSdk 24 | JDK 17 |
| Node.js | Active LTS (pinned in `.nvmrc`) | via nvm/fnm |
| Java | 17+ | Required by OpenAPI Generator for Dart client output |
| pnpm | pinned via `packageManager` field (corepack) | |
| Docker Desktop / Colima | latest | Postgres, Redis, MinIO |
| melos | pinned dev dependency | `dart pub global activate melos` |
| Firebase CLI + FlutterFire CLI | latest | for config generation (per flavor) |
| Fastlane (Ruby via bundler) | pinned in Gemfile | release builds |

## 2. First-Time Setup
```bash
git clone <repo-url> supplybiz && cd supplybiz
tools/bootstrap.sh          # fvm install, melos bootstrap, pnpm install, docker compose up -d
cp apps/api/.env.example apps/api/.env          # fill local values (no real secrets needed for dev)
cp apps/admin/.env.example apps/admin/.env.local
pnpm --filter api prisma migrate dev && pnpm --filter api prisma db seed
tools/codegen.sh            # OpenAPI → Dart/TS clients
melos run build_runner      # freezed/riverpod/drift codegen
```

## 3. Running
| Component | Command |
|---|---|
| API | `pnpm --filter api dev` (http://localhost:3000/api/v1, Swagger at /docs in dev only) |
| Worker | `pnpm --filter api dev:worker` |
| Admin | `pnpm --filter admin dev` (http://localhost:3001) |
| Infra connectivity smoke check (API) | `pnpm --filter api infra:check` |
| Mobile (Android emulator) | `cd apps/mobile && fvm flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json` |
| Mobile (iOS simulator) | `cd apps/mobile && fvm flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json` |
Dev conveniences: `ConsoleOtp` logs OTP to API console (dev only; disabled by config guard in staging/prod); fixed test OTP `123456` for allow-listed test numbers in **dev & staging only**; `FakeKyc` auto-verifies PAN ending in `F` and fails others (for testing).

Android emulator reaches host API at `10.0.2.2`; set in `config/dev.json`.

## 4. Environment Variables & Secrets
### 4.1 API (`apps/api/.env`)
| Key | Example (dev) | Secret? |
|---|---|---|
| `NODE_ENV` | development | no |
| `PORT` | 3000 | no |
| `DATABASE_URL` | postgresql://sb:sb@localhost:5432/supplybiz | yes (prod) |
| `REDIS_URL` | redis://localhost:6379 | yes (prod) |
| `HEALTHCHECK_STRICT` | false | no |
| `RATE_LIMIT_TTL_SECONDS` | 60 | no |
| `RATE_LIMIT_MAX_REQUESTS` | 120 | no |
| `OTEL_ENABLED` | false | no |
| `JWT_PRIVATE_KEY` / `JWT_PUBLIC_KEYS` (JWKS) | generated dev keys | yes |
| `OTP_PEPPER` | random | yes |
| `OTP_PROVIDER` | console \| sms_<vendor> \| … | no |
| `SMS_API_KEY`, `SMS_SENDER_ID`, `SMS_DLT_TEMPLATE_ID` | — | yes |
| `WHATSAPP_TOKEN`, `WHATSAPP_PHONE_ID`, `WHATSAPP_TEMPLATE` | — | yes |
| `KYC_PROVIDER`, `KYC_API_KEY`, `KYC_WEBHOOK_SECRET` | fake | yes |
| `BILLING_PROVIDER`, `BILLING_KEY_ID`, `BILLING_KEY_SECRET`, `BILLING_WEBHOOK_SECRET` | fake | yes |
| `STORAGE_ENDPOINT`, `STORAGE_BUCKET_MEDIA`, `STORAGE_BUCKET_KYC`, `STORAGE_ACCESS_KEY`, `STORAGE_SECRET_KEY` | MinIO | yes |
| `KMS_KEY_ID` / `FIELD_ENCRYPTION_KEY` (dev only) | — | yes |
| `FCM_SERVICE_ACCOUNT_JSON` | — | yes |
| `GEO_PROVIDER`, `GEO_API_KEY` | fake | yes |
| `SENTRY_DSN`, `OTEL_EXPORTER_OTLP_ENDPOINT` | — | DSN semi-public |
| `TEST_OTP_ALLOWLIST` | +919999900001,… (dev/staging only) | no |
Validated at startup with zod; app refuses to start on missing/invalid keys or if `ConsoleOtp`/test OTP enabled in production.

### 4.2 Admin (`apps/admin/.env.local`)
`API_BASE_URL`, `SESSION_SECRET` (secret), `SENTRY_DSN`.

### 4.3 Mobile (`apps/mobile/config/<flavor>.json`, **non-secret only**)
`API_BASE_URL`, `LINK_DOMAIN`, `ENV_NAME`, `FIREBASE_ENABLED`, `SENTRY/Crashlytics flags`, `MAPS_API_KEY` (restricted by package/bundle ID — treated as public), `CERT_PINS` (release). Firebase is disabled in the checked-in flavor configs. To enable it for a configured Firebase project, set `FIREBASE_ENABLED` to `true` and provide that flavor's native config: `android/app/src/<flavor>/google-services.json` and `ios/config/<flavor>/GoogleService-Info.plist`. Android applies Google Services when any flavor file exists and processes only flavors with a configuration file. Never create placeholder Firebase credentials; a Firebase-enabled app without valid native config displays a startup error.

Android application IDs are `in.supplybiz.mobile.dev`, `in.supplybiz.mobile.staging`, and `in.supplybiz.mobile`. iOS uses matching bundle IDs and shared `dev`, `staging`, and `prod` schemes.

### 4.4 Secrets management
| Environment | Storage |
|---|---|
| Local | `.env` files (git-ignored), dev-only values |
| CI | GitHub Environments secrets; cloud via OIDC |
| Staging/Prod | Cloud secret manager (provider TBD Q-02); injected at runtime; rotation policy 90 days for keys, immediate on suspicion |
| Signing | Android upload keystore & iOS certs/API key in CI secrets (base64) + offline backup in password manager owned by PO |

## 5. Build Instructions
| Target | Command |
|---|---|
| Android AAB (prod) | `fvm flutter build appbundle --flavor prod -t lib/main_prod.dart --dart-define-from-file=config/prod.json --obfuscate --split-debug-info=build/symbols` |
| iOS IPA (prod) | `fvm flutter build ipa --flavor prod -t lib/main_prod.dart --dart-define-from-file=config/prod.json --obfuscate --split-debug-info=build/symbols` |
| API image | `docker build -f apps/api/Dockerfile -t supplybiz-api:<sha> .` |
| Admin image | `docker build -f apps/admin/Dockerfile -t supplybiz-admin:<sha> .` |
Normally run via Fastlane/CI only ([GIT_CICD §5](GIT_CICD.md#5-cd-pipelines)).

## 6. Troubleshooting
| Symptom | Fix |
|---|---|
| `pod install` fails | `cd ios && pod repo update && pod install`; ensure Xcode CLI tools selected |
| Generated files missing | `melos run build_runner` / `tools/codegen.sh` |
| Android can't reach API | Use `10.0.2.2`; allow cleartext only in dev network config |
| Prisma drift error | `pnpm --filter api prisma migrate reset` (dev only — destroys local data) |
| Push not received in dev | Check flavor Firebase config, notification permission, device token registered via `/me/devices/current` |
