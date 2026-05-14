## HP container with damage / heal / death signals. Pure logic — no visuals.
## Used by Player, Enemy, and any node that needs a health pool.
class_name HealthComponent
extends Node

## Emitted on every HP change (damage, heal, init). UI binds to this.
signal health_changed(current: int, max_value: int)
## Emitted only on damage (not heal). `source` is the attacker node when known.
signal damaged(amount: int, source: Node)
## Emitted once when HP reaches 0. `killer` may be null for environmental kills.
signal died(killer: Node)

@export var max_hp: int = 100
var current_hp: int


func _ready() -> void:
	current_hp = max_hp


## Applies `amount` damage. No-op if `amount <= 0` or already dead. Emits `damaged` and
## `health_changed`; emits `died` exactly once when HP hits 0.
func take_damage(amount: int, source: Node = null) -> void:
	if amount <= 0 or current_hp <= 0:
		return
	current_hp = max(current_hp - amount, 0)
	if get_parent() != null and get_parent().is_in_group(&"player"):
		print("[HP] damage=%d → %d/%d (%.0f%%)" % [amount, current_hp, max_hp, 100.0 * current_hp / max_hp])
	damaged.emit(amount, source)
	health_changed.emit(current_hp, max_hp)
	if current_hp == 0:
		died.emit(source)


## Heals `amount`, clamped to `max_hp`. No-op if `amount <= 0` or already dead.
func heal(amount: int) -> void:
	if amount <= 0 or current_hp <= 0:
		return
	current_hp = min(current_hp + amount, max_hp)
	if get_parent() != null and get_parent().is_in_group(&"player"):
		print("[HP] heal=%d → %d/%d (%.0f%%)" % [amount, current_hp, max_hp, 100.0 * current_hp / max_hp])
	health_changed.emit(current_hp, max_hp)


## Returns true while HP > 0.
func is_alive() -> bool:
	return current_hp > 0


## Current HP as a fraction in `[0.0, 1.0]`. Returns 0.0 if `max_hp == 0`.
func get_hp_ratio() -> float:
	if max_hp == 0:
		return 0.0
	return float(current_hp) / float(max_hp)
