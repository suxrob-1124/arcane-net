# Developer Guide

> Step-by-step recipes for adding skills, enemies, and GUT tests, plus the commit checklist.

## Before Any Change

```bash
GODOT="/Applications/Godot_mono.app/Contents/MacOS/Godot"

# After adding a new .gd file with class_name — MANDATORY before running tests
"$GODOT" --path . --headless --import

# Run all GUT tests
"$GODOT" --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/

# Run one test file
"$GODOT" --path . --headless -s addons/gut/gut_cmdln.gd \
  -gdir=res://tests/ -ginclude_subdirs -gunit_test_name=test_skill_manager.gd

# Headless smoke test: 30 s of synthetic input on Main.tscn, catches SCRIPT ERROR / signal regressions
"$GODOT" --path . --headless -s tests/playtest_smoke.gd 2>&1 | grep -E "SCRIPT ERROR|push_error"

# Visual smoke test: same run, dumps PNG snapshots to /tmp/arcane-net-smoke/ every 5 s
"$GODOT" --path . -s tests/playtest_smoke.gd && ls /tmp/arcane-net-smoke/
```

---

## How to Add a New Skill

### Step 1 — Create the SkillData resource

In the Godot editor: **FileSystem → `resources/skills/` → right-click → New Resource → SkillData**.

Or via GDScript (for tests):

```gdscript
var data := SkillData.new()
data.id = &"my_skill"
data.display_name = "My Skill"
data.rarity = SkillData.Rarity.RARE
data.max_stacks = 3
data.implementation_scene = preload("res://scenes/skills/MySkill.tscn")
ResourceSaver.save(data, "res://resources/skills/my_skill.tres")
```

Fields:

| Field | Required | Notes |
|---|---|---|
| `id` | yes | unique `StringName`, matches `conflicts_with` / `requires_skills` references |
| `display_name` | yes | shown in level-up UI |
| `rarity` | yes | affects pick probability (COMMON 60, RARE 25, EPIC 10, LEGENDARY 5) |
| `max_stacks` | yes | after this many stacks the skill evolves (if `evolves_into` is set) |
| `implementation_scene` | yes | `PackedScene` of the skill behaviour node |
| `evolves_into` | optional | another `SkillData` resource |
| `conflicts_with` | optional | list of skill `id`s that cannot coexist |
| `requires_skills` | optional | prerequisites that must be owned first |

### Step 2 — Create the implementation scene

Create `scenes/skills/MySkill.tscn`. Root should be a `Node` (or `Node3D` if spatial placement is needed). Attach a script:

```gdscript
class_name SkillCleave  # example
extends Node

var data: SkillData  # SkillManager sets this via set("data", skill)

func _ready() -> void:
    # connect to player signals, subscribe to EventBus, etc.
    pass
```

`SkillManager._add_new()` will:

1. Instantiate the scene.
2. Set the `data` property on the instance.
3. Add the instance as a child of the `skill_host_path` node.

### Step 3 — Register in SkillManager

Add your `.tres` file to `SkillManager.skill_pool` array in the Inspector (or via code in tests).

### Step 4 — Validate

```bash
"$GODOT" --path . --headless --import
"$GODOT" --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/
```

Then playtest in `Main.tscn` — kill enemies, level up, verify the skill appears in the UI and its effect works.

---

## How to Add a New Enemy

### Step 1 — Create EnemyData resource

```gdscript
var data := EnemyData.new()
data.enemy_name = "Void Crawler"
data.enemy_id = &"void_crawler"
data.max_hp = 60
data.move_speed = 5.0
data.melee_damage = 15
data.xp_reward = 25
data.chase_radius = 12.0
data.attack_radius = 1.8
data.attack_telegraph = 0.4   # wind-up before hit, in seconds
data.enemy_scene = preload("res://scenes/enemies/VoidCrawler.tscn")
ResourceSaver.save(data, "res://resources/enemies/void_crawler.tres")
```

### Step 2 — Create the enemy scene

Root: `CharacterBody3D`. Use `Enemy` directly or extend it.

If extending `Enemy`:

```gdscript
class_name VoidCrawler
extends Enemy

func _state_attack() -> void:
    # Telegraph: wait attack_telegraph seconds, then deal damage
    # Use a Timer node or await, then call _player.take_damage(data.melee_damage)
    pass
```

