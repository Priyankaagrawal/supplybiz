# CHANGELOG

All notable changes to this project are documented here. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow SemVer (mobile `mobile-vX.Y.Z`, API `api-vX.Y.Z`, admin `admin-vX.Y.Z`; documentation `docs-vX.Y`).

## [Unreleased]

- T-153 (READY_FOR_VERIFY, 2026-11-10): permission-checked admin category create/edit/availability/order/product types, generated-client server forms, CSRF, atomic retry/audit persistence and vendor-reference protection; regenerated API clients. Seven native HTTP/PostgreSQL/production Next.js checks, four admin security checks, two runtime checks, four runner guards, API lint/typecheck/build, admin lint/TypeScript/build and Dart client analysis pass. Prior permission blocker resolved; manual browser/keyboard/200%/PASS, deployed HTTPS and G0/G1 remain pending. See admin README for commands and handoff.

- T-025 (READY_FOR_VERIFY, 2026-11-10): vendor More → Service area form for shop address/coordinates and radius OR additional pincodes, optional foreground Android GPS with manual fallback, generated-client saves, encrypted interrupted-request recovery and server re-verification errors. Nine focused checks, clean analysis, Android dev APK build/install, two native encrypted-retry/form/200%-text/location-channel smoke checks and four runner guards pass. Previous Gradle/device blockers resolved; mobile HTTP responses simulated. Live API/DB, GPS fix/permission prompts, TalkBack/manual PASS and G0/G1 pending; see mobile README; iOS deferred.

- T-023 (READY_FOR_VERIFY, 2026-11-10): owned, idempotent service-area radius/pincode configuration with PostGIS radius OR pincode coverage and regenerated clients. Windows storage now validates private ACLs for directories/media while preserving POSIX checks. Eleven native HTTP/PostGIS checks, six storage/ACL checks, two runtime smoke checks, four runner guards and API/client checks pass. Manual PASS and G0/G1 pending; see API README.

- T-151 (READY_FOR_VERIFY, 2026-11-10): OPS/SUPER_ADMIN manual KYC queue/case screens, masked account/PAN summaries, private watermarked document viewer and reason-required CSRF/idempotent decisions through the server-side generated client. Ten focused native KYC/API/production Next.js checks, four admin security checks, two native runtime checks, four runner guards and API/admin lint/typecheck/build pass. Manual browser/PDF/accessibility/PASS, deployed HTTPS and G0/G1 remain pending; providers/push NOT_RUN. See admin README handoff.

- T-024 (READY_FOR_VERIFY, 2026-11-10): Android vendor category/business/KYC/status screens use existing generated APIs, encrypted resumable drafts with v1→v2 migration, durable form retry keys, private uploads/previews, manual Aadhaar image masking and FLAG_SECURE. Manual-review/rejection/resubmission and unverified status guidance are wired. Twenty-two focused checks, clean analysis, Android dev build and native encrypted-storage/security smoke pass; HTTP responses in mobile checks are simulated. Live API/DB, SAF/PDF interaction, TalkBack/manual PASS and G0/G1 remain pending; iOS deferred. See mobile README handoff.

- T-022 (READY_FOR_VERIFY, local API): manual KYC submission/rejection/resubmission/approval with encrypted PAN/bank input, owned document attachments, OPS/SUPER_ADMIN authorization, concurrent/restart-safe replay, immutable review evidence, transactional audit and durable in-app notices; regenerated clients. Nine native KYC checks, two runtime checks and lightweight API/client/consumer checks pass. Manual PASS and G0/G1 pending; push is NOT_RUN and staging/production KYC writes fail closed pending KMS encryption. See API README handoff.

- T-152 (READY_FOR_VERIFY): append-only audit storage, atomic redacted admin-account/auth/private-document history, historical event backfill and SUPER_ADMIN-only S-A-16 viewer with filters/cursor pagination; regenerated clients. Six focused native audit checks (including production Next.js/API/DB smoke), lightweight API/admin/client checks and runner guards pass. Manual browser/accessibility/PASS and G1 pending; retention remains Q-20. See admin README for evidence and verification steps.

- T-021 (READY_FOR_VERIFY): persisted vendor category/business onboarding with validated coordinates/PostGIS, owned shop-photo attachment, settings defaults, resumable step/data, atomic owner-scoped replay and regenerated clients. Eight focused native HTTP/DB checks, two runtime smoke checks, build/lint/typecheck and client checks pass; manual PASS and G0/G1 pending.
### Added — T-020 (ready for manual verification), 2026-11-04
- Private multipart media uploads with bounded image/PDF validation, image EXIF stripping, durable metadata, owner-scoped concurrent/restart idempotency, compensated writes and bounded orphan cleanup. Added owner reads and permission-checked admin document reads with immutable access audit; regenerated clients.
- ADR-027 excludes malware scanning and automated masking validation. Nine focused native HTTP/DB/files checks and API/client lightweight checks pass; manual PASS, owning-task business attachment/UI integration and G1 remain pending. See API README for exact commands and manual steps.

### Added — T-150 (ready for manual verification), 2026-11-04
- Runnable Next.js admin password/TOTP enrolment/login/logout with PostgreSQL sessions, shared lockout, encrypted secrets, CSRF-protected BFF cookies, default-deny ADR-026 permissions and immutable auth events. Added operator Argon2id/breach-checked provisioning, generated clients and real admin checks.
- Focused API/admin/native checks and production Next.js → API → PostgreSQL form smoke pass. Manual browser/accessibility/HTTPS verification, live breach-provider provisioning and G1 remain pending; setup/evidence in the admin README.

### Changed — approved admin permission policy, 2026-11-04
- ADR-026 resolves Q-25 with SUPER_ADMIN/OPS/SUPPORT/FINANCE grants, default-deny API/UI enforcement and explicit sensitive-operation restrictions. Updated scope, security, requirements, acceptance criteria and T-150 references; production admin domain remains Q-33 and does not block localhost development. Documentation only; task statuses and implementation evidence are unchanged.

### Added — T-017 (ready for manual verification), 2026-11-04
- Persisted public API mobile config, Android version guard/426, generated clients, offline policy cache and blocking accessible update screen with Play intent. Resume/four-minute refresh and retry supported; no experimentation dependency. API/DB and Android focused checks pass; manual PASS and module gates pending; iOS deferred.

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
