extends Node

func _ready() -> void:
	print("GameState: %s | Platform: %s" % [
		GameState.Mode.keys()[GameState.current_mode],
		get_platform()
	])

func get_platform() -> String:
	return OS.get_name()
