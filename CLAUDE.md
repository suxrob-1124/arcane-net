# CLAUDE.md

> Thin index for AI agents working on Arcane Net. Detailed knowledge lives in linked docs — keep this file short.

## MANDATORY before starting any task

These rules override default behaviour. Hooks in `.claude/settings.json` also enforce some of them at tool-call time — treat the hook block as a hard guardrail, not a suggestion.

1. **Planning** — any task involving "plan / design / спланируй / задизайнь" MUST go through the `feature-plan` skill and produce a file at `.claude/plans/feat-<slug>.md` based on `.claude/templates/feature_plan.md`. Every section filled (use `N/A` for inapplicable). No custom plan structures.
2. **Read before coding** — for changes in `scripts/combat/`, `scripts/spectator/`, `scripts/progression/`, or `scripts/dungeon_gen/`, open the matching `.claude/docs/*.md` first (`combat_and_progression.md`, `spectator_mode.md`, `architecture.md`, `dev-guide.md`).
3. **REVIEW.md gate** — before declaring a task done, walk the [REVIEW.md](REVIEW.md) checklist and report each item explicitly.
4. **Playtest gate** — for changes in `scripts/combat/`, `scripts/spectator/`, `scripts/ui/`, scenes, or AI: remind the user to run `/playtest-check` (≥ 30 s on Main.tscn, zero ERROR logs) before any commit.
5. **Project memory** — `.claude/memory/` contains binding project rules (not auto-loaded by the harness). Read its index at [`.claude/memory/MEMORY.md`](.claude/memory/MEMORY.md) at the start of any non-trivial task.

## Project Overview

Arcane Net — isometric action-RPG.

- **Engine**: Godot 4.6 Forward Plus, .NET build (`Godot_mono.app`)
- **Language**: GDScript (fully typed); C# available via mono build
- **Main scene**: `res://scenes/main/Main.tscn`
- **Tests**: GUT in `addons/gut/` (installed via AssetLib, not committed)
- **GDD**: `Technical_GDD_v1.1.docx` — source of truth for directory layout

## Commands

```bash
GODOT="/Applications/Godot_mono.app/Contents/MacOS/Godot"

# Run main scene
"$GODOT" --path /Users/sukhrobshukurov/Dev/godot-test-game

# Run a specific scene
"$GODOT" --path . scenes/main/Main.tscn

# Reimport resources — MANDATORY after adding any .gd with class_name
"$GODOT" --path . --headless --import

# All GUT tests
"$GODOT" --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/

# A single test file
"$GODOT" --path . --headless -s addons/gut/gut_cmdln.gd \
  -gdir=res://tests/ -ginclude_subdirs -gunit_test_name=test_spawner_logic.gd
```

## Documentation Map

| Doc | Purpose |
|---|---|
| [`README.md`](README.md) | Public-facing overview, quickstart, project tree |
| [`REVIEW.md`](REVIEW.md) | Pre-commit checklist + style guide |
| [`.claude/docs/architecture.md`](.claude/docs/architecture.md) | AutoLoads, composition, StringName rules, directory map, IsoCamera |
| [`.claude/docs/combat_and_progression.md`](.claude/docs/combat_and_progression.md) | Attack/Dash/Health components, Enemy FSM, Hitstop, XP, SkillManager |
| [`.claude/docs/spectator_mode.md`](.claude/docs/spectator_mode.md) | Spectator transition, SpectatorState, EchoCompanion, SpectatorAction |
| [`.claude/docs/dev-guide.md`](.claude/docs/dev-guide.md) | How to add a skill / enemy / GUT test; commit checklist |
| [`.claude/templates/feature_plan.md`](.claude/templates/feature_plan.md) | Required template for Planner agent |
| [`.claude/skills/`](.claude/skills/) | Invokable workflows: `add-skill`, `add-enemy`, `add-spectator-action`, `godot-commit`, `godot-branch-pr`, `feature-plan`, `playtest-check`, `standup` |

## Code Standards

- **Typed GDScript** everywhere — vars, parameters, return types.
- **Typed signals** — every signal argument annotated.
- **StringName** (`&"..."`) for input actions, group names, NodePaths, method-name lookups.
- **Composition over inheritance** — `Player` is a facade; logic lives in components. Components must not call each other directly; coordinate via the facade or `EventBus`.
- **AutoLoad = single responsibility** — only globally needed, node-independent functions.
- **No magic numbers** — extract to `const`.
- **`##` docs on every public symbol** — class header, each `signal`, each public method. Skip `_private` methods and Godot lifecycle hooks (`_ready`, `_process`, `_physics_process`). Style: single-line preferred, multi-line only when behaviour is non-obvious.
- **Game feel is not unit-tested** — IsoCamera, shake, smoothing, dash feel are playtest-only.

## Testing Rules

- Tests live in `tests/`, `extends GutTest`. See [`dev-guide.md`](.claude/docs/dev-guide.md#how-to-write-gut-tests).
- After adding a new `class_name`, run `--headless --import` BEFORE tests — otherwise GUT will report `Could not find type`.
- Unit tests cover pure logic (math, FSM transitions, signal payloads). Visual / timing / AutoLoad integration is verified by playtest.
- Before opening a PR that touches `scripts/combat/`, `scripts/spectator/`, `scripts/ui/`, scenes, or AI: run `Main.tscn` for ≥ 30 s and verify zero ERROR logs. Without a playtest, no PR.

## AI Rules

- Warn immediately on architecture violations (business logic in `Player.gd`, direct component-to-component calls, AutoLoad with multiple responsibilities).
- Do not infer dev phase from this file — read `git log` and current code.
- Do not create folders outside the GDD 2.1 directory map (see [`architecture.md`](.claude/docs/architecture.md#directory-map)). Forbidden: `shaders/`, `entities/`, `systems/`.
- `.gitkeep` belongs in empty folders only until the first real file lands; delete it then.
- Never commit `.godot/`, `.import/`, `.mono/`, `.DS_Store`, build binaries.
- For interactive commands (`gh auth login` and the like), ask the user to run `! <command>` in the prompt.

## Workflows

Conditional workflows live as invokable skills (see `.claude/skills/` in Documentation Map):

- Committing → `godot-commit`
- Branching / opening a PR → `godot-branch-pr`
- Playtesting → `playtest-check`
- Daily standup report → `standup`
