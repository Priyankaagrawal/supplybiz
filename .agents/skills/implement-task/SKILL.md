---
name: implement-task
description: Implement a Supply Biz task by T-xxx ID using PROMPTS.md section 1 in FAST mode, stopping when ready to run.
---

# Implement task

Example: `$implement-task T-012` or `Implement T-012 from TASKS.md using PROMPTS.md section 1. Stop when ready to run.`

Resolve paths from the repository root. Use the supplied task ID; T-012 is only an example. Ask for the intended ID if it is missing or unknown before changing files.

1. Follow root `AGENTS.md` and the reading order in `docs/05-ai-development/AGENTS.md`, reusing context already loaded. Read the selected row in `docs/05-ai-development/TASKS.md`, direct prerequisites and only directly relevant requirements and decisions. Dependencies must be DONE or READY_FOR_VERIFY unless a stubbed integration was explicitly approved.
2. Read `docs/05-ai-development/PROMPTS.md` operating rules and section 1. These maintained documents are authoritative. Respect documentation approval requirements and unresolved questions; explain any specific blocker rather than inventing requirements.
3. Inspect existing code and implement the smallest complete runnable slice. Preserve required security, validation, data integrity, localization and accessibility. Update migrations, contracts and generated clients only when required; never hand-edit generated files.
4. Add or adjust focused tests for changed logic and critical failures. Run targeted formatting, analysis and tests; fix failures caused by the change. Defer full suites, broad golden matrices, unrelated codegen and comprehensive documentation work to finalization.
5. Update only the selected task status to IN_PROGRESS, READY_FOR_VERIFY when runnable, or BLOCKED with a specific reason. Preserve unrelated work. Do not mark DONE.

Report result, changed files, exact commands/results, 3–5 manual verification steps and blockers in approximately 12 lines. Distinguish executed checks from suggested commands. Stop when ready to run; do not start services, claim manual PASS or finalize automatically.

Token discipline: no broad repo/document scans, no unrelated refactors, no lengthy plans, no redundant summaries. Honor AGENTS.md precedence and explain any conflicting instruction.