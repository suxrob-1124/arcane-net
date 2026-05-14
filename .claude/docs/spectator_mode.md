# Spectator Mode & Echo Companion

> Death-to-spectator transition flow, SpectatorState gating, EchoCompanion scan loop, and SpectatorAction reference.

## What It Is (USP)

When the player dies, they do not return to a menu — they become a **spectator**. They watch an ally continue the run and interact through the **Echo Companion**, an AI that the spectator can nudge into casting abilities on their behalf. This keeps eliminated players engaged and rewards their attention by helping the living player.

---

## Transition Flow

### Trigger

`SpectatorController` (`scripts/spectator/SpectatorController.gd`) listens to `EventBus.player_died`.

### Sequence on player death

1. Freeze camera at death position (detach from the player node before it becomes a ghost).
2. Call `player.enter_ghost_state()` if the method exists.
3. `find_alive_allies()` — scan group `&"allies"`, exclude `&"enemies"`, check `is_alive()`.
4. If no allies → `EventBus.game_over.emit()` → end.
5. Pick the nearest ally as the initial spectator camera target.
6. `SpectatorState.enter_spectator_mode()` → sets `GameState.current_mode = SPECTATOR` → emits `spectator_mode_entered`.

### Target switching

The `switch_target` input action cycles through the `find_alive_allies()` list in array order (wraps around). The camera re-targets instantly.

---

## SpectatorState AutoLoad

File: `scripts/spectator/SpectatorState.gd`.

```gdscript
const ECHO_THRESHOLD: int = 3

var human_spectator_count: int = 0
var current_mana: float = 100.0
var cooldowns_map: Dictionary = {}
```

`echo_should_be_active() -> bool`:

```gdscript
return GameState.player_count >= 1 and human_spectator_count < ECHO_THRESHOLD
```

Echo is active while fewer than 3 human spectators are watching. With 3+ humans spectating, they are expected to send commands directly and Echo steps back.

Signals:

- `spectator_mode_entered()` — fired on transition in.
- `spectator_mode_exited()` — fired on transition out (not yet wired to respawn logic).

---

## Echo Companion

File: `scripts/spectator/EchoCompanion.gd`. `Node` with a `ManaComponent` child, instantiated in the dungeon scene alongside the player.

### Scan loop

Every `TICK_INTERVAL = 0.25 s` (4 Hz, synced with Glitch Pup attack cadence):

1. Guard: skip if `_is_acting` or `not SpectatorState.echo_should_be_active()`.
2. Build context snapshot (player HP ratio, highest-HP enemy, AOE-telegraph flag).
3. `_pick_action(ctx)` — iterate `actions` in priority order, return the first whose `is_off_cooldown()`, `can_execute()`, and `mana_cost` are all satisfied.
4. `_perform(action, ctx)` — `await` a random delay `[min_delay, max_delay]` (default 0.5–1.5 s), re-check mana, `mana.spend()`, `action.execute(ctx)`, `action.mark_used()` (starts personal cooldown), emit `companion_acted` + `EventBus.echo_acted`.

DEBUG_LOG deduplicates identical tick states via `_last_tick_state` so log output stays scannable during long idle periods.

### Mana

`ManaComponent` (`scripts/core/ManaComponent.gd`):

- Starting mana: `100.0` (mirrored in `SpectatorState.current_mana`).
- Regen: `regen_per_minute = 10.0` per **GDD 6.8** (1 unit per 6 s). Intentionally slow — Echo is meant to cast roughly once per encounter, not spam.
- `can_spend(cost)` and `spend(cost)` are the only public API Echo uses.

### Action priority list

Hardcoded in `EchoCompanion._ready()`:

```gdscript
actions = [HealAction.new(), ShieldAction.new(), DamageSpikeAction.new()]
```

Priority is array order — the first action whose condition passes wins.

---

## SpectatorAction Base Class

