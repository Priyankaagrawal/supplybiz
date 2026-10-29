# QUALITY & OBSERVABILITY — approved delivery baseline

Updated 2026-10-29. ADR-024/SR-06 defers advanced telemetry; ADR-025 makes mobile execution Android-only until after Android production release. This is target documentation, not implementation evidence.

## 1. Errors and logging
Preserve Problem Details, request IDs, typed client error mapping, useful loading/error/retry behavior and redacted structured API/worker/admin logs. Use existing logging/diagnostic wrappers; never log OTPs/tokens/raw phone/address/KYC/bank contents. Map provider failures to safe errors with bounded timeouts/retries; no new generic circuit-breaker framework. Mutations retry only under idempotency/outbox policy, never indiscriminately.

## 2. Basic crash reporting
T-018 wires existing basic Android crash/error diagnostics where configured, with environment/build identification and no PII. Report an unavailable backend honestly; local structured diagnostic evidence is distinct from a captured Crashlytics report. Basic crash-free/ANR targets remain, measured on observed Android runs rather than invented beta statistics. API/admin logs capture sanitized errors. iOS dSYMs/APNs/native crash validation is deferred to T-185 after Android release.

## 3. Deferred telemetry
Firebase product analytics funnels/event catalogs, custom Firebase Performance traces, OTel exporters/dashboards, Sentry expansion, attestation, experimentation and Remote Config campaigns are POST-DELIVERY under approved SR-06. Existing source wrappers may be reused; do not add new telemetry dependencies/infrastructure or make campaign event coverage a task gate. Business dashboard numbers come from actual SQL records; plan grants are not paid revenue. No events for deferred finance, billing, grocery, reviews or marketing are required.

## 4. Analytics
POST-DELIVERY reference heading retained for inbound links. Product-event analytics is deferred; no mandatory event matrix in the current DoD. Keep existing privacy/consent and log redaction controls. Basic operational records and DB reports are retained.

## 5. Required operational checks
| Area | Minimum delivery evidence |
|---|---|
| API/admin | Availability/5xx and request latency from health/request logs; authorized basic dashboard; process supervision |
| Worker | Persisted job status/counts/errors, leased retries, catch-up, outbox backlog age and failure visibility |
| Subscription generation | Alert if next-day job not successful by 22:30 IST; idempotent catch-up runbook |
| OTP | Safe provider failure reporting, shared abuse limits and no secret leakage |
| Storage/DB | Disk free/capacity, upload-root access, failed upload/validation, encrypted DB/files backup success/age and tested paired restore |
| Security | Dependency review, authorization/tenant/log-redaction findings; no high/critical issue left open |

## 6. Performance monitoring
Representative Android startup/frame/memory/size and API load checks use existing tooling and agreed capacity. Fix measured blockers; broad device farms, scale campaigns and advanced dashboards are deferred. Do not claim historical 10k-vendor design ambition has been load-tested.

## 7. Alerting
Basic availability, generation-failure, outbox failure/backlog, disk capacity and backup-failure/age alerts require an assigned owner and a demonstrated trigger. Use the host/provider's existing monitoring and operational dashboard rather than a new telemetry platform. Manual KYC backlog is visible to ops. Billing webhook/campaign alerts are not active requirements.

## 8. Health endpoints
`GET /health/live` checks process; `/health/ready` checks DB and persistent upload-root access/capacity; `/version` identifies build. Restrict/rate-limit operational detail. No deferred-provider dependency may make readiness fail.

## 9. Quality gates
Task build/lint/smoke and focused critical checks; comprehensive integration/regression/E2E at module completion and G6; actual DB/file restore and basic security/accessibility evidence. Follow TEST_STRATEGY, TASKS and DELIVERY_SCOPE. iOS checks are deferred, never PASS, and do not block Android gates.
