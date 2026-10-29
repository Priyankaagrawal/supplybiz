---
name: auto-tasks
description: Pick eligible TODO Supply Biz tasks and implement them sequentially with specialist runtime and verification checks, preserving manual approval before DONE.
---

# Supply Biz task orchestrator

## Invocation
`$auto-tasks` or `$auto-tasks max=3` (default max=1). Optional `task=T-015` selects a specific eligible TODO task. `max` limits distinct tasks attempted, including those left READY_FOR_VERIFY.

## Select a TODO task
1. Read applicable AGENTS rules, TASKS.md task-state/dependency rules and relevant PROMPTS.md sections. Reuse loaded context; inspect only selected-task references.
2. Confirm multi-agent support and custom roles `implementer`, `runner`, `verifier` are available; otherwise report unsupported and stop.
3. Pick the lowest-numbered TODO with all direct dependencies DONE or READY_FOR_VERIFY, following TASKS.md. Evaluate all prerequisites in ranges/milestones; ask if genuinely ambiguous. With `task=`, require that task to be TODO and eligible.
4. Skip IN_PROGRESS, READY_FOR_VERIFY, BLOCKED and DONE tasks. Existing manual gates do not block another eligible TODO. Use run-task or verify-task explicitly to handle pending verification; never take over another worker's work.
5. Inspect Git status and selected-task files. Preserve unrelated edits; their presence alone does not block independent work. Stop if affected edits would be overwritten or their ownership is unclear, explaining the specific collision. Follow repository branch rules. Never stash, discard, copy or commit existing edits automatically; do not commit, push, merge or delete worktrees without authorization.
6. If no eligible TODO exists, report unmet prerequisites and stop; do not switch to pending verification automatically.

## Process the selected task
One task and one specialist phase at a time. The coordinator delegates implementation and checks; it does not implement or test code itself.

1. Record the task ID and mark only it IN_PROGRESS when safe.
2. Delegate to `implementer` using [implement-task](../implement-task/SKILL.md). Wait for implementation and targeted checks. If blocked, report the reason and stop with an accurate status.
3. Delegate to `runner` using [run-task](../run-task/SKILL.md). Follow the platform scope in TASKS.md (Android only while iOS verification is deferred). For a runtime defect, return precise logs to implementer for one focused repair and retry runner once. For unavailable setup, report NOT_RUN, provide exact setup/run instructions and proceed only to verification preparation; do not retry unavailable environments.
4. Delegate to `verifier` using [verify-task](../verify-task/SKILL.md). Without explicit task-specific manual PASS, perform preparation only. For an actionable defect, allow one focused implementer repair and relevant rechecks. Limit repairs to two total rounds per task.
5. Leave runnable work READY_FOR_VERIFY with executed check evidence and a short manual checklist. Mark DONE only after explicit manual PASS and required acceptance/DoD checks. Automation and skill invocation are not approval. Repairs affecting approved behavior require renewed manual verification.
6. After implementation and available automated checks finish and the checklist is handed off, select the next eligible TODO until `max` is reached. Existing READY_FOR_VERIFY tasks may remain pending. Stop on unresolved implementation defects, missing runtime prerequisites or exhausted repairs.

Read the routed skill and give its path to the specialist. Its phase report returns control to the coordinator; manual approval remains required for finalization. Send narrow context: task ID, paths, scope and previous-phase evidence. Never run concurrent write agents.

## Boundaries
- Use targeted checks; broader suites only when required by task DoD.
- No production deploy, destructive migrations, external side effects, secret access or paid-service usage without explicit authorization.
- Preserve unrelated statuses and edits. Retain IN_PROGRESS or BLOCKED with a reason if implementation is unfinished; unavailable runtime alone is not evidence of a code defect.
- Report unavailable checks as NOT_RUN and iOS checks as deferred, never PASS.

## Final report
Concisely report task ID/status, changes, runtime/test evidence, blockers, manual checklist and next eligible TODO.
