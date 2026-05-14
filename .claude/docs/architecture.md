# Architecture

> AutoLoad layout, node composition pattern, StringName rules, directory map, and IsoCamera reference.

## Engine & Language

- **Engine**: Godot 4.6 Forward Plus (.NET build — use `Godot_mono.app`).
- **Language**: GDScript (fully typed). C# is available via mono but not used for gameplay code.
- **Rendering**: isometric 3D via an orthographic `Camera3D`.

---

## AutoLoad Singletons

Load order matters. Each singleton may only read from singletons loaded before it.

| Order | Name | Path | Responsibility |
|---|---|---|---|
| 1 | `GameState` | `scripts/core/GameState.gd` | Global mode enum, current scene ref, player count |
| 2 | `EventBus` | `scripts/core/EventBus.gd` | Typed global signals; no logic, no state |
| 3 | `SpectatorState` | `scripts/spectator/SpectatorState.gd` | Spectator counter, Echo activity gating |
| 4 | `Hitstop` | `scripts/core/Hitstop.gd` | `Engine.time_scale` freeze; ref-counted requests |
| 5 | `InputManager` | `scripts/core/InputManager.gd` | Platform input; reads `GameState.current_mode` in `_ready()` |

### GameState

```gdscript
enum Mode { HUB, DUNGEON, SPECTATOR }
var current_mode: Mode = Mode.HUB
var current_scene: Node = null
var player_count: int = 1
```

Write `current_mode` only from scene-transition code. All other systems read it.

### EventBus

Pure signal hub — no logic, no state. All signals are fully typed.

```gdscript
signal player_died(player: Node3D, cause: StringName, position: Vector3)
signal room_cleared(room_id: String)
signal skill_picked(skill_id: StringName)
signal enemy_died(enemy: Node3D, position: Vector3, xp_reward: int)
signal level_up_triggered(new_level: int)
signal echo_acted(action_name: StringName)
signal game_over()
```

**Rule**: systems must never hold direct references to unrelated systems. Route cross-system communication through `EventBus`.

### Hitstop

Reference-counted freeze: simultaneous callers stack instead of fighting each other.

```gdscript
Hitstop.request(0.05)  # freezes Engine.time_scale for 0.05 s
```

`process_mode = PROCESS_MODE_ALWAYS` keeps the node ticking even while time is frozen so its own timer fires.

---

## Node Composition Pattern

No deep inheritance trees. `Player` is a facade; behaviour lives in child components.

```
Player (CharacterBody3D)          ← facade: flags only
├── MovementComponent (Node)      ← isometric input → velocity
├── DashComponent (Node)          ← dash state machine, iframes
├── AttackComponent (Node3D)      ← projectile spawn, hitstop, shake
├── HealthComponent (Node)        ← HP, damage, death signal
├── ExperienceComponent (Node)    ← XP accumulation, level-up events
└── Visuals (Node3D)              ← mesh + look_at rotation
```

**Rule**: components must not reference sibling components directly. Cross-component coordination goes through `Player`'s public API or `EventBus`.

---

## StringName Rules

Use `&"..."` literals (not plain strings) for:

| Context | Example |
|---|---|
| Input action names | `Input.is_action_pressed(&"attack")` |
| Group names | `add_to_group(&"enemies")` |
| Method-name lookups | `node.has_method(&"heal")` |
| `NodePath` literals | `NodePath(&"../Player")` |
| Signal / tag identifiers | `cause: StringName = &"enemy"` |

Never use bare `String` in these contexts — it allocates on every frame.

---

## Directory Map

| Path | Contents |
|---|---|
| `scripts/core/` | AutoLoad singletons: `GameState`, `EventBus`, `InputManager`, `Hitstop`, `ManaComponent` |
| `scripts/combat/` | `Player`, `MovementComponent`, `DashComponent`, `AttackComponent`, `IsoCamera`, `Enemy`, `HealthComponent`, `Projectile` |
| `scripts/progression/` | `SkillManager`, `ExperienceComponent` |
| `scripts/dungeon_gen/` | `DungeonGenerator`, `DungeonBuilder`, `RoomNode`, `Door`, `Portal`, `EnemySpawner` |
| `scripts/spectator/` | `SpectatorController`, `SpectatorState` (AutoLoad), `EchoCompanion` |
| `scripts/spectator/actions/` | `SpectatorAction` (base), `HealAction`, `ShieldAction`, `DamageSpikeAction` |
| `scripts/data/` | `SkillData`, `EnemyData`, `RoomData` — pure `Resource` subclasses |
| `scripts/ui/` | `HUD`, `PlayerHealthBar`, `FadeLayer`, `XPNumberPopup` |
| `scenes/main/` | Entry point `Main.tscn` |
| `resources/` | `.tres` / `.res` files (skills, enemies, rooms) |
| `tests/` | GUT unit tests |

**Forbidden directories** (not in GDD 2.1): `shaders/`, `entities/`, `systems/`.

---

## IsoCamera

`Camera3D` in orthographic mode (`size = 10`), lives in `Main.tscn`.

- **Smoothing**: `global_position.lerp(desired, 1.0 - pow(smoothing, delta))` — frame-rate independent. `smoothing ∈ [0.001, 0.01]`.
- **Orientation**: set via `look_at(target.global_position)` in `_ready()`, not via `rotation_degrees`.
- **Screen shake**: `h_offset` / `v_offset` with linear decay. Repeated `shake()` takes `max` intensity — a new hit is never swallowed by an ongoing shake.
- Joined to group `&"camera"` so `AttackComponent` can find it without a direct reference.
