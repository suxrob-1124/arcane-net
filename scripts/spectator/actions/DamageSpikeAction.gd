## Burst damage on a high-HP enemy. Gated by a 60-second personal cooldown per GDD 6.8 — Echo
## casts this rarely, not on every cooldown of mana.
class_name DamageSpikeAction
extends SpectatorAction

## Damage applied to the target on cast.
const DAMAGE_AMOUNT: int = 80
## Minimum enemy HP ratio for the action to consider an enemy worth spiking.
const MIN_ENEMY_HP_RATIO: float = 0.80


func _init() -> void:
	action_name = &"damage_spike"
	mana_cost = 80.0
	cooldown_seconds = 60.0


## Returns true when a tracked enemy has HP ratio above MIN_ENEMY_HP_RATIO.
func can_execute(ctx: Dictionary) -> bool:
	return ctx.get("highest_hp_enemy_ratio", 0.0) > MIN_ENEMY_HP_RATIO


func execute(ctx: Dictionary) -> void:
	var enemy: Node = ctx.get("highest_hp_enemy")
	if enemy == null or not is_instance_valid(enemy):
		return
	if enemy.has_method(&"take_damage"):
		enemy.take_damage(DAMAGE_AMOUNT)
	else:
		push_warning("EchoCompanion/DamageSpikeAction: enemy has no take_damage() method")
