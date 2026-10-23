# FOLDER STRUCTURE

| Field | Value |
|---|---|
| Status | Draft v0.1 |
| Owner | Technical Architect |
| Last updated | 2026-10-19 |
| Related | [MODULE_DESIGN](MODULE_DESIGN.md), [CODING_STANDARDS](../06-development/CODING_STANDARDS.md), [ENVIRONMENT_SETUP](../06-development/ENVIRONMENT_SETUP.md) |

## 1. Purpose
Canonical monorepo layout (ADR-003). Agents must place new files according to this document; deviations require an ADR.

## 2. Repository Root
```
supplybiz/
├── README.md                    # Project entry point & doc index
├── AGENTS.md                    # Pointer to docs/05-ai-development/AGENTS.md
├── docs/                        # All documentation (this set)
├── contracts/
│   └── openapi.yaml             # API contract (generated from API, committed, CI-diffed)
├── apps/
│   ├── mobile/                  # Flutter app (Android + iOS)
│   ├── api/                     # NestJS API + worker
│   └── admin/                   # Next.js admin panel
├── packages/
│   ├── ui_kit/                  # Flutter design system (Sb* widgets, tokens)
│   ├── api_client/              # Generated Dart client (do not edit by hand)
│   └── ts-client/               # Generated TypeScript client for admin
├── infra/
│   ├── docker/                  # docker-compose for local Postgres, Redis, MinIO
│   └── terraform/               # IaC (provider TBD, Q-02)
├── tools/                       # scripts: codegen, seed, release helpers
├── .github/workflows/           # CI/CD pipelines
├── melos.yaml                   # Dart workspace (mobile + packages)
├── pnpm-workspace.yaml          # TS workspace (api, admin, ts-client)
├── turbo.json                   # TS task pipeline
├── .fvmrc                       # Pinned Flutter version
├── .nvmrc                       # Pinned Node version
└── .editorconfig
```

## 3. Mobile (`apps/mobile`)
```
apps/mobile/
├── lib/
│   ├── main_dev.dart | main_staging.dart | main_prod.dart   # flavor entry points
│   ├── bootstrap.dart           # init Firebase, DB, DI, error zones
│   ├── app/
│   │   ├── app.dart             # MaterialApp.router, theme, locale
│   │   └── router/              # routes.dart, guards.dart, deep_links.dart, shells/
│   ├── core/                    # see MODULE_DESIGN §3.1
│   │   ├── config/ network/ storage/ sync/ session/ router/
│   │   ├── l10n/ analytics/ logging/ crash/ permissions/ upi/
│   │   └── utils/               # money.dart (paise), dates.dart (IST), validators.dart
│   ├── features/
│   │   ├── common/{auth,notifications,settings}/
│   │   ├── vendor/{onboarding,dashboard,products,orders,quick_sale,customers,
│   │   │          subscriptions,deliveries,khata,reports,plans,settings}/
│   │   └── customer/{home,discovery,cart,orders,subscriptions,khata,money,
│   │                bills,grocery_assist,profile}/
│   └── l10n/
│       ├── app_en.arb
│       └── app_hi.arb
├── test/                        # mirrors lib/ (unit + widget + golden)
├── integration_test/            # Patrol E2E flows
├── android/ (flavors: dev, staging, prod)
├── ios/ (schemes: dev, staging, prod)
├── assets/{fonts,images,icons}/
├── config/{dev,staging,prod}.json   # non-secret --dart-define-from-file
├── analysis_options.yaml
└── pubspec.yaml
```

### 3.1 Feature folder template
```
features/vendor/orders/
├── orders.dart                  # public barrel: routes + public providers only
├── data/
│   ├── orders_remote_ds.dart
│   ├── orders_local_ds.dart     # drift DAO usage
│   ├── orders_repository_impl.dart
│   └── mappers.dart             # DTO ↔ entity
├── domain/
│   ├── order.dart               # freezed entity
│   ├── order_status.dart
│   └── orders_repository.dart   # abstract interface
└── presentation/
    ├── order_list_screen.dart   # S-V-08
    ├── order_detail_screen.dart # S-V-09
    ├── widgets/
    └── controllers/             # Riverpod notifiers (*_controller.dart)
```
Screen files include the screen ID in a top comment, e.g. `// S-V-09 Order details`.

## 4. Backend (`apps/api`)
```
apps/api/
├── src/
│   ├── main.ts                  # HTTP entry
│   ├── worker.ts                # BullMQ worker + scheduler entry
│   ├── app.module.ts
│   ├── config/                  # typed config, env validation (zod)
│   ├── common/                  # errors, guards, interceptors, pagination, money, time, outbox
│   ├── integrations/            # adapters: otp, kyc, billing, bbps, push, geo, storage
│   ├── modules/
│   │   └── <module>/
│   │       ├── <module>.module.ts
│   │       ├── <module>.controller.ts        # mobile endpoints
│   │       ├── <module>.admin.controller.ts  # admin endpoints (if any)
│   │       ├── <module>.service.ts
│   │       ├── <module>.repository.ts
│   │       ├── dto/                           # class-validator DTOs
│   │       ├── jobs/                          # BullMQ processors
│   │       └── <module>.service.spec.ts
│   └── prisma/
│       ├── schema.prisma
│       ├── migrations/
│       └── seed.ts
├── test/                        # e2e (supertest + testcontainers)
└── Dockerfile
```

## 5. Admin (`apps/admin`)
```
apps/admin/
├── src/
│   ├── app/                     # App Router routes (S-A-xx)
│   ├── components/              # shadcn/ui based
│   ├── lib/                     # api client wrapper, auth, rbac
│   └── i18n/                    # EN (HI optional, TBD)
├── tests/                       # Playwright
└── Dockerfile
```

## 6. File Responsibility Rules
| Rule | Detail |
|---|---|
| Generated code | `packages/api_client`, `packages/ts-client`, `*.g.dart`, `*.freezed.dart` are generated — never hand-edit; regenerate via `tools/codegen.sh` |
| Secrets | Never in repo; `.env.example` documents keys only |
| Docs | Requirement or design changes update `docs/` in the same PR |
| Tests | Live next to code (TS) or mirrored under `test/` (Dart) |
