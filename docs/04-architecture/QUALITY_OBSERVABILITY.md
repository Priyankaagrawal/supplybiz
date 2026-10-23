# QUALITY & OBSERVABILITY

| Field | Value |
|---|---|
| Status | Draft v0.1 |
| Owner | Technical Architect + DevOps |
| Last updated | 2026-10-19 |
| Related | [ARCHITECTURE](ARCHITECTURE.md), [DEPLOYMENT_OPERATIONS](../08-deployment-operations/DEPLOYMENT_OPERATIONS.md), [PRD §6](../01-business/PRD.md#6-success-metrics) |

## 1. Purpose
Error handling, logging, analytics, crash reporting, performance monitoring and alerting across mobile, API, worker and admin.

## 2. Error Handling

### 2.1 Mobile
| Layer | Rule |
|---|---|
| Data | Convert `DioException`/DB errors to sealed `AppFailure` (`Network`, `Timeout`, `Unauthorized`, `Forbidden(code)`, `NotFound`, `Conflict(code)`, `Validation(fieldErrors)`, `BusinessRule(code)`, `Server`, `Unknown`) |
| Presentation | Map `AppFailure` → localized message via `failure.toMessage(l10n)`; `code` from API maps to specific strings (fallback to `title`) |
| Global | `runZonedGuarded` + `FlutterError.onError` + `PlatformDispatcher.onError` → Crashlytics (non-fatal for handled, fatal for uncaught) |
| Retries | Auto-retry idempotent GETs (2×, backoff) on network/5xx; mutations retry only via outbox or explicit user action |
| UX | Never show raw error text or stack traces; always provide next action |

### 2.2 API
- Global exception filter → Problem Details ([API_SPECIFICATION §3](API_SPECIFICATION.md#3-error-model-rfc-9457-problem-details)).
- Domain errors are typed (`BusinessRuleError(code)`), never generic `Error`.
- 5xx responses log full context server-side with `requestId`; response hides internals.
- External provider failures → `DEPENDENCY_UNAVAILABLE`, circuit breaker (opossum) per provider.

## 3. Logging
| Aspect | Mobile | API / Worker | Admin |
|---|---|---|---|
| Library | `logger` wrapper → console (debug) + Crashlytics breadcrumbs (release) | pino (JSON) | Next.js server logs (pino) |
| Levels | debug (dev only), info, warn, error | same | same |
| Correlation | `X-Request-Id` per request; included in breadcrumbs | `requestId`, `traceId`, `userId` (hashed), `vendorId`, `route`, `latencyMs`, `status` | same |
| PII | Forbidden: tokens, OTP, full mobile, Aadhaar/PAN/bank, addresses. Mobile masked `98xxxxxx10` | pino redaction paths enforced + unit test | same |
| Retention | Crashlytics default | 30 days hot, 1 year archive (proposed) | same |

## 4. Analytics
Firebase Analytics (ADR-010). Consent: analytics collection enabled after consent at signup; user can opt out in settings (proposed). `user_id` = hashed internal ID. User properties: `active_role`, `language`, `vendor_category`, `plan_code`, `city`.

| Event | Params | KPI |
|---|---|---|
| `login_otp_sent` / `login_success` | channel | Funnel |
| `role_selected` | role | — |
| `onboarding_step_completed` | step | Onboarding time (G-01) |
| `kyc_submitted` / `kyc_status_changed` | status | KYC rate |
| `product_created` | type | — |
| `order_placed` | vendor_category, items_count, total_bucket, source | Order frequency |
| `order_status_changed` | to, actor_role | Delivery success rate |
| `quick_sale_completed` | mode, paid_bucket | G-02 |
| `subscription_created` / `_paused` / `_skipped` / `_cancelled` | creator_role, days_count | Retention, conversion |
| `holiday_marked` | affected_count_bucket | — |
| `payment_recorded` / `payment_claim_created` / `_confirmed` | method | Payment latency |
| `khata_viewed` | role | Khata usage |
| `report_viewed` / `report_downloaded` | range | G-06 |
| `plan_viewed` / `plan_purchase_started` / `plan_activated` | plan, duration | Upgrade rate |
| `vendor_list_viewed` / `vendor_viewed` | category, sort | Discovery |
| `grocery_parse_completed` | source, matched_count, unmatched_count | R-09 |
| `bill_payment_*` | category | TBD |
| `feature_locked_viewed` | feature | Upsell |
| `offline_action_queued` / `sync_failed` | type, code | Offline health |
Amounts are bucketed; no PII in params. Server-side business KPIs (GMV, active vendors) come from DB-backed admin dashboard (FR-401), not client analytics.

## 5. Crash Reporting
- Mobile: Firebase Crashlytics with dSYM upload (iOS) and `--split-debug-info` symbol upload (Dart obfuscation map) in CI.
- Custom keys: `active_role`, `screen_id`, `app_flavor`, `outbox_pending`.
- API/Admin: Sentry (errors + release tracking), environment-tagged.
- Targets: crash-free sessions ≥ 99.5%, crash-free users ≥ 99.7%, ANR < 0.47% (Play vitals bad-behaviour threshold).

## 6. Performance Monitoring
| Area | Tool | Metrics |
|---|---|---|
| Mobile | Firebase Performance | app start, screen traces (`screen_S-V-05`), HTTP latency/success by endpoint, slow/frozen frames |
| API | OpenTelemetry → metrics backend (provider-native or Grafana stack, TBD Q-02) | RED metrics per route (rate, errors, duration p50/p95/p99), DB query time, pool saturation |
| Worker | OTel + BullMQ metrics | queue depth, job duration, failures, `job_runs` status |
| DB | Managed DB insights | slow queries (> 200 ms), locks, replication lag, storage |
| Synthetic | Uptime checks every 1 min | `/health/live`, `/health/ready`, admin login page |

## 7. Alerting
| Alert | Condition | Severity | Route |
|---|---|---|---|
| API availability | 5xx rate > 2% for 5 min or uptime check fails 3× | P1 | On-call (pager) |
| API latency | p95 > 1 s for 10 min | P2 | On-call |
| Subscription generation | `job_runs` for D+1 not SUCCESS by 22:30 IST | **P1** | On-call + PO |
| OTP delivery | send failure rate > 5% for 10 min or provider error | P1 | On-call |
| OTP abuse | sends/hour > 3× baseline | P2 | Security |
| Queue backlog | notification queue depth > 10k for 10 min | P2 | On-call |
| Crash spike | crash-free sessions < 99% for latest release (Crashlytics velocity alert) | P1 | Mobile lead |
| KYC backlog | MANUAL_REVIEW older than 24 h > 20 | P3 | Ops |
| Plan webhook failures | > 3 in 15 min | P2 | Finance + on-call |
| DB | CPU > 80% 15 min, storage > 80%, replication lag > 60 s | P2 | On-call |
| Certificate / domain expiry | < 21 days | P3 | DevOps |
On-call tooling and rota: TBD.

## 8. Health Endpoints
`GET /health/live` (process), `GET /health/ready` (DB, Redis reachable), `GET /version` (git SHA, build time). Not exposed through public docs; rate-limited.

## 9. Quality Gates (summary)
Defined in [GIT_CICD §4](../06-development/GIT_CICD.md#4-ci-pipelines) and [TEST_STRATEGY](../07-testing/TEST_STRATEGY.md): lint clean, tests green, coverage thresholds (NFR-018), no high/critical vulnerabilities, OpenAPI diff reviewed, bundle size budget.
