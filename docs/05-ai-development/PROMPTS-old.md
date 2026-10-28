# PROMPTS — Reusable Prompts for AI Agents

| Field | Value |
|---|---|
| Status | Draft v0.1 |
| Owner | Technical Architect |
| Last updated | 2026-10-19 |
| Related | [AGENTS](AGENTS.md), [TASKS](TASKS.md) |

Replace `{{…}}` placeholders. All prompts assume the agent follows [AGENTS](AGENTS.md).

## 1. Implement a Task
```
You are implementing {{T-xxx}} in the Supply Biz monorepo.
1. Read docs/05-ai-development/CONTEXT.md and AGENTS.md.
2. Read the task row in docs/05-ai-development/TASKS.md and every referenced FR/US/RULE/S/ADR.
3. List any open questions (Q-xx) that affect this task. If any block the core behaviour, stop and ask.
4. Propose a short plan: files to create/modify (per FOLDER_STRUCTURE), API changes, DB migrations, tests (with TC IDs).
5. Implement: contract/schema first → backend → codegen → mobile/admin.
6. Add tests: unit, widget/e2e, authZ/IDOR, edge cases from SCREEN_SPECIFICATIONS §5.
7. Run: {{commands from AGENTS §5}}. Fix all failures.
8. Update TASKS status, CHANGELOG (Unreleased), and any doc whose behaviour changed.
Output: summary, files changed, test results, remaining questions.
```

## 2. Implement a Screen
```
Implement screen {{S-X-nn}} for feature {{feature}}.
Inputs: SCREEN_SPECIFICATIONS entry {{S-X-nn}}, UI_UX_GUIDELINES, DESIGN.md, related FR/US.
Requirements:
- Use only ui_kit Sb* components and theme tokens; no hex/magic numbers.
- Implement loading (skeleton), empty, error (retry), offline, locked-by-plan, permission states as applicable.
- Riverpod controller in presentation/controllers; repository via provider; no data-source calls from widgets.
- Strings in app_en.arb and app_hi.arb; semantics labels; 48dp targets; text scale 200% safe.
- Widget tests for each state + golden tests (EN/HI, 320dp & 390dp).
- Add analytics events listed in QUALITY_OBSERVABILITY §4 for this screen.
```

## 3. Implement an API Endpoint
```
Implement {{METHOD path}} in module {{module}} per API_SPECIFICATION §{{n}} and SRS {{FR}}.
- DTOs with class-validator (whitelist, forbidNonWhitelisted); Swagger decorators.
- Derive vendorId/userId from token; never from body. Apply role, plan and KYC guards as specified.
- Require Idempotency-Key for state-changing mobile endpoints.
- Use Prisma transaction for multi-table writes; emit domain events via outbox.
- Map business rule violations to the documented error codes.
- Tests: unit (service rules RULE-xx), e2e (happy path, validation, 401/403, IDOR other-tenant → 404, idempotent replay, version conflict).
- Regenerate contracts/openapi.yaml and clients.
```

## 4. Fix a Bug
```
Bug: {{description}} (observed in {{env/version/platform}}, steps: {{steps}}).
1. Reproduce with a failing automated test first (unit/widget/e2e) referencing the related TC/FR.
2. Identify root cause; explain it in 2–3 sentences.
3. Apply the minimal fix consistent with docs; do not refactor unrelated code.
4. Confirm the test passes and the full suite is green.
5. If the docs were wrong or ambiguous, propose the doc fix in the same PR.
Output: root cause, fix summary, tests added.
```

## 5. Refactor
```
Refactor {{area}} to {{goal}} without changing behaviour.
- Confirm existing tests cover the behaviour; add characterization tests if not.
- Keep public interfaces stable unless the goal requires otherwise (then update all callers).
- Respect module boundaries (MODULE_DESIGN §2.1, §3 rules).
- No functional changes, no new dependencies unless justified.
Output: before/after structure, test evidence.
```

## 6. Write Tests for Existing Code
```
Write tests for {{file/module}} covering TC IDs {{TC-xxx…}} from TEST_CASES.md.
- Cover happy path, boundaries, invalid input, authZ, offline/retry where applicable.
- Use fakes for integrations (FakeKyc, ConsoleOtp, FakeBilling, LogPush).
- Deterministic: inject clock (IST), no real network, no sleeps.
Report coverage before/after.
```

## 7. Database Migration
```
Create a Prisma migration for {{change}} per DATA_DESIGN.
- Expand/contract for destructive changes; backfill script if needed.
- Add indexes/constraints from DATA_DESIGN; keep ledger append-only grants intact.
- Update DATA_DESIGN.md if the model changes. Provide rollback notes.
```

## 8. Review a Pull Request
```
Review PR {{link/diff}} against AGENTS.md DoD and CODING_STANDARDS.md.
Check: requirement coverage (FR/US/TC IDs), security (authZ, IDOR, input validation, PII in logs), money in paise, idempotency, l10n EN/HI, accessibility, states, tests quality, generated code untouched, docs updated.
Output: blocking issues, non-blocking suggestions, questions.
```

## 9. Clarify a Requirement
```
I found ambiguity in {{doc §}} regarding {{topic}}.
Options: A) … B) … C) …
Impact on: {{FR/US/T/TC}}.
Recommendation: {{option}} because {{reason}}.
Please confirm; I will record the decision in SCOPE (Q-xx) or DECISIONS (ADR).
```

## 10. Generate Release Notes
```
Generate release notes for {{version}} from CHANGELOG.md Unreleased and merged PR titles.
Produce: (1) CHANGELOG section (Keep a Changelog), (2) store "What's new" text ≤ 500 chars in EN and HI, user-facing only, no internal IDs.
```
