#!/usr/bin/env bash
# Stop hook.
# If there are uncommitted changes in scripts/, inject a reminder to run the
# REVIEW.md checklist and the /playtest-check ritual before claiming done.
set -euo pipefail

repo_root="/Users/sukhrobshukurov/Dev/godot-test-game"

if ! command -v git >/dev/null 2>&1; then
  exit 0
fi

# Look for modified/added/untracked files inside scripts/
changes=$(git -C "$repo_root" status --porcelain 2>/dev/null | awk '{print $2}' | grep -E '^scripts/(combat|spectator|ui|core|progression|dungeon_gen|data|network)/' || true)

if [ -z "$changes" ]; then
  exit 0
fi

python3 <<PY
import json
msg = (
    "REVIEW GATE — uncommitted changes detected in scripts/. Before claiming done:\n"
    "1. Did \`--headless --import\` pass?\n"
    "2. Did the full GUT suite stay green?\n"
    "3. Did you apply the REVIEW.md checklist (## docs on new public symbols, typed signals, StringName for inputs/groups, composition not inheritance)?\n"
    "4. Did you remind the user about \`/playtest-check\` if changes touched scripts/combat or scripts/spectator?\n"
    "Surface any gap to the user explicitly instead of silently finishing."
)
print(json.dumps({"systemMessage": msg}))
PY
