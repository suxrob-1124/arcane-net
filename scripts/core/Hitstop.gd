## Reference-counted time-freeze. AutoLoad singleton.
## Multiple concurrent `request()` calls stack — `Engine.time_scale` returns to 1.0 only
## when every outstanding request has resolved. Runs in PROCESS_MODE_ALWAYS so its
## own timer ticks while time is frozen.
extends Node

var _active_count: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Freeze `Engine.time_scale` for `duration` seconds. Safe to call concurrently —
## requests stack and the freeze lasts until the last one resolves.
func request(duration: float = 0.05) -> void:
	_active_count += 1
	if _active_count == 1:
		Engine.time_scale = 0.0
	await get_tree().create_timer(duration, false, false, true).timeout
	_active_count -= 1
	if _active_count == 0:
		Engine.time_scale = 1.0
