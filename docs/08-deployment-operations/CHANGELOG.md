# CHANGELOG

All notable changes to this project are documented here. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow SemVer (mobile `mobile-vX.Y.Z`, API `api-vX.Y.Z`, admin `admin-vX.Y.Z`; documentation `docs-vX.Y`).

## [Unreleased]
### Changed — approved scope and platform sequence, 2026-10-29
- Recorded user approval of all SR-01–SR-06 in ADR-024; applied deferred task/requirement/screen/test status, manual KYC and plan assignments, forms/GPS, table/CSV reports and basic diagnostics. Added DELIVERY_SCOPE applicability index and rebaselined G0–G6.
- ADR-025 makes all current mobile builds/runs/testing/signing/distribution Android-only. Preserved iOS design/source/configuration; T-185 validates iOS only after actual Android production release T-179.
- Documentation only: no application code, runtime config, manifests, dependencies, generated contracts or test results changed. Earlier pending-approval entries below are history superseded by this approval.

### Changed — delivery planning, 2026-10-29
- Documentation-only ADR-023 baseline: English, native PostgreSQL/processes, secure local-file storage, task build/lint/smoke and comprehensive module gates.
- Reprioritized dependency-aware tasks, 15-day daily milestones, reconciliation tasks T-180–T-184 and approval-pending scope proposals SR-01–SR-06. No application code, runtime configuration, lockfile or generated client changed.
- Previous implementation entries below are historical evidence, not current requirements. Their removed infrastructure/locale/snapshot dependencies await reconciliation tasks; prior pending snapshot refresh work is superseded, not a current gate.

### Added
- T-009 UI kit implementation (verification in progress): shared design tokens and light theme,
  subset Noto Sans/Devanagari fonts (400–700), localized EN/HI controls, status badges,
  cards, selectors, global states, uploads and accessible bar/pie charts.
  Added component, accessibility and eight catalog golden tests; previously pending visual verification is superseded by T-183 and ADR-023.
- Applied the UI kit theme/localization delegates to the mobile shell. Pinned Flutter
  3.35.7 / minimum Dart 3.9 to match the existing workspace lockfile and golden toolchain.
- Monorepo foundation scaffolding for T-001:
  - Root workspace/tooling files: `.editorconfig`, `.fvmrc`, `.nvmrc`, `package.json`, `pnpm-workspace.yaml`, `turbo.json`, `melos.yaml`.
  - Folder skeleton aligned to `FOLDER_STRUCTURE` for `apps/`, `packages/`, `contracts/`, `infra/`, and `tools/`.
  - `tools/bootstrap.sh` for first-time workspace setup and local infra startup.
  - `tools/codegen.sh` for OpenAPI → TypeScript/Dart client generation.
  - Initial OpenAPI contract at `contracts/openapi.yaml` and placeholder app/package manifests to enable workspace bootstrap.
- Local infrastructure scaffolding for T-002:
  - `infra/docker/docker-compose.yml` for Postgres+PostGIS, Redis, and MinIO with health checks.
  - API-side infra smoke check command `pnpm --filter api infra:check` to verify local connectivity to Postgres, Redis, and MinIO.
  - Expanded `apps/api/.env.example` with MinIO/local storage variables used in development.
- CI workflow scaffolding for T-003:
  - Added GitHub Actions workflows with path filters for mobile, API, and admin checks:
    - `.github/workflows/mobile-ci.yml`
    - `.github/workflows/api-ci.yml`
    - `.github/workflows/admin-ci.yml`
  - Added API `typecheck` script placeholder to support API CI stages.
- API platform skeleton for T-004:
  - Implemented NestJS API bootstrap with typed environment validation, request-id middleware, pino logging, global rate limiting, and RFC 9457 Problem Details error filter.
  - Added health and version endpoints (`/api/v1/health/live`, `/api/v1/health/ready`, `/api/v1/version`) and worker entrypoint.
  - Added API unit/e2e tests validating health readiness response and Problem Details error shape.
- Data layer foundation for T-005:
  - Added Prisma schema v1 for identity and plan/catalog seed tables (`users`, `user_roles`, `consents`, `sessions`, `devices`, `user_preferences`, `admin_users`, `categories`, `plans`, `plan_prices`).
  - Added initial SQL migration under `apps/api/src/prisma/migrations`.
  - Added idempotent Prisma seed script for categories and BRD plan prices (monthly/half-yearly/yearly).
  - Added Prisma generate/migrate/seed scripts in API package scripts.
- Reliability foundation for T-006:
  - Added DB models and migration for `idempotency_keys` and `outbox_events`.
  - Added global idempotency interceptor for mutation requests using `Idempotency-Key` with replay and mismatch handling (`422 IDEMPOTENCY_MISMATCH`).
  - Added worker-side outbox dispatcher service (batch dispatch from pending to dispatched).
  - Added API e2e coverage for TC-500 and TC-501 idempotency behavior.
- Contract/codegen foundation for T-007:
  - Added API-side OpenAPI generation command (`pnpm --filter api openapi:generate`) from Nest controllers.
  - Updated `tools/codegen.sh` to regenerate `contracts/openapi.yaml` before TS/Dart client generation.
  - Updated API CI workflow to install Java, run full codegen (`tools/codegen.sh`), and fail when generated contract/client artifacts drift.
- Flutter app foundation for T-008:
  - Added dev/staging/prod entrypoints, shared bootstrap, environment validation, and a visible startup-error screen.
  - Added Android product flavors and iOS schemes/configurations with distinct application identifiers.
  - Added opt-in Firebase Core initialization with per-flavor native config wiring; Firebase remains disabled until real project files are supplied.
  - Replaced the generated counter demo with a Supply Biz app shell and environment/startup widget tests.

## [docs-v0.1] — 2026-10-19
### Added
- Complete documentation set (Phases 1–5) under `docs/` and root `README.md`.
- Requirement IDs: FR-001–FR-413, NFR-001–NFR-020, RULE-01–RULE-25, US-001–US-405, TC-001–TC-613, T-001–T-189, ADR-001–ADR-022.
### Decided (stakeholder, 2026-10-19)
- Flutter mobile app; NestJS + PostgreSQL backend; single store app in one monorepo.
- Customer v1 scope = all features in source document; vendor v1 excludes staff/delivery boys and support tickets/chat.
- Customer→vendor payments off-platform (recorded only); KYC via API with manual fallback.
- Web admin panel fully documented; status-based tracking (no live GPS) in v1.
- Historical 2026-10-19 baseline: single brand "Supply Biz"; English + Hindi; OTP-only authentication. Language scope is superseded by ADR-023.
### Open
- 35 open questions (SCOPE §8), including billing channel for vendor plans (ADR-015) and cloud provider (ADR-017).