Required child nodes:

- `HealthComponent` — HP tracking
- `Visuals` (`Node3D`) — mesh; `look_at` uses this
- `RetargetTimer` (`Timer`, `one_shot = false`) — periodic player scan

Add the enemy to group `&"enemies"` in `_ready()` (base `Enemy` does this automatically).

### Step 3 — Implement the ATTACK state

Base `Enemy._state_attack()` is a stub. Override it:

```gdscript
func _state_attack() -> void:
    if _player == null or not is_instance_valid(_player):
        set_state(State.IDLE)
        return
    # 1. Show telegraph (flash, sound, windup animation)
    await get_tree().create_timer(data.attack_telegraph).timeout
    # 2. Check player is still in range
    if global_position.distance_to(_player.global_position) <= data.attack_radius * 1.5:
        _player.take_damage(data.melee_damage)
    set_state(State.CHASE)
```

### Step 4 — Register with EnemySpawner

Add the `.tres` to `EnemySpawner.enemy_pool` in the Inspector, or in `DungeonGenerator` spawn logic.

### Step 5 — Validate

```bash
"$GODOT" --path . --headless --import
"$GODOT" --path . --headless -s addons/gut/gut_cmdln.gd \
  -gdir=res://tests/ -ginclude_subdirs -gunit_test_name=test_spawner_logic.gd
```

Playtest: verify chase, attack telegraph, death FX, XP drop.

---

## How to Write GUT Tests

### File structure

```gdscript
extends GutTest

func test_something_specific() -> void:
    # arrange
    var component := MyClass.new()
    add_child_autofree(component)   # auto cleanup after test
    # act
    component.do_thing()
    # assert
    assert_eq(component.result, expected_value, "description of what should be true")
```

All test files live in `tests/`. File names must start with `test_`.

### Rules

**Test only logic.** If it runs without a rendered frame, it can be unit-tested:

- Math (XP curves, damage formulas, movement vector rotation).
- State transitions (FSM state after input, cooldown flags).
- Signal emission order and parameters.
- Data validation (pool filtering, skill conflict resolution).

**Never unit-test:**

- Camera smoothing / screen shake feel.
- Dash timing feel.
- Visual correctness (mesh visibility, particle effects).
- AutoLoad signal integration between two live singletons in-scene.

These require playtest. Add a note in `REVIEW.md` checklist instead.

### Signal testing

```gdscript
func test_level_up_emits_event_bus_signal() -> void:
    var c := ExperienceComponent.new()
    add_child_autofree(c)
    watch_signals(EventBus)         # GUT tracks signals on this object
    c.add_xp(150)
    assert_signal_emitted_with_parameters(EventBus, &"level_up_triggered", [2])
```

Use `watch_signals(node)` before the action, then `assert_signal_emitted` / `assert_signal_emitted_with_parameters`.

### Derive expected values from the formula, not hardcoded numbers

```gdscript
# Good — formula is the source of truth
var remaining: int = 10000
var expected_level: int = 1
while remaining >= c.get_required_xp(expected_level):
    remaining -= c.get_required_xp(expected_level)
    expected_level += 1
c.add_xp(10000)
assert_eq(c.current_level, expected_level, "...")

# Bad — breaks silently if the XP curve changes
assert_eq(c.current_level, 7, "level after 10000 xp")
```

### After adding a new class_name

Always run `--headless --import` before tests, or you'll get `Could not find type`:

```bash
"$GODOT" --path . --headless --import && \
"$GODOT" --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/
```

---

## Commit Checklist

1. `--headless --import` passes with no errors.
2. All GUT tests green.
3. For gameplay changes:
   - `tests/playtest_smoke.gd` (headless) finishes with zero `SCRIPT ERROR` / `push_error` lines.
   - Manual `Main.tscn` playtest ≥ 30 s with zero ERROR logs (game-feel verification — camera, shake, dash feel).
4. No `.godot/`, `.mono/`, `.DS_Store` in diff.
5. Conventional Commit message: `feat(combat): add void crawler enemy`.
6. Cross-check [`REVIEW.md`](../../REVIEW.md) for project-specific checklist items.
