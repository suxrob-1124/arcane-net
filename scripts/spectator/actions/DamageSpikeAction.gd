class_name DamageSpikeAction
extends SpectatorAction


func _init() -> void:
	action_name = &"damage_spike"
	mana_cost = 80.0


func can_execute(ctx: Dictionary) -> bool:
	return ctx.get("highest_hp_enemy_ratio", 0.0) > 0.80


func execute(ctx: Dictionary) -> void:
	var enemy: Node = ctx.get("highest_hp_enemy")
	if enemy == null or not is_instance_valid(enemy):
		return
	if enemy.has_method(&"take_damage"):
		enemy.take_damage(80)
	else:
		push_warning("EchoCompanion/DamageSpikeAction: enemy has no take_damage() method")
