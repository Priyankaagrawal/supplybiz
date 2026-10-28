---
name: verify-task
description: Verify a Supply Biz task by T-xxx ID and finalize with PROMPTS.md section 6 after the user confirms manual verification PASS.
---

# Verify task

Examples: `$verify-task T-012` or `Manual verification PASS. Finalize T-012 using PROMPTS.md section 6.`

Resolve paths from the repository root. Use the supplied task ID; ask for it if missing or unknown. Support verification preparation and finalization while preserving the manual PASS gate.

1. Follow root `AGENTS.md` and required project context, reusing material already loaded. Read the operating rules and relevant sections of `docs/05-ai-development/PROMPTS.md`, the selected task row in `docs/05-ai-development/TASKS.md`, its Done when criteria, linked acceptance criteria/test cases and applicable DoD in `docs/05-ai-development/AGENTS.md`.
2. Check whether the user explicitly confirmed manual verification PASS for this task in the current conversation. Skill invocation, successful startup and passing automated checks alone are not confirmation.
3. Without manual PASS, inspect relevant implementation and check evidence; provide run commands and 3–5 manual checks tied to acceptance criteria. Report gaps, leave the task short of DONE and request the manual result. Do not execute section 6 finalization yet.
4. If the user reports failure, follow PROMPTS section 5: reproduce where feasible, fix the minimal implicated code and run focused checks. Return for manual verification; a fix does not carry forward PASS for behavior changed.
5. After manual PASS, follow PROMPTS section 6. Add missing high-value tests and required security/edge cases; run applicable checks for changed layers, including widget/golden/E2E or broader regression checks where required. Never treat placeholder scripts or checks not run as passing.
6. Update affected documentation and CHANGELOG as required, preserving unrelated work. Mark only the selected task DONE when its Done when criteria and applicable DoD checks are satisfied. Otherwise retain READY_FOR_VERIFY or IN_PROGRESS with remaining gaps; use BLOCKED with a specific reason when appropriate.

Report result, changed files, exact checks/results, manual verification status and blockers in approximately 12 lines. Do not create commits, publish builds or deploy merely because verification passed.

Token discipline: focus on selected task; no unrelated refactoring, broad documentation rewrite or speculative work.