## DamageSpike is a luxury action — only fires when the player is safe AND Echo has a full mana
## reserve. Prevents it from draining mana that Heal/Shield may urgently need.
class_name DamageSpikeAction
extends SpectatorAction

## Mana threshold below which DamageSpike is suppressed; ensures Heal (40) + Shield (60) can still fire.
const MANA_RESERVE_THRESHOLD: float = 95.0
## HP ratio below which DamageSpike is suppressed; below 70% a drop to Heal range is too likely.
const SAFE_HP_THRESHOLD: float = 0.70


func _init() -> void:
	action_name = &"damage_spike"
	mana_cost = 80.0


## Returns true only when the player is safe, Echo has near-full mana, and a high-HP enemy exists.
func can_execute(ctx: Dictionary) -> bool:
	return ctx.get("highest_hp_enemy_ratio", 0.0) > 0.80 \
		and ctx.get("player_hp_ratio", 1.0) >= SAFE_HP_THRESHOLD \
		and ctx.get("current_mana", 0.0) >= MANA_RESERVE_THRESHOLD


func execute(ctx: Dictionary) -> void:
	var enemy: Node = ctx.get("highest_hp_enemy")
	if enemy == null or not is_instance_valid(enemy):
		return
	if enemy.has_method(&"take_damage"):
		enemy.take_damage(80)
	else:
		push_warning("EchoCompanion/DamageSpikeAction: enemy has no take_damage() method")
