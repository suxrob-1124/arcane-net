# Combat & Progression

> Player combat components, enemy FSM, Hitstop, XP, and SkillManager reference.

## Player Combat

### AttackComponent

`Node3D`, direct child of `Player`. File: `scripts/combat/AttackComponent.gd`.

Flow on `attack` input:

1. Check `can_attack()` → `CooldownTimer.is_stopped()`.
2. Gather overlapping bodies/areas in `DetectionArea` that are in group `&"enemies"`.
3. `select_nearest_target()` picks the closest by `distance_squared_to`.
4. Spawn projectile via `projectile_scene.instantiate()`, parent it to `GameState.current_scene`.
5. Call `launch(direction)` on the projectile (or set `direction` property as fallback).
6. `Hitstop.request(0.05)` + `IsoCamera.shake(0.05, 0.05)`.
7. Start `CooldownTimer` (default `0.4 s`).

Direction fallback order when no target is in range:

1. Current isometric input direction from `MovementComponent.get_input_iso_direction()`.
2. `-Visuals.basis.z` (character forward).

Signal: `attack_performed(target: Node3D)` — `target` may be `null`.

### DashComponent

File: `scripts/combat/DashComponent.gd`.

```
DASH_SPEED = 20.0   # 4 m in 0.2 s
```

| Timer | Duration | Purpose |
|---|---|---|
| `DurationTimer` | 0.2 s | dash movement window |
| `IframesTimer` | 0.25 s | invulnerability window |
| `CooldownTimer` | 1.5 s | next-dash lockout |

During a dash: `Player.is_invulnerable = true`, `Player.is_dashing = true`, `MovementComponent` is disabled, and `DashComponent` calls `move_and_slide()` itself.

Signals: `dash_started(direction: Vector3)`, `dash_ended()` — extension points for VFX/SFX.

### HealthComponent

File: `scripts/combat/HealthComponent.gd`.

```gdscript
signal health_changed(current: int, max_value: int)
signal damaged(amount: int, source: Node)
signal died(killer: Node)
```

- `take_damage()` is a no-op if `amount <= 0` or already dead.
- `heal()` is a no-op if already dead.
- `get_hp_ratio() -> float` is consumed by `EchoCompanion` context.

---

## Enemy FSM

`Enemy` (`scripts/combat/Enemy.gd`) — `CharacterBody3D`.

### States

```gdscript
enum State { IDLE, CHASE, ATTACK, DEAD }
```

| State | Transition out |
|---|---|
| `IDLE` | → `CHASE` when player distance ≤ `data.chase_radius` |
| `CHASE` | → `ATTACK` when distance ≤ `data.attack_radius`; → `IDLE` when distance > `chase_radius × 1.2` |
| `ATTACK` | stub — override in subclasses |
| `DEAD` | terminal; disables `_physics_process` |

`_retarget()` runs on `RetargetTimer` (periodic). Clears `_player` if the player has no `is_alive()` or is dead.

### EnemyData Resource

File: `scripts/data/EnemyData.gd`.

```gdscript
@export var max_hp: int = 30
@export var move_speed: float = 4.0
@export var melee_damage: int = 10
@export var xp_reward: int = 10
@export var chase_radius: float = 10.0
@export var attack_radius: float = 1.5
@export var attack_telegraph: float = 0.5   # seconds of wind-up before hit
```

### Death sequence

1. `set_state(DEAD)`, disable physics.
2. Spawn `CPUParticles3D` burst (purple, 20 particles, one-shot).
3. Flash mesh white for 0.1 s using a temporary `StandardMaterial3D`.
4. `EventBus.enemy_died.emit(self, death_pos, xp)`.
5. `Hitstop.request(0.05)`.
6. Spawn `XPNumberPopup` above corpse.
7. `queue_free()` after 0.4 s.

### Telegraph pattern

`EnemyData.attack_telegraph` is the pre-hit delay exported on the resource. Concrete enemy subclasses (for example `GlitchPup`) use it in their `ATTACK` state to time their swing. The base `Enemy._state_attack()` is a stub — always override it.

---

## Hitstop

`Hitstop` AutoLoad (`scripts/core/Hitstop.gd`) — reference-counted `Engine.time_scale` freeze.

```gdscript
Hitstop.request(0.05)   # any duration in seconds
```

Multiple concurrent calls stack: `time_scale` returns to `1.0` only when all outstanding requests resolve. Uses `create_timer(..., process_always = true)` so the timer ticks while frozen.

> **Known issue**: `AttackComponent` has its own inline `Engine.time_scale` manipulation (TODO Phase 3: replace with `Hitstop`). Until then two freeze paths coexist.

---

## Progression

### ExperienceComponent

File: `scripts/progression/ExperienceComponent.gd`.

XP curve: `XP_BASE * level ^ XP_EXP` = `100 * level^1.5`.

| Level | XP to reach next |
|---|---|
| 1 | 100 |
| 5 | ~1118 |
| 10 | 3162 |

Signal emission order for a single level-up:

1. `xp_gained(amount, current_before, required_L1)` — immediate feedback.
2. `level_up(new_level)` — local signal.
3. `EventBus.level_up_triggered(new_level)` — triggers `SkillManager`.
4. `xp_gained(0, remainder, required_L2)` — UI progress-bar refresh.

`MAX_LEVELS_PER_CALL = 100` caps the while-loop in case of misconfigured XP rewards.

Listens to `EventBus.enemy_died` — automatically calls `add_xp(xp_reward)`.

### SkillManager

File: `scripts/progression/SkillManager.gd`.

Listens to `EventBus.level_up_triggered` → calls `request_level_up_choice()` → emits `level_up_pending(choices: Array[SkillData])` for the UI.

Rarity weights (higher = more common):

| Rarity | Weight |
|---|---|
| `COMMON` | 60 |
| `RARE` | 25 |
| `EPIC` | 10 |
| `LEGENDARY` | 5 |

Skill lifecycle:

1. `apply_skill(skill)` — adds to `_active` dict with `stacks = 1`, or increments existing.
2. When `stacks == max_stacks` and `evolves_into != null` → `_evolve()`: free old instance, call `_add_new(new_skill)`, emit `skill_evolved`.
3. Instantiate `implementation_scene` under `skill_host_path` node so the skill's logic node lives in the correct scene-tree position.

Pool filtering (`_build_available_pool`): skip skills with unsatisfied `requires_skills`, active `conflicts_with`, or fully-stacked skills with no evolution target.

### SkillData Resource

File: `scripts/data/SkillData.gd`.

```gdscript
@export var id: StringName = &""
@export var rarity: Rarity = Rarity.COMMON
@export var max_stacks: int = 5
@export var evolves_into: SkillData          # optional evolution target
@export var conflicts_with: Array[StringName]
@export var requires_skills: Array[StringName]
@export var implementation_scene: PackedScene
```
