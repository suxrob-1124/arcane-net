# Arcane Net

Tech-Noir Fantasy Isometric Action-RPG built in Godot 4.6.

**USP — Spectator Mode 2.0**: when a player dies they become a spectator who can actively influence the run through their AI companion Echo, creating a cooperative loop that keeps everyone engaged even after death.

## Tech Stack

| Component | Details |
|-----------|---------|
| Engine | Godot 4.6, Forward Plus renderer, .NET build |
| Language | GDScript (fully typed) |
| C# | Available via mono build (assembly: `Arcane Net`) |
| Tests | [GUT](https://github.com/bitwes/Gut) framework (`addons/gut/`) |
| Physics layers | world / player / enemies / projectiles / hitbox |

## Quick Start

### Prerequisites

- Godot 4.6 **.NET build** (mono) — the plain build will not work.
- On macOS the expected path is `/Applications/Godot_mono.app/Contents/MacOS/Godot`.

```bash
export GODOT="/Applications/Godot_mono.app/Contents/MacOS/Godot"
```

### Import resources

Run this **before** opening the editor or running tests, and again every time you add a new `class_name`:

```bash
"$GODOT" --path /path/to/godot-test-game --headless --import
```

### Run the game

```bash
# Launch the main scene
"$GODOT" --path /path/to/godot-test-game

# Launch a specific scene
"$GODOT" --path /path/to/godot-test-game scenes/main/Main.tscn
```

## Testing

GUT tests live in `tests/`. Always run `--headless --import` first if you added new scripts.

```bash
# Run all tests
"$GODOT" --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/

# Run a single test file
"$GODOT" --path . --headless -s addons/gut/gut_cmdln.gd \
  -gdir=res://tests/ -ginclude_subdirs -gunit_test_name=test_spawner_logic.gd
```

Tests cover logic only (movement math, dash cooldown, dungeon generation, spawner). Game feel, camera smoothing, and AutoLoad signal integration are verified by playtesting — not unit tests.

## Project Structure

```
scripts/
  core/           # AutoLoad singletons: GameState, EventBus, InputManager, Hitstop
  combat/         # Player facade, MovementComponent, DashComponent, IsoCamera
  spectator/      # SpectatorState (AutoLoad), EchoCompanion, priority actions
  spectator/
    actions/      # SpectatorAction base + HealAction and stubs
  dungeon_gen/    # Procedural dungeon generation
  progression/    # Levels, XP, stats
  network/        # Multiplayer
  ui/             # UI logic
  data/           # Data classes and resource parsing

scenes/
  main/           # Entry point (Main.tscn)
  hub/            # Hub world scenes
  dungeon/        # Dungeon scenes
  combat/         # Combat-specific scenes
  spectator/      # Spectator mode scenes
  ui/             # UI scenes

resources/
  skills/         # Skill resource files
  enemies/        # Enemy resource files
  rooms/          # Room resource files

assets/
  audio/
  characters/
  enemies/
  environments/
  ui/

tests/            # GUT unit tests
addons/gut/       # GUT framework (not committed — install via AssetLib)
```

### AutoLoad singletons (load order matters)

| Singleton | Path | Role |
|-----------|------|------|
| `GameState` | `scripts/core/GameState.gd` | Game mode (`HUB / DUNGEON / SPECTATOR`), current scene ref |
| `EventBus` | `scripts/core/EventBus.gd` | Global signals between decoupled systems |
| `SpectatorState` | `scripts/spectator/SpectatorState.gd` | Live spectator count, `echo_should_be_active()` |
| `Hitstop` | `scripts/core/Hitstop.gd` | Frame-freeze effect for game feel |
| `InputManager` | `scripts/core/InputManager.gd` | Platform-aware input handling (loads last, reads `GameState`) |

## Input Bindings

| Action | Keys |
|--------|------|
| Move | WASD / Arrow keys |
| Dash | Space |
| Attack | Left Mouse Button / Enter |
| Switch target | Tab / Gamepad RB |

## Further docs

- [`CLAUDE.md`](CLAUDE.md) — instructions for AI agents working on this repo.
- [`REVIEW.md`](REVIEW.md) — pre-commit checklist and style guide.
- [`.claude/docs/architecture.md`](.claude/docs/architecture.md) — AutoLoads, composition, IsoCamera, directory map.
- [`.claude/docs/combat_and_progression.md`](.claude/docs/combat_and_progression.md) — combat components, Enemy FSM, XP, SkillManager.
- [`.claude/docs/spectator_mode.md`](.claude/docs/spectator_mode.md) — spectator transition and Echo Companion.
- [`.claude/docs/dev-guide.md`](.claude/docs/dev-guide.md) — recipes for adding a skill / enemy / test.
- [`.claude/templates/feature_plan.md`](.claude/templates/feature_plan.md) — planning template for new features.
