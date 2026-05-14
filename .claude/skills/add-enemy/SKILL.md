---
name: add-enemy
description: Add a new enemy to Arcane Net — creates an EnemyData resource, scene extending Enemy, implements _state_attack with telegraph, registers with EnemySpawner, runs import + GUT tests. Use when the user asks "add an enemy", "create enemy X", or describes a new opponent for the dungeon.
---

# add-enemy

Follow `.claude/docs/dev-guide.md` → "How to Add a New Enemy" exactly. Summary:

1. **Create EnemyData** at `resources/enemies/<id>.tres`. Fields: `enemy_name`, `enemy_id` (`StringName`), `max_hp`, `move_speed`, `melee_damage`, `xp_reward`, `chase_radius`, `attack_radius`, `attack_telegraph`, `enemy_scene` (`PackedScene`).
2. **Create scene** at `scenes/enemies/<Name>.tscn`. Root: `CharacterBody3D`. Required children: `HealthComponent`, `Visuals` (`Node3D`), `RetargetTimer` (`Timer`, `one_shot = false`).
3. **Extend Enemy** and override `_state_attack()`:
   ```gdscript
   class_name VoidCrawler
   extends Enemy

   func _state_attack() -> void:
       if _player == null or not is_instance_valid(_player):
           set_state(State.IDLE)
           return
       await get_tree().create_timer(data.attack_telegraph).timeout
       if global_position.distance_to(_player.global_position) <= data.attack_radius * 1.5:
           _player.take_damage(data.melee_damage)
       set_state(State.CHASE)
   ```
4. **Register** the `.tres` in `EnemySpawner.enemy_pool` (Inspector or `DungeonGenerator` spawn logic).
5. **Validate**:
   ```bash
   "$GODOT" --path . --headless --import
   "$GODOT" --path . --headless -s addons/gut/gut_cmdln.gd \
     -gdir=res://tests/ -ginclude_subdirs -gunit_test_name=test_spawner_logic.gd
   ```
6. **Playtest** — verify chase, attack telegraph timing, death FX, XP drop.

## Hard rules

- Always override `_state_attack()`. Base `Enemy._state_attack()` is a stub.
- Telegraph (`attack_telegraph` seconds) is mandatory — no instant-hit enemies.
- Add the enemy to group `&"enemies"` — base `Enemy._ready()` already does this; don't double-add.
- `##` docs on class, signals, public methods.
- See `.claude/docs/combat_and_progression.md` for the full FSM contract.
