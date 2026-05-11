extends Node

var _active_count: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func request(duration: float = 0.05) -> void:
	_active_count += 1
	if _active_count == 1:
		Engine.time_scale = 0.0
	await get_tree().create_timer(duration, false, false, true).timeout
	_active_count -= 1
	if _active_count == 0:
		Engine.time_scale = 1.0
