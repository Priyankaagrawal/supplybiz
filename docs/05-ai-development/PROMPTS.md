# PROMPTS — Fast, Token-Efficient AI Implementation Workflow

## Operating rules (apply to every prompt)
- Default to **FAST mode**: implement the smallest working scope, run targeted checks, then STOP for manual verification.
- Read `AGENTS.md` only if not already loaded; consult `CONTEXT.md` or other documents only for specific missing requirements. Read relevant sections, never entire documentation trees.
- Read the selected task row, its dependencies and only directly relevant FR/US/RULE/ADR/screen sections. Search for IDs before opening files.
- Inspect existing implementation before proposing changes. Reuse patterns, utilities, generated clients, and UI kit.
- No speculative architecture, unrelated refactors, broad repository scans, dependency upgrades, or repeated summaries.
- Do not regenerate API clients unless the contract changed. Do not run all tests, golden matrices, builds for every platform, or CI locally unless requested.
- Never silently bypass security, authorization, validation, migrations, data integrity, or required error handling. Use fakes only where already supported and clearly label them.
- Commands: choose the narrowest available analyze/lint/test/build/run command. Report commands not executed honestly.
- If a blocking requirement is unclear, ask one focused question; otherwise state a reasonable reversible assumption.
- Limit final response to: result, files changed, commands/results, how to verify, blockers (max ~12 lines).

## 1. FAST — Implement one task (default)
```text
Implement {{T-xxx}} from TASKS.md in FAST mode.
1. Read only its row, prerequisites, and directly relevant requirement sections; inspect existing code in the affected module.
2. If blocked by a genuine missing decision or prerequisite, stop and say exactly what is needed.
3. Implement the smallest complete, runnable vertical slice satisfying the task's core behavior; reuse existing conventions. For API changes, include required migration/contract updates and minimum auth/validation/idempotency safeguards where applicable.
4. Add or update only focused tests needed for changed logic and critical failure/security cases. Run targeted formatter/analyzer/tests; fix failures caused by your changes.
5. Do NOT run full suites, broad golden tests, unrelated codegen, comprehensive documentation updates, or extensive planning. Do not mark DONE yet.
6. Update task status to READY_FOR_VERIFY when runnable; otherwise IN_PROGRESS or BLOCKED. Give exact commands and 3-5 manual verification steps.
STOP. Wait for my verification before finalizing.
```

## 2. FAST — Implement one screen
```text
Implement screen {{S-X-nn}} for task {{T-xxx}} in FAST mode.
Read only its screen spec, linked FR/US and relevant ui_kit examples. Reuse Sb* components, Riverpod and theme tokens. Wire to the existing repository/provider; do not invent APIs.
Implement core happy path plus applicable loading, empty and error states; add offline/permission/plan states only when relevant. Use EN/HI l10n and basic accessibility semantics.
Add one or two focused widget/controller tests; run targeted analyze/test. Do not run golden matrices or unrelated E2E now.
Provide run route, verification steps and any known gaps. Set READY_FOR_VERIFY; STOP.
```

## 3. FAST — Implement one API endpoint
```text
Implement {{METHOD path}} for {{T-xxx}} per relevant API spec/FR.
Inspect existing module, DTO, guards and Prisma patterns. Implement DTO validation, authZ/tenant isolation, documented errors, and transaction/idempotency/outbox where relevant. Update schema/migration and OpenAPI/generated clients ONLY if changed.
Add focused service/e2e tests: success, invalid input, unauthorized/other-tenant, and relevant replay/conflict cases. Run only related tests and typecheck. Provide curl/example request and verification steps. STOP before broad regression.
```

## 4. RUN — Start and troubleshoot
```text
Run/check {{T-xxx}} on {{platform/environment}} using existing project scripts.
First inspect the relevant package scripts/README. Execute the minimum commands to start it. Fix only blockers introduced by this task or preventing local run. Do not refactor or add features.
Report exact commands, process/result, URL/device route, and anything I must configure manually. If execution is unavailable, give precise commands without claiming success.
```

## 5. FIX — After manual testing
```text
Fix this observed issue in {{T-xxx}}: {{steps, expected, actual, logs}}.
Inspect only implicated code; reproduce with one focused test when feasible; apply the minimal fix; rerun targeted checks. Do not modify unrelated files or expand scope. Report root cause, changed files and how to retest.
```

## 6. FINALIZE — Only after I confirm manual verification
```text
Finalize {{T-xxx}} after manual verification PASS.
Review the task's Done when criteria and relevant AGENTS DoD. Add missing high-value tests, required security/edge cases and applicable widget/golden/E2E checks; run the appropriate broader checks for changed layers. Update CHANGELOG and affected docs only when necessary. Mark DONE only if criteria and checks are satisfied; otherwise report remaining gaps and keep READY_FOR_VERIFY/IN_PROGRESS.
Summarize results concisely.
```

## 7. Focused refactor
```text
Refactor {{area}} for {{goal}} with no behavior change. Inspect only affected code, preserve interfaces, run relevant existing tests, and report changed files and results. Avoid unrelated cleanup.
```

## 8. Focused tests
```text
Add focused tests for {{file/module}} covering {{TC IDs}}. Prioritize core behavior, boundary and security cases. Use existing fakes, deterministic clocks and no real network. Run only these tests; report results and uncovered gaps.
```

## 9. Migration
```text
Implement Prisma migration for {{change}} according to the relevant DATA_DESIGN section. Include constraints/indexes, safe backfill/expand-contract if needed, and rollback notes. Run targeted migration validation. Do not rewrite unrelated schema.
```

## 10. Review
```text
Review {{diff/PR}} for functional regressions, authZ/IDOR, input validation, money precision, idempotency, localization and tests. Inspect changed files and directly related code only. Return blockers first with file/line, then concise suggestions.
```

## 11. Clarify
```text
Clarify {{Q-xx/topic}} using only the relevant spec sections. State the ambiguity, 2-3 options, impact, and recommended reversible choice. Ask for one decision; do not implement until resolved if core behavior is blocked.
```

## 12. Release notes
```text
Generate {{version}} release notes from CHANGELOG Unreleased and provided merged PRs. Include concise changelog and EN/HI user-facing store text (max 500 chars each). Do not scan unrelated git history.
```

## Suggested daily usage
1. `Implement T-xxx from TASKS.md using PROMPTS.md section 1. Stop when ready to run.`
2. `Run T-xxx using PROMPTS.md section 4.`
3. Test manually; use section 5 for any bugs.
4. `Manual verification PASS. Finalize T-xxx using PROMPTS.md section 6.`

