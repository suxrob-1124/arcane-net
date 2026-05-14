#!/usr/bin/env bash
# UserPromptSubmit hook.
# If the user's prompt contains planning intent, inject a hard reminder
# that the assistant MUST use the feature-plan skill + template, not improvise.
set -euo pipefail

input=$(cat)
prompt=$(printf '%s' "$input" | python3 -c "import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('prompt', ''))
except Exception:
    pass" 2>/dev/null || true)

lc=$(printf '%s' "$prompt" | tr '[:upper:]' '[:lower:]')

# Russian + English planning keywords
pattern='спланир|план работ|план реализ|план фич|план задач|нужно спланир|задизайн|design a feature|plan this feature|draft a plan|implementation plan|спроектир'

if printf '%s' "$lc" | grep -qE "$pattern"; then
  python3 <<'PY'
import json
msg = (
    "PLANNING TASK DETECTED. Mandatory rules — overrides any other planning approach:\n"
    "1. Invoke the `feature-plan` skill (Skill tool with skill='feature-plan').\n"
    "2. Base the plan on `.claude/templates/feature_plan.md`. Fill EVERY section; mark inapplicable ones N/A explicitly.\n"
    "3. Save the plan as `.claude/plans/feat-<slug>.md` (project-level, NOT user-level /Users/.../.claude/plans/).\n"
    "4. Before writing the plan, read REVIEW.md and the relevant `.claude/docs/*.md` (architecture, combat_and_progression, spectator_mode, dev-guide).\n"
    "5. Improvising a custom plan structure is forbidden — see project memory `feedback_planner_template.md`."
)
print(json.dumps({"hookSpecificOutput": {"hookEventName": "UserPromptSubmit", "additionalContext": msg}}))
PY
fi
