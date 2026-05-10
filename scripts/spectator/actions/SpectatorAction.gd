class_name SpectatorAction
extends RefCounted

var action_name: StringName = &""
var mana_cost: float = 0.0


func can_execute(ctx: Dictionary) -> bool:
	return false


func execute(ctx: Dictionary) -> void:
	pass
