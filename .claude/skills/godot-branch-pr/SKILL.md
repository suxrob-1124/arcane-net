---
name: godot-branch-pr
description: Branching and pull-request workflow for Arcane Net — creates a feat/fix/refactor branch from main, pushes, opens a PR with the project checklist (import passes, tests green, no .godot in diff). Use when the user asks to create a branch, push, open a PR, or merge work back to main.
---

# godot-branch-pr

GitHub Flow: branch from `main` → commits → push → PR → squash merge → delete branch. Direct commits to `main` are forbidden.

## Branch naming

`<type>/<slug>` where `<type>` is one of:

- `feat/` — new feature
- `fix/` — bug fix
- `refactor/` — internal restructuring, no behaviour change
- `docs/` — documentation only
- `chore/` — tooling, deps, config
- `test/` — test-only changes

Slug: kebab-case, ≤ 5 words. Example: `feat/void-crawler-enemy`.

## Workflow

1. **Branch from `main`**:
   ```bash
   git checkout main && git pull
   git checkout -b feat/<slug>
   ```
2. **Commit** via the `godot-commit` skill (which runs import + GUT + REVIEW.md checklist).
3. **Push**:
   ```bash
   git push -u origin feat/<slug>
   ```
4. **Open PR** with `gh pr create`. Body must include:
   - Summary (1–3 bullets)
   - Test plan (what to validate manually)
   - Confirmation: import passes, GUT green, no `.godot/` / `.DS_Store` in diff, playtest done for gameplay changes

## PR checklist (copy into body)

```
## Summary
- ...

## Test plan
- [ ] `--headless --import` passes
- [ ] GUT tests green
- [ ] Main.tscn playtest ≥ 30 s, zero ERROR logs (gameplay changes only)
- [ ] No `.godot/` / `.import/` / `.DS_Store` in diff
- [ ] REVIEW.md items satisfied
```

## Hard rules

- Never commit directly to `main`.
- Never force-push to `main`.
- Squash-merge only; delete the branch after merge.
- Remote: `origin` → GitHub repo `arcane-net` (public). If missing, create via `gh repo create` and ask the user to run interactive auth (`! gh auth login`).
