#!/usr/bin/env bash
# PreToolUse hook for Write.
# Blocks writes to any .claude/plans/*.md (project- or user-level) whose
# content does not contain the mandatory sections from
# .claude/templates/feature_plan.md.
set -euo pipefail

input=$(cat)

python3 <<'PY'
import json
import sys
import re

raw = sys.stdin.read() if False else None  # placeholder; we re-read below
PY

# Re-read stdin via python for parsing
python3 - "$input" <<'PY'
import json
import re
import sys

raw = sys.argv[1] if len(sys.argv) > 1 else ""
try:
    data = json.loads(raw)
except Exception:
    sys.exit(0)

tool_name = data.get("tool_name", "")
tool_input = data.get("tool_input", {}) or {}
file_path = tool_input.get("file_path", "") or ""
content = tool_input.get("content", "") or ""

if tool_name != "Write":
    sys.exit(0)

if not re.search(r"\.claude/plans/[^/]+\.md$", file_path):
    sys.exit(0)

required = [
    "## Context & Goal",
    "## Architecture & Node Tree",
    "## EventBus Integration",
    "## GUT Tests",
    "## Implementation Checklist",
]
missing = [s for s in required if s not in content]

if missing:
    reason = (
        "Plan file must follow `.claude/templates/feature_plan.md`. "
        "Missing required sections: " + ", ".join(missing) + ". "
        "Read the template, invoke the `feature-plan` skill, and rewrite using the full structure. "
        "If a section is inapplicable, keep the heading and write N/A."
    )
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }))
    sys.exit(0)
PY
