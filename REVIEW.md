# REVIEW.md

> **Agent rule:** Before every commit, check this file and verify all applicable items.

---

## Review Checklist

- [ ] PR title / Commit message follows Conventional Commits (`<type>(<scope>): <subject>`)
- [ ] Project runs without errors (`--headless --import` passes)
- [ ] All GUT tests pass successfully
- [ ] Signals are strictly typed (e.g., `signal health_changed(old_val: int, new_val: int)`)
- [ ] Input actions and node names use `&StringName` syntax (e.g., `&"move_left"`)
- [ ] Composition is used over inheritance (logic is in components, not monolithic scripts)
- [ ] Public symbols documented with `##` — class header, every `signal`, every public method (skip `_private` and Godot lifecycle hooks)

---

## Style Guide

| Element | Convention | Example |
|---|---|---|
| AutoLoads / Singletons | PascalCase | `EventBus`, `GameState` |
| Nodes & Scenes | PascalCase | `PlayerCharacter.tscn`, `MovementComponent` |
| GDScript variables & functions | snake_case | `current_health`, `apply_damage()` |
| Private methods | leading underscore | `_on_hitbox_entered()` |

---

## Ignore in Review

- `.godot/` folder contents
- `.import/` folder contents
- Changes in `addons/gut/`
