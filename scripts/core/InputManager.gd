## Platform-aware input router. AutoLoad singleton, loaded last so it can read GameState.
## Currently a thin shim that prints the current mode + platform on boot; expand here
## when adding gamepad / mobile-specific bindings.
extends Node

func _ready() -> void:
	print("GameState: %s | Platform: %s" % [
		GameState.Mode.keys()[GameState.current_mode],
		get_platform()
	])

## Returns the OS name as reported by `OS.get_name()` (for example `macOS`, `Windows`).
func get_platform() -> String:
	return OS.get_name()
