# CODING STANDARDS

| Field | Value |
|---|---|
| Status | Draft v0.1 |
| Owner | Technical Architect |
| Last updated | 2026-10-19 |
| Related | [AGENTS](../05-ai-development/AGENTS.md), [FOLDER_STRUCTURE](../04-architecture/FOLDER_STRUCTURE.md), [GIT_CICD](GIT_CICD.md) |

## 1. General
- Readability over cleverness; small functions (< 40 lines), small files (< 400 lines, screens may reach 500 with extracted widgets).
- No dead code, commented-out code, or TODOs without a task ID (`// TODO(T-123): …`).
- Comments explain *why*, not *what*.
- Fail fast at boundaries (DTO validation, form validation); trust internal types afterwards.
- All money in paise (`int`/`bigint`), all business dates in IST, all timestamps UTC.

## 2. Dart / Flutter
| Topic | Standard |
|---|---|
| Lints | `very_good_analysis` (or `flutter_lints` + strict rules) with `strict-casts`, `strict-inference`, `strict-raw-types`; `dart format` line length 100 |
| Naming | Files `snake_case.dart`; classes `UpperCamelCase`; providers `xxxProvider`; controllers `XxxController`; screens `XxxScreen`; private widgets `_Xxx` |
| Immutability | Entities/state with `freezed`; prefer `final`; collections unmodifiable |
| Null safety | No `!` except after explicit checks; prefer pattern matching |
| State | Riverpod generator (`@riverpod`); `AsyncValue` for async; no `setState` except purely local UI state (animations, text controllers) |
| Widgets | `const` constructors; extract widgets instead of helper methods returning widgets; keep `build` pure |
| Errors | Repositories return `Future<T>` and throw `AppFailure`; controllers catch to `AsyncError`; never swallow errors |
| Async | Always `await` or explicitly `unawaited()`; cancel subscriptions in `ref.onDispose` |
| Navigation | Typed routes only; no `Navigator.push` with anonymous routes in features |
| Strings | `context.l10n.key`; no hard-coded user-facing strings |
| Assets | Referenced via generated constants (`flutter_gen`) |
| Platform code | Only in `core/` or plugins; features stay platform-agnostic |
| Tests | `test/` mirrors `lib/`; names `xxx_test.dart`; use `mocktail`; widget tests with `ProviderScope` overrides |

Example controller:
```dart
@riverpod
class OrderDetailController extends _$OrderDetailController {
  @override
  Future<Order> build(String orderId) =>
      ref.watch(ordersRepositoryProvider).getOrder(orderId);

  Future<void> accept() async {
    final current = state.requireValue;
    state = const AsyncLoading<Order>().copyWithPrevious(state);
    state = await AsyncValue.guard(() => ref
        .read(ordersRepositoryProvider)
        .transition(current.id, to: OrderStatus.accepted, version: current.version));
  }
}
```

## 3. TypeScript / NestJS
| Topic | Standard |
|---|---|
| Config | `strict: true`, `noUncheckedIndexedAccess: true`; ESLint (typescript-eslint strict, eslint-plugin-boundaries), Prettier |
| Naming | Files `kebab-case.ts` (`orders.service.ts`); classes `PascalCase`; DTOs `XxxDto`; enums `PascalCase` with `UPPER_SNAKE` members |
| Layers | Controller (HTTP only) → Service (business rules) → Repository (Prisma). No Prisma in controllers |
| Validation | `class-validator` DTOs + global `ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true })` |
| Errors | Throw `BusinessRuleError(code, detail)` / Nest HTTP exceptions; global filter → Problem Details |
| Transactions | `prisma.$transaction` for multi-write; ledger writes always transactional |
| SQL | Prisma or `$queryRaw` tagged templates only (parameterized); never string concatenation |
| Async | No floating promises (`@typescript-eslint/no-floating-promises`) |
| Money | `bigint` or `number` integers ≤ 2^53 validated; helper `Money` utils; no floats |
| Time | `date-fns-tz` / `Temporal` polyfill with `Asia/Kolkata`; inject `Clock` for testability |
| Logging | Injected pino logger; structured fields; redaction config |
| Tests | `*.spec.ts` next to source (unit); `test/*.e2e-spec.ts` (Supertest + Testcontainers) |

## 4. Next.js Admin
- Server Components by default; Client Components only for interactivity.
- Data access through generated TS client in route handlers/server actions; never expose admin tokens to the browser.
- Forms with `react-hook-form` + `zod`; tables with TanStack Table; RBAC via `<Can>`.
- Sensitive document viewers: no download button, watermark overlay, audit call before display.

## 5. Reusable Components
- Mobile reusable UI → `packages/ui_kit` (prefix `Sb`), with golden tests and dartdoc one-liners.
- Cross-feature mobile logic → `core/`; never copy-paste between features.
- Backend shared utils → `common/` (money, time, pagination, idempotency, guards).
- Promote code to shared only when used by ≥ 2 features.

## 6. Error-Handling Rules (summary)
1. Validate at boundaries; map to documented error codes.
2. Never expose stack traces or provider error text to users.
3. Log once at the boundary where handled (no duplicate logging).
4. Every catch either handles, rethrows with context, or reports — never empty.

## 7. Security Coding Rules
- AuthZ check in service layer for every resource access (ownership), not only controller guards.
- No PII in logs/analytics; use redaction helpers.
- Validate file uploads server-side (type, size, magic bytes).
- Use constant-time comparison for OTPs/signatures.
- Dependencies pinned via lockfiles; Renovate/Dependabot updates reviewed.

## 8. Code Review Rules
| Check | Blocking? |
|---|---|
| Linked FR/US/T IDs and tests with TC IDs | Yes |
| CI green (lint, tests, coverage, OpenAPI diff, security scans) | Yes |
| AuthZ / IDOR covered for new endpoints | Yes |
| Money/time conventions | Yes |
| l10n EN+HI, a11y semantics | Yes |
| Generated code not hand-edited | Yes |
| Docs updated for behaviour change | Yes |
| Naming, structure, readability | Non-blocking unless severe |
- At least 1 approving review (2 for `ledger`, `auth`, `kyc`, `subscriptions` generation, infra).
- Reviewer may request tests for any untested branch.
