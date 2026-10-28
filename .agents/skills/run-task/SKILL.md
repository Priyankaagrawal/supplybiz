---
name: run-task
description: Run or troubleshoot a Supply Biz task by T-xxx ID using PROMPTS.md section 4 and existing local project scripts.
---

# Run task

Example: `$run-task T-012 on Android` or `Run T-012 using PROMPTS.md section 4.`

Resolve paths from the repository root. Use the supplied task ID, not the example ID. Ask for the intended ID if missing or unknown.

1. Follow root `AGENTS.md` and required project context, reusing material already loaded. Read `docs/05-ai-development/PROMPTS.md` operating rules and section 4, the selected row in `docs/05-ai-development/TASKS.md`, and relevant package scripts and README instructions.
2. Identify the affected app/service and local dependencies. Use the requested platform/environment; otherwise infer it from the task and available configuration. Ask only if the target materially affects execution and cannot be inferred.
3. Execute the minimum existing commands needed to run/check the task. Inspect current scripts rather than assuming documented placeholders work. Respect execution permissions; this skill does not authorize production deployment or destructive resets.
4. Fix only task-related defects or blockers preventing local execution. Use PROMPTS section 5 for observed defects, reproduce with a focused test when feasible, and rerun relevant checks. Do not add features or refactor unrelated code.
5. Track processes started so the user can access and stop them. Keep READY_FOR_VERIFY when runnable; use IN_PROGRESS or BLOCKED with a reason if unfinished. Successful startup does not establish manual PASS or DONE.

Report exact commands, observed process/results, URL or device route, required manual configuration and how to stop processes started by this run. If execution is unavailable, provide precise commands and the blocker without claiming success. Keep the response to approximately 12 lines and stop for manual verification.

Token discipline: no broad scanning, repeated logs, speculative environment changes or comprehensive documentation updates.