File: `scripts/spectator/actions/SpectatorAction.gd`.

```gdscript
class_name SpectatorAction
extends RefCounted

var action_name: StringName = &""
var mana_cost: float = 0.0
var cooldown_seconds: float = 0.0       # 0 = no personal cooldown

func can_execute(_ctx: Dictionary) -> bool:  return false
func execute(_ctx: Dictionary) -> void:      pass
func is_off_cooldown() -> bool: ...
func mark_used() -> void: ...           # called by EchoCompanion after a successful cast
```

`RefCounted` — no scene required, lives in memory only. `can_execute()` is for ability-specific conditions only; cooldown and mana are checked separately by the caller.

Context dict keys available to actions:

| Key | Type | Value |
|---|---|---|
| `player` | `Node` | first node in group `&"player"` |
| `player_hp_ratio` | `float` | `0.0–1.0` |
| `boss_casting_aoe` | `bool` | `true` while inside an enemy telegraph window (`EventBus.enemy_telegraph_started`) |
| `highest_hp_enemy_ratio` | `float` | highest HP% among all enemies |
| `highest_hp_enemy` | `Node` | that enemy node |

---

## Implemented Actions

### HealAction

| Property | Value |
|---|---|
| `action_name` | `&"heal"` |
| `mana_cost` | `40.0` |
| `cooldown_seconds` | `0.0` |
| `can_execute` | `player_hp_ratio <= 0.30` (inclusive — fires AT 30%) |
| `execute` | `player.heal(40)` via `HealthComponent.heal()` |

### ShieldAction

| Property | Value |
|---|---|
| `action_name` | `&"shield"` |
| `mana_cost` | `60.0` |
| `cooldown_seconds` | `0.0` |
| `can_execute` | `boss_casting_aoe == true` **and** `HP_FLOOR (0.50) <= player_hp_ratio <= HP_CEILING (0.85)` |
| `execute` | `player.add_invuln_source()` for `SHIELD_DURATION = 1.5 s`, then `remove_invuln_source()` |

Suppressed at low HP so mana stays available for Heal; suppressed at high HP because the player has enough buffer. AOE-flag is driven by `EventBus.enemy_telegraph_started` — Echo tracks the window via `_aoe_alert_until_ms`. Invuln stacks safely with DashComponent via the ref-counted `_invuln_sources` counter on `Player`.

### DamageSpikeAction

| Property | Value |
|---|---|
| `action_name` | `&"damage_spike"` |
| `mana_cost` | `80.0` |
| `cooldown_seconds` | `60.0` (per **GDD 6.8** — personal cooldown) |
| `can_execute` | `highest_hp_enemy_ratio > MIN_ENEMY_HP_RATIO (0.80)` |
| `execute` | `enemy.take_damage(DAMAGE_AMOUNT = 80)` |

DamageSpike is a luxury action — slow regen + 60 s cooldown ensures Echo casts it rarely, leaving mana for Heal/Shield when the player needs them.

---

## Adding a New SpectatorAction

1. Create `scripts/spectator/actions/MyAction.gd`:

   ```gdscript
   class_name MyAction
   extends SpectatorAction

   func _init() -> void:
       action_name = &"my_action"
       mana_cost = 50.0
       cooldown_seconds = 30.0   # optional — 0 means no personal cooldown

   func can_execute(ctx: Dictionary) -> bool:
       return ctx.get("some_key", false)

   func execute(ctx: Dictionary) -> void:
       pass
   ```

2. Add it to `EchoCompanion._ready()` in priority order:

   ```gdscript
   actions = [HealAction.new(), MyAction.new(), ShieldAction.new(), DamageSpikeAction.new()]
   ```

3. If the action needs a new context key, add it to `EchoCompanion._build_context()`.

4. Run `--headless --import`, GUT tests, then `tests/playtest_smoke.gd` (headless + visual), then a manual ≥ 30 s playtest in `Main.tscn`.
