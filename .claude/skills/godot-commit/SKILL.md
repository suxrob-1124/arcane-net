---
name: godot-commit
description: Pre-commit ritual for Arcane Net — runs --headless --import, GUT tests, REVIEW.md checklist, then creates a Conventional Commit. Use when the user asks "commit", "make a commit", "коммит", or signals they want to wrap up changes.
---

# godot-commit

The full pre-commit ritual. Never skip steps — `--no-verify` is forbidden by `CLAUDE.md`.

## Step 1 — Import & tests

```bash
GODOT="/Applications/Godot_mono.app/Contents/MacOS/Godot"
"$GODOT" --path . --headless --import
"$GODOT" --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/ -gexit
```

Both must report zero ERROR lines. If GUT fails, stop and fix — do not commit.

## Step 2 — REVIEW.md checklist

Open `REVIEW.md` and verify each applicable box:

- Conventional Commits format
- Import passes / GUT green (just verified in step 1)
- Typed signals
- `&StringName` for input actions / node names
- Composition over inheritance
- `##` docs on public symbols (class, signals, public methods)

For gameplay changes (combat / spectator / AI / UI / scenes): **playtest Main.tscn ≥ 30 s** before commit — invoke the `playtest-check` skill.

## Step 3 — Commit

Format: `<type>(<scope>): <subject>` — subject ≤ 72 chars, imperative, no trailing period.

- **Types**: `feat` | `fix` | `refactor` | `perf` | `test` | `docs` | `chore` | `style`
- **Scopes**: `core` | `combat` | `camera` | `dungeon` | `ui` | `network` | `progression` | `tests` | `assets`

Stage explicit files (never `git add -A` — `.godot/`, `.DS_Store`, `.mono/` must not enter the index).

```bash
git status
git diff --staged
git commit -m "$(cat <<'EOF'
feat(combat): add void crawler enemy

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

## Hard rules

- Never `--no-verify`, never bypass hooks. Fix the root cause.
- Never `git add -A` / `git add .`.
- Never commit `.godot/`, `.import/`, `.mono/`, `.DS_Store`, build binaries.
- Never amend a previous commit — create a new one.
- Direct commits to `main` are forbidden; work on a `feat/<slug>` branch.
