class_name DamageSpikeAction
extends SpectatorAction


func _init() -> void:
	action_name = &"damage_spike"
	mana_cost = 80.0


func can_execute(ctx: Dictionary) -> bool:
	return ctx.get("highest_hp_enemy_ratio", 0.0) > 0.80


func execute(_ctx: Dictionary) -> void:
	push_warning("EchoCompanion/DamageSpikeAction: not implemented")
