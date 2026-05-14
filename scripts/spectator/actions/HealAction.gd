class_name HealAction
extends SpectatorAction


func _init() -> void:
	action_name = &"heal"
	mana_cost = 40.0


func can_execute(ctx: Dictionary) -> bool:
	return ctx.get("player_hp_ratio", 1.0) <= 0.30


func execute(ctx: Dictionary) -> void:
	var player: Node = ctx.get("player")
	if player == null:
		return
	if player.has_method(&"heal"):
		player.heal(40)
	else:
		push_warning("EchoCompanion/HealAction: player has no heal() method")
