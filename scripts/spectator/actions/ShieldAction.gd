class_name ShieldAction
extends SpectatorAction


func _init() -> void:
	action_name = &"shield"
	mana_cost = 60.0


func can_execute(ctx: Dictionary) -> bool:
	return ctx.get("boss_casting_aoe", false)


func execute(_ctx: Dictionary) -> void:
	push_warning("EchoCompanion/ShieldAction: not implemented")
