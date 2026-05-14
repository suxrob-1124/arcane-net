# Feature: [Name]

> **Status**: Draft | In Progress | Done  
> **Branch**: `feat/<slug>`  
> **Date**: YYYY-MM-DD

---

## Context & Goal

_What problem does this feature solve? What player-facing or system-level outcome is expected?_

- **Why now**: 
- **Success criteria**: 
- **Out of scope**: 

---

## Architecture & Node Tree

_List every new script, scene, or Resource file. Follow GDD 2.1 directory map — no folders outside the allowed list._

```
scenes/
  <mode>/
    MyScene.tscn          ← brief role note

scripts/
  <subsystem>/
    MyNode.gd             ← CharacterBody3D / Node / Resource / …
    MyComponent.gd        ← single responsibility
```

**AutoLoad changes** (only if globally necessary):
- [ ] None / `GameState` / `EventBus` / `SpectatorState` — _reason_

**Composition notes**:
- Which node is the façade?
- Which nodes are pure components?
- Any direct parent→child calls that cross component boundaries? (prefer signals)

---

## EventBus Integration

_List every signal this feature emits or listens to. Typed signatures required._

| Signal | Args | Emitter | Listener(s) | When |
|---|---|---|---|---|
| `signal_name` | `(arg: Type)` | `Emitter.gd` | `Listener.gd` | description |

**New signals to add to EventBus.gd** (if any):
```gdscript
signal signal_name(arg: Type)
```

---

## GUT Tests

_Cover pure logic only — no timers, no visuals, no AutoLoad integration._

| Test file | `test_*` method | What it asserts |
|---|---|---|
| `tests/test_<feature>.gd` | `test_<behavior>` | expected outcome |

**Not covered by tests** (game feel / timing — playtested only):
- 

---

## Implementation Checklist

> Executor agent: check off each item as it is completed.

### Setup
- [ ] Create branch `feat/<slug>` from `main`
- [ ] Run `--headless --import` after adding any new `class_name`

### Scripts & Scenes
- [ ] 
- [ ] 
- [ ] Every new script has `##` docs: class header, every `signal`, every public method

### Signals & EventBus
- [ ] Add new signal declarations to `EventBus.gd`
- [ ] Wire emitters and listeners

### Tests
- [ ] Write GUT tests listed above
- [ ] Run `--headless --import` then full test suite — all green

### Integration
- [ ] Connect to AutoLoad singletons if needed
- [ ] Verify no ERROR logs after 30-second playtest of `Main.tscn`
- [ ] Check REVIEW.md — all applicable items satisfied

### Commit & PR
- [ ] Conventional commit: `feat(<scope>): <subject ≤72 chars>`
- [ ] PR checklist: no `.godot/` / `.DS_Store` in diff, tests green, import passes
