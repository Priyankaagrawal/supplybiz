---
name: auto-task
description: Select and implement one next eligible active Supply Biz task in ROADMAP order using PROMPTS section 1, with Android-only mobile checks, stopping ready for manual verification. Use for a single automatic task selection, not the existing multi-task orchestrator.
---

# Implement the next roadmap task

Invoke with `$auto-task`. Complete one implementation attempt per invocation, then stop for manual verification. This skill does not invoke or modify `auto-tasks` and does not require specialist agents.

## Select the task

1. Resolve project documents from the repository root. Follow root `AGENTS.md` and its CONTEXT → AGENTS → TASKS reading order, reusing context already loaded. Read `docs/05-ai-development/ROADMAP.md`, TASKS dependency/status rules, and PROMPTS operating rules and section 1. Use DELIVERY_SCOPE and accepted decisions to distinguish active scope from approved backlog.
2. Select the highest-priority eligible active task in ROADMAP daily order, not the lowest task number. Check its current TASKS row and every direct dependency, including ranges and required gates. Dependencies must be DONE or READY_FOR_VERIFY for implementation against stable contracts. Apply only explicitly authorized dependency exceptions within their stated scope; do not extend an exception to another task automatically.
3. Skip DEFERRED, REMOVED and DONE tasks. Leave READY_FOR_VERIFY tasks awaiting manual verification. Skip BLOCKED tasks unless their recorded blocker is demonstrably resolved. Resume IN_PROGRESS work only when it belongs to this session or its ownership is clear; otherwise choose an eligible TODO without overwriting another worker's work.
4. Check unresolved questions before editing. Skip candidates with genuine missing decisions or unmet prerequisites and continue in roadmap order. If no task is eligible, report the concrete blockers and stop. If a blocker emerges after selecting a task, follow PROMPTS section 1: record the accurate status and stop rather than inventing policy or starting a second task.
5. State the selected task ID and why its dependencies permit implementation. Inspect Git status and relevant source; preserve existing edits and unrelated task statuses.

## Implement and check

- Follow PROMPTS section 1 in FAST mode and the selected task's Done when criteria. Read only linked user-story acceptance criteria, FR/RULE/screen sections and relevant architecture/decisions. Implement the smallest complete runnable slice using existing patterns; do not implement deferred clauses of mixed requirements.
- Preserve required validation, authorization, tenant isolation, idempotency, financial integrity, English localization and accessibility. Change migrations/contracts when necessary; regenerate affected clients from source and never hand-edit generated files.
- Run affected-layer build/typecheck, lint/analyze, runnable smoke and focused critical-logic/security checks. Fix defects introduced by the task. Do not run broad suites, screenshot baseline generation or unrelated codegen; comprehensive module checks follow the separate project gate workflow.
- Use Android only for mobile builds, runs, device/emulator checks and accessibility checks. Preserve iOS source/configuration; report iOS checks as deferred, never passed.
- Report unavailable checks as NOT_RUN with the specific reason. Do not claim live-provider delivery from simulation, manual PASS from automation, or a module-gate pass from task checks. Do not leave newly started check processes running; preserve pre-existing services/devices.

## Handoff and stop

Update only the selected task to READY_FOR_VERIFY when runnable with the required lightweight evidence. Otherwise retain IN_PROGRESS or record BLOCKED with the specific reason. Record concise check evidence and necessary handoff instructions in the project's existing documentation; defer comprehensive finalization to PROMPTS section 6.

Report the task/status, changed files, exact executed commands/results, 3–5 manual verification steps and remaining blockers in approximately 12 lines. Distinguish executed checks from suggested commands.

Stop after this one task's handoff. Do not select another task, start a separate RUN workflow, finalize, or mark DONE. Wait for task-specific manual verification and a subsequent user instruction.
