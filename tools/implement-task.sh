
#!/usr/bin/env bash
set -euo pipefail

TASK_ID="${1:-}"

if [[ ! "$TASK_ID" =~ ^T-[0-9]{3}$ ]]; then
  echo "Usage: ./tools/implement-task.sh T-012"
  exit 1
fi

cd "$(dirname "$0")/.."

if [[ ! -f ".agents/skills/implement-task/SKILL.md" ]]; then
  echo "Missing implement-task skill"
  exit 1
fi

if [[ ! -f "docs/05-ai-development/TASKS.md" ]]; then
  echo "Missing TASKS.md"
  exit 1
fi

echo "Implementing $TASK_ID..."

codex exec --full-auto \
  "Use the \$implement-task skill to implement $TASK_ID.

Follow TASKS.md and PROMPTS.md section 1.
Read only relevant documentation and code.
Implement the minimum complete working functionality.
Run targeted checks only.
Do not start the application or emulator.
Do not run full regression tests.
Do not implement unrelated tasks.
Update status to READY_FOR_VERIFY only if checks pass.
Report commands for manual execution.
Stop when ready to run."